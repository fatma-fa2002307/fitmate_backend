import ollama
import json
import pandas as pd
from typing import Optional, List, Dict
from app.models.schemas import WorkoutRequest, WorkoutResponse, Exercise
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
        # Load and prepare exercise database for RAG
        self.df = pd.read_csv('data/exercises.csv')
        self.exercise_categories = self._prepare_exercise_categories()

    def _prepare_exercise_categories(self) -> Dict[str, List[Dict[str, str]]]:
        """Prepare exercise database for RAG by organizing exercises by category."""
        categories = {
            'Legs': ['Legs'],
            'Push': ['Chest', 'Shoulders', 'Triceps'],
            'Pull': ['Back', 'Biceps'],
            'Core': ['Abdominals']
        }
        
        organized_exercises = {}
        for category, body_parts in categories.items():
            exercises = self.df[self.df['BodyPart'].isin(body_parts)].to_dict('records')
            organized_exercises[category] = exercises
            
        return organized_exercises

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

    def _format_exercises_for_prompt(self, category: str) -> str:
        """Format exercises for the prompt in a structured way."""
        exercises = self.exercise_categories.get(category, [])
        exercise_list = "\n".join([
            f"- {ex['Title']} ({ex['BodyPart']})"
            for ex in exercises
        ])
        return exercise_list

    def _generate_prompt(self, data: WorkoutRequest, category: str) -> str:
        """Generate a more concise RAG-enhanced prompt."""
        # Get only exercise titles for the category
        available_exercises = self.exercise_categories.get(category, [])
        exercise_list = ", ".join([ex['Title'] for ex in available_exercises])
        
        # Simplified intensity guidelines
        intensity_map = {
            'Beginner': '3 sets, 10-12 reps',
            'Intermediate': '4 sets, 8-12 reps',
            'Advanced': '5 sets, 6-12 reps'
        }
        
        intensity = intensity_map.get(data.fitnessLevel, intensity_map[data.fitnessLevel])
        
        return f"""Create a {category} workout with EXACTLY 4 exercises for a {data.age}yo {data.gender}, {data.height}cm, {data.weight}kg, goal: {data.goal}, level: {data.fitnessLevel}.

    Guidelines: {intensity}

    Available exercises: {exercise_list}

    Return JSON only, EXACTLY 4 exercises, in this format:
    {{
    "workouts": [
        {{ "workout": "Exercise Name", "sets": "3", "reps": "10" }}
    ]
    }}

    Use ONLY exercises from the list. No comments or explanations.
    """

    def generate_workout(self, data: WorkoutRequest) -> WorkoutResponse:
        try:
            # Determine next workout category
            next_category = self._get_next_category(data.workoutDays, data.lastWorkoutCategory)
            
            # Generate optimized prompt
            prompt = self._generate_prompt(data=data, category=next_category)
            
            # Use system message to enforce JSON response
            response = ollama.chat(
                model="gemma:2b", 
                messages=[
                    {"role": "system", "content": "You are a fitness API that returns only JSON."},
                    {"role": "user", "content": prompt}
                ],
                options={"temperature": 0.1}  # Lower temperature for more deterministic output
            )
            
            content = response['message']['content'].strip()
            
            try:
                parsed_response = json.loads(content)
            except json.JSONDecodeError as e:
                print(f"JSON Parse Error: {str(e)}")
                print(f"Content attempting to parse: {content}")
                # Provide a fallback workout if parsing fails
                parsed_response = {
                    "workouts": [
                        {
                            "workout": "Bodyweight Squat",
                            "sets": "3",
                            "reps": "12-15",
                            "instruction": "Stand with feet shoulder-width apart, lower your body as if sitting back into a chair, then push through your heels to return to standing."
                        },
                        {
                            "workout": "Push Ups",
                            "sets": "3",
                            "reps": "8-12",
                            "instruction": "Start in a plank position, lower your body until your chest nearly touches the ground, then push back up."
                        },
                        {
                            "workout": "Plank",
                            "sets": "3",
                            "reps": "30 seconds",
                            "instruction": "Hold a straight-arm plank position, keeping your body in a straight line from head to heels."
                        }
                    ]
                }
            
            workouts = parsed_response.get("workouts", [])
            
            # Validate and ensure exercises are from our database
            valid_workouts = []
            available_exercises = [ex['Title'] for ex in self.exercise_categories[next_category]]
            
            for workout in workouts:
                if workout["workout"] in available_exercises:
                    # Ensure all required fields are present
                    cleaned_workout = {
                        "workout": workout["workout"],
                        "image": self.exercise_db.get_exercise_icon(workout["workout"]),
                        "sets": workout.get("sets", "3"),
                        "reps": workout.get("reps", "12"),
                        "instruction": workout.get("instruction", "Perform the exercise with proper form.")
                    }
                    valid_workouts.append(cleaned_workout)
            
            # Ensure minimum number of exercises
            while len(valid_workouts) < 5:
                for exercise in available_exercises:
                    if len(valid_workouts) >= 5:
                        break
                    if exercise not in [w["workout"] for w in valid_workouts]:
                        valid_workouts.append({
                            "workout": exercise,
                            "image": self.exercise_db.get_exercise_icon(exercise),
                            "sets": "3",
                            "reps": "12",
                            "instruction": "Perform the exercise with proper form."
                        })
                        break
            
            return WorkoutResponse(workouts=valid_workouts, category=next_category)
        except Exception as e:
            print(f"Error in generate_workout: {str(e)}")
            raise