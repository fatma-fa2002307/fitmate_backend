import ollama
import logging
import random
from datetime import datetime
from typing import Dict, List, Any, Optional
import json
import traceback

# Configure logging
logging.basicConfig(level=logging.INFO, 
                   format='%(asctime)s [%(levelname)s] - %(message)s',
                   datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger("tip_engine")

class TipEngine:
    """Engine for generating personalized fitness and nutrition tips using LLaMA."""
    
    def __init__(self):
        # Categories of tips with their icons
        self.tip_categories = {
            "nutrition": "nutrition_restaurant",
            "workout": "fitness_center", 
            "motivation": "emoji_events",
            "recovery": "self_improvement",
            "habit": "trending_up",
            "hydration": "water_drop"
        }
        
    async def generate_personalized_tip(self, user_data: Dict[str, Any]) -> Dict[str, Any]:
        """Generate a personalized tip based on user data."""
        try:
            # Print debug info about the user data
            logger.info(f"DEBUG: Generating tip with user data: {json.dumps(user_data, default=str)}")
            
            # Extract user details for personalization
            goal = user_data.get('goal', 'Improve Fitness')
            workout_days = user_data.get('workoutDays', 3)
            gender = user_data.get('gender', 'Unspecified')
            fitness_level = user_data.get('fitnessLevel', 'Intermediate')
            
            # Additional context from food logs and workout data
            recent_workouts = user_data.get('recentWorkouts', [])
            food_logs = user_data.get('foodLogs', [])
            calorie_percentage = user_data.get('caloriePercentage', 0.0)
            
            # Debug info about specific user metrics
            logger.info(f"DEBUG: User profile - Goal: {goal}, Gender: {gender}, Fitness Level: {fitness_level}")
            logger.info(f"DEBUG: User metrics - Workout days: {workout_days}, Calorie %: {calorie_percentage}")
            logger.info(f"DEBUG: User has {len(recent_workouts)} recent workouts and {len(food_logs)} food logs")
            
            # Determine which categories to focus on based on user context
            focus_categories = self._determine_focus_categories(
                goal, workout_days, recent_workouts, food_logs, calorie_percentage
            )
            
            # Debug info about selected categories
            logger.info(f"DEBUG: Focus categories: {focus_categories}")
            
            # Select a random category from the focused ones
            category = random.choice(focus_categories)
            logger.info(f"DEBUG: Selected tip category: {category}")
            
            # Generate the tip using LLaMA
            tip = await self._generate_tip_with_llama(
                category, goal, gender, fitness_level, workout_days, 
                recent_workouts, food_logs, calorie_percentage
            )
            
            logger.info(f"DEBUG: Generated tip: {tip}")
            
            # Format response with category and icon
            response = {
                "tip": tip,
                "category": category,
                "icon": self.tip_categories.get(category, "tips_and_updates"),
                "generated_at": datetime.now().isoformat()
            }
            
            logger.info(f"Successfully generated {category} tip for user with goal: {goal}")
            return response
            
        except Exception as e:
            logger.error(f"Error generating tip: {str(e)}")
            logger.error(traceback.format_exc())
            # Return a fallback tip if anything fails
            return self._get_fallback_tip()
    
    def _determine_focus_categories(
        self, goal: str, workout_days: int, 
        recent_workouts: List[Dict[str, Any]], food_logs: List[Dict[str, Any]],
        calorie_percentage: float
    ) -> List[str]:
        """Determine which categories to focus on based on user data."""
        # Start with all categories
        categories = list(self.tip_categories.keys())
        focused_categories = []
        
        # Focus on nutrition if user is tracking food or has specific goals
        if "Weight Loss" in goal or "Muscle" in goal or food_logs:
            focused_categories.append("nutrition")
            
        # Focus on workout if user has workout days set or recent workouts
        if workout_days > 0 or recent_workouts:
            focused_categories.append("workout")
            
        # Focus on recovery for frequent workout users
        if workout_days >= 4:
            focused_categories.append("recovery")
            
        # Focus on hydration if user doesn't have enough food logs or is active
        if len(food_logs) < 3 or workout_days >= 3:
            focused_categories.append("hydration")
            
        # Focus on habit building for all users
        focused_categories.append("habit")
        
        # Focus on motivation for all users
        focused_categories.append("motivation")
        
        # If we couldn't determine focus, use all categories
        if not focused_categories:
            return categories
            
        return focused_categories
    
    async def _generate_tip_with_llama(
        self, category: str, goal: str, gender: str, fitness_level: str,
        workout_days: int, recent_workouts: List[Dict[str, Any]], 
        food_logs: List[Dict[str, Any]], calorie_percentage: float
    ) -> str:
        """Generate a tip using LLaMA based on user context."""
        try:
            # Create a prompt for LLaMA with relevant user context
            prompt = self._create_tip_prompt(
                category, goal, gender, fitness_level, workout_days,
                recent_workouts, food_logs, calorie_percentage
            )
            
            # Log the prompt for debugging
            logger.info(f"DEBUG: LLaMA Prompt: {prompt}")
            
            # Call LLaMA model
            logger.info(f"Requesting {category} tip from LLaMA")
            response = ollama.chat(
                model="llama3.2",
                messages=[
                    {
                        "role": "system", 
                        "content": "You are a professional fitness and nutrition coach who provides concise, highly personalized, and actionable tips. Your tips are extremely playful, witty, encouraging, and engaging while still being scientifically sound. You include specific details that make users feel the tip was made just for them. You use wordplay, fun metaphors, and occasional emoji for emphasis."
                    },
                    {"role": "user", "content": prompt}
                ],
                options={"temperature": 0.8}  # Slightly higher temperature for more creative tips
            )
            
            # Extract the content
            content = response['message']['content'].strip()
            logger.info(f"DEBUG: Raw LLaMA response: {content}")
            
            # Ensure the tip isn't too long (aim for a single sentence or short paragraph)
            tip = self._process_tip(content)
            
            return tip
            
        except Exception as e:
            logger.error(f"Error generating tip with LLaMA: {str(e)}")
            logger.error(traceback.format_exc())
            return self._get_fallback_tip()["tip"]
    
    def _create_tip_prompt(
        self, category: str, goal: str, gender: str, fitness_level: str,
        workout_days: int, recent_workouts: List[Dict[str, Any]], 
        food_logs: List[Dict[str, Any]], calorie_percentage: float
    ) -> str:
        """Create a prompt for LLaMA to generate a personalized tip."""
        
        # Extract specific details for super personalization
        workout_types = []
        for workout in recent_workouts:
            if 'category' in workout:
                workout_types.append(workout['category'])
                
        food_types = []
        high_protein = False
        high_carb = False
        for food in food_logs:
            if 'dishName' in food:
                food_types.append(food['dishName'])
            if 'protein' in food and food['protein'] > 20:
                high_protein = True
            if 'carbs' in food and food['carbs'] > 40:
                high_carb = True
        
        # Base prompt with category and user profile
        prompt = f"""Create a SHORT, HIGHLY PERSONALIZED, and PLAYFUL fitness/nutrition tip for a {gender} with a fitness goal of '{goal}' who works out {workout_days} days per week and is at a {fitness_level} fitness level.

Focus area: {category.capitalize()}

"""
        # Add more specific details to increase personalization
        if workout_types:
            prompt += f"They recently did these workouts: {', '.join(workout_types[:3])}. "
            
        if food_types:
            prompt += f"Their recent meals include: {', '.join(food_types[:3])}. "
            
        if high_protein:
            prompt += "They tend to eat high-protein meals. "
            
        if high_carb:
            prompt += "Their diet includes higher carbohydrate foods. "
            
        if calorie_percentage > 0:
            if calorie_percentage < 0.5:
                prompt += "They're currently early in their day's calorie intake. "
            elif calorie_percentage < 0.8:
                prompt += "They've consumed most of their daily calories. "
            else:
                prompt += "They've reached or exceeded their daily calorie target. "
        
        # Add context based on category
        if category == "nutrition":
            prompt += f"""
The user has logged {len(food_logs)} meals today and has consumed approximately {calorie_percentage:.0%} of their daily calorie goal.

Create a SINGLE nutrition tip that is:
1. SUPER personalized to their exact situation and meals
2. Very playful and witty - use wordplay or a fun metaphor
3. Specifically tailored to their goal of {goal}
4. Include a specific food suggestion or meal timing recommendation
5. Under 150 characters and punchy
"""
            
        elif category == "workout":
            workout_context = "No recent workouts" if not recent_workouts else f"{len(recent_workouts)} recent workouts"
            prompt += f"""
The user has {workout_context}.

Create a SINGLE workout tip that is:
1. HIGHLY specific to their current workout frequency and fitness level
2. Very playful, witty, and motivating - use creative language or metaphors
3. Tailored for someone who works out {workout_days} days/week
4. Mention a specific exercise or technique relevant to their {fitness_level} level
5. Under 150 characters and punchy
"""
            
        elif category == "motivation":
            prompt += f"""
Create an uplifting and motivational tip that:
1. Feels written SPECIFICALLY for them and their {goal} goal
2. Uses wordplay, a fun metaphor or analogy
3. Is extremely positive, playful and encouraging
4. Mentions something unique about their workout routine or diet
5. Under 150 characters and punchy
"""
            
        elif category == "recovery":
            prompt += f"""
Create a recovery tip that:
1. Is HIGHLY personalized for someone doing {workout_days} workouts per week
2. Is extremely playful and uses a fun metaphor or wordplay
3. Offers a specific recovery technique appropriate for their {fitness_level} level
4. Includes a common household item they might use for recovery
5. Under 150 characters and punchy
"""
            
        elif category == "habit":
            prompt += f"""
Create a habit-building tip that:
1. Is SUPER specific to their {goal} goal
2. Is extremely playful with witty wordplay or a clever metaphor
3. Suggests a very specific micro-habit they could implement
4. Ties the habit explicitly to their {goal} goal
5. Under 120 characters and punchy
"""
            
        elif category == "hydration":
            prompt += f"""
Create a hydration tip that:
1. Is personally tailored to their {workout_days} workouts per week
2. Is extremely playful, with water-related wordplay or puns
3. Gives a specific, actionable hydration suggestion
4. Mentions how proper hydration specifically helps with their {goal} goal
5. Under 150 characters and punchy
"""
        
        # Final instructions
        prompt += """
IMPORTANT: The tip should be ONE sentence or very short paragraph, conversational in tone, and feel like it was made SPECIFICALLY for this unique user. 
    Make them feel like you really know their situation. Do not include any emojis or special characters in the tip text.

Only return the tip text, with no additional explanations or content ."""
        
        return prompt
    
    def _process_tip(self, content: str) -> str:
        """Process the raw tip from LLaMA to ensure it's appropriate length."""
        # Remove quotation marks if present
        content = content.strip('"\'')
        
        # If the content has multiple paragraphs, just use the first one
        paragraphs = content.split('\n\n')
        content = paragraphs[0]
        
        # If still too long, truncate to a reasonable length
        if len(content) > 200:
            sentences = content.split('. ')
            content = '. '.join(sentences[:2]) + '.'
            
        return content.strip()
        
    def _get_fallback_tip(self) -> Dict[str, Any]:
        """Get a fallback tip if LLaMA fails."""
        fallback_tips = [
            {
                "tip": "💧 Make water your BFF! Try infusing it with fruits for a flavor party that keeps you hydrated and happy!",
                "category": "hydration",
                "icon": "water_drop"
            },
            {
                "tip": "🥦 Pro tip: Sneak in veggies like a nutrition ninja! Add spinach to your smoothie for a stealth health upgrade!",
                "category": "nutrition",
                "icon": "nutrition_restaurant"
            },
            {
                "tip": "💪 Quality beats quantity! Master your squat form before adding weight—your knees will send you a thank-you card!",
                "category": "workout",
                "icon": "fitness_center"
            },
            {
                "tip": "✨ Remember: Rome wasn't built in a day, and neither are awesome biceps! Keep showing up for yourself!",
                "category": "motivation",
                "icon": "emoji_events"
            },
            {
                "tip": "😴 Rest isn't being lazy—it's when your muscles throw their build-back-better party! Give them time to celebrate!",
                "category": "recovery",
                "icon": "self_improvement"
            }
        ]
        
        tip = random.choice(fallback_tips)
        tip["generated_at"] = datetime.now().isoformat()
        return tip