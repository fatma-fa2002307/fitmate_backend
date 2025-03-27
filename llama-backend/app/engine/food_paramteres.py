import ollama
import json
import logging
import random
from typing import List, Dict, Any, Optional
from app.models.schemas import FoodParameterRequest, FoodParameterResponse, MilestoneType

# Configure logging
logging.basicConfig(level=logging.INFO, 
                    format='%(asctime)s [%(levelname)s] - %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger("food_parameter_engine")

class FoodParameterEngine:
    """Engine for generating personalized food parameters based on user's profile and current state."""
    
    def __init__(self):
        # Milestone calorie percentage configurations
        self.milestone_calorie_percentage = {
            MilestoneType.START: 0.3,         # 30% of daily calories for breakfast
            MilestoneType.QUARTER: 0.15,      # 15% of daily calories for mid-morning snack
            MilestoneType.HALF: 0.3,          # 30% of daily calories for lunch
            MilestoneType.THREE_QUARTERS: 0.2, # 20% of daily calories for dinner
            MilestoneType.ALMOST_COMPLETE: 0.05, # 5% of daily calories for evening snack
            MilestoneType.COMPLETED: 0.05     # 5% or less for zero/ultra-low calorie options
        }
        
        # Default macro ratios based on goals
        self.goal_macro_ratios = {
            "Weight Loss": {
                "protein": 0.30,
                "carbs": 0.40,
                "fat": 0.30
            },
            "Gain Muscle": {
                "protein": 0.35,
                "carbs": 0.45,
                "fat": 0.20
            },
            "Improve Fitness": {
                "protein": 0.25,
                "carbs": 0.50,
                "fat": 0.25
            }
        }
        
        # Default meal types based on milestones
        self.milestone_meal_types = {
            MilestoneType.START: "breakfast",
            MilestoneType.QUARTER: "snack",
            MilestoneType.HALF: "lunch",
            MilestoneType.THREE_QUARTERS: "dinner",
            MilestoneType.ALMOST_COMPLETE: "snack",
            MilestoneType.COMPLETED: "snack"
        }
        
        # Default dietary focus based on goals
        self.goal_dietary_focus = {
            "Weight Loss": "low-calorie, high-protein",
            "Gain Muscle": "high-protein, nutrient-dense",
            "Improve Fitness": "balanced, nutrient-rich"
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
            return MilestoneType.COMPLETED  # for 100%+

    def generate_food_parameters(self, request: FoodParameterRequest) -> FoodParameterResponse:
        """Generate personalized meal parameters based on user's profile."""
        try:
            # Calculate current milestone
            consumed_calories = request.consumedCalories
            total_calories = request.totalCalories
            percentage_consumed = consumed_calories / total_calories if total_calories > 0 else 0
            
            current_milestone = self.get_milestone_from_percentage(percentage_consumed)
            logger.info(f"Current milestone: {current_milestone.name} ({percentage_consumed:.2%} calories consumed)")
            
            # Try to get parameters from LLaMA
            parameters = self._generate_via_llm(
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
                milestone=self.get_milestone_from_percentage(request.consumedCalories / request.totalCalories if request.totalCalories > 0 else 0),
                total_calories=request.totalCalories,
                consumed_calories=request.consumedCalories,
                goal=request.goal
            )
    
    def _generate_via_llm(self, current_milestone: MilestoneType, total_calories: float, 
                         consumed_calories: float, percentage_consumed: float, 
                         goal: str, disliked_food_ids: List[str]) -> Optional[FoodParameterResponse]:
        """Generate food parameters using LLama model."""
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
            
            # Calculate remaining calories
            remaining_calories = total_calories - consumed_calories
            
            # Calculate default target calories
            default_target_calories = total_calories * self.milestone_calorie_percentage[current_milestone]
            default_target_calories = min(default_target_calories, remaining_calories)
            
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

FOLLOW INSTRUCTIONS CAREFULLY! Return ONLY in this JSON format:
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
    
    def _get_default_parameters(self, milestone: MilestoneType, total_calories: float, 
                               consumed_calories: float, goal: str) -> FoodParameterResponse:
        """Get default parameters if LLaMA fails."""
        from datetime import datetime
        
        # Calculate target calories
        target_calories = total_calories * self.milestone_calorie_percentage[milestone]
        remaining_calories = total_calories - consumed_calories
        target_calories = min(target_calories, remaining_calories)
        
        # Get default meal type
        meal_type = self.milestone_meal_types[milestone]
        
        # Get default macro ratios
        macro_ratios = self.goal_macro_ratios.get(goal, self.goal_macro_ratios["Improve Fitness"])
        
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
    
    def _generate_default_explanations(self, milestone: MilestoneType, goal: str, dietary_focus: str) -> List[str]:
        """Generate default explanations based on milestone and goal."""
        milestone_name = milestone.name.lower().replace('_', ' ')
        
        explanations_by_milestone = {
            MilestoneType.START: [
                f"A nutrient-dense breakfast helps kick-start your metabolism and provides energy for the day ahead.",
                f"Including protein in your breakfast helps control appetite throughout the morning.",
                f"Complex carbohydrates at breakfast provide sustained energy and help maintain stable blood sugar levels."
            ],
            MilestoneType.QUARTER: [
                f"A light mid-morning snack helps maintain energy levels between breakfast and lunch.",
                f"Choosing protein-rich snacks helps curb hunger and prevents overeating at lunch.",
                f"Including fiber in your snack promotes satiety and digestive health."
            ],
            MilestoneType.HALF: [
                f"A balanced lunch refuels your body for afternoon activities.",
                f"Including lean protein at lunch supports muscle maintenance and repair.",
                f"Complex carbohydrates provide sustained energy for the remainder of your workday."
            ],
            MilestoneType.THREE_QUARTERS: [
                f"A nutritious dinner completes your daily nutritional needs.",
                f"Including vegetables at dinner ensures you meet your micronutrient requirements.",
                f"Moderate portion sizes at dinner support quality sleep and recovery."
            ],
            MilestoneType.ALMOST_COMPLETE: [
                f"A light evening snack can help satisfy cravings without excess calories.",
                f"Protein-rich evening snacks support overnight muscle recovery.",
                f"Avoiding heavy meals close to bedtime promotes better sleep quality."
            ],
            MilestoneType.COMPLETED: [
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