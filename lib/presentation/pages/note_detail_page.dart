import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notefolder/core/themes/app_colors.dart';
import 'package:notefolder/domain/entities/note_entity.dart';
import 'package:notefolder/presentation/bloc/note_bloc.dart';
import 'package:notefolder/presentation/bloc/note_event.dart';
import 'package:notefolder/presentation/bloc/note_state.dart';
import 'package:notefolder/presentation/widgets/pin_input.dart';
import 'package:notefolder/presentation/widgets/content_speech_field.dart';

class NoteDetailPage extends StatefulWidget {
  const NoteDetailPage({super.key, required this.noteId});

  final String noteId;

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  late final NoteBloc _bloc;
  Timer? _autosaveTimer;
  String _pin = '';
  final _picker = ImagePicker();
  DateTime? _deadline;
  String? _bannerPath;
  List<String> _contentImages = [];
  List<String> _contentWeather = [];
  List<String> _contentBlockAlignments = [];
  String? _folderId;
  double? _latitude;
  double? _longitude;
  NoteEntity? _note;
  bool _loaded = false;
  bool _isLocked = false;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  bool _closeAfterSave = false;
  bool _popAfterSave = false;
  String _saveStatus = 'All changes saved';

  @override
  void initState() {
    super.initState();
    _bloc = context.read<NoteBloc>();
    _bloc.add(GetNoteById(widget.noteId));
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _fill(NoteEntity note) {
    if (_loaded) return;
    _loaded = true;
    _note = note;
    _titleCtrl.text = note.title;
    _contentCtrl.text = note.content;
    _contentBlockAlignments = [...note.contentBlockAlignments];
    _contentImages = [...note.contentImages];
    _contentWeather = [...note.contentWeather];
    _deadline = note.deadline;
    _bannerPath = note.banner;
    _folderId = note.folderId;
    _latitude = note.latitude;
    _longitude = note.longitude;
    _isLocked = note.isLocked;
    _pin = note.pin ?? '';
    _saveStatus = 'All changes saved';
  }

  bool get _canSaveCurrent =>
      _titleCtrl.text.trim().isNotEmpty &&
      _contentCtrl.text.trim().isNotEmpty &&
      (!_isLocked || _pin.length == 6);

  NoteEntity? _currentNote() {
    final note = _note;
    if (note == null || !_canSaveCurrent) return null;
    return NoteEntity(
      id: note.id,
      banner: _bannerPath,
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      contentBlockAlignments: _contentBlockAlignments,
      contentImages: _contentImages,
      contentWeather: _contentWeather,
      deadline: _deadline,
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
      isLocked: _isLocked,
      pin: _isLocked ? _pin : null,
      folderId: _folderId,
      latitude: _latitude,
      longitude: _longitude,
    );
  }

  bool _matchesCurrent(NoteEntity note) =>
      note.title == _titleCtrl.text.trim() &&
      note.content == _contentCtrl.text.trim() &&
      _listEquals(note.contentBlockAlignments, _contentBlockAlignments) &&
      _listEquals(note.contentImages, _contentImages) &&
      _listEquals(note.contentWeather, _contentWeather) &&
      note.banner == _bannerPath &&
      note.deadline == _deadline &&
      note.isLocked == _isLocked &&
      note.pin == (_isLocked ? _pin : null) &&
      note.folderId == _folderId &&
      note.latitude == _latitude &&
      note.longitude == _longitude;

  bool _listEquals(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  void _scheduleAutosave() {
    if (!_loaded) return;
    _autosaveTimer?.cancel();
    if (_note != null && _matchesCurrent(_note!)) {
      setState(() {
        _hasUnsavedChanges = false;
        _saveStatus = _isSaving ? 'Saving...' : 'All changes saved';
      });
      return;
    }

    setState(() {
      _hasUnsavedChanges = true;
      _saveStatus = 'Unsaved changes';
    });
    _autosaveTimer = Timer(const Duration(milliseconds: 700), () {
      _save(autosave: true);
    });
  }

  Future<void> _pickBanner() async {
    try {
      final img = await _picker.pickImage(source: ImageSource.gallery);
      if (img == null || !mounted) return;
      setState(() => _bannerPath = img.path);
      _scheduleAutosave();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
    );
    if (time == null) return;
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
    _scheduleAutosave();
  }

  String _formatDeadline(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$mi';
  }

  void _save({bool autosave = false}) {
    if (!mounted || _isSaving) return;
    _autosaveTimer?.cancel();
    if (_note == null) return;
    if (!_canSaveCurrent) {
      if (autosave) return;
      final message =
          _titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty
          ? 'Title and content are required'
          : 'PIN must be 6 digits';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    final updatedNote = _currentNote();
    if (updatedNote == null) return;
    _closeAfterSave = !autosave;
    setState(() {
      _isSaving = true;
      _saveStatus = 'Saving...';
    });
    _bloc.add(UpdateNoteEvent(updatedNote));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving && (!_hasUnsavedChanges || !_canSaveCurrent),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _closeAfterSave = false;
          _popAfterSave = false;
          _bloc.add(const LoadNotes());
        } else {
          _popAfterSave = true;
          if (!_isSaving) _save(autosave: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail'),
          actions: [
            if (_folderId != null)
              IconButton(
                tooltip: 'Move to no folder',
                onPressed: _isSaving
                    ? null
                    : () {
                        setState(() => _folderId = null);
                        _scheduleAutosave();
                      },
                icon: const Icon(Icons.folder_off_outlined),
              ),
          ],
        ),
        body: SafeArea(
          child: BlocConsumer<NoteBloc, NoteState>(
            listener: (context, state) {
              if (state is NoteDetailLoaded) _fill(state.note);
              if (state is NoteOperationSuccess &&
                  state.note?.id == _note?.id) {
                if (state.message != 'Note updated') {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
                _isSaving = false;
                _note = state.note;
                _hasUnsavedChanges = !_matchesCurrent(state.note!);
                if (_hasUnsavedChanges) {
                  _scheduleAutosave();
                } else {
                  _saveStatus = 'All changes saved';
                  if (_closeAfterSave || _popAfterSave) {
                    _closeAfterSave = false;
                    _popAfterSave = false;
                    context.pop();
                  }
                }
              }
              if (state is NoteError) {
                if (_isSaving) {
                  _isSaving = false;
                  _saveStatus = 'Save failed';
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              if (state is NoteLoading && !_loaded) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_note == null) {
                return const Center(child: Text('Note not found'));
              }
              final saving = state is NoteLoading;
              return LayoutBuilder(
                builder: (context, viewport) => SingleChildScrollView(
                  padding: const EdgeInsets.all(18.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: viewport.maxHeight - 36,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GestureDetector(
                            onTap: _pickBanner,
                            behavior: HitTestBehavior.opaque,
                            child: Stack(
                              children: [
                                Container(
                                  height: 90,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: _bannerPath == null
                                        ? const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              AppColors.primary,
                                              AppColors.secondary,
                                            ],
                                          )
                                        : null,
                                    color: _bannerPath == null
                                        ? null
                                        : Colors.black12,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _bannerPath == null
                                      ? const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons
                                                  .add_photo_alternate_outlined,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Add banner',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Image.file(
                                          File(_bannerPath!),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Center(
                                                    child: Text(
                                                      'Could not load image',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                        ),
                                ),
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_bannerPath != null)
                                        Material(
                                          color: Colors.black54,
                                          shape: const CircleBorder(),
                                          child: InkWell(
                                            customBorder: const CircleBorder(),
                                            onTap: () {
                                              setState(
                                                () => _bannerPath = null,
                                              );
                                              _scheduleAutosave();
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Icon(
                                                Icons.delete_outline,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (_bannerPath != null)
                                        const SizedBox(width: 8),
                                      Material(
                                        color: Colors.black54,
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: _pickBanner,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Icon(
                                              _bannerPath == null
                                                  ? Icons.add_a_photo
                                                  : Icons.edit,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _titleCtrl,
                            onChanged: (_) => _scheduleAutosave(),
                            decoration: InputDecoration(
                              hintText: 'Title',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ContentSpeechField(
                              controller: _contentCtrl,
                              contentBlockAlignments: _contentBlockAlignments,
                              onContentBlockAlignmentsChanged: (alignments) {
                                setState(
                                  () => _contentBlockAlignments = alignments,
                                );
                                _scheduleAutosave();
                              },
                              images: _contentImages,
                              weather: _contentWeather,
                              onImagesChanged: (images) {
                                setState(() => _contentImages = images);
                                _scheduleAutosave();
                              },
                              onWeatherChanged: (weather) {
                                setState(() => _contentWeather = weather);
                                _scheduleAutosave();
                              },
                              latitude: _latitude,
                              longitude: _longitude,
                              onLocationChanged: (location) {
                                setState(() {
                                  _latitude = location?.latitude;
                                  _longitude = location?.longitude;
                                });
                                _scheduleAutosave();
                              },
                              onChanged: (_) => _scheduleAutosave(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              icon: const Icon(Icons.schedule),
                              label: Text(
                                _deadline == null
                                    ? 'Set deadline'
                                    : _formatDeadline(_deadline!),
                              ),
                              onPressed: _pickDeadline,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Lock this note'),
                            secondary: const Icon(Icons.lock_outline),
                            value: _isLocked,
                            onChanged: (val) {
                              setState(() => _isLocked = val);
                              _scheduleAutosave();
                            },
                          ),
                          if (_isLocked) ...[
                            const SizedBox(height: 8),
                            PinInput(
                              initialPin: _pin,
                              onChanged: (pin) {
                                _pin = pin;
                                _scheduleAutosave();
                              },
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            _saveStatus,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.primary,
                                    AppColors.secondary,
                                  ],
                                ),
                              ),
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: saving ? null : () => _save(),
                                child: saving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          color: AppColors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
