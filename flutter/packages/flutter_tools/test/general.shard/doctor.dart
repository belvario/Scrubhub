// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/linux/linux_doctor.dart';
import 'package:flutter_tools/src/web/web_validator.dart';
import 'package:flutter_tools/src/windows/visual_studio_validator.dart';

import '../src/common.dart';
import '../src/testbed.dart';

void main() {
  Testbed testbed;

  setUp(() {
    testbed = Testbed();
  });

  test('doctor validators includes desktop when features are enabled', () => testbed.run(() {
    expect(DoctorValidatorsProvider.defaultInstance.validators,
        contains(isInstanceOf<LinuxDoctorValidator>()));
    expect(DoctorValidatorsProvider.defaultInstance.validators,
        contains(isInstanceOf<VisualStudioValidator>()));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(
      isLinuxEnabled: true,
      isWindowsEnabled: true,
    ),
  }));

  test('doctor validators does not include desktop when features are enabled', () => testbed.run(() {
    expect(DoctorValidatorsProvider.defaultInstance.validators,
        isNot(contains(isInstanceOf<LinuxDoctorValidator>())));
    expect(DoctorValidatorsProvider.defaultInstance.validators,
        isNot(contains(isInstanceOf<VisualStudioValidator>())));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(
      isLinuxEnabled: false,
      isWindowsEnabled: false,
    ),
  }));

  test('doctor validators includes web when feature is enabled', () => testbed.run(() {
    expect(DoctorValidatorsProvider.defaultInstance.validators,
        contains(isInstanceOf<WebValidator>()));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(
      isWebEnabled: true,
    ),
  }));

  test('doctor validators does not include web when feature is disabled', () => testbed.run(() {
    expect(DoctorValidatorsProvider.defaultInstance.validators,
        isNot(contains(isInstanceOf<WebValidator>())));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(
      isWebEnabled: false,
    ),
  }));
}
