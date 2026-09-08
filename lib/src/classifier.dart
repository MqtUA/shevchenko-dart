import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'generated/data.dart';
import 'language.dart';

/// Fixed 20-step Embedding / SimpleRNN(ReLU) / Dense(sigmoid) inference.
final class FamilyNameClassifier {
  static const _alphabet = 'абвгґдеєжзиіїйклмнопрстуфхцчшщьюя';
  static final _weights = _decodeWeights();
  static Float32List _decodeWeights() {
    final bytes = base64Decode(modelWeights);
    final data = ByteData.sublistView(bytes);
    return Float32List.fromList([
      for (var i = 0; i < bytes.length; i += 4)
        data.getFloat32(i, Endian.little),
    ]);
  }

  Uint8List encode(String word) {
    final suffix = word
        .substring(math.max(0, word.length - 20))
        .toLowerCase()
        .padLeft(20, '-');
    return Uint8List.fromList([
      for (var i = 0; i < 20; i++) _alphabet.indexOf(suffix[i]) + 1,
    ]);
  }

  WordClass classify(String word) {
    final override = surnameOverrides[word.toLowerCase()];
    return override == null
        ? decode(score(word))
        : WordClass.values.byName(override);
  }

  static WordClass decode(double score) =>
      score >= 0.5 ? WordClass.noun : WordClass.adjective;

  double score(String word, {List<List<double>>? states}) {
    final weights = _weights;
    var state = Float32List(16);
    final rounded = Float32List(1);
    double f32(double value) {
      rounded[0] = value;
      return rounded[0];
    }

    for (final letter in encode(word)) {
      final next = Float32List(16);
      for (var j = 0; j < 16; j++) {
        var inputDot = 0.0;
        var recurrentDot = 0.0;
        for (var k = 0; k < 16; k++) {
          inputDot += weights[letter * 16 + k] * weights[544 + k * 16 + j];
          recurrentDot += state[k] * weights[800 + k * 16 + j];
        }
        final biased = f32(f32(inputDot) + weights[1056 + j]);
        next[j] = math.max(0, f32(biased + f32(recurrentDot)));
      }
      state = next;
      states?.add(state.toList());
    }
    var dense = 0.0;
    for (var i = 0; i < 16; i++) {
      dense += state[i] * weights[1072 + i];
    }
    final logit = f32(f32(dense) + weights[1088]);
    return f32(1 / (1 + math.exp(-logit)));
  }
}
