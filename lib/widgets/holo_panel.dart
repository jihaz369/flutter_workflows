import 'package:flutter/material.dart';
import '../theme/holo_theme.dart';

class HoloPanel extends StatelessWidget {
  final String title;
  final Widget child;
  const HoloPanel({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: HoloTheme.panel.withOpacity(0.65),
        border: Border.all(color: HoloTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('◆ ', style: TextStyle(color: HoloTheme.cyan, fontSize: 10)),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: HoloTheme.cyan,
                  fontFamily: HoloTheme.fontMono,
                  fontSize: 12,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
