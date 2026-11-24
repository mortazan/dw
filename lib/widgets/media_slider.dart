import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../models/media_item.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';

IconData _kindIcon(MediaKind k) {
  switch (k) {
    case MediaKind.audio:
      return Icons.music_note_rounded;
    case MediaKind.video:
      return Icons.play_circle_fill_rounded;
    case MediaKind.link:
      return Icons.link_rounded;
  }
}

Color _kindColor(MediaKind k) {
  switch (k) {
    case MediaKind.audio:
      return kPurple;
    case MediaKind.video:
      return const Color(0xFFF0607A);
    case MediaKind.link:
      return kBlue;
  }
}

/// A horizontal strip of small thumbnails. Tap to play, long-press to edit.
class MediaSlider extends StatelessWidget {
  const MediaSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final items = appState.media;
    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final m in items)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: _Thumb(item: m),
            ),
          _AddThumb(empty: items.isEmpty),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final color = _kindColor(item.kind);
    final cover = item.cover;
    final hasCover = cover != null && File(cover).existsSync();
    return GestureDetector(
      onTap: () => playMedia(context, item),
      onLongPress: () => showMediaEditor(context, existing: item),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: hasCover
                    ? null
                    : LinearGradient(
                        colors: [color, color.withValues(alpha: 0.6)],
                      ),
                image: hasCover
                    ? DecorationImage(image: FileImage(File(cover)), fit: BoxFit.cover)
                    : null,
              ),
              child: Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_kindIcon(item.kind), color: Colors.white, size: 14),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddThumb extends StatelessWidget {
  const _AddThumb({required this.empty});

  final bool empty;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => showMediaEditor(context),
        child: SizedBox(
          width: empty ? 150 : 64,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.5), width: 1.5),
                ),
                child: const Icon(Icons.add, color: kPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                empty ? 'آهنگ یا ویدیوی دلخواه را اضافه کنید' : 'افزودن',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: kMuted),
              ),
            ],
          ),
        ),
      );
}

Future<String> _copyIntoApp(String path, String prefix) async {
  final dir = await getApplicationDocumentsDirectory();
  final dot = path.lastIndexOf('.');
  final ext = dot == -1 ? '' : path.substring(dot);
  final saved = await File(path).copy(
    '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext',
  );
  return saved.path;
}

String _nameOf(String path) {
  final file = path.split('/').last;
  final dot = file.lastIndexOf('.');
  return dot > 0 ? file.substring(0, dot) : file;
}

/// Add a new item, or edit/delete [existing].
Future<void> showMediaEditor(BuildContext context, {MediaItem? existing}) async {
  final titleController = TextEditingController(text: existing?.title ?? '');
  final linkController = TextEditingController();
  var kind = existing?.kind ?? MediaKind.audio;
  String? pickedPath;
  String? cover = existing?.cover;
  String? error;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(existing == null ? 'افزودن به اسلایدر' : 'ویرایش'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (existing == null) ...[
                Wrap(
                  spacing: 8,
                  children: [
                    for (final k in MediaKind.values)
                      ChoiceChip(
                        selected: kind == k,
                        onSelected: (_) => setState(() {
                          kind = k;
                          pickedPath = null;
                          error = null;
                        }),
                        label: Text(k.label),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (kind == MediaKind.link)
                  TextField(
                    controller: linkController,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'آدرس (مثلاً لینک یوتیوب)',
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: kind == MediaKind.audio ? FileType.audio : FileType.video,
                      );
                      final path = result?.files.single.path;
                      if (path == null) return;
                      setState(() {
                        pickedPath = path;
                        if (titleController.text.trim().isEmpty) {
                          titleController.text = _nameOf(path);
                        }
                      });
                    },
                    icon: const Icon(Icons.folder_open),
                    label: Text(
                      pickedPath == null ? 'انتخاب فایل' : _nameOf(pickedPath!),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'عنوان', errorText: error),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final img = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 400,
                          imageQuality: 80,
                        );
                        if (img == null) return;
                        final saved = await _copyIntoApp(img.path, 'cover');
                        setState(() => cover = saved);
                      },
                      icon: const Icon(Icons.image_outlined),
                      label: Text(cover == null ? 'تصویر بندانگشتی' : 'تغییر تصویر'),
                    ),
                  ),
                  if (cover != null)
                    IconButton(
                      onPressed: () => setState(() => cover = null),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE5484D)),
              onPressed: () {
                Navigator.pop(dialogContext);
                appState.deleteMedia(existing.id);
              },
              child: const Text('حذف'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (existing != null) {
                if (title.isEmpty) {
                  setState(() => error = 'عنوان را وارد کنید');
                  return;
                }
                Navigator.pop(dialogContext);
                await appState.updateMedia(
                  existing.copyWith(
                    title: title,
                    cover: cover,
                    clearCover: cover == null,
                  ),
                );
                return;
              }
              final String source;
              if (kind == MediaKind.link) {
                var url = linkController.text.trim();
                if (url.isNotEmpty && !url.contains('://')) url = 'https://$url';
                if (Uri.tryParse(url)?.hasAuthority != true) {
                  setState(() => error = 'آدرس معتبر وارد کنید');
                  return;
                }
                source = url;
              } else {
                if (pickedPath == null) {
                  setState(() => error = 'ابتدا یک فایل انتخاب کنید');
                  return;
                }
                source = await _copyIntoApp(pickedPath!, 'media');
              }
              final item = MediaItem(
                id: const Uuid().v4(),
                title: title.isEmpty ? (kind == MediaKind.link ? 'لینک' : _nameOf(source)) : title,
                kind: kind,
                source: source,
                cover: cover,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              await appState.addMedia(item);
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    ),
  );
  titleController.dispose();
  linkController.dispose();
}

Future<void> playMedia(BuildContext context, MediaItem item) async {
  switch (item.kind) {
    case MediaKind.link:
      final ok = await launchUrl(
        Uri.parse(item.source),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) {
        messengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('لینک باز نشد')),
        );
      }
    case MediaKind.audio:
      if (!File(item.source).existsSync()) {
        messengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('فایل پیدا نشد')),
        );
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: pal(context).card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => _AudioSheet(item: item),
      );
    case MediaKind.video:
      if (!File(item.source).existsSync()) {
        messengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('فایل پیدا نشد')),
        );
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VideoPage(item: item)),
      );
  }
}

String _mmss(Duration d) =>
    toFa('${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}');

class _AudioSheet extends StatefulWidget {
  const _AudioSheet({required this.item});

  final MediaItem item;

  @override
  State<_AudioSheet> createState() => _AudioSheetState();
}

class _AudioSheetState extends State<_AudioSheet> {
  final player = AudioPlayer();
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool playing = false;

  @override
  void initState() {
    super.initState();
    player.onPositionChanged.listen((p) {
      if (mounted) setState(() => position = p);
    });
    player.onDurationChanged.listen((d) {
      if (mounted) setState(() => duration = d);
    });
    player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => playing = false);
    });
    player.play(DeviceFileSource(widget.item.source));
    playing = true;
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxMs = duration.inMilliseconds.toDouble();
    final value = position.inMilliseconds
        .toDouble()
        .clamp(0.0, maxMs <= 0 ? 1.0 : maxMs)
        .toDouble();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_note_rounded, size: 40, color: kPurple),
            const SizedBox(height: 8),
            Text(
              widget.item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: value,
              max: maxMs <= 0 ? 1.0 : maxMs,
              onChanged: (v) => player.seek(Duration(milliseconds: v.toInt())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(_mmss(position)), Text(_mmss(duration))],
            ),
            const SizedBox(height: 8),
            IconButton.filled(
              iconSize: 34,
              onPressed: () async {
                if (playing) {
                  await player.pause();
                } else {
                  await player.resume();
                }
                setState(() => playing = !playing);
              },
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPage extends StatefulWidget {
  const VideoPage({super.key, required this.item});

  final MediaItem item;

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late final VideoPlayerController controller;
  bool ready = false;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.file(File(widget.item.source))
      ..addListener(() {
        if (mounted) setState(() {});
      })
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => ready = true);
        controller.play();
      });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = controller.value;
    final maxMs = v.duration.inMilliseconds.toDouble();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.item.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ready
                  ? AspectRatio(
                      aspectRatio: v.aspectRatio,
                      child: VideoPlayer(controller),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
          if (ready)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              child: Row(
                children: [
                  IconButton(
                    color: Colors.white,
                    onPressed: () =>
                        v.isPlaying ? controller.pause() : controller.play(),
                    icon: Icon(v.isPlaying ? Icons.pause : Icons.play_arrow),
                  ),
                  Expanded(
                    child: Slider(
                      value: v.position.inMilliseconds
                          .toDouble()
                          .clamp(0.0, maxMs <= 0 ? 1.0 : maxMs)
                          .toDouble(),
                      max: maxMs <= 0 ? 1.0 : maxMs,
                      onChanged: (x) =>
                          controller.seekTo(Duration(milliseconds: x.toInt())),
                    ),
                  ),
                  Text(
                    _mmss(v.position),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
