import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _selectedImages;
  String _textInput = '';
  int _durationMinutes = 1;
  bool _isProcessing = false;
  final FlutterTts _tts = FlutterTts();

  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages = images;
      });
      await _createVideoFromImages(images);
    }
  }

  Future<void> _createVideoFromImages(List<XFile> images) async {
    setState(() => _isProcessing = true);
    try {
      final directory = await getTemporaryDirectory();
      final outputPath = '${directory.path}/output_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final concatFile = '${directory.path}/concat.txt';
      
      // Tạo file concat cho FFmpeg
      String concatContent = '';
      for (int i = 0; i < images.length; i++) {
        concatContent += "file '${images[i].path}'\nduration 3\n";
      }
      // Thêm frame cuối để tránh lỗi
      concatContent += "file '${images.last.path}'\n";
      
      await File(concatFile).writeAsString(concatContent);
      
      // FFmpeg command để tạo video slideshow
      final command = '-f concat -safe 0 -i $concatFile -vf "fps=25,format=yuv420p" -c:v libx264 -preset fast -crf 22 -c:a aac -b:a 128k $outputPath';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (returnCode?.isValueSuccess() == true) {
        Navigator.pushNamed(context, '/editor', arguments: {'type': 'images', 'videoPath': outputPath});
      } else {
        throw Exception('FFmpeg failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tạo video từ hình ảnh: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _createVideoFromText() async {
    if (_textInput.isNotEmpty) {
      setState(() => _isProcessing = true);
      try {
        final directory = await getTemporaryDirectory();
        final videoPath = '${directory.path}/text_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final imagePath = '${directory.path}/text_image.png';
        
        // Tạo hình ảnh từ text sử dụng FFmpeg
        final textCommand = '-f lavfi -i color=c=blue:s=1280x720:d=1 -vf "drawtext=text=\'${_textInput.replaceAll("'", "\\''")}\':fontcolor=white:fontsize=50:x=(w-text_w)/2:y=(h-text_h)/2:font=Arial" -frames:v 1 $imagePath';
        await FFmpegKit.execute(textCommand);
        
        // Tạo video từ hình ảnh với thời lượng chỉ định
        final videoCommand = '-loop 1 -i $imagePath -c:v libx264 -t ${_durationMinutes * 60} -pix_fmt yuv420p -preset fast -crf 22 $videoPath';
        final session = await FFmpegKit.execute(videoCommand);
        final returnCode = await session.getReturnCode();
        
        if (returnCode?.isValueSuccess() == true) {
          Navigator.pushNamed(context, '/editor', arguments: {'type': 'text', 'videoPath': videoPath, 'data': _textInput, 'duration': _durationMinutes});
        } else {
          throw Exception('FFmpeg video creation failed');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo video từ văn bản: $e')),
        );
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minh Hoàng Video Creator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Chọn loại video bạn muốn tạo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickImages,
              icon: const Icon(Icons.photo_library),
              label: Text(_isProcessing ? 'Đang xử lý...' : 'Tạo video từ hình ảnh'),
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (value) => _textInput = value,
              decoration: const InputDecoration(labelText: 'Nhập văn bản cho video'),
              maxLines: 3,
            ),
            Slider(
              value: _durationMinutes.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              label: '$_durationMinutes phút',
              onChanged: (value) => setState(() => _durationMinutes = value.toInt()),
            ),
            const Text('Thời lượng video (1-60 phút)'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _createVideoFromText,
              icon: const Icon(Icons.text_fields),
              label: const Text('Tạo video từ văn bản'),
            ),
            if (_selectedImages != null && _selectedImages!.isNotEmpty)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                  itemCount: _selectedImages!.length,
                  itemBuilder: (context, index) => Image.file(File(_selectedImages![index].path)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}