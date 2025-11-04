import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  VideoPlayerController? _controller;
  bool _showSubtitles = false;
  bool _addLogo = true;
  String _subtitleText = 'Phụ đề mẫu';
  Color _subtitleColor = Colors.white;
  List<String> _stickers = ['😊', '🎥', '✨', '❤️', '🔥', '⭐'];
  String? _videoPath;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _videoPath = args?['videoPath'] as String?;
      if (_videoPath != null && File(_videoPath!).existsSync()) {
        _controller = VideoPlayerController.file(File(_videoPath!))
          ..initialize().then((_) => setState(() {}));
      } else {
        // Không có video, hiển thị thông báo thay vì mock
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy video để chỉnh sửa')),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _applyEdits() async {
    if (_videoPath == null || !File(_videoPath!).existsSync()) return;
    setState(() => _isProcessing = true);
    try {
      final directory = await getTemporaryDirectory();
      final outputPath = '${directory.path}/edited_${DateTime.now().millisecondsSinceEpoch}.mp4';
      
      List<String> vfFilters = [];
      
      // Thêm phụ đề nếu có
      if (_showSubtitles) {
        final subtitleFile = File('${directory.path}/subtitles.srt');
        await subtitleFile.writeAsString('1\n00:00:00,000 --> 00:10:00,000\n$_subtitleText');
        vfFilters.add('subtitles=${subtitleFile.path}:force_style=\'FontSize=24,PrimaryColour=&H${_subtitleColor.value.toRadixString(16).substring(2)}\'');
      }
      
      // Thêm logo nếu có
      if (_addLogo) {
        vfFilters.add('drawtext=text=\'Minh Hoàng\':fontcolor=white:fontsize=50:x=10:y=10');
      }
      
      String command = '-i $_videoPath';
      if (vfFilters.isNotEmpty) {
        command += ' -vf "${vfFilters.join(',')}" ';
      }
      command += '-c:v libx264 -c:a aac $outputPath';
      
      await FFmpegKit.execute(command);
      
      if (File(outputPath).existsSync()) {
        setState(() {
          _videoPath = outputPath;
          _controller = VideoPlayerController.file(File(_videoPath!))
            ..initialize().then((_) => setState(() {}));
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã áp dụng chỉnh sửa!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chỉnh sửa: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _exportVideo() async {
    if (_videoPath == null || !File(_videoPath!).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có video để xuất')),
      );
      return;
    }
    // Chia sẻ video cho Teams
    await Share.shareXFiles([XFile(_videoPath!)], text: 'Video từ Minh Hoàng Video Creator');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa Video'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isProcessing ? null : _applyEdits,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportVideo,
          ),
        ],
      ),
      body: _controller == null ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          if (_controller!.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  setState(() {
                    _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: () => _controller!.pause(),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Thêm phụ đề'),
                    value: _showSubtitles,
                    onChanged: (value) => setState(() => _showSubtitles = value),
                  ),
                  if (_showSubtitles)
                    Column(
                      children: [
                        TextField(
                          controller: TextEditingController(text: _subtitleText),
                          onChanged: (value) => _subtitleText = value,
                          decoration: const InputDecoration(labelText: 'Nội dung phụ đề'),
                        ),
                        ElevatedButton(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Chọn màu phụ đề'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: _subtitleColor,
                                  onColorChanged: (color) => setState(() => _subtitleColor = color),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          ),
                          child: const Text('Chọn màu'),
                        ),
                      ],
                    ),
                  SwitchListTile(
                    title: const Text('Chèn Logo "Minh Hoàng"'),
                    value: _addLogo,
                    onChanged: (value) => setState(() => _addLogo = value),
                  ),
                  const Text('Nhãn dán (Stickers)', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 200,
                    child: StaggeredGrid.count(
                      crossAxisCount: 4,
                      children: _stickers.map((sticker) {
                        return StaggeredGridTile.fit(
                          crossAxisCellCount: 1,
                          child: GestureDetector(
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đã thêm sticker: $sticker')),
                            ),
                            child: Container(
                              color: Colors.grey[200],
                              child: Center(child: Text(sticker, style: const TextStyle(fontSize: 24))),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _applyEdits,
                    icon: const Icon(Icons.edit),
                    label: Text(_isProcessing ? 'Đang xử lý...' : 'Áp dụng chỉnh sửa'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _exportVideo,
                    icon: const Icon(Icons.share),
                    label: const Text('Xuất cho Teams'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}