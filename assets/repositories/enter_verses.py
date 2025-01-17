import json
import re

def load_json_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        return json.load(file)

def save_json_file(data, file_path):
    with open(file_path, 'w', encoding='utf-8') as file:
        json.dump(data, file, ensure_ascii=False, indent=2)

BIBLE_BOOKS = [
    "1. Mose", "2. Mose", "3. Mose", "4. Mose", "5. Mose",
    "Josua", "Richter", "Ruth", "1. Samuel", "2. Samuel",
    "1. Könige", "2. Könige", "1. Chronika", "2. Chronika",
    "Esra", "Nehemia", "Esther", "Hiob", "Psalm", "Sprüche",
    "Prediger", "Hohes Lied", "Jesaja", "Jeremia", "Klagelieder",
    "Hesekiel", "Daniel", "Hosea", "Joel", "Amos", "Obadja",
    "Jona", "Micha", "Nahum", "Habakuk", "Zephanja", "Haggai",
    "Sacharja", "Maleachi", "Matthäus", "Markus", "Lukas",
    "Johannes", "Apostelgeschichte", "Römer", "1. Korinther",
    "2. Korinther", "Galater", "Epheser", "Philipper", "Kolosser",
    "1. Thessalonicher", "2. Thessalonicher", "1. Timotheus",
    "2. Timotheus", "Titus", "Philemon", "Hebräer", "Jakobus",
    "1. Petrus", "2. Petrus", "1. Johannes", "2. Johannes",
    "3. Johannes", "Judas", "Offenbarung"
]

def get_book_name(book_index):
    return BIBLE_BOOKS[book_index]

def parse_verse_reference(verse_ref):
    match = re.match(r"([\w\s\.]+)\s+(\d+):(\d+)", verse_ref)
    if match:
        return match.group(1), int(match.group(2)), int(match.group(3))
    return None, None, None

def add_verses_to_schedule(schedule_path, verses_path):
    print(f"\nLade Dateien...")
    schedule = load_json_file(schedule_path)
    verses = load_json_file(verses_path)
    
    print(f"Gefundene Verse: {len(verses)}")
    verses_added = 0
    
    # Durch alle Wochen und Tage iterieren
    for week_idx, week in enumerate(schedule):
        for day_idx, day in enumerate(week):
            # Prüfe ob es ein einzelner Abschnitt ist
            if isinstance(day, dict) and "bookIndex" in day:
                section = day
                print(f"\nPrüfe Abschnitt:")
                print(f"bookIndex: {section['bookIndex']} ({get_book_name(section['bookIndex'])})")
                print(f"chapter: {section['chapter']}-{section['endChapter']}")
                
                # Suche passende Verse
                for verse_ref, verse_data in verses.items():
                    if verse_matches_section(
                        verse_ref,
                        section["bookIndex"],
                        section["chapter"],
                        section["endChapter"],
                        section["startIndex"],
                        section["endIndex"]
                    ):
                        if "verses" not in section:
                            section["verses"] = {}
                        section["verses"][verse_ref] = verse_data
                        verses_added += 1
                        print(f"✓ Vers hinzugefügt: {verse_ref}")
            
            # Prüfe ob es eine Liste von Abschnitten ist
            elif isinstance(day, list):
                for section in day:
                    if isinstance(section, dict) and "bookIndex" in section:
                        print(f"\nPrüfe Abschnitt:")
                        print(f"bookIndex: {section['bookIndex']} ({get_book_name(section['bookIndex'])})")
                        print(f"chapter: {section['chapter']}-{section['endChapter']}")
                        
                        # Suche passende Verse
                        for verse_ref, verse_data in verses.items():
                            if verse_matches_section(
                                verse_ref,
                                section["bookIndex"],
                                section["chapter"],
                                section["endChapter"],
                                section["startIndex"],
                                section["endIndex"]
                            ):
                                if "verses" not in section:
                                    section["verses"] = {}
                                section["verses"][verse_ref] = verse_data
                                verses_added += 1
                                print(f"✓ Vers hinzugefügt: {verse_ref}")
    
    if verses_added > 0:
        save_json_file(schedule, schedule_path)
        print(f"\nGesamtzahl eingefügter Verse: {verses_added}")
        print("Datei wurde gespeichert!")
    else:
        print("\nKeine Verse gefunden!")

def verse_matches_section(verse_ref, book_index, chapter, end_chapter, start_index, end_index):
    book_name, verse_chapter, verse_num = parse_verse_reference(verse_ref)
    
    if book_name is None or verse_chapter is None or verse_num is None:
        return False
        
    section_book_name = get_book_name(book_index)
    
    # Prüfe ob Buch übereinstimmt
    if book_name != section_book_name:
        return False
    
    # Prüfe ob Kapitel im Bereich liegt
    if not (chapter <= verse_chapter <= end_chapter):
        return False
    
    # Für alle Verse in den angegebenen Kapiteln
    return True

def add_videos_to_schedule(schedule_path, videos_path):
    print(f"\nLade Dateien für Videos...")
    schedule = load_json_file(schedule_path)
    videos = load_json_file(videos_path)
    
    videos_added = 0
    processed_books = set()  # Hier speichern wir die bereits verarbeiteten Bücher
    
    for week in schedule:
        for day in week:
            if isinstance(day, list):
                for section in day:
                    if isinstance(section, dict) and "bookIndex" in section:
                        current_book_index = section['bookIndex']
                        current_book = get_book_name(current_book_index)
                        
                        # Prüfe ob wir dieses Buch noch nicht verarbeitet haben
                        if current_book not in processed_books:
                            print(f"\nNeues Bibelbuch gefunden: {current_book} (Index: {current_book_index})")
                            
                            # Bei Index 0 füge auch die allgemeine Einführung hinzu
                            if current_book_index == 0 and "Einführung" not in processed_books:
                                if "videos" not in section:
                                    section["videos"] = {}
                                section["videos"]["Einführung"] = videos["Einführung"]
                                videos_added += 1
                                processed_books.add("Einführung")
                                print(f"✓ Video 'Einführung in die Bibel' hinzugefügt")
                            
                            # Füge Video für das aktuelle Bibelbuch hinzu
                            if current_book in videos:
                                if "videos" not in section:
                                    section["videos"] = {}
                                section["videos"][current_book] = videos[current_book]
                                videos_added += 1
                                processed_books.add(current_book)
                                print(f"✓ Video für {current_book} hinzugefügt")
            
            # Für den Fall, dass der Tag direkt ein Abschnitt ist
            elif isinstance(day, dict) and "bookIndex" in day:
                current_book_index = day['bookIndex']
                current_book = get_book_name(current_book_index)
                
                # Prüfe ob wir dieses Buch noch nicht verarbeitet haben
                if current_book not in processed_books:
                    print(f"\nNeues Bibelbuch gefunden: {current_book} (Index: {current_book_index})")
                    
                    # Bei Index 0 füge auch die allgemeine Einführung hinzu
                    if current_book_index == 0 and "Einführung" not in processed_books:
                        if "videos" not in day:
                            day["videos"] = {}
                        day["videos"]["Einführung"] = videos["Einführung"]
                        videos_added += 1
                        processed_books.add("Einführung")
                        print(f"✓ Video 'Einführung in die Bibel' hinzugefügt")
                    
                    # Füge Video für das aktuelle Bibelbuch hinzu
                    if current_book in videos:
                        if "videos" not in day:
                            day["videos"] = {}
                        day["videos"][current_book] = videos[current_book]
                        videos_added += 1
                        processed_books.add(current_book)
                        print(f"✓ Video für {current_book} hinzugefügt")
    
    print(f"\nGesamtzahl eingefügter Videos: {videos_added}")
    print(f"Verarbeitete Bibelbücher: {len(processed_books)}")
    if videos_added > 0:
        save_json_file(schedule, schedule_path)
        print("Datei wurde gespeichert!")
    else:
        print("Keine Videos eingefügt!")

# Beispielaufruf
schedule_file = "schedule_canonical_y4.json"
videos_file = "videos.json"

print("Starte Video-Verarbeitung...")
add_videos_to_schedule(schedule_file, videos_file)
print("Fertig!")

# Beispielaufruf
schedule_file = "schedule_canonical_y4.json"
verses_file = "bible_verses.json"

print("Starte Verarbeitung...")
add_verses_to_schedule(schedule_file, verses_file)
print("Fertig!")