import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:notefolder/core/routes/app_routes.dart';
import 'package:notefolder/core/themes/app_colors.dart';
import 'package:notefolder/core/themes/app_spacing.dart';
import 'package:notefolder/domain/entities/folder_entity.dart';
import 'package:notefolder/domain/entities/note_entity.dart';
import 'package:notefolder/presentation/bloc/folder_bloc.dart';
import 'package:notefolder/presentation/bloc/folder_event.dart';
import 'package:notefolder/presentation/bloc/folder_state.dart';
import 'package:notefolder/presentation/bloc/note_bloc.dart';
import 'package:notefolder/presentation/bloc/note_event.dart';
import 'package:notefolder/presentation/bloc/note_state.dart';

class FolderList extends StatelessWidget {
  const FolderList({super.key, this.query = ''});

  final String query;

  static Future<void> createFolder(BuildContext context) async {
    final name = await _askFolderName(context, 'New folder');
    if (name == null || !context.mounted) return;
    final now = DateTime.now();
    context.read<FolderBloc>().add(
      AddFolderEvent(
        FolderEntity(
          id: now.microsecondsSinceEpoch.toString(),
          name: name,
          createdAt: now,
        ),
      ),
    );
  }

  Future<void> _editFolder(BuildContext context, {FolderEntity? folder}) async {
    final name = await _askFolderName(
      context,
      folder == null ? 'New folder' : 'Rename folder',
      initialName: folder?.name ?? '',
    );
    if (name == null || !context.mounted) return;
    final bloc = context.read<FolderBloc>();
    if (folder == null) {
      final now = DateTime.now();
      bloc.add(
        AddFolderEvent(
          FolderEntity(
            id: now.microsecondsSinceEpoch.toString(),
            name: name,
            createdAt: now,
          ),
        ),
      );
    } else {
      bloc.add(
        UpdateFolderEvent(
          FolderEntity(id: folder.id, name: name, createdAt: folder.createdAt),
        ),
      );
    }
  }

  Future<void> _deleteFolder(BuildContext context, FolderEntity folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete folder?'),
        content: const Text('Its notes will be kept and moved to No folder.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<FolderBloc>().add(DeleteFolderEvent(folder.id));
    }
  }

  Future<void> _showFolderNotes(
    BuildContext context,
    FolderEntity folder,
    List<NoteEntity> notes,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _FolderNotesSheet(
        folder: folder,
        folders: (context.read<FolderBloc>().state is FoldersLoaded)
            ? (context.read<FolderBloc>().state as FoldersLoaded).folders
            : const [],
        initialNotes: notes,
        onAddNotes: () => _addNotesToFolder(context, folder),
        onMoveNote: _moveNote,
        onRemoveFromFolder: _removeFromFolder,
        onDeleteNote: _deleteNote,
        onOpenNote: (note) {
          Navigator.pop(sheetContext);
          _openNote(context, note);
        },
      ),
    );
  }

  Future<void> _addNotesToFolder(
    BuildContext context,
    FolderEntity folder,
  ) async {
    final noteState = context.read<NoteBloc>().state;
    if (noteState is! NotesLoaded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notes are still loading')));
      return;
    }
    final candidates = noteState.notes
        .where((note) => note.folderId != folder.id)
        .toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no other notes to add')),
      );
      return;
    }
    final selected = await showDialog<List<NoteEntity>>(
      context: context,
      builder: (dialogContext) => _SelectNotesDialog(notes: candidates),
    );
    if (selected == null || !context.mounted) return;
    for (final note in selected) {
      context.read<NoteBloc>().add(
        UpdateNoteEvent(_withFolder(note, folder.id)),
      );
    }
  }

  Future<void> _moveNote(
    BuildContext context,
    NoteEntity note,
    List<FolderEntity> folders,
  ) async {
    final folderId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Move note to'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, ''),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.inbox_outlined),
              title: Text('No folder'),
            ),
          ),
          for (final folder in folders)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, folder.id),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_outlined),
                title: Text(folder.name),
                trailing: note.folderId == folder.id
                    ? const Icon(Icons.check)
                    : null,
              ),
            ),
        ],
      ),
    );
    if (folderId == null || !context.mounted) return;
    final newFolderId = folderId.isEmpty ? null : folderId;
    if (newFolderId == note.folderId) return;
    context.read<NoteBloc>().add(
      UpdateNoteEvent(_withFolder(note, newFolderId)),
    );
  }

  Future<void> _deleteNote(BuildContext context, NoteEntity note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('“${note.title}” will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<NoteBloc>().add(DeleteNoteEvent(note.id));
    }
  }

  void _removeFromFolder(BuildContext context, NoteEntity note) {
    context.read<NoteBloc>().add(UpdateNoteEvent(_withFolder(note, null)));
  }

  static NoteEntity _withFolder(NoteEntity note, String? folderId) =>
      NoteEntity(
        id: note.id,
        banner: note.banner,
        title: note.title,
        content: note.content,
        contentBlockAlignments: note.contentBlockAlignments,
        contentImages: note.contentImages,
        contentWeather: note.contentWeather,
        deadline: note.deadline,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
        isLocked: note.isLocked,
        pin: note.pin,
        folderId: folderId,
        latitude: note.latitude,
        longitude: note.longitude,
      );

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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FolderBloc, FolderState>(
      listener: (context, state) {
        if (state is FoldersLoaded && state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
          if (state.message!.startsWith('Folder deleted')) {
            context.read<NoteBloc>().add(const LoadNotes());
          }
        } else if (state is FolderError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is FolderLoading || state is FolderInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is FolderError) return Center(child: Text(state.message));
        if (state is! FoldersLoaded) return const SizedBox.shrink();

        return BlocBuilder<NoteBloc, NoteState>(
          builder: (context, noteState) {
            final notes = noteState is NotesLoaded
                ? noteState.notes
                : <NoteEntity>[];
            final filteredFolders = state.folders
                .where((folder) => folder.name.toLowerCase().contains(query))
                .toList();
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your folders',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                AppSpacing.gapXs,
                                Text(
                                  '${filteredFolders.length} ${filteredFolders.length == 1 ? 'folder' : 'folders'}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filteredFolders.isEmpty && query.isNotEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No folders match your search')),
                  )
                else if (filteredFolders.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxxl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_open_outlined,
                              size: 72,
                              color: AppColors.primary.withValues(alpha: 0.55),
                            ),
                            AppSpacing.gapLg,
                            Text(
                              'Keep notes organized',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            AppSpacing.gapSm,
                            Text(
                              'Create a folder to group related notes.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                            AppSpacing.gapLg,
                            FilledButton.icon(
                              onPressed: () => _editFolder(context),
                              icon: const Icon(
                                Icons.create_new_folder_outlined,
                              ),
                              label: const Text('Create your first folder'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xs,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final folder = filteredFolders[index];
                        final folderNotes = notes
                            .where((note) => note.folderId == folder.id)
                            .toList();
                        return _FolderCard(
                          folder: folder,
                          noteCount: folderNotes.length,
                          onTap: () =>
                              _showFolderNotes(context, folder, folderNotes),
                          onRename: () => _editFolder(context, folder: folder),
                          onDelete: () => _deleteFolder(context, folder),
                        );
                      }, childCount: filteredFolders.length),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            mainAxisSpacing: AppSpacing.md,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisExtent: 154,
                          ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.noteCount,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final FolderEntity folder;
  final int noteCount;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surface
          : AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.folder_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Folder actions',
                      onSelected: (action) {
                        if (action == 'rename') onRename();
                        if (action == 'delete') onDelete();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  folder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppSpacing.gapXs,
                Text(
                  '$noteCount ${noteCount == 1 ? 'note' : 'notes'}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<String?> _askFolderName(
  BuildContext context,
  String title, {
  String initialName = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _FolderNameDialog(title: title, initialName: initialName),
  );
}

class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog({required this.title, required this.initialName});

  final String title;
  final String initialName;

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 60,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(hintText: 'Folder name'),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _save(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _controller.text.trim().isEmpty ? null : _save,
        child: const Text('Save'),
      ),
    ],
  );
}

class _FolderNotesSheet extends StatefulWidget {
  const _FolderNotesSheet({
    required this.folder,
    required this.folders,
    required this.initialNotes,
    required this.onAddNotes,
    required this.onMoveNote,
    required this.onRemoveFromFolder,
    required this.onDeleteNote,
    required this.onOpenNote,
  });

  final FolderEntity folder;
  final List<FolderEntity> folders;
  final List<NoteEntity> initialNotes;
  final VoidCallback onAddNotes;
  final Future<void> Function(
    BuildContext context,
    NoteEntity note,
    List<FolderEntity> folders,
  )
  onMoveNote;
  final void Function(BuildContext context, NoteEntity note) onRemoveFromFolder;
  final Future<void> Function(BuildContext context, NoteEntity note)
  onDeleteNote;
  final ValueChanged<NoteEntity> onOpenNote;

  @override
  State<_FolderNotesSheet> createState() => _FolderNotesSheetState();
}

class _FolderNotesSheetState extends State<_FolderNotesSheet> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.78,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_rounded, color: AppColors.primary),
                  AppSpacing.gapMd,
                  Expanded(
                    child: Text(
                      widget.folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Add existing notes',
                    onPressed: widget.onAddNotes,
                    icon: const Icon(Icons.note_add_outlined),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<NoteBloc, NoteState>(
                builder: (context, state) {
                  final allNotes = state is NotesLoaded
                      ? state.notes
                      : widget.initialNotes;
                  final notes = allNotes
                      .where((note) => note.folderId == widget.folder.id)
                      .toList();
                  if (notes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.note_add_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          AppSpacing.gapMd,
                          Text(
                            'This folder is empty',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          AppSpacing.gapXs,
                          Text(
                            'Add existing notes with the button above.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: notes.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return ListTile(
                        title: Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          note.isLocked ? 'Locked note' : note.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: Icon(
                          note.isLocked
                              ? Icons.lock_outline
                              : Icons.note_outlined,
                          color: AppColors.primary,
                        ),
                        onTap: () => widget.onOpenNote(note),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Note actions',
                          onSelected: (action) {
                            if (action == 'move') {
                              widget.onMoveNote(context, note, widget.folders);
                            } else if (action == 'unfile') {
                              widget.onRemoveFromFolder(context, note);
                            } else if (action == 'delete') {
                              widget.onDeleteNote(context, note);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'move',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.drive_file_move_outlined),
                                title: Text('Move to folder'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'unfile',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.folder_off_outlined),
                                title: Text('Move to no folder'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.delete_outline),
                                title: Text('Delete note'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectNotesDialog extends StatefulWidget {
  const _SelectNotesDialog({required this.notes});

  final List<NoteEntity> notes;

  @override
  State<_SelectNotesDialog> createState() => _SelectNotesDialogState();
}

class _SelectNotesDialogState extends State<_SelectNotesDialog> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add notes to folder'),
    content: SizedBox(
      width: double.maxFinite,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.notes.length,
        itemBuilder: (context, index) {
          final note = widget.notes[index];
          return CheckboxListTile(
            value: _selectedIds.contains(note.id),
            title: Text(
              note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              note.folderId == null
                  ? 'No folder'
                  : 'Currently in another folder',
              maxLines: 1,
            ),
            secondary: Icon(
              note.isLocked ? Icons.lock_outline : Icons.note_outlined,
            ),
            controlAffinity: ListTileControlAffinity.trailing,
            onChanged: (selected) => setState(() {
              if (selected == true) {
                _selectedIds.add(note.id);
              } else {
                _selectedIds.remove(note.id);
              }
            }),
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _selectedIds.isEmpty
            ? null
            : () => Navigator.pop(
                context,
                widget.notes
                    .where((note) => _selectedIds.contains(note.id))
                    .toList(),
              ),
        child: Text('Add ${_selectedIds.length}'),
      ),
    ],
  );
}
