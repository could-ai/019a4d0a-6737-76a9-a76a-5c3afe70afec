import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterTts _tts = FlutterTts();
  String _selectedVoice = 'Nam';
  String _selectedLanguage = 'vi-VN';
  double _speechRate = 0.5;
  bool _isGeneratingVoiceover = false;

  final List<String> _voices = ['Nam', 'Nữ', 'Trẻ', 'Già', 'Thiếu nhi', 'Trẻ em'];
  final Map<String, String> _languages = {
    'vi-VN': 'Tiếng Việt',
    'en-US': 'English',
    'fr-FR': 'Français',
    'es-ES': 'Español',
    'de-DE': 'Deutsch',
  };

  void _testVoice() async {
    await _tts.setVoice({'name': _selectedVoice, 'locale': _selectedLanguage});
    await _tts.setSpeechRate(_speechRate);
    await _tts.speak('Đây là giọng đọc mẫu cho video của bạn.');
  }

  Future<void> _generateVoiceover(String text, int durationMinutes) async {
    setState(() => _isGeneratingVoiceover = true);
    try {
      final directory = await getTemporaryDirectory();
      final audioPath = '${directory.path}/voiceover.wav';
      
      await _tts.setVoice({'name': _selectedVoice, 'locale': _selectedLanguage});
      await _tts.setSpeechRate(_speechRate);
      
      // Mock lưu TTS - trong thực tế cần plugin để lưu file âm thanh
      await _tts.speak(text);
      
      // Tạo audio file với FFmpeg (mock)
      final command = '-f lavfi -i "sine=frequency=1000:duration=${durationMinutes * 60}" -acodec pcm_s16le -ar 44100 -ac 2 $audioPath';
      await FFmpegKit.execute(command);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo voiceover!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tạo voiceover: $e')),
      );
    } finally {
      setState(() => _isGeneratingVoiceover = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt âm thanh'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Chọn giọng đọc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedVoice,
              items: _voices.map((voice) => DropdownMenuItem(value: voice, child: Text(voice))).toList(),
              onChanged: (value) => setState(() => _selectedVoice = value!),
            ),
            const SizedBox(height: 20),
            const Text('Chọn ngôn ngữ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedLanguage,
              items: _languages.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
              onChanged: (value) => setState(() => _selectedLanguage = value!),
            ),
            const SizedBox(height: 20),
            const Text('Tốc độ nói'),
            Slider(
              value: _speechRate,
              min: 0.1,
              max: 1.0,
              onChanged: (value) => setState(() => _speechRate = value),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _testVoice,
              icon: const Icon(Icons.volume_up),
              label: const Text('Nghe thử giọng đọc'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isGeneratingVoiceover ? null : () => _generateVoiceover('Văn bản mẫu cho voiceover', 1),
              icon: const Icon(Icons.mic),
              label: Text(_isGeneratingVoiceover ? 'Đang tạo...' : 'Tạo voiceover mẫu'),
            ),
          ],
        ),
      ),
    );
  }
}