import 'package:flutter/material.dart';

// فرض می‌کنیم NoteItem در همین فایل است یا اینجا کپی شده
class NoteItem {
  final String noteType;
  final String sender;
  final String subject;
  final String? severity;
  final String text;
  final DateTime date;

  NoteItem({
    required this.noteType,
    required this.sender,
    required this.subject,
    this.severity,
    required this.text,
    required this.date,
  });
}

class IncidentFormScreen extends StatefulWidget {
  final DateTime? initialDate;
  final String? noteType;

  const IncidentFormScreen({Key? key, this.initialDate, this.noteType})
    : super(key: key);

  @override
  State<IncidentFormScreen> createState() => _IncidentFormScreenState();
}

class _IncidentFormScreenState extends State<IncidentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _subject;
  String? _severity;
  String? _text;
  late DateTime selectedDate;

  final List<String> severities = ['کم', 'متوسط', 'زیاد', 'بحرانی'];

  // نمونه داده برای نمایش در پایین فرم
  final List<NoteItem> savedIncidents = [
    NoteItem(
      noteType: 'اتفاق',
      sender: '',
      subject: 'قطعی اینترنت',
      severity: 'زیاد',
      text: 'اینترنت در طبقه دوم قطع شده است.',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NoteItem(
      noteType: 'اتفاق',
      sender: '',
      subject: 'تعویض سیستم ها',
      severity: 'متوسط',
      text: 'برنامه تعویض سیستم‌ها در هفته آینده.',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final isIncident = (widget.noteType == null || widget.noteType == 'اتفاق');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
          primaryColor: const Color.fromARGB(255, 12, 12, 12),
          colorScheme: const ColorScheme.dark(primary: Colors.teal),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 13, 14, 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: const Color.fromARGB(255, 10, 10, 10),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            labelStyle: TextStyle(color: const Color.fromARGB(255, 13, 14, 13)),
          ),
        ),
        child: Scaffold(
          appBar: AppBar(title: Text('ثبت ${widget.noteType ?? 'اتفاق'}')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.teal[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'تاریخ انتخاب شده: ${_formatDate(selectedDate)}',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),

                  // موضوع
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'موضوع'),
                    onChanged: (val) => _subject = val,
                    validator: (val) => val == null || val.isEmpty
                        ? 'موضوع را وارد کنید'
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // فقط اگر نوع یادداشت اتفاق است، درجه بندی را نمایش بده
                  if (isIncident)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'درجه حادثه',
                      ),
                      items: severities
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _severity = val),
                      value: _severity,
                      validator: (val) =>
                          val == null ? 'لطفا درجه حادثه را انتخاب کنید' : null,
                    ),

                  if (isIncident) const SizedBox(height: 16),

                  // متن
                  TextFormField(
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'متن'),
                    onChanged: (val) => _text = val,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'متن را وارد کنید' : null,
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newNote = NoteItem(
                          noteType: widget.noteType ?? 'اتفاق',
                          sender: '', // فرستنده حذف شده
                          subject: _subject!,
                          severity: isIncident ? _severity! : null,
                          text: _text!,
                          date: selectedDate,
                        );
                        Navigator.pop(context, newNote);
                      }
                    },
                    child: Text('ثبت ${widget.noteType ?? 'اتفاق'}'),
                  ),

                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 10),

                  // نمایش لیست حوادث ثبت شده (در اینجا فقط نمونه است)
                  const Text(
                    'لیست حوادث ثبت شده:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  ...savedIncidents.map((incident) {
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.event_note),
                        title: Text(
                          '${incident.subject} - ${incident.severity ?? ''}',
                        ),
                        subtitle: Text(incident.text),
                        isThreeLine: true,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
