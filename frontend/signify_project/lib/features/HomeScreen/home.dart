import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:signify_project/services/tts_service.dart';
import 'package:signify_project/services/stt_service.dart';
import 'package:signify_project/services/userProfile.dart' as user_service;
import 'package:record/record.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'home_providers.dart';
import '../SignDetection/session_based_video_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(inputTextProvider));
    _player = AudioPlayer();

    _configureAudioPlayer();

    _controller.addListener(() {
      if (_controller.text != ref.read(inputTextProvider)) {
        ref.read(inputTextProvider.notifier).state = _controller.text;
      }
    });
  }

  void _configureAudioPlayer() async {
    try {
      await _player.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransient,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.defaultToSpeaker},
          ),
        ),
      );

      // Set volume to maximum
      await _player.setVolume(1.0);

      // Set player mode
      await _player.setPlayerMode(PlayerMode.mediaPlayer);

      print('Audio player configured successfully');
    } catch (e) {
      print('Audio player configuration error: $e');
    }
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
        final transcript = await STTService.sendAudioForTranscription(
          audioFile,
        );

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

  Future<void> _playAudioFromFile(String filePath) async {
    try {
      print('Attempting to play audio from file: $filePath');

      final file = File(filePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        print('Audio file exists, size: $fileSize bytes');
      } else {
        print('Audio file does not exist!');
        return;
      }

      if (_player.state == PlayerState.playing) {
        await _player.stop();
      }

      await Future.delayed(const Duration(milliseconds: 300));

      await _player.setVolume(1.0);

      await _player.setPlayerMode(PlayerMode.mediaPlayer);

      await _player.play(DeviceFileSource(filePath));

      print('Audio playback started successfully from local file');

      _player.onPlayerStateChanged.take(5).listen((PlayerState state) {
        print('Player state changed to: $state');
        if (state == PlayerState.playing) {
          print(
            'Audio is now playing - check device volume and speaker settings',
          );
        }
      });

      _player.onPlayerComplete.take(1).listen((event) {
        print('Audio playback completed');
      });

      _player.onDurationChanged.take(1).listen((Duration duration) {
        print('Audio duration: ${duration.inMilliseconds}ms');
      });
    } catch (e) {
      print('Audio playback error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Audio playback failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(user_service.userProfileProvider);
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
                      userProfileAsync.when(
                        data:
                            (user) => Text(
                              user.fullname.isNotEmpty
                                  ? 'Hi, ${user.fullname.split(' ')[0]}'
                                  : 'Hi, User',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'LeagueSpartan',
                                color: Color(0xFF005FCE),
                              ),
                            ),
                        loading:
                            () => const Text(
                              'Hi, User',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'LeagueSpartan',
                                color: Color(0xFF005FCE),
                              ),
                            ),
                        error:
                            (_, __) => const Text(
                              'Hi, User',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'LeagueSpartan',
                                color: Color(0xFF005FCE),
                              ),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                        'Voice it',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF005FCE),
                          fontFamily: 'LeagueSpartan',
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 180,
                      child: Card(
                        color: Colors.blue.shade50,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon:
                                        isLoading
                                            ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : const Icon(Icons.volume_up),
                                    onPressed:
                                        inputText.isEmpty || isLoading
                                            ? null
                                            : () async {
                                              print(
                                                'TTS button pressed with text: $inputText',
                                              );
                                              ref
                                                  .read(
                                                    isLoadingProvider.notifier,
                                                  )
                                                  .state = true;
                                              final filePath =
                                                  await TTSService.getTtsAudioDirect(
                                                    inputText,
                                                  );
                                              ref
                                                  .read(
                                                    isLoadingProvider.notifier,
                                                  )
                                                  .state = false;

                                              print(
                                                'TTS service returned file path: $filePath',
                                              );
                                              if (filePath != null) {
                                                try {
                                                  await _playAudioFromFile(
                                                    filePath,
                                                  );
                                                } catch (e) {
                                                  print(
                                                    'Audio playback failed: $e',
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Audio playback failed: ${e.toString()}',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } else {
                                                print(
                                                  'TTS service returned null file path',
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Failed to generate audio. Please check your connection and try again.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      ref
                                          .read(inputTextProvider.notifier)
                                          .state = '';
                                      _controller.clear();
                                    },
                                  ),
                                ],
                              ),
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
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.only(bottom: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                        'Turn Voice to Words',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF005FCE),
                          fontFamily: 'LeagueSpartan',
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 180,
                      child: Card(
                        color: Colors.blue.shade50,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      ref.read(sttTextProvider.notifier).state =
                                          '';
                                    },
                                  ),
                                ],
                              ),
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
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
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
                    onTap: () async {
                      // Navigate to session-based video recording screen
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SessionBasedVideoScreen(),
                        ),
                      );

                      // If user selected a word, add it to the input text
                      if (result != null && result is String) {
                        final currentText = ref.read(inputTextProvider);
                        final newText =
                            currentText.isEmpty
                                ? result
                                : '$currentText $result';
                        ref.read(inputTextProvider.notifier).state = newText;
                        _controller.text = newText;
                        _controller.selection = TextSelection.collapsed(
                          offset: newText.length,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(40),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.blue,
                      ),
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
