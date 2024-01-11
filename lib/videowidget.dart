// ignore_for_file: must_be_immutable, empty_catches

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

bool _isLoading = false;

class VideoWidget extends StatefulWidget {
  String url;

  VideoWidget(this.url, {super.key});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController _controller;
  initplayer() async {
    try {
      setState(() {
        _isLoading = true;
      });

      _controller = VideoPlayerController.file(File(widget.url));
      _controller.initialize();
      _controller.setLooping(true);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();

    initplayer();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? SizedBox(
            height: 250,
            width: MediaQuery.of(context).size.width * 0.67,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).dividerColor,
                strokeWidth: 2,
              ),
            ),
          )
        : GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: const BoxConstraints(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IntrinsicHeight(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 350),
                      child: Container(
                        color: Colors.grey.withOpacity(.4),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.all(7),
                    child: Icon(_controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow),
                  ),
                ],
              ),
            ),
          );
  }
}
