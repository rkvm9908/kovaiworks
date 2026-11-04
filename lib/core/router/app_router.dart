import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../features/landing/landing_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/worker/presentation/worker_profile_setup.dart';
import '../../features/worker/presentation/worker_home.dart';
import '../../features/worker/presentation/my_work_screen.dart';
import '../../features/worker/presentation/worker_profile_screen.dart';
import '../../features/owner/presentation/employer_setup.dart';
import '../../features/owner/presentation/owner_home.dart';
import '../../features/owner/presentation/post_job_screen.dart';
import '../../features/owner/presentation/nearby_workers_map.dart';
import '../../features/owner/presentation/requests_screen.dart';
import '../../features/owner/presentation/owner_profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/notifications/notifications_screen.dart';

const _protected = [
  '/worker-home',
  '/owner-home',
  '/post-job',
  '/nearby',
  '/requests',
  '/my-work',
  '/profile',
  '/owner-profile',
  '/notifications',
];

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    if (!loggedIn && _protected.contains(state.matchedLocation)) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const LandingScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/role', builder: (_, __) => const RoleSelectionScreen()),
    GoRoute(
      path: '/login',
      builder: (_, state) =>
          LoginScreen(role: state.uri.queryParameters['role'] ?? 'worker'),
    ),
    GoRoute(path: '/worker-setup', builder: (_, __) => const WorkerProfileSetup()),
    GoRoute(path: '/owner-setup', builder: (_, __) => const EmployerSetup()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/worker-home', builder: (_, __) => const WorkerHome()),
    GoRoute(path: '/owner-home', builder: (_, __) => const OwnerHome()),
    GoRoute(path: '/post-job', builder: (_, __) => const PostJobScreen()),
    GoRoute(path: '/nearby', builder: (_, __) => const NearbyWorkersMap()),
    GoRoute(path: '/requests', builder: (_, __) => const RequestsScreen()),
    GoRoute(path: '/my-work', builder: (_, __) => const MyWorkScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const WorkerProfileScreen()),
    GoRoute(path: '/owner-profile', builder: (_, __) => const OwnerProfileScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
  ],
);