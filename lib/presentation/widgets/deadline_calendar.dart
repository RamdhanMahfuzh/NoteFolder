import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notefolder/core/routes/app_routes.dart';
import 'package:notefolder/core/themes/app_colors.dart';
import 'package:notefolder/core/themes/app_spacing.dart';
import 'package:notefolder/domain/entities/note_entity.dart';

class DeadlineCalendar extends StatefulWidget {
  const DeadlineCalendar({super.key, required this.notes});

  final List<NoteEntity> notes;

  @override
  State<DeadlineCalendar> createState() => _DeadlineCalendarState();
}

class _DeadlineCalendarState extends State<DeadlineCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  Future<void> _openNote(BuildContext context, NoteEntity note) async {
    if (!note.isLocked) {
      context.push(AppRoutes.noteDetailPath(note.id));
      return;
    }
    final result = await context.push<Object?>(AppRoutes.pinPath(note.id));
    if (result == null || !context.mounted) return;
    if (result == true || result == (note.pin ?? '')) {
      context.push(AppRoutes.noteDetailPath(note.id));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incorrect PIN')));
    }
  }

  void _openDay(
    BuildContext context,
    DateTime date,
    List<NoteEntity> dayNotes,
  ) {
    if (dayNotes.length == 1) {
      _openNote(context, dayNotes.first);
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: dayNotes.length,
          itemBuilder: (context, index) {
            final note = dayNotes[index];
            return ListTile(
              leading: note.isLocked
                  ? const Icon(Icons.lock_outline, size: 20)
                  : null,
              title: Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                note.isLocked ? '🔒 Locked note' : note.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openNote(context, note);
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final byDate = <DateTime, List<NoteEntity>>{};
    for (final note in widget.notes) {
      final deadline = note.deadline;
      if (deadline != null) {
        final key = DateTime(deadline.year, deadline.month, deadline.day);
        byDate.putIfAbsent(key, () => []).add(note);
      }
    }

    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    const labels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
              ),
              Expanded(
                child: Text(
                  '${monthNames[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
              ),
            ],
          ),
          AppSpacing.gapXs,
          Row(
            children: [
              for (final label in labels)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.gapSm,
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) return const SizedBox.shrink();
              final day = index - startWeekday + 1;
              final date = DateTime(_month.year, _month.month, day);
              final isToday = date == today;
              final dayNotes = byDate[date] ?? const <NoteEntity>[];
              final hasDeadline = dayNotes.isNotEmpty;
              return Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: hasDeadline
                      ? () => _openDay(context, date, dayNotes)
                      : null,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday ? AppColors.primary : null,
                      border: !isToday && hasDeadline
                          ? Border.all(color: Colors.white, width: 1.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
