import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class VideoDetailScreen extends StatelessWidget {
  final String title;
  final List<String> emotions;

  const VideoDetailScreen({
    Key? key,
    required this.title,
    required this.emotions,
  }) : super(key: key);

  // Función para contar la frecuencia de cada emoción
  Map<String, int> _countEmotions(List<String> emotions) {
    Map<String, int> emotionCounts = {};

    for (var emotion in emotions) {
      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
    }

    return emotionCounts;
  }

  // Función para calcular el porcentaje de cada emoción
  Map<String, double> _calculateEmotionPercentages(Map<String, int> emotionCounts) {
    int totalEmotions = emotionCounts.values.reduce((a, b) => a + b);
    Map<String, double> emotionPercentages = {};

    emotionCounts.forEach((emotion, count) {
      emotionPercentages[emotion] = (count / totalEmotions) * 100;
    });

    return emotionPercentages;
  }

  @override
  Widget build(BuildContext context) {
    final emotionCounts = _countEmotions(emotions);
    final emotionPercentages = _calculateEmotionPercentages(emotionCounts);
    final List<MapEntry<String, double>> sortedEmotions = emotionPercentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Convertir las emociones y sus valores en listas separadas
    List<String> emotionLabels = sortedEmotions.map((e) => e.key).toList();
    List<double> emotionValues = sortedEmotions.map((e) => e.value).toList();

    // Calcular el valor máximo de las emociones
    double maxEmotionValue = emotionValues.isNotEmpty ? emotionValues.reduce((a, b) => a > b ? a : b) : 100.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF5A04AC),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gráfico de Radar
          Container(
            height: 300,
            margin: const EdgeInsets.all(16.0),
            child: AnimatedRadarChart(
              emotionLabels: emotionLabels,
              emotionValues: emotionValues,
              maxEmotionValue: maxEmotionValue,
            ),
          ),
          // Fondo del detalle
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
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
                      'Details:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20.0),
                      itemCount: sortedEmotions.length,
                      itemBuilder: (context, index) {
                        final emotion = sortedEmotions[index];
                        return EmotionDetail(
                          emotion: emotion,
                          maxEmotionValue: maxEmotionValue,
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
    );
  }
}

class AnimatedRadarChart extends StatefulWidget {
  final List<String> emotionLabels;
  final List<double> emotionValues;
  final double maxEmotionValue;

  const AnimatedRadarChart({
    Key? key,
    required this.emotionLabels,
    required this.emotionValues,
    required this.maxEmotionValue,
  }) : super(key: key);

  @override
  _AnimatedRadarChartState createState() => _AnimatedRadarChartState();
}

class _AnimatedRadarChartState extends State<AnimatedRadarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return RadarChart(
          RadarChartData(
            borderData: FlBorderData(show: false),
            radarBorderData: BorderSide(color: Colors.black, width: 1),
            radarBackgroundColor: Colors.grey[200],
            gridBorderData: BorderSide(color: Colors.grey, width: 1),
            tickBorderData: BorderSide(color: Colors.grey, width: 1),
            titlePositionPercentageOffset: 0.2,
            getTitle: (index, angle) {
              return RadarChartTitle(
                text: widget.emotionLabels[index],
                positionPercentageOffset: 0.2,
              );
            },
            dataSets: [
              RadarDataSet(
                dataEntries: List.generate(
                  widget.emotionLabels.length,
                  (index) => RadarEntry(value: widget.emotionValues[index] * _animation.value),
                ),
                fillColor: Color(0xFF5A04AC).withOpacity(0.3),
                borderColor: Color(0xFF5A04AC),
                borderWidth: 2,
                entryRadius: 4,
              ),
            ],
            radarShape: RadarShape.circle,
            ticksTextStyle: TextStyle(color: Colors.black, fontSize: 10),
            tickCount: (widget.maxEmotionValue / 10).ceil(),
          ),
        );
      },
    );
  }
}

class EmotionDetail extends StatelessWidget {
  final MapEntry<String, double> emotion;
  final double maxEmotionValue;

  const EmotionDetail({
    Key? key,
    required this.emotion,
    required this.maxEmotionValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(1, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            emotion.key,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A04AC),
            ),
          ),
          AnimatedCircularProgressIndicator(
            value: emotion.value / maxEmotionValue,
            color: Color(0xFF5A04AC),
            percentage: '${emotion.value.toStringAsFixed(2)}%',
          ),
        ],
      ),
    );
  }
}

class AnimatedCircularProgressIndicator extends StatefulWidget {
  final double value;
  final Color color;
  final String percentage;

  const AnimatedCircularProgressIndicator({
    Key? key,
    required this.value,
    required this.color,
    required this.percentage,
  }) : super(key: key);

  @override
  _AnimatedCircularProgressIndicatorState createState() =>
      _AnimatedCircularProgressIndicatorState();
}

class _AnimatedCircularProgressIndicatorState
    extends State<AnimatedCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CircularProgressIndicator(
              value: _animation.value,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
            );
          },
        ),
        SizedBox(height: 5),
        Text(
          widget.percentage,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
