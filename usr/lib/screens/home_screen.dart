import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      setState(() {
        _selectedImages = images;
      });
      // Mock: Navigate to editor with selected images
      Navigator.pushNamed(context, '/editor', arguments: {'type': 'images', 'data': _selectedImages});
    }
  }

  void _createVideoFromText() {
    if (_textInput.isNotEmpty) {
      // Mock: Navigate to editor with text and duration
      Navigator.pushNamed(context, '/editor', arguments: {'type': 'text', 'data': _textInput, 'duration': _durationMinutes});
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
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: const Text('Tạo video từ hình ảnh'),
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
            if (_selectedImages != null)
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
