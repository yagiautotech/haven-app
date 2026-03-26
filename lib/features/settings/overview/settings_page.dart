import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/gen/translations.g.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _urlController = TextEditingController();
  final _addDomainController = TextEditingController();
  final _addProcessController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _urlController.dispose();
    _addDomainController.dispose();
    _addProcessController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _urlController.text = data!.text!;
        _isEditing = true;
      });
    }
  }

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    await ref.read(addProfileNotifierProvider.notifier).addClipboard(url);
    setState(() => _isEditing = false);
  }

  List<String> _parseSaved(String saved) =>
      saved.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  void _addDomain() {
    final input = _addDomainController.text.trim();
    if (input.isEmpty) return;
    final saved = ref.read(ConfigOptions.customBypassDomains);
    final list = _parseSaved(saved);
    if (!list.contains(input)) {
      list.add(input);
      ref.read(ConfigOptions.customBypassDomains.notifier).update(list.join(','));
    }
    _addDomainController.clear();
  }

  void _removeDomain(String domain) {
    final saved = ref.read(ConfigOptions.customBypassDomains);
    final list = _parseSaved(saved)..remove(domain);
    ref.read(ConfigOptions.customBypassDomains.notifier).update(list.join(','));
  }

  void _addProcess() {
    final input = _addProcessController.text.trim();
    if (input.isEmpty) return;
    final saved = ref.read(ConfigOptions.customBypassProcesses);
    final list = _parseSaved(saved);
    if (!list.contains(input)) {
      list.add(input);
      ref.read(ConfigOptions.customBypassProcesses.notifier).update(list.join(','));
    }
    _addProcessController.clear();
  }

  void _removeProcess(String process) {
    final saved = ref.read(ConfigOptions.customBypassProcesses);
    final list = _parseSaved(saved)..remove(process);
    ref.read(ConfigOptions.customBypassProcesses.notifier).update(list.join(','));
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).requireValue;
    final activeProfile = ref.watch(activeProfileProvider);
    final addState = ref.watch(addProfileNotifierProvider);
    final locale = ref.watch(localePreferencesProvider);
    final version = ref.watch(appInfoProvider).valueOrNull?.presentVersion ?? '';
    final bypassDomains = _parseSaved(ref.watch(ConfigOptions.customBypassDomains));
    final bypassProcesses = _parseSaved(ref.watch(ConfigOptions.customBypassProcesses));

    if (!_isEditing) {
      final url = activeProfile.valueOrNull is RemoteProfileEntity
          ? (activeProfile.valueOrNull as RemoteProfileEntity).url
          : '';
      if (_urlController.text != url) _urlController.text = url;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.settings.title),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Subscription section
          _SectionHeader(label: 'Подписка'),
          const Gap(8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Subscription URL',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey),
                  ),
                  const Gap(8),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'https://...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.content_paste_rounded, size: 20),
                        tooltip: 'Вставить из буфера',
                        onPressed: _pasteFromClipboard,
                      ),
                    ),
                    maxLines: 2,
                    minLines: 1,
                    onChanged: (_) => setState(() => _isEditing = true),
                  ),
                  const Gap(12),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: addState.isLoading ? null : _saveUrl,
                      icon: addState.isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        activeProfile.valueOrNull != null ? 'Обновить' : 'Сохранить',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Gap(24),

          // Bypass domains section
          _SectionHeader(label: 'Сайты без VPN'),
          const Gap(8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (bypassDomains.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Добавьте сайты, которые будут открываться без VPN',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ),
                  ...bypassDomains.map((domain) => _BypassItem(
                    label: domain,
                    onDelete: () => _removeDomain(domain),
                  )),
                  if (bypassDomains.isNotEmpty) const Gap(8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addDomainController,
                          decoration: InputDecoration(
                            hintText: 'mango-office.ru',
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onSubmitted: (_) => _addDomain(),
                        ),
                      ),
                      const Gap(8),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _addDomain,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Добавить'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Gap(24),

          // Per-app proxy section (Android)
          if (PlatformUtils.isAndroid) ...[
            _SectionHeader(label: 'Приложения без VPN'),
            const Gap(8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: ListTile(
                leading: const Icon(Icons.apps_rounded, color: Color(0xFF1565C0)),
                title: const Text('Выбрать приложения'),
                subtitle: const Text('Приложения, которые работают без VPN'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.goNamed('per-app-proxy'),
              ),
            ),
            const Gap(24),
          ],

          // Per-process bypass (Windows/Linux/macOS)
          if (!PlatformUtils.isAndroid) ...[
            _SectionHeader(label: 'Программы без VPN'),
            const Gap(8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (bypassProcesses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Добавьте программы, трафик которых пойдёт напрямую (например: Mango.exe)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ...bypassProcesses.map((p) => _BypassItem(
                      label: p,
                      icon: Icons.terminal_rounded,
                      onDelete: () => _removeProcess(p),
                    )),
                    if (bypassProcesses.isNotEmpty) const Gap(8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addProcessController,
                            decoration: InputDecoration(
                              hintText: PlatformUtils.isWindows ? 'Mango.exe' : 'mango',
                              hintStyle: const TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onSubmitted: (_) => _addProcess(),
                          ),
                        ),
                        const Gap(8),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _addProcess,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text('Добавить'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Gap(24),
          ],

          // Language section
          _SectionHeader(label: t.pages.settings.general.locale),
          const Gap(8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded, size: 20, color: Color(0xFF1565C0)),
                  const Gap(12),
                  const Text('Язык / Language'),
                  const Spacer(),
                  _LangChip(
                    label: 'RU',
                    selected: locale == AppLocale.ru,
                    onTap: () => ref.read(localePreferencesProvider.notifier).changeLocale(AppLocale.ru),
                  ),
                  const Gap(8),
                  _LangChip(
                    label: 'EN',
                    selected: locale == AppLocale.en,
                    onTap: () => ref.read(localePreferencesProvider.notifier).changeLocale(AppLocale.en),
                  ),
                ],
              ),
            ),
          ),

          const Gap(24),

          // About section
          _SectionHeader(label: t.pages.about.title),
          const Gap(8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Assets.images.logo.svg(height: 48),
                      const Gap(14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.common.appTitle,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          if (version.isNotEmpty)
                            Text(
                              'v$version',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.open_in_browser_rounded, color: Color(0xFF1565C0)),
                  title: const Text('haven.yagihub.ru'),
                  subtitle: const Text('Сайт и поддержка'),
                  onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.websiteUrl)),
                ),
              ],
            ),
          ),

          const Gap(32),
        ],
      ),
    );
  }
}

class _BypassItem extends StatelessWidget {
  const _BypassItem({required this.label, required this.onDelete, this.icon = Icons.language_outlined});

  final String label;
  final IconData icon;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Gap(12),
            Icon(icon, size: 16, color: const Color(0xFF1565C0)),
            const Gap(8),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14)),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade500),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1565C0) : Colors.transparent,
          border: Border.all(
            color: selected ? const Color(0xFF1565C0) : Colors.grey.shade400,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade600,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
