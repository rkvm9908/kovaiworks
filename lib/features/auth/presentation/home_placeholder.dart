import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

class HomePlaceholder extends StatelessWidget {
  final bool isWorker;
  const HomePlaceholder({super.key, required this.isWorker});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(isWorker ? t.workerHome : t.ownerHome),
        actions: [
                    IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: t.logout,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/role');
            },
          ),
        ],
      ),
      body: Center(child: Text('Logged in: ${user?.phoneNumber}')),
    );
  }
}