import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:notefolder/core/backup/backup_exporter.dart';
import 'package:notefolder/core/routes/app_routes.dart';
import 'package:notefolder/core/themes/app_spacing.dart';
import 'package:notefolder/core/themes/app_typography.dart';
import 'package:notefolder/core/themes/theme_mode_scope.dart';
import 'package:notefolder/data/database/app_database.dart';
import 'package:notefolder/injection/injection.dart' as di;
import 'package:notefolder/presentation/bloc/note_bloc.dart';
import 'package:notefolder/presentation/bloc/note_event.dart';
import 'package:notefolder/presentation/bloc/note_state.dart';
import 'package:notefolder/presentation/widgets/folder_list.dart';
import 'package:notefolder/presentation/widgets/deadline_calendar.dart';
import 'package:notefolder/presentation/widgets/app_search_bar.dart';
import 'package:notefolder/presentation/widgets/empty_notes_illustration.dart';
import 'package:notefolder/presentation/widgets/gradient_icon_button.dart';
import 'package:notefolder/presentation/widgets/notes_grid.dart';
import 'package:notefolder/presentation/widgets/weather_card.dart';
import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late final TabController _tabController;
  String _query = '';
  int _selectedTab = 0;
  bool _exportingBackup = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_onTabChanged);
    context.read<NoteBloc>().add(const LoadNotes());
  }

  void _onTabChanged() {
    if (_selectedTab == _tabController.index) return;
    setState(() => _selectedTab = _tabController.index);
  }

  Future<void> _exportBackup() async {
    if (_exportingBackup) return;
    setState(() => _exportingBackup = true);
    try {
      final db = await di.sl<AppDatabase>().database;
      final json = await createBackupJson(
        notes: await db.query(AppDatabase.notesTable),
        folders: await db.query(AppDatabase.foldersTable),
      );
      final name =
          'noteapp-backup-${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(json)),
            mimeType: 'application/json',
          ),
        ],
        subject: 'NoteApp backup',
        fileNameOverrides: [name],
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export backup: $error')),
      );
    } finally {
      if (mounted) setState(() => _exportingBackup = false);
    }
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onFoldersTab = _selectedTab == 1;
    final themeModeScope = ThemeModeScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      controller: _searchCtrl,
                      hintText: onFoldersTab
                          ? 'Search folders...'
                          : 'Search notes...',
                      onChanged: (v) =>
                          setState(() => _query = v.trim().toLowerCase()),
                    ),
                  ),
                  if (onFoldersTab) ...[
                    AppSpacing.gapSm,
                    GradientIconButton(
                      icon: Icons.create_new_folder_outlined,
                      tooltip: 'Create folder',
                      onPressed: () => FolderList.createFolder(context),
                    ),
                  ],
                  PopupMenuButton<String>(
                    tooltip: 'Settings',
                    onSelected: (action) {
                      if (action == 'backup') {
                        _exportBackup();
                      } else {
                        themeModeScope.toggle();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'backup',
                        enabled: !_exportingBackup,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _exportingBackup
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.backup_outlined),
                          title: const Text('Backup'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'theme',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            themeModeScope.isDarkMode
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                          ),
                          title: Text(
                            themeModeScope.isDarkMode
                                ? 'Light mode'
                                : 'Dark mode',
                          ),
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  BlocConsumer<NoteBloc, NoteState>(
                    listener: (context, state) {
                      if (state is NoteOperationSuccess) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(state.message)));
                      }
                      if (state is NoteError) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(state.message)));
                      }
                    },
                    builder: (context, state) {
                      if (state is NoteLoading ||
                          state is NoteOperationSuccess) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is NotesLoaded) {
                        final notes = _query.isEmpty
                            ? state.notes
                            : state.notes
                                  .where(
                                    (n) => '${n.title} ${n.content}'
                                        .toLowerCase()
                                        .contains(_query),
                                  )
                                  .toList();
                        final sorted = [...notes]
                          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                        final visible = sorted.take(4).toList();
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            children: [
                              if (notes.isEmpty)
                                const EmptyNotesIllustration()
                              else
                                NotesGrid(notes: visible, scrollable: false),
                              if (sorted.length > 4)
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => context.push(AppRoutes.allNotes),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: AppSpacing.sm,
                                    ),
                                    child: Text(
                                      'see more',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              AppSpacing.gapLg,
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Scheduled Deadlines',
                                        textAlign: TextAlign.start,
                                        style: AppTypography.textTheme.bodyLarge
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppSpacing.gapLg,
                              DeadlineCalendar(notes: notes),
                              AppSpacing.gapMd,
                              const SizedBox(
                                width: double.infinity,
                                child: WeatherCard(),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  FolderList(query: _query),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addNote),
        tooltip: 'Add note',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 72,
        child: Row(
          children: [
            Expanded(
              child: _bottomTab(
                label: 'Notes',
                icon: Icons.sticky_note_2_outlined,
                index: 0,
              ),
            ),
            const SizedBox(width: 72),
            Expanded(
              child: _bottomTab(
                label: 'Folders',
                icon: Icons.folder_outlined,
                index: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomTab({
    required String label,
    required IconData icon,
    required int index,
  }) {
    final selected = _selectedTab == index;
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return TextButton(
      onPressed: () => _tabController.animateTo(index),
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(0, 48),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 20), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}
