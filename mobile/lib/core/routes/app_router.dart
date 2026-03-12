import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/global_providers.dart';
import '../theme/app_theme.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/call/presentation/video_call_screen.dart';
import '../../features/discovery/presentation/screens/discovery_screen.dart';
import '../../features/match/presentation/screens/match_animation_screen.dart';
import '../../features/premium/presentation/paywall_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/chat/view/messages_list_screen.dart';
import '../../features/chat/view/chat_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = auth.isAuthenticated;
      final isLoading = auth.isLoading;

      final path = state.uri.path;
      final loggingIn = path == '/login' || path == '/register';

      if (isLoading) {
        return null;
      }

      if (!isLoggedIn && !loggingIn) {
        return '/login';
      }

      if (isLoggedIn && (path == '/login' || path == '/splash')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const _SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return _ShellScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiscoveryScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/messages',
            name: 'messages',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MessagesListScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          return CustomTransitionPage(
            child: ChatDetailScreen(
              name: extra?['name'] ?? '',
              avatarUrl: extra?['avatarUrl'] ?? '',
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/call/:matchId',
        name: 'call',
        builder: (context, state) {
          // Şimdilik avatarlar mock; gerçek veriyi matchId ile backend'den çekersin.
          return const VideoCallScreen();
        },
      ),
      GoRoute(
        path: '/paywall',
        name: 'paywall',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PaywallScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween =
                Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/match',
        name: 'match',
        builder: (context, state) {
          final currentAvatar = state.extra is Map
              ? (state.extra as Map)['currentAvatar'] as String?
              : null;
          final matchedAvatar = state.extra is Map
              ? (state.extra as Map)['matchedAvatar'] as String?
              : null;
          return MatchAnimationScreen(
            currentUserAvatar: currentAvatar ??
                'https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg',
            matchedUserAvatar: matchedAvatar ??
                'https://images.pexels.com/photos/2379005/pexels-photo-2379005.jpeg',
          );
        },
      ),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this.ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ShellScaffold extends ConsumerWidget {
  const _ShellScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;

    int index;
    if (location.startsWith('/profile')) {
      index = 1;
    } else if (location.startsWith('/messages')) {
      index = 2;
    } else if (location.startsWith('/settings')) {
      index = 3;
    } else {
      index = 0;
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          child,
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _FloatingNavBar(
                currentIndex: index,
                onTap: (i) {
                  switch (i) {
                    case 0:
                      GoRouter.of(context).go('/home');
                      break;
                    case 1:
                      GoRouter.of(context).go('/profile');
                      break;
                    case 2:
                      GoRouter.of(context).go('/messages');
                      break;
                    case 3:
                      GoRouter.of(context).go('/settings');
                      break;
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha:0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.55),
                offset: const Offset(0, 18),
                blurRadius: 40,
                spreadRadius: -12,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _FloatingNavIcon(
                icon: Icons.radar_rounded,
                active: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _FloatingNavIcon(
                icon: Icons.person_outline,
                active: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _FloatingNavIcon(
                icon: Icons.chat_bubble_rounded,
                active: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _FloatingNavIcon(
                icon: Icons.settings_outlined,
                active: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingNavIcon extends StatelessWidget {
  const _FloatingNavIcon({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(active ? 10 : 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              active ? Colors.white.withValues(alpha:0.12) : Colors.transparent,
        ),
        child: AnimatedScale(
          scale: active ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Icon(
            icon,
            color:
                active ? AppColors.accentPurpleSoft : AppColors.softGrey,
          ),
        ),
      ),
    );
  }
}

