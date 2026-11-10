import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../data/secure/key_store.dart';
import '../../domain/models/models.dart';

/// 语音识别配置：与对话模型配置完全独立，互不覆盖。
/// 默认硅基流动 SenseVoiceSmall，可切换 Qwen3-ASR 或 Groq Whisper。
class AsrConfigPage extends ConsumerStatefulWidget {
  const AsrConfigPage({super.key});

  @override
  ConsumerState<AsrConfigPage> createState() => _AsrConfigPageState();
}

class _AsrConfigPageState extends ConsumerState<AsrConfigPage> {
  static const _presets = <String, Map<String, String>>{
    '硅基流动 SenseVoiceSmall': {
      'base': 'https://api.siliconflow.cn/v1',
      'model': 'FunAudioLLM/SenseVoiceSmall',
    },
    '硅基流动 Qwen3-ASR': {
      'base': 'https://api.siliconflow.cn/v1',
      'model': 'Qwen/Qwen3-ASR-1.7B',
    },
    'Groq Whisper Turbo': {
      'base': 'https://api.groq.com/openai/v1',
      'model': 'whisper-large-v3-turbo',
    },
  };

  final _baseUrl = TextEditingController();
  final _model = TextEditingController();
  final _apiKey = TextEditingController();
  final _expBaseUrl = TextEditingController();
  final _expModel = TextEditingController();
  final _expApiKey = TextEditingController();
  bool _expEnabled = false;
  bool _loading = true;
  bool _saving = false;
  bool _obscure = true;
  String? _error;
  String? _notice;
  String? _storedMask;
  String? _expStoredMask;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = ref.read(settingsRepositoryProvider);
    await settings.load();
    final key = await ref.read(keyStoreProvider).read(SettingsKeys.asrKeyRef);
    final expKey = await ref.read(keyStoreProvider).read(SettingsKeys.asrExperimentalKeyRef);
    if (!mounted) return;
    setState(() {
      _baseUrl.text = settings.getString(SettingsKeys.asrBaseUrl, 'https://api.siliconflow.cn/v1');
      _model.text = settings.getString(SettingsKeys.asrModel, 'FunAudioLLM/SenseVoiceSmall');
      _expEnabled = settings.getString(SettingsKeys.asrExperimentalEnabled, 'false') == 'true';
      _expBaseUrl.text =
          settings.getString(SettingsKeys.asrExperimentalBaseUrl, 'https://aiping.cn/api/v1');
      _expModel.text = settings.getString(SettingsKeys.asrExperimentalModel, 'MiMo-V2.6-Flash');
      _storedMask = KeyStore.mask(key);
      _expStoredMask = KeyStore.mask(expKey);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _model.dispose();
    _apiKey.dispose();
    _expBaseUrl.dispose();
    _expModel.dispose();
    _expApiKey.dispose();
    super.dispose();
  }

  String? _validate() {
    final base = _baseUrl.text.trim();
    if (base.isEmpty) return '请填写接口地址';
    if (!base.startsWith('http://') && !base.startsWith('https://')) {
      return '接口地址需要以 http:// 或 https:// 开头';
    }
    if (_model.text.trim().isEmpty) return '请填写模型名称';
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _notice = null;
    });
    try {
      final typedKey = _apiKey.text.trim();
      if (typedKey.isNotEmpty) {
        await ref.read(keyStoreProvider).write(SettingsKeys.asrKeyRef, typedKey);
        _apiKey.clear();
      }
      if (_expApiKey.text.trim().isNotEmpty) {
        await ref.read(keyStoreProvider).write(SettingsKeys.asrExperimentalKeyRef, _expApiKey.text.trim());
        _expApiKey.clear();
      }
      final settings = ref.read(settingsRepositoryProvider);
      await settings.set(SettingsKeys.asrBaseUrl, _baseUrl.text.trim().replaceAll(RegExp(r'/+$'), ''));
      await settings.set(SettingsKeys.asrModel, _model.text.trim());
      await settings.set(SettingsKeys.asrExperimentalEnabled, _expEnabled ? 'true' : 'false');
      await settings.set(SettingsKeys.asrExperimentalBaseUrl, _expBaseUrl.text.trim().replaceAll(RegExp(r'/+$'), ''));
      await settings.set(SettingsKeys.asrExperimentalModel, _expModel.text.trim());
      final key = await ref.read(keyStoreProvider).read(SettingsKeys.asrKeyRef);
      if (!mounted) return;
      setState(() {
        _storedMask = KeyStore.mask(key);
        _saving = false;
        _notice = key == null || key.isEmpty
            ? '已保存，但还没有密钥，识别会退回系统语音识别。'
            : '已保存。识别接口将在首次录音时实测。';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '保存失败：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '语音识别配置',
      bottomBar: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: PrimaryButton(label: '保存识别配置', loading: _saving, onPressed: _loading ? null : _save),
            ),
          ),
        ),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWash,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.graphic_eq_rounded, size: 18, color: AppColors.primaryDeep),
                          const SizedBox(width: 8),
                          Text('标准 OpenAI 语音识别协议', style: AppText.cardTitle),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '识别配置与对话模型分开保存。未配置或接口不可用时，会自动退回系统语音识别。',
                        style: AppText.caption.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('快速选择', style: AppText.caption),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.entries.map((entry) {
                    final selected = _model.text.trim() == entry.value['model'];
                    return GestureDetector(
                      onTap: () => setState(() {
                        _model.text = entry.value['model']!;
                        _baseUrl.text = entry.value['base']!;
                        _error = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.surfaceTint,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
                        ),
                        child: Text(
                          entry.key,
                          style: AppText.tag.copyWith(
                            fontSize: 10,
                            color: selected ? Colors.white : AppColors.inkSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _baseUrl,
                  label: '识别接口 Base URL',
                  hint: 'https://api.siliconflow.cn/v1',
                  keyboardType: TextInputType.url,
                  prefixIcon: Icons.link_rounded,
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _model,
                  label: '识别模型',
                  hint: 'FunAudioLLM/SenseVoiceSmall',
                  prefixIcon: Icons.memory_rounded,
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _apiKey,
                  label: '识别 API Key',
                  hint: _storedMask == null || _storedMask == '未填写'
                      ? 'sk-...'
                      : '已保存 $_storedMask，留空则不修改',
                  obscure: _obscure,
                  prefixIcon: Icons.key_rounded,
                  onChanged: (_) => setState(() => _error = null),
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 18,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.inkMuted),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '识别密钥与对话密钥分开存储，界面只显示尾号。',
                        style: AppText.caption.copyWith(fontSize: 10),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  ErrorBanner(message: _error!),
                ],
                if (_notice != null) ...[
                  const SizedBox(height: 14),
                  InlineNotice(message: _notice!, ok: true, onClose: () => setState(() => _notice = null)),
                ],
                const SizedBox(height: 20),
                AppCard(
                  shadow: false,
                  color: AppColors.surfaceTint,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        button: true,
                        label: '实验识别开关',
                        toggled: _expEnabled,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _expEnabled = !_expEnabled),
                          child: Row(
                            children: [
                              const Icon(Icons.science_outlined, size: 16, color: AppColors.inkSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '用对话模型做识别（实验）',
                                  style: AppText.caption.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _expEnabled,
                                activeTrackColor: AppColors.primary,
                                onChanged: (value) => setState(() => _expEnabled = value),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        '默认关闭。开启后作为兜底：已配置的识别接口失败时用同一段录音重试；未配置识别接口时优先于系统识别。'
                        '已知延迟 4–6 秒、无词级时间戳，输出依赖提示词，模型升级可能失效。',
                        style: AppText.caption.copyWith(fontSize: 10.5, height: 1.6),
                      ),
                      if (_expEnabled) ...[
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _expBaseUrl,
                          label: '实验识别 Base URL',
                          hint: 'https://aiping.cn/api/v1',
                          keyboardType: TextInputType.url,
                          prefixIcon: Icons.link_rounded,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _expModel,
                          label: '实验识别模型',
                          hint: 'MiMo-V2.6-Flash',
                          prefixIcon: Icons.memory_rounded,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _expApiKey,
                          label: '实验识别 API Key（可选）',
                          hint: _expStoredMask == null || _expStoredMask == '未填写'
                              ? '留空则复用对话模型密钥'
                              : '已保存 $_expStoredMask，留空则不修改',
                          obscure: _obscure,
                          prefixIcon: Icons.key_rounded,
                        ),
                      ],
                    ],
                  ),
                  ),
                const SizedBox(height: 20),
                AppCard(
                  shadow: false,
                  color: AppColors.surfaceTint,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('说明', style: AppText.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(
                        '· 默认硅基流动 SenseVoiceSmall，免费额度足够个人练习\n'
                        '· 换 Qwen3-ASR 或 Groq Whisper 只需改这里的地址与模型名\n'
                        '· 录音以 16k 单声道 WAV 上传，返回纯文本\n'
                        '· 未配置密钥时退回系统识别，不会影响对话主流程',
                        style: AppText.caption.copyWith(height: 1.7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
