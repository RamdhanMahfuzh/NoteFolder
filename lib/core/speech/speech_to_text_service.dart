import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextService {
  SpeechToTextService._();

  static final instance = SpeechToTextService._();

  final SpeechToText _speech = SpeechToText();
  final _status = StreamController<String>.broadcast();
  final _errors = StreamController<SpeechRecognitionError>.broadcast();
  bool _initialized = false;

  Stream<String> get status => _status.stream;
  Stream<SpeechRecognitionError> get errors => _errors.stream;
  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onStatus: _status.add,
      onError: _errors.add,
    );
    return _initialized;
  }

  Future<void> listen(void Function(SpeechRecognitionResult) onResult) =>
      _speech.listen(onResult: onResult);

  Future<void> stop() => _speech.stop();
}
