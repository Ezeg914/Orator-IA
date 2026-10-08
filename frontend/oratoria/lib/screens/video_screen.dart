import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:oratoria/services/auth_service.dart';

class VideoScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  // Se llama cuando el servidor terminó de analizar y guardar el video
  final VoidCallback? onUploaded;

  VideoScreen(this.cameras, {this.onUploaded});

  @override
  State<VideoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<VideoScreen> {
  late CameraController controller;
  bool _isRecording = false;
  String _videoPath = '';
  int _selectedCameraIndex = 0;
  bool _isFrontCamera = false;
  bool _isFlashOn = false;
  bool _showDialog = false;
  String _videoTitle = '';

  @override
  void initState() {
    super.initState();
    controller = CameraController(widget.cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _toggleFlashLight() {
    if (_isFlashOn) {
      controller.setFlashMode(FlashMode.off);
      setState(() {
        _isFlashOn = false;
      });
    } else {
      controller.setFlashMode(FlashMode.torch);
      setState(() {
        _isFlashOn = true;
      });
    }
  }

  void _switchCamera() async {
    if (controller != null) {
      await controller.dispose();
    }
    _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
    _initCamera(_selectedCameraIndex);
  }

  Future<void> _initCamera(int cameraIndex) async {
    controller = CameraController(widget.cameras[cameraIndex], ResolutionPreset.max);

    try {
      await controller.initialize();
      setState(() {
        _isFrontCamera = cameraIndex == 0;
      });
    } catch (e) {
      print("Error initializing camera: ${e}");
    }

    if (!mounted) {
      return;
    }
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopVideoRecording();
    } else {
      _startVideoRecording();
    }
  }

  void _startVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      try {
        await controller.initialize();
        await controller.startVideoRecording();
        setState(() {
          _isRecording = true;
          _videoPath = path;
        });
      } catch (e) {
        print("Error starting video recording: ${e}");
      }
    }
  }

  void _stopVideoRecording() async {
    if (controller.value.isRecordingVideo) {
      try {
        final XFile videoFile = await controller.stopVideoRecording();
        setState(() {
          _isRecording = false;
          _videoPath = videoFile.path;
        });
        _showUploadDialog();
      } catch (e) {
        print("Error stopping video recording: ${e}");
      }
    }
  }

  Future<void> _uploadVideoToServer(String videoPath, String title) async {
  final Uri url = Uri.parse('$apiBaseUrl/videos/?title=$title');
  final request = http.MultipartRequest('POST', url)
    ..headers.addAll({'Accept': 'application/json', ...AuthService.authHeaders});

  final file = await http.MultipartFile.fromPath('file', videoPath, contentType: MediaType('video', 'mp4'));
  request.files.add(file);

  try {
    final response = await request.send();
    final responseData = await response.stream.toBytes();
    final responseString = String.fromCharCodes(responseData);

    if (response.statusCode == 200) {
      print('Video uploaded successfully: $responseString');
      widget.onUploaded?.call(); // Avisar a la galería aunque ya se haya salido de esta pantalla
      if (!mounted) return;
      Navigator.pop(context); // Close dialog
    } else {
      print('Failed to upload video: ${response.statusCode}');
      print('Error details: $responseString');
      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      _showErrorDialog('Failed to upload video: ${response.statusCode}');
    }
  } catch (e) {
    print('Error uploading video: $e');
    if (!mounted) return;
    Navigator.pop(context); // Close dialog
    _showErrorDialog('Error uploading video: $e');
  }
}

void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Upload Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}





  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Upload Video'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Title'),
                onChanged: (value) {
                  _videoTitle = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_videoTitle.isNotEmpty) {
                  _uploadVideoToServer(_videoPath, _videoTitle);
                } else {
                  print('Title cannot be empty');
                }
              },
              child: Text('Upload'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Optionally delete the file if discarded
                File(_videoPath).delete();
                setState(() {
                  _videoPath = '';
                });
              },
              child: Text('Discard'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Stack(
              children: [
                Positioned.fill(
                  top: 0,
                  bottom: _isFrontCamera == false ? 129 : 129,
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: CameraPreview(controller),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: GestureDetector(
                            onTap: _toggleFlashLight,
                            child: _isFlashOn == false
                                ? Icon(Icons.flash_off, color: Colors.white, size: 30)
                                : Icon(Icons.flash_on, color: Colors.white, size: 30),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: _isFrontCamera == false ? Colors.black : Colors.black,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Container()),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _toggleRecording,
                                      child: Center(
                                        child: Container(
                                          height: 70,
                                          width: 70,
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(50),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                              style: BorderStyle.solid,
                                            ),
                                          ),
                                          child: _isRecording == false
                                              ? Icon(Icons.radio_button_unchecked, color: Colors.white, size: 65)
                                              : Icon(Icons.radio_button_checked, color: Colors.red, size: 65),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _switchCamera,
                                      child: Icon(Icons.cameraswitch, color: Colors.white, size: 30),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
