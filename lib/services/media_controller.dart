import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native media key controls (Android only). No-ops on web and other platforms.
class MediaController {
  static const MethodChannel _channel = MethodChannel(
    'com.example.larger/media_control',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.example.larger/media_status',
  );

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Stream<bool> get playbackStateStream {
    if (!isSupported) {
      return const Stream<bool>.empty();
    }
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => event as bool)
        .handleError((Object error, StackTrace stackTrace) {
          // Missing native plugin (e.g. unexpected platform) — ignore.
        });
  }

  static Future<void> playPause() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('playPause');
    } catch (e) {
      debugPrint('Failed to send play/pause: $e');
    }
  }

  static Future<void> next() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('next');
    } catch (e) {
      debugPrint('Failed to send next: $e');
    }
  }

  static Future<void> previous() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('previous');
    } catch (e) {
      debugPrint('Failed to send previous: $e');
    }
  }
}
