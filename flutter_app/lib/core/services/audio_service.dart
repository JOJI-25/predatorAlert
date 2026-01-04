/// Audio service for siren playback

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class AudioService {
  AudioService._();
  
  static final AudioService instance = AudioService._();
  
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  
  bool get isPlaying => _isPlaying;
  
  /// Play the siren alarm sound on loop
  Future<void> playSiren() async {
    if (_isPlaying) return;
    
    try {
      _isPlaying = true;
      
      // Set to loop mode
      await _player.setReleaseMode(ReleaseMode.loop);
      
      // Play siren sound
      // Using a generated tone as fallback if asset doesn't exist
      await _player.play(
        AssetSource('audio/siren.mp3'),
        volume: 1.0,
      );
      
      // Start vibration pattern
      _startVibration();
      
      print('🔊 Siren started');
    } catch (e) {
      print('Error playing siren: $e');
      // Try playing a tone as fallback
      _playFallbackTone();
    }
  }
  
  /// Stop the siren alarm
  Future<void> stopSiren() async {
    if (!_isPlaying) return;
    
    try {
      await _player.stop();
      _isPlaying = false;
      
      // Stop vibration
      Vibration.cancel();
      
      print('🔇 Siren stopped');
    } catch (e) {
      print('Error stopping siren: $e');
    }
  }
  
  void _startVibration() async {
    // Check if device supports vibration
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    
    if (hasVibrator) {
      // Vibrate in pattern: 500ms on, 200ms off, repeat
      Vibration.vibrate(
        pattern: [0, 500, 200, 500, 200, 500],
        repeat: 0,
      );
    }
  }
  
  Future<void> _playFallbackTone() async {
    // Generate a simple alert tone if siren asset is missing
    try {
      await _player.play(
        UrlSource('https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      print('Fallback tone also failed: $e');
    }
  }
  
  /// Play a short notification sound
  Future<void> playNotificationSound() async {
    try {
      final player = AudioPlayer();
      await player.play(
        AssetSource('audio/notification.mp3'),
        volume: 0.7,
      );
    } catch (e) {
      print('Error playing notification: $e');
    }
  }
  
  void dispose() {
    _player.dispose();
  }
}
