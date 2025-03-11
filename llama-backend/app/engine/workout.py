import ollama
import json
import pandas as pd
import random
import re
from typing import Optional, List, Dict, Any
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
        """Prepare exercise database for organizing exercises by category."""
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
            print(f"Error getting next category: {e}")
            # Use a safe default if anything goes wrong
            return "Full Body"

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
            # Return minimal valid structure
            return {
                "options": [[] for _ in range(num_options)],
                "category": next_category if 'next_category' in locals() else "Full Body"
            }

    def _fix_json(self, content: str) -> str:
        """Fix common JSON errors from LLama responses."""
        # Convert from markdown code block if present
        if '```' in content:
            lines = content.split('\n')
            filtered_lines = []
            in_code_block = False
            
            for line in lines:
                if line.strip().startswith('```'):
                    in_code_block = not in_code_block
                    continue
                if not in_code_block or line.strip():  # Skip empty lines outside code blocks
                    filtered_lines.append(line)
            
            content = '\n'.join(filtered_lines)

        # Fix sets and reps values that should be strings
        # Find all instances of "sets": digit and "reps": digit-digit
        content = re.sub(r'"sets"\s*:\s*(\d+)', r'"sets": "\1"', content)
        content = re.sub(r'"reps"\s*:\s*(\d+)-(\d+)', r'"reps": "\1-\2"', content)
        content = re.sub(r'"reps"\s*:\s*(\d+)', r'"reps": "\1"', content)
        
        # Fix nested braces issues
        content = re.sub(r'}\s*{', '},{', content)
        
        return content

    def _parse_safe(self, json_str: str) -> Dict[str, Any]:
        """Safely parse JSON with multiple fallback attempts."""
        try:
            # First try normal parsing
            return json.loads(json_str)
        except json.JSONDecodeError as e:
            print(f"JSON decode error: {e}")
            print(f"Attempting to fix JSON...")
            
            try:
                # Try with our fixes
                fixed_json = self._fix_json(json_str)
                return json.loads(fixed_json)
            except json.JSONDecodeError as e2:
                print(f"Second JSON decode error: {e2}")
                
                try:
                    # Try with a more aggressive approach: extract the options array
                    options_match = re.search(r'"options"\s*:\s*\[\s*\[(.*?)\]\s*\]', json_str, re.DOTALL)
                    if options_match:
                        options_content = options_match.group(1)
                        
                        # Fix possible JSON issues in the extracted content
                        options_content = options_content.replace("'", '"')
                        
                        # Build a skeleton with just the options
                        fixed_json = '{"options": [[' + options_content + ']]}'
                        return json.loads(fixed_json)
                    else:
                        # If we can't extract options, create a minimal valid structure
                        print("Could not extract options from JSON, returning empty structure")
                        return {"options": []}
                except Exception as e3:
                    print(f"Third parsing attempt failed: {e3}")
                    return {"options": []}

    def _generate_cardio_options(self, data: WorkoutRequest, category: str) -> dict:
        """Generate cardio workout options with appropriate parameters."""
        try:
            # Prepare a list of available cardio exercises
            cardio_types = ", ".join([ex["Title"] for ex in CARDIO_EXERCISES])
            
            # Create a prompt that explicitly emphasizes string formatting for all values
            prompt = f"""Create EXACTLY 3 cardio workouts for a {data.age}yo {data.gender}, {data.height}cm, {data.weight}kg, {data.fitnessLevel} level, goal: {data.goal}.

Choose 3 different exercises from: {cardio_types}

For each exercise, provide:
- Duration (like "30 min")
- Intensity (like "Moderate")
- Format (like "Steady-state" or "Intervals")
- Calories burned (like "250-300")
- Description

Return ONLY in this exact JSON format (EVERYTHING in QUOTES, including numbers):
{{
  "options": [
    [
      {{
        "workout": "Exercise Name", 
        "duration": "30 min", 
        "intensity": "Moderate", 
        "format": "Steady-state", 
        "calories": "250-300", 
        "description": "Brief description"
      }}
    ],
    [
      {{
        "workout": "Different Exercise", 
        "duration": "25 min", 
        "intensity": "High", 
        "format": "Intervals (30s/30s)", 
        "calories": "300-350", 
        "description": "Brief description"
      }}
    ],
    [
      {{
        "workout": "Another Exercise", 
        "duration": "45 min", 
        "intensity": "Low-Moderate", 
        "format": "Steady-state", 
        "calories": "350-400", 
        "description": "Brief description"
      }}
    ]
  ]
}}
IMPORTANT: EVERY value MUST be in QUOTES. No bare numbers."""
            
            print("Requesting cardio workout from LLM...")
            
            # Use ollama with very specific system instruction about JSON format
            response = ollama.chat(
                model="llama3.2",
                messages=[
                    {
                        "role": "system", 
                        "content": "You are a professoinal fitness coach that returns only valid JSON. You must put ALL values in double quotes, including numbers. Format exactly as requested. Return ONLY the JSON with no explanation or markdown."
                    },
                    {"role": "user", "content": prompt}
                ],
                options={"temperature": 0.1}  # Very low temperature for consistent formatting
            )
            
            # Extract the content
            content = response['message']['content'].strip()
            
            # Try to parse with our safe parsing method
            workout_data = self._parse_safe(content)
            options = workout_data.get("options", [])
            
            if not options:
                print("No valid workout options received from LLM, generating backup options")
                return self._create_default_cardio_options(category)
            
            # Process the options to add images and ensure proper formatting
            processed_options = []
            used_cardio_types = set()
            
            for option in options:
                if not option:  # Skip empty options
                    continue
                    
                # Each cardio option has one exercise
                cardio_exercise = option[0]
                if "workout" not in cardio_exercise:
                    continue
                    
                workout_name = cardio_exercise["workout"]
                workout_lower = workout_name.lower()
                
                # Skip duplicates
                if any(workout_lower in used or used in workout_lower for used in used_cardio_types):
                    continue
                
                # Record this exercise type
                used_cardio_types.add(workout_lower)
                
                # Find matching cardio image
                matching_cardio = next(
                    (c for c in CARDIO_EXERCISES if c["Title"].lower() in workout_lower), 
                    {"Title": workout_name, "Image": "cardio.webp"}
                )
                
                # Create properly formatted exercise
                formatted_exercise = {
                    "workout": workout_name,
                    "image": f"/workout-images/cardio/{matching_cardio['Image']}",
                    "duration": cardio_exercise.get("duration", "30 min"),
                    "intensity": cardio_exercise.get("intensity", "Moderate"),
                    "format": cardio_exercise.get("format", "Steady-state"),
                    "calories": cardio_exercise.get("calories", "250-300"),
                    "description": cardio_exercise.get("description", f"Perform {workout_name} at a comfortable pace."),
                    "is_cardio": True
                }
                
                processed_options.append([formatted_exercise])
            
            # If we don't have enough options, fill in with defaults
            if len(processed_options) < 3:
                # Find unused cardio exercises
                available_cardio = [c for c in CARDIO_EXERCISES 
                                   if not any(c["Title"].lower() in used for used in used_cardio_types)]
                
                # If we've used all exercises, reset the list
                if not available_cardio:
                    available_cardio = CARDIO_EXERCISES
                
                # Add more options until we have 3
                while len(processed_options) < 3 and available_cardio:
                    cardio = random.choice(available_cardio)
                    available_cardio.remove(cardio)
                    
                    # Create a default option for this cardio type
                    default_option = [{
                        "workout": cardio["Title"],
                        "image": f"/workout-images/{cardio['Image']}",
                        "duration": "30 min",
                        "intensity": "Moderate",
                        "format": "Steady-state",
                        "calories": "250-300",
                        "description": f"Perform {cardio['Title']} at a comfortable pace.",
                        "is_cardio": True
                    }]
                    
                    processed_options.append(default_option)
            
            return {
                "options": processed_options,
                "category": category
            }
            
        except Exception as e:
            print(f"Error in generate_cardio_options: {str(e)}")
            return self._create_default_cardio_options(category)
            
    def _create_default_cardio_options(self, category: str) -> dict:
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        """Create default cardio options when LLM fails."""
        options = []
        used_indices = set()
        
        # Create 3 different cardio options
        for _ in range(3):
            # Find an unused cardio exercise
            available_indices = [i for i in range(len(CARDIO_EXERCISES)) if i not in used_indices]
            if not available_indices:  # If all are used, reset
                used_indices = set()
                available_indices = list(range(len(CARDIO_EXERCISES)))
                
            index = random.choice(available_indices)
            used_indices.add(index)
            cardio = CARDIO_EXERCISES[index]
            
            # Create a default option
            option = [{
                "workout": cardio["Title"],
                "image": f"/workout-images/{cardio['Image']}",
                "duration": "30 min",
                "intensity": "Moderate",
                "format": "Steady-state",
                "calories": "250-300",
                "description": f"Perform {cardio['Title']} at a comfortable pace.",
                "is_cardio": True
            }]
            
            options.append(option)
            
        return {
            "options": options,
            "category": category
        }

    def _generate_strength_options(self, data: WorkoutRequest, category: str) -> dict:
        """Generate strength training workout options."""
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
            
            # Create exercise lists from both categories (limit to avoid token limits)
            exercise_list = ", ".join([ex['Title'] for ex in all_exercises[:30]])
            home_exercise_list = ", ".join([ex['Title'] for ex in home_friendly_exercises[:20]])
            
            # If we don't have enough home exercises, add some generic ones
            if len(home_friendly_exercises) < 8:
                generic_home_exercises = [
                    "Push Ups", "Pull Ups", "Bodyweight Squats", "Lunges", 
                    "Dumbbell Curls", "Dumbbell Shoulder Press", "Planks", "Burpees"
                ]
                home_exercise_list += ", " + ", ".join(generic_home_exercises)
            
            # Create a prompt that explicitly emphasizes string formatting for all values
            prompt = f"""Create EXACTLY 3 {category} workout options for a {data.age}yo {data.gender}, {data.height}cm, {data.weight}kg, {data.fitnessLevel} level, goal: {data.goal}.

INSTRUCTIONS:
1. OPTION 1 and OPTION 3: Use any exercises from this list: {exercise_list}
2. OPTION 2: Must be HOME-FRIENDLY using only: {home_exercise_list}
3. Each option should have 4 different exercises
4. Target different muscles within {category}
5. Include sets and reps appropriate for {data.fitnessLevel} level

Return ONLY in this exact JSON format (EVERYTHING in QUOTES, including numbers):
{{
  "options": [
    [
      {{ "workout": "Exercise 1", "sets": "3", "reps": "10-12" }},
      {{ "workout": "Exercise 2", "sets": "4", "reps": "8" }},
      {{ "workout": "Exercise 3", "sets": "3", "reps": "10" }},
      {{ "workout": "Exercise 4", "sets": "3", "reps": "12" }}
    ],
    [
      {{ "workout": "Home Exercise 1", "sets": "3", "reps": "12" }},
      {{ "workout": "Home Exercise 2", "sets": "4", "reps": "8" }},
      {{ "workout": "Home Exercise 3", "sets": "3", "reps": "30s" }},
      {{ "workout": "Home Exercise 4", "sets": "3", "reps": "10" }}
    ],
    [
      {{ "workout": "Exercise 5", "sets": "3", "reps": "10-12" }},
      {{ "workout": "Exercise 6", "sets": "3", "reps": "12" }},
      {{ "workout": "Exercise 7", "sets": "4", "reps": "8" }},
      {{ "workout": "Exercise 8", "sets": "3", "reps": "10" }}
    ]
  ]
}}
IMPORTANT: PUT ALL VALUES IN QUOTES, INCLUDING NUMBERS. Format exactly as shown."""
            
            print("Requesting strength workout from LLM...")
            
            # Use ollama with very specific system instruction about JSON format
            response = ollama.chat(
                model="llama3.2",
                messages=[
                    {
                        "role": "system", 
                        "content": "You are a fitness API that returns only valid JSON. You must put ALL values in double quotes, including numbers. Format exactly as requested. Return ONLY the JSON with no explanation or markdown."
                    },
                    {"role": "user", "content": prompt}
                ],
                options={"temperature": 0.1}  # Very low temperature for consistent formatting
            )
            
            # Extract the content
            content = response['message']['content'].strip()
            
            # Try to parse with our safe parsing method
            workout_data = self._parse_safe(content)
            options = workout_data.get("options", [])
            
            if not options:
                print("No valid workout options received from LLM, generating backup options")
                return self._create_default_strength_options(category, home_friendly_exercises, all_exercises)
            
            # Process the options to add images and ensure proper formatting
            processed_options = []
            
            for option_index, option in enumerate(options):
                if not option:  # Skip empty options
                    continue
                
                processed_exercises = []
                exercise_names = set()  # Track exercise names to avoid duplicates
                
                for exercise in option:
                    if "workout" not in exercise:
                        continue
                        
                    # Skip duplicates within this option
                    exercise_name = exercise["workout"]
                    if exercise_name.lower() in exercise_names:
                        continue
                    
                    # Track this exercise name
                    exercise_names.add(exercise_name.lower())
                    
                    # Ensure sets and reps are strings
                    sets = str(exercise.get("sets", "3"))
                    reps = str(exercise.get("reps", "10-12"))
                    
                    # Add the exercise
                    processed_exercise = {
                        "workout": exercise_name,
                        "image": self.exercise_db.get_exercise_icon(exercise_name),
                        "sets": sets,
                        "reps": reps,
                        "instruction": exercise.get("instruction", "")
                    }
                    processed_exercises.append(processed_exercise)
                
                processed_options.append(processed_exercises)
            
            # Ensure we have enough exercises in each option
            for i, option in enumerate(processed_options):
                if len(option) < 4:
                    print(f"Option {i+1} needs more exercises (has {len(option)})")
                    
                    # Select appropriate exercise pool
                    exercise_pool = home_friendly_exercises if i == 1 else all_exercises
                    
                    # Get current exercise names
                    current_names = [ex["workout"].lower() for ex in option]
                    
                    # Filter out exercises we already have
                    available_pool = [ex for ex in exercise_pool if ex["Title"].lower() not in current_names]
                    
                    # Calculate how many more we need
                    missing_count = 4 - len(option)
                    
                    if available_pool and missing_count > 0:
                        # Add random exercises from the available pool
                        random_exercises = random.sample(available_pool, min(missing_count, len(available_pool)))
                        
                        for ex in random_exercises:
                            option.append({
                                "workout": ex["Title"],
                                "image": self.exercise_db.get_exercise_icon(ex["Title"]),
                                "sets": "3",
                                "reps": "10-12",
                                "instruction": ""
                            })
            
            # Make sure we have 3 options
            while len(processed_options) < 3:
                option_index = len(processed_options)
                print(f"Creating new option {option_index+1}")
                
                # Select appropriate exercise pool
                exercise_pool = home_friendly_exercises if option_index == 1 else all_exercises
                
                new_option = []
                if exercise_pool and len(exercise_pool) >= 4:
                    # Get 4 random exercises for this option
                    random_exercises = random.sample(exercise_pool, min(4, len(exercise_pool)))
                    
                    for ex in random_exercises:
                        new_option.append({
                            "workout": ex["Title"],
                            "image": self.exercise_db.get_exercise_icon(ex["Title"]),
                            "sets": "3",
                            "reps": "10-12",
                            "instruction": ""
                        })
                
                processed_options.append(new_option)
            
            return {
                "options": processed_options,
                "category": category
            }
            
        except Exception as e:
            print(f"Error in generate_strength_options: {str(e)}")
            return self._create_default_strength_options(category, home_friendly_exercises, all_exercises)

    def _create_default_strength_options(self, category: str, home_exercises: List[Dict], all_exercises: List[Dict]) -> dict:
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        """Create default strength options when LLM fails."""
        options = []
        
        # Create 3 different strength options
        for i in range(3):
            option = []
            
            # Select the appropriate pool based on option index
            exercise_pool = home_exercises if i == 1 else all_exercises
            
            if exercise_pool and len(exercise_pool) >= 4:
                # Get 4 random exercises for this option
                random_exercises = random.sample(exercise_pool, min(4, len(exercise_pool)))
                
                for ex in random_exercises:
                    option.append({
                        "workout": ex["Title"],
                        "image": self.exercise_db.get_exercise_icon(ex["Title"]),
                        "sets": "3",
                        "reps": "10-12",
                        "instruction": ""
                    })
            else:
                # Use generic exercises based on category
                generic_exercises = []
                if category == "Upper Body":
                    generic_exercises = ["Push Ups", "Pull Ups", "Dumbbell Shoulder Press", "Dumbbell Curls"]
                elif category == "Lower Body":
                    generic_exercises = ["Bodyweight Squats", "Lunges", "Calf Raises", "Glute Bridges"]
                elif category == "Push":
                    generic_exercises = ["Push Ups", "Bench Press", "Dumbbell Shoulder Press", "Tricep Dips"]
                elif category == "Pull":
                    generic_exercises = ["Pull Ups", "Dumbbell Rows", "Lat Pulldowns", "Dumbbell Curls"]
                elif category == "Legs":
                    generic_exercises = ["Bodyweight Squats", "Lunges", "Leg Press", "Leg Curls"]
                else:  # Full Body
                    generic_exercises = ["Push Ups", "Pull Ups", "Bodyweight Squats", "Planks"]
                
                for ex_name in generic_exercises:
                    option.append({
                        "workout": ex_name,
                        "image": self.exercise_db.get_exercise_icon(ex_name),
                        "sets": "3",
                        "reps": "10-12",
                        "instruction": ""
                    })
            
            options.append(option)
            
        return {
            "options": options,
            "category": category
        }