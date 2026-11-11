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

/// 二期导入页（`/materials/import`）：支持本地文件与链接下载两条路线。
class MaterialImportPage extends ConsumerStatefulWidget {
  const MaterialImportPage({super.key});

  @override
  ConsumerState<MaterialImportPage> createState() => _MaterialImportPageState();
}

class _MaterialImportPageState extends ConsumerState<MaterialImportPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _mediaUrlController = TextEditingController();
  final TextEditingController _subtitleUrlController = TextEditingController();
  PlatformFile? _media;
  PlatformFile? _subtitle;
  bool _urlMode = false;
  String _stage = '读取字幕并切句';
  double _progress = 0;
  String? _error;
  String? _existingId;
  bool _busy = false;

  @override
  void dispose() {
    _titleController.dispose();
    _mediaUrlController.dispose();
    _subtitleUrlController.dispose();
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
    await Future<void>.delayed(Duration.zero);
    try {
      final item = await ref.read(materialImportServiceProvider).importFiles(
            media: _media!,
            subtitle: _subtitle!,
            title: _titleController.text,
          );
      _afterSuccess(item.segmentCount);
    } on MaterialImportException catch (e) {
      _fail(e.message, e.existingId);
    } on SubtitleParseException catch (e) {
      _fail(e.message);
    } on Object catch (e) {
      _fail('导入失败：$e。请确认文件可以读取后重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runUrlImport() async {
    final mediaUrl = _mediaUrlController.text.trim();
    if (mediaUrl.isEmpty) {
      _fail('请先填写音视频链接。');
      return;
    }
    setState(() {
      _busy = true;
      _progress = 0;
      _error = null;
      _existingId = null;
      _stage = '下载音视频';
    });
    await Future<void>.delayed(Duration.zero);
    try {
      final item = await ref.read(materialImportServiceProvider).importFromUrl(
            mediaUrl: mediaUrl,
            subtitleUrl: _subtitleUrlController.text.trim().isEmpty
                ? null
                : _subtitleUrlController.text.trim(),
            title: _titleController.text,
            onProgress: (p) => setState(() => _progress = p),
          );
      _afterSuccess(item.segmentCount);
    } on MaterialImportException catch (e) {
      _fail(e.message, e.existingId);
    } on SubtitleParseException catch (e) {
      _fail(e.message);
    } on Object catch (e) {
      _fail('导入失败：$e。请确认链接可访问、格式正确后重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _afterSuccess(int count) {
    ref.invalidate(materialLibraryProvider);
    ref.invalidate(wrongSegmentsProvider);
    if (!mounted) return;
    showAppToast(context, '已导入 $count 句，可以开始听了');
    context.pop();
  }

  void _fail(String message, [String? existingId]) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _existingId = existingId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileReady = _media != null && _subtitle != null;
    final urlReady = _mediaUrlController.text.trim().isNotEmpty;
    return PageScaffold(
      title: '导入教材',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Text(
            '选一份本地音视频或填一个链接，再配上对应字幕（本地选文件 / 链接填字幕 URL）。App 会按句切开，只播音频，不显示画面。',
            style: AppText.bodySecondary.copyWith(height: 1.6),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('本地文件'),
                selected: !_urlMode,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: !_urlMode ? Colors.white : AppColors.inkSecondary,
                ),
                onSelected: (_) => setState(() => _urlMode = false),
              ),
              ChoiceChip(
                label: const Text('链接导入'),
                selected: _urlMode,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _urlMode ? Colors.white : AppColors.inkSecondary,
                ),
                onSelected: (_) => setState(() => _urlMode = true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionTitle(title: '素材来源'),
          const SizedBox(height: 12),
          if (_urlMode)
            _UrlRows(
              mediaController: _mediaUrlController,
              subtitleController: _subtitleUrlController,
              enabled: !_busy,
            )
          else ...[
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
          ],
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
              onRetry: (_urlMode ? urlReady : fileReady) ? (_urlMode ? _runUrlImport : _runImport) : null,
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
            Column(
              children: [
                LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  color: AppColors.primary,
                  backgroundColor: AppColors.surfaceTint,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 12),
                Text('$_stage…', style: AppText.caption),
              ],
            )
          else if (_urlMode)
            PrimaryButton(
              label: '从链接导入',
              icon: Icons.link_rounded,
              onPressed: urlReady ? _runUrlImport : null,
            )
          else
            PrimaryButton(
              label: '开始导入',
              icon: Icons.playlist_add_rounded,
              onPressed: fileReady ? _runImport : null,
            ),
          const SizedBox(height: 24),
          Text(
            '素材版权归原权利人。本功能只处理你自己提供的本地文件或链接，仅供个人学习使用，不下载版权内容、不分享、不做视频转码。',
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

class _UrlRows extends StatelessWidget {
  const _UrlRows({
    required this.mediaController,
    required this.subtitleController,
    required this.enabled,
  });

  final TextEditingController mediaController;
  final TextEditingController subtitleController;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: mediaController,
          label: '音视频链接',
          hint: 'http(s)://… 指向 MP3 / M4A / WAV / MP4 等',
          enabled: enabled,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: subtitleController,
          label: '字幕链接（可选）',
          hint: 'http(s)://… 指向 .srt / .vtt；不填则无法切句',
          enabled: enabled,
        ),
      ],
    );
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
