// lib/home_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:oratoria/screens/video_detail_screen.dart';
import 'package:oratoria/screens/video_player_screen.dart';
import 'package:oratoria/screens/video_screen.dart';
import 'package:oratoria/screens/login_screen.dart';
import 'package:oratoria/services/auth_service.dart';
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

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> fetchVideos() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/videos/'),
      headers: AuthService.authHeaders,
    );

    if (response.statusCode == 401) {
      // Sesión vencida o inválida: volver al login
      await _logout();
      return;
    }

    if (!mounted) {
      return;
    }

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);

      setState(() {
        videosData = data.map((item) {
          List<dynamic> emotionList = json.decode(item['emotion_json']); // Decodificar emoción JSON
          return {
            'id': item['id'],
            'title': item['title'],
            'emotions': emotionList.cast<String>(),
          };
        }).toList();
      });
    } else {
      throw Exception('Failed to load videos');
    }
  }

  // El listado no trae el video (es pesado): se descarga recién al reproducirlo
  Future<void> _playVideo(int videoId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    Uint8List? videoData;
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/videos/$videoId'),
        headers: AuthService.authHeaders,
      );
      if (response.statusCode == 200) {
        videoData = base64Decode(json.decode(response.body)['video_data']);
      } else {
        print('Failed to load video: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading video: $e');
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(); // Close loading dialog

    if (videoData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load the video')),
      );
      return;
    }
    Navigator.push(
      context,
      _createRoute(VideoPlayerScreen(videoData: videoData)),
    );
  }

  Future<void> _deleteVideo(int videoId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete video'),
          content: Text('Delete "$title"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    int? statusCode;
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/videos/$videoId'),
        headers: AuthService.authHeaders,
      );
      statusCode = response.statusCode;
    } catch (e) {
      print('Error deleting video: $e');
    }

    if (statusCode == 401) {
      await _logout();
      return;
    }
    if (!mounted) {
      return;
    }
    // 404: ya no existe en el servidor, también se saca de la lista
    if (statusCode == 200 || statusCode == 404) {
      setState(() {
        videosData.removeWhere((video) => video['id'] == videoId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete the video')),
      );
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
          Positioned(
            top: 36,
            right: 10,
            child: Row(
              children: [
                Text(
                  AuthService.username,
                  style: TextStyle(
                    color: Color(0xFF5A04AC),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.logout, color: Color(0xFF5A04AC)),
                  tooltip: 'Log out',
                  onPressed: _logout,
                ),
              ],
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
                    // Deslizar hacia abajo para recargar la galería
                    child: RefreshIndicator(
                      onRefresh: fetchVideos,
                      color: Color(0xFF5A04AC),
                      child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                            videoData: Uint8List(0),
                            path: 'video-${video['id']}', // Tag único del Hero por video
                            onPlay: () => _playVideo(video['id']),
                            onDelete: () => _deleteVideo(video['id'], video['title']),
                          ),
                        );
                      },
                      ),
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
            // Recargar la galería apenas el servidor termina de analizar el video
            _createRoute(VideoScreen(cameras, onUploaded: fetchVideos)),
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
  final VoidCallback onDelete;

  const VideoThumbnail({
    Key? key,
    required this.title,
    required this.emotions,
    required this.videoData,
    required this.path,
    required this.onPlay,
    required this.onDelete,
  }) : super(key: key);

  // Texto del chip: la emoción que más aparece y su porcentaje
  String get _summary {
    if (emotions.isEmpty) {
      return 'No emotions detected';
    }
    final Map<String, int> counts = {};
    for (var emotion in emotions) {
      counts[emotion] = (counts[emotion] ?? 0) + 1;
    }
    final top = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    final percentage = (top.value / emotions.length * 100).round();
    return 'Mostly ${top.key} · $percentage%';
  }

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
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Miniatura con el botón de play encima
                SizedBox(
                  width: 105,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset('assets/123.jpg', fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF5A04AC).withOpacity(0.55),
                              Color(0xFF9C6AFA).withOpacity(0.15),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(Icons.play_arrow_rounded, color: Color(0xFF5A04AC), size: 32),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A04AC),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Emoción predominante del video
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Color(0xFF9C6AFA).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.insights_rounded, size: 15, color: Color(0xFF5A04AC)),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  _summary,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF5A04AC),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    _createRoute(VideoDetailScreen(
                                      title: title,
                                      emotions: emotions,
                                    )),
                                  );
                                },
                                icon: Icon(Icons.bar_chart_rounded, size: 18),
                                label: Text('View Details'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF5A04AC),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, color: Color(0xFF9C6AFA)),
                              tooltip: 'Delete',
                              onPressed: onDelete,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
