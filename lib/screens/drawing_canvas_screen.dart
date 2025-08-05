import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';

class DrawingCanvasScreen extends StatefulWidget {
  const DrawingCanvasScreen({super.key});

  @override
  State<DrawingCanvasScreen> createState() => DrawingCanvasScreenState();
}

class DrawingCanvasScreenState extends State<DrawingCanvasScreen> {
  List<Offset> points = [];
  GlobalKey canvasKey = GlobalKey();
  String resultText = "";
  List<Map<String, dynamic>>? details;
  double? averageConfidence;

  void clearCanvas() {
    setState(() {
      points.clear();
      resultText = "";
      details = null;
      averageConfidence = null;
    });
  }

  Future<void> predict() async {
    RenderRepaintBoundary boundary =
    canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image canvasImage = await boundary.toImage();
    ByteData? byteData =
    await canvasImage.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    Directory tempDir = await getTemporaryDirectory();
    String filePath = '${tempDir.path}/drawing.png';
    File imageFile = File(filePath);
    await imageFile.writeAsBytes(pngBytes);

    Map<String, dynamic>? response =
    await ApiService.sendImageForPrediction(imageFile);

    List<Map<String, dynamic>> predictionDetails = [];
    double? avgConf;

    if (response != null) {
      if (response['characters'] != null) {
        predictionDetails =
        List<Map<String, dynamic>>.from(response['characters']);
        if (predictionDetails.isNotEmpty) {
          double sum = 0;
          for (Map<String, dynamic> item in predictionDetails) {
            sum += item['confidence'];
          }
          avgConf = sum / predictionDetails.length;
        }
      }

      if (avgConf == null && response['confidence'] != null) {
        avgConf = response['confidence'].toDouble();
      }

      setState(() {
        resultText = response['prediction'] ?? "";
        averageConfidence = avgConf;
        details = predictionDetails.isNotEmpty ? predictionDetails : null;
      });
    }
  }

  Widget buildCanvas() {
    return RepaintBoundary(
      key: canvasKey,
      child: Container(
        width: 350,
        height: 350,
        color: Colors.white,
        child: GestureDetector(
          onPanUpdate: (dragDetails) {
            RenderBox? renderBox =
            canvasKey.currentContext!.findRenderObject() as RenderBox?;
            Offset localPosition =
            renderBox!.globalToLocal(dragDetails.globalPosition);

            if (localPosition.dx >= 0 &&
                localPosition.dy >= 0 &&
                localPosition.dx <= renderBox.size.width &&
                localPosition.dy <= renderBox.size.height) {
              setState(() {
                points.add(localPosition);
              });
            }
          },
          onPanEnd: (_) {
            setState(() {
              points.add(Offset.infinite);
            });
          },
          child: CustomPaint(
            painter: _DrawingPainter(points),
            size: const Size(300, 300),
          ),
        ),
      ),
    );
  }

  Widget buildResults() {
    List<Widget> resultWidgets = [];

    if (resultText != "") {
      resultWidgets.add(
        Text(
          "Prediction: $resultText",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (averageConfidence != null) {
      resultWidgets.add(SizedBox(height: 10));
      resultWidgets.add(
        Text("Avg Confidence: ${averageConfidence!.toStringAsFixed(2)}"),
      );
    }

    if (details != null) {
      resultWidgets.add(SizedBox(height: 10));
      for (Map<String, dynamic> item in details!) {
        resultWidgets.add(
          Text(
              "Char: ${item['character']}, Confidence: ${item['confidence'].toStringAsFixed(2)}"),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: resultWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Draw Characters")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            buildCanvas(),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: predict,
                  icon: Icon(Icons.search),
                  label: Text("Predict"),
                  style: ElevatedButton.styleFrom(
                    padding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: clearCanvas,
                  icon: Icon(Icons.clear),
                  label: Text("Clear"),
                  style: ElevatedButton.styleFrom(
                    padding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            buildResults(),
          ],
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  List<Offset> points;
  _DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.color = Colors.black;
    paint.strokeWidth = 8.0;
    paint.strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      Offset p1 = points[i];
      Offset p2 = points[i + 1];
      if (p1 != Offset.infinite && p2 != Offset.infinite) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) {
    return true;
  }
}
