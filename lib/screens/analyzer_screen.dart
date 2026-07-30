import 'package:flutter/material.dart';
import '../theme/holo_theme.dart';
import '../widgets/holo_panel.dart';

class AnalyzerScreen extends StatelessWidget {
  const AnalyzerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          HoloPanel(
            title: 'Frequency Domain',
            child: Container(
              height: 200,
              color: HoloTheme.darkPanel,
              child: const Center(
                child: Text('Spectrum Analyzer Placeholder\nConnect signal source',
                  style: TextStyle(color: HoloTheme.dimCyan, fontFamily: HoloTheme.fontMono),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          HoloPanel(
            title: 'Spectrogram',
            child: Container(
              height: 200,
              color: HoloTheme.darkPanel,
              child: const Center(
                child: Text('Waterfall Display Placeholder',
                  style: TextStyle(color: HoloTheme.dimCyan, fontFamily: HoloTheme.fontMono),
                ),
              ),
            ),
          ),
          HoloPanel(
            title: 'Statistics',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('SNR', '-- dB'),
                _buildStat('BER', '--'),
                _buildStat('FER', '--'),
                _buildStat('Lock', 'UNLOCKED'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: HoloTheme.dimCyan, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: HoloTheme.cyan, fontFamily: HoloTheme.fontMono, fontSize: 14)),
      ],
    );
  }
}
