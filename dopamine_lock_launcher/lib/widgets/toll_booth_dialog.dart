import 'package:flutter/material.dart';

import '../models/question.dart';

class TollBoothDialog extends StatefulWidget {
  const TollBoothDialog({
    super.key,
    required this.question,
    required this.onAnswered,
  });

  final Question question;
  final Future<void> Function(bool isCorrect) onAnswered;

  @override
  State<TollBoothDialog> createState() => _TollBoothDialogState();
}

class _TollBoothDialogState extends State<TollBoothDialog> {
  String? _selectedAnswer;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    final selectedAnswer = _selectedAnswer;
    if (selectedAnswer == null || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    final isCorrect = selectedAnswer == widget.question.correctAnswer;
    await widget.onAnswered(isCorrect);

    if (!mounted) {
      return;
    }

    if (isCorrect) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSubmitting = false;
      _selectedAnswer = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wrong answer. Try again.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unlock Toll Booth', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.question.questionText,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...widget.question.options.map(
              (option) => RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: Text(option),
                value: option,
                groupValue: _selectedAnswer,
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _selectedAnswer = value),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedAnswer == null || _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
