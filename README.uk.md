# shevchenko-dart — українське відмінювання на Dart

[English](https://github.com/MqtUA/shevchenko-dart/blob/main/README.md) | **Українська**

Версія бібліотеки: **1.0.0**.

Бібліотека відмінює українські імена, по батькові, прізвища, військові звання та посади у семи відмінках і визначає граматичний рід за ім'ям або по батькові.
Це Dart порт [shevchenko.js](https://github.com/tooleks/shevchenko-js) та [shevchenko-ext-military](https://github.com/tooleks/shevchenko-ext-military).

Правила, Unicode-нормалізація й модель прізвищ працюють локально.
У браузері Dart-код компілюється у JavaScript або WebAssembly.

## Зміст

- [Вимоги та встановлення](#вимоги-та-встановлення)
- [Імпорти та перший виклик](#імпорти-та-перший-виклик)
- [Який API обрати](#який-api-обрати)
- [Flutter: повний приклад](#flutter-повний-приклад)
- [Dart Web: повний приклад](#dart-web-повний-приклад)
- [CLI: повний приклад](#cli-повний-приклад)
- [Відмінки, поля та JSON](#відмінки-поля-та-json)
- [Визначення роду](#визначення-роду)
- [Діагностика](#діагностика)
- [Помилки та порожні значення](#помилки-та-порожні-значення)
- [Map-адаптер](#map-адаптер)
- [Розширення та власний engine](#розширення-та-власний-engine)
- [Перевірки та структура репозиторію](#перевірки-та-структура-репозиторію)

## Вимоги та встановлення

Потрібен **Dart 3.11.0 або новіший у межах 3.x**. Для Flutter потрібен Flutter
SDK із відповідною версією Dart. Перевірте встановлені інструменти:

```sh
dart --version
flutter --version
```

Якщо пакет доступний на pub.dev, додайте його однією командою з папки свого
застосунку:

```sh
# Flutter-застосунок
flutter pub add shevchenko

# CLI або Dart Web
dart pub add shevchenko
```

Виконайте тільки команду для свого типу проєкту. Вона додасть актуальний
сумісний constraint у `pubspec.yaml` і завантажить залежності.

Для локальної розробки пакета або до його появи на pub.dev використовуйте
path-залежність. Наприклад, розташуйте бібліотеку та застосунок поруч:

```text
projects/
  shevchenko-dart/
    pubspec.yaml
    lib/
  my_app/
    pubspec.yaml
```

У `my_app/pubspec.yaml` додайте залежність до вже наявного блоку `dependencies`:

```yaml
environment:
  sdk: '>=3.11.0 <4.0.0'

dependencies:
  shevchenko:
    path: ../shevchenko-dart
```

Шлях обчислюється від папки **pubspec.yaml вашого застосунку**, а не від
термінала. Збережіть інші залежності, зокрема `flutter: {sdk: flutter}` у Flutter.
Після ручної зміни pubspec виконайте з папки свого застосунку:

```sh
# Flutter
flutter pub get

# Звичайний Dart / Dart Web / CLI
dart pub get
```

Використовуйте відповідну команду для свого типу проєкту. Node.js і npm не потрібні.
Початкове завантаження Dart-залежностей може потребувати мережі; саме відмінювання
після встановлення працює офлайн.

## Імпорти та перший виклик

У всіх трьох середовищах основний імпорт однаковий:

```dart
import 'package:shevchenko/shevchenko.dart' as s;
```

Назва пакета в імпорті — **shevchenko**, навіть якщо папка називається
`shevchenko-dart`. Не імпортуйте файли з `lib/src` безпосередньо.
Префікс `s` необов'язковий, але всі приклади нижче використовують його.

Повний мінімальний приклад Dart:

```dart
import 'package:shevchenko/shevchenko.dart' as s;

Future<void> main() async {
  final result = await s.inGenitive(const s.DeclensionInput(
    gender: s.GrammaticalGender.masculine,
    givenName: 'Тарас',
    patronymicName: 'Григорович',
    familyName: 'Шевченко',
    militaryRank: 'солдат',
    militaryAppointment: 'помічник гранатометника',
  ));

  print(result.givenName); // Тараса
  print(result.patronymicName); // Григоровича
  print(result.familyName); // Шевченка
  print(result.militaryRank); // солдата
  print(result.militaryAppointment); // помічника гранатометника
  print(result.toJson());
}
```

Методи повертають `Future`: отримуйте результат через `await` або `FutureBuilder`.
Жодної окремої ініціалізації моделі або реєстрації військових правил не потрібно.

## Який API обрати

| Завдання | API |
| --- | --- |
| Окремі поля імені, звання чи посади | `DeclensionInput` + `inGenitive()` або інший case-метод |
| Відмінок обирається під час виконання | `Shevchenko().inflect(grammaticalCase, input)` |
| Готовий рядок ПІБ у відомому порядку | `FullNameInput` + `inflectFullName()` |
| Список готових ПІБ | `inflectFullNames()` |
| Рід ще невідомий | `detectGender()` перед відмінюванням |
| Наявний Map/JSON-код | імпорт `shevchenko_compat.dart` |
| Власні поля або правила | окремий `Shevchenko` і `registerExtension()` |

Для більшості Flutter, Web і CLI застосунків починайте з typed API у
`shevchenko.dart`. Він перевіряється компілятором і не потребує ручної роботи з
ключами Map. Compat-адаптер призначений для межі з уже наявним JSON API.

## Flutter: повний приклад

### Створення та підключення

У папці `projects`, поруч із `shevchenko-dart`:

```sh
flutter create my_app
cd my_app
```

Додайте path-залежність, як показано вище, та виконайте `flutter pub get`.
Замініть вміст **lib/main.dart** на цей самодостатній приклад:

```dart
import 'package:flutter/material.dart';
import 'package:shevchenko/shevchenko.dart' as s;

void main() => runApp(const MaterialApp(home: DeclensionPage()));

class DeclensionPage extends StatefulWidget {
  const DeclensionPage({super.key});

  @override
  State<DeclensionPage> createState() => _DeclensionPageState();
}

class _DeclensionPageState extends State<DeclensionPage> {
  late final Future<s.DeclensionOutput> _result;

  @override
  void initState() {
    super.initState();
    // Створюємо Future один раз, а не під час кожного build().
    _result = s.inGenitive(const s.DeclensionInput(
      gender: s.GrammaticalGender.masculine,
      givenName: 'Тарас',
      patronymicName: 'Григорович',
      familyName: 'Шевченко',
      militaryRank: 'солдат',
      militaryAppointment: 'помічник гранатометника',
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Родовий відмінок')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: FutureBuilder<s.DeclensionOutput>(
        future: _result,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Не вдалося відмінити: ${snapshot.error}');
          }
          final result = snapshot.data;
          if (result == null) return const CircularProgressIndicator();
          return SelectableText([
            result.givenName,
            result.patronymicName,
            result.familyName,
            result.militaryRank,
            result.militaryAppointment,
          ].whereType<String>().join('\n'));
        },
      ),
    ),
  );
}
```

### Запуск і збірка

```sh
flutter devices
flutter run -d chrome
```

Для Android запустіть емулятор або під'єднайте пристрій і виконайте
`flutter run -d DEVICE_ID`, підставивши ID з `flutter devices`.
На Windows із налаштованим desktop toolchain доступне `flutter run -d windows`.

З папки Flutter-застосунку можна створити відповідну збірку:

```sh
flutter build apk --release
flutter build windows --release
flutter build web --release
flutter build web --wasm --release
```

Обирайте команду для потрібної платформи та встановленого toolchain.
Для Web публікуйте весь каталог `build/web`; браузерні ресурси не потрібно
додавати до assets бібліотеки. Після `--wasm` також зберігайте весь згенерований
набір файлів, а не лише `.wasm`.

Готовий приклад із цього репозиторію:

Інтерактивний застосунок має перемикач статі `М / Ж`, три поля: `Звання`, `ПІБ`,
`Посада`, кнопку `Тест` і показує об’єднаний результат у всіх семи відмінках у порядку
`звання ПІБ посада`. Порожні поля ігноруються. Для ПІБ застосунок розпізнає
обидва порядки трьох компонентів, обидва порядки імені та прізвища, а також
ім’я з по батькові. Обраний рід застосовується до всіх заповнених полів. Усі
результати можна скопіювати однією кнопкою.

```sh
cd example/flutter_app
flutter pub get
flutter test
flutter run -d chrome
```

`Future` не переносить обчислення у фоновий isolate. Для великих пакетів ПІБ
у native Flutter виконуйте пакетну обробку через `Isolate.run` або `compute`,
створюючи engine всередині worker. Окремі виклики можна використовувати як у
прикладі вище. Не запускайте відмінювання повторно з кожного `build()`.

## Dart Web: повний приклад

Це сценарій браузерного застосунку без Flutter. DOM доступний через
`package:web`; імпорт самої бібліотеки залишається незмінним.

### Створення проєкту

Створіть поруч із `shevchenko-dart` папку `my_web`, а в ній — **pubspec.yaml**:

```yaml
name: my_web
publish_to: none

environment:
  sdk: '>=3.11.0 <4.0.0'

dependencies:
  shevchenko:
    path: ../shevchenko-dart
  web: 1.1.1
```

Виконайте `dart pub get`. Створіть папку `web` і файл **web/main.dart**:

```dart
import 'dart:js_interop';
import 'package:shevchenko/shevchenko.dart' as s;
import 'package:web/web.dart' as web;

void main() {
  final name = web.document.getElementById('name') as web.HTMLInputElement;
  final output = web.document.getElementById('output')!;
  final button = web.document.getElementById('submit') as web.HTMLButtonElement;

  Future<void> inflect() async {
    button.disabled = true;
    try {
      final result = await s.inGenitive(s.DeclensionInput(
        gender: s.GrammaticalGender.masculine,
        givenName: name.value,
      ));
      output.textContent = result.givenName ?? '';
    } on s.InputValidationException catch (error) {
      output.textContent = error.message;
    } catch (error) {
      output.textContent = 'Помилка: $error';
    } finally {
      button.disabled = false;
    }
  }

  button.addEventListener('click', ((web.Event event) {
    inflect();
  }).toJS);
}
```

Поруч створіть **web/index.html**:

```html
<!doctype html>
<html lang="uk">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Відмінювання</title>
</head>
<body>
  <label>Чоловіче ім'я: <input id="name" value="Тарас"></label>
  <button id="submit" type="button">У родовий відмінок</button>
  <p id="output" aria-live="polite"></p>
  <script defer src="main.dart.js"></script>
</body>
</html>
```

### Компіляція та локальний сервер

З папки `my_web`:

```sh
dart compile js -O2 web/main.dart -o web/main.dart.js
dart run ../shevchenko-dart/tool/serve.dart web 8080
```

Відкрийте **http://127.0.0.1:8080/** і натисніть кнопку: результат — `Тараса`.
Сервер зупиняється через `Ctrl+C`. Після зміни Dart-коду повторіть компіляцію
та оновіть сторінку. Не відкривайте HTML через `file://`.

`main.dart.js` — результат Dart-компілятора, потрібний браузеру під час запуску.
Не додавайте його, source maps та `.deps` до Git. Для власного web-проєкту додайте
їх до `.gitignore`; у цьому репозиторії вони вже ігноруються. Для розгортання
подайте вміст `web/` статичним HTTP-сервером. Node.js та npm для збірки не потрібні.

Готовий розширений приклад із усіма п'ятьма полями та вибором відмінка
компілюйте в `tmp`, щоб згенерований JavaScript не лежав поруч із Dart-кодом:

```sh
dart pub get --directory example/web_app
dart analyze example/web_app
mkdir -p tmp/web-app
cp example/web_app/web/index.html tmp/web-app/index.html
cd example/web_app
dart compile js -O2 web/main.dart -o ../../tmp/web-app/main.dart.js
cd ../..
dart run tool/serve.dart tmp/web-app 8080
```

Еквівалент підготовки каталогу в PowerShell:

```powershell
New-Item -ItemType Directory -Force tmp/web-app | Out-Null
Copy-Item example/web_app/web/index.html tmp/web-app/index.html
```

У browser-коді не імпортуйте `dart:io`. Для прямого Dart/Wasm потрібен відповідний
браузерний bootstrap; звичайний HTML вище призначений для JS-компіляції. У цьому
репозиторії Wasm-перевірки бібліотеки запускаються через `dart test -p chrome -c dart2wasm`.

## CLI: повний приклад

### Створення консольного застосунку

У папці поруч із бібліотекою:

```sh
dart create -t console my_cli
cd my_cli
```

Додайте `shevchenko: {path: ../shevchenko-dart}` до `dependencies` у pubspec
(або використайте багаторядковий YAML зі встановлення вище), виконайте
`dart pub get` і замініть **bin/my_cli.dart**:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:shevchenko/shevchenko.dart' as s;

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln('Usage: my_cli masculine|feminine CASE FAMILY_NAME');
    stderr.writeln('Example: my_cli masculine genitive Шевченко');
    exitCode = 64;
    return;
  }

  try {
    final gender = s.GrammaticalGender.values.byName(args[0]);
    final grammaticalCase = s.GrammaticalCase.values.byName(args[1]);
    final result = await s.Shevchenko().inflect(
      grammaticalCase,
      s.DeclensionInput(gender: gender, familyName: args[2]),
    );
    stdout.writeln(jsonEncode(result.toJson()));
  } on s.InputValidationException catch (error) {
    stderr.writeln('${error.code}: ${error.message}');
    exitCode = 64;
  } on ArgumentError catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
  }
}
```

### Запуск із аргументами

```sh
dart run bin/my_cli.dart masculine genitive Шевченко
dart run bin/my_cli.dart feminine dative Зелена
```

Перший виклик друкує `{"familyName":"Шевченка"}`. Рядки з пробілами передавайте
одним аргументом у лапках. Зберігайте код і вхідні файли в UTF-8.
Назви `CASE` наведені в таблиці нижче.

### Самостійний executable

Спочатку створіть папку `build`, потім виконайте на цільовій ОС:

```sh
# Windows
dart compile exe bin/my_cli.dart -o build/my_cli.exe
.\build\my_cli.exe masculine genitive Шевченко

# Linux / macOS
dart compile exe bin/my_cli.dart -o build/my_cli
./build/my_cli masculine genitive Шевченко
```

Застосовуйте пару команд для своєї ОС. Executable містить runtime-дані бібліотеки
й не потребує встановленого Dart SDK для запуску. Приклад Linux/macOS описує
спосіб збірки; підтверджені локальні перевірки цього проєкту виконувалися на Windows.

Для готового демонстраційного виклику без створення нового застосунку виконайте
з кореня цього репозиторію:

```sh
dart pub get
dart run example/main.dart
```

Це бібліотека: готова глобальна команда `shevchenko` не встановлюється. CLI вище
показує, як створити команду для власного застосунку.

## Відмінки, поля та JSON

| Українська назва | Метод | `GrammaticalCase` / CLI `CASE` |
| --- | --- | --- |
| Називний | `inNominative` | `nominative` |
| Родовий | `inGenitive` | `genitive` |
| Давальний | `inDative` | `dative` |
| Знахідний | `inAccusative` | `accusative` |
| Орудний | `inAblative` | `ablative` |
| Місцевий | `inLocative` | `locative` |
| Кличний | `inVocative` | `vocative` |

Назва `inAblative` збережена для сумісності з початковим API.
Усі сім методів доступні і як top-level `s.inGenitive(input)`, і на екземплярі
`s.Shevchenko().inGenitive(input)`. Для enum використовуйте
`engine.inflect(s.GrammaticalCase.genitive, input)`.

| Поле | Значення |
| --- | --- |
| `gender` | Обов'язковий `GrammaticalGender.masculine` або `.feminine` |
| `givenName` | Ім'я |
| `patronymicName` | По батькові |
| `familyName` | Прізвище |
| `militaryRank` | Військове звання |
| `militaryAppointment` | Військова посада |

П'ять текстових полів незалежні: можна передати тільки звання або тільки ім'я.
Відмінювання потребує хоча б одного відомого чи зареєстрованого поля.
Результат `DeclensionOutput` містить передані поля без `gender`; не передані
typed-поля мають значення `null`. Текст нормалізується в NFC, але пробіли
автоматично не обрізаються. Рід задається явно; він не визначається автоматично.

Оригінальний API shevchenko.js 3.2.2 не має поля `fullName`: він приймає
`givenName`, `patronymicName` і `familyName` окремо. Dart API додатково має
`FullNameInput` для готового рядка. Формат треба вказати явно, бо рядки
`Тарас Шевченко` і `Тарас Григорович` неможливо надійно розрізнити лише за
двома словами.

```dart
import 'package:shevchenko/shevchenko.dart' as s;

final declined = await s.inflectFullName(
  s.GrammaticalCase.genitive,
  s.FullNameInput(
    fullName: 'Шевченко Тарас Григорович',
    gender: s.GrammaticalGender.masculine,
    format: s.FullNameFormat.familyGivenPatronymic,
  ),
); // Шевченка Тараса Григоровича
```

Доступні п'ять явних форматів:

| Формат | Приклад |
| --- | --- |
| `FullNameFormat.givenPatronymicFamily` | `Тарас Григорович Шевченко` |
| `FullNameFormat.familyGivenPatronymic` | `Шевченко Тарас Григорович` |
| `FullNameFormat.givenFamily` | `Тарас Шевченко` |
| `FullNameFormat.familyGiven` | `Шевченко Тарас` |
| `FullNameFormat.givenPatronymic` | `Тарас Григорович` |

`FullNameInput` прибирає пробіли на краях і розділяє компоненти за одним або
кількома whitespace-символами. Невідповідна формату кількість компонентів дає
`FormatException`; бібліотека не намагається вгадати інший формат.

`inflectFullName()` одразу повертає готовий рядок. Якщо ви вже викликали
структурований API, `input.formatOutput(output)` збере `DeclensionOutput` у
порядку, заданому цим `FullNameInput`, і повідомить про відсутній обов'язковий
компонент через `StateError`.

Для списку ПІБ використовуйте `inflectFullNames`. Кожен елемент може мати свій
формат і рід. Результати повертаються в порядку вхідного списку; обробка
зупиняється на першій помилці.

```dart
import 'package:shevchenko/shevchenko.dart' as s;

final names = <s.FullNameInput>[
  s.FullNameInput(
    fullName: 'Тарас Григорович Шевченко',
    gender: s.GrammaticalGender.masculine,
    format: s.FullNameFormat.givenPatronymicFamily,
  ),
  s.FullNameInput(
    fullName: 'Шевченко Тарас Григорович',
    gender: s.GrammaticalGender.masculine,
    format: s.FullNameFormat.familyGivenPatronymic,
  ),
  s.FullNameInput(
    fullName: 'Тарас Шевченко',
    gender: s.GrammaticalGender.masculine,
    format: s.FullNameFormat.givenFamily,
  ),
  s.FullNameInput(
    fullName: 'Шевченко Тарас',
    gender: s.GrammaticalGender.masculine,
    format: s.FullNameFormat.familyGiven,
  ),
  s.FullNameInput(
    fullName: 'Тарас Григорович',
    gender: s.GrammaticalGender.masculine,
    format: s.FullNameFormat.givenPatronymic,
  ),
];

final declinedNames = await s.inflectFullNames(
  s.GrammaticalCase.genitive,
  names,
);
// [
//   Тараса Григоровича Шевченка,
//   Шевченка Тараса Григоровича,
//   Тараса Шевченка,
//   Шевченка Тараса,
//   Тараса Григоровича,
// ]
```

Структурований API також підтримує всі ці комбінації та дає змогу самостійно
формувати результат:

```dart
final result = await s.inGenitive(const s.DeclensionInput(
  gender: s.GrammaticalGender.masculine,
  givenName: 'Тарас',
  patronymicName: 'Григорович',
  familyName: 'Шевченко',
));
final usualOrder = [
  result.givenName,
  result.patronymicName,
  result.familyName,
].whereType<String>().join(' '); // Тараса Григоровича Шевченка
final familyFirst = [
  result.familyName,
  result.givenName,
  result.patronymicName,
].whereType<String>().join(' '); // Шевченка Тараса Григоровича
```

Для JSON додайте `import 'dart:convert';` та використовуйте:

```dart
final input = s.DeclensionInput.fromJson({
  'gender': 'masculine',
  'givenName': 'Тарас',
});
final result = await s.inGenitive(input);
final jsonText = jsonEncode(result.toJson()); // {"givenName":"Тараса"}
```

Для рядка JSON: `s.DeclensionInput.fromJson((jsonDecode(text) as Map).cast<String, Object?>())`.
DTO мають структурні `==`/`hashCode`; вкладені JSON-колекції захищені від зміни.
`fromJson()` зберігає написання до engine-виклику, де відбуваються NFC-нормалізація
та перевірка зареєстрованих полів.

## Визначення роду

```dart
import 'package:shevchenko/shevchenko.dart' as s;

Future<void> main() async {
  final gender = await s.detectGender(
    const s.GenderDetectionInput(givenName: 'Оксана'),
  );
  print(gender); // GrammaticalGender.feminine
  if (gender == null) return; // Запитайте рід у користувача.
  final result = await s.inGenitive(s.DeclensionInput(
    gender: gender,
    givenName: 'Оксана',
  ));
  print(result.givenName); // Оксани
}
```

Результат — masculine, feminine або `null`. Непорожнє по батькові має пріоритет
над ім'ям. Якщо його рід невідомий, fallback до імені не відбувається.
Прізвище саме по собі не дає визначеного роду. Передавайте щонайменше одне
поле ПІБ; за невідомого роду рішення має прийняти застосунок або користувач.

## Діагностика

Коли застосунку потрібно пояснити незмінене слово або визначити використане
правило, викликайте `inflectWithDiagnostics()`:

```dart
final result = await s.inflectWithDiagnostics(
  s.GrammaticalCase.genitive,
  const s.DeclensionInput(
    gender: s.GrammaticalGender.masculine,
    givenName: 'Тарас',
  ),
);

print(result.output.givenName); // Тараса
final word = result.diagnostics['givenName']!.words.single;
print(word.status); // WordInflectionStatus.changed
print(word.ruleDescription);
```

Для кожної частини складеного імені результат розрізняє змінене слово,
незмінений результат правила, свідомо збережену частину та відсутність
відповідного правила. `detectGenderWithDiagnostics()` повертає визначений рід,
використане поле та довжини чоловічого й жіночого збігів.

## Помилки та порожні значення

- `null` у typed-конструкторі означає відсутнє поле; `toJson()` його пропускає.
- Порожній рядок `''` є переданим полем і дозволений.
- Explicit `null` для стандартного текстового поля у `fromJson()` або map API
  відхиляється; пропустіть ключ, якщо значення відсутнє.
- У JSON `gender` — рядок `masculine` чи `feminine`, а не українська назва.
- Невідомі поля не копіюються автоматично в результат; вони доступні hooks.

Перехоплюйте помилку навколо **await**, а також навколо `fromJson()`, якщо він
використовується:

```dart
try {
  await s.inGenitive(const s.DeclensionInput(
    gender: s.GrammaticalGender.masculine,
  ));
} on s.InputValidationException catch (error) {
  print(error.code); // missingFields
  print(error.message);
}
```

Коди: `invalidInput`, `invalidGender`, `missingFields`, `invalidField`.
Пошкоджений JSON може окремо спричинити `FormatException` у `jsonDecode()`;
винятки власних hooks передаються викликачеві.

## Map-адаптер

Для інтеграцій, які вже працюють із JSON/maps, є окремий імпорт:

```dart
import 'package:shevchenko/shevchenko_compat.dart' as compat;

Future<void> main() async {
  final result = await compat.inGenitive({
    'gender': 'masculine',
    'givenName': 'Тарас',
    'militaryRank': 'солдат',
  });
  print(result['givenName']); // Тараса
  print(result['militaryRank']); // солдата
  print(await compat.detectGender({'givenName': 'Оксана'})); // feminine
}
```

Сім методів повертають `Future<Map<String, Object?>>`; `detectGender` —
`Future<String?>`. Адаптер та typed top-level API використовують спільний
стандартний engine без публічної зміни його конфігурації.
`compat.Undefined.value` призначений для міграції семантики
undefined; у звичайному JSON просто пропускайте відсутні ключі.

## Розширення та власний engine

`s.Shevchenko()` вже підтримує військові поля. `s.Shevchenko.core()` створює
екземпляр без військового розширення. Його можна додати через
`engine.registerExtension(s.militaryExtension)`.

Повний приклад власного поля, включно з необхідним імпортом:

```dart
import 'package:shevchenko/shevchenko.dart' as s;

Future<void> main() async {
  final engine = s.Shevchenko();
  engine.registerExtension((context) => s.ShevchenkoExtension(
    fieldNames: ['customName'],
    afterInflect: (grammaticalCase, input) async {
      final value = input['customName'];
      if (value is! String) return null;
      return {'customName': await context.wordInflector.inflect(
        value,
        s.DeclensionParams(
          grammaticalCase: grammaticalCase,
          gender: s.GrammaticalGender.values.byName(input['gender']! as String),
        ),
      )};
    },
  ));

  final result = await engine.inGenitive(s.DeclensionInput.withCustomFields(
    gender: s.GrammaticalGender.masculine,
    customFields: {'customName': 'Тарас'},
  ));
  print(result.customFields['customName']); // Тараса
}
```

Кожний engine має окремий реєстр. Hooks виконуються послідовно, отримують
нормалізований read-only input, а пізніший результат може перекрити попередні
поля. Повторна реєстрація означає повторний виклик. Виняток зупиняє pipeline.
Реєстр і вкладені JSON-дані фіксуються до першого `await`; їхні подальші зміни
не змінюють запит, який уже виконується.

Для власних правил доступні `WordInflector`, `DeclensionRule`, `DeclensionPattern`,
`InflectionCommand`, `InflectionCommandAction`, `DeclensionParams`, `ApplicationType`,
`WordClass`, `CustomRuleFilter`. `WordInflector` отримує immutable-правила;
однаковий priority зберігає порядок джерела. Фільтр викликається для всіх кандидатів.
Група `0` в команді означає першу regex capture group. Деталі поведінки й межі
сумісності описані у [COMPATIBILITY.md](doc/COMPATIBILITY.md).

## Перевірки та структура репозиторію

З кореня репозиторію:

```sh
dart pub get --enforce-lockfile
dart run tool/check_repository.dart
dart run tool/check_format.dart
dart analyze --fatal-infos
dart run tool/verify_artifacts.dart --check
dart test
dart test -p chrome
dart test -p chrome -c dart2wasm
```

Браузерні тести потребують Chrome. Повний корпус запускається окремо:
`dart test tool/full_test.dart -p vm`; для JS — `-p chrome`, для Wasm —
`-p chrome -c dart2wasm`, для native AOT — `-p vm -c exe`.

| Каталог | Призначення |
| --- | --- |
| `lib/` | Публічний API та pure Dart реалізація |
| `example/` | Робочі CLI, Flutter і Dart Web приклади |
| `test/` | Тести та їхні постійні еталонні fixtures |
| `tool/` | Dart-інструменти перевірки та генерації |
| `tool/data/` | Лише вхідні дані Dart-генератора з хешами джерел |
| `benchmark/` | Відтворюваний Dart benchmark |
| `doc/` | Документація сумісності й розробки |
| `tmp/` | Локальні тимчасові файли й результати виконання; не входить у Git |

JavaScript/TypeScript джерела, Node-залежності, звіти й результати збірок не
входять у репозиторій. Fixtures та JSON-дані генератора потрібні для тестів і
відтворення Dart-таблиць: це постійні входи перевірок, а не звіти.
Робота з генератором і тестами описана у [DEVELOPMENT.md](doc/DEVELOPMENT.md).

Бібліотека зберігає поведінку початкового runtime, включно з його мовними
особливостями; вона не є окремим редактором української мови.

## Ліцензія

MIT. Ліцензія пакета — [LICENSE](LICENSE); авторство вихідних бібліотек, правила,
ваги та використані дані — [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
