import ollama
import json
import pandas as pd
import random
from typing import Optional, List, Dict
from app.models.schemas import WorkoutRequest, WorkoutResponse, Exercise
from app.utils.exercise_db import ExerciseDatabase


CARDIO_EXERCISES = [
    {"Title": "Treadmill Running", "Image": "treadmill.jpg", "Icon": "cardio.webp"},
    {"Title": "Outdoor Running", "Image": "running.heic", "Icon": "cardio.webp"},
    {"Title": "Walking", "Image": "walking.heic", "Icon": "cardio.webp"},
    {"Title": "Cycling", "Image": "bicycle.png", "Icon": "cardio.webp"},
    {"Title": "Exercise Bike", "Image": "exercise-bike.jpg", "Icon": "cardio.webp"},
    {"Title": "Jump Rope", "Image": "jumping-rope.jpg", "Icon": "cardio.webp"},
    {"Title": "Swimming", "Image": "swimming.avif", "Icon": "cardio.webp"},
    {"Title": "Hiking", "Image": "hiking.jpg", "Icon": "cardio.webp"},
]

class WorkoutEngine:
    def __init__(self):
        self.exercise_db = ExerciseDatabase()
        
        # Map workout plans based on goals and workout frequency
        self.workout_plans = {
            "Weight Loss": {
                1: ["Cardio"],
                2: ["Cardio", "Full Body"],
                3: ["Cardio", "Upper Body", "Lower Body"],
                4: ["Cardio", "Upper Body", "Lower Body", "Cardio"],
                5: ["Cardio", "Upper Body", "Lower Body", "Cardio", "Full Body"],
                6: ["Cardio", "Push", "Pull", "Legs", "Cardio", "Full Body"]
            },
            "Gain Muscle": {
                1: ["Full Body"],
                2: ["Upper Body", "Lower Body"],
                3: ["Push", "Pull", "Legs"],
                4: ["Upper Body", "Lower Body", "Upper Body", "Lower Body"],
                5: ["Push", "Pull", "Legs", "Upper Body", "Lower Body"],
                6: ["Push", "Pull", "Legs", "Push", "Pull", "Legs"]
            },
            "Improve Fitness": {
                1: ["Full Body"],
                2: ["Cardio", "Full Body"],
                3: ["Cardio", "Upper Body", "Lower Body"],
                4: ["Cardio", "Push", "Pull", "Legs"],
                5: ["Cardio", "Push", "Pull", "Legs", "Full Body"],
                6: ["Cardio", "Push", "Pull", "Legs", "Cardio", "Full Body"]
            }
        }
        
        # Traditional workout sequence for backwards compatibility
        self.workout_sequence = {
            3: ['Legs', 'Push', 'Pull'],
            4: ['Legs', 'Push', 'Pull', 'Core'],
            5: ['Legs', 'Push', 'Pull', 'Legs', 'Core'],
            6: ['Legs', 'Push', 'Pull', 'Legs', 'Push', 'Core']
        }
        
        # Map workout categories to body parts
        self.category_mapping = {
            "Push": ["Chest", "Shoulders", "Triceps"],
            "Pull": ["Back", "Biceps"],
            "Legs": ["Legs"],
            "Upper Body": ["Chest", "Back", "Shoulders", "Biceps", "Triceps"],
            "Lower Body": ["Legs"],
            "Full Body": ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Legs", "Abdominals"],
            "Core": ["Abdominals"],
            "Cardio": ["Cardio"]
        }
        
        # Load and prepare exercise database
        try:
            self.df = pd.read_csv('data/exercises.csv')
            self.exercise_categories = self._prepare_exercise_categories()
        except Exception as e:
            print(f"Error loading exercise database: {e}")
            self.df = pd.DataFrame()
            self.exercise_categories = {}

    def _prepare_exercise_categories(self) -> Dict[str, List[Dict[str, str]]]:
        """Prepare exercise database for RAG by organizing exercises by category."""
        try:
            organized_exercises = {}
            
            # Prepare traditional strength exercises by category
            for category, body_parts in self.category_mapping.items():
                if category != "Cardio":  # Skip cardio for now - we'll add it separately
                    exercises = self.df[self.df['BodyPart'].isin(body_parts)].to_dict('records')
                    organized_exercises[category] = exercises
            
            # Add cardio as a separate category using the module-level constant
            organized_exercises["Cardio"] = CARDIO_EXERCISES
                
            return organized_exercises
        except Exception as e:
            print(f"Error preparing exercise categories: {e}")
            return {}

    def _get_next_category(self, workout_days: int, goal: str, last_category: Optional[str] = None) -> str:
        """Determine the next workout category based on the goal, workout frequency, and last workout."""
        try:
            # Get the appropriate workout plan based on goal and frequency
            workout_plan = self.workout_plans.get(goal, self.workout_plans["Improve Fitness"])
            sequence = workout_plan.get(workout_days, workout_plan[3])  # Default to 3 days if not found
            
            if not last_category:
                return sequence[0]
                
            try:
                current_index = sequence.index(last_category)
                next_index = (current_index + 1) % len(sequence)
                return sequence[next_index]
            except ValueError:
                return sequence[0]
        except Exception as e:
            print(f"Error getting next category, using fallback: {e}")
            # Fallback to the old method if anything goes wrong
            sequence = self.workout_sequence.get(workout_days, self.workout_sequence[3])
            
            if not last_category:
                return sequence[0]
                
            try:
                current_index = sequence.index(last_category)
                next_index = (current_index + 1) % len(sequence)
                return sequence[next_index]
            except ValueError:
                return sequence[0]

    def _get_set_rep_guidelines(self, fitness_level: str, category: str = "") -> dict:
        """Get set and rep guidelines based on fitness level and category."""
        if category == "Cardio":
            return {
                "Beginner": {
                    "duration": "20-30 min",
                    "intensity": "Low to Moderate",
                    "intervals": "Optional"
                },
                "Intermediate": {
                    "duration": "30-45 min",
                    "intensity": "Moderate to High",
                    "intervals": "Recommended"
                },
                "Advanced": {
                    "duration": "45-60 min",
                    "intensity": "High",
                    "intervals": "Highly Recommended"
                }
            }.get(fitness_level, {"duration": "30 min", "intensity": "Moderate", "intervals": "Optional"})
        else:
            # Traditional strength training guidelines
            return {
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
                    "sets": "3-5",
                    "sets_range": "3-5",
                    "reps": "6-12",
                    "reps_range": "6-12"
                }
            }.get(fitness_level, {"sets": "3", "sets_range": "3", "reps": "10-12", "reps_range": "10-12"})

    def generate_workout_options(self, data: WorkoutRequest, num_options: int = 3) -> dict:
        """Generate multiple workout options with variations based on user goals and workout frequency."""
        try:
            # Determine next workout category based on goal and workout frequency
            next_category = self._get_next_category(
                data.workoutDays, 
                data.goal, 
                data.lastWorkoutCategory
            )
            
            print(f"Selected workout category: {next_category}")
            
            # Check if we need to generate cardio workout
            if next_category == "Cardio":
                return self._generate_cardio_options(data, next_category)
            else:
                return self._generate_strength_options(data, next_category)
                
        except Exception as e:
            print(f"Error in generate_workout_options: {str(e)}")
            return self._create_fallback_options(next_category, data)

    def _generate_cardio_options(self, data: WorkoutRequest, category: str) -> dict:
        """Generate cardio workout options with appropriate parameters."""
        try:
            # Use the module-level cardio exercises
            exercise_list = ", ".join([ex['Title'] for ex in CARDIO_EXERCISES])
            
            # Get cardio guidelines based on fitness level
            guidelines = self._get_set_rep_guidelines(data.fitnessLevel, "Cardio")
            
            # Prepare a prompt for the model that specifies cardio parameters
            prompt = f"""Create EXACTLY 3 cardio workout options for a {data.age}yo {data.gender}, {data.height}cm, {data.weight}kg, fitness level: {data.fitnessLevel}, goal: {data.goal}.

Today's focus is: Cardio workout.

VERY IMPORTANT REQUIREMENTS:
1. Each option should be a SINGLE cardio workout with detailed parameters
2. Use ONLY exercises from this list: {exercise_list}
3. Each option should be a different type of cardio exercise
4. For each exercise, provide the following details:
   - For {data.fitnessLevel} level:
   - Duration: {guidelines["duration"]}
   - Intensity: {guidelines["intensity"]}
   - Format: Whether it's steady-state cardio or interval training
   - Calories burned estimate
   - Description: Brief instructions on how to perform the workout

Return in this JSON format:
{{
"options": [
    [
    {{ 
      "workout": "Exercise Name", 
      "duration": "30 min", 
      "intensity": "Moderate", 
      "format": "Steady-state", 
      "calories": "250-300", 
      "description": "Brief description of how to perform the exercise"
    }}
    ],
    [
    {{ 
      "workout": "Different Exercise", 
      "duration": "25 min", 
      "intensity": "High", 
      "format": "Intervals (30s high / 30s low)", 
      "calories": "300-350", 
      "description": "Brief description of how to perform the exercise"
    }}
    ],
    [
    {{ 
      "workout": "Another Exercise", 
      "duration": "45 min", 
      "intensity": "Low to moderate", 
      "format": "Steady-state", 
      "calories": "350-400", 
      "description": "Brief description of how to perform the exercise"
    }}
    ]
]
}}

Return ONLY the JSON without any explanations.
"""
            
            # Use system message to enforce JSON response
            response = ollama.chat(
                model="llama3.2", 
                messages=[
                    {"role": "system", "content": "You are a fitness API that returns only clean JSON. You must ensure each workout option provides appropriate cardio parameters."},
                    {"role": "user", "content": prompt}
                ],
                options={"temperature": 0.4}  # Lower temperature for more deterministic output
            )
            
            content = response['message']['content'].strip()
            
            try:
                parsed_response = json.loads(content)
                
                # Extract options list
                workout_options = parsed_response.get("options", [])
                
                # Process each option to add image paths
                processed_options = []
                for option in workout_options:
                    processed_exercises = []
                    
                    if len(option) > 0:
                        exercise = option[0]  # Cardio options only have one "exercise" per option
                        exercise_name = exercise["workout"]
                        
                        # Find the matching cardio exercise for the image
                        matching_cardio = next((c for c in CARDIO_EXERCISES if c["Title"].lower() in exercise_name.lower()), 
                                            {"Title": exercise_name, "Image": "cardio.webp", "Icon": "cardio.webp"})
                        
                        # Create processed cardio exercise with proper format
                        processed_exercise = {
                            "workout": exercise_name,
                            "image": f"/workout-images/{matching_cardio['Image']}",
                            "duration": exercise.get("duration", guidelines["duration"]),
                            "intensity": exercise.get("intensity", guidelines["intensity"]),
                            "format": exercise.get("format", "Steady-state"),
                            "calories": exercise.get("calories", "250-350"),
                            "description": exercise.get("description", "Perform at a comfortable pace."),
                            "is_cardio": True  # Flag to indicate this is a cardio exercise for the frontend
                        }
                        processed_exercises.append(processed_exercise)
                    
                    processed_options.append(processed_exercises)
                
                # If we have all 3 valid options
                if len(processed_options) == 3:
                    return {
                        "options": processed_options,
                        "category": category
                    }
                else:
                    # If not enough valid options, create fallback options
                    return self._create_cardio_fallback_options(category, data)
                    
            except (json.JSONDecodeError, ValueError) as e:
                print(f"Error parsing cardio workout: {str(e)}")
                print(f"Content attempting to parse: {content}")
                
                # Create fallback options if JSON parsing fails
                return self._create_cardio_fallback_options(category, data)
                    
        except Exception as e:
            print(f"Error in generate_cardio_options: {str(e)}")
            return self._create_cardio_fallback_options(category, data)

    def _generate_strength_options(self, data: WorkoutRequest, category: str) -> dict:
        """Generate strength training workout options with flexibility for the Llama model."""
        try:
            # Get available exercises for this category
            available_exercises = []
            
            # Map the category to the relevant body parts
            if category in self.category_mapping:
                for body_part in self.category_mapping[category]:
                    if body_part == "Cardio":
                        continue  # Skip cardio for strength training
                    exercises = self.df[self.df['BodyPart'] == body_part].to_dict('records')
                    available_exercises.extend(exercises)
            else:
                # Fallback to the original category if not found in mapping
                category_exercises = self.exercise_categories.get(category, [])
                available_exercises = [ex for ex in category_exercises if "Title" in ex]
            
            # Create two separate lists: one for home-friendly exercises and one for all exercises
            home_friendly_exercises = []
            all_exercises = []
            
            for ex in available_exercises:
                if "Title" in ex:
                    all_exercises.append(ex)
                    
                    # Filter for bodyweight and dumbbell exercises based on title
                    title = ex["Title"].lower()
                    if any(term in title for term in ['push up', 'pull up', 'bodyweight', 'dumbbell', 'squat', 'lunge', 'plank']):
                        home_friendly_exercises.append(ex)
            
            # Create exercise lists from both categories
            exercise_list = ", ".join([ex['Title'] for ex in all_exercises])
            home_exercise_list = ", ".join([ex['Title'] for ex in home_friendly_exercises])
            
            # If we don't have enough home exercises, add some generic ones
            if len(home_friendly_exercises) < 4:
                generic_home_exercises = [
                    "Push Ups", "Pull Ups", "Bodyweight Squats", "Lunges", 
                    "Dumbbell Curls", "Dumbbell Shoulder Press", "Planks", "Burpees"
                ]
                home_exercise_list += ", " + ", ".join(generic_home_exercises)
                
            # Create a base number of exercises (can be slightly flexible)
            base_num_exercises = 4
            if category == "Full Body":
                base_num_exercises = 5  # Full body workouts need more exercises to hit all muscle groups
            
            # Prepare a prompt for the model that encourages natural exercise programming
            prompt = f"""Create EXACTLY 3 workout options for a {data.age}yo {data.gender}, {data.height}cm, {data.weight}kg, fitness level: {data.fitnessLevel}, goal: {data.goal}.

    Today's focus is: {category} workout.

    VERY IMPORTANT REQUIREMENTS:
    1. Each option should have 4-5 exercises appropriate for a {category} workout (4 is preferred, 5th is optional if needed)
    2. OPTION 1 and OPTION 3 can use any exercises from this list: {exercise_list}
    3. OPTION 2 must be a HOME-FRIENDLY workout using ONLY bodyweight and dumbbell exercises from this list: {home_exercise_list}
    4. Each option MUST DIFFER BY AT LEAST 2 EXERCISES from other options
    5. Each option should target different muscles within the {category} category. AVOID OVERWORKING MUSCLES!
    6. For each exercise, choose NATURAL and APPROPRIATE reps and sets based on:
    - The specific exercise (heavy compound lifts use fewer reps, bodyweight may use more)
    - The user's fitness level: {data.fitnessLevel}
    - The user's goal: {data.goal}
    7. For time-based exercises like planks, use time instead of reps (e.g., "30s" instead of "10 reps")
    8. BE CREATIVE with set/rep schemes based on exercise type and intensity

    Return in this JSON format:
    {{
    "options": [
        [
        {{ "workout": "Exercise Name", "sets": "3", "reps": "10-12" }},
        {{ "workout": "Exercise Name", "sets": "4", "reps": "8" }},
        {{ "workout": "Exercise Name", "sets": "3", "reps": "10" }},
        {{ "workout": "Exercise Name", "sets": "3", "reps": "12" }},
        {{ "workout": "Exercise Name", "sets": "3", "reps": "8-10" }} // 5th is optional
        ],
        [
        {{ "workout": "Home-Friendly Exercise", "sets": "3", "reps": "12" }},
        {{ "workout": "Home-Friendly Exercise", "sets": "4", "reps": "8" }},
        {{ "workout": "Plank or Similar", "sets": "3", "reps": "30s" }},
        {{ "workout": "Home-Friendly Exercise", "sets": "3", "reps": "10" }},
        {{ "workout": "Home-Friendly Exercise", "sets": "3", "reps": "15" }} // 5th is optional
        ],
        [
        {{ "workout": "Exercise Name", "sets": "3", "reps": "10-12" }},
        {{ "workout": "Exercise Name", "sets": "3", "reps": "12" }},
        {{ "workout": "Exercise Name", "sets": "4", "reps": "8" }},
        {{ "workout": "Exercise Name", "sets": "3", "reps": "10" }},
        {{ "workout": "Exercise Name", "sets": "3", "reps": "8-10" }} // 5th is optional
        ]
    ]
    }}

    REMEMBER: Option 2 must be a HOME-FRIENDLY workout using only bodyweight and dumbbell exercises.
    Be CREATIVE with set and rep schemes based on exercise type but keep them REALISTIC.
    Return ONLY the JSON without any explanations.
    """
            
            # Use system message to enforce JSON response but allow creativity
            response = ollama.chat(
                model="llama3.2", 
                messages=[
                    {"role": "system", "content": "You are a knowledgeable fitness expert who creates personalized workout plans. Create JSON with natural, exercise-appropriate set and rep schemes."},
                    {"role": "user", "content": prompt}
                ],
                options={"temperature": 0.5}  # Slightly higher temperature for more creativity
            )
            
            content = response['message']['content'].strip()
            
            try:
                parsed_response = json.loads(content)
                
                # Extract options list
                workout_options = parsed_response.get("options", [])
                
                # Verify that we have exactly 3 options
                if len(workout_options) != 3:
                    raise ValueError(f"Expected 3 workout options, got {len(workout_options)}")
                
                # Process each option to add image paths
                processed_options = []
                for i, option in enumerate(workout_options):
                    processed_exercises = []
                    
                    # Dictionary to check if this is a valid exercise
                    valid_exercise_dict = {ex['Title']: True for ex in available_exercises if "Title" in ex}
                    
                    for exercise in option:
                        exercise_name = exercise["workout"]
                        
                        # For common exercises that might not be in our dataset but are valid
                        common_exercises = ["Push Ups", "Pull Ups", "Plank", "Burpees", "Bodyweight Squats", "Lunges"]
                        
                        # Verify this is a valid exercise from our dataset or a common one
                        if exercise_name in valid_exercise_dict or any(ex.lower() in exercise_name.lower() for ex in common_exercises):
                            # Add the exercise with correct fields as provided by the model
                            processed_exercise = {
                                "workout": exercise_name,
                                "image": self.exercise_db.get_exercise_icon(exercise_name),
                                "sets": exercise.get("sets", "3"),
                                "reps": exercise.get("reps", "10"),
                                "instruction": ""
                            }
                            processed_exercises.append(processed_exercise)
                    
                    # Make sure we have at least 4 exercises but no more than 5
                    min_exercises = 4
                    max_exercises = 5
                    
                    if len(processed_exercises) < min_exercises:
                        # Fill with appropriate exercises if not enough valid exercises
                        if i == 1:  # For option 2 (home workout), add generic home exercises
                            generic_exercises = [
                                "Push Ups", "Pull Ups", "Bodyweight Squats", "Lunges", 
                                "Dumbbell Curls", "Dumbbell Shoulder Press", "Planks", "Burpees"
                            ]
                            
                            while len(processed_exercises) < min_exercises:
                                ex_name = random.choice(generic_exercises)
                                if ex_name not in [ex["workout"] for ex in processed_exercises]:
                                    processed_exercise = {
                                        "workout": ex_name,
                                        "image": self.exercise_db.get_exercise_icon(ex_name),
                                        "sets": "3",
                                        "reps": "30s" if ex_name == "Planks" else "10-12",
                                        "instruction": ""
                                    }
                                    processed_exercises.append(processed_exercise)
                        else:  # For options 1 and 3, add from available exercises
                            while len(processed_exercises) < min_exercises and available_exercises:
                                random_exercise = random.choice(available_exercises)
                                if "Title" in random_exercise:
                                    exercise_name = random_exercise['Title']
                                    if exercise_name not in [ex["workout"] for ex in processed_exercises]:
                                        processed_exercise = {
                                            "workout": exercise_name,
                                            "image": self.exercise_db.get_exercise_icon(exercise_name),
                                            "sets": "3",
                                            "reps": "10-12",
                                            "instruction": ""
                                        }
                                        processed_exercises.append(processed_exercise)
                    
                    # Trim excessive exercises to ensure we don't have more than max_exercises
                    if len(processed_exercises) > max_exercises:
                        processed_exercises = processed_exercises[:max_exercises]
                    
                    processed_options.append(processed_exercises)
                
                # If we have all 3 valid options
                if len(processed_options) == 3:
                    return {
                        "options": processed_options,
                        "category": category
                    }
                else:
                    # Create fallback options if something went wrong
                    return self._create_strength_fallback_options(available_exercises, category, data)
                    
            except (json.JSONDecodeError, ValueError) as e:
                print(f"Error: {str(e)}")
                print(f"Content attempting to parse: {content}")
                
                # Create fallback options if JSON parsing fails
                return self._create_strength_fallback_options(available_exercises, category, data)
                    
        except Exception as e:
            print(f"Error in generate_strength_options: {str(e)}")
            # Create fallback strength options
            return self._create_strength_fallback_options([], category, data)

    def _create_strength_fallback_options(self, available_exercises, category, data):
        """Create fallback workout options if the main method fails, with flexibility in mind."""
        try:
            # Create 3 distinct workout options
            print("fall back!")
            all_exercises = [ex['Title'] for ex in available_exercises if "Title" in ex]
            options = []
            
            # Create home-friendly exercise list
            home_exercises = [ex for ex in all_exercises if any(
                term in ex.lower() for term in ['push up', 'pull up', 'bodyweight', 'dumbbell', 'squat', 'lunge', 'plank']
            )]
            
            # Add generic exercises if we don't have enough
            if len(all_exercises) < 4:
                generic_exercises = [
                    "Push Ups", "Pull Ups", "Squats", "Lunges", 
                    "Bench Press", "Shoulder Press", "Leg Press", "Deadlift"
                ]
                all_exercises.extend([ex for ex in generic_exercises if ex not in all_exercises])
            
            # Add generic home exercises if needed
            if len(home_exercises) < 4:
                generic_home_exercises = [
                    "Push Ups", "Pull Ups", "Bodyweight Squats", "Lunges", 
                    "Dumbbell Curls", "Dumbbell Shoulder Press", "Planks", "Burpees"
                ]
                home_exercises.extend([ex for ex in generic_home_exercises if ex not in home_exercises])
            
            # Determine number of exercises based on category and goal
            min_exercises = 4
            max_exercises = 5
            
            if category == "Full Body":
                min_exercises = 5
                max_exercises = 6
            
            # Determine how many exercises to use for each option (with some randomness)
            # Full body always gets max, others have a chance of getting max or min
            option1_count = max_exercises if category == "Full Body" else random.randint(min_exercises, max_exercises)
            option2_count = min_exercises  # Home workout typically has fewer exercises
            option3_count = max_exercises if category == "Full Body" else random.randint(min_exercises, max_exercises)
            
            # Option 1: Regular workout
            option1 = random.sample(all_exercises, min(option1_count, len(all_exercises)))
            
            # Option 2: Home workout
            option2 = random.sample(home_exercises, min(option2_count, len(home_exercises)))
            
            # Option 3: Regular workout (different from Option 1)
            remaining_exercises = [ex for ex in all_exercises if ex not in option1]
            if len(remaining_exercises) < option3_count:
                remaining_exercises.extend([f"Generic {category} Exercise {i+1}" for i in range(option3_count - len(remaining_exercises))])
            
            option3 = random.sample(remaining_exercises, min(option3_count, len(remaining_exercises)))
            
            options = [option1, option2, option3]
            
            # Format options with creative set/rep schemes
            formatted_options = []
            
            # Based on fitness level and goal, create appropriate rep ranges
            rep_ranges = {
                "Beginner": {
                    "Weight Loss": ["12-15", "10-12", "15", "12-20", "20"],
                    "Gain Muscle": ["8-12", "10-12", "12", "10", "8"],
                    "Improve Fitness": ["10-15", "12-15", "15-20", "10-12", "12"]
                },
                "Intermediate": {
                    "Weight Loss": ["15-20", "12-15", "15", "12", "10-15"],
                    "Gain Muscle": ["6-8", "8-10", "10-12", "12", "8"],
                    "Improve Fitness": ["10-12", "12-15", "15", "10", "8-12"]
                },
                "Advanced": {
                    "Weight Loss": ["15-20", "20", "15", "12-15", "15-25"],
                    "Gain Muscle": ["4-6", "6-8", "8-10", "10-12", "12"],
                    "Improve Fitness": ["8-12", "10-15", "12", "15", "8"]
                }
            }
            
            # Get appropriate rep ranges for fitness level and goal
            goal = data.goal if data.goal in ["Weight Loss", "Gain Muscle", "Improve Fitness"] else "Improve Fitness"
            level = data.fitnessLevel if data.fitnessLevel in ["Beginner", "Intermediate", "Advanced"] else "Beginner"
            
            available_reps = rep_ranges.get(level, {}).get(goal, ["10-12", "12", "15", "8-10", "10"])
            
            # Set ranges
            set_ranges = {
                "Beginner": ["2", "3", "2-3"],
                "Intermediate": ["3", "3-4", "4"],
                "Advanced": ["3-4", "4", "4-5", "5"]
            }
            
            available_sets = set_ranges.get(level, ["3", "3-4"])
            
            for i, option in enumerate(options):
                formatted_option = []
                
                for exercise in option:
                    # Generate creative sets and reps for each exercise
                    exercise_lower = exercise.lower()
                    
                    # For timed exercises like planks
                    if any(term in exercise_lower for term in ['plank', 'hold', 'bridge']):
                        # Adjust time based on fitness level
                        times = {
                            "Beginner": ["20s", "30s", "40s"],
                            "Intermediate": ["30s", "45s", "60s"],
                            "Advanced": ["45s", "60s", "75s", "90s"]
                        }
                        reps = random.choice(times.get(level, ["30s", "45s"]))
                    else:
                        reps = random.choice(available_reps)
                    
                    # Sets are more standard
                    sets = random.choice(available_sets)
                    
                    # For compound exercises, slightly adjust the rep ranges
                    if any(term in exercise_lower for term in ['squat', 'deadlift', 'bench press', 'shoulder press']):
                        if "Weight Loss" not in goal and "Improve Fitness" not in goal:
                            # For muscle gain, use slightly lower reps for major compounds
                            reps = random.choice(["6-8", "8-10", "5-8", "8-12"])
                    
                    # For bodyweight exercises with higher reps
                    if any(term in exercise_lower for term in ['push up', 'pull up', 'bodyweight', 'burpee']):
                        if "Beginner" in level:
                            reps = random.choice(["8-12", "10-15", "12"])
                        elif "Advanced" in level and "Weight Loss" in goal:
                            reps = random.choice(["15-20", "20-25", "15-25", "20"])
                    
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
            print(f"Error creating flexible strength fallback options: {str(e)}")
            # Return minimal valid response
            return self._create_fallback_options(category, data)
            
    def _create_cardio_fallback_options(self, category, data):
        """Create fallback cardio workout options."""
        try:
            guidelines = self._get_set_rep_guidelines(data.fitnessLevel, "Cardio")
            
            # Create 3 different cardio options from our list
            cardio_options = []
            
            # If we don't have enough cardio exercises, add some generic ones
            cardio_exercises = list(CARDIO_EXERCISES)
            if len(cardio_exercises) < 3:
                cardio_exercises.extend([
                    {"Title": "Walking", "Image": "cardio.webp", "Icon": "cardio.webp"},
                    {"Title": "Jogging", "Image": "cardio.webp", "Icon": "cardio.webp"},
                    {"Title": "Cycling", "Image": "cardio.webp", "Icon": "cardio.webp"}
                ])
                
            # Select 3 random cardio exercises
            selected_cardio = random.sample(cardio_exercises, min(3, len(cardio_exercises)))
            
            # Create durations and intensities based on fitness level
            durations = {
                "Beginner": ["20 min", "25 min", "30 min"],
                "Intermediate": ["30 min", "35 min", "45 min"],
                "Advanced": ["45 min", "50 min", "60 min"]
            }
            
            intensities = {
                "Beginner": ["Low", "Low to Moderate", "Moderate"],
                "Intermediate": ["Moderate", "Moderate to High", "High"],
                "Advanced": ["Moderate to High", "High", "Very High"]
            }
            
            formats = ["Steady-state", "Intervals (30s high / 30s low)", "Intervals (1 min high / 1 min low)"]
            calories = ["200-250", "250-300", "300-350", "350-400", "400-450"]
            
            # Create formatted options
            for i, cardio in enumerate(selected_cardio):
                exercise = {
                    "workout": cardio["Title"],
                    "image": f"/workout-images/{cardio['Image']}",
                    "duration": random.choice(durations.get(data.fitnessLevel, durations["Beginner"])),
                    "intensity": random.choice(intensities.get(data.fitnessLevel, intensities["Beginner"])),
                    "format": random.choice(formats),
                    "calories": random.choice(calories),
                    "description": f"Perform {cardio['Title']} at a comfortable pace that matches the intensity level.",
                    "is_cardio": True
                }
                cardio_options.append([exercise])  # Each cardio option is a list with one exercise
                
            return {
                "options": cardio_options,
                "category": category
            }
        except Exception as e:
            print(f"Error creating cardio fallback options: {str(e)}")
            # Return minimal valid response
            return self._create_fallback_options(category, data)
    
    def _create_fallback_options(self, category, data):
        """Emergency fallback method that always works regardless of other issues."""
        # Create basic workout options
        options = []
        
        if category == "Cardio":
            cardio_types = ["Walking", "Running", "Cycling"]
            for _ in range(3):
                cardio_option = []
                cardio_type = random.choice(cardio_types)
                cardio_option.append({
                    "workout": cardio_type,
                    "image": f"/workout-images/cardio.webp",
                    "duration": "30 min",
                    "intensity": "Moderate",
                    "format": "Steady-state",
                    "calories": "300-350",
                    "description": f"Perform {cardio_type} at a comfortable pace.",
                    "is_cardio": True
                })
                options.append(cardio_option)
        else:
            # Basic strength workout
            for _ in range(3):
                strength_option = []
                for i in range(4):
                    strength_option.append({
                        "workout": f"Exercise {i+1}",
                        "image": "/workout-images/icons/default-icon.png",
                        "sets": "3",
                        "reps": "10-12",
                        "instruction": ""
                    })
                options.append(strength_option)
        
        return {
            "options": options,
            "category": category
        }