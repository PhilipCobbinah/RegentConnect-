import 'package:flutter/material.dart';

// Top Wave Clipper
class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx, firstControlPoint.dy,
      firstEndPoint.dx, firstEndPoint.dy,
    );
    
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 60);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(
      secondControlPoint.dx, secondControlPoint.dy,
      secondEndPoint.dx, secondEndPoint.dy,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Bottom Wave Clipper
class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, 30);
    
    var firstControlPoint = Offset(size.width / 4, 0);
    var firstEndPoint = Offset(size.width / 2, 20);
    path.quadraticBezierTo(
      firstControlPoint.dx, firstControlPoint.dy,
      firstEndPoint.dx, firstEndPoint.dy,
    );
    
    var secondControlPoint = Offset(size.width * 3 / 4, 40);
    var secondEndPoint = Offset(size.width, 15);
    path.quadraticBezierTo(
      secondControlPoint.dx, secondControlPoint.dy,
      secondEndPoint.dx, secondEndPoint.dy,
    );
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Wave Painter for more complex waves
class WavePainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final bool isTop;

  WavePainter({
    required this.color1,
    required this.color2,
    this.isTop = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: isTop ? Alignment.topLeft : Alignment.bottomLeft,
        end: isTop ? Alignment.bottomRight : Alignment.topRight,
        colors: [color1, color2],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    
    if (isTop) {
      path.lineTo(0, size.height - 50);
      
      // First wave
      path.quadraticBezierTo(
        size.width * 0.25, size.height - 20,
        size.width * 0.5, size.height - 40,
      );
      
      // Second wave
      path.quadraticBezierTo(
        size.width * 0.75, size.height - 60,
        size.width, size.height - 30,
      );
      
      path.lineTo(size.width, 0);
    } else {
      path.moveTo(0, 40);
      
      // First wave
      path.quadraticBezierTo(
        size.width * 0.25, 10,
        size.width * 0.5, 30,
      );
      
      // Second wave
      path.quadraticBezierTo(
        size.width * 0.75, 50,
        size.width, 25,
      );
      
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
