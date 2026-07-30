import 'package:flutter/material.dart';
import '../theme/holo_theme.dart';
import '../widgets/holo_panel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          HoloPanel(
            title: 'System Configuration',
            child: Column(
              children: [
                _buildSetting('Audio Output Device', 'Default'),
                _buildSlider('Input Gain (dB)', 20, 0, 40),
                _buildDropdown('AGC', 'Fast', ['Fast', 'Slow', 'Off']),
                _buildNumberField('Squelch (dB)', -40),
                _buildNumberField('Preamble Length', 64),
                _buildNumberField('Postamble Length', 32),
              ],
            ),
          ),
          HoloPanel(
            title: 'Encryption Defaults',
            child: Column(
              children: [
                _buildDropdown('Algorithm', 'AES-GCM-256', ['AES-GCM-256', 'ChaCha20-Poly1305']),
                _buildDropdown('Key Derivation', 'PBKDF2 (100k iter)', ['PBKDF2 (100k iter)', 'Argon2id']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetting(String label, String value) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: HoloTheme.cyan, fontSize: 12)),
      trailing: Text(value, style: const TextStyle(color: HoloTheme.dimCyan, fontFamily: HoloTheme.fontMono)),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: HoloTheme.cyan, fontSize: 12)),
      subtitle: Slider(value: value / max, min: 0, max: 1, onChanged: (_) {}),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: HoloTheme.cyan, fontSize: 12)),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: HoloTheme.panel,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(color: HoloTheme.cyan, fontSize: 11)))).toList(),
        onChanged: (_) {},
      ),
    );
  }

  Widget _buildNumberField(String label, int value) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: HoloTheme.cyan, fontSize: 12)),
      trailing: SizedBox(
        width: 80,
        child: TextField(
          controller: TextEditingController(text: value.toString()),
          keyboardType: TextInputType.number,
          style: const TextStyle(color: HoloTheme.cyan, fontFamily: HoloTheme.fontMono, fontSize: 12),
          textAlign: TextAlign.end,
        ),
      ),
    );
  }
}
