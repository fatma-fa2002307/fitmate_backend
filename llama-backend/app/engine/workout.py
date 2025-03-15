import ollama
import json
import pandas as pd
import random
import re
import logging
from typing import Optional, List, Dict, Any
from app.models.schemas import WorkoutRequest, WorkoutResponse, Exercise
from app.utils.exercise_db import ExerciseDatabase


# Configure logging
logging.basicConfig(level=logging.INFO, 
                   format='%(asctime)s [%(levelname)s] - %(message)s',
                   datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger("workout_engine")

CARDIO_EXERCISES = [
    {"Title": "Treadmill Running", "Image": "treadmill.webp", "Icon": "cardio.webp"},
    {"Title": "Outdoor Running", "Image": "running.webp", "Icon": "cardio.webp"},
    {"Title": "Walking", "Image": "walking.webp", "Icon": "cardio.webp"},
    {"Title": "Cycling", "Image": "bicycle.webp", "Icon": "cardio.webp"},
    {"Title": "Exercise Bike", "Image": "exercise-bike.webp", "Icon": "cardio.webp"},
    {"Title": "Jump Rope", "Image": "jumping-rope.webp", "Icon": "cardio.webp"},
    {"Title": "Swimming", "Image": "swimming.webp", "Icon": "cardio.webp"},
    {"Title": "Hiking", "Image": "hiking.webp", "Icon": "cardio.webp"},
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
            logger.info("Exercise database loaded successfully")
        except Exception as e:
            logger.error(f"Error loading exercise database: {e}")
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
            
            logger.info(f"Prepared {len(organized_exercises)} exercise categories")
            return organized_exercises
        except Exception as e:
            logger.error(f"Error preparing exercise categories: {e}")
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
                logger.info(f"Next workout category: {sequence[next_index]} (after {last_category})")
                return sequence[next_index]
            except ValueError:
                logger.info(f"Last category {last_category} not found in sequence, defaulting to first: {sequence[0]}")
                return sequence[0]
        except Exception as e:
            logger.error(f"Error getting next category: {e}")
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
            
            logger.info(f"Selected workout category: {next_category} for user with goal: {data.goal}")
            
            # Check if we need to generate cardio workout
            if next_category == "Cardio":
                return self._generate_cardio_options(data, next_category)
            else:
                return self._generate_strength_options(data, next_category)
                
        except Exception as e:
            logger.error(f"Error in generate_workout_options: {str(e)}", exc_info=True)
            # Return minimal valid structure
            return {
                "options": [[] for _ in range(num_options)],
                "category": next_category if 'next_category' in locals() else "Full Body"
            }

    def _fix_json(self, content: str) -> str:
        """Fix common JSON errors from LLama responses."""
        logger.info("Fixing JSON formatting issues in LLM response")
        
        # Print first and last 100 chars of content for debugging
        logger.info(f"JSON content before fixing (truncated): {content[:100]}...{content[-100:] if len(content) > 100 else content}")
        
        # Convert from markdown code block if present
        if '```' in content:
            logger.info("Removing markdown code blocks")
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

        # Fix the problematic double-quote pattern in reps field that appears in logs
        # Pattern like: "reps": "" "10-12"" or "reps": "" "10""
        content = re.sub(r'"reps"\s*:\s*""\s*"([^"]+)""', r'"reps": "\1"', content)
        
        # Fix missing closing brace after reps field
        content = re.sub(r'"reps"\s*:\s*"([^"]+)"\s*\n\s*\]', r'"reps": "\1" }\n    ]', content)
        
        # Fix sets and reps values that should be strings
        # Find all instances of "sets": digit and "reps": digit-digit
        content = re.sub(r'"sets"\s*:\s*(\d+)', r'"sets": "\1"', content)
        content = re.sub(r'"reps"\s*:\s*(\d+)-(\d+)', r'"reps": "\1-\2"', content)
        content = re.sub(r'"reps"\s*:\s*(\d+)', r'"reps": "\1"', content)
        content = re.sub(r'"reps"\s*:\s*(\d+)s', r'"reps": "\1s"', content)  # For "30s" format
        
        # Also handle other formats like "30 seconds"
        content = re.sub(r'"reps"\s*:\s*"?(\d+)\s*seconds"?', r'"reps": "\1s"', content)
        
        # Fix nested braces issues
        content = re.sub(r'}\s*{', '},{', content)
        
        # Make sure there's a proper closing } before the closing ] in all arrays
        content = re.sub(r'(\s*"[^"]*"\s*:\s*"[^"]*")\s*\n\s*\]', r'\1 }\n    ]', content)
        
        # Check for missing commas between objects in arrays
        content = re.sub(r'}\s*{', '}, {', content)
        
        # Try to balance closing braces throughout the JSON
        open_braces = content.count('{')
        close_braces = content.count('}')
        if open_braces > close_braces:
            # Add missing closing braces at the end, using Python's string multiplication
            content = content.rstrip() + ('}' * (open_braces - close_braces))
            logger.info(f"Added {open_braces - close_braces} closing braces to balance JSON")
        
        # Print first and last 100 chars of content after fixing
        logger.info(f"JSON content after fixing (truncated): {content[:100]}...{content[-100:] if len(content) > 100 else content}")
        
        return content

    def _parse_safe(self, json_str: str) -> Dict[str, Any]:
        """Safely parse JSON with multiple fallback attempts."""
        try:
            # First try normal parsing
            return json.loads(json_str)
        except json.JSONDecodeError as e:
            logger.error(f"JSON decode error: {e}")
            logger.info("Attempting to fix JSON formatting issues")
            
            try:
                # Try with our fixes
                fixed_json = self._fix_json(json_str)
                return json.loads(fixed_json)
            except json.JSONDecodeError as e2:
                logger.error(f"Second JSON decode error after fixing: {e2}")
                
                try:
                    # Try with a more aggressive approach: extract the options array
                    logger.info("Attempting more aggressive JSON extraction")
                    options_match = re.search(r'"options"\s*:\s*\[\s*\[(.*?)\]\s*\]', json_str, re.DOTALL)
                    if options_match:
                        options_content = options_match.group(1)
                        
                        # Fix possible JSON issues in the extracted content
                        options_content = options_content.replace("'", '"')
                        
                        # Build a skeleton with just the options
                        fixed_json = '{"options": [[' + options_content + ']]}'
                        logger.info(f"Extracted options JSON: {fixed_json[:100]}...")
                        return json.loads(fixed_json)
                    else:
                        # If we can't extract options, create a minimal valid structure
                        logger.error("Could not extract options from JSON, returning empty structure")
                        return {"options": []}
                except Exception as e3:
                    logger.error(f"Third parsing attempt failed: {e3}")
                    return {"options": []}

    def _generate_cardio_options(self, data: WorkoutRequest, category: str) -> dict:
        """Generate cardio workout options with appropriate parameters, allowing for maximum creativity."""
        try:
            cardio_examples = ", ".join([ex["Title"] for ex in CARDIO_EXERCISES])
            #create prompt 
            prompt = f"""You are a professional fitness coach. Create EXACTLY 3 different creative cardio workout options for a {data.age}yo {data.gender}, {data.height}cm, {data.weight}kg, {data.fitnessLevel} level, goal: {data.goal}.

    INSTRUCTIONS:
    1. You can create ANY cardio exercise - not limited to this list: {cardio_examples}
    2. Option 1 must use no equipment, Option 2 can use basic equipment, and Option 3 can be anything innovative or challenging.
    3. Each option should have one cardio exercise with detailed parameters.
    4. Tailor the intensity, duration, and format to match the user's fitness level and goals.
    5. choose realistic cardio exercises that can be sustained for longer durations like running, bicycle rides, or swimming, jumping rope.

    For each cardio workout, provide:
    - Exercise name (be specific and creative)
    - Duration (like "30 min")
    - Intensity (like "Moderate" or "High-intensity" two words max.)
    - Format (like "30 sec work/30 sec rest" or "Steady-state")
    - Calories burned estimate (like "250-300")
    - A brief description of how to perform the workout

    Return ONLY in this exact JSON format (EVERYTHING in QUOTES, including numbers). Don't add any more information or markdown:
    {{
    "options": [
        [
        {{
            "workout": "Cardio Exercise 1", 
            "duration": "30 min", 
            "intensity": "Moderate", 
            "format": "Steady-state", 
            "calories": "250-300", 
            "description": "Brief description with specific instructions"
        }}
        ],
        [
        {{
            "workout": "Cardio Exercise 2", 
            "duration": "25 min", 
            "intensity": "High", 
            "format": "Intervals (30s/30s)", 
            "calories": "300-350", 
            "description": "Brief description with specific instructions"
        }}
        ],
        [
        {{
            "workout": "Cardio Exercise 3", 
            "duration": "45 min", 
            "intensity": "Low-Moderate", 
            "format": "Steady-state", 
            "calories": "350-400", 
            "description": "Brief description with specific instructions"
        }}
        ]
    ]
    }}
    IMPORTANT: EVERY value MUST be in QUOTES. No bare numbers."""
            
            logger.info("Requesting creative cardio workout from LLM...")
            
            # Use ollama with very specific system instruction about JSON format
            response = ollama.chat(
                model="llama3.2",
                messages=[
                    {
                        "role": "system", 
                        "content": "You are a professional fitness coach that returns only valid JSON. You must put ALL values in double quotes, including numbers. Format exactly as requested. Return ONLY the JSON with no explanation or markdown. Be creative and suggest ANY cardio workout that would benefit the user, without restricting yourself to common options."
                    },
                    {"role": "user", "content": prompt}
                ],
                options={"temperature": 0.5}  #higher temp, more creativity
            )
            
            # Extract the content
            content = response['message']['content'].strip()
            
            # Log first 200 characters of response for debugging
            logger.info(f"LLM response (truncated): {content[:200]}...")
            
            # Try to parse with our safe parsing method
            workout_data = self._parse_safe(content)
            options = workout_data.get("options", [])
            
            if not options:
                logger.error("No valid workout options received from LLM, generating backup options")
                return self._create_default_cardio_options(category)
            
            # Process the options to add images and ensure proper formatting
            processed_options = []
            used_cardio_names = set()
            
            for option_index, option in enumerate(options):
                if not option:  # Skip empty options
                    logger.warning(f"Empty option found at index {option_index}")
                    continue
                    
                # Each cardio option has one exercise
                cardio_exercise = option[0]
                if "workout" not in cardio_exercise:
                    logger.warning(f"No 'workout' field in option {option_index}")
                    continue
                    
                workout_name = cardio_exercise["workout"]
                workout_lower = workout_name.lower()
                
                # Skip duplicates
                if any(workout_lower in used or used in workout_lower for used in used_cardio_names):
                    logger.info(f"Skipping duplicate cardio workout: {workout_name}")
                    continue
                
                # Record this exercise type
                used_cardio_names.add(workout_lower)
                
                # Find appropriate image based on workout type categories
                # Water-based exercises
                if any(term in workout_lower for term in ['swim', 'water', 'pool', 'aqua']):
                    image_path = "/workout-images/cardio/swimming.webp"
                    logger.info(f"Using swimming image for water-based workout: {workout_name}")

                # Running/jogging exercises
                elif any(term in workout_lower for term in ['run', 'jog', 'sprint', 'dash', 'marathon']):
                    # Use treadmill image if it mentions treadmill or indoor
                    if any(term in workout_lower for term in ['treadmill', 'indoor', 'machine']):
                        image_path = "/workout-images/cardio/treadmill.webp"
                        logger.info(f"Using treadmill image for indoor running workout: {workout_name}")
                    else:
                        image_path = "/workout-images/cardio/running.webp"
                        logger.info(f"Using outdoor running image for running workout: {workout_name}")

                # Walking exercises
                elif any(term in workout_lower for term in ['walk', 'hike', 'trek', 'stroll']):
                    if 'hike' in workout_lower or 'trek' in workout_lower or 'trail' in workout_lower:
                        image_path = "/workout-images/cardio/hiking.webp"
                        logger.info(f"Using hiking image for trail workout: {workout_name}")
                    else:
                        image_path = "/workout-images/cardio/walking.webp"
                        logger.info(f"Using walking image for walking workout: {workout_name}")

                # Cycling exercises
                elif any(term in workout_lower for term in ['cycl', 'bike', 'bik', 'bicycle', 'spinning']):
                    if any(term in workout_lower for term in ['stationary', 'spinning', 'indoor', 'exercise']):
                        image_path = "/workout-images/cardio/exercise-bike.webp"
                        logger.info(f"Using exercise bike image for indoor cycling: {workout_name}")
                    else:
                        image_path = "/workout-images/cardio/bicycle.webp"
                        logger.info(f"Using bicycle image for outdoor cycling: {workout_name}")

                # Jumping exercises
                elif any(term in workout_lower for term in ['jump', 'leap', 'hop', 'skip', 'rope']):
                    image_path = "/workout-images/cardio/jumping-rope.webp"
                    logger.info(f"Using jumping rope image for jumping workout: {workout_name}")

                # Default fallback - try exact matches or use generic image
                else:
                    # Check for any exact matches with known images
                    matched = False
                    for cardio in CARDIO_EXERCISES:
                        cardio_title_lower = cardio["Title"].lower()
                        if cardio_title_lower in workout_lower or workout_lower in cardio_title_lower:
                            image_path = f"/workout-images/cardio/{cardio['Image']}"
                            logger.info(f"Found exact match for '{cardio['Title']}': {workout_name}")
                            matched = True
                            break
                    
                    # If no match found, use generic cardio image
                    if not matched:
                        image_path = "/workout-images/cardio/cardio.webp"
                        logger.info(f"No specific image match for '{workout_name}', using generic cardio image")
                
                # Create properly formatted exercise with the correct image path
                formatted_exercise = {
                    "workout": workout_name,
                    "image": image_path,  # This is the properly formatted path
                    "duration": cardio_exercise.get("duration", "30 min"),
                    "intensity": cardio_exercise.get("intensity", "Moderate"),
                    "format": cardio_exercise.get("format", "Steady-state"),
                    "calories": cardio_exercise.get("calories", "250-300"),
                    "description": cardio_exercise.get("description", f"Perform {workout_name} at a comfortable pace."),
                    "is_cardio": True
                }
                
                processed_options.append([formatted_exercise])
                logger.info(f"Processed cardio workout: {workout_name} with image: {image_path}")
            
            # If we don't have enough options, fill in with defaults
            if len(processed_options) < 3:
                logger.warning(f"Only {len(processed_options)} valid cardio options generated, filling with defaults")
                
                # Generate defaults that won't overlap with what we already have
                defaults_to_add = 3 - len(processed_options)
                default_cardio_types = [
                    {
                        "workout": "Outdoor Running", 
                        "image": "/workout-images/cardio/running.webp",
                        "duration": "30 min", 
                        "intensity": "Moderate", 
                        "format": "Steady-state", 
                        "calories": "300-350",
                        "description": "Run at a comfortable pace outdoors, focusing on maintaining consistent effort.",
                        "is_cardio": True
                    },
                    {
                        "workout": "Jump Rope Intervals", 
                        "image": "/workout-images/cardio/jumping-rope.webp",
                        "duration": "20 min", 
                        "intensity": "High", 
                        "format": "40 sec work/20 sec rest", 
                        "calories": "250-300",
                        "description": "Jump rope with high intensity for 40 seconds, followed by 20 seconds of rest. Repeat for 20 minutes.",
                        "is_cardio": True
                    },
                    {
                        "workout": "Indoor Cycling", 
                        "image": "/workout-images/cardio/exercise-bike.webp",
                        "duration": "45 min", 
                        "intensity": "Moderate", 
                        "format": "Pyramid intervals", 
                        "calories": "400-450",
                        "description": "Start with 5 minute warm-up, then alternate between 1, 2, 3, 4, 3, 2, 1 minute intervals of high intensity with equal rest periods.",
                        "is_cardio": True
                    }
                ]
                
                # Add default options that don't overlap with existing ones
                used_defaults = []
                for default_workout in default_cardio_types:
                    default_name = default_workout["workout"].lower()
                    if not any(default_name in used or used in default_name for used in used_cardio_names):
                        processed_options.append([default_workout])
                        used_cardio_names.add(default_name)
                        used_defaults.append(default_workout["workout"])
                        
                        if len(processed_options) >= 3:
                            break
                
                logger.info(f"Added default cardio workouts: {', '.join(used_defaults)}")
            
            logger.info(f"Successfully generated {len(processed_options)} cardio workout options")
            return {
                "options": processed_options,
                "category": category
            }
            
        except Exception as e:
            logger.error(f"Error in generate_cardio_options: {str(e)}", exc_info=True)
            return self._create_default_cardio_options(category)
            
    def _create_default_cardio_options(self, category: str) -> dict:
        """Create default cardio options when LLM fails."""
        logger.warning("Creating default cardio options due to LLM failure")
        options = []
        used_indices = set()
        
        # Create 3 different cardio options
        for i in range(3):
            # Find an unused cardio exercise
            available_indices = [i for i in range(len(CARDIO_EXERCISES)) if i not in used_indices]
            if not available_indices:  # If all are used, reset
                used_indices = set()
                available_indices = list(range(len(CARDIO_EXERCISES)))
                
            index = random.choice(available_indices)
            used_indices.add(index)
            cardio = CARDIO_EXERCISES[index]
            
            # FIXED: Use proper path format for images
            image_path = f"/workout-images/cardio/{cardio['Image']}"
            
            # Create a default option with correct image path
            option = [{
                "workout": cardio["Title"],
                "image": image_path,  # Correctly formatted path
                "duration": "30 min",
                "intensity": "Moderate",
                "format": "Steady-state",
                "calories": "250-300",
                "description": f"Perform {cardio['Title']} at a comfortable pace.",
                "is_cardio": True
            }]
            
            options.append(option)
            logger.info(f"Created default cardio option {i+1}: {cardio['Title']} with image: {image_path}")
            
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
            
            # Create list of all exercises
            all_exercises = []
            
            for ex in available_exercises:
                if "Title" in ex:
                    all_exercises.append(ex)
                    
            # Create exercise list from both categories (limit to avoid token limits)
            exercise_list = ", ".join([ex['Title'] for ex in all_exercises[:40]])
            
            # Create a prompt that explicitly emphasizes string formatting for all values
            prompt = f"""Create EXACTLY 3 different {category} workout options for a {data.age}yo {data.gender}, {data.height}cm, {data.weight}kg, {data.fitnessLevel} level, goal: {data.goal}.

INSTRUCTIONS:
1. OPTION 1: Create a challenging workout with EXACTLY 4 different exercises from this list: {exercise_list}
   - This should be the most intense option
   - Use EXACTLY the same name as the exercises from the list. no extra words or letters

2. OPTION 2: Create a moderate workout with EXACTLY 5 different exercises from this list: {exercise_list}
   - This should be slightly less intense than Option 1
   - Include more exercises but with lower intensity

3. OPTION 3: Create a HOME-FRIENDLY workout with EXACTLY 4 different exercises from this list: {exercise_list}
   - Select ONLY bodyweight exercises or exercises that can be done with dumbbells
   - No gym machines or specialized equipment should be included

For each exercise, be creative with sets and reps:
- You can use any format: single numbers (e.g. "10"), ranges (e.g. "8-12"), or time-based (e.g. "30s")
- Adjust sets and reps based on exercise difficulty and {data.fitnessLevel} level
- Target different muscles within {category} for a balanced workout

Return ONLY in this exact JSON format:
{{
  "options": [
    [
      {{ "workout": "Exercise 1", "sets": "3", "reps": "10-12" }},
      {{ "workout": "Exercise 2", "sets": "4", "reps": "8" }},
      {{ "workout": "Exercise 3", "sets": "3", "reps": "10" }},
      {{ "workout": "Exercise 4", "sets": "3", "reps": "12" }}
    ],
    [
      {{ "workout": "Exercise 1", "sets": "3", "reps": "12" }},
      {{ "workout": "Exercise 2", "sets": "3", "reps": "10" }},
      {{ "workout": "Exercise 3", "sets": "3", "reps": "15" }},
      {{ "workout": "Exercise 4", "sets": "2", "reps": "30s" }},
      {{ "workout": "Exercise 5", "sets": "3", "reps": "10" }}
    ],
    [
      {{ "workout": "Exercise 1", "sets": "3", "reps": "10-12" }}, // Home-friendly
      {{ "workout": "Exercise 2", "sets": "4", "reps": "8" }},// Home-friendly
      {{ "workout": "Exercise 3", "sets": "3", "reps": "12" }},// Home-friendly
      {{ "workout": "Exercise 4", "sets": "3", "reps": "15" }}// Home-friendly
    ]
  ]
}}
IMPORTANT: Make sure to put ALL values in quotes and format exactly as shown above."""
            
            logger.info("Requesting strength workout from LLM...")
            
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
                options={"temperature": 0.5}  # Very low temperature for consistent formatting
            )
            
            # Extract the content
            content = response['message']['content'].strip()
            
            # Log first 200 characters of response for debugging
            logger.info(f"LLM response (truncated): {content[:200]}...")
            
            # Try to parse with our safe parsing method
            workout_data = self._parse_safe(content)
            options = workout_data.get("options", [])
            
            if not options:
                logger.error("No valid workout options received from LLM, generating backup options")
                return self._create_default_strength_options(category, all_exercises)
            
            # Verify exercise counts in options
            if len(options) != 3:
                logger.warning(f"Expected 3 options, but received {len(options)}")
            
            # Process the options to add images and ensure proper formatting
            processed_options = []
            
            for option_index, option in enumerate(options):
                if not option:  # Skip empty options
                    logger.warning(f"Empty option found at index {option_index}")
                    continue
                
                processed_exercises = []
                exercise_names = set()  # Track exercise names to avoid duplicates
                expected_count = 5 if option_index == 1 else 4  # Option 2 should have 5 exercises
                
                logger.info(f"Processing option {option_index+1} with {len(option)} exercises (expected {expected_count})")
                
                for exercise in option:
                    if "workout" not in exercise:
                        logger.warning(f"Missing 'workout' field in exercise: {exercise}")
                        continue
                        
                    # Skip duplicates within this option
                    exercise_name = exercise["workout"]
                    if exercise_name.lower() in exercise_names:
                        logger.info(f"Skipping duplicate exercise: {exercise_name}")
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
            
            # Ensure we have the right number of exercises in each option
            for i, option in enumerate(processed_options):
                expected_count = 5 if i == 1 else 4  # Option 2 should have 5 exercises
                
                if len(option) != expected_count:
                    logger.warning(f"Option {i+1} has {len(option)} exercises but should have {expected_count}")
                    
                    # Select appropriate exercise pool
                    # For option 3 (index 2), filter for home-friendly exercises
                    if i == 2:  # Home-friendly option
                        # Filter for exercises that can be done at home
                        available_pool = [ex for ex in all_exercises 
                                         if any(term in ex["Title"].lower() 
                                               for term in ['push up', 'pull up', 'bodyweight', 
                                                           'dumbbell', 'squat', 'lunge', 'plank'])]
                        if not available_pool:  # Fallback if no home exercises found
                            available_pool = all_exercises
                    else:
                        available_pool = all_exercises
                    
                    # Get current exercise names
                    current_names = [ex["workout"].lower() for ex in option]
                    
                    # Filter out exercises we already have
                    available_pool = [ex for ex in available_pool 
                                     if ex["Title"].lower() not in current_names]
                    
                    # Calculate how many more/fewer we need
                    if len(option) < expected_count:  # Need to add exercises
                        missing_count = expected_count - len(option)
                        logger.info(f"Adding {missing_count} exercises to option {i+1}")
                        
                        if available_pool and missing_count > 0:
                            # Add random exercises from the available pool
                            random_exercises = random.sample(available_pool, 
                                                           min(missing_count, len(available_pool)))
                            
                            for ex in random_exercises:
                                option.append({
                                    "workout": ex["Title"],
                                    "image": self.exercise_db.get_exercise_icon(ex["Title"]),
                                    "sets": "3",
                                    "reps": "10-12",
                                    "instruction": ""
                                })
                    elif len(option) > expected_count:  # Need to remove exercises
                        # Remove excess exercises
                        excess = len(option) - expected_count
                        logger.info(f"Removing {excess} exercises from option {i+1}")
                        option[:] = option[:expected_count]
            
            # Make sure we have 3 options
            while len(processed_options) < 3:
                option_index = len(processed_options)
                logger.warning(f"Creating new option {option_index+1} to ensure 3 options")
                
                # For the home option
                if option_index == 2:  # Home-friendly option
                    # Filter for exercises that can be done at home
                    exercise_pool = [ex for ex in all_exercises 
                                    if any(term in ex["Title"].lower() 
                                          for term in ['push up', 'pull up', 'bodyweight', 
                                                      'dumbbell', 'squat', 'lunge', 'plank'])]
                    if not exercise_pool:  # Fallback if no home exercises found
                        exercise_pool = all_exercises
                else:
                    exercise_pool = all_exercises
                
                new_option = []
                expected_count = 5 if option_index == 1 else 4
                
                if exercise_pool and len(exercise_pool) >= expected_count:
                    # Get random exercises for this option
                    random_exercises = random.sample(exercise_pool, min(expected_count, len(exercise_pool)))
                    
                    for ex in random_exercises:
                        new_option.append({
                            "workout": ex["Title"],
                            "image": self.exercise_db.get_exercise_icon(ex["Title"]),
                            "sets": "3",
                            "reps": "10-12",
                            "instruction": ""
                        })
                
                processed_options.append(new_option)
            
            logger.info(f"Successfully generated {len(processed_options)} strength workout options")
            return {
                "options": processed_options,
                "category": category
            }
            
        except Exception as e:
            logger.error(f"Error in generate_strength_options: {str(e)}", exc_info=True)
            return self._create_default_strength_options(category, all_exercises)

    def _create_default_strength_options(self, category: str, available_exercises=None) -> dict:
        """Create default strength options when LLM fails."""
        logger.warning(f"Creating default strength options for {category} due to LLM failure")
        options = []
        
        if not available_exercises:
            logger.warning("No available exercises provided for defaults, using empty list")
            available_exercises = []
        
        # Create 3 different strength options
        for i in range(3):
            option = []
            expected_count = 5 if i == 1 else 4  # Option 2 should have 5 exercises
            
            # For the home option
            if i == 2:  # Home-friendly option
                # Filter for exercises that can be done at home
                exercise_pool = [ex for ex in available_exercises 
                                if any(term in ex["Title"].lower() 
                                      for term in ['push up', 'pull up', 'bodyweight', 
                                                  'dumbbell', 'squat', 'lunge', 'plank'])]
                if not exercise_pool:  # Fallback if no home exercises found
                    exercise_pool = available_exercises
            else:
                exercise_pool = available_exercises
            
            if exercise_pool and len(exercise_pool) >= expected_count:
                # Get random exercises for this option
                random_exercises = random.sample(exercise_pool, min(expected_count, len(exercise_pool)))
                
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
                    if i == 1:  # Add one more for option 2
                        generic_exercises.append("Tricep Dips")
                elif category == "Lower Body":
                    generic_exercises = ["Bodyweight Squats", "Lunges", "Calf Raises", "Glute Bridges"]
                    if i == 1:  # Add one more for option 2
                        generic_exercises.append("Single Leg Deadlift")
                elif category == "Push":
                    generic_exercises = ["Push Ups", "Bench Press", "Dumbbell Shoulder Press", "Tricep Dips"]
                    if i == 1:  # Add one more for option 2
                        generic_exercises.append("Incline Push Ups")
                elif category == "Pull":
                    generic_exercises = ["Pull Ups", "Dumbbell Rows", "Lat Pulldowns", "Dumbbell Curls"]
                    if i == 1:  # Add one more for option 2
                        generic_exercises.append("Face Pulls")
                elif category == "Legs":
                    generic_exercises = ["Bodyweight Squats", "Lunges", "Leg Press", "Leg Curls"]
                    if i == 1:  # Add one more for option 2
                        generic_exercises.append("Calf Raises")
                else:  # Full Body
                    generic_exercises = ["Push Ups", "Pull Ups", "Bodyweight Squats", "Planks"]
                    if i == 1:  # Add one more for option 2
                        generic_exercises.append("Burpees")
                
                for ex_name in generic_exercises:
                    option.append({
                        "workout": ex_name,
                        "image": self.exercise_db.get_exercise_icon(ex_name),
                        "sets": "3",
                        "reps": "10-12",
                        "instruction": ""
                    })
            
            options.append(option)
            logger.info(f"Created default {category} option {i+1} with {len(option)} exercises")
            
        return {
            "options": options,
            "category": category
        }