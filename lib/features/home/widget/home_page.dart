import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final activeProfile = ref.watch(activeProfileProvider);
    final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    final version = ref.watch(appInfoProvider).valueOrNull?.presentVersion ?? '';

    final isConnected = connectionStatus.valueOrNull?.isConnected ?? false;
    final isSwitching = connectionStatus.valueOrNull?.isSwitching ?? false;

    final Color statusColor = switch (connectionStatus) {
      AsyncData(value: Connected()) => const Color(0xFF2E7D32),
      AsyncData(value: Connecting()) || AsyncData(value: Disconnecting()) => const Color(0xFFF57C00),
      _ => const Color(0xFF1565C0),
    };

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Assets.images.logo.svg(height: 28),
            const Gap(10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.common.appTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (version.isNotEmpty)
                  Text(version, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.goNamed('settings'),
            tooltip: t.pages.settings.title,
          ),
          const Gap(4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Connection button
                _ConnectButton(
                  statusColor: statusColor,
                  isSwitching: isSwitching,
                  hasProfile: hasAnyProfile.valueOrNull ?? false,
                  onTap: () async {
                    if (isSwitching) return;
                    if (!(hasAnyProfile.valueOrNull ?? false)) {
                      context.goNamed('settings');
                      return;
                    }
                    await ref.read(connectionNotifierProvider.notifier).toggleConnection();
                  },
                ),

                const Gap(20),

                // Status label
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    key: ValueKey(connectionStatus.toString()),
                    switch (connectionStatus) {
                      AsyncData(value: final status) => status.present(t),
                      _ => '',
                    },
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),

                const Gap(40),

                // Profile card
                switch (activeProfile) {
                  AsyncData(value: final profile?) => _ProfileCard(
                    profile: profile,
                    isConnected: isConnected,
                  ),
                  _ when !(hasAnyProfile.valueOrNull ?? true) => _NoProfileCard(
                    onAdd: () => context.goNamed('settings'),
                  ),
                  _ => const SizedBox.shrink(),
                },

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({
    required this.statusColor,
    required this.isSwitching,
    required this.hasProfile,
    required this.onTap,
  });

  final Color statusColor;
  final bool isSwitching;
  final bool hasProfile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 148,
        height: 148,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: isSwitching ? 8 : 24,
              spreadRadius: isSwitching ? 0 : 4,
              color: statusColor.withValues(alpha: isSwitching ? 0.3 : 0.5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: isSwitching
              ? CircularProgressIndicator(color: statusColor, strokeWidth: 3)
              : Assets.images.logo.svg(
                  colorFilter: ColorFilter.mode(statusColor, BlendMode.srcIn),
                ),
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.profile, required this.isConnected});

  final ProfileEntity profile;
  final bool isConnected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subInfo = profile is RemoteProfileEntity
        ? (profile as RemoteProfileEntity).subInfo
        : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.dns_rounded,
              color: isConnected ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
              size: 20,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subInfo != null && !subInfo.isExpired) ...[
                    const Gap(2),
                    _SubInfoBar(subInfo: subInfo),
                  ] else if (subInfo?.isExpired == true)
                    Text(
                      'Подписка истекла',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
                    ),
                ],
              ),
            ),
            if (profile is RemoteProfileEntity)
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Обновить',
                onPressed: () async {
                  await ref
                      .read(updateProfileNotifierProvider(profile.id).notifier)
                      .updateProfile(profile as RemoteProfileEntity);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SubInfoBar extends StatelessWidget {
  const _SubInfoBar({required this.subInfo});

  final SubscriptionInfo subInfo;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double val = bytes.toDouble();
    while (val >= 1024 && i < units.length - 1) {
      val /= 1024;
      i++;
    }
    return '${val.toStringAsFixed(1)} ${units[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = subInfo.remainingBW;
    final ratio = subInfo.remainingRatio;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(
                ratio > 0.3 ? const Color(0xFF1565C0) : Colors.orange,
              ),
            ),
          ),
        ),
        const Gap(8),
        Text(
          _formatBytes(remaining),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _NoProfileCard extends StatelessWidget {
  const _NoProfileCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF1565C0).withValues(alpha: 0.4)),
      ),
      color: const Color(0xFF1565C0).withValues(alpha: 0.06),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_link_rounded, color: Color(0xFF1565C0)),
              const Gap(10),
              const Text(
                'Добавьте подписку для подключения',
                style: TextStyle(
                  color: Color(0xFF1565C0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
