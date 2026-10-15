import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

enum _Source { youtube, vimeo, file, other }

/// What a lesson's video link points to, and the id the player needs.
class LessonVideoSource {
  LessonVideoSource._(this._source, this.id, this.url);

  factory LessonVideoSource.parse(String url) {
    final youtube = YoutubePlayerController.convertUrlToId(url);
    if (youtube != null) return LessonVideoSource._(_Source.youtube, youtube, url);
    final vimeo = RegExp(r'vimeo\.com/(?:video/)?(\d+)').firstMatch(url)?.group(1);
    if (vimeo != null) return LessonVideoSource._(_Source.vimeo, vimeo, url);
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    if (RegExp(r'\.(mp4|m4v|mov|webm|m3u8)$').hasMatch(path)) return LessonVideoSource._(_Source.file, '', url);
    return LessonVideoSource._(_Source.other, '', url);
  }

  final _Source _source;
  final String id;
  final String url;

  /// Whether the app can play it itself (YouTube, Vimeo, or a video file).
  bool get playsInApp => _source != _Source.other;

  String? get thumbnailUrl => _source == _Source.youtube ? 'https://i.ytimg.com/vi/$id/hqdefault.jpg' : null;
}

/// A lesson's video: a thumbnail with a play button, then the video itself, played in the app.
class LessonVideo extends StatefulWidget {
  const LessonVideo({super.key, required this.url, this.durationMinutes = 0});

  final String url;
  final int durationMinutes;

  @override
  State<LessonVideo> createState() => _LessonVideoState();
}

class _LessonVideoState extends State<LessonVideo> {
  late LessonVideoSource _source = LessonVideoSource.parse(widget.url);
  bool _playing = false;

  @override
  void didUpdateWidget(covariant LessonVideo old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _source = LessonVideoSource.parse(widget.url);
      _playing = false;
    }
  }

  void _play() {
    if (_source.playsInApp) {
      setState(() => _playing = true);
    } else {
      openLink(context, widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = !_playing
        ? _Thumbnail(source: _source, durationMinutes: widget.durationMinutes, onPlay: _play)
        : switch (_source._source) {
            _Source.youtube => _YoutubeVideo(id: _source.id),
            _Source.vimeo => _VimeoVideo(id: _source.id),
            _Source.file => _FileVideo(url: _source.url),
            _Source.other => const SizedBox.shrink(),
          };
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(aspectRatio: 16 / 9, child: ColoredBox(color: Colors.black, child: content)),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.source, required this.durationMinutes, required this.onPlay});

  final LessonVideoSource source;
  final int durationMinutes;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fallback = DecoratedBox(decoration: BoxDecoration(gradient: p.gradient));
    final image = source.thumbnailUrl;
    return Semantics(
      button: true,
      label: source.playsInApp ? 'Play the video' : 'Open the video',
      child: GestureDetector(
        key: const ValueKey('play-video'),
        onTap: onPlay,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image == null)
              fallback
            else
              Image.network(image, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback),
            // Darken the picture a little so the play button stands out.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x10000000), Color(0x80000000)],
                ),
              ),
            ),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
                ),
                child: Icon(
                  source.playsInApp ? LucideIcons.play : LucideIcons.externalLink,
                  color: p.brand,
                  size: 28,
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 10,
              right: 12,
              child: Row(
                children: [
                  Text(
                    source.playsInApp ? 'Watch the video' : 'Open the video',
                    style: context.text.labelLarge?.copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  if (durationMinutes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$durationMinutes min',
                        style: context.text.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
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

class _YoutubeVideo extends StatefulWidget {
  const _YoutubeVideo({required this.id});
  final String id;

  @override
  State<_YoutubeVideo> createState() => _YoutubeVideoState();
}

class _YoutubeVideoState extends State<_YoutubeVideo> {
  late final _controller = YoutubePlayerController.fromVideoId(
    videoId: widget.id,
    autoPlay: true,
    params: const YoutubePlayerParams(showFullscreenButton: true, strictRelatedVideos: true),
  );

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => YoutubePlayer(controller: _controller, backgroundColor: Colors.black);
}

class _VimeoVideo extends StatefulWidget {
  const _VimeoVideo({required this.id});
  final String id;

  @override
  State<_VimeoVideo> createState() => _VimeoVideoState();
}

class _VimeoVideoState extends State<_VimeoVideo> {
  late final _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.black)
    ..loadRequest(Uri.parse('https://player.vimeo.com/video/${widget.id}?autoplay=1&playsinline=1&dnt=1'));

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}

/// A direct video file (MP4, HLS…), with play/pause and a progress bar.
class _FileVideo extends StatefulWidget {
  const _FileVideo({required this.url});
  final String url;

  @override
  State<_FileVideo> createState() => _FileVideoState();
}

class _FileVideoState extends State<_FileVideo> {
  late final _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.initialize().then((_) => _controller.play(), onError: (_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (_failed) {
      return Center(
        child: TextButton.icon(
          onPressed: () => openLink(context, widget.url),
          icon: const Icon(LucideIcons.externalLink, color: Colors.white, size: 16),
          label: const Text("This video can't play here. Open it", style: TextStyle(color: Colors.white)),
        ),
      );
    }
    final value = _controller.value;
    if (!value.isInitialized) return const Center(child: CircularProgressIndicator(color: Colors.white));
    return GestureDetector(
      onTap: () => value.isPlaying ? _controller.pause() : _controller.play(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: AspectRatio(aspectRatio: value.aspectRatio, child: VideoPlayer(_controller))),
          if (!value.isPlaying)
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                child: const Icon(LucideIcons.play, color: Colors.white),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              padding: const EdgeInsets.only(top: 12),
              colors: VideoProgressColors(playedColor: p.brand2, bufferedColor: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }
}
