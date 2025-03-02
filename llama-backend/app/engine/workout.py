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
        """Generate RAG-enhanced prompt using exercise database."""
        available_exercises = self._format_exercises_for_prompt(category)
        
        # Add intensity guidelines based on fitness level
        intensity_guidelines = {
            'Beginner': {
                'sets': '3 sets, 8-12 reps with lighter weights',
                'desc': 'Focus on form and basic movements. Include more rest between sets.'
            },
            'Intermediate': {
                'sets': '4 sets, 8-12 reps with moderate weights',
                'desc': 'Increase complexity of exercises. Include supersets where appropriate.'
            },
            'Advanced': {
                'sets': '4-5 sets, 8-15 reps with challenging weights',
                'desc': 'Include advanced variations and complex movement patterns. Minimize rest periods.'
            }
        }
        
        current_intensity = intensity_guidelines.get(data.fitnessLevel, intensity_guidelines['Beginner'])
        
        return f"""
        You are a professional fitness trainer creating a {category} workout for a {data.age}-year-old {data.gender} 
        who is {data.height} cm tall, weighs {data.weight} kg, and wants to {data.goal}.
        Their fitness level is {data.fitnessLevel}.

        Intensity Guidelines for {data.fitnessLevel} level:
        {current_intensity['desc']}
        Recommended sets/reps: {current_intensity['sets']}

        Here are the available exercises for {category} training:
        {available_exercises}

        Create a workout plan using ONLY exercises from the above list. Your response must be valid JSON in this format:
        {{
            "workouts": [
                {{
                    "workout": "Exercise Name",
                    "image": "",
                    "sets": "3-4",
                    "reps": "8-12",                }}
            ]
        }}

        REQUIREMENTS:
        - Select 4-5 exercises from the provided list
        - Exercise names must EXACTLY match the ones provided
        - DO NOT invent new exercises
        - Include appropriate sets and reps based on fitness level
        - If an exercise is based on time like Plank, make the reps be Seconds/minutes
        - Focus on {data.goal} as the training goal
        - Make sure your suggestions match the user's fitness level
        - Make sure your suggestions vary in muscle groups to ensure successful workout
        """

    def generate_workout(self, data: WorkoutRequest) -> WorkoutResponse:
        try:
            # Determine next workout category
            next_category = self._get_next_category(data.workoutDays, data.lastWorkoutCategory)
            
            # Generate RAG-enhanced workout
            prompt = self._generate_prompt(data=data, category=next_category)
            response = ollama.chat(model="gemma:2b", messages=[{"role": "user", "content": prompt}])
            
            content = response['message']['content'].strip()
            
            # Clean up potential JSON formatting issues
            content = content.replace(",]", "]")  # Remove trailing commas in arrays
            content = content.replace(",}", "}")   # Remove trailing commas in objects
            
            # Extract JSON if it's embedded in markdown or other text
            if "```json" in content:
                start = content.find("{")
                end = content.rfind("}") + 1
                content = content[start:end]
            
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
                    if len(valid_workouts) >= 6:
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