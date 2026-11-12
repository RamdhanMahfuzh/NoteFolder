import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notefolder/presentation/bloc/folder_bloc.dart';
import 'package:notefolder/presentation/bloc/folder_state.dart';
import 'package:notefolder/presentation/bloc/note_bloc.dart';
import 'package:notefolder/presentation/bloc/note_event.dart';
import 'package:notefolder/presentation/bloc/note_state.dart';
import 'package:notefolder/presentation/widgets/notes_grid.dart';
import 'package:notefolder/presentation/widgets/app_search_bar.dart';

class AllNotesPage extends StatefulWidget {
  const AllNotesPage({super.key});

  @override
  State<AllNotesPage> createState() => _AllNotesPageState();
}

class _AllNotesPageState extends State<AllNotesPage> {
  static const _allFolders = 'all';
  static const _unfiled = 'unfiled';

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _folderFilter = _allFolders;
  bool _newestFirst = true;

  @override
  void initState() {
    super.initState();
    context.read<NoteBloc>().add(const LoadNotes());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All notes')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AppSearchBar(
                controller: _searchCtrl,
                hintText: 'Search notes...',
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: BlocBuilder<FolderBloc, FolderState>(
                      builder: (context, folderState) {
                        if (folderState is FolderError) {
                          return Text(
                            'Could not load folders: ${folderState.message}',
                          );
                        }
                        if (folderState is! FoldersLoaded) {
                          return const LinearProgressIndicator();
                        }
                        final folderExists = folderState.folders.any(
                          (folder) => folder.id == _folderFilter,
                        );
                        final selectedFolder =
                            _folderFilter == _allFolders ||
                                _folderFilter == _unfiled ||
                                folderExists
                            ? _folderFilter
                            : _allFolders;
                        return DropdownButtonFormField<String>(
                          key: ValueKey(selectedFolder),
                          initialValue: selectedFolder,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Folder',
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: _allFolders,
                              child: Text('All folders'),
                            ),
                            const DropdownMenuItem(
                              value: _unfiled,
                              child: Text('Unfiled'),
                            ),
                            for (final folder in folderState.folders)
                              DropdownMenuItem(
                                value: folder.id,
                                child: Text(
                                  folder.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _folderFilter = value);
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<bool>(
                      initialValue: _newestFirst,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sort by',
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: true,
                          child: Text('Newest first'),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text('Oldest first'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _newestFirst = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<NoteBloc, NoteState>(
                builder: (context, state) {
                  if (state is NoteLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is NotesLoaded) {
                    final foldersState = context.read<FolderBloc>().state;
                    final folderFilter =
                        _folderFilter != _allFolders &&
                            _folderFilter != _unfiled &&
                            foldersState is FoldersLoaded &&
                            !foldersState.folders.any(
                              (folder) => folder.id == _folderFilter,
                            )
                        ? _allFolders
                        : _folderFilter;
                    final notes = state.notes.where((note) {
                      final matchesQuery =
                          _query.isEmpty ||
                          '${note.title} ${note.content}'
                              .toLowerCase()
                              .contains(_query);
                      final matchesFolder =
                          folderFilter == _allFolders ||
                          (folderFilter == _unfiled && note.folderId == null) ||
                          note.folderId == folderFilter;
                      return matchesQuery && matchesFolder;
                    }).toList();
                    final sorted = [...notes]
                      ..sort(
                        (a, b) => _newestFirst
                            ? b.createdAt.compareTo(a.createdAt)
                            : a.createdAt.compareTo(b.createdAt),
                      );
                    return NotesGrid(notes: sorted, groupByDate: true);
                  }
                  if (state is NoteError) {
                    return Center(child: Text(state.message));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
