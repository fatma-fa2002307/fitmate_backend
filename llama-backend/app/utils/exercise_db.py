import pandas as pd
import os
from typing import Dict, List

class ExerciseDatabase:
    def __init__(self, csv_path: str = 'data/exercises.csv'):
        self.df = pd.read_csv(csv_path)
        self.exercise_dict = self.df.set_index('Title')['Icon'].to_dict()
        
        # Add cardio exercises to the dictionary
        self.cardio_exercises = {
            "Treadmill Running": "cardio.webp",
            "Outdoor Running": "cardio.webp",
            "Walking": "cardio.webp",
            "Cycling": "cardio.webp",
            "Exercise Bike": "cardio.webp",
            "Jump Rope": "cardio.webp",
            "Swimming": "cardio.webp",
            "Hiking": "cardio.webp",
        }
        
        # Update the exercise dictionary with cardio exercises
        self.exercise_dict.update(self.cardio_exercises)
        
        # Define workout category mapping
        self.workout_categories = {
            'Legs': ['Legs'],
            'Push': ['Chest', 'Shoulders', 'Triceps'],
            'Pull': ['Back', 'Biceps'],
            'Core': ['Abdominals'],
            'Upper Body': ['Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps'],
            'Lower Body': ['Legs'],
            'Full Body': ['Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps', 'Legs', 'Abdominals'],
            'Cardio': ['Cardio']
        }
    
    def get_exercise_icon(self, exercise_name: str) -> str:
        """Get the icon path for a given exercise name."""
        if exercise_name in self.exercise_dict:
            # Use the correct path that matches your directory structure
            return f"/workout-images/icons/{self.exercise_dict[exercise_name]}"
        # Check if it's a cardio exercise by partial match
        for cardio_name in self.cardio_exercises:
            if cardio_name.lower() in exercise_name.lower():
                return f"/workout-images/icons/{self.cardio_exercises[cardio_name]}"
        return "/workout-images/icons/default-icon.png"
    
    def get_exercise_image(self, exercise_name: str) -> str:
        """Get the full image path for a given exercise name."""
        # For cardio, return the appropriate image
        for cardio_name in self.cardio_exercises:
            if cardio_name.lower() in exercise_name.lower():
                # Return the appropriate image filename based on cardio exercise name
                if "treadmill" in exercise_name.lower():
                    return "/workout-images/cardio/treadmill.webp"
                elif "outdoor running" in exercise_name.lower() or "running" in exercise_name.lower():
                    return "/workout-images/cardio/running.webp"
                elif "walking" in exercise_name.lower():
                    return "/workout-images/cardio/walking.webp"
                elif "cycling" in exercise_name.lower() or "bike" in exercise_name.lower():
                    if "exercise bike" in exercise_name.lower():
                        return "/workout-images/cardio/exercise-bike.webp"
                    else:
                        return "/workout-images/cardio/bicycle.webp"
                elif "jump rope" in exercise_name.lower():
                    return "/workout-images/cardio/jumping-rope.webp"
                elif "swimming" in exercise_name.lower():
                    return "/workout-images/cardio/swimming.webp"
                elif "hiking" in exercise_name.lower():
                    return "/workout-images/cardio/hiking.webp"
                # Default cardio image
                return "/workout-images/cardio/cardio.webp"
        
        # For strength training exercises, construct the image path from the exercise name
        formatted_name = exercise_name.replace(" ", "-")
        return f"/workout-images/{formatted_name}.webp"
    
    def get_exercises_by_category(self, category: str) -> list:
        """Get all exercises for a given category."""
        if category == "Cardio":
            # Return cardio exercises with proper formatting
            return [{"Title": name, "Icon": icon} for name, icon in self.cardio_exercises.items()]
            
        target_body_parts = self.workout_categories.get(category, [])
        return self.df[self.df['BodyPart'].isin(target_body_parts)].to_dict('records')