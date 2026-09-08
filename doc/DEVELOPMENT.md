# Розробка та перевірки

У репозиторії підтримуються Dart-код, приклади, тести та потрібні їм дані.
Node.js, npm і JS/TS-джерела для роботи з ним не потрібні.
Інструкції інтеграції у застосунки наведені в [README](../README.md).

## Підготовка

Використовуйте Dart 3.11.0+ у межах 3.x. З кореня:

Мінімальний SDK узгоджений з актуальним `test`, який потребує Dart 3.11.
Обмеження 3.13.1 було прив'язане до початкового середовища перевірки,
а не до специфічного API реалізації. Dart 3.11.0 і stable перевірені локально.

```sh
dart pub get --enforce-lockfile
dart run tool/check_repository.dart
dart run tool/check_format.dart
dart analyze --fatal-infos
dart test
```

Приклади Flutter і Web мають власні pubspec/lockfile. Виконуйте `flutter pub get`
або `dart pub get`, format, analyze та тести окремо в їхніх каталогах.
У бібліотеці імпортуйте публічний API, а не `lib/src`.

## Правила та модель

`tool/data/` містить тільки 11 потрібних генератору файлів: правила, гендерні
патерни, винятки прізвищ, військові правила, модель і її початкові ваги.
`manifest.json` зберігає їхні початкові шляхи, commits, розміри й SHA-256.
Це вхідні дані збірки, які повинні залишатися у Git.

Джерела: shevchenko.js 3.2.2, commit
`e99c64c4e3771d7477116fc3fec7d2f099cc0cb3`, та military extension
0.0.0-beta.3; точний commit кожного файла записаний у manifest.
Авторство й ліцензії збережені у `THIRD_PARTY_NOTICES.md`.

```sh
dart run tool/generate_data.dart --check
dart run tool/generate_data.dart
```

Перша команда перевіряє хеші, розгортання макросів, порядок правил, форму й
байти ваг та збіг із `lib/src/generated/data.dart`. Друга відтворює файл.
Не редагуйте generated-таблиці вручну і не оновлюйте хеші лише для приховування
розбіжності. Зміна джерел потребує перевірки очікуваної поведінки.

## Fixtures та браузерні тести

JSON-fixtures містять зафіксовані очікувані результати. Їхні Dart-представлення
дозволяють виконувати ті самі перевірки без файлової системи у браузері та AOT.
Unicode conformance source і ліцензія лежать у `test/fixtures/unicode/`.

```sh
dart run tool/embed_fixtures.dart --check
dart run tool/embed_unicode.dart --check
dart run tool/embed_full.dart --check
dart test -p chrome
dart test -p chrome -c dart2wasm
```

Щоб відтворити embedded-файли, повторіть відповідну команду без `--check`.
Для Chrome можна задати `CHROME_EXECUTABLE`, якщо браузер встановлено нестандартно.

### Що саме доводять тести

Очікувані результати не обчислюються поточною Dart-реалізацією під час тесту:

- `golden.json` містить 9 797 повних результатів і помилок, записаних із
  зафіксованого upstream runtime;
- `rules.json` містить 924 приклади й перевіряє кожне з 99 правил у всіх семи
  відмінках ізольовано;
- `classifier.json` та `layers.json` звіряють векторизацію, score, клас і всі
  20 × 16 проміжних станів моделі;
- `full.json` містить 101 302 унікальні слова; повний тест перевіряє 1 418 228
  викликів, а результати кожної тисячі слів — незалежним SHA-256;
- Unicode-тест використовує офіційний `NormalizationTest.txt`, а ручні
  regression-тести фіксують API, concurrency, immutable snapshots і поширені
  комбінації ПІБ.

`fixture_integrity_test.dart` фіксує кількість записів, унікальні ID, набір
операцій, provenance, розміри тензорів, усі правила та відмінки. Окремі негативні
тести пошкоджують копії metadata й перевіряють, що пропущений рядок, дубль,
перекритий shard або неправильний hash не можуть пройти непомітно.

Після змін engine, моделі або даних виконайте повний корпус:

```sh
dart test tool/full_test.dart -p vm
dart test tool/full_test.dart -p vm -c exe
dart test tool/full_test.dart -p chrome
dart test tool/full_test.dart -p chrome -c dart2wasm
```

Ці команди порівнюють результат із зафіксованими очікуваннями без запуску
JavaScript-реалізації. Оновлюйте очікувані результати тільки після незалежної
перевірки першоджерела. Локальні інструменти для такої перевірки зберігайте
поза Git у `tmp/`.

## Приклади, benchmarks і тимчасові файли

Для статичного web-прикладу компілюйте вихідні файли в ігнорований `tmp/`, а
потім запускайте loopback-сервер:

```sh
mkdir -p tmp/web-app
cp example/web_app/web/index.html tmp/web-app/index.html
cd example/web_app
dart compile js -O2 web/main.dart -o ../../tmp/web-app/main.dart.js
cd ../..
dart run tool/serve.dart tmp/web-app 8080
```

Після компіляції прикладу та запуску сервера перевірка його початкового
результату виконується через `dart run tool/browser_smoke.dart http://127.0.0.1:8080/`.
У разі помилки Chrome profile та діагностика залишаються в
`tmp/browser-smoke/`; після успішної перевірки профіль видаляється.

Для повного JIT-звіту з allocation counters та heap usage потрібен VM Service.
`--no-dds` не запускає окремий DevTools service. Створіть `tmp/benchmark`, потім
виконайте:

```sh
dart --enable-vm-service=0 --disable-service-auth-codes --no-dds --define=BENCHMARK_MODE=jit-vm benchmark/main.dart --output=tmp/benchmark/vm-jit.json
dart compile exe --define=BENCHMARK_MODE=aot benchmark/main.dart -o tmp/benchmark/run.exe
./tmp/benchmark/run.exe --output=tmp/benchmark/vm-aot.json
```

На Unix можна прибрати розширення `.exe`. Порівнюйте вимірювання на однаковій
машині, SDK і режимі збірки. Benchmark окремо подає cold call, median/p95,
кількість виділених об'єктів і байтів для 1 000 викликів, а також вісім серій
по 10 000 викликів. Після кожної JIT-серії VM Service виконує GC; звіт містить
heap/RSS кожної серії та розкид останніх трьох точок. AOT не має VM Service
allocation counters, тому його звіт містить timing і RSS plateau.

Для локального звіту розмірів виконайте publish dry-run, скомпілюйте Web-приклад
і запустіть `tool/size_report.dart`. Він створює JSON із розміром package,
JavaScript bundle до/після gzip та AOT executable. Самі звіти зберігайте в
`tmp/` і не додавайте до Git.

## GitHub releases

`.github/workflows/ci.yml` не запускає тести, аналіз, збірки або benchmarks.
Після push у default branch workflow порівнює `version:` у поточному
`pubspec.yaml` із версією до push. Якщо версія не змінилася, workflow завершує
роботу без release. Перший push гілки, для якого попереднього `pubspec.yaml`
немає, вважає поточну версію новою.

Для нової версії створюється GitHub Release і тег `v<version>`. Release notes
містять усі commit subjects та короткі hashes після попереднього GitHub Release;
для першого release — всю доступну історію. Повторний запуск не створює release,
якщо такий тег уже має GitHub Release. Перевірки перед push запускає розробник
локально командами з цього документа.

Усі локальні звіти, скриншоти, профілі та результати вимірювань зберігайте в
`tmp/`. `build/`, `.dart_tool/` і кеші є ігнорованими каталогами інструментів.
У `doc/` додавайте документацію користувача/розробника, а не логи виконання.
`tool/check_repository.dart` відхиляє JS/TS та службові файли серед tracked
і нових файлів, які можуть потрапити до коміту.

## Пакування

```sh
dart run tool/check_package.dart
```

Команда виконує publish dry-run. Наразі вона допускає одне попередження:
відсутній URL репозиторію. Інші попередження й помилки відхиляються. Перед
публікацією додайте справжній URL і перевірте metadata.
