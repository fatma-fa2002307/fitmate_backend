import ollama
import json
import pandas as pd
import random
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

    def _get_set_rep_guidelines(self, fitness_level: str) -> dict:
        """Get set and rep guidelines based on fitness level."""
        guidelines = {
            "Beginner": {
                "sets": "3",
                "sets_range": "3",
                "reps": "10-12",
                "reps_range": "10-12"
            },
            "Intermediate": {
                "sets": "3-4",
                "sets_range": "3-4",
                "reps": "8-12",
                "reps_range": "8-12"
            },
            "Advanced": {
                "sets": "2-4",
                "sets_range": "2-4",
                "reps": "6-12",
                "reps_range": "6-12"
            }
        }
        return guidelines.get(fitness_level, guidelines["Beginner"])

    def generate_workout_options(self, data: WorkoutRequest, num_options: int = 3) -> dict:
        """Generate multiple workout options with variations, ensuring at least 2 exercises differ between options."""
        try:
            # Determine next workout category
            next_category = self._get_next_category(data.workoutDays, data.lastWorkoutCategory)
            
            # Get available exercises for this category
            available_exercises = self.exercise_categories.get(next_category, [])
            exercise_list = ", ".join([ex['Title'] for ex in available_exercises])
            
            # Get set and rep guidelines based on fitness level
            guidelines = self._get_set_rep_guidelines(data.fitnessLevel)
            
            # Prepare a prompt for the model that emphasizes our specific requirements
            prompt = f"""Create EXACTLY 3 workout options for a {data.age}yo {data.gender}, {data.height}cm, {data.weight}kg, fitness level: {data.fitnessLevel}, goal: {data.goal}.

Today's focus is: {next_category} workout.

VERY IMPORTANT REQUIREMENTS:
1. Each option should have 4-5 exercises depending on intensity (use 5 for lower intensity exercises)
2. Use ONLY exercises from this list: {exercise_list}
3. You can repeat exercises between options, but EACH OPTION MUST DIFFER BY AT LEAST 2 EXERCISES from other options
4. Each option should target different muscles within the {next_category} category. AVOID OVERWORKING MUSCLES!
5. For each exercise, choose appropriate sets and reps within these guidelines:
   - For {data.fitnessLevel} level:
   - Sets: {guidelines["sets_range"]} (choose a specific number for each exercise)
   - Reps: {guidelines["reps_range"]} (choose a specific number or range for each exercise)
6. Heavier or more challenging exercises should have fewer reps/sets, while lighter exercises can have more
Return in this JSON format:
{{
"options": [
    [
    {{ "workout": "Exercise Name", "sets": "3", "reps": "10-12" }},
    {{ "workout": "Exercise Name", "sets": "4", "reps": "8" }},
    {{ "workout": "Exercise Name", "sets": "3", "reps": "10" }},
    {{ "workout": "Exercise Name", "sets": "3", "reps": "12" }},
    {{ "workout": "Exercise Name", "sets": "4", "reps": "8-10" }} // optional 5th exercise
    ],
    [
    {{ "workout": "Exercise Name", "sets": "3", "reps": "12" }},
    {{ "workout": "Exercise Name", "sets": "4", "reps": "8" }},
    {{ "workout": "Exercise Name", "sets": "3", "reps": "10-12" }},
    {{ "workout": "Exercise Name", "sets": "3", "reps": "10" }},
    {{ "workout": "Exercise Name", "sets": "4", "reps": "8" }} // optional 5th exercise
    ],
    [
    {{ "workout": "Exercise Name", "sets": "3", "reps": "10-12" }},
    {{ "workout": "Exercise Name", "sets": "3", "reps": "12" }},
    {{ "workout": "Exercise Name", "sets": "4", "reps": "8" }},
    {{ "workout": "Exercise Name", "sets": "3", "reps": "10" }},
    {{ "workout": "Exercise Name", "sets": "3", "reps": "8-10" }} // optional 5th exercise
    ]
]
}}

Remember to choose SPECIFIC set and rep numbers or ranges for EACH exercise based on its difficulty and the fitness level.
Return ONLY the JSON without any explanations.
"""
            
            # Use system message to enforce JSON response
            response = ollama.chat(
                model="llama3.2", 
                messages=[
                    {"role": "system", "content": "You are a fitness API that returns only clean JSON. You must ensure each workout option differs from others by at least 2 exercises and uses appropriate sets/reps for each specific exercise."},
                    {"role": "user", "content": prompt}
                ],
                options={"temperature": 0.4}  # Lower temperature for more deterministic output
            )
            
            content = response['message']['content'].strip()
            
            try:
                parsed_response = json.loads(content)
                
                # Extract options list
                workout_options = parsed_response.get("options", [])
                
                # Verify that we have exactly 3 options
                if len(workout_options) != 3:
                    raise ValueError(f"Expected 3 workout options, got {len(workout_options)}")
                    
                # Verify that each option has 4-5 exercises
                for i, option in enumerate(workout_options):
                    if len(option) < 4 or len(option) > 5:
                        raise ValueError(f"Option {i+1} has {len(option)} exercises instead of 4-5")
                
                # Verify that each option differs from others by at least 2 exercises
                self._verify_option_differences(workout_options)
                
                # Process each option to add image paths
                processed_options = []
                for option in workout_options:
                    processed_exercises = []
                    
                    # Dictionary to check if this is a valid exercise
                    valid_exercise_dict = {ex['Title']: True for ex in available_exercises}
                    
                    for exercise in option:
                        exercise_name = exercise["workout"]
                        
                        # Verify this is a valid exercise from our dataset
                        if exercise_name in valid_exercise_dict:
                            # Add the exercise with correct fields
                            processed_exercise = {
                                "workout": exercise_name,
                                "image": self.exercise_db.get_exercise_icon(exercise_name),
                                "sets": exercise.get("sets", guidelines["sets"]),
                                "reps": exercise.get("reps", guidelines["reps"]),
                                "instruction": "" # No instruction as requested
                            }
                            processed_exercises.append(processed_exercise)
                    
                    # If we have 4-5 valid exercises in this option
                    if 4 <= len(processed_exercises) <= 5:
                        processed_options.append(processed_exercises)
                    else:
                        # If not enough valid exercises, fill with random ones from the category
                        target_count = min(5, max(4, len(option)))  # Keep original count if valid, otherwise ensure at least 4
                        
                        while len(processed_exercises) < target_count:
                            random_exercise = random.choice(available_exercises)
                            exercise_name = random_exercise['Title']
                            if exercise_name not in [ex["workout"] for ex in processed_exercises]:
                                # For fallback exercises, generate random sets and reps within the guidelines
                                if guidelines["sets_range"].find("-") > 0:
                                    min_sets, max_sets = map(int, guidelines["sets_range"].split("-"))
                                    sets = str(random.randint(min_sets, max_sets))
                                else:
                                    sets = guidelines["sets"]
                                
                                if guidelines["reps_range"].find("-") > 0:
                                    min_reps, max_reps = map(int, guidelines["reps_range"].split("-"))
                                    if random.choice([True, False]):  # 50% chance of range vs single number
                                        range_min = random.randint(min_reps, max_reps - 2)
                                        range_max = random.randint(range_min + 2, max_reps)
                                        reps = f"{range_min}-{range_max}"
                                    else:
                                        reps = str(random.randint(min_reps, max_reps))
                                else:
                                    reps = guidelines["reps"]
                                
                                processed_exercise = {
                                    "workout": exercise_name,
                                    "image": self.exercise_db.get_exercise_icon(exercise_name),
                                    "sets": sets,
                                    "reps": reps,
                                    "instruction": ""
                                }
                                processed_exercises.append(processed_exercise)
                        
                        processed_options.append(processed_exercises)
                
                # If we have all 3 valid options
                if len(processed_options) == 3:
                    return {
                        "options": processed_options,
                        "category": next_category
                    }
                else:
                    # If not enough valid options, create fallback options
                    return self._create_fallback_options(available_exercises, next_category, data)
                    
            except (json.JSONDecodeError, ValueError) as e:
                print(f"Error: {str(e)}")
                print(f"Content attempting to parse: {content}")
                
                # Create fallback options if JSON parsing fails
                return self._create_fallback_options(available_exercises, next_category, data)
                    
        except Exception as e:
            print(f"Error in generate_workout_options: {str(e)}")
            # Get available exercises for this category
            available_exercises = self.exercise_categories.get(next_category, [])
            return self._create_fallback_options(available_exercises, next_category, data)

    def _verify_option_differences(self, workout_options):
        """Verify that each option differs from others by at least 2 exercises."""
        for i in range(len(workout_options)):
            for j in range(i+1, len(workout_options)):
                option1_exercises = set(ex["workout"] for ex in workout_options[i])
                option2_exercises = set(ex["workout"] for ex in workout_options[j])
                
                common_exercises = option1_exercises.intersection(option2_exercises)
                
                if len(common_exercises) > 2:  # More than 2 exercises in common (less than 2 different)
                    raise ValueError(f"Options {i+1} and {j+1} do not differ by at least 2 exercises")

    def _create_fallback_options(self, available_exercises, category, data):
        """Create fallback workout options if the main method fails."""
        try:
            guidelines = self._get_set_rep_guidelines(data.fitnessLevel)
            
            if len(available_exercises) < 8:  # Not enough exercises for 3 distinct options
                print(f"Not enough exercises in category {category} for distinct options")
                
            # Create 3 distinct workout options
            all_exercises = [ex['Title'] for ex in available_exercises]
            options = []
            
            # Ensure we have enough exercises
            if len(all_exercises) < 4:
                while len(all_exercises) < 4:
                    all_exercises.append(f"Generic {category} Exercise {len(all_exercises) + 1}")
                    
            # Create first option with 4-5 random exercises
            num_exercises = 5 if data.fitnessLevel == "Beginner" and len(all_exercises) >= 5 else 4
            option1 = random.sample(all_exercises, min(num_exercises, len(all_exercises)))
            options.append(option1)
            
            # Create second option with 2 from first option and 2 new ones
            remaining_exercises = [ex for ex in all_exercises if ex not in option1]
            if len(remaining_exercises) < 2:
                remaining_exercises.extend([f"Generic {category} Exercise {len(all_exercises) + i}" for i in range(2)])
                
            option2 = random.sample(option1, 2) + random.sample(remaining_exercises, 2)
            options.append(option2)
            
            # Create third option with 2 from second option and 2 new ones
            remaining_exercises = [ex for ex in all_exercises if ex not in option2]
            if len(remaining_exercises) < 2:
                remaining_exercises.extend([f"Generic {category} Exercise {len(all_exercises) + i}" for i in range(2)])
                
            option3 = random.sample(option2, 2) + random.sample(remaining_exercises, 2)
            options.append(option3)
            
            # Format options
            formatted_options = []
            for option in options:
                formatted_option = []
                for exercise in option:
                    # Generate varying sets and reps for each exercise
                    if guidelines["sets_range"].find("-") > 0:
                        min_sets, max_sets = map(int, guidelines["sets_range"].split("-"))
                        sets = str(random.randint(min_sets, max_sets))
                    else:
                        sets = guidelines["sets"]
                    
                    if guidelines["reps_range"].find("-") > 0:
                        min_reps, max_reps = map(int, guidelines["reps_range"].split("-"))
                        if random.choice([True, False]):  # 50% chance of range vs single number
                            range_min = random.randint(min_reps, max_reps - 2)
                            range_max = random.randint(range_min + 2, max_reps)
                            reps = f"{range_min}-{range_max}"
                        else:
                            reps = str(random.randint(min_reps, max_reps))
                    else:
                        reps = guidelines["reps"]
                        
                    formatted_option.append({
                        "workout": exercise,
                        "image": self.exercise_db.get_exercise_icon(exercise),
                        "sets": sets,
                        "reps": reps,
                        "instruction": ""
                    })
                formatted_options.append(formatted_option)
                
            return {
                "options": formatted_options,
                "category": category
            }
        except Exception as e:
            print(f"Error creating fallback options: {str(e)}")
            # Return minimal valid response
            return {
                "options": [],
                "category": category
            }