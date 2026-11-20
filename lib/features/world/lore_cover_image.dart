import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/storage/image_storage_service.dart';

class LoreCoverImage extends StatefulWidget {
  final String? imagePath;
  final BoxFit fit;
  final Widget? fallback;

  const LoreCoverImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  State<LoreCoverImage> createState() => _LoreCoverImageState();
}

class _LoreCoverImageState extends State<LoreCoverImage> {
  File? _file;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void didUpdateWidget(LoreCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _loadFile();
    }
  }

  Future<void> _loadFile() async {
    if (widget.imagePath == null || widget.imagePath!.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _file = null;
          _loading = false;
        });
      }
      return;
    }

    final file = await ImageStorageService.instance.resolveImageFile(
      widget.imagePath,
    );
    if (mounted) {
      setState(() {
        _file = file;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox();
    }
    if (_file != null && _file!.existsSync()) {
      return Image.file(
        _file!,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) =>
            widget.fallback ?? const SizedBox(),
      );
    }
    return widget.fallback ?? const SizedBox();
  }
}
