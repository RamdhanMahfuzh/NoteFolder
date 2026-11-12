import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:notefolder/core/routes/app_routes.dart';
import 'package:notefolder/core/themes/app_spacing.dart';
import 'package:notefolder/core/themes/app_typography.dart';
import 'package:notefolder/domain/entities/note_entity.dart';
import 'package:notefolder/presentation/bloc/folder_bloc.dart';
import 'package:notefolder/presentation/bloc/folder_state.dart';
import 'package:notefolder/presentation/bloc/note_bloc.dart';
import 'package:notefolder/presentation/bloc/note_event.dart';

class NotesGrid extends StatelessWidget {
  const NotesGrid({
    super.key,
    required this.notes,
    this.scrollable = true,
    this.groupByDate = false,
  });

  final List<NoteEntity> notes;
  final bool scrollable;
  final bool groupByDate;

  Widget _grid(
    BuildContext context,
    List<NoteEntity> items, {
    required EdgeInsetsGeometry padding,
    bool forceShrink = false,
  }) {
    final shrink = forceShrink || !scrollable;
    return MasonryGridView.count(
      padding: padding,
      shrinkWrap: shrink,
      physics: shrink ? const NeverScrollableScrollPhysics() : null,
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      itemCount: items.length,
      itemBuilder: (context, index) => NoteCard(note: items[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!groupByDate) {
      return _grid(
        context,
        notes,
        padding: const EdgeInsets.all(AppSpacing.md),
      );
    }
    final groups = <String, List<NoteEntity>>{};
    for (final note in notes) {
      final key =
          '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}';
      groups.putIfAbsent(key, () => []).add(note);
    }
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              entry.key,
              style: AppTypography.textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _grid(
            context,
            entry.value,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            forceShrink: true,
          ),
        ],
      ],
    );
    if (scrollable) {
      return SingleChildScrollView(child: content);
    }
    return content;
  }
}

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note});

  final NoteEntity note;

  Future<void> _moveToFolder(BuildContext context) async {
    final folderId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => BlocBuilder<FolderBloc, FolderState>(
        builder: (context, state) {
          if (state is FolderLoading || state is FolderInitial) {
            return const AlertDialog(
              content: SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          if (state is FolderError) {
            return AlertDialog(
              title: const Text('Could not load folders'),
              content: Text(state.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            );
          }
          if (state is! FoldersLoaded) return const SizedBox.shrink();
          return SimpleDialog(
            title: const Text('Move note to folder'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, ''),
                child: Row(
                  children: [
                    const Icon(Icons.inbox_outlined),
                    AppSpacing.gapMd,
                    const Text('No folder'),
                    if (note.folderId == null) ...[
                      const Spacer(),
                      const Icon(Icons.check, size: 18),
                    ],
                  ],
                ),
              ),
              for (final folder in state.folders)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, folder.id),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_outlined),
                      AppSpacing.gapMd,
                      Expanded(child: Text(folder.name)),
                      if (note.folderId == folder.id) ...[
                        AppSpacing.gapSm,
                        const Icon(Icons.check, size: 18),
                      ],
                    ],
                  ),
                ),
              if (state.folders.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.sm,
                    AppSpacing.xxl,
                    AppSpacing.lg,
                  ),
                  child: Text('Create a folder from the Folders tab first.'),
                ),
            ],
          );
        },
      ),
    );
    if (folderId == null || !context.mounted) return;
    final updatedFolderId = folderId.isEmpty ? null : folderId;
    if (updatedFolderId == note.folderId) return;
    context.read<NoteBloc>().add(
      UpdateNoteEvent(
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
          folderId: updatedFolderId,
          latitude: note.latitude,
          longitude: note.longitude,
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
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
    final scheme = Theme.of(context).colorScheme;
    final cardTextColor = scheme.onPrimary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _handleTap(context),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primary, scheme.secondary],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: cardTextColor),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Move to folder',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _moveToFolder(context),
                        icon: Icon(
                          note.folderId == null
                              ? Icons.drive_file_move_outline
                              : Icons.folder,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      InkWell(
                        onTap: () => context.read<NoteBloc>().add(
                          DeleteNoteEvent(note.id),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapXs,
                  Text(
                    note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: cardTextColor),
                  ),
                  AppSpacing.gapXs,
                  Text(
                    note.isLocked ? '🔒 Locked note' : note.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cardTextColor.withValues(alpha: 0.7),
                    ),
                  ),
                  AppSpacing.gapXs,
                  if (note.banner != null && note.banner!.isNotEmpty)
                    Image.file(
                      File(note.banner!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
