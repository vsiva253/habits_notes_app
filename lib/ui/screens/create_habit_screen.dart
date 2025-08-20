import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/habit.dart';
import '../../logic/auth_cubit.dart';
import '../../logic/habits_cubit.dart';

class CreateHabitScreen extends StatefulWidget {
  final Habit? habit; // if provided, we are editing

  const CreateHabitScreen({super.key, this.habit});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String _selectedColor = 'blue';

  final List<String> _availableColors = [
    'red', 'blue', 'green', 'yellow', 'orange',
    'purple', 'pink', 'teal', 'indigo', 'brown', 'grey'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _titleController.text = widget.habit!.title;
      _selectedColor = widget.habit!.color;
    }
  }

  void _saveHabit() {
    if (_formKey.currentState!.validate()) {
      final authCubit = context.read<AuthCubit>();
      final habitsCubit = context.read<HabitsCubit>();
      
      if (authCubit.isAuthenticated) {
        final user = authCubit.getCurrentUser();
        if (user != null) {
          if (widget.habit == null) {
            habitsCubit.createHabit(
              title: _titleController.text.trim(),
              color: _selectedColor,
              userId: user.id,
            );
          } else {
            final updated = widget.habit!.copyWith(
              title: _titleController.text.trim(),
              color: _selectedColor,
              updatedAt: DateTime.now(),
            );
            habitsCubit.updateHabit(updated, user.id);
          }

          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit == null ? 'Create Habit' : 'Edit Habit'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton.icon(
              onPressed: _saveHabit,
              icon: const Icon(Icons.check),
              label: Text(widget.habit == null ? 'Save' : 'Update'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Habit Title',
                  hintText: 'e.g., Read 15 min/day',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a habit title';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveHabit(),
              ),
              
              const SizedBox(height: 24),
              
              // Color Selection
              Text(
                'Choose a color:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableColors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: AnimatedScale(
                      scale: isSelected ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getColorFromString(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: _getColorFromString(color).withOpacity(0.35),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              
              // Preview (animated)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Container(
                  key: ValueKey('preview-${_selectedColor}-${_titleController.text.isNotEmpty}'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getColorFromString(_selectedColor).withOpacity(0.08),
                        Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                      ],
                    ),
                    border: Border.all(
                      color: _getColorFromString(_selectedColor).withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _getColorFromString(_selectedColor),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getColorFromString(_selectedColor).withOpacity(0.35),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.task_alt,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _titleController.text.isNotEmpty ? _titleController.text : 'New Habit',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveHabit,
                  icon: const Icon(Icons.check_circle),
                  label: Text(widget.habit == null ? 'Create Habit' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'brown':
        return Colors.brown;
      case 'grey':
      case 'gray':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
