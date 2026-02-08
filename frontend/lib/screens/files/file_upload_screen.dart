import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';

class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({super.key});

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  final ApiService _api = ApiService();
  bool _uploading = false;
  final List<_FileItem> _files = [];

  Future<void> _pickAndUpload() async {
    final r =
        await FilePicker.platform.pickFiles(withData: true);
    if (r == null) return;

    final f = r.files.first;
    if (f.bytes == null) return;

    setState(() => _uploading = true);

    final res = await _api.uploadFile(
      bytes: f.bytes!,
      filename: f.name,
    );

    setState(() {
      _files.insert(
        0,
        _FileItem(
          name: f.name,
          size: f.size,
          url: res['url'],
        ),
      );
      _uploading = false;
    });
  }

  void _download(_FileItem f) {
    html.AnchorElement(href: f.url)
      ..download = f.name
      ..click();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Upload')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _uploading ? null : _pickAndUpload,
              icon: _uploading
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.upload),
              label:
                  Text(_uploading ? 'Uploading…' : 'Upload File'),
            ),
          ),
          Expanded(
            child: _files.isEmpty
                ? const Center(child: Text('No files'))
                : ListView.builder(
                    itemCount: _files.length,
                    itemBuilder: (_, i) {
                      final f = _files[i];
                      return ListTile(
                        leading:
                            const Icon(Icons.insert_drive_file),
                        title: Text(f.name),
                        subtitle:
                            Text('${(f.size / 1024).toStringAsFixed(1)} KB'),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => _download(f),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FileItem {
  final String name;
  final int size;
  final String url;
  _FileItem({required this.name, required this.size, required this.url});
}