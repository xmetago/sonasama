import 'package:flutter/material.dart';

class EnergyBar extends StatelessWidget {
  final double value;

  const EnergyBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.5, // %50 oranında küçültme
      child: Container(
        height: 50, // Orijinal boyutlar
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
          border: Border.all(color: Colors.black.withOpacity(0.3), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4CAF50),
                      Color(0xFF81C784),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(
                Icons.bolt,
                size: 24,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
