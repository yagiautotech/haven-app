import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/go_router/helper/custom_transition.dart';
import 'package:hiddify/features/home/widget/home_page.dart';
import 'package:hiddify/features/intro/widget/intro_page.dart';
import 'package:hiddify/features/settings/overview/settings_page.dart';
import 'package:hiddify/core/router/go_router/refresh_listenable.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'routing_config_notifier.g.dart';

// when the routing config is not yet initialized, this config is used
final loadingConfig = RoutingConfig(
  routes: <RouteBase>[GoRoute(path: '/home', builder: (context, state) => const Material())],
);

@Riverpod(keepAlive: true)
class RoutingConfigNotifier extends _$RoutingConfigNotifier {
  @override
  RoutingConfig build() {
    return RoutingConfig(
      redirect: (context, state) {
        final introCompleted = ref.read(Preferences.introCompleted);
        final isIntro = state.matchedLocation == '/intro';

        // handle deep links / URL protocol
        String? url;
        if (LinkParser.protocols.contains(state.uri.scheme)) {
          url = state.uri.toString();
        } else if (PlatformUtils.isDesktop && newUrlFromAppLink.isNotEmpty) {
          url = newUrlFromAppLink;
          newUrlFromAppLink = '';
        } else if (state.uri.queryParameters['url'] != null) {
          url = state.uri.queryParameters['url'];
        }

        if (!introCompleted) {
          return url != null ? '/intro?url=$url' : '/intro';
        } else if (isIntro) {
          if (url != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(url: url),
            );
          }
          return '/home';
        } else if (url != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(url: url),
          );
          return '/home';
        }
        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          name: 'home',
          path: '/home',
          builder: (_, _) => const HomePage(),
          routes: [
            GoRoute(
              name: 'settings',
              path: '/settings',
              pageBuilder: (_, state) =>
                  customTransition(TransitionType.slide, state.pageKey, const SettingsPage()),
            ),
          ],
        ),
        GoRoute(
          name: 'intro',
          path: '/intro',
          builder: (_, _) => const IntroPage(),
        ),
      ],
    );
  }
}
