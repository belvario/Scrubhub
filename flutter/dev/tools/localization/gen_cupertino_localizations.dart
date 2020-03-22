// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'localizations_utils.dart';

HeaderGenerator generateCupertinoHeader = (String regenerateInstructions) {
  return '''
// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use:
// $regenerateInstructions

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' as intl;

import '../cupertino_localizations.dart';

// The classes defined here encode all of the translations found in the
// `flutter_localizations/lib/src/l10n/*.arb` files.
//
// These classes are constructed by the [getCupertinoTranslation] method at the
// bottom of this file, and used by the [_GlobalCupertinoLocalizationsDelegate.load]
// method defined in `flutter_localizations/lib/src/cupertino_localizations.dart`.''';
};

/// Returns the source of the constructor for a GlobalCupertinoLocalizations
/// subclass.
ConstructorGenerator generateCupertinoConstructor = (LocaleInfo locale) {
  final String localeName = locale.originalString;
  return '''
  /// Create an instance of the translation bundle for ${describeLocale(localeName)}.
  ///
  /// For details on the meaning of the arguments, see [GlobalCupertinoLocalizations].
  const CupertinoLocalization${camelCase(locale)}({
    String localeName = '$localeName',
    @required intl.DateFormat fullYearFormat,
    @required intl.DateFormat dayFormat,
    @required intl.DateFormat mediumDateFormat,
    @required intl.DateFormat singleDigitHourFormat,
    @required intl.DateFormat singleDigitMinuteFormat,
    @required intl.DateFormat doubleDigitMinuteFormat,
    @required intl.DateFormat singleDigitSecondFormat,
    @required intl.NumberFormat decimalFormat,
  }) : super(
    localeName: localeName,
    fullYearFormat: fullYearFormat,
    dayFormat: dayFormat,
    mediumDateFormat: mediumDateFormat,
    singleDigitHourFormat: singleDigitHourFormat,
    singleDigitMinuteFormat: singleDigitMinuteFormat,
    doubleDigitMinuteFormat: doubleDigitMinuteFormat,
    singleDigitSecondFormat: singleDigitSecondFormat,
    decimalFormat: decimalFormat,
  );''';
};

const String cupertinoFactoryName = 'getCupertinoTranslation';

const String cupertinoFactoryDeclaration = '''
GlobalCupertinoLocalizations getCupertinoTranslation(
  Locale locale,
  intl.DateFormat fullYearFormat,
  intl.DateFormat dayFormat,
  intl.DateFormat mediumDateFormat,
  intl.DateFormat singleDigitHourFormat,
  intl.DateFormat singleDigitMinuteFormat,
  intl.DateFormat doubleDigitMinuteFormat,
  intl.DateFormat singleDigitSecondFormat,
  intl.NumberFormat decimalFormat,
) {''';

const String cupertinoFactoryArguments =
    'fullYearFormat: fullYearFormat, dayFormat: dayFormat, mediumDateFormat: mediumDateFormat, singleDigitHourFormat: singleDigitHourFormat, singleDigitMinuteFormat: singleDigitMinuteFormat, doubleDigitMinuteFormat: doubleDigitMinuteFormat, singleDigitSecondFormat: singleDigitSecondFormat, decimalFormat: decimalFormat';

const String cupertinoSupportedLanguagesConstant = 'kCupertinoSupportedLanguages';

const String cupertinoSupportedLanguagesDocMacro = 'flutter.localizations.cupertino.languages';
