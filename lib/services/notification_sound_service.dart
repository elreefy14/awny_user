import 'package:just_audio/just_audio.dart';

class NotificationSoundService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playBookingAlert() async {
    try {
      await _audioPlayer.setAsset('assets/sounds/booking_alert.mp3');
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing sound: $e');
    }
  }
}
