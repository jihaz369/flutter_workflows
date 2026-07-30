import 'package:flutter/material.dart';
import '../theme/holo_theme.dart';
import 'sender_screen.dart';
import 'receiver_screen.dart';
import 'settings_screen.dart';
import 'analyzer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<(String, Widget, IconData)> _tabs = [
    ('SENDER', const SenderScreen(), Icons.send),
    ('RECEIVER', const ReceiverScreen(), Icons.mic),
    ('SETTINGS', const SettingsScreen(), Icons.settings),
    ('ANALYZER', const AnalyzerScreen(), Icons.analytics),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoloTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: HoloTheme.borderColor)),
              ),
              child: Column(
                children: [
                  Text(
                    '◈ HOLO RADIO ◈',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      shadows: [
                        const Shadow(color: HoloTheme.cyan, blurRadius: 20),
                        const Shadow(color: HoloTheme.blue, blurRadius: 40),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'DIGITAL MODEM SYSTEM // OFFLINE CAPABLE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 6,
                      color: HoloTheme.dimCyan,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_tabs.length, (index) {
                  final isActive = index == _currentIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? HoloTheme.dimCyan.withOpacity(0.3) : HoloTheme.panel.withOpacity(0.4),
                          border: Border.all(
                            color: isActive ? HoloTheme.cyan : HoloTheme.borderColor,
                          ),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: isActive ? [
                            BoxShadow(color: HoloTheme.cyan.withOpacity(0.2), blurRadius: 20),
                          ] : null,
                        ),
                        child: Text(
                          _tabs[index].$1,
                          style: TextStyle(
                            fontFamily: HoloTheme.fontMono,
                            fontSize: 12,
                            letterSpacing: 2,
                            color: isActive ? HoloTheme.cyan : HoloTheme.dimCyan,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(child: _tabs[_currentIndex].$2),
          ],
        ),
      ),
    );
  }
}
