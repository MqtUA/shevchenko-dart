# Compatibility contract

The behavioral reference is the pinned **core 3.2.2 + military beta.3** pair with
military registered once and TensorFlow.js **CPU 4.22.0**. It is not the older
core 3.1.4 selected by the military repository's lockfile.

## Preserved behavior

All five standard fields, seven case wire values and both gender values are
preserved. `ablative` is the upstream name for Ukrainian instrumental.
Validation order is object → gender → present fields → field types. Empty
strings are present; explicit null is invalid; undefined is skipped. Arrays
pass the JS object check and subsequently fail missing gender/fields.

Only known input fields are NFC-normalized, after validation, in a new object.
No trim, space collapse, apostrophe unification or dash conversion occurs.
WordInflector itself does not normalize. Strings and suffix encoding use UTF-16
code units. Regex flags retain case-insensitive ECMAScript behavior.

Equal-priority rules retain their source order. All custom-filter callbacks
execute on the prefiltered candidate list. Only the first command alternative
is used. An unmatched optional capture coerces to `undefined`, as in JS string
concatenation. Rules without captures can replace a match with an empty string.

Compound names split only on ASCII hyphens. A non-final monosyllabic surname
part is unchanged. Classifier conditions, frozen overrides, gender precedence,
and ties favoring feminine are preserved. Military splits only ASCII spaces;
hyphenation precedes delimiter extraction; military rules supply their own
gender. Leading multiple ASCII delimiters preserve upstream's one-unit slice
quirk. There are 12 handwritten military conflicts; see
`test/fixtures/upstream-conflicts.json`.

Hooks receive normalized input, run sequentially, and merge in registration
order after name results. A later hook may override name fields. Missing hooks
and null hook outputs are valid; an exception stops the pipeline. Duplicate
registration is not ignored. Unknown input keys are retained for hooks only.

## Dart adaptations and exclusions

| JavaScript | Dart |
| --- | --- |
| Promise | Future; errors complete the Future |
| String enums | Enum `.name` retains each wire value |
| absent/undefined | Typed null omits; raw adapter also accepts `Undefined.value` |
| `InputValidationError` / TypeError | `InputValidationException` with exact message and stable code |
| global extension registry | Registry per instance; top-level calls use a fixed shared default |
| mutable extension input | Read-only defensive copies of JSON maps/lists |
| arbitrary hook results | Raw maps preserve values; typed output checks standard String fields and rejects gender |
| no `fullName` input or batch API | `FullNameInput` with an explicit format; ordered `inflectFullNames` convenience API |

Validation codes are `invalidInput`, `invalidGender`, `missingFields`, and
`invalidField`. Invalid typed custom-rule schemas produce Dart ArgumentError,
FormatException or StateError; exact JS exception classes for malformed custom
rules are outside the contract. In particular, copying nonempty case output
from an empty custom-rule template throws StateError instead of JS TypeError.

JS prototypes, inherited properties, getters, Proxy, function-valued inputs,
exact stacks, mutable/cyclic custom objects and hook registration during an
in-flight operation are excluded. Registry changes apply to subsequent calls.
Non-JSON arbitrary Dart objects are not deep-cloned. Locale-specific casing
outside the pinned oracle locale is not claimed. Exact parity is established
for the documented corpus, not mathematically for every possible Unicode string
or every TensorFlow backend. No linguistic corrections were introduced.

The full-name convenience API is outside behavioral parity. It trims the whole
string, splits it on one or more whitespace characters, and requires one of five
explicit layouts. This prevents heuristic confusion between given-name + family
name and given-name + patronymic inputs. Batch calls run sequentially, retain
input order, and stop on the first error. Each parsed item is then processed by
the same parity-covered structured engine.

The README lists the tested platforms and their integration instructions.
