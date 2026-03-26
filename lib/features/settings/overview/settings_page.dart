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
  final _bypassController = TextEditingController();
  bool _isEditing = false;
  bool _isBypassEditing = false;

  @override
  void dispose() {
    _urlController.dispose();
    _bypassController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).requireValue;
    final activeProfile = ref.watch(activeProfileProvider);
    final addState = ref.watch(addProfileNotifierProvider);
    final locale = ref.watch(localePreferencesProvider);
    final version = ref.watch(appInfoProvider).valueOrNull?.presentVersion ?? '';
    final savedBypass = ref.watch(ConfigOptions.customBypassDomains);

    // Pre-fill URL from active profile if not editing
    if (!_isEditing) {
      final url = activeProfile.valueOrNull is RemoteProfileEntity
          ? (activeProfile.valueOrNull as RemoteProfileEntity).url
          : '';
      if (_urlController.text != url) {
        _urlController.text = url;
      }
    }

    // Pre-fill bypass domains if not editing
    if (!_isBypassEditing && _bypassController.text != savedBypass) {
      _bypassController.text = savedBypass;
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
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
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
                  Text(
                    'Домены через запятую (например: domain:mangoffice.ru,domain:mango-office.ru)',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey),
                  ),
                  const Gap(8),
                  TextField(
                    controller: _bypassController,
                    decoration: InputDecoration(
                      hintText: 'domain:example.ru,domain:bank.ru',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    onChanged: (_) => setState(() => _isBypassEditing = true),
                  ),
                  const Gap(12),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(ConfigOptions.customBypassDomains.notifier).update(_bypassController.text.trim());
                        setState(() => _isBypassEditing = false);
                      },
                      icon: const Icon(Icons.save_rounded, size: 20),
                      label: const Text('Сохранить', style: TextStyle(fontWeight: FontWeight.w600)),
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

          // Per-app proxy section (Android only)
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
                subtitle: const Text('Укажите приложения, которые работают напрямую'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.goNamed('per-app-proxy'),
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
                    onTap: () => ref
                        .read(localePreferencesProvider.notifier)
                        .changeLocale(AppLocale.ru),
                  ),
                  const Gap(8),
                  _LangChip(
                    label: 'EN',
                    selected: locale == AppLocale.en,
                    onTap: () => ref
                        .read(localePreferencesProvider.notifier)
                        .changeLocale(AppLocale.en),
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
