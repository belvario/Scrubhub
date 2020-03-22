// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (String language in kCupertinoSupportedLanguages) {
    testWidgets('translations exist for $language', (WidgetTester tester) async {
      final Locale locale = Locale(language);

      expect(GlobalCupertinoLocalizations.delegate.isSupported(locale), isTrue);

      final CupertinoLocalizations localizations = await GlobalCupertinoLocalizations.delegate.load(locale);

      expect(localizations.datePickerYear(0), isNotNull);
      expect(localizations.datePickerYear(1), isNotNull);
      expect(localizations.datePickerYear(2), isNotNull);
      expect(localizations.datePickerYear(10), isNotNull);

      expect(localizations.datePickerMonth(1), isNotNull);
      expect(localizations.datePickerMonth(2), isNotNull);
      expect(localizations.datePickerMonth(11), isNotNull);
      expect(localizations.datePickerMonth(12), isNotNull);

      expect(localizations.datePickerDayOfMonth(0), isNotNull);
      expect(localizations.datePickerDayOfMonth(1), isNotNull);
      expect(localizations.datePickerDayOfMonth(2), isNotNull);
      expect(localizations.datePickerDayOfMonth(10), isNotNull);

      expect(localizations.datePickerMediumDate(DateTime(2019, 3, 25)), isNotNull);

      expect(localizations.datePickerHour(0), isNotNull);
      expect(localizations.datePickerHour(1), isNotNull);
      expect(localizations.datePickerHour(2), isNotNull);
      expect(localizations.datePickerHour(10), isNotNull);

      expect(localizations.datePickerHourSemanticsLabel(0), isNotNull);
      expect(localizations.datePickerHourSemanticsLabel(1), isNotNull);
      expect(localizations.datePickerHourSemanticsLabel(2), isNotNull);
      expect(localizations.datePickerHourSemanticsLabel(10), isNotNull);
      expect(localizations.datePickerHourSemanticsLabel(0), isNot(contains(r'$hour')));
      expect(localizations.datePickerHourSemanticsLabel(1), isNot(contains(r'$hour')));
      expect(localizations.datePickerHourSemanticsLabel(2), isNot(contains(r'$hour')));
      expect(localizations.datePickerHourSemanticsLabel(10), isNot(contains(r'$hour')));

      expect(localizations.datePickerDateOrder, isNotNull);
      expect(localizations.datePickerDateTimeOrder, isNotNull);
      expect(localizations.anteMeridiemAbbreviation, isNotNull);
      expect(localizations.postMeridiemAbbreviation, isNotNull);
      expect(localizations.alertDialogLabel, isNotNull);

      expect(localizations.timerPickerHour(0), isNotNull);
      expect(localizations.timerPickerHour(1), isNotNull);
      expect(localizations.timerPickerHour(2), isNotNull);
      expect(localizations.timerPickerHour(10), isNotNull);

      expect(localizations.timerPickerMinute(0), isNotNull);
      expect(localizations.timerPickerMinute(1), isNotNull);
      expect(localizations.timerPickerMinute(2), isNotNull);
      expect(localizations.timerPickerMinute(10), isNotNull);

      expect(localizations.timerPickerSecond(0), isNotNull);
      expect(localizations.timerPickerSecond(1), isNotNull);
      expect(localizations.timerPickerSecond(2), isNotNull);
      expect(localizations.timerPickerSecond(10), isNotNull);

      expect(localizations.timerPickerHourLabel(0), isNotNull);
      expect(localizations.timerPickerHourLabel(1), isNotNull);
      expect(localizations.timerPickerHourLabel(2), isNotNull);
      expect(localizations.timerPickerHourLabel(10), isNotNull);

      expect(localizations.timerPickerMinuteLabel(0), isNotNull);
      expect(localizations.timerPickerMinuteLabel(1), isNotNull);
      expect(localizations.timerPickerMinuteLabel(2), isNotNull);
      expect(localizations.timerPickerMinuteLabel(10), isNotNull);

      expect(localizations.timerPickerSecondLabel(0), isNotNull);
      expect(localizations.timerPickerSecondLabel(1), isNotNull);
      expect(localizations.timerPickerSecondLabel(2), isNotNull);
      expect(localizations.timerPickerSecondLabel(10), isNotNull);

      expect(localizations.cutButtonLabel, isNotNull);
      expect(localizations.copyButtonLabel, isNotNull);
      expect(localizations.pasteButtonLabel, isNotNull);
      expect(localizations.selectAllButtonLabel, isNotNull);
    });
  }

  testWidgets('Spot check French', (WidgetTester tester) async {
    const Locale locale = Locale('fr');
    expect(GlobalCupertinoLocalizations.delegate.isSupported(locale), isTrue);
    final CupertinoLocalizations localizations = await GlobalCupertinoLocalizations.delegate.load(locale);
    expect(localizations is CupertinoLocalizationFr, true);
    expect(localizations.alertDialogLabel, 'Alerte');
    expect(localizations.datePickerHourSemanticsLabel(1), '1 heure');
    expect(localizations.datePickerHourSemanticsLabel(12), '12 heures');
    expect(localizations.pasteButtonLabel, 'Coller');
    expect(localizations.datePickerDateOrder, DatePickerDateOrder.dmy);
    expect(localizations.timerPickerSecondLabel(20), 's');
    expect(localizations.selectAllButtonLabel, 'Tout sélect.');
    expect(localizations.timerPickerMinute(10), '10');
  });

  testWidgets('Spot check Chinese', (WidgetTester tester) async {
    const Locale locale = Locale('zh');
    expect(GlobalCupertinoLocalizations.delegate.isSupported(locale), isTrue);
    final CupertinoLocalizations localizations = await GlobalCupertinoLocalizations.delegate.load(locale);
    expect(localizations is CupertinoLocalizationZh, true);
    expect(localizations.alertDialogLabel, '提醒');
    expect(localizations.datePickerHourSemanticsLabel(1), '1 点');
    expect(localizations.datePickerHourSemanticsLabel(12), '12 点');
    expect(localizations.pasteButtonLabel, '粘贴');
    expect(localizations.datePickerDateOrder, DatePickerDateOrder.ymd);
    expect(localizations.timerPickerSecondLabel(20), '秒');
    expect(localizations.selectAllButtonLabel, '全选');
    expect(localizations.timerPickerMinute(10), '10');
  });
}
