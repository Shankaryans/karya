import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_provider.dart';
import 'task_dialog.dart';
import 'task_tile.dart';

/// Left panel showing the list of tasks for selected date
class TodoListPanel extends StatefulWidget {
  const TodoListPanel({super.key});

  @override
  State<TodoListPanel> createState() => _TodoListPanelState();
}

class _TodoListPanelState extends State<TodoListPanel> {
  late TextEditingController _searchController;
  late FocusNode _searchFocus;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocus = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _addNewTask() {
    final provider = context.read<TaskProvider>();
    showDialog(
      context: context,
      builder: (context) => TaskDialog(initialDate: provider.selectedDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Tasks',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Tooltip(
                    message: 'Add new task (Ctrl+N)',
                    child: FloatingActionButton(
                      onPressed: _addNewTask,
                      mini: true,
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Search field
              TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (value) {
                  context.read<TaskProvider>().setSearchQuery(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search tasks... (Ctrl+F)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<TaskProvider>().setSearchQuery('');
                            _searchFocus.unfocus();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Task list
        Expanded(
          child: Consumer<TaskProvider>(
            builder: (context, taskProvider, _) {
              final tasks = taskProvider.tasks;

              if (tasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isNotEmpty
                            ? 'No matching tasks found'
                            : 'No tasks for this date',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addNewTask,
                        icon: const Icon(Icons.add),
                        label: const Text('Create a Task'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return TaskTile(task: tasks[index]);
                },
              );
            },
          ),
        ),

        // Footer with stats
        Consumer<TaskProvider>(
          builder: (context, taskProvider, _) {
            final selectedStatus = taskProvider.statusFilter;
            final selectedPriority = taskProvider.priorityFilter;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.assignment,
                        label: 'Total',
                        value: '${taskProvider.total}',
                        selected: selectedStatus == TaskStatusFilter.all,
                        onTap: () {
                          // Toggle: if already 'all', keep all; otherwise set to all
                          taskProvider.setStatusFilter(TaskStatusFilter.all);
                        },
                      ),
                      _StatItem(
                        icon: Icons.check_circle,
                        label: 'Completed',
                        value: '${taskProvider.completed}',
                        color: Colors.green,
                        selected: selectedStatus == TaskStatusFilter.completed,
                        onTap: () {
                          final next =
                              selectedStatus == TaskStatusFilter.completed
                              ? TaskStatusFilter.all
                              : TaskStatusFilter.completed;
                          taskProvider.setStatusFilter(next);
                        },
                      ),
                      _StatItem(
                        icon: Icons.warning_amber_rounded,
                        label: 'Incomplete',
                        value: '${taskProvider.incomplete}',
                        color: Colors.red,
                        selected: selectedStatus == TaskStatusFilter.incomplete,
                        onTap: () {
                          final next =
                              selectedStatus == TaskStatusFilter.incomplete
                              ? TaskStatusFilter.all
                              : TaskStatusFilter.incomplete;
                          taskProvider.setStatusFilter(next);
                        },
                      ),
                      _StatItem(
                        icon: Icons.schedule,
                        label: 'Pending',
                        value: '${taskProvider.pending}',
                        color: Colors.orange,
                        selected: selectedStatus == TaskStatusFilter.pending,
                        onTap: () {
                          final next =
                              selectedStatus == TaskStatusFilter.pending
                              ? TaskStatusFilter.all
                              : TaskStatusFilter.pending;
                          taskProvider.setStatusFilter(next);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.priority_high,
                        label: 'High',
                        value: '${taskProvider.highPriority}',
                        color: Colors.red,
                        selected: selectedPriority == 'high',
                        onTap: () {
                          final next = selectedPriority == 'high'
                              ? 'all'
                              : 'high';
                          taskProvider.setPriorityFilter(next);
                        },
                      ),
                      _StatItem(
                        icon: Icons.priority_high,
                        label: 'Medium',
                        value: '${taskProvider.middlePriority}',
                        color: Colors.orange,
                        selected: selectedPriority == 'medium',
                        onTap: () {
                          final next = selectedPriority == 'medium'
                              ? 'all'
                              : 'medium';
                          taskProvider.setPriorityFilter(next);
                        },
                      ),
                      _StatItem(
                        icon: Icons.priority_high,
                        label: 'Low',
                        value: '${taskProvider.lowPriority}',
                        color: Colors.green,
                        selected: selectedPriority == 'low',
                        onTap: () {
                          final next = selectedPriority == 'low'
                              ? 'all'
                              : 'low';
                          taskProvider.setPriorityFilter(next);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Helper widget for displaying stats
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final bool selected;
  final VoidCallback? onTap;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.12)
        : Colors.transparent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? Colors.blue, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
