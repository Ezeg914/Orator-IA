// lib/video_player.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VideoPlayerScreen extends StatefulWidget {
  final Uint8List videoData;

  const VideoPlayerScreen({Key? key, required this.videoData}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  late String tempFilePath;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayerFuture = _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    // Obtener el directorio temporal
    final tempDir = await getTemporaryDirectory();
    tempFilePath = '${tempDir.path}/temp_video.mp4';

    // Escribir el video en el archivo temporal
    final tempFile = File(tempFilePath);
    await tempFile.writeAsBytes(widget.videoData);

    _controller = VideoPlayerController.file(tempFile)
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
        backgroundColor: Color(0xFF5A04AC),
      ),
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading video'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying ? _controller.pause() : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
