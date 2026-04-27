import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ai_coach_provider.dart';

class VoiceAgentState {
  final bool isListening;
  final String recognizedText;
  final bool isSpeaking;
  
  const VoiceAgentState({
    this.isListening = false,
    this.recognizedText = '',
    this.isSpeaking = false,
  });
  
  VoiceAgentState copyWith({
    bool? isListening,
    String? recognizedText,
    bool? isSpeaking,
  }) {
    return VoiceAgentState(
      isListening: isListening ?? this.isListening,
      recognizedText: recognizedText ?? this.recognizedText,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }
}

class VoiceAgentNotifier extends StateNotifier<VoiceAgentState> {
  final Ref _ref;
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _speechEnabled = false;

  VoiceAgentNotifier(this._ref) : super(const VoiceAgentState()) {
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      if (mounted) state = state.copyWith(isSpeaking: false);
    });
  }

  Future<void> startListening() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;

    if (!_speechEnabled) {
      _speechEnabled = await _speechToText.initialize();
    }

    if (_speechEnabled) {
      state = state.copyWith(isListening: true, recognizedText: '');
      await _flutterTts.stop();
      state = state.copyWith(isSpeaking: false);
      
      await _speechToText.listen(
        onResult: (result) {
          if (mounted) state = state.copyWith(recognizedText: result.recognizedWords);
        },
      );
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    state = state.copyWith(isListening: false);
    
    if (state.recognizedText.isNotEmpty) {
      final textToSend = state.recognizedText;
      state = state.copyWith(recognizedText: '');
      
      // Send to AI Coach
      final aiNotifier = _ref.read(aiCoachProvider.notifier);
      await aiNotifier.sendMessage(textToSend);
      
      // After sending, speak the latest message
      if (!mounted) return;
      final aiState = _ref.read(aiCoachProvider);
      if (aiState.messages.isNotEmpty && !aiState.isLoading && aiState.error == null) {
        final lastMsg = aiState.messages.last;
        if (!lastMsg.isUser) {
           speak(lastMsg.content);
        }
      }
    }
  }

  Future<void> speak(String text) async {
    // Remove emojis before speaking so TTS doesn't say "rocket ship emoji"
    final cleanText = text.replaceAll(RegExp(r'[^\x00-\x7F]+'), '');
    state = state.copyWith(isSpeaking: true);
    await _flutterTts.speak(cleanText);
  }
  
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    state = state.copyWith(isSpeaking: false);
  }
}

final voiceAgentProvider = StateNotifierProvider<VoiceAgentNotifier, VoiceAgentState>((ref) {
  return VoiceAgentNotifier(ref);
});
