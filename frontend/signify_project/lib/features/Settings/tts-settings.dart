import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signify_project/services/tts_preferences.dart';

class TTSSettingsScreen extends ConsumerStatefulWidget {
  const TTSSettingsScreen({super.key});

  @override
  ConsumerState<TTSSettingsScreen> createState() => _TTSSettingsScreenState();
}

class _TTSSettingsScreenState extends ConsumerState<TTSSettingsScreen> {
  String _selectedVoiceId = 'female';
  double _stability = 0.5;
  bool _showSuccess = false;

  String _getStabilityDescription() {
    if (_stability <= 0.2) {
      return "Maximum emotion - Very expressive and natural tone";
    } else if (_stability <= 0.4) {
      return "High emotion - Expressive with some variation";
    } else if (_stability <= 0.6) {
      return "Balanced - Good mix of emotion and clarity";
    } else if (_stability <= 0.8) {
      return "High clarity - Consistent and stable pronunciation";
    } else {
      return "Maximum clarity - Very stable and clear speech";
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final notifier = ref.read(ttsSettingsProvider.notifier);
    final prefs = await notifier.fetchTTSPreferences();
    if (prefs != null) {
      setState(() {
        _selectedVoiceId = prefs['voice_id'] ?? 'female';
        _stability = (prefs['stability'] ?? 0.5).toDouble().clamp(0.0, 1.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ttsState = ref.watch(ttsSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              IconButton(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                icon: Image.asset(
                  'assets/images/back.png',
                  height: 36,
                  width: 36,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Text-to-Speech Settings',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Colors.black,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Voice type',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontWeight: FontWeight.bold,
                  fontSize: 33,
                  color: Color(0xFF005FCE),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF005FCE), width: 2.2),
                ),
                alignment: Alignment.centerLeft,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedVoiceId,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF005FCE),
                    ),
                    style: const TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Color(0xFF005FCE),
                    ),
                    dropdownColor: Colors.white,
                    items: const [
                      DropdownMenuItem(
                        value: 'female',
                        child: Text(
                          'Female',
                          style: TextStyle(
                            color: Color(0xFF005FCE),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'male',
                        child: Text(
                          'Male',
                          style: TextStyle(
                            color: Color(0xFF005FCE),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedVoiceId = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 80),
              Row(
                children: [
                  const Text(
                    'Emotion vs Clearness',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontWeight: FontWeight.bold,
                      fontSize: 33,
                      color: Color(0xFF005FCE),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text(
                                'Emotion vs Clearness',
                                style: TextStyle(
                                  fontFamily: 'LeagueSpartan',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Color(0xFF005FCE),
                                ),
                              ),
                              content: const Text(
                                'This setting controls the balance between emotional expression and speech clarity:\n\n'
                                '• Move toward "Emotion" for more expressive, natural-sounding speech with varied tone\n\n'
                                '• Move toward "Clearness" for more consistent, stable pronunciation that\'s easier to understand\n\n'
                                'Find the balance that works best for you!',
                                style: TextStyle(
                                  fontFamily: 'LeagueSpartan',
                                  fontSize: 18,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Got it!'),
                                ),
                              ],
                            ),
                      );
                    },
                    child: const Icon(
                      Icons.info_outline,
                      color: Color(0xFF005FCE),
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Emotion',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 16,
                          color: Color(0xFF005FCE),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF005FCE),
                            inactiveTrackColor: const Color(0xFFE3F1FB),
                            thumbColor: const Color(0xFF005FCE),
                            overlayColor: const Color(0x33005FCE),
                            trackHeight: 5,
                          ),
                          child: Slider(
                            value: _stability.clamp(0.0, 1.0),
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            label: _stability.toStringAsFixed(2),
                            onChanged: (value) {
                              setState(() {
                                _stability = value;
                              });
                            },
                          ),
                        ),
                      ),
                      const Text(
                        'Clearness',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 16,
                          color: Color(0xFF005FCE),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStabilityDescription(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 16,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              Center(
                child: Text(
                  _stability.toStringAsFixed(2),
                  style: const TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_showSuccess)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Preferences updated successfully!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'LeagueSpartan',
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ttsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (e, _) => Text(
                      e.toString(),
                      style: const TextStyle(color: Colors.red),
                    ),
                data: (data) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 70),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          ttsState.isLoading
                              ? null
                              : () async {
                                await ref
                                    .read(ttsSettingsProvider.notifier)
                                    .updateTTSSettings(
                                      selectedVoiceId: _selectedVoiceId,
                                      stability: _stability,
                                    );
                                setState(() {
                                  _showSuccess = true;
                                });

                                // Auto-hide success message after 3 seconds
                                Timer(const Duration(seconds: 3), () {
                                  if (mounted) {
                                    setState(() {
                                      _showSuccess = false;
                                    });
                                  }
                                });

                                await _loadPreferences();
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005FCE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 2,
                        textStyle: const TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'LeagueSpartan',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        height: 70,
        decoration: const BoxDecoration(
          color: Color(0xFF005FCE),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/home');
                },
                child: Image.asset(
                  'assets/images/home.png',
                  width: 59,
                  height: 52,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
                child: Image.asset(
                  'assets/images/settings.png',
                  width: 56,
                  height: 60,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: Image.asset(
                  'assets/images/user.png',
                  width: 58,
                  height: 58,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
