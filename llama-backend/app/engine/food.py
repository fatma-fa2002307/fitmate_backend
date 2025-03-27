import ollama
import json
import logging
import random
from typing import List, Dict, Any, Optional
from app.models.schemas import FoodSuggestionRequest, FoodSuggestion, MilestoneType

# Configure logging
logging.basicConfig(level=logging.INFO, 
                   format='%(asctime)s [%(levelname)s] - %(message)s',
                   datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger("food_suggestion_engine")

class FoodSuggestionEngine:
    """Engine for generating food suggestions based on user's calorie consumption milestone."""
    
    def __init__(self):
        # Example food suggestions for each milestone if API fails
        self.fallback_suggestions = {
            MilestoneType.START: [
                {"id": "fb-1", "title": "Oatmeal with Berries", "image": "oatmeal.jpg", "calories": 350, "protein": 10, "carbs": 60, "fat": 7},
                {"id": "fb-2", "title": "Greek Yogurt Parfait", "image": "yogurt_parfait.jpg", "calories": 300, "protein": 15, "carbs": 45, "fat": 5},
                {"id": "fb-3", "title": "Avocado Toast", "image": "avocado_toast.jpg", "calories": 380, "protein": 12, "carbs": 40, "fat": 18}
            ],
            MilestoneType.QUARTER: [
                {"id": "fb-4", "title": "Hummus and Vegetables", "image": "hummus.jpg", "calories": 250, "protein": 8, "carbs": 30, "fat": 10},
                {"id": "fb-5", "title": "Apple with Peanut Butter", "image": "apple_pb.jpg", "calories": 280, "protein": 7, "carbs": 35, "fat": 12},
                {"id": "fb-6", "title": "Trail Mix", "image": "trail_mix.jpg", "calories": 220, "protein": 6, "carbs": 25, "fat": 13}
            ],
            MilestoneType.HALF: [
                {"id": "fb-7", "title": "Chicken Salad", "image": "chicken_salad.jpg", "calories": 450, "protein": 30, "carbs": 25, "fat": 22},
                {"id": "fb-8", "title": "Quinoa Bowl", "image": "quinoa_bowl.jpg", "calories": 480, "protein": 18, "carbs": 65, "fat": 15},
                {"id": "fb-9", "title": "Turkey Sandwich", "image": "turkey_sandwich.jpg", "calories": 420, "protein": 25, "carbs": 48, "fat": 12}
            ],
            MilestoneType.THREE_QUARTERS: [
                {"id": "fb-10", "title": "Grilled Salmon", "image": "salmon.jpg", "calories": 320, "protein": 28, "carbs": 0, "fat": 18},
                {"id": "fb-11", "title": "Vegetable Stir Fry", "image": "stir_fry.jpg", "calories": 280, "protein": 12, "carbs": 35, "fat": 10},
                {"id": "fb-12", "title": "Lentil Soup", "image": "lentil_soup.jpg", "calories": 230, "protein": 15, "carbs": 30, "fat": 5}
            ],
            MilestoneType.ALMOST_COMPLETE: [
                {"id": "fb-13", "title": "Greek Yogurt", "image": "greek_yogurt.jpg", "calories": 120, "protein": 15, "carbs": 8, "fat": 0},
                {"id": "fb-14", "title": "Hard Boiled Egg", "image": "boiled_egg.jpg", "calories": 80, "protein": 7, "carbs": 0, "fat": 5},
                {"id": "fb-15", "title": "Strawberries", "image": "strawberries.jpg", "calories": 50, "protein": 1, "carbs": 12, "fat": 0}
            ],
            MilestoneType.COMPLETED: [
                {"id": "fb-16", "title": "Cucumber Slices", "image": "cucumber.jpg", "calories": 16, "protein": 0.7, "carbs": 3.1, "fat": 0.1},
                {"id": "fb-17", "title": "Herbal Tea", "image": "herbal_tea.jpg", "calories": 0, "protein": 0, "carbs": 0, "fat": 0},
                {"id": "fb-18", "title": "Celery Sticks", "image": "celery.jpg", "calories": 10, "protein": 0.5, "carbs": 2, "fat": 0}
    ]
        }
        
        # Milestone calorie percentage configurations
        self.milestone_calorie_percentage = {
            MilestoneType.START: 0.3,         # 30% of daily calories for breakfast
            MilestoneType.QUARTER: 0.25,      # 25% of daily calories for snack/light meal
            MilestoneType.HALF: 0.35,         # 35% of daily calories for main meal
            MilestoneType.THREE_QUARTERS: 0.2, # 20% of daily calories for light dinner
            MilestoneType.ALMOST_COMPLETE: 0.1, # 10% of daily calories for small snack
            MilestoneType.COMPLETED: 0.05    # 5% or less for zero/ultra-low calorie options
        }

    def get_milestone_from_percentage(self, percentage: float) -> MilestoneType:
        """Determine the milestone based on the percentage of calories consumed."""
        if percentage < 0.1:
            return MilestoneType.START
        elif percentage < 0.35:
            return MilestoneType.QUARTER
        elif percentage < 0.6:
            return MilestoneType.HALF
        elif percentage < 0.85:
            return MilestoneType.THREE_QUARTERS
        elif percentage < 1.0:
            return MilestoneType.ALMOST_COMPLETE
        else:
            return MilestoneType.COMPLETED  #for 100%+

    def generate_suggestions(self, request: FoodSuggestionRequest) -> List[FoodSuggestion]:
        """Generate food suggestions based on user's calorie consumption milestone."""
        try:
            # Calculate current milestone
            consumed_calories = request.consumedCalories
            total_calories = request.totalCalories
            percentage_consumed = consumed_calories / total_calories if total_calories > 0 else 0
            
            current_milestone = self.get_milestone_from_percentage(percentage_consumed)
            logger.info(f"Current milestone: {current_milestone.name} ({percentage_consumed:.2%} calories consumed)")
            
            # Filter out disliked foods
            disliked_food_ids = request.dislikedFoodIds or []
            
            # Calculate remaining calories
            remaining_calories = total_calories - consumed_calories
            
            # Calculate target calories for this milestone
            target_calories = total_calories * self.milestone_calorie_percentage[current_milestone]
            target_calories = min(target_calories, remaining_calories)  # Can't exceed remaining calories
            
            logger.info(f"Generating suggestions for milestone {current_milestone.name}, target calories: {target_calories:.0f}")
            
            # Try to get suggestions from LLM
            suggestions = self._generate_via_llm(
                current_milestone=current_milestone,
                target_calories=target_calories,
                disliked_food_ids=disliked_food_ids,
                request=request
            )
            
            # If LLM fails, use fallback suggestions
            if not suggestions:
                logger.warning("LLM failed to generate suggestions, using fallback")
                suggestions = self._get_fallback_suggestions(current_milestone, disliked_food_ids)
            
            return suggestions
            
        except Exception as e:
            logger.error(f"Error generating food suggestions: {str(e)}", exc_info=True)
            # Return fallback suggestions if there's an error
            return self._get_fallback_suggestions(
                self.get_milestone_from_percentage(request.consumedCalories / request.totalCalories if request.totalCalories > 0 else 0),
                request.dislikedFoodIds or []
            )
    
    def _generate_via_llm(self, current_milestone: MilestoneType, target_calories: float, 
                         disliked_food_ids: List[str], request: FoodSuggestionRequest) -> List[FoodSuggestion]:
        """Generate food suggestions using LLama model."""
        try:
            # Prepare prompt for LLM
            milestone_names = {
                MilestoneType.START: "breakfast (morning)",
                MilestoneType.QUARTER: "mid-morning snack",
                MilestoneType.HALF: "lunch (mid-day meal)",
                MilestoneType.THREE_QUARTERS: "dinner (evening meal)",
                MilestoneType.ALMOST_COMPLETE: "evening snack",
                MilestoneType.COMPLETED: "zero/ultra-low calorie option"
            }
            
            milestone_description = milestone_names[current_milestone]
            disliked_foods_text = ", ".join(disliked_food_ids) if disliked_food_ids else "None"
            
            prompt = f"""As a nutrition AI assistant, recommend 3 food items for a {milestone_description} that would fit within a {target_calories:.0f} calorie budget.

User Profile:
- Daily calorie goal: {request.totalCalories} calories
- Calories consumed so far: {request.consumedCalories} calories
- Disliked foods: {disliked_foods_text}
- Goal: {request.goal}

For each food recommendation, provide:
1. A single food item or simple meal (not a recipe with many ingredients)
2. A title (keep it concise)
3. Estimated calories (within the target range)
4. Estimated macronutrients (protein, carbs, and fat in grams)

FOLLOW INSTRUCTIONS CAREFULLY OR THE RESPONSE IS INVALID! NO EXPLANATIONS OR ADDITIONAL TEXT NEEDED.
Return ONLY in this JSON format:
```json
[
  {{
    "id": "generated-1",
    "title": "Food Item Name",
    "image": "food_item.jpg",
    "calories": 350,
    "protein": 15,
    "carbs": 40,
    "fat": 10
  }},
  ...
]
```
"""

            # Call LLama model
            logger.info("Sending request to LLama model")
            response = ollama.chat(
                model="llama3.2",
                messages=[
                    {
                        "role": "system", 
                        "content": "You are a nutrition expert that recommends food items based on caloric and macronutrient needs. Always respond with valid JSON."
                    },
                    {"role": "user", "content": prompt}
                ],
                options={"temperature": 0.5}
            )
            
            content = response['message']['content'].strip()
            logger.info(f"Received response from LLama model: {content[:100]}...")
            
            # Extract JSON from response (might be wrapped in ```json blocks)
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0].strip()
            elif "```" in content:
                content = content.split("```")[1].split("```")[0].strip()
            
            # Parse suggestions
            suggestions_data = json.loads(content)
            
            # Convert to FoodSuggestion objects
            suggestions = []
            for item in suggestions_data:
                suggestion = FoodSuggestion(
                    id=item["id"],
                    title=item["title"],
                    image=item["image"],
                    calories=item["calories"],
                    protein=item["protein"],
                    carbs=item["carbs"],
                    fat=item["fat"]
                )
                suggestions.append(suggestion)
            
            return suggestions
            
        except Exception as e:
            logger.error(f"Error generating suggestions via LLM: {str(e)}", exc_info=True)
            return []
    
    def _get_fallback_suggestions(self, milestone: MilestoneType, disliked_food_ids: List[str]) -> List[FoodSuggestion]:
        """Get fallback suggestions if API call fails."""
        # Filter out disliked foods
        suggestions = self.fallback_suggestions[milestone]
        filtered_suggestions = [s for s in suggestions if s["id"] not in disliked_food_ids]
        
        # If all suggestions are disliked, return random ones anyway
        if not filtered_suggestions and suggestions:
            filtered_suggestions = random.sample(suggestions, min(3, len(suggestions)))
        
        # Convert to FoodSuggestion objects
        result = []
        for item in filtered_suggestions[:3]:  # Limit to 3 suggestions
            suggestion = FoodSuggestion(
                id=item["id"],
                title=item["title"],
                image=item["image"],
                calories=item["calories"],
                protein=item["protein"],
                carbs=item["carbs"],
                fat=item["fat"]
            )
            result.append(suggestion)
            
        return result