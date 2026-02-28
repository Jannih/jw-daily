import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nwt_reading/src/daily_text/entities/daily_text.dart';
import 'package:nwt_reading/src/daily_text/repositories/daily_text_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class DailyTextPage extends ConsumerWidget {
  const DailyTextPage({super.key});
  static const routeName = '/daily-text';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDailyText = ref.watch(dailyTextProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagestext'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'In JW Library öffnen',
            onPressed: () {
              final now = DateTime.now();
              final url = Uri.parse(
                  'https://www.jw.org/finder?srcid=jwlshare&wtlocale=X&prefer=lang&docid=${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}&par=0');
              launchUrl(url, mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
      body: asyncDailyText.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorView(context, ref, error),
        data: (dailyText) =>
            _buildDetailView(context, dailyText, colorScheme),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Tagestext konnte nicht geladen werden',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bitte prüfe deine Internetverbindung.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(dailyTextProvider.notifier).state =
                    const AsyncValue.loading();
                ref.read(dailyTextRepositoryProvider).loadTodaysDailyText();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView(
      BuildContext context, DailyText dailyText, ColorScheme colorScheme) {
    final dateFormat = DateFormat('EEEE, d. MMMM yyyy', 'de_DE');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 18, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(dailyText.date),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Theme scripture reference
          Text(
            dailyText.themeScripture,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
          ),
          const SizedBox(height: 16),

          // Theme text (the actual verse)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color: colorScheme.primary,
                  width: 4,
                ),
              ),
            ),
            child: Text(
              dailyText.themeText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                    color: colorScheme.onSurface,
                  ),
            ),
          ),
          const SizedBox(height: 24),

          // Comment
          Text(
            dailyText.comment,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 24),

          // Source reference
          if (dailyText.source.isNotEmpty)
            Text(
              dailyText.source,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
