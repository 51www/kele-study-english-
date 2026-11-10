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
import '../../services/llm/llm_client.dart';
import '../../services/llm/llm_models.dart';

class ModelConfigPage extends ConsumerStatefulWidget {
  const ModelConfigPage({super.key});

  @override
  ConsumerState<ModelConfigPage> createState() => _ModelConfigPageState();
}

class _ModelConfigPageState extends ConsumerState<ModelConfigPage> {
  final _baseUrl = TextEditingController();
  final _model = TextEditingController();
  final _apiKey = TextEditingController();
  bool _loading = true;
  bool _testing = false;
  bool _saving = false;
  bool _obscure = true;
  String? _error;
  ConnectionCheck? _check;
  LlmProfile? _profile;
  String? _storedMask;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(llmProfileRepositoryProvider);
    final keyStore = ref.read(keyStoreProvider);
    final profile = await repo.loadOrCreate();
    final key = await keyStore.read(profile.keyRef);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _baseUrl.text = profile.baseUrl;
      _model.text = profile.model;
      _storedMask = KeyStore.mask(key);
      _loading = false;
      if (profile.lastCheckStatus == 'ok' || profile.lastCheckStatus == 'fail') {
        _check = ConnectionCheck(
          status: profile.lastCheckStatus,
          message: profile.lastCheckMessage ?? '',
          latencyMs: 0,
        );
      }
    });
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _model.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<String?> _currentKey() async {
    final typed = _apiKey.text.trim();
    if (typed.isNotEmpty) return typed;
    final profile = _profile;
    if (profile == null) return null;
    final stored = await ref.read(keyStoreProvider).read(profile.keyRef);
    return stored == null || stored.isEmpty ? null : stored;
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

  Future<void> _test() async {
    setState(() {
      _error = _validate();
      _check = null;
    });
    if (_error != null) return;
    final key = await _currentKey();
    if (key == null) {
      setState(() => _error = '请填写 API Key');
      return;
    }
    setState(() => _testing = true);
    final client = ref.read(llmClientProvider);
    final check = await client.check(LlmConfig(
      baseUrl: _baseUrl.text.trim(),
      apiKey: key,
      model: _model.text.trim(),
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
      final typedKey = _apiKey.text.trim();
      if (typedKey.isNotEmpty) {
        await ref.read(keyStoreProvider).write(profile.keyRef, typedKey);
        _apiKey.clear();
      }
      final updated = profile.copyWith(
        baseUrl: _baseUrl.text.trim().replaceAll(RegExp(r'/+$'), ''),
        model: _model.text.trim(),
      );
      await ref.read(llmProfileRepositoryProvider).save(updated);
      ref.invalidate(profileInfoProvider);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _saving = false;
      });
      final key = await _currentKey();
      setState(() => _storedMask = KeyStore.mask(key));
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
                          Text('OpenAI 兼容接口', style: AppText.cardTitle),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '接口地址、密钥与模型名都由你填写。密钥只保存在本机安全存储里，不会写入日志或仓库。',
                        style: AppText.caption.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                if (check != null && check.models.isNotEmpty) ...[
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
}
