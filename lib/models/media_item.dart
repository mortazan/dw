enum MediaKind {
  audio('آهنگ'),
  video('ویدیو'),
  link('لینک');

  const MediaKind(this.label);
  final String label;

  static MediaKind parse(Object? value) => MediaKind.values.firstWhere(
        (k) => k.name == value,
        orElse: () => MediaKind.link,
      );
}

/// A favourite song, video or link shown in the dashboard slider.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.kind,
    required this.source,
    this.cover,
  });

  final String id;
  final String title;
  final MediaKind kind;

  /// A file path (audio/video) or a web address (link).
  final String source;

  /// Optional path of a custom thumbnail image.
  final String? cover;

  MediaItem copyWith({
    String? title,
    String? cover,
    bool clearCover = false,
    MediaKind? kind,
    String? source,
  }) =>
      MediaItem(
        id: id,
        title: title ?? this.title,
        kind: kind ?? this.kind,
        source: source ?? this.source,
        cover: clearCover ? null : (cover ?? this.cover),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'kind': kind.name,
        'source': source,
        'cover': cover,
      };

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        id: json['id'] as String,
        title: json['title'] as String,
        kind: MediaKind.parse(json['kind']),
        source: json['source'] as String,
        cover: json['cover'] as String?,
      );
}
