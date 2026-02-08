import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../providers/task_provider.dart';
import '../models/task.dart';

class ChatScreen extends StatefulWidget {
  final Task task;
  const ChatScreen({super.key, required this.task});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _isSpeaking = false;
  int? _speakingIndex;
  Timer? _scrollDebounce;

  final List<_PendingItem> _pending = [];

  @override
  void dispose() {
    html.window.speechSynthesis?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _scrollDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final items = [...provider.messages.map(_ChatItem.fromMessage), ..._pending.map(_ChatItem.fromPending)];
    _autoScroll();

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2B2B),
        title: Text(widget.task.description),
      ),
      body: Column(
        children: [
          Expanded(
            child: items.isEmpty
                ? _empty()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _chatItem(items[i], i),
                  ),
          ),
          _input(provider),
        ],
      ),
    );
  }

  // ---------------- UI ----------------

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Schreibe eine Nachricht oder lade eine Datei hoch',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Dateien werden mit Emoji-Icons im Chat angezeigt 📎🖼️📄',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
      );

  Widget _input(TaskProvider provider) {
    final canSend = widget.task.isPaid && _inputCtrl.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: const Color(0xFF2B2B2B),
      child: Column(
        children: [
          if (widget.task.isPaid)
            Row(
              children: [
                _iconBtn(Icons.attach_file, () => _pickFile(provider)),
                _iconBtn(Icons.image, () => _pickImage(provider)),
                _iconBtn(Icons.picture_as_pdf, () => _pickDoc(provider)),
                const Spacer(),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Nachricht eingeben…',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              IconButton(
                icon: Icon(Icons.arrow_upward, color: canSend ? Colors.white : Colors.grey),
                onPressed: canSend ? () => _send(provider) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => IconButton(
        icon: Icon(icon, color: Colors.grey),
        onPressed: onTap,
      );

  // ---------------- Chat Item ----------------

  Widget _chatItem(_ChatItem item, int index) {
    final isUser = item.role == 'user';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: isUser ? const Color(0xFF212121) : const Color(0xFF2B2B2B),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 24),
          if (!isUser)
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(4)),
              child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          if (!isUser) const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Datei-Anzeige falls vorhanden
                if (item.fileName != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF40414F),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade700),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getFileEmoji(item.fileName ?? ''),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item.fileName ?? 'Unbekannte Datei',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.fileType != null)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.fileType!.toUpperCase(),
                              style: const TextStyle(color: Colors.teal, fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ),
                // Text-Inhalt falls vorhanden  
                if (item.content != null && item.content!.isNotEmpty)
                  MarkdownBody(
                    data: item.content!,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Colors.white, height: 1.6),
                      code: const TextStyle(backgroundColor: Color(0xFF40414F)),
                    ),
                  ),
                if (!isUser) _actions(item.content ?? '', index),
                if (item.isPending)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: const [
                        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('Wird gesendet…', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _actions(String text, int index) {
    return Row(
      children: [
        _action(Icons.content_copy, () => _copy(text)),
        _action(
          _isSpeaking && _speakingIndex == index ? Icons.stop : Icons.volume_up,
          () => _speak(text, index),
        ),
        _action(Icons.share, () => _share(text)),
        _action(Icons.download, () => _download(text)),
      ],
    );
  }

  Widget _action(IconData icon, VoidCallback onTap) => IconButton(
        icon: Icon(icon, size: 18, color: Colors.grey),
        onPressed: onTap,
      );

  // ---------------- Logic ----------------

  Future<void> _send(TaskProvider provider) async {
    final text = _inputCtrl.text.trim();
    _inputCtrl.clear();
    setState(() => _pending.add(_PendingItem(text)));
    await provider.sendMessage(widget.task.id!, content: text);
    setState(() => _pending.removeAt(0));
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _toast('Kopiert');
  }

  void _speak(String text, int index) {
    if (_isSpeaking && _speakingIndex == index) {
      html.window.speechSynthesis?.cancel();
      setState(() => _isSpeaking = false);
      return;
    }
    html.window.speechSynthesis?.cancel();
    final u = html.SpeechSynthesisUtterance(text)..lang = 'de-DE';
    html.window.speechSynthesis?.speak(u);
    setState(() {
      _isSpeaking = true;
      _speakingIndex = index;
    });
    u.onEnd.listen((_) => setState(() => _isSpeaking = false));
  }

  Future<void> _share(String text) async {
    try {
      await Share.share(text);
    } catch (_) {
      Clipboard.setData(ClipboardData(text: text));
      _toast('Kopiert');
    }
  }

  void _download(String text) {
    final blob = html.Blob([utf8.encode(text)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)..download = 'chat.txt'..click();
    html.Url.revokeObjectUrl(url);
  }

  // ---------------- Upload ----------------

  Future<void> _pickFile(TaskProvider p) async {
    final r = await FilePicker.platform.pickFiles(withData: true);
    if (r == null) return;
    setState(() => _pending.add(_PendingItem('📎 ${r.files.single.name}')));
    await p.uploadAndSendFile(
      widget.task.id!,
      bytes: r.files.single.bytes!,
      filename: r.files.single.name,
    );
    setState(() => _pending.removeAt(0));
  }

  Future<void> _pickImage(TaskProvider p) => _pickFile(p);
  Future<void> _pickDoc(TaskProvider p) => _pickFile(p);

  // ---------------- Helpers ----------------

  void _autoScroll() {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 80), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), duration: const Duration(seconds: 1)),
    );
  }

  // ---------------- File Helper ----------------

  String _getFileEmoji(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg': case 'jpeg': case 'png': case 'gif': case 'bmp': case 'webp': case 'svg':
        return '🖼️';
      case 'pdf':
        return '📄';
      case 'doc': case 'docx': case 'rtf':
        return '📝';
      case 'xls': case 'xlsx': case 'csv':
        return '📊';
      case 'ppt': case 'pptx':
        return '📊';
      case 'zip': case 'rar': case '7z': case 'tar': case 'gz':
        return '🗜️';
      case 'mp3': case 'wav': case 'flac': case 'aac': case 'm4a':
        return '🎵';
      case 'mp4': case 'avi': case 'mov': case 'mkv': case 'wmv':
        return '🎬';
      case 'txt': case 'md': case 'json': case 'xml': case 'yaml': case 'yml':
        return '📄';
      default:
        return '📎';
    }
  }
}

// ---------------- Models ----------------

class _ChatItem {
  final String role;
  final String? content;
  final String? fileName;
  final String? fileType;
  final String? fileUrl;
  final bool isPending;

  _ChatItem(this.role, this.content, {this.fileName, this.fileType, this.fileUrl, this.isPending = false});

  factory _ChatItem.fromMessage(Message m) => _ChatItem(
    m.role, 
    m.content, 
    fileName: m.fileName,
    fileType: m.fileType,
    fileUrl: m.fileUrl,
  );
  
  factory _ChatItem.fromPending(_PendingItem p) => _ChatItem('user', p.text, isPending: true);
}

class _PendingItem {
  final String text;
  _PendingItem(this.text);
}
