import 'package:flutter_riverpod/flutter_riverpod.dart';

final inputTextProvider = StateProvider<String>((ref) => '');
final isLoadingProvider = StateProvider<bool>((ref) => false);
final sttTextProvider = StateProvider<String>((ref) => '');
final ttsAudioUrlProvider = StateProvider<String?>((ref) => null);

final userNameProvider = StateProvider<String>((ref) => '');
final userProfileImageProvider = StateProvider<String?>((ref) => null);
