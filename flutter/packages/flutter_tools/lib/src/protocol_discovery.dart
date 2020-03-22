// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'base/io.dart';
import 'device.dart';
import 'globals.dart';

/// Discovers a specific service protocol on a device, and forwards the service
/// protocol device port to the host.
class ProtocolDiscovery {
  ProtocolDiscovery._(
    this.logReader,
    this.serviceName, {
    this.portForwarder,
    this.throttleDuration,
    this.hostPort,
    this.devicePort,
    this.ipv6,
  }) : assert(logReader != null)
  {
    _deviceLogSubscription = logReader.logLines.listen(
      _handleLine,
      onDone: _stopScrapingLogs,
    );
    _uriStreamController = _BufferedStreamController<Uri>();
  }

  factory ProtocolDiscovery.observatory(
    DeviceLogReader logReader, {
    DevicePortForwarder portForwarder,
    Duration throttleDuration = const Duration(milliseconds: 200),
    @required int hostPort,
    @required int devicePort,
    @required bool ipv6,
  }) {
    const String kObservatoryService = 'Observatory';
    return ProtocolDiscovery._(
      logReader,
      kObservatoryService,
      portForwarder: portForwarder,
      throttleDuration: throttleDuration,
      hostPort: hostPort,
      devicePort: devicePort,
      ipv6: ipv6,
    );
  }

  final DeviceLogReader logReader;
  final String serviceName;
  final DevicePortForwarder portForwarder;
  final int hostPort;
  final int devicePort;
  final bool ipv6;

  /// The time to wait before forwarding a new observatory URIs from [logReader].
  final Duration throttleDuration;

  StreamSubscription<String> _deviceLogSubscription;
  _BufferedStreamController<Uri> _uriStreamController;

  /// The discovered service URL.
  /// Use [uris] instead.
  // TODO(egarciad): replace `uri` for `uris`.
  Future<Uri> get uri {
    return uris.first;
  }

  /// The discovered service URLs.
  ///
  /// When a new observatory URL: is available in [logReader],
  /// the URLs are forwarded at most once every [throttleDuration].
  ///
  /// Port forwarding is only attempted when this is invoked,
  /// for each observatory URL in the stream.
  Stream<Uri> get uris {
    return _uriStreamController.stream
      .transform(_throttle<Uri>(
        waitDuration: throttleDuration,
      ))
      .asyncMap<Uri>(_forwardPort);
  }

  Future<void> cancel() => _stopScrapingLogs();

  Future<void> _stopScrapingLogs() async {
    await _uriStreamController?.close();
    await _deviceLogSubscription?.cancel();
    _deviceLogSubscription = null;
  }

  Match _getPatternMatch(String line) {
    final RegExp r = RegExp('${RegExp.escape(serviceName)} listening on ((http|\/\/)[a-zA-Z0-9:/=_\\-\.\\[\\]]+)');
    return r.firstMatch(line);
  }

  Uri _getObservatoryUri(String line) {
    final Match match = _getPatternMatch(line);
    if (match != null) {
      return Uri.parse(match[1]);
    }
    return null;
  }

  void _handleLine(String line) {
    Uri uri;
    try {
      uri = _getObservatoryUri(line);
    } on FormatException catch(error, stackTrace) {
      _uriStreamController.addError(error, stackTrace);
    }
    if (uri == null) {
      return;
    }
    if (devicePort != null && uri.port != devicePort) {
      printTrace('skipping potential observatory $uri due to device port mismatch');
      return;
    }
    _uriStreamController.add(uri);
  }

  Future<Uri> _forwardPort(Uri deviceUri) async {
    printTrace('$serviceName URL on device: $deviceUri');
    Uri hostUri = deviceUri;

    if (portForwarder != null) {
      final int actualDevicePort = deviceUri.port;
      final int actualHostPort = await portForwarder.forward(actualDevicePort, hostPort: hostPort);
      printTrace('Forwarded host port $actualHostPort to device port $actualDevicePort for $serviceName');
      hostUri = deviceUri.replace(port: actualHostPort);
    }

    assert(InternetAddress(hostUri.host).isLoopback);
    if (ipv6) {
      hostUri = hostUri.replace(host: InternetAddress.loopbackIPv6.host);
    }
    return hostUri;
  }
}

/// Provides a broadcast stream controller that buffers the events
/// if there isn't a listener attached.
/// The events are then delivered when a listener is attached to the stream.
class _BufferedStreamController<T> {
  _BufferedStreamController() : _events = <dynamic>[];

  /// The stream that this controller is controlling.
  Stream<T> get stream {
    return _streamController.stream;
  }

  StreamController<T> _streamControllerInstance;

  StreamController<T> get _streamController {
    _streamControllerInstance ??= StreamController<T>.broadcast(onListen: () {
      for (dynamic event in _events) {
        assert(!(T is List));
        if (event is T) {
          _streamControllerInstance.add(event);
        } else {
          _streamControllerInstance.addError(
            event.first as Object,
            event.last as StackTrace,
          );
        }
      }
      _events.clear();
    });
    return _streamControllerInstance;
  }

  final List<dynamic> _events;

  /// Sends [event] if there is a listener attached to the broadcast stream.
  /// Otherwise, it enqueues [event] until a listener is attached.
  void add(T event) {
    if (_streamController.hasListener) {
      _streamController.add(event);
    } else {
      _events.add(event);
    }
  }

  /// Sends or enqueues an error event.
  void addError(Object error, [StackTrace stackTrace]) {
    if (_streamController.hasListener) {
      _streamController.addError(error, stackTrace);
    } else {
      _events.add(<dynamic>[error, stackTrace]);
    }
  }

  /// Closes the stream.
  Future<void> close() {
    return _streamController.close();
  }
}

/// This transformer will produce an event at most once every [waitDuration].
///
/// For example, consider a `waitDuration` of `10ms`, and list of event names
/// and arrival times: `a (0ms), b (5ms), c (11ms), d (21ms)`.
/// The events `c` and `d` will be produced as a result.
StreamTransformer<S, S> _throttle<S>({
  @required Duration waitDuration,
}) {
  assert(waitDuration != null);

  S latestLine;
  int lastExecution;
  Future<void> throttleFuture;

  return StreamTransformer<S, S>
    .fromHandlers(
      handleData: (S value, EventSink<S> sink) {
        latestLine = value;

        final int currentTime = DateTime.now().millisecondsSinceEpoch;
        lastExecution ??= currentTime;
        final int remainingTime = currentTime - lastExecution;
        final int nextExecutionTime = remainingTime > waitDuration.inMilliseconds
          ? 0
          : waitDuration.inMilliseconds - remainingTime;

        throttleFuture ??= Future<void>
          .delayed(Duration(milliseconds: nextExecutionTime))
          .whenComplete(() {
            sink.add(latestLine);
            throttleFuture = null;
            lastExecution = DateTime.now().millisecondsSinceEpoch;
          });
      }
    );
}
