import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

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
  List<String> _stickers = ['😊', '🎥', '✨'];

  @override
  void initState() {
    super.initState();
    // Mock: Load a sample video (replace with actual generated video)
    _controller = VideoPlayerController.asset('assets/videos/sample.mp4')
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _exportVideo() {
    // Mock: Simulate export for Teams
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video đã được xuất cho Teams! (Mock)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final type = args?['type'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa Video'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _exportVideo,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(_controller?.value.isPlaying ?? false ? Icons.pause : Icons.play),
                onPressed: () {
                  setState(() {
                    _controller?.value.isPlaying ?? false ? _controller?.pause() : _controller?.play();
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: () => _controller?.pause(),
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
                          onChanged: (value) => setState(() => _subtitleText = value),
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
                  const Text('Nhãn dán (Stickers)'),
                  StaggeredGridView.countBuilder(
                    shrinkWrap: true,
                    crossAxisCount: 4,
                    itemCount: _stickers.length,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã thêm sticker: ${_stickers[index]}')),
                      ),
                      child: Container(
                        color: Colors.grey[200],
                        child: Center(child: Text(_stickers[index], style: const TextStyle(fontSize: 24))),
                      ),
                    ),
                    staggeredTileBuilder: (index) => const StaggeredTile.fit(1),
                  ),
                  const SizedBox(height: 20),
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
