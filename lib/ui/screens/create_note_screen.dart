import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth_cubit.dart';
import '../../logic/notes_cubit.dart';
import '../../data/models/note.dart';

class CreateNoteScreen extends StatefulWidget {
  final String habitId;
  final Note? note; // If provided, we're editing

  const CreateNoteScreen({
    super.key,
    required this.habitId,
    this.note,
  });

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.note != null;
    if (_isEditing) {
      _textController.text = widget.note!.text;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_formKey.currentState!.validate()) {
      final authCubit = context.read<AuthCubit>();
      final notesCubit = context.read<NotesCubit>();
      
      if (authCubit.isAuthenticated) {
        final user = authCubit.getCurrentUser();
        if (user != null) {
          if (_isEditing) {
            // Update existing note
            final updatedNote = widget.note!.copyWith(
              text: _textController.text.trim(),
            );
            notesCubit.updateNote(updatedNote, user.id);
          } else {
            // Create new note
            notesCubit.createNote(
              text: _textController.text.trim(),
              habitId: widget.habitId,
              userId: user.id,
            );
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
        title: Text(_isEditing ? 'Edit Note' : 'Add Note'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton.icon(
              onPressed: _saveNote,
              icon: const Icon(Icons.save_alt),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
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
              // Note Text Field
              TextFormField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Note',
                  hintText: _isEditing 
                      ? 'Update your note...'
                      : 'Write something about your habit...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
                maxLines: 8,
                textInputAction: TextInputAction.newline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter some text';
                  }
                  if (value.trim().length < 3) {
                    return 'Note must be at least 3 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Character count & helper
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Characters: ${_textController.text.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  if (_isEditing)
                    Text(
                      'Last updated: ${_formatDate(widget.note!.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
              
              const Spacer(),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveNote,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(_isEditing ? 'Update Note' : 'Add Note'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'today';
    if (difference == 1) return 'yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).round()} weeks ago';
    if (difference < 365) return '${(difference / 30).round()} months ago';
    return '${(difference / 365).round()} years ago';
  }
}
