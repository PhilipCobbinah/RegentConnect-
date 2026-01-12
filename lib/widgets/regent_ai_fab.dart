import 'package:flutter/material.dart';

class RegentAIFab extends StatefulWidget {
  final VoidCallback? onPressed;
  
  const RegentAIFab({super.key, this.onPressed});

  @override
  State<RegentAIFab> createState() => _RegentAIFabState();
}

class _RegentAIFabState extends State<RegentAIFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 80,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _controller.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _controller.reverse();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: widget.onPressed ?? () {
              Navigator.pushNamed(context, '/ai-bot');
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A148C).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: TrianglePainter(),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Create gradient for the triangular shape - Violet and Black
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Main violet gradient triangle
    final violetPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF4A148C), // Deep violet
          const Color(0xFF7B1FA2), // Purple
        ],
      ).createShader(rect);

    // Cream accent
    final creamPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xFFFFF8E1), // Cream
          Color(0xFFFFECB3), // Light cream
        ],
      ).createShader(rect);

    // Draw rounded triangle shape
    final path = Path();
    
    // Create a rounded triangle
    const radius = 12.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Triangle points
    final topPoint = Offset(centerX, 4);
    final bottomLeftPoint = Offset(4, size.height - 4);
    final bottomRightPoint = Offset(size.width - 4, size.height - 4);
    
    path.moveTo(topPoint.dx, topPoint.dy + radius);
    
    // Top to bottom right
    path.quadraticBezierTo(
      topPoint.dx + radius / 2, topPoint.dy,
      topPoint.dx + radius, topPoint.dy + radius / 2,
    );
    path.lineTo(bottomRightPoint.dx - radius, bottomRightPoint.dy - radius);
    
    // Bottom right corner
    path.quadraticBezierTo(
      bottomRightPoint.dx, bottomRightPoint.dy - radius / 2,
      bottomRightPoint.dx, bottomRightPoint.dy,
    );
    path.quadraticBezierTo(
      bottomRightPoint.dx - radius / 2, bottomRightPoint.dy,
      bottomRightPoint.dx - radius, bottomRightPoint.dy,
    );
    
    // Bottom right to bottom left
    path.lineTo(bottomLeftPoint.dx + radius, bottomLeftPoint.dy);
    
    // Bottom left corner
    path.quadraticBezierTo(
      bottomLeftPoint.dx + radius / 2, bottomLeftPoint.dy,
      bottomLeftPoint.dx, bottomLeftPoint.dy,
    );
    path.quadraticBezierTo(
      bottomLeftPoint.dx, bottomLeftPoint.dy - radius / 2,
      bottomLeftPoint.dx + radius, bottomLeftPoint.dy - radius,
    );
    
    // Bottom left to top
    path.lineTo(topPoint.dx - radius, topPoint.dy + radius / 2);
    path.quadraticBezierTo(
      topPoint.dx - radius / 2, topPoint.dy,
      topPoint.dx, topPoint.dy + radius,
    );
    
    path.close();

    // Draw main shape
    canvas.drawPath(path, violetPaint);
    
    // Draw cream accent triangle (smaller, at top-right)
    final accentPath = Path();
    accentPath.moveTo(size.width - 8, 16);
    accentPath.lineTo(size.width - 8, 28);
    accentPath.lineTo(size.width - 20, 22);
    accentPath.close();
    
    canvas.drawPath(accentPath, creamPaint);
    
    // Draw another cream accent (bottom-left)
    final accentPath2 = Path();
    accentPath2.moveTo(12, size.height - 12);
    accentPath2.lineTo(24, size.height - 12);
    accentPath2.lineTo(18, size.height - 22);
    accentPath2.close();
    
    canvas.drawPath(accentPath2, creamPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Alternative simpler design - Diamond/Crystal shape with Violet and Black
class RegentAICrystalFab extends StatelessWidget {
  final VoidCallback? onPressed;
  final double bottomOffset;
  
  const RegentAICrystalFab({
    super.key, 
    this.onPressed,
    this.bottomOffset = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: bottomOffset,
      child: GestureDetector(
        onTap: onPressed ?? () => Navigator.pushNamed(context, '/ai-bot'),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4A148C), // Deep violet
                Color(0xFF7B1FA2), // Purple
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(8),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A148C).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Cream accent
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECB3).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Icon
              const Center(
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
