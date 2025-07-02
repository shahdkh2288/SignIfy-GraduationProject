import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signify_project/services/stt_preferences.dart';

class STTSettingsScreen extends ConsumerStatefulWidget {
  const STTSettingsScreen({super.key});

  @override
  ConsumerState<STTSettingsScreen> createState() => _STTSettingsScreenState();
}

class _STTSettingsScreenState extends ConsumerState<STTSettingsScreen> {
  String _selectedLanguage = 'en';
  bool _smartFormat = true;
  bool _profanityFilter = false;
  bool _showSuccess = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _fetchCurrentPreferences();
      _initialized = true;
    }
  }

  Future<void> _fetchCurrentPreferences() async {
    final notifier = ref.read(sttSettingsProvider.notifier);
    
    final prefs = await notifier.getCurrentSTTPreferences();
    if (prefs != null) {
      setState(() {
        _selectedLanguage = prefs['language'] ?? 'en';
        _smartFormat = prefs['smart_format'] ?? true;
        _profanityFilter = prefs['profanity_filter'] ?? false;
      });
    }
  }

  void _showSuccessMessage() {
    setState(() {
      _showSuccess = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSuccess = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sttState = ref.watch(sttSettingsProvider);
    return Scaffold(
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
                icon: Image.asset('assets/images/back.png', height: 36, width: 36),
              ),
              const SizedBox(height: 15),
              const Text(
                'Speech-to-Text Settings',
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
                'Language',
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
                    value: _selectedLanguage,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF005FCE)),
                    style: const TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Color(0xFF005FCE),
                    ),
                    dropdownColor: Colors.white,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(color: Color(0xFF005FCE), fontSize: 24, fontWeight: FontWeight.bold))),
                      DropdownMenuItem(value: 'ar', child: Text('Arabic', style: TextStyle(color: Color(0xFF005FCE), fontSize: 24, fontWeight: FontWeight.bold))),
                      DropdownMenuItem(value: 'es', child: Text('Spanish', style: TextStyle(color: Color(0xFF005FCE), fontSize: 24, fontWeight: FontWeight.bold))),
                      DropdownMenuItem(value: 'fr', child: Text('French', style: TextStyle(color: Color(0xFF005FCE), fontSize: 24, fontWeight: FontWeight.bold))),
                      DropdownMenuItem(value: 'de', child: Text('German', style: TextStyle(color: Color(0xFF005FCE), fontSize: 24, fontWeight: FontWeight.bold))),
                      DropdownMenuItem(value: 'it', child: Text('Italian', style: TextStyle(color: Color(0xFF005FCE), fontSize: 24, fontWeight: FontWeight.bold))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Smart Format',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontWeight: FontWeight.bold,
                          fontSize: 33,
                          color: Color(0xFF005FCE),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text(
                                'What is Smart Format?',
                                style: TextStyle(
                                  fontFamily: 'LeagueSpartan',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Color(0xFF005FCE),
                                ),
                              ),
                              content: const Text(
                                'Smart Format automatically adds punctuation and capitalization to your transcribed speech.',
                                style: TextStyle(
                                  fontFamily: 'LeagueSpartan',
                                  fontSize: 18,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Icon(Icons.info_outline, color: Color(0xFF005FCE), size: 26),
                      ),
                    ],
                  ),
                  Switch(
                    value: _smartFormat,
                    onChanged: (value) {
                      setState(() {
                        _smartFormat = value;
                      });
                    },
                    activeColor: const Color(0xFF005FCE),
                    inactiveThumbColor: Colors.grey[300],
                    inactiveTrackColor: Colors.grey[200],
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Profanity Filter',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontWeight: FontWeight.bold,
                          fontSize: 33,
                          color: Color(0xFF005FCE),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text(
                                'What is Profanity Filter?',
                                style: TextStyle(
                                  fontFamily: 'LeagueSpartan',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Color(0xFF005FCE),
                                ),
                              ),
                              content: const Text(
                                'Profanity Filter censors or removes inappropriate language from your transcribed speech.',
                                style: TextStyle(
                                  fontFamily: 'LeagueSpartan',
                                  fontSize: 18,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Icon(Icons.info_outline, color: Color(0xFF005FCE), size: 26),
                      ),
                    ],
                  ),
                  Switch(
                    value: _profanityFilter,
                    onChanged: (value) {
                      setState(() {
                        _profanityFilter = value;
                      });
                    },
                    activeColor: const Color(0xFF005FCE),
                    inactiveThumbColor: Colors.grey[300],
                    inactiveTrackColor: Colors.grey[200],
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              if (_showSuccess)
                const Text(
                  'Updated successfully',
                  style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              sttState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(
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
                      onPressed: sttState.isLoading
                          ? null
                          : () async {
                              await ref.read(sttSettingsProvider.notifier).updateSTTSettings(
                                    language: _selectedLanguage,
                                    smartFormat: _smartFormat,
                                    profanityFilter: _profanityFilter,
                                  );
                              _showSuccessMessage();
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
              const SizedBox(height: 24),
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