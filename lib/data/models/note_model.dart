import 'dart:convert';

import '../../domain/entities/note_entity.dart';

class NoteModel extends NoteEntity {
  const NoteModel({
    required super.id,
    super.banner,
    required super.title,
    required super.content,
    super.contentBlockAlignments,
    super.contentImages,
    super.contentWeather,
    super.deadline,
    required super.createdAt,
    required super.updatedAt,
    required super.isLocked,
    super.pin,
    super.folderId,
    super.latitude,
    super.longitude,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['createdAt'] ?? json['created_at'];
    final updatedAtValue = json['updatedAt'] ?? json['updated_at'];
    final isLockedVal = json['is_locked'] ?? json['isLocked'];

    final content = json['content'] as String;
    final savedAlignments = json['content_block_alignments'] as String?;
    final legacyAlignment = json['content_alignment'] as String? ?? 'left';

    return NoteModel(
      id: json['id'] as String,
      banner: json['banner'] as String?,
      title: json['title'] as String,
      content: content,
      contentBlockAlignments: savedAlignments == null
          ? List<String>.filled(content.split('\n').length, legacyAlignment)
          : List<String>.from(jsonDecode(savedAlignments) as List),
      contentImages: json['content_images'] == null
          ? const []
          : List<String>.from(
              jsonDecode(json['content_images'] as String) as List,
            ),
      contentWeather: json['content_weather'] == null
          ? const []
          : List<String>.from(
              jsonDecode(json['content_weather'] as String) as List,
            ),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      createdAt: DateTime.parse(createdAtValue as String),
      updatedAt: DateTime.parse(updatedAtValue as String),
      isLocked: isLockedVal is int
          ? isLockedVal == 1
          : (isLockedVal as bool? ?? false),
      pin: json['pin'] as String?,
      folderId: json['folder_id'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  NoteEntity toEntity() {
    return NoteEntity(
      id: id,
      banner: banner,
      title: title,
      content: content,
      contentBlockAlignments: contentBlockAlignments,
      contentImages: contentImages,
      contentWeather: contentWeather,
      deadline: deadline,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isLocked: isLocked,
      pin: pin,
      folderId: folderId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'banner': banner,
      'title': title,
      'content': content,
      'content_block_alignments': jsonEncode(contentBlockAlignments),
      'content_images': jsonEncode(contentImages),
      'content_weather': jsonEncode(contentWeather),
      'deadline': deadline?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_locked': isLocked ? 1 : 0,
      'pin': pin,
      'folder_id': folderId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
