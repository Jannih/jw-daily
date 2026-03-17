import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nwt_reading/src/daily_text/entities/daily_text.dart';
import 'package:nwt_reading/src/daily_text/presentations/daily_text_page.dart';
import 'package:nwt_reading/src/daily_text/repositories/daily_text_repository.dart';
import 'package:nwt_reading/src/localization/app_localizations_getter.dart';

class DailyTextCard extends ConsumerStatefulWidget {
  const DailyTextCard({super.key});

  @override
  ConsumerState<DailyTextCard> createState() => _DailyTextCardState();
}

class _DailyTextCardState extends ConsumerState<DailyTextCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(dailyTextProvider);
      if (state.isLoading) {
        ref.read(dailyTextRepositoryProvider).loadTodaysDailyText();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncDailyText = ref.watch(dailyTextProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: context.loc.dailyTextTitle,
      child: GestureDetector(
      onTap: () {
        final dailyText = asyncDailyText.valueOrNull;
        if (dailyText != null) {
          Navigator.pushNamed(context, DailyTextPage.routeName);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.secondaryContainer,
              ],
            ),
          ),
          child: asyncDailyText.when(
            loading: () => _buildLoading(context),
            error: (error, _) => _buildError(context, error),
            data: (dailyText) => _buildContent(context, dailyText),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const SizedBox(
      height: 80,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return SizedBox(
      height: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off,
              color: Theme.of(context).colorScheme.error, size: 28),
          const SizedBox(height: 8),
          Text(
            context.loc.dailyTextNotAvailable,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            onPressed: () {
              ref.read(dailyTextProvider.notifier).state =
                  const AsyncValue.loading();
              ref.read(dailyTextRepositoryProvider).loadTodaysDailyText();
            },
            child: Text(context.loc.dailyTextRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, DailyText dailyText) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat('EEEE, d. MMMM', locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              context.loc.dailyTextTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            Text(
              dateFormat.format(dailyText.date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          dailyText.themeScripture,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          dailyText.themeText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: colorScheme.onSecondaryContainer,
              ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            context.loc.dailyTextReadMore,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}
