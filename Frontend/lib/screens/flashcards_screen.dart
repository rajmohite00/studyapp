import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/flashcard_provider.dart';
import '../app_theme.dart';
import '../widgets/animations.dart';

class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  bool _isFlipped = false;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  void _flipCard() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _rateCard(String cardId, int quality) {
    HapticFeedback.mediumImpact();
    ref.read(flashcardProvider.notifier).reviewCard(cardId, quality);
    setState(() {
      _isFlipped = false; // Reset for next card
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flashcardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Smart Flashcards',
          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: state.isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : state.dueCards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 60, color: AppColors.accentGreen),
                  const SizedBox(height: 16),
                  Text(
                    "You're all caught up!",
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Study sessions automatically\ngenerate new flashcards.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  '${state.dueCards.length} cards remaining',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                
                // The Card
                GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    height: 350,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isFlipped ? const Color(0xFFF0FDF4) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.textPrimary,
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.textPrimary,
                          offset: Offset(4, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 16,
                          right: 16,
                          child: IconButton(
                            icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                            onPressed: () {
                              _flutterTts.speak(_isFlipped ? state.dueCards.first.definition : state.dueCards.first.term);
                            },
                          ),
                        ),
                        Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isFlipped ? 'Definition' : 'Term',
                              style: GoogleFonts.outfit(
                                fontSize: 14, 
                                fontWeight: FontWeight.bold, 
                                color: _isFlipped ? AppColors.accentGreen : AppColors.primary
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _isFlipped ? state.dueCards.first.definition : state.dueCards.first.term,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: _isFlipped ? 20 : 28,
                                fontWeight: _isFlipped ? FontWeight.w500 : FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _isFlipped ? '' : 'Tap to reveal',
                              style: GoogleFonts.outfit(color: AppColors.textLight, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Buttons (Only show when flipped)
                if (_isFlipped)
                  FadeSlideIn(
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _RateButton(
                            label: 'Hard',
                            interval: '10m',
                            color: Colors.redAccent,
                            onTap: () => _rateCard(state.dueCards.first.id, 1), // 1 = wrong/hard
                          ),
                          _RateButton(
                            label: 'Good',
                            interval: '1d',
                            color: Colors.orangeAccent,
                            onTap: () => _rateCard(state.dueCards.first.id, 3), // 3 = good
                          ),
                          _RateButton(
                            label: 'Easy',
                            interval: '4d',
                            color: AppColors.accentGreen,
                            onTap: () => _rateCard(state.dueCards.first.id, 5), // 5 = perfect
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                if (!_isFlipped)
                  const SizedBox(height: 100),
              ],
            ),
    );
  }
}

class _RateButton extends StatelessWidget {
  final String label;
  final String interval;
  final Color color;
  final VoidCallback onTap;

  const _RateButton({required this.label, required this.interval, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressButton(
      scaleDown: 0.9,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              interval,
              style: GoogleFonts.outfit(
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
