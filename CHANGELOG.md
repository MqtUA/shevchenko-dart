# 1.0.0

- Added a stable typed API for all seven Ukrainian grammatical cases.
- Added full-name parsing with explicit component layouts and ordered batch
  processing.
- Added field and word-level inflection diagnostics, including selected rule
  descriptions and unchanged-word reasons.
- Added gender detection diagnostics with the selected input source and pattern
  match lengths.
- Kept extension registration local to each `Shevchenko` instance to prevent
  shared global configuration changes.
- Included military rank and appointment declension by default, with a
  core-only engine available through `Shevchenko.core()`.
- Added the separate `shevchenko_compat.dart` entrypoint for Map and JSON
  integrations.
- Added NFC normalization, immutable extension inputs, typed validation errors,
  and defensive DTO ownership.
- Snapshotted nested extension outputs and rejected raw maps with non-string
  keys to keep asynchronous calls deterministic.
- Replaced runtime JSON parsing of generated declension rules with pre-parsed
  constant Dart data.
- Added release CI across the minimum and stable Dart SDKs, including VM,
  JavaScript, WebAssembly, full-corpus, artifact, and package checks.
- Added English and Ukrainian package documentation, native, web, and Flutter
  examples, reproducible benchmarks, and cross-runtime parity fixtures.
