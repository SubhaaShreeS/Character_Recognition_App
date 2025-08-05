import 'package:flutter/material.dart';
import 'drawing_canvas_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void goToCanvas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DrawingCanvasScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Character Recognition App")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.edit,
              size: 60,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              "Recognize single and multi characters",
              style: TextStyle(
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => goToCanvas(context),
              icon: const Icon(Icons.brush),
              label: const Text("Draw Characters"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
