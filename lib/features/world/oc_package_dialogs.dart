import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/export/models/export_bundle.dart';
import '../../core/export/oc_package_service.dart';
import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/world_provider.dart';

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
  ConsumerState<OcPackageExportDialog> createState() => _OcPackageExportDialogState();
}

class _OcPackageExportDialogState extends ConsumerState<OcPackageExportDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.world.name);
    _descController = TextEditingController(text: widget.world.description ?? '');
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
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '打包全部数据、立绘与画廊为便携单文件，可在其他设备无损导入',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                    onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isExporting ? null : _handleExport,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已成功导出分享包：$savePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    }
  }
}

/// Modal dialog for importing an .ocpkg file with pre-inspection & conflict resolution
class OcPackageImportDialog extends ConsumerStatefulWidget {
  final int? targetWorldId;

  const OcPackageImportDialog({super.key, this.targetWorldId});

  static Future<void> show(BuildContext context, {int? targetWorldId}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => OcPackageImportDialog(targetWorldId: targetWorldId),
    );
  }

  @override
  ConsumerState<OcPackageImportDialog> createState() => _OcPackageImportDialogState();
}

class _OcPackageImportDialogState extends ConsumerState<OcPackageImportDialog> {
  String? _selectedFilePath;
  PackageInspectionResult? _inspection;
  bool _isLoading = false;
  bool _isImporting = false;
  String? _errorMessage;

  ConflictPolicy _conflictPolicy = ConflictPolicy.renameCopy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickAndInspectFile();
    });
  }

  Future<void> _pickAndInspectFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ocpkg', 'zip'],
        dialogTitle: '选择要导入的 .ocpkg 数据包',
      );

      if (result == null || result.files.single.path == null) {
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      final path = result.files.single.path!;
      final service = ref.read(ocPackageServiceProvider);
      final inspection = await service.inspectPackage(path);

      if (mounted) {
        setState(() {
          _selectedFilePath = path;
          _inspection = inspection;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
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
                      Icons.unarchive,
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
                          '导入数据分享包 (.ocpkg)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '安全解析外部数据包并合并至当前知识库',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content Area
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('正在解析数据包与安全校验...'),
                          ],
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 12),
                                Text('解析失败：$_errorMessage', textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: _pickAndInspectFile,
                                  child: const Text('重新选择文件'),
                                ),
                              ],
                            ),
                          )
                        : _inspection != null
                            ? _buildInspectionView()
                            : const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // Bottom Actions
              if (!_isLoading && _errorMessage == null && _inspection != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isImporting ? null : _handleImport,
                      icon: _isImporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.download_done),
                      label: Text(_isImporting ? '导入合并中...' : '开始安全导入'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInspectionView() {
    final ins = _inspection!;
    final counts = ins.manifest.entityCounts;
    final hasConflict = ins.existingConflictedCharacters.isNotEmpty || ins.hasWorldConflict;

    return ListView(
      children: [
        // Summary Card
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      ins.manifest.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '版本 ${ins.manifest.version}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (ins.manifest.description != null && ins.manifest.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(ins.manifest.description!, style: const TextStyle(fontSize: 13)),
                ],
                const Divider(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildStatPill('收录角色', '${counts['characters'] ?? 0} 位'),
                    _buildStatPill('编年事件', '${counts['timelineEvents'] ?? 0} 条'),
                    _buildStatPill('关系纽带', '${counts['relations'] ?? 0} 条'),
                    _buildStatPill('包含画廊/图片', '${ins.mediaCount} 个文件'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Characters in package
        const Text(
          '包内角色一览',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ins.characterNames.map((name) {
            final isConflicted = ins.existingConflictedCharacters.contains(name);
            return Chip(
              avatar: isConflicted
                  ? const Icon(Icons.warning, size: 16, color: Colors.amber)
                  : const Icon(Icons.person, size: 16),
              label: Text(name),
              backgroundColor: isConflicted ? Colors.amber.withValues(alpha: 0.15) : null,
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Conflict Warning & Policy selection
        if (hasConflict) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '检测到包内有 ${ins.existingConflictedCharacters.length} 位角色与当前数据库同名。请选择冲突解决策略：',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        const Text(
          '冲突处理策略',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        RadioGroup<ConflictPolicy>(
          groupValue: _conflictPolicy,
          onChanged: (v) {
            if (!_isImporting && v != null) {
              setState(() => _conflictPolicy = v);
            }
          },
          child: const Column(
            children: [
              RadioListTile<ConflictPolicy>(
                title: Text('自动创建副本 (推荐)'),
                subtitle: Text('为同名角色添加「(导入)」后缀，自动重映射所有关系与外键，原数据不受任何影响'),
                value: ConflictPolicy.renameCopy,
              ),
              RadioListTile<ConflictPolicy>(
                title: Text('覆盖已有记录'),
                subtitle: Text('若发现同名角色，直接更新其基础小传与设定内容'),
                value: ConflictPolicy.overwrite,
              ),
              RadioListTile<ConflictPolicy>(
                title: Text('跳过同名记录'),
                subtitle: Text('若已存在同名角色，直接忽略包内的对应角色，仅导入新增角色'),
                value: ConflictPolicy.skip,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label：', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _handleImport() async {
    if (_selectedFilePath == null) return;

    setState(() => _isImporting = true);

    try {
      final service = ref.read(ocPackageServiceProvider);
      final result = await service.importPackage(
        packagePath: _selectedFilePath!,
        conflictPolicy: _conflictPolicy,
        targetWorldId: widget.targetWorldId,
      );

      // Invalidate relevant providers
      ref.invalidate(worldsProvider);
      if (widget.targetWorldId != null) {
        ref.invalidate(charactersByWorldProvider(widget.targetWorldId!));
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '导入成功！共导入 ${result.importedCharacters} 位角色、${result.importedGalleries} 张相册立绘、${result.importedTimelineEvents} 条大事件。',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败：$e')),
        );
      }
    }
  }
}
