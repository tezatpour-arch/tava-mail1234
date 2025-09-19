import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../models/note.dart';
import '../services/NoteDatabase.dart';
// مسیر درست رو تنظیم کن
import 'note_detail_screen.dart';

class NoteBoardScreen extends StatefulWidget {
  const NoteBoardScreen({Key? key}) : super(key: key);

  @override
  State<NoteBoardScreen> createState() => _NoteBoardScreenState();
}

class _NoteBoardScreenState extends State<NoteBoardScreen> {
  Jalali _selectedJalali = Jalali.now();
  String selectedNoteType = 'یادداشت';
  List<Note> notes = [];

  final List<Map<String, dynamic>> noteTypes = [
    {'title': 'یادداشت', 'icon': Icons.note},
    {'title': 'اتفاق', 'icon': Icons.warning},
    {'title': 'اعلان', 'icon': Icons.notifications},
    {'title': 'درخواست', 'icon': Icons.request_page},
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final localNotes = await NoteDatabase.instance.getAllNotes();
    setState(() {
      notes = localNotes
          .where(
            (n) =>
                n.noteType == selectedNoteType &&
                _isSameDay(n.date, _selectedJalali.toDateTime()),
          )
          .toList();
    });
  }

  bool _isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  void _onDaySelected(Jalali day) {
    setState(() {
      _selectedJalali = day;
    });
    _loadNotes();
  }

  void _onMonthChanged(int offset) {
    setState(() {
      final newMonth = _selectedJalali.addMonths(offset);
      _selectedJalali = Jalali(newMonth.year, newMonth.month, 1);
    });
    _loadNotes();
  }

  Future<void> _insertNoteLocal(Note note) async {
    await NoteDatabase.instance.insertNote(note);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('دفتر یادداشت‌ها'), centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildNoteTypeSelector(),
              const SizedBox(height: 12),
              _buildMonthHeader(),
              _buildCalendarGrid(),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('افزودن یادداشت'),
                onPressed: () async {
                  final newNote = await Navigator.push<Note>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoteDetailScreen(
                        noteType: selectedNoteType,
                        initialDate: _selectedJalali.toDateTime(),
                      ),
                    ),
                  );
                  if (newNote != null) {
                    await _insertNoteLocal(newNote);
                    _loadNotes();
                  }
                },
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildNotesList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTypeSelector() {
    return Wrap(
      spacing: 8,
      children: noteTypes.map((item) {
        final selected = item['title'] == selectedNoteType;
        return ChoiceChip(
          label: Text(item['title']),
          selected: selected,
          avatar: Icon(item['icon'], size: 20),
          onSelected: (_) {
            setState(() {
              selectedNoteType = item['title'];
            });
            _loadNotes();
          },
        );
      }).toList(),
    );
  }

  Widget _buildMonthHeader() {
    final monthName = _selectedJalali.formatter.mN;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _onMonthChanged(-1),
        ),
        Text(
          '${_selectedJalali.year} $monthName',
          style: const TextStyle(fontSize: 18),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => _onMonthChanged(1),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = Jalali(
      _selectedJalali.year,
      _selectedJalali.month,
      1,
    );
    final weekdayOffset = firstDayOfMonth.weekDay % 7;
    final daysInMonth = firstDayOfMonth.monthLength;

    final days = <Widget>[];

    const weekDays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    for (var wd in weekDays) {
      days.add(
        Center(
          child: Text(wd, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }

    for (int i = 0; i < weekdayOffset; i++) {
      days.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final current = Jalali(_selectedJalali.year, _selectedJalali.month, day);
      final isSelected = _selectedJalali == current;
      final isToday = current == Jalali.now();

      days.add(
        GestureDetector(
          onTap: () => _onDaySelected(current),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue
                  : isToday
                  ? Colors.blue.shade100
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text('$day')),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 7,
      children: days,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  Widget _buildNotesList() {
    if (notes.isEmpty) {
      return const Center(child: Text('یادداشتی برای این روز وجود ندارد.'));
    }

    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (_, index) {
        final note = notes[index];
        return Card(
          child: ListTile(
            title: Text(note.subject),
            subtitle: Text(note.text),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('حذف یادداشت'),
                    content: const Text('آیا از حذف این یادداشت مطمئن هستید؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('خیر'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('بله'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await NoteDatabase.instance.deleteNote(note.id!);
                  setState(() {
                    notes.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('یادداشت حذف شد')),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
