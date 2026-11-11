import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/widgets/common.dart';
import '../ingest/material_import_service.dart';
import '../ingest/subtitle_parser.dart';
import '../providers.dart';

/// 二期导入页（`/materials/import`）：只选本地文件，不碰网络与平台下载。
class MaterialImportPage extends ConsumerStatefulWidget {
  const MaterialImportPage({super.key});

  @override
  ConsumerState<MaterialImportPage> createState() => _MaterialImportPageState();
}

class _MaterialImportPageState extends ConsumerState<MaterialImportPage> {
  final TextEditingController _titleController = TextEditingController();
  PlatformFile? _media;
  PlatformFile? _subtitle;
  String _stage = '读取字幕并切句';
  String? _error;
  String? _existingId;
  bool _busy = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [
        ...MaterialImportService.audioExtensions,
        ...MaterialImportService.videoExtensions,
      ],
    );
    if (file == null || !mounted) return;
    setState(() {
      _media = file;
      _titleController.text = _defaultTitle(file.name);
      _error = null;
      _existingId = null;
    });
  }

  Future<void> _pickSubtitle() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: MaterialImportService.subtitleExtensions.toList(),
    );
    if (file == null || !mounted) return;
    setState(() {
      _subtitle = file;
      _error = null;
      _existingId = null;
    });
  }

  Future<void> _runImport() async {
    if (_media == null || _subtitle == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _existingId = null;
      _stage = '读取字幕并切句';
    });
    // 让「正在解析」先绘制出来，再进入同步解析。
    await Future<void>.delayed(Duration.zero);
    try {
      final item = await ref.read(materialImportServiceProvider).importFiles(
            media: _media!,
            subtitle: _subtitle!,
            title: _titleController.text,
          );
      ref.invalidate(materialLibraryProvider);
      ref.invalidate(wrongSegmentsProvider);
      if (!mounted) return;
      showAppToast(context, '已导入 ${item.segmentCount} 句，可以开始听了');
      context.pop();
    } on MaterialImportException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _existingId = e.existingId;
        });
      }
    } on SubtitleParseException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = '导入失败：$e。请确认文件可以读取后重试。');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _media != null && _subtitle != null;
    return PageScaffold(
      title: '导入教材',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Text(
            '选一份本地音视频，再选和它对应的字幕。App 会按句切开，只播音频，不显示画面。',
            style: AppText.bodySecondary.copyWith(height: 1.6),
          ),
          const SizedBox(height: 20),
          const SectionTitle(title: '选择文件'),
          const SizedBox(height: 12),
          _FileRow(
            icon: Icons.audio_file_outlined,
            label: '音视频文件',
            hint: 'MP3 / M4A / WAV / MP4 等',
            name: _media?.name,
            onTap: _busy ? null : _pickMedia,
          ),
          const SizedBox(height: 12),
          _FileRow(
            icon: Icons.subtitles_outlined,
            label: '字幕文件',
            hint: '.srt / .vtt · UTF-8 或 GBK',
            name: _subtitle?.name,
            onTap: _busy ? null : _pickSubtitle,
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: _titleController,
            label: '教材名称',
            hint: '留空则使用文件名',
            enabled: !_busy,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            ErrorBanner(
              message: _error!,
              onRetry: ready ? _runImport : null,
              onClose: () => setState(() {
                _error = null;
                _existingId = null;
              }),
            ),
            if (_existingId != null) ...[
              const SizedBox(height: 10),
              SecondaryButton(
                label: '打开已有教材',
                onPressed: () => context.push('/materials/$_existingId'),
              ),
            ],
          ],
          const SizedBox(height: 24),
          if (_busy)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text('$_stage…（最长 30 分钟的素材）', style: AppText.caption),
              ],
            )
          else
            PrimaryButton(
              label: '开始导入',
              icon: Icons.playlist_add_rounded,
              onPressed: ready ? _runImport : null,
            ),
          const SizedBox(height: 24),
          Text(
            '素材版权归原权利人。本功能只处理你自己选择的本地文件，仅供个人学习使用，不下载、不分享、不做视频转码。',
            style: AppText.caption.copyWith(height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _defaultTitle(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.icon,
    required this.label,
    required this.hint,
    required this.name,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final String? name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final picked = name != null;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.inkSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  picked ? name! : label,
                  style: AppText.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(picked ? '已选择 · 点按可更换' : hint, style: AppText.caption),
              ],
            ),
          ),
          Icon(
            picked ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
            size: 18,
            color: picked ? AppColors.success : AppColors.inkMuted,
          ),
        ],
      ),
    );
  }
}
