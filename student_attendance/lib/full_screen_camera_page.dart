import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:socket_io_client/socket_io_client.dart' as io;


class FullScreenCameraPage extends StatefulWidget {
  final CameraController cameraController;

  const FullScreenCameraPage({super.key, required this.cameraController});

  @override
  FullScreenCameraPageState createState() => FullScreenCameraPageState();
}

class FullScreenCameraPageState extends State<FullScreenCameraPage> {
  late io.Socket socket;
  bool isRecognizing = false;
  Timer? frameTimer;
  List<String> recognizedStudents = [];
  List<Rect> detectedFaces = []; // List to store face bounding boxes
  int elapsedSeconds = 0;
  Timer? stopwatchTimer;

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  void _connectSocket() {
    socket = io.io(
      'http://192.168.183.114:5000', // Replace with your server IP address
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    socket.connect();

    socket.onConnect((_) => debugPrint('✅ Connected to server'));
    socket.onDisconnect((_) => debugPrint('❌ Disconnected from server'));

    // Listen for 'recognized' event from server
    socket.on('recognized', (data) {
      if (data != null && data['name'] != null) {
        markStudentAsRecognized(data['name']);
      }
    });

    // Listen for face bounding boxes
    socket.on('faces', (data) {
      if (data != null && data['faces'] != null) {
        // Update detected faces' positions
        List<dynamic> faces = data['faces'];
        setState(() {
          detectedFaces =
              faces.map((face) {
                return Rect.fromLTRB(
                  face['left'].toDouble(),
                  face['top'].toDouble(),
                  face['right'].toDouble(),
                  face['bottom'].toDouble(),
                );
              }).toList();
        });
      }
    });
  }

  void markStudentAsRecognized(String name) {
    if (!recognizedStudents.contains(name)) {
      setState(() {
        recognizedStudents.add(name);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 $name recognized!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _startImageStream() {
    widget.cameraController.startImageStream((CameraImage image) async {
      if (!isRecognizing || (frameTimer?.isActive ?? false)) return;

      frameTimer = Timer(const Duration(milliseconds: 800), () {});

      try {
        Uint8List jpeg = await _convertCameraImageToJpeg(image);
        String base64Image = "data:image/jpeg;base64,${base64Encode(jpeg)}";
        socket.emit('frame', {'image': base64Image});
        debugPrint('📸 Frame sent');
      } catch (e) {
        debugPrint('⚠️ Image conversion error: $e');
      }
    });
  }

  Future<Uint8List> _convertCameraImageToJpeg(CameraImage image) async {
    final int width = image.width;
    final int height = image.height;
    final img.Image imgImage = img.Image(width: width, height: height);

    final planeY = image.planes[0];
    final planeU = image.planes[1];
    final planeV = image.planes[2];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = (y ~/ 2) * planeU.bytesPerRow + (x ~/ 2);

        final int yp = planeY.bytes[y * planeY.bytesPerRow + x];
        final int up = planeU.bytes[uvIndex];
        final int vp = planeV.bytes[uvIndex];

        final int r = (yp + 1.370705 * (vp - 128)).clamp(0, 255).toInt();
        final int g =
        (yp - 0.337633 * (up - 128) - 0.698001 * (vp - 128))
            .clamp(0, 255)
            .toInt();
        final int b = (yp + 1.732446 * (up - 128)).clamp(0, 255).toInt();

        imgImage.setPixelRgb(x, y, r, g, b);
      }
    }

    return Uint8List.fromList(img.encodeJpg(imgImage, quality: 85));
  }

  void startRecognition() {
    setState(() {
      recognizedStudents.clear();
      isRecognizing = true;
      elapsedSeconds = 0;
    });
    _startImageStream();

    stopwatchTimer?.cancel();
    stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        elapsedSeconds++;
      });
    });
  }

  void stopRecognition() {
    stopwatchTimer?.cancel();
    stopwatchTimer = null;

    setState(() {
      isRecognizing = false;
    });

    _showResult();
  }

  Future<void> _showResult() async{
    final summary =
    recognizedStudents.isEmpty
        ? 'No students were recognized.'
        : '✅ ${recognizedStudents.length} recognized:\n${recognizedStudents.join(', ')}';

    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
        title: const Text('Summary'),
        content: Text(summary),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    Navigator.pop(context, recognizedStudents); // Return list to previous page
  }

  @override
  void dispose() {
    frameTimer?.cancel();
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(widget.cameraController)),

          if (isRecognizing)
            CustomPaint(
              size: Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height,
              ),
              painter: FacePainter(detectedFaces),
            ),
          if (!isRecognizing)
            Positioned(
              bottom: 40,
              left: MediaQuery.of(context).size.width * 0.25,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.face, color: Colors.blueAccent),
                label: const Text(
                  'Start Recognition',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  // padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: startRecognition,
              ),
            ),
          if (isRecognizing)
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: stopRecognition,
                child: const CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 25,
                  child: Icon(Icons.stop, color: Colors.white),
                ),
              ),
            ),

          // Timer display (when recognizing)
          if (isRecognizing)
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  formatTime(elapsedSeconds), // Format as mm:ss
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Rect> faces;

  FacePainter(this.faces);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
    Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (var face in faces) {
      canvas.drawRect(face, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
