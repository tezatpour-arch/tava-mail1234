import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../models/note.dart';

class NoteDetailScreen extends StatefulWidget {
  final String noteType;
  final DateTime initialDate;

  const NoteDetailScreen({
    Key? key,
    required this.noteType,
    required this.initialDate,
  }) : super(key: key);

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController textController = TextEditingController();

  @override
  void dispose() {
    subjectController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 13, 14, 14),
          title: Text('ثبت ${widget.noteType}'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getNoteIcon(widget.noteType), color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    'موضوع ${widget.noteType}:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  hintText: 'عنوان یادداشت را وارد کنید...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.teal.shade50,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'متن یادداشت را وارد کنید...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.teal.shade50,
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Feather.save, size: 20),
                  onPressed: () {
                    if (textController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('متن یادداشت نمی‌تواند خالی باشد'),
                        ),
                      );
                      return;
                    }

                    final newNote = Note(
                      subject: subjectController.text.trim(),
                      text: textController.text.trim(),
                      noteType: widget.noteType,
                      date: widget.initialDate,
                      sender: 'سیستم',
                      id: null,
                    );

                    Navigator.pop(context, newNote);
                  },
                  label: Text('ثبت ${widget.noteType}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 17, 17, 17),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNoteIcon(String type) {
    switch (type) {
      case 'یادداشت':
        return MaterialCommunityIcons.note_text_outline;
      case 'اتفاق':
        return FontAwesome.exclamation_circle;
      case 'درخواست':
        return MaterialCommunityIcons.file_document_outline;
      case 'اعلان':
        return Feather.bell;
      default:
        return Feather.file_text;
    }
  }
}
