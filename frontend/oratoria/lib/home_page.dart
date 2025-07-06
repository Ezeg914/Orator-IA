// lib/home_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:oratoria/screens/video_detail_screen.dart';
import 'package:oratoria/screens/video_player_screen.dart';
import 'package:oratoria/screens/video_screen.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras = [];

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> videosData = [];

  @override
  void initState() {
    super.initState();
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    final response = await http.get(Uri.parse('http://192.168.1.42:5000/api/videos/'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);

      setState(() {
        videosData = data.map((item) {
          List<dynamic> emotionList = json.decode(item['emotion_json']); // Decodificar emoción JSON
          return {
            'id': item['id'],
            'title': item['title'],
            'emotions': emotionList.cast<String>(),
            'video_data': base64Decode(item['video_data']),
            'path': item['path'],
          };
        }).toList();
      });
    } else {
      throw Exception('Failed to load videos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 40,
            left: 20,
            child: Text(
              "Orator-IA",
              style: TextStyle(
                color: Color(0xFF5A04AC),
                fontSize: 30,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(2.0, 2.0),
                    blurRadius: 3.0,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.only(top: 100, left: 10, right: 10, bottom: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF5A04AC),
                    Color(0xFF9C6AFA),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(20),
                  topRight: Radius.circular(80),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF9C6AFA),
                    offset: Offset(3, 6),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      "Gallery",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: videosData.length,
                      itemBuilder: (context, index) {
                        final video = videosData[index];
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(45, 131, 7, 125),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                offset: Offset(2, 4),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: VideoThumbnail(
                            title: video['title'],
                            emotions: video['emotions'],
                            videoData: video['video_data'] ?? Uint8List(0),
                            path: video['path'] ?? '',
                            onPlay: () {
                              Navigator.push(
                                context,
                                _createRoute(VideoPlayerScreen(videoData: video['video_data'])),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            _createRoute(VideoScreen(cameras)),
          );
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

Route _createRoute(Widget screen) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}

class VideoThumbnail extends StatelessWidget {
  final String title;
  final List<String> emotions;
  final Uint8List videoData;
  final String path;
  final VoidCallback onPlay;

  const VideoThumbnail({
    Key? key,
    required this.title,
    required this.emotions,
    required this.videoData,
    required this.path,
    required this.onPlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: path,
      child: GestureDetector(
        onTap: onPlay,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(2, 4),
                blurRadius: 5,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
                  image: DecorationImage(
                    image: AssetImage('assets/123.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A04AC),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            _createRoute(VideoDetailScreen(
                              title: title,
                              emotions: emotions,
                            )),
                          );
                        },
                        child: Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.play_arrow, color: Color(0xFF5A04AC)),
                onPressed: onPlay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
