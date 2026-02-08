import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/task_provider.dart';
import '../../models/task.dart';

class TaskDetailChat extends StatefulWidget {
  final Task task;
  const TaskDetailChat({super.key, required this.task});

  @override
  State<TaskDetailChat> createState() => _TaskDetailChatState();
}

class _TaskDetailChatState extends State<TaskDetailChat> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _isSpeaking = false;
  int? _speakingIndex;
  Timer? _scrollDebounce;

  final List<_PendingItem> _pending = [];
  
  // Für Datei-Uploads die im Textfeld angezeigt werden
  String? _pendingFileText;
  List<int>? _pendingFileBytes;
  String? _pendingFileName;

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

    return Container(
      color: const Color(0xFF212121),
      child: Column(
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
        child: Text(
          'Schreibe eine Nachricht oder lade eine Datei hoch',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );

  Widget _input(TaskProvider provider) {
    final hasText = _inputCtrl.text.trim().isNotEmpty;
    final hasPendingFile = _pendingFileBytes != null;
    final canSend = widget.task.isPaid && (hasText || hasPendingFile);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: const Color(0xFF2B2B2B),
      child: Column(
        children: [
          // UPLOAD BUTTONS - IMMER ZEIGEN (AUCH BEI UNBEZAHLTEN TASKS)
          Row(
            children: [
              _iconBtn(Icons.attach_file, 'Datei', () => _pickFile(provider)),
              const SizedBox(width: 8),
              _iconBtn(Icons.image, 'Bild', () => _pickImage(provider)),
              const SizedBox(width: 8),
              _iconBtn(Icons.picture_as_pdf, 'PDF', () => _pickDoc(provider)),
              const Spacer(),
              if (hasPendingFile)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                  onPressed: _clearAttachedFile,
                  tooltip: 'Datei entfernen',
                ),
            ],
          ),
          const SizedBox(height: 12),
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

  Widget _iconBtn(IconData icon, String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );

  // ---------------- Chat Item ----------------

  Widget _chatItem(_ChatItem item, int index) {
    final isUser = item.role == 'user';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      color: const Color(0xFF212121), // SCHWARZ - kein separater Hintergrund
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFF10A37F), borderRadius: BorderRadius.circular(4)),
              child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          if (!isUser) const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Text(
                      item.content ?? '',
                      textAlign: isUser ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(color: Colors.white, height: 1.6, fontSize: 15),
                    ),
                  ),
                ),
                if (!isUser) _actions(item.content ?? '', index),
                if (item.isPending)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
          if (isUser) const SizedBox(width: 16),
          if (isUser)
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.blue[700], borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
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
    
    // Prüfe ob eine Datei angehängt ist
    if (_pendingFileBytes != null && _pendingFileName != null) {
      // Sende Text mit Datei
      await provider.uploadAndSendFile(
        widget.task.id!,
        bytes: _pendingFileBytes!,
        filename: _pendingFileName!,
        message: text,
      );
      
      // Datei-Daten zurücksetzen
      setState(() {
        _pendingFileBytes = null;
        _pendingFileName = null;
        _pendingFileText = null;
      });
    } else {
      // Normale Textnachricht
      await provider.sendMessage(widget.task.id!, content: text);
    }
    
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
    
    // Datei ins Textfeld einfügen statt direkt senden
    final fileName = r.files.single.name;
    final fileEmoji = _getFileEmoji(fileName);
    final fileText = '$fileEmoji $fileName';
    
    setState(() {
      _pendingFileBytes = r.files.single.bytes!;
      _pendingFileName = fileName;
      _pendingFileText = fileText;
      
      // Ins Textfeld einfügen
      final currentText = _inputCtrl.text;
      if (currentText.isEmpty) {
        _inputCtrl.text = fileText;
      } else {
        _inputCtrl.text = '$currentText\n$fileText';
      }
    });
  }

  Future<void> _pickImage(TaskProvider p) => _pickFile(p);
  Future<void> _pickDoc(TaskProvider p) => _pickFile(p);
  
  String _getFileEmoji(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'svg':
      case 'webp':
        return '🖼️';
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'ppt':
      case 'pptx':
        return '📋';
      case 'zip':
      case 'rar':
      case '7z':
        return '🗜️';
      case 'mp3':
      case 'wav':
      case 'flac':
        return '🎵';
      case 'mp4':
      case 'avi':
      case 'mkv':
        return '🎬';
      case 'txt':
        return '📄';
      default:
        return '📎';
    }
  }
  
  void _clearAttachedFile() {
    setState(() {
      // Entferne Datei-Referenz aus dem Textfeld bevor wir die Variablen zurücksetzen
      final currentText = _inputCtrl.text;
      final fileTextToRemove = _pendingFileText;
      
      if (fileTextToRemove != null && currentText.contains(fileTextToRemove)) {
        final newText = currentText.replaceAll(fileTextToRemove, '').trim();
        final lines = newText.split('\n').where((line) => line.trim().isNotEmpty).toList();
        _inputCtrl.text = lines.join('\n');
      }
      
      // Jetzt die Datei-Daten zurücksetzen
      _pendingFileBytes = null;
      _pendingFileName = null;
      _pendingFileText = null;
    });
  }

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
}

// ---------------- Models ----------------

class _ChatItem {
  final String role;
  final String? content;
  final bool isPending;

  _ChatItem(this.role, this.content, {this.isPending = false});

  factory _ChatItem.fromMessage(Message m) => _ChatItem(m.role, m.content);
  factory _ChatItem.fromPending(_PendingItem p) => _ChatItem('user', p.text, isPending: true);
}

class _PendingItem {
  final String text;
  _PendingItem(this.text);
}
