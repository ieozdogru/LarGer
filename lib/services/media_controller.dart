import 'package:flutter/services.dart';

class MediaController {
  static const MethodChannel _channel = MethodChannel(
    'com.example.larger/media_control',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.example.larger/media_status',
  );

  static Stream<bool> get playbackStateStream {
    return _eventChannel.receiveBroadcastStream().map((event) => event as bool);
  }

  static Future<void> playPause() async {
    try {
      await _channel.invokeMethod('playPause');
    } catch (e) {
      print('Failed to send play/pause: $e');
    }
  }

  static Future<void> next() async {
    try {
      await _channel.invokeMethod('next');
    } catch (e) {
      print('Failed to send next: $e');
    }
  }

  static Future<void> previous() async {
    try {
      await _channel.invokeMethod('previous');
    } catch (e) {
      print('Failed to send previous: $e');
    }
  }
}
