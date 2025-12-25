import 'package:flutter/material.dart';
import 'package:todo_list/screens/settings/general_settings.dart';
import 'package:todo_list/screens/settings/about_screen.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({Key? key}) : super(key: key);

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  late OverlayEntry _overlayEntry;
  bool _isOpen = false;

  void _togglePanel() {
    if (_isOpen) {
      _overlayEntry.remove();
      setState(() => _isOpen = false);
    } else {
      _overlayEntry = OverlayEntry(builder: (context) => _buildDropdown());
      Overlay.of(context).insert(_overlayEntry);
      setState(() => _isOpen = true);
    }
  }

  void _showGeneralPanel() {
    // replace current overlay with general settings panel
    if (_isOpen) _overlayEntry.remove();
    _overlayEntry = OverlayEntry(builder: (context) => _buildGeneralDropdown());
    Overlay.of(context).insert(_overlayEntry);
    setState(() => _isOpen = true);
  }

  void _showAboutPanel() {
    if (_isOpen) _overlayEntry.remove();
    _overlayEntry = OverlayEntry(builder: (context) => _buildAboutDropdown());
    Overlay.of(context).insert(_overlayEntry);
    setState(() => _isOpen = true);
  }

  Widget _buildDropdown() {
    return Positioned(
      top: 56,
      right: 56,
      width: 340,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _overlayEntry.remove();
                        setState(() => _isOpen = false);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('General'),
                onTap: _showGeneralPanel,
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                onTap: _showAboutPanel,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralDropdown() {
    final mq = MediaQuery.of(context);
    return Positioned(
      top: 56,
      right: 56,
      width: mq.size.width > 700 ? 600 : mq.size.width - 100,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: BoxConstraints(maxHeight: mq.size.height - 80),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      'General',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _overlayEntry.remove();
                        setState(() => _isOpen = false);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Embed the GeneralSettings widget inside the panel
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GeneralSettings(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutDropdown() {
    final mq = MediaQuery.of(context);
    return Positioned(
      top: 56,
      right: 56,
      width: mq.size.width > 700 ? 420 : mq.size.width - 140,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: BoxConstraints(maxHeight: mq.size.height - 80),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _overlayEntry.remove();
                        setState(() => _isOpen = false);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AboutScreen(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Settings',
      onPressed: _togglePanel,
    );
  }
}
