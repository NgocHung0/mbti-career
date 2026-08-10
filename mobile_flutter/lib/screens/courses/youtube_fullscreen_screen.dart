import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../services/course_progress_service.dart';
import '../../core/constants/app_colors.dart';

class YoutubeFullscreenScreen extends StatefulWidget {
  final String videoUrl;
  final int lessonId;
  final int startAtSeconds;

  const YoutubeFullscreenScreen({
    super.key,
    required this.videoUrl,
    required this.lessonId,
    required this.startAtSeconds,
  });

  @override
  State<YoutubeFullscreenScreen> createState() =>
      _YoutubeFullscreenScreenState();
}

class _YoutubeFullscreenScreenState extends State<YoutubeFullscreenScreen> {
  YoutubePlayerController? controller;
  Timer? saveTimer;

  bool finished = false;
  bool popped = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    if (videoId != null && videoId.isNotEmpty) {
      controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
      );

      controller!.addListener(handleVideoState);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.startAtSeconds > 0) {
          controller?.seekTo(Duration(seconds: widget.startAtSeconds));
        }
      });

      saveTimer = Timer.periodic(Duration(seconds: 8), (_) {
        saveCurrentProgress(completed: false);
      });
    }
  }

  void handleVideoState() {
    final c = controller;
    if (c == null || !mounted) return;

    if (c.value.playerState == PlayerState.ended && !finished) {
      finished = true;
      saveCurrentProgress(completed: true);
      closeScreen(completed: true);
    }
  }

  Future<void> saveCurrentProgress({required bool completed}) async {
    final current = controller?.value.position.inSeconds ?? 0;

    try {
      await CourseProgressService.saveProgress(
        lessonId: widget.lessonId,
        videoProgress: current,
        completed: completed,
      );
    } catch (_) {}
  }

  Future<void> closeScreen({bool completed = false}) async {
    if (popped) return;
    popped = true;

    saveTimer?.cancel();

    if (!completed) {
      await saveCurrentProgress(completed: finished);
    }

    if (!mounted) return;

    Navigator.pop(context, {
      'completed': completed || finished,
      'progress': controller?.value.position.inSeconds ?? widget.startAtSeconds,
    });
  }

  @override
  void dispose() {
    saveTimer?.cancel();
    controller?.removeListener(handleVideoState);
    controller?.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        closeScreen(completed: finished);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: controller == null
            ? Center(
                child: Text(
                  'Video không hợp lệ',
                  style: TextStyle(color: AppColors.card(context)),
                ),
              )
            : Stack(
                children: [
                  Center(
                    child: YoutubePlayer(
                      controller: controller!,
                      showVideoProgressIndicator: true,
                    ),
                  ),
                  Positioned(
                    top: 18,
                    left: 18,
                    child: SafeArea(
                      child: IconButton(
                        onPressed: () => closeScreen(completed: finished),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}