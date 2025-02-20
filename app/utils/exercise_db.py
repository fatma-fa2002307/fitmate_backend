import pandas as pd
from typing import Dict, List

class ExerciseDatabase:
    def __init__(self, csv_path: str = 'data/exercises.csv'):
        self.df = pd.read_csv(csv_path)
        self.exercise_dict = self.df.set_index('Title')['Icon'].to_dict()
        
        self.workout_categories = {
            'Legs': ['Legs'],
            'Push': ['Chest', 'Shoulders', 'Triceps'],
            'Pull': ['Back', 'Biceps'],
            'Core': ['Abdominals']
        }
    
    def get_exercise_icon(self, exercise_name: str) -> str:
        """Get the icon path for a given exercise name."""
        if exercise_name in self.exercise_dict:
            # Use the correct path that matches your directory structure
            return f"/workout-images/icons/{self.exercise_dict[exercise_name]}"
        return "/workout-images/icons/default-icon.png"
    
    def get_exercises_by_category(self, category: str) -> list:
        """Get all exercises for a given category."""
        target_body_parts = self.workout_categories.get(category, [])
        return self.df[self.df['BodyPart'].isin(target_body_parts)].to_dict('records')