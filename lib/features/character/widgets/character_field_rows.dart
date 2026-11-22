import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/character_provider.dart';

/// Single read-only row displaying a label and value pair in character details.
class CharacterInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const CharacterInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Editable custom field row supporting inline updates and error protection.
class CharacterFieldRow extends ConsumerStatefulWidget {
  final dynamic field;
  final int characterId;

  const CharacterFieldRow({
    super.key,
    required this.field,
    required this.characterId,
  });

  @override
  ConsumerState<CharacterFieldRow> createState() => _CharacterFieldRowState();
}

class _CharacterFieldRowState extends ConsumerState<CharacterFieldRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.field.value ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              widget.field.fieldName,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: widget.field.fieldType == 'long_text'
                ? TextField(
                    controller: _controller,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.all(8),
                    ),
                    onSubmitted: _save,
                  )
                : TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.all(8),
                    ),
                    onSubmitted: _save,
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 18),
            onPressed: () => _save(_controller.text),
          ),
        ],
      ),
    );
  }

  void _save(String value) {
    try {
      ref
          .read(characterActionsProvider)
          .updateField(
            widget.characterId,
            widget.field.fieldName,
            widget.field.fieldType,
            value,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存字段失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
