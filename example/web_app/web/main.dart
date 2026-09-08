import 'dart:convert';
import 'dart:js_interop';

import 'package:shevchenko/shevchenko.dart';
import 'package:web/web.dart' as web;

Future<void> main() async {
  final engine = Shevchenko();
  String input(String id) =>
      (web.document.getElementById(id) as web.HTMLInputElement).value;
  String selected(String id) =>
      (web.document.getElementById(id) as web.HTMLSelectElement).value;
  var revision = 0;
  Future<String> update() async {
    final request = ++revision;
    String output;
    try {
      final result = await engine.inflect(
        GrammaticalCase.values.byName(selected('case')),
        DeclensionInput(
          gender: GrammaticalGender.values.byName(selected('gender')),
          givenName: input('givenName'),
          patronymicName: input('patronymicName'),
          familyName: input('familyName'),
          militaryRank: input('militaryRank'),
          militaryAppointment: input('militaryAppointment'),
        ),
      );
      output = const JsonEncoder.withIndent('  ').convert(result.toJson());
    } catch (error) {
      output = '$error';
    }
    if (request == revision)
      web.document.getElementById('output')!.textContent = output;
    return output;
  }

  web.document
      .getElementById('request')!
      .addEventListener(
        'submit',
        ((web.Event event) {
          event.preventDefault();
          update();
        }).toJS,
      );
  final initialOutput = await update();
  final model = await engine.inGenitive(
    const DeclensionInput(
      gender: GrammaticalGender.feminine,
      familyName: 'Зелена',
    ),
  );
  final nfc = await engine.inGenitive(
    const DeclensionInput(
      gender: GrammaticalGender.masculine,
      givenName: 'И\u0306осип',
    ),
  );
  if (model.familyName != 'Зеленої' ||
      nfc.givenName != 'Йосипа' ||
      !initialOutput.contains('помічника гранатометника')) {
    throw StateError('Web example mismatch');
  }
  web.document.body!.setAttribute('data-smoke', 'passed');
}
