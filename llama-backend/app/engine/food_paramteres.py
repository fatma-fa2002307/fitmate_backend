import ollama
import json
import logging
import random
from typing import List, Dict, Any, Optional
from app.models.schemas import FoodParameterRequest, FoodParameterResponse, FoodSuggestionRequest
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO, 
                    format='%(asctime)s [%(levelname)s] - %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger("food_parameter_engine")

class FoodParameterEngine:
    """Engine for generating personalized food parameters and suggestions using LLaMA model."""

    def __init__(self):
        # Milestone calorie percentage configurations
        self.milestone_calorie_percentage = {
            "START": 0.3,         # 30% of daily calories for breakfast
            "QUARTER": 0.15,      # 15% of daily calories for mid-morning snack
            "HALF": 0.3,          # 30% of daily calories for lunch
            "THREE_QUARTERS": 0.2, # 20% of daily calories for dinner
            "ALMOST_COMPLETE": 0.05, # 5% of daily calories for evening snack
            "COMPLETED": 0.02     # 2% or less for zero/ultra-low calorie options
        }
        
        # Milestone descriptions for better context
        self.milestone_descriptions = {
            "START": "breakfast (first meal of the day)",
            "QUARTER": "mid-morning snack", 
            "HALF": "lunch (main mid-day meal)",
            "THREE_QUARTERS": "dinner (evening meal)",
            "ALMOST_COMPLETE": "light evening snack",
            "COMPLETED": "zero/ultra-low calorie option (already at calorie goal)"
        }
        
        # Default meal types based on milestones
        self.milestone_meal_types = {
            "START": "breakfast",
            "QUARTER": "snack",
            "HALF": "lunch",
            "THREE_QUARTERS": "dinner",
            "ALMOST_COMPLETE": "snack",
            "COMPLETED": "snack"
        }
        
        # Default dietary focus based on goals
        self.goal_dietary_focus = {
            "Weight Loss": "low-calorie, high-protein",
            "Gain Muscle": "high-protein, nutrient-dense",
            "Improve Fitness": "balanced, nutrient-rich"
        }

    def _get_milestone_from_percentage(self, percentage: float) -> str:
        """Determine the milestone based on the percentage of calories consumed."""
        if percentage < 0.1:
            return "START"
        elif percentage < 0.35:
            return "QUARTER"
        elif percentage < 0.6:
            return "HALF"
        elif percentage < 0.85:
            return "THREE_QUARTERS"
        elif percentage < 1.0:
            return "ALMOST_COMPLETE"
        else:
            return "COMPLETED"  # for 100%+
        
    def generate_food_parameters(self, request: FoodParameterRequest) -> FoodParameterResponse:
        """Generate personalized meal parameters based on user's profile."""
        try:
            # Calculate current milestone
            consumed_calories = request.consumedCalories
            total_calories = request.totalCalories
            percentage_consumed = consumed_calories / total_calories if total_calories > 0 else 0
            
            current_milestone = self._get_milestone_from_percentage(percentage_consumed)
            logger.info(f"Current milestone: {current_milestone} ({percentage_consumed:.2%} calories consumed)")
            
            # Try to get parameters from LLaMA
            parameters = self._generate_parameters_via_llm(
                current_milestone=current_milestone,
                total_calories=total_calories,
                consumed_calories=consumed_calories,
                percentage_consumed=percentage_consumed,  # Pass calculated percentage
                goal=request.goal,
                disliked_food_ids=request.dislikedFoodIds or []
            )
            
            # If LLaMA fails, use default parameters
            if not parameters:
                logger.warning("LLaMA failed to generate parameters, using defaults")
                parameters = self._get_default_parameters(
                    milestone=current_milestone,
                    total_calories=total_calories,
                    consumed_calories=consumed_calories,
                    goal=request.goal
                )
            
            logger.info(f"Generated food parameters: {parameters}")
            return parameters
            
        except Exception as e:
            logger.error(f"Error generating food parameters: {str(e)}", exc_info=True)
            # Return default parameters if there's an error
            return self._get_default_parameters(
                milestone=self._get_milestone_from_percentage(request.consumedCalories / request.totalCalories if request.totalCalories > 0 else 0),
                total_calories=request.totalCalories,
                consumed_calories=request.consumedCalories,
                goal=request.goal
            )
    
    def _generate_parameters_via_llm(self, current_milestone: str, total_calories: float, 
                                    consumed_calories: float, percentage_consumed: float, 
                                    goal: str, disliked_food_ids: List[str]) -> Optional[FoodParameterResponse]:
        """Generate food parameters using LLama model."""
        try:
            # Prepare prompt for LLM
            milestone_names = {
                "START": "breakfast (morning)",
                "QUARTER": "mid-morning snack",
                "HALF": "lunch (mid-day meal)",
                "THREE_QUARTERS": "dinner (evening meal)",
                "ALMOST_COMPLETE": "evening snack",
                "COMPLETED": "zero/ultra-low calorie option"
            }
            
            milestone_description = milestone_names.get(current_milestone, "meal")
            disliked_foods_text = ", ".join(disliked_food_ids) if disliked_food_ids else "None"
            
            # Calculate remaining calories
            remaining_calories = total_calories - consumed_calories
            
            # Calculate default target calories
            default_target_calories = total_calories * self.milestone_calorie_percentage.get(current_milestone, 0.2)
            default_target_calories = min(default_target_calories, remaining_calories)
            
            # Special case for COMPLETED milestone - ultra-low calorie options
            if current_milestone == "COMPLETED":
                default_target_calories = min(50, remaining_calories)
            
            # Get time of day
            from datetime import datetime
            current_hour = datetime.now().hour
            time_of_day = "morning" if current_hour < 12 else "afternoon" if current_hour < 18 else "evening"
            
            prompt = f"""As a nutrition AI expert, provide personalized meal parameters for a user based on their current nutritional status and fitness goals.

User Profile:
- Daily calorie goal: {total_calories:.0f} calories
- Calories consumed so far: {consumed_calories:.0f} calories ({percentage_consumed:.0%} of daily goal)
- Remaining calories: {remaining_calories:.0f}
- Current meal context: {milestone_description}
- Current time: {time_of_day}
- Goal: {goal}
- Disliked foods: {disliked_foods_text}

Please determine the following parameters for their next meal:
1. The most appropriate meal type (breakfast, lunch, dinner, snack, dessert, etc.)
2. Optimal target calories for this meal (considering their remaining daily budget)
3. Ideal macronutrient ratio for this meal (protein/carbs/fat percentages)
4. 3-5 specific nutritional explanations tailored to their current status and goals
5. Dietary focus for this meal (e.g., "high-protein", "low-carb", etc.)

The default target calories would be {default_target_calories:.0f}, but you can adjust based on the user's needs.

FOLLOW INSTRUCTIONS CAREFULLY! Return ONLY the following JSON format:
```json
{{
  "mealType": "breakfast",
  "targetCalories": 500,
  "macroRatios": {{
    "protein": 0.3,
    "carbs": 0.4,
    "fat": 0.3
  }},
  "explanations": [
    "Explanation 1 about why this meal is beneficial",
    "Explanation 2 about specific nutrition benefits",
    "Explanation 3 about how this supports their goals"
  ],
  "dietaryFocus": "high-protein, low-carb"
}}
```
"""

            # Call LLama model
            logger.info("Sending request to LLama model")
            response = ollama.chat(
                model="llama3.2",
                messages=[
                    {
                        "role": "system", 
                        "content": "You are a nutrition expert that generates personalized meal parameters based on a user's current status and fitness goals. Always respond with valid JSON."
                    },
                    {"role": "user", "content": prompt}
                ],
                options={"temperature": 0.7}
            )
            
            content = response['message']['content'].strip()
            logger.info(f"Received response from LLama model: {content[:100]}...")
            
            # Extract JSON from response (might be wrapped in ```json blocks)
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0].strip()
            elif "```" in content:
                content = content.split("```")[1].split("```")[0].strip()
            
            # Parse parameters
            parameters_data = json.loads(content)
            
            # Convert to FoodParameterResponse
            return FoodParameterResponse(
                milestone=current_milestone,
                mealType=parameters_data["mealType"],
                targetCalories=parameters_data["targetCalories"],
                macroRatios=parameters_data["macroRatios"],
                explanations=parameters_data["explanations"],
                dietaryFocus=parameters_data["dietaryFocus"],
                timestamp=datetime.now()
            )
            
        except Exception as e:
            logger.error(f"Error generating parameters via LLM: {str(e)}", exc_info=True)
            return None
    
    def _get_default_parameters(self, milestone: str, total_calories: float, 
                               consumed_calories: float, goal: str) -> FoodParameterResponse:
        """Get default parameters if LLaMA fails."""
        from datetime import datetime
        
        # Calculate target calories
        target_calories = total_calories * self.milestone_calorie_percentage.get(milestone, 0.2)
        remaining_calories = total_calories - consumed_calories
        target_calories = min(target_calories, remaining_calories)
        
        # Get default meal type
        meal_type = self.milestone_meal_types.get(milestone, "meal")
        
        # Get default macro ratios
        macro_ratios = self._get_default_macro_ratios(goal)
        
        # Get default dietary focus
        dietary_focus = self.goal_dietary_focus.get(goal, self.goal_dietary_focus["Improve Fitness"])
        
        # Generate default explanations
        explanations = self._generate_default_explanations(milestone, goal, dietary_focus)
        
        return FoodParameterResponse(
            milestone=milestone,
            mealType=meal_type,
            targetCalories=target_calories,
            macroRatios=macro_ratios,
            explanations=explanations,
            dietaryFocus=dietary_focus,
            timestamp=datetime.now()
        )
    
    def _generate_default_explanations(self, milestone: str, goal: str, dietary_focus: str) -> List[str]:
        """Generate default explanations based on milestone and goal."""
        milestone_name = milestone.lower().replace('_', ' ')
        
        explanations_by_milestone = {
            "START": [
                f"A nutrient-dense breakfast helps kick-start your metabolism and provides energy for the day ahead.",
                f"Including protein in your breakfast helps control appetite throughout the morning.",
                f"Complex carbohydrates at breakfast provide sustained energy and help maintain stable blood sugar levels."
            ],
            "QUARTER": [
                f"A light mid-morning snack helps maintain energy levels between breakfast and lunch.",
                f"Choosing protein-rich snacks helps curb hunger and prevents overeating at lunch.",
                f"Including fiber in your snack promotes satiety and digestive health."
            ],
            "HALF": [
                f"A balanced lunch refuels your body for afternoon activities.",
                f"Including lean protein at lunch supports muscle maintenance and repair.",
                f"Complex carbohydrates provide sustained energy for the remainder of your workday."
            ],
            "THREE_QUARTERS": [
                f"A nutritious dinner completes your daily nutritional needs.",
                f"Including vegetables at dinner ensures you meet your micronutrient requirements.",
                f"Moderate portion sizes at dinner support quality sleep and recovery."
            ],
            "ALMOST_COMPLETE": [
                f"A light evening snack can help satisfy cravings without excess calories.",
                f"Protein-rich evening snacks support overnight muscle recovery.",
                f"Avoiding heavy meals close to bedtime promotes better sleep quality."
            ],
            "COMPLETED": [
                f"Ultra-low calorie options allow you to enjoy something without exceeding your daily targets.",
                f"Focusing on nutrient-dense, low-calorie foods maximizes nutrition while minimizing calories.",
                f"Hydrating foods and beverages can help satisfy cravings without adding significant calories."
            ]
        }
        
        goal_explanations = {
            "Weight Loss": [
                f"Higher protein intake helps preserve lean muscle mass during weight loss.",
                f"Controlled carbohydrate intake helps manage insulin levels and reduce fat storage.",
                f"Including fiber-rich foods increases satiety while keeping calories low."
            ],
            "Gain Muscle": [
                f"Higher protein intake supports muscle protein synthesis and recovery.",
                f"Adequate carbohydrates replenish muscle glycogen stores for optimal performance.",
                f"Essential fats support hormone production necessary for muscle growth."
            ],
            "Improve Fitness": [
                f"Balanced nutrition optimizes energy availability for workouts and daily activities.",
                f"Adequate protein supports muscle recovery and adaptation to exercise.",
                f"Complex carbohydrates fuel high-intensity exercise and support energy levels."
            ]
        }
        
        # Combine milestone and goal explanations
        milestone_explanations = explanations_by_milestone.get(milestone, [])
        goal_specific_explanations = goal_explanations.get(goal, [])
        
        # Select a mix of explanations (2 from milestone, 1 from goal)
        selected_explanations = []
        if milestone_explanations:
            selected_explanations.extend(random.sample(milestone_explanations, min(2, len(milestone_explanations))))
        if goal_specific_explanations:
            selected_explanations.extend(random.sample(goal_specific_explanations, min(1, len(goal_specific_explanations))))
            
        return selected_explanations
    
    # New method to generate food suggestions
    def generate_food_suggestions(self, request: FoodSuggestionRequest) -> Dict[str, Any]:
        """Generate food suggestions using LLaMA model based on user's current status."""
        try:
            # Calculate current milestone and percentage
            total_calories = request.totalCalories
            consumed_calories = request.consumedCalories
            percentage_consumed = consumed_calories / total_calories if total_calories > 0 else 0
            
            milestone = self._get_milestone_from_percentage(percentage_consumed)
            remaining_calories = max(0, total_calories - consumed_calories)
            
            logger.info(f"Generating food suggestions for milestone: {milestone}")
            logger.info(f"User has consumed {consumed_calories:.1f}/{total_calories:.1f} calories ({percentage_consumed:.1%})")
            
            # Get time of day for context
            current_hour = datetime.now().hour
            time_of_day = "morning" if current_hour < 12 else "afternoon" if current_hour < 18 else "evening"
            
            # Format disliked foods for the prompt
            disliked_foods_text = ", ".join(request.dislikedFoodIds) if request.dislikedFoodIds else "None"
            
            # Construct prompt for LLaMA
            prompt = self._construct_food_suggestion_prompt(
                milestone=milestone,
                total_calories=total_calories,
                consumed_calories=consumed_calories,
                remaining_calories=remaining_calories,
                goal=request.goal,
                time_of_day=time_of_day,
                disliked_foods=disliked_foods_text
            )
            
            # Get suggestions from LLaMA
            suggestions = self._generate_suggestions_via_llm(prompt)
            
            # If LLaMA fails to generate valid suggestions, use a simpler prompt
            if not suggestions:
                logger.warning("LLaMA failed with detailed prompt, trying simplified prompt")
                simplified_prompt = self._construct_simplified_prompt(
                    milestone=milestone,
                    remaining_calories=remaining_calories,
                    goal=request.goal
                )
                suggestions = self._generate_suggestions_via_llm(simplified_prompt)
            
            # If we still don't have valid suggestions, return an empty list
            # The client will handle fallbacks on its side
            if not suggestions:
                logger.error("Failed to generate suggestions even with simplified prompt")
                suggestions = []
            
            return {
                "milestone": milestone,
                "suggestions": suggestions
            }
            
        except Exception as e:
            logger.error(f"Error generating food suggestions: {str(e)}", exc_info=True)
            return {
                "milestone": self._get_milestone_from_percentage(request.consumedCalories / request.totalCalories if request.totalCalories > 0 else 0),
                "suggestions": []  # Return empty list, client will handle fallbacks
            }
    
    def _construct_food_suggestion_prompt(self, milestone: str, total_calories: float, 
                                        consumed_calories: float, remaining_calories: float,
                                        goal: str, time_of_day: str, disliked_foods: str) -> str:
        """Construct a detailed prompt for food suggestion generation."""
        
        meal_context = self.milestone_descriptions.get(milestone, "meal")
        
        # Calculate target calories for this meal
        suggested_calories = total_calories * self.milestone_calorie_percentage.get(milestone, 0.2)
        suggested_calories = min(suggested_calories, remaining_calories)
        
        # Special case for COMPLETED milestone - ultra-low calorie options
        if milestone == "COMPLETED":
            suggested_calories = min(50, remaining_calories)

        prompt = f"""As a nutrition expert, suggest personalized food options for a user based on their current status and fitness goals.

User Profile:
- Daily calorie goal: {total_calories:.0f} calories
- Calories consumed so far: {consumed_calories:.0f} calories
- Remaining calories: {remaining_calories:.0f}
- Current meal context: {meal_context}
- Current time: {time_of_day}
- Fitness goal: {goal}
- Disliked foods: {disliked_foods}

TASK:
Generate 3 DIVERSE and UNIQUE food suggestions (NO repetition). Include a mix of complete meals and simple options:
- Ensure each suggestion is completely different from the others in ingredients and preparation
- Vary between complex meals and simple options like snacks/ingredients
- Be creative and avoid generic options

For the COMPLETED milestone (where user has already reached calorie goal), suggest ultra-low calorie options like water, tea, vegetables.

Each suggestion should include:
1. A descriptive title (be specific and avoid generic names)
2. Estimated calories (around {suggested_calories:.0f} calories is appropriate for this meal context)
3. Macronutrient breakdown (protein, carbs, fat in grams)
4. A personalized explanation of why this food supports the user's goals

FOLLOW INSTRUCTIONS CAREFULLY! Return ONLY the following JSON format:
```json
[
  {{
    "id": "unique-id-1",
    "title": "Specific Food Option Title",
    "image": "https://spoonacular.com/cdn/ingredients_100x100/food-name.jpg",
    "calories": 300,
    "protein": 20.0,
    "carbs": 30.0,
    "fat": 10.0,
    "sourceUrl": "",
    "readyInMinutes": 0,
    "servings": 1,
    "explanation": "Personalized nutrition explanation",
    "isSimpleIngredient": false
  }},
  {{
    "id": "unique-id-2",
    "title": "Different Food Option",
    "image": "https://spoonacular.com/cdn/ingredients_100x100/different-food.jpg",
    "calories": 240,
    "protein": 15.0,
    "carbs": 25.0,
    "fat": 8.0,
    "sourceUrl": "",
    "readyInMinutes": 0,
    "servings": 1,
    "explanation": "Different personalized explanation",
    "isSimpleIngredient": true
  }},
  {{
    "id": "unique-id-3",
    "title": "Completely Different Option",
    "image": "https://spoonacular.com/cdn/ingredients_100x100/another-food.jpg",
    "calories": 280,
    "protein": 18.0,
    "carbs": 20.0,
    "fat": 12.0,
    "sourceUrl": "",
    "readyInMinutes": 0,
    "servings": 1,
    "explanation": "Unique explanation for this option",
    "isSimpleIngredient": true
  }}
]
```

IMPORTANT NOTES:
1. Each suggestion must be COMPLETELY UNIQUE - different ingredients, different preparation methods
2. For image URLs, use accurate food names that would appear in Spoonacular's database (e.g., "apple.jpg", "chicken-breast.jpg")
3. EVERY field should be included for EACH suggestion
4. For the COMPLETED milestone (already at calorie goal), suggest ultra-low or zero calorie options
5. Ensure explanations are personalized to the user's goal, milestone, and nutritional needs
6. Do NOT repeat food types or ingredients across suggestions
"""

        return prompt

    def _construct_simplified_prompt(self, milestone: str, remaining_calories: float, goal: str) -> str:
        """Construct a simplified prompt as fallback if detailed prompt fails."""
        
        meal_type = {
            "START": "breakfast",
            "QUARTER": "snack",
            "HALF": "lunch",
            "THREE_QUARTERS": "dinner",
            "ALMOST_COMPLETE": "light snack",
            "COMPLETED": "zero-calorie option"
        }.get(milestone, "meal")
        
        prompt = f"""Generate 3 diverse food suggestions for {meal_type} with {remaining_calories:.0f} calories remaining. Goal: {goal}.

MAKE SURE EACH SUGGESTION IS COMPLETELY DIFFERENT FROM THE OTHERS - no repeated ingredients or cooking methods.

Return only valid JSON array of food objects with these fields: id, title, image, calories, protein, carbs, fat, sourceUrl, readyInMinutes, servings, explanation, isSimpleIngredient.

For images use format: https://spoonacular.com/cdn/ingredients_100x100/food-name.jpg
"""
        return prompt
            
    def _generate_suggestions_via_llm(self, prompt: str) -> List[Dict[str, Any]]:
        """Generate food suggestions using LLama model."""
        try:
            logger.info("Sending food suggestion request to LLama model")
            
            response = ollama.chat(
                model="llama3.2",
                messages=[
                    {
                        "role": "system", 
                        "content": "You are a nutrition expert that generates personalized food suggestions based on a user's current status and fitness goals. Always respond with valid JSON array of food suggestions only."
                    },
                    {"role": "user", "content": prompt}
                ],
                options={"temperature": 0.7}
            )
            
            content = response['message']['content'].strip()
            logger.info(f"Received response from LLama model: {content[:100]}...")
            
            # Extract JSON from response (might be wrapped in ```json blocks)
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0].strip()
            elif "```" in content:
                content = content.split("```")[1].split("```")[0].strip()
            
            # Parse suggestions
            try:
                suggestions = json.loads(content)
                
                # Validate that we have a list with at least one item
                if isinstance(suggestions, list) and len(suggestions) > 0:
                    logger.info(f"Successfully parsed {len(suggestions)} food suggestions")
                    
                    # Ensure required fields are present
                    for suggestion in suggestions:
                        required_fields = ["id", "title", "image", "calories", "protein", "carbs", "fat", "explanation"]
                        if not all(field in suggestion for field in required_fields):
                            logger.warning(f"Suggestion missing required fields: {suggestion}")
                            return []
                            
                    return suggestions
                else:
                    logger.warning(f"Invalid suggestions format: {suggestions}")
                    return []
                    
            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse JSON response: {e}")
                return []
                
        except Exception as e:
            logger.error(f"Error generating suggestions via LLM: {str(e)}", exc_info=True)
            return []
            
    def _get_default_macro_ratios(self, goal: str) -> Dict[str, float]:
        """Get default macro ratios based on goal."""
        if goal.lower() == "weight loss":
            return {
                "protein": 0.30,
                "carbs": 0.40,
                "fat": 0.30,
            }
        elif goal.lower() == "gain muscle":
            return {
                "protein": 0.35,
                "carbs": 0.45,
                "fat": 0.20,
            }
        else:  # "improve fitness" or default
            return {
                "protein": 0.25,
                "carbs": 0.50,
                "fat": 0.25,
            }
        