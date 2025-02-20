import json
from typing import Optional
import openai
from app.models.schemas import WorkoutRequest, WorkoutResponse
from app.utils.exercise_db import ExerciseDatabase

class WorkoutEngine:
    def __init__(self):
        self.exercise_db = ExerciseDatabase()
        self.workout_sequence = {
            3: ['Legs', 'Push', 'Pull'],
            4: ['Legs', 'Push', 'Pull', 'Core'],
            5: ['Legs', 'Push', 'Pull', 'Legs', 'Core'],
            6: ['Legs', 'Push', 'Pull', 'Legs', 'Push', 'Core']
        }
        
    def _get_next_category(self, workout_days: int, last_category: Optional[str] = None) -> str:
        """Determine the next workout category based on the last workout."""
        sequence = self.workout_sequence.get(workout_days, self.workout_sequence[3])
        
        if not last_category:
            return sequence[0]
            
        try:
            current_index = sequence.index(last_category)
            next_index = (current_index + 1) % len(sequence)
            return sequence[next_index]
        except ValueError:
            return sequence[0]

    def _generate_prompt(self, data: WorkoutRequest, category: str) -> str:
        """Generate the prompt for OpenAI based on user data."""
        # Get available exercises for the category
        available_exercises = self.exercise_db.get_exercises_by_category(category)
        exercise_list = "\n".join([f"- {ex['Title']}" for ex in available_exercises])
        
        return f"""Generate a {category} workout plan with 5-6 exercises for a {data.age}-year-old {data.gender} 
        who is {data.height} cm tall, weighs {data.weight} kg, and wants to {data.goal}. 
        
        Choose ONLY from these available exercises:
        {exercise_list}
        
        Respond with ONLY a JSON array in this exact format:
        {{
            "workouts": [
                {{"workout": "Exercise Name", "image": ""}}
            ]
        }}
        
        The exercise names must EXACTLY match the ones provided in the list.
        Include 5-6 exercises from the {category} category only."""

    def generate_workout(self, data: WorkoutRequest) -> WorkoutResponse:
        try:
            # Determine next workout category
            next_category = self._get_next_category(data.workoutDays, data.lastWorkoutCategory)
            
            # Generate workout with OpenAI
            prompt = self._generate_prompt(data=data, category=next_category)
            
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "You are a professional fitness trainer. Respond only with the requested JSON format."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7
            )
            
            content = response.choices[0].message.content.strip()
            parsed_response = json.loads(content)
            workouts = parsed_response.get("workouts", [])
            
            # Add image paths
            for workout in workouts:
                workout["image"] = self.exercise_db.get_exercise_icon(workout["workout"])
            
            return WorkoutResponse(workouts=workouts, category=next_category)
        except Exception as e:
            print(f"Error in generate_workout: {str(e)}")
            raise