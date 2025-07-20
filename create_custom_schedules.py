import json
import os
import math

# Configuration for different schedule types
SCHEDULE_CONFIG = {
    'gospels': {
        'book_indices': [39, 40, 41, 42],  # Matthew, Mark, Luke, John
    },
    'greek_scriptures': {
        'book_indices': list(range(39, 66)),  # From Matthew to Revelation
    }
}

# Number of days for each duration
DURATION_DAYS = {
    'm3': 91,   # ~3 months
    'm6': 183,  # ~6 months
    'y1': 365,
    'y2': 730,
    'y4': 1460,
}

def get_filtered_sections(chronological_schedule_path, book_indices):
    """
    Reads the longest chronological schedule and extracts all sections 
    belonging to the specified book indices, maintaining their order.
    """
    print(f"Reading all sections for specified books from {chronological_schedule_path}...")
    with open(chronological_schedule_path, 'r', encoding='utf-8') as f:
        schedule = json.load(f)
    
    filtered_sections = []
    for day in schedule:
        if isinstance(day, list):
            for section in day:
                if isinstance(section, dict) and section.get('bookIndex') in book_indices:
                    filtered_sections.append(section)
    
    print(f"Found {len(filtered_sections)} total matching sections.")
    return filtered_sections

def distribute_sections(sections, num_days):
    """
    Distributes a list of sections as evenly as possible over a given number of days.
    """
    total_sections = len(sections)
    
    base_sections_per_day = total_sections // num_days
    extra_sections = total_sections % num_days
    
    print(f"Distributing {total_sections} sections into {num_days} days.")
    print(f"Base sections per day: {base_sections_per_day}")
    print(f"Days with an extra section: {extra_sections}")

    final_schedule = []
    current_section_index = 0
    for i in range(num_days):
        num_to_assign = base_sections_per_day + (1 if i < extra_sections else 0)
        
        day_content = sections[current_section_index : current_section_index + num_to_assign]
        final_schedule.append(day_content)
        current_section_index += num_to_assign
        
    return final_schedule


def main():
    base_path = 'assets/repositories'
    source_schedule_path = os.path.join(base_path, 'schedule_chronological_y4.json')
    
    if not os.path.exists(source_schedule_path):
        print(f"Error: Source schedule file not found at {source_schedule_path}")
        return

    for schedule_type, config in SCHEDULE_CONFIG.items():
        print(f"\n--- Processing schedule type: {schedule_type} ---")
        
        all_filtered_sections = get_filtered_sections(source_schedule_path, config['book_indices'])
    
        for duration, num_days in DURATION_DAYS.items():
            output_filename = f'schedule_{schedule_type}_{duration}.json'
            output_filepath = os.path.join(base_path, output_filename)
            
            print(f"\nCreating {output_filename} for a duration of {num_days} days...")
            
            distributed_schedule = distribute_sections(all_filtered_sections, num_days)
            
            with open(output_filepath, 'w', encoding='utf-8') as f:
                json.dump(distributed_schedule, f, ensure_ascii=False, indent=2)
            
            print(f"Successfully created {output_filepath} with {len(distributed_schedule)} days.")

if __name__ == "__main__":
    main() 