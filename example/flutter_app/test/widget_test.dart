import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shevchenko/shevchenko.dart' as s;
import 'package:shevchenko_example/declension_demo.dart';
import 'package:shevchenko_example/main.dart';
import 'package:shevchenko_example/smoke.dart';

void main() {
  testWidgets('shows three inputs and all seven combined results', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text('Звання'), findsOneWidget);
    expect(find.text('ПІБ'), findsOneWidget);
    expect(find.text('Посада'), findsOneWidget);
    expect(find.text('Стать'), findsOneWidget);
    expect(find.text('М'), findsOneWidget);
    expect(find.text('Ж'), findsOneWidget);
    expect(find.text('Тест'), findsOneWidget);

    await tester.tap(find.byKey(const Key('testButton')));
    await tester.pumpAndSettle();

    const expected = {
      'Називний': 'солдат Тарас Григорович Шевченко помічник гранатометника',
      'Родовий': 'солдата Тараса Григоровича Шевченка помічника гранатометника',
      'Давальний':
          'солдату Тарасу Григоровичу Шевченку помічнику гранатометника',
      'Знахідний':
          'солдата Тараса Григоровича Шевченка помічника гранатометника',
      'Орудний':
          'солдатом Тарасом Григоровичем Шевченком помічником гранатометника',
      'Місцевий':
          'солдатові Тарасові Григоровичу Шевченкові помічникові гранатометника',
      'Кличний': 'солдате Тарасе Григоровичу Шевченку помічнику гранатометника',
    };
    for (final entry in expected.entries) {
      final result = find.byKey(ValueKey('result:${entry.key}'));
      expect(result, findsOneWidget);
      expect(tester.widget<Text>(result).data, entry.value);
    }
  });

  testWidgets('empty fields are omitted from the combined result', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.enterText(find.byKey(const Key('rankText')), '');
    await tester.enterText(find.byKey(const Key('appointmentText')), '');
    await tester.enterText(
      find.byKey(const Key('fullNameText')),
      'Тарас Шевченко',
    );
    await tester.tap(find.byKey(const Key('testButton')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('result:Родовий'))).data,
      'Тараса Шевченка',
    );
  });

  testWidgets('shows a useful message when every field is empty', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.enterText(find.byKey(const Key('rankText')), '');
    await tester.enterText(find.byKey(const Key('fullNameText')), '');
    await tester.enterText(find.byKey(const Key('appointmentText')), '');
    await tester.tap(find.byKey(const Key('testButton')));
    await tester.pumpAndSettle();

    expect(find.text('Заповніть хоча б одне поле.'), findsOneWidget);
  });

  test('supports every requested full-name layout', () async {
    final cases = {
      'Тарас Григорович Шевченко': 'Тараса Григоровича Шевченка',
      'Шевченко Тарас Григорович': 'Шевченка Тараса Григоровича',
      'Тарас Шевченко': 'Тараса Шевченка',
      'Шевченко Тарас': 'Шевченка Тараса',
      'Тарас Григорович': 'Тараса Григоровича',
    };
    for (final entry in cases.entries) {
      final result = await declineAllCases(
        rank: '',
        fullName: entry.key,
        appointment: '',
        gender: s.GrammaticalGender.masculine,
      );
      expect(result['Родовий'], entry.value);
    }
  });

  test('each optional input works independently', () async {
    const cases = [
      (rank: 'солдат', fullName: '', appointment: '', expected: 'солдата'),
      (
        rank: '',
        fullName: 'Тарас Шевченко',
        appointment: '',
        expected: 'Тараса Шевченка',
      ),
      (
        rank: '',
        fullName: '',
        appointment: 'помічник гранатометника',
        expected: 'помічника гранатометника',
      ),
    ];
    for (final input in cases) {
      final result = await declineAllCases(
        rank: input.rank,
        fullName: input.fullName,
        appointment: input.appointment,
        gender: s.GrammaticalGender.masculine,
      );
      expect(result['Родовий'], input.expected);
    }
  });

  testWidgets('selected female gender controls every declined field', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.text('Ж'));
    await tester.enterText(find.byKey(const Key('rankText')), 'солдат');
    await tester.enterText(
      find.byKey(const Key('fullNameText')),
      'Олена Іванівна Зелена',
    );
    await tester.enterText(
      find.byKey(const Key('appointmentText')),
      'помічник гранатометника',
    );
    await tester.tap(find.byKey(const Key('testButton')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('result:Родовий'))).data,
      'солдата Олени Іванівни Зеленої помічника гранатометника',
    );
  });

  test('platform smoke calls still cover combined package behavior', () async {
    final result = await runExample();
    expect(result['militaryAppointment'], 'помічника гранатометника');
  });
}
