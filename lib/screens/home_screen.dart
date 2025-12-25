import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/widgets/task_dialog.dart';
import '../models/task_provider.dart';
import '../models/theme_provider.dart';
import '../widgets/calendar_panel.dart';
import '../widgets/todo_list_panel.dart';
import '../widgets/notification_panel.dart';
import '../widgets/settings_panel.dart';

/// Main home screen with split layout (todo list + calendar)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FocusNode _globalFocusNode;

  @override
  void initState() {
    super.initState();
    _globalFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _globalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKey: (node, event) {
        // Only handle key down events
        if (event is RawKeyDownEvent) {
          final pressed = RawKeyboard.instance.keysPressed;
          final isCtrlPressed =
              pressed.contains(LogicalKeyboardKey.controlLeft) ||
              pressed.contains(LogicalKeyboardKey.controlRight) ||
              pressed.contains(LogicalKeyboardKey.metaLeft) ||
              pressed.contains(LogicalKeyboardKey.metaRight);

          if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyN) {
            // Ctrl/Cmd + N: Add new task
            _showAddTaskDialog();
            return KeyEventResult.handled;
          }

          if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyF) {
            // Ctrl/Cmd + F: Focus search (implementation requires exposing a FocusNode)
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      focusNode: _globalFocusNode,
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/vertical_logo.png',
                  height: 80,
                  width: 200,
                ),
              ],
            ),
          ),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
          actions: [
            const NotificationPanel(),
            const SettingsPanel(),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  tooltip: 'Toggle theme',
                  onPressed: themeProvider.toggleTheme,
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Use responsive layout
            if (constraints.maxWidth > 900) {
              // Split layout for larger screens
              return Row(
                children: [
                  // Left panel: To-Do List
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: const TodoListPanel(),
                    ),
                  ),
                  // Right panel: Calendar
                  Expanded(flex: 1, child: const CalendarPanel()),
                ],
              );
            } else {
              // Stacked layout for smaller screens
              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(icon: Icon(Icons.task_alt), text: 'Tasks'),
                        Tab(icon: Icon(Icons.calendar_today), text: 'Calendar'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          const TodoListPanel(),
                          const CalendarPanel(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final provider = context.read<TaskProvider>();
    showDialog(
      context: context,
      builder: (context) => TaskDialog(initialDate: provider.selectedDate),
    );
  }
}
