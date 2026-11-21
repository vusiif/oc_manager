import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../providers/database_provider.dart';

/// Modal dialog for exporting a world or characters into a portable .ocpkg package
class OcPackageExportDialog extends ConsumerStatefulWidget {
  final World world;

  const OcPackageExportDialog({super.key, required this.world});

  static Future<void> show(BuildContext context, World world) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => OcPackageExportDialog(world: world),
    );
  }

  @override
  ConsumerState<OcPackageExportDialog> createState() =>
      _OcPackageExportDialogState();
}

class _OcPackageExportDialogState extends ConsumerState<OcPackageExportDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.world.name);
    _descController = TextEditingController(
      text: widget.world.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.archive,
                      color: Theme.of(context).colorScheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '导出数据分享包 (.ocpkg)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '打包全部数据、立绘与画廊为便携单文件，可在其他设备无损导入',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Inputs
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '分享包名称',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '分享包备注或简介 (可选)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '分享包包含：角色档案、六维属性、头像、高清画廊切片、编年史事件与人际关系网络。',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isExporting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isExporting ? null : _handleExport,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.file_download),
                    label: Text(_isExporting ? '打包中...' : '导出 .ocpkg'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final defaultFileName = '${title.replaceAll(' ', '_')}.ocpkg';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: '保存 .ocpkg 数据包',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['ocpkg', 'zip'],
    );

    if (savePath == null) return;

    setState(() => _isExporting = true);

    try {
      final service = ref.read(ocPackageServiceProvider);
      await service.exportWorldPackage(
        worldId: widget.world.id,
        outputPath: savePath,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已成功导出分享包：$savePath')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败：$e')));
      }
    }
  }
}
