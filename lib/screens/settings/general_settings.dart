import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/theme_provider.dart';

class GeneralSettings extends StatefulWidget {
  const GeneralSettings({Key? key}) : super(key: key);

  @override
  State<GeneralSettings> createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<GeneralSettings> {
  static const _soundKey = 'notificationSound';
  final List<Map<String, String>> _sounds = [
    {'label': 'Sound 1', 'asset': 'assets/sounds/1.mp3'},
    {'label': 'Sound 2', 'asset': 'assets/sounds/2.mp3'},
    {'label': 'Sound 3', 'asset': 'assets/sounds/3.mp3'},
    {'label': 'Sound 4', 'asset': 'assets/sounds/4.mp3'},
    {'label': 'Sound 5', 'asset': 'assets/sounds/5.mp3'},
  ];

  late Box _box;
  String? _selectedSound;
  late final AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _box = Hive.box('settings');
    _selectedSound = _box.get(_soundKey) as String?;
    if (_selectedSound == null) {
      // default to first sound option
      _selectedSound = _sounds.first['asset'];
      _box.put(_soundKey, _selectedSound);
    }
    _player = AudioPlayer();
  }

  void _selectSound(String asset) {
    setState(() {
      _selectedSound = asset;
    });
    _box.put(_soundKey, asset);
  }

  String _assetForPlayer(String asset) =>
      asset.startsWith('assets/') ? asset.substring('assets/'.length) : asset;

  Future<void> _playAsset(String asset) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(_assetForPlayer(asset)));
    } catch (_) {
      // ignore playback errors for now
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final mode = themeProvider.themeMode;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Theme'),
            subtitle: const Text('Choose light, dark or follow system'),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: mode,
            onChanged: (v) {
              if (v != null) context.read<ThemeProvider>().setThemeMode(v);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: mode,
            onChanged: (v) {
              if (v != null) context.read<ThemeProvider>().setThemeMode(v);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System'),
            value: ThemeMode.system,
            groupValue: mode,
            onChanged: (v) {
              if (v != null) context.read<ThemeProvider>().setThemeMode(v);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Notification sound',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ..._sounds.map((s) {
            final asset = s['asset']!;
            return RadioListTile<String>(
              title: Text(s['label']!),
              value: asset,
              groupValue: _selectedSound,
              onChanged: (v) {
                if (v != null) _selectSound(v);
              },
              secondary: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => _playAsset(asset),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
