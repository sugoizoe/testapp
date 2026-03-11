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
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
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
    final router = GoRouter.of(context);
    final location = GoRouterState.of(context).uri.path;

    int index;
    if (location.startsWith('/profile')) {
      index = 1;
    } else if (location.startsWith('/settings')) {
      index = 2;
    } else {
      index = 0;
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: child,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: index,
        onTap: (i) {
          switch (i) {
            case 0:
              router.go('/home');
              break;
            case 1:
              router.go('/profile');
              break;
            case 2:
              router.go('/settings');
              break;
          }
        },
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.deepCharcoal.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            icon: Icons.radar_rounded,
            label: 'Keşfet',
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Ayarlar',
            selected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? AppColors.accentPurpleSoft : AppColors.softGrey;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

