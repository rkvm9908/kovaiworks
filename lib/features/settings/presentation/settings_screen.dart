import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(t.language, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'en', label: Text(t.english)),
              ButtonSegment(value: 'ta', label: Text(t.tamil)),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (s) =>
                ref.read(localeProvider.notifier).setLocale(s.first),
          ),
        ],
      ),
    );
  }
}