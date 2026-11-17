import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../core/logger.dart';
import '../../data/secure/key_store.dart';
import '../../domain/models/models.dart';
import '../../domain/models/provider_presets.dart';
import '../../services/llm/llm_client.dart';
import '../../services/llm/llm_models.dart';

/// 模型配置：集中配置对话模型与语音识别。
///
/// 简化方案（DeepSeek / MiMo）只需填一个 Key，地址、模型名与识别协议
/// 由预设决定；自定义方案分别配置 AI 模型与 ASR 模型。
class ModelConfigPage extends ConsumerStatefulWidget {
  const ModelConfigPage({super.key});

  @override
  ConsumerState<ModelConfigPage> createState() => _ModelConfigPageState();
}

class _ModelConfigPageState extends ConsumerState<ModelConfigPage> {
  static const _asrPresets = <String, Map<String, String>>{
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

  final _schemeKey = TextEditingController();
  final _baseUrl = TextEditingController();
  final _model = TextEditingController();
  final _apiKey = TextEditingController();
  final _asrBaseUrl = TextEditingController();
  final _asrModel = TextEditingController();
  final _asrApiKey = TextEditingController();
  final _expBaseUrl = TextEditingController();
  final _expModel = TextEditingController();
  final _expApiKey = TextEditingController();

  ConfigScheme _scheme = ConfigScheme.custom;
  bool _expEnabled = false;
  bool _loading = true;
  bool _testing = false;
  bool _saving = false;
  bool _obscure = true;
  String? _error;
  ConnectionCheck? _check;
  LlmProfile? _profile;
  String? _storedMask;
  String? _asrStoredMask;
  String? _expStoredMask;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(llmProfileRepositoryProvider);
    final keyStore = ref.read(keyStoreProvider);
    final settings = ref.read(settingsRepositoryProvider);
    await settings.load();
    final profile = await repo.loadOrCreate();
    final key = await keyStore.read(profile.keyRef);
    final asrKey = await keyStore.read(SettingsKeys.asrKeyRef);
    final expKey = await keyStore.read(SettingsKeys.asrExperimentalKeyRef);
    if (!mounted) return;
    setState(() {
      _scheme = ConfigScheme.from(settings.getString(SettingsKeys.configScheme));
      _profile = profile;
      _baseUrl.text = profile.baseUrl;
      _model.text = profile.model;
      _asrBaseUrl.text = settings.getString(
        SettingsKeys.asrBaseUrl,
        customPreset.asrBaseUrl,
      );
      _asrModel.text = settings.getString(SettingsKeys.asrModel, customPreset.asrModel);
      _expEnabled =
          settings.getString(SettingsKeys.asrExperimentalEnabled, 'false') == 'true';
      _expBaseUrl.text = settings.getString(
        SettingsKeys.asrExperimentalBaseUrl,
        'https://aiping.cn/api/v1',
      );
      _expModel.text = settings.getString(SettingsKeys.asrExperimentalModel, 'MiMo-V2.6-Flash');
      _storedMask = KeyStore.mask(key);
      _asrStoredMask = KeyStore.mask(asrKey);
      _expStoredMask = KeyStore.mask(expKey);
      if (profile.lastCheckStatus == 'ok' || profile.lastCheckStatus == 'fail') {
        _check = ConnectionCheck(
          status: profile.lastCheckStatus,
          message: profile.lastCheckMessage ?? '',
          latencyMs: 0,
        );
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _schemeKey.dispose();
    _baseUrl.dispose();
    _model.dispose();
    _apiKey.dispose();
    _asrBaseUrl.dispose();
    _asrModel.dispose();
    _asrApiKey.dispose();
    _expBaseUrl.dispose();
    _expModel.dispose();
    _expApiKey.dispose();
    super.dispose();
  }

  ProviderPreset get _preset => presetFor(_scheme);

  bool get _isPresetScheme => _scheme != ConfigScheme.custom;

  String? _validate() {
    if (_isPresetScheme) {
      if (_schemeKey.text.trim().isEmpty && (_storedMask == null || _storedMask == '未填写')) {
        return '请填写 ${_preset.scheme.label} API Key';
      }
      return null;
    }
    final base = _baseUrl.text.trim();
    if (base.isEmpty) return '请填写接口地址';
    if (!base.startsWith('http://') && !base.startsWith('https://')) {
      return '接口地址需要以 http:// 或 https:// 开头';
    }
    if (_model.text.trim().isEmpty) return '请填写模型名称';
    final asrBase = _asrBaseUrl.text.trim();
    if (asrBase.isEmpty) return '请填写识别接口地址';
    if (!asrBase.startsWith('http://') && !asrBase.startsWith('https://')) {
      return '识别接口地址需要以 http:// 或 https:// 开头';
    }
    if (_asrModel.text.trim().isEmpty) return '请填写识别模型';
    return null;
  }

  Future<String?> _currentLlmKey() async {
    final typed = _scheme == ConfigScheme.custom ? _apiKey.text.trim() : _schemeKey.text.trim();
    if (typed.isNotEmpty) return typed;
    final profile = _profile;
    if (profile == null) return null;
    final stored = await ref.read(keyStoreProvider).read(profile.keyRef);
    return stored == null || stored.isEmpty ? null : stored;
  }

  Future<void> _test() async {
    setState(() {
      _error = _validate();
      _check = null;
    });
    if (_error != null) return;
    final key = await _currentLlmKey();
    if (key == null) {
      setState(() => _error = '请填写 API Key');
      return;
    }
    setState(() => _testing = true);
    final client = ref.read(llmClientProvider);
    final check = await client.check(LlmConfig(
      baseUrl: _isPresetScheme ? _preset.llmBaseUrl : _baseUrl.text.trim(),
      apiKey: key,
      model: _isPresetScheme ? _preset.llmModel : _model.text.trim(),
    ));
    final profile = _profile;
    if (profile != null) {
      await ref.read(llmProfileRepositoryProvider).markCheck(profile, check.status, check.message);
    }
    if (!mounted) return;
    setState(() {
      _testing = false;
      _check = check;
      _error = null;
    });
    AppLogger.debug('model check status=${check.status} latency=${check.latencyMs}ms');
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final profile = _profile;
    if (profile == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final keyStore = ref.read(keyStoreProvider);
      final settings = ref.read(settingsRepositoryProvider);
      if (_isPresetScheme) {
        // 简化方案：一个 Key 同时写入对话模型与语音识别，
        // 地址 / 模型 / 识别协议全部按预设覆盖。
        final typedKey = _schemeKey.text.trim();
        final key = typedKey.isNotEmpty
            ? typedKey
            : await keyStore.read(profile.keyRef);
        if (key != null && key.isNotEmpty) {
          await keyStore.write(profile.keyRef, key);
          await keyStore.write(SettingsKeys.asrKeyRef, key);
        }
        await settings.set(SettingsKeys.configScheme, _scheme.value);
        await settings.set(SettingsKeys.asrMode, _preset.asrMode);
        await settings.set(SettingsKeys.asrBaseUrl, _preset.asrBaseUrl);
        await settings.set(SettingsKeys.asrModel, _preset.asrModel);
        await settings.set(SettingsKeys.asrExperimentalEnabled, 'false');
        final updated = profile.copyWith(
          baseUrl: _preset.llmBaseUrl,
          model: _preset.llmModel,
        );
        await ref.read(llmProfileRepositoryProvider).save(updated);
        _schemeKey.clear();
        if (!mounted) return;
        setState(() {
          _profile = updated;
          _scheme = _preset.scheme;
        });
      } else {
        final typedKey = _apiKey.text.trim();
        if (typedKey.isNotEmpty) {
          await keyStore.write(profile.keyRef, typedKey);
          _apiKey.clear();
        }
        final typedAsrKey = _asrApiKey.text.trim();
        if (typedAsrKey.isNotEmpty) {
          await keyStore.write(SettingsKeys.asrKeyRef, typedAsrKey);
          _asrApiKey.clear();
        }
        if (_expApiKey.text.trim().isNotEmpty) {
          await keyStore.write(SettingsKeys.asrExperimentalKeyRef, _expApiKey.text.trim());
          _expApiKey.clear();
        }
        await settings.set(SettingsKeys.configScheme, ConfigScheme.custom.value);
        await settings.set(SettingsKeys.asrMode, AsrModes.openai);
        await settings.set(
          SettingsKeys.asrBaseUrl,
          _asrBaseUrl.text.trim().replaceAll(RegExp(r'/+$'), ''),
        );
        await settings.set(SettingsKeys.asrModel, _asrModel.text.trim());
        await settings.set(SettingsKeys.asrExperimentalEnabled, _expEnabled ? 'true' : 'false');
        await settings.set(
          SettingsKeys.asrExperimentalBaseUrl,
          _expBaseUrl.text.trim().replaceAll(RegExp(r'/+$'), ''),
        );
        await settings.set(SettingsKeys.asrExperimentalModel, _expModel.text.trim());
        final updated = profile.copyWith(
          baseUrl: _baseUrl.text.trim().replaceAll(RegExp(r'/+$'), ''),
          model: _model.text.trim(),
        );
        await ref.read(llmProfileRepositoryProvider).save(updated);
        if (!mounted) return;
        setState(() => _profile = updated);
      }
      ref.invalidate(profileInfoProvider);
      final key = await _currentLlmKey();
      final asrKey = await keyStore.read(SettingsKeys.asrKeyRef);
      if (!mounted) return;
      setState(() {
        _storedMask = KeyStore.mask(key);
        _asrStoredMask = KeyStore.mask(asrKey);
        _saving = false;
      });
      if (mounted) showAppToast(context, '配置已保存');
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
    final check = _check;
    return PageScaffold(
      title: '模型配置',
      bottomBar: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: PrimaryButton(
                label: '保存配置',
                loading: _saving,
                onPressed: _loading ? null : _save,
              ),
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
                          const Icon(Icons.hub_rounded, size: 18, color: AppColors.primaryDeep),
                          const SizedBox(width: 8),
                          Text('配置方案', style: AppText.cardTitle),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '选 DeepSeek 或 MiMo 时只需填一个 Key，对话与语音识别都走同一家的模型；'
                        '自定义方案分别配置 AI 模型与 ASR 模型。',
                        style: AppText.caption.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedControl(
                  items: [
                    for (final scheme in ConfigScheme.values) scheme.label,
                  ],
                  index: ConfigScheme.values.indexOf(_scheme),
                  onChanged: (i) => setState(() {
                    _scheme = ConfigScheme.values[i];
                    _error = null;
                  }),
                ),
                const SizedBox(height: 20),
                if (_isPresetScheme)
                  _buildPresetBody()
                else
                  _buildCustomBody(),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  ErrorBanner(message: _error!),
                ],
                if (check != null) ...[
                  const SizedBox(height: 14),
                  InlineNotice(
                    message: check.ok
                        ? '连接成功，耗时 ${check.latencyMs} ms。${check.message}'
                        : check.message,
                    ok: check.ok,
                    onClose: () => setState(() => _check = null),
                  ),
                ],
                if (!_isPresetScheme && check != null && check.models.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('接口返回的模型（${check.models.length}）', style: AppText.caption),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: check.models
                        .take(18)
                        .map(
                          (model) => GestureDetector(
                            onTap: () => setState(() => _model.text = model),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: model == _model.text ? AppColors.primary : AppColors.surfaceTint,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: model == _model.text ? AppColors.primary : AppColors.divider,
                                ),
                              ),
                              child: Text(
                                model,
                                style: AppText.tag.copyWith(
                                  fontSize: 10,
                                  color: model == _model.text ? Colors.white : AppColors.inkSecondary,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 20),
                SecondaryButton(
                  label: _testing ? '连接中…' : '测试连接',
                  icon: Icons.wifi_tethering_rounded,
                  onPressed: _testing ? null : _test,
                ),
                const SizedBox(height: 20),
                AppCard(
                  shadow: false,
                  color: AppColors.surfaceTint,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('排查提示', style: AppText.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(
                        '· 401/403：密钥无效或没有该模型权限\n'
                        '· 404：接口地址不对，确认是否包含 /v1\n'
                        '· 429：请求太频繁，稍后再试\n'
                        '· 思考型模型（如 GLM Flash）会先输出思考内容，正文可能稍慢',
                        style: AppText.caption.copyWith(height: 1.7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// DeepSeek / MiMo 简化方案：预设信息 + 单个 Key 输入。
  Widget _buildPresetBody() {
    final preset = _preset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          shadow: false,
          color: AppColors.surfaceTint,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _presetInfoRow('对话模型', preset.llmModel),
              const Divider(height: 14, color: AppColors.divider),
              _presetInfoRow('语音识别', preset.asrLabel),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _schemeKey,
          label: '${preset.scheme.label} API Key',
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
                '密钥以安全存储保存，对话与识别共用，界面仅显示尾号。',
                style: AppText.caption.copyWith(fontSize: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _presetInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: AppText.caption.copyWith(color: AppColors.inkSecondary)),
        ),
        Expanded(
          child: Text(value, style: AppText.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  /// 自定义方案：分别配置 AI 模型与 ASR 模型。
  Widget _buildCustomBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI 模型（对话）', style: AppText.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        AppTextField(
          controller: _baseUrl,
          label: '接口地址 Base URL',
          hint: 'https://example.com/api/v1',
          keyboardType: TextInputType.url,
          prefixIcon: Icons.link_rounded,
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _model,
          label: '模型名称',
          hint: '例如 GLM-5.3-Flash',
          prefixIcon: Icons.memory_rounded,
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _apiKey,
          label: 'API Key',
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
                '密钥以安全存储保存，界面仅显示尾号。',
                style: AppText.caption.copyWith(fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('语音识别（ASR）', style: AppText.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _asrPresets.entries.map((entry) {
            final selected = _asrModel.text.trim() == entry.value['model'];
            return GestureDetector(
              onTap: () => setState(() {
                _asrModel.text = entry.value['model']!;
                _asrBaseUrl.text = entry.value['base']!;
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
        const SizedBox(height: 14),
        AppTextField(
          controller: _asrBaseUrl,
          label: '识别接口 Base URL',
          hint: 'https://api.siliconflow.cn/v1',
          keyboardType: TextInputType.url,
          prefixIcon: Icons.link_rounded,
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _asrModel,
          label: '识别模型',
          hint: 'FunAudioLLM/SenseVoiceSmall',
          prefixIcon: Icons.memory_rounded,
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _asrApiKey,
          label: '识别 API Key',
          hint: _asrStoredMask == null || _asrStoredMask == '未填写'
              ? 'sk-...'
              : '已保存 $_asrStoredMask，留空则不修改',
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
        const SizedBox(height: 16),
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
                '· 识别配置与对话模型分开保存，互不覆盖\n'
                '· 录音以 16k 单声道 WAV 上传，返回纯文本\n'
                '· 未配置密钥时退回系统识别，不会影响对话主流程',
                style: AppText.caption.copyWith(height: 1.7),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
