import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notefolder/core/themes/app_colors.dart';
import 'package:notefolder/domain/entities/note_entity.dart';
import 'package:notefolder/presentation/bloc/note_bloc.dart';
import 'package:notefolder/presentation/bloc/note_event.dart';
import 'package:notefolder/presentation/widgets/pin_input.dart';
import 'package:notefolder/presentation/bloc/note_state.dart';
import 'package:notefolder/presentation/widgets/content_speech_field.dart';

class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _pin = '';
  final _picker = ImagePicker();
  DateTime? _deadline;
  String? _bannerPath;
  List<String> _contentImages = [];
  List<String> _contentWeather = [];
  List<String> _contentBlockAlignments = [];
  double? _latitude;
  double? _longitude;
  bool _isLocked = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBanner() async {
    try {
      final img = await _picker.pickImage(source: ImageSource.gallery);
      if (img == null) return;
      if (!mounted) return;
      setState(() => _bannerPath = img.path);
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
      firstDate: now,
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
  }

  String _formatDeadline(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$mi';
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content are required')),
      );
      return;
    }
    if (_isLocked && _pin.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN must be 6 digits')));
      return;
    }

    final now = DateTime.now();
    context.read<NoteBloc>().add(
      AddNoteEvent(
        NoteEntity(
          id: now.microsecondsSinceEpoch.toString(),
          banner: _bannerPath,
          title: title,
          content: content,
          contentBlockAlignments: _contentBlockAlignments,
          contentImages: _contentImages,
          contentWeather: _contentWeather,
          deadline: _deadline,
          createdAt: now,
          updatedAt: now,
          isLocked: _isLocked,
          pin: _isLocked ? _pin : null,
          latitude: _latitude,
          longitude: _longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<NoteBloc, NoteState>(
          listener: (context, state) {
            if (state is NoteOperationSuccess) {
              if (state.message != 'Note added') {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
              context.pop();
            }
            if (state is NoteError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final saving =
                state is NoteLoading || state is NoteOperationSuccess;
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
                                            Icons.add_photo_alternate_outlined,
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
                                        errorBuilder: (_, _, _) => const Center(
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
                                child: Material(
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
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _titleCtrl,
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
                            onContentBlockAlignmentsChanged: (alignments) =>
                                setState(
                                  () => _contentBlockAlignments = alignments,
                                ),
                            images: _contentImages,
                            weather: _contentWeather,
                            onImagesChanged: (images) =>
                                setState(() => _contentImages = images),
                            onWeatherChanged: (weather) =>
                                setState(() => _contentWeather = weather),
                            latitude: _latitude,
                            longitude: _longitude,
                            onLocationChanged: (location) => setState(() {
                              _latitude = location?.latitude;
                              _longitude = location?.longitude;
                            }),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
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
                            if (_deadline != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () =>
                                    setState(() => _deadline = null),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Hapus deadline',
                                style: IconButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Lock this note'),
                          secondary: const Icon(Icons.lock_outline),
                          value: _isLocked,
                          onChanged: (val) => setState(() => _isLocked = val),
                        ),
                        if (_isLocked) ...[
                          const SizedBox(height: 8),
                          PinInput(
                            onChanged: (pin) => setState(() => _pin = pin),
                          ),
                        ],
                        const SizedBox(height: 12),
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
                              onPressed: saving ? null : _save,
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
                                      'Add Note',
                                      style: TextStyle(color: AppColors.white),
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
    );
  }
}
