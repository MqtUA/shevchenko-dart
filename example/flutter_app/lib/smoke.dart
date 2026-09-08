import 'package:shevchenko/shevchenko.dart' as s;

/// Real library calls shared by the app and its widget test.
Future<Map<String, Object?>> runExample() async {
  final result = await s.inGenitive(
    const s.DeclensionInput(
      gender: s.GrammaticalGender.masculine,
      givenName: 'Тарас',
      patronymicName: 'Григорович',
      familyName: 'Шевченко',
      militaryRank: 'солдат',
      militaryAppointment: 'помічник гранатометника',
    ),
  );
  if (result.givenName != 'Тараса' ||
      result.patronymicName != 'Григоровича' ||
      result.familyName != 'Шевченка' ||
      result.militaryRank != 'солдата' ||
      result.militaryAppointment != 'помічника гранатометника') {
    throw StateError('Combined example mismatch');
  }
  final normalized = await s.inGenitive(
    const s.DeclensionInput(
      gender: s.GrammaticalGender.masculine,
      givenName: 'И\u0306осип',
    ),
  );
  final modeled = await s.inGenitive(
    const s.DeclensionInput(
      gender: s.GrammaticalGender.feminine,
      familyName: 'Зелена',
    ),
  );
  if (normalized.givenName != 'Йосипа' || modeled.familyName != 'Зеленої') {
    throw StateError('NFC/model example mismatch');
  }
  return result.toJson();
}
