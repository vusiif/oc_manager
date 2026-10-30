import 'dart:io';
import 'package:flutter/material.dart';
import '../../storage/image_storage_service.dart';
import '../design_tokens.dart';

/// Reusable character avatar widget supporting both local image files and fallback letter badge.
class OcAvatar extends StatefulWidget {
  final String? avatarPath;
  final String name;
  final String gender;
  final double size;
  final BoxShape shape;
  final double borderRadius;
  final bool isDraft;

  const OcAvatar({
    super.key,
    required this.avatarPath,
    required this.name,
    this.gender = '',
    this.size = 40.0,
    this.shape = BoxShape.circle,
    this.borderRadius = 8.0,
    this.isDraft = false,
  });

  @override
  State<OcAvatar> createState() => _OcAvatarState();
}

class _OcAvatarState extends State<OcAvatar> {
  File? _resolvedFile;

  @override
  void initState() {
    super.initState();
    _checkAvatarFile();
  }

  @override
  void didUpdateWidget(OcAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarPath != widget.avatarPath) {
      _checkAvatarFile();
    }
  }

  Future<void> _checkAvatarFile() async {
    if (widget.avatarPath == null || widget.avatarPath!.trim().isEmpty) {
      if (mounted) setState(() => _resolvedFile = null);
      return;
    }
    final file = await ImageStorageService.instance.resolveImageFile(widget.avatarPath);
    if (mounted) {
      setState(() {
        _resolvedFile = file;
      });
    }
  }

  Color _getGenderColor(String gender) {
    if (gender == '男') return AppColors.genderMale;
    if (gender == '女') return AppColors.genderFemale;
    if (gender.isNotEmpty) return AppColors.genderOther;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final genderColor = _getGenderColor(widget.gender);
    final initial = widget.name.isNotEmpty ? widget.name[0] : '?';

    Widget child;

    if (_resolvedFile != null) {
      child = Image.file(
        _resolvedFile!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallback(genderColor, initial),
      );
    } else {
      child = _buildFallback(genderColor, initial);
    }

    if (widget.shape == BoxShape.circle) {
      return ClipOval(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: child,
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: child,
        ),
      );
    }
  }

  Widget _buildFallback(Color genderColor, String initial) {
    final bgColor = widget.isDraft
        ? Colors.grey.shade400
        : genderColor.withValues(alpha: 0.15);
    final textColor = widget.isDraft ? Colors.white : genderColor;

    return Container(
      width: widget.size,
      height: widget.size,
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: widget.size * 0.42,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
