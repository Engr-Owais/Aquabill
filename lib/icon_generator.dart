import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

Future<void> main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Create a picture recorder
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Define the size (1024x1024 for maximum quality)
  const size = Size(1024, 1024);

  // Create the icon
  final paint = Paint()
    ..color = const Color(0xFF0077B6)
    ..style = PaintingStyle.fill;

  // Draw background
  canvas.drawRect(Offset.zero & size, paint);

  // Draw water drop
  final center = Offset(size.width / 2, size.height / 2);
  final dropPath = Path();
  final dropSize = size.width * 0.7;

  dropPath.moveTo(center.dx, center.dy - dropSize / 2);
  dropPath.cubicTo(
    center.dx + dropSize / 2,
    center.dy - dropSize / 3,
    center.dx + dropSize / 2,
    center.dy + dropSize / 3,
    center.dx,
    center.dy + dropSize / 2,
  );
  dropPath.cubicTo(
    center.dx - dropSize / 2,
    center.dy + dropSize / 3,
    center.dx - dropSize / 2,
    center.dy - dropSize / 3,
    center.dx,
    center.dy - dropSize / 2,
  );

  final dropPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  canvas.drawPath(dropPath, dropPaint);

  // Convert to image
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();

  // Ensure directory exists
  final directory = Directory('assets/icon');
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }

  // Save the image
  final iconFile = File('assets/icon/icon.png');
  await iconFile.writeAsBytes(buffer);

  print('Icon generated successfully at: ${iconFile.path}');
}
