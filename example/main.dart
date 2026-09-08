import 'package:shevchenko/shevchenko.dart' as shevchenko;

Future<void> main() async {
  final result = await shevchenko.inGenitive(
    const shevchenko.DeclensionInput(
      gender: shevchenko.GrammaticalGender.masculine,
      givenName: 'Тарас',
      patronymicName: 'Григорович',
      familyName: 'Шевченко',
      militaryRank: 'солдат',
      militaryAppointment: 'помічник гранатометника',
    ),
  );
  print(result.toJson());
}
