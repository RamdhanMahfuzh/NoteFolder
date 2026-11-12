import 'package:equatable/equatable.dart';

class NoteEntity extends Equatable {
  const NoteEntity({
    required this.id,
    this.banner,
    required this.title,
    required this.content,
    this.contentBlockAlignments = const [],
    this.contentImages = const [],
    this.contentWeather = const [],
    this.deadline,
    required this.createdAt,
    required this.updatedAt,
    required this.isLocked,
    this.pin,
    this.folderId,
    this.latitude,
    this.longitude,
  });
  final String id;
  final String? banner;
  final String title;
  final String content;
  final List<String> contentBlockAlignments;
  final List<String> contentImages;
  final List<String> contentWeather;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLocked;
  final String? pin;
  final String? folderId;
  final double? latitude;
  final double? longitude;

  @override
  List<Object?> get props => [
    id,
    banner,
    title,
    content,
    contentBlockAlignments,
    contentImages,
    contentWeather,
    deadline,
    createdAt,
    updatedAt,
    isLocked,
    pin,
    folderId,
    latitude,
    longitude,
  ];
}
