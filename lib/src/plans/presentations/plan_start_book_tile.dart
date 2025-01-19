import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/bible_languages/entities/bible_languages.dart';
import 'package:nwt_reading/src/plans/stories/plan_edit_story.dart';

class PlanStartBookTile extends ConsumerWidget {
  const PlanStartBookTile(this.planId, {Key? key}) : super(key: key);

  final String? planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planEditProviderFamily(planId));
    final planEdit = ref.read(planEditProviderFamily(planId).notifier);
    final bibleLanguages = ref.watch(bibleLanguagesProvider);
    
    return bibleLanguages.when(
      data: (languages) {
        final language = languages.bibleLanguages[plan.language];
        final books = language?.books ?? <Book>[];
        
        return ListTile(
          title: const Text('Startpunkt wählen'),
          subtitle: const Text('Wähle das Bibelbuch, mit dem der Plan beginnen soll'),
          trailing: DropdownButton<String>(
            value: planEdit.startBook,
            hint: const Text('Von Anfang'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Von Anfang'),
              ),
              ...books.map((Book book) => DropdownMenuItem<String>(
                value: book.name,
                child: Text(book.name),
              )),
            ],
            onChanged: (value) => planEdit.updateStartBook(value),
          ),
        );
      },
      loading: () => const ListTile(
        title: Text('Startpunkt wählen'),
        trailing: CircularProgressIndicator(),
      ),
      error: (_, __) => const ListTile(
        title: Text('Startpunkt wählen'),
        subtitle: Text('Fehler beim Laden der Bibelbücher'),
      ),
    );
  }
}