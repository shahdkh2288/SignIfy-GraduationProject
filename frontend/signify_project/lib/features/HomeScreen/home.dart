import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:signify_project/services/tts_service.dart';
import 'package:signify_project/services/stt_service.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late TextEditingController _controller;
  late AudioPlayer _player;
  final record = AudioRecorder();

  bool _isListening = false;
  String? _recordedFilePath;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(inputTextProvider));
    _player = AudioPlayer();

    _controller.addListener(() {
      if (_controller.text != ref.read(inputTextProvider)) {
        ref.read(inputTextProvider.notifier).state = _controller.text;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    record.dispose(); 
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await record.hasPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied')),
      );
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/recorded.m4a';
    _recordedFilePath = filePath;

    try {
      await record.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: filePath,
      );
      setState(() => _isListening = true);
    } catch (e) {
      print("Recording error: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await record.stop();
      setState(() => _isListening = false);

      if (path != null && File(path).existsSync()) {
        final audioFile = File(path);
        final transcript = await STTService.sendAudioForTranscription(audioFile);

        if (transcript != null) {
          ref.read(sttTextProvider.notifier).state = transcript;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to transcribe audio')),
          );
        }
      }
    } catch (e) {
      print("Stop recording error: $e");
    }
  }

  

  Future<void> _playAudio(String url) async {
    try {
      await _player.stop();
      await Future.delayed(const Duration(milliseconds: 500));
      await _player.setSource(UrlSource(url));
      await _player.resume();
    } catch (e) {
      print('Audio error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio playback failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(userNameProvider);
    final inputText = ref.watch(inputTextProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final sttText = ref.watch(sttTextProvider);

    if (_controller.text != inputText) {
      _controller.text = inputText;
      _controller.selection = TextSelection.collapsed(offset: inputText.length);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, ${userName.isNotEmpty ? userName : "User"}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'LeagueSpartan',
                          color: Color(0xFF005FCE),
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.person, size: 80, color: Color(0xFF005FCE)),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Input Card
              SizedBox(
                height: 180,
                child: Card(
                  color: Colors.blue.shade50,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: TextField(
                                  maxLength: 750,
                                  maxLines: null,
                                  expands: true,
                                  controller: _controller,
                                  decoration: const InputDecoration(
                                    hintText: "Enter text here...",
                                    border: InputBorder.none,
                                    counterText: '',
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                '${inputText.length}/750',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.volume_up),
                                onPressed: inputText.isEmpty || isLoading
                                    ? null
                                    : () async {
                                        ref.read(isLoadingProvider.notifier).state = true;
                                        final url = await TTSService.getTtsAudioUrl(inputText);
                                        ref.read(isLoadingProvider.notifier).state = false;

                                        if (url != null) {
                                          ref.read(ttsAudioUrlProvider.notifier).state = url;
                                          await _playAudio(url);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Failed to generate audio')),
                                          );
                                        }
                                      },
                              ),
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  ref.read(inputTextProvider.notifier).state = '';
                                  _controller.clear();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32), 

              // STT Card
              SizedBox(
                height: 180,
                child: Card(
                  color: Colors.blue.shade50,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  child: Text(
                                    sttText,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                '${sttText.length}/750',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              ref.read(sttTextProvider.notifier).state = '';
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80), 
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: _isListening ? _stopRecording : _startRecording,
                    borderRadius: BorderRadius.circular(40),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(
                        _isListening ? Icons.mic_off : Icons.mic,
                        size: 55,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {}, 
                    borderRadius: BorderRadius.circular(40),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(Icons.camera_alt, size: 40, color: Colors.blue),
                    ),
                  ),
                ],
              ),
              const Spacer(),
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


