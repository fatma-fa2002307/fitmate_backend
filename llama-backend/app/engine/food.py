import ollama
import json
import logging
import random
import aiohttp
import asyncio
from typing import List, Dict, Any, Optional
from datetime import datetime
from app.models.schemas import FoodParameterRequest, FoodParameterResponse, MilestoneType, FoodSuggestion, FoodSuggestionRequest, FoodSuggestionResponse

# Configure logging
logging.basicConfig(level=logging.INFO, 
                    format='%(asctime)s [%(levelname)s] - %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger("enhanced_food_engine")

class SpoonacularService:
    """Service for interacting with the Spoonacular API"""
    
    def __init__(self, api_key="eb79020295ab472b9044cb370bceafd0"):
        self.api_key = api_key
        self.base_url = "https://api.spoonacular.com"
    
    async def search_recipes(self, min_calories=0, max_calories=2000, meal_type=None, 
                            diet=None, exclude_ingredients=None, number=10):
        """Search for recipes that match the given criteria"""
        try:
            params = {
                "apiKey": self.api_key,
                "number": number,
                "minCalories": min_calories,
                "maxCalories": max_calories,
                "addRecipeNutrition": "true",
                "sort": "random",
                "fillIngredients": "true",
            }
            
            if meal_type: params["type"] = meal_type
            if diet: params["diet"] = diet
            if exclude_ingredients: params["excludeIngredients"] = ",".join(exclude_ingredients)
                
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{self.base_url}/recipes/complexSearch", params=params) as response:
                    if response.status == 200:
                        data = await response.json()
                        return self._process_recipes(data)
                    else:
                        logger.error(f"Spoonacular API error: {response.status}")
                        return []
        except Exception as e:
            logger.error(f"Error searching recipes: {str(e)}")
            return []
            
    async def search_ingredients(self, min_calories=0, max_calories=500, number=10, query=None):
        """Search for simple food ingredients"""
        try:
            params = {
                "apiKey": self.api_key,
                "number": number,
                "minCalories": min_calories,
                "maxCalories": max_calories,
                "metaInformation": "true",
                "sort": "calories",
            }
            
            if query: params["query"] = query
                
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{self.base_url}/food/ingredients/search", params=params) as response:
                    if response.status == 200:
                        data = await response.json()
                        return await self._process_ingredients(data, session)
                    else:
                        logger.error(f"Spoonacular API error: {response.status}")
                        return []
        except Exception as e:
            logger.error(f"Error searching ingredients: {str(e)}")
            return []
    
    async def search_drinks(self, max_calories=300, number=5, query=None):
        """Search for drink options"""
        try:
            query = query or "tea OR coffee OR water OR herbal tea"
                
            params = {
                "apiKey": self.api_key,
                "number": number,
                "maxCalories": max_calories,
                "type": "drink",
                "query": query,
                "addRecipeNutrition": "true",
                "sort": "random",
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{self.base_url}/recipes/complexSearch", params=params) as response:
                    if response.status == 200:
                        data = await response.json()
                        return self._process_recipes(data, food_type="drink")
                    else:
                        logger.error(f"Spoonacular API error: {response.status}")
                        return []
        except Exception as e:
            logger.error(f"Error searching drinks: {str(e)}")
            return []
    
    def _process_recipes(self, data, food_type="recipe"):
        """Process recipe search results from Spoonacular"""
        processed_recipes = []
        
        if "results" not in data:
            return processed_recipes
            
        for recipe in data["results"]:
            try:
                # Extract nutrition information
                nutrition = {
                    "calories": 0,
                    "protein": 0,
                    "carbs": 0,
                    "fat": 0
                }
                
                if "nutrition" in recipe:
                    for nutrient in recipe["nutrition"]["nutrients"]:
                        name = nutrient["name"].lower()
                        if name == "calories":
                            nutrition["calories"] = int(nutrient["amount"])
                        elif name == "fat":
                            nutrition["fat"] = round(nutrient["amount"], 1)
                        elif name == "carbohydrates":
                            nutrition["carbs"] = round(nutrient["amount"], 1)
                        elif name == "protein":
                            nutrition["protein"] = round(nutrient["amount"], 1)
                
                # Create processed recipe
                processed_recipe = {
                    "id": str(recipe["id"]),
                    "title": recipe["title"],
                    "image": recipe["image"],
                    "sourceUrl": recipe.get("sourceUrl", ""),
                    "readyInMinutes": recipe.get("readyInMinutes", 0),
                    "servings": recipe.get("servings", 1),
                    "calories": nutrition["calories"],
                    "protein": nutrition["protein"],
                    "carbs": nutrition["carbs"],
                    "fat": nutrition["fat"],
                    "foodType": food_type
                }
                
                processed_recipes.append(processed_recipe)
            except Exception as e:
                logger.error(f"Error processing recipe: {str(e)}")
                continue
                
        return processed_recipes
        
    async def _process_ingredients(self, data, session):
        """Process ingredient search results"""
        processed_ingredients = []
        
        if "results" not in data:
            return processed_ingredients
            
        for ingredient in data["results"]:
            try:
                ingredient_id = ingredient["id"]
                nutrition = await self._get_ingredient_nutrition(ingredient_id, 100, session)
                
                processed_ingredient = {
                    "id": str(ingredient_id),
                    "title": ingredient["name"],
                    "image": f"https://spoonacular.com/cdn/ingredients_250x250/{ingredient.get('image', '')}",
                    "calories": nutrition.get("calories", 0),
                    "protein": nutrition.get("protein", 0),
                    "carbs": nutrition.get("carbs", 0),
                    "fat": nutrition.get("fat", 0),
                    "servingSize": "100g",
                    "foodType": "ingredient"
                }
                
                processed_ingredients.append(processed_ingredient)
            except Exception as e:
                logger.error(f"Error processing ingredient: {str(e)}")
                continue
                
        return processed_ingredients
        
    async def _get_ingredient_nutrition(self, ingredient_id, amount, session):
        """Get nutrition information for an ingredient"""
        try:
            params = {
                "apiKey": self.api_key,
                "amount": amount,
            }
            
            async with session.get(f"{self.base_url}/food/ingredients/{ingredient_id}/information", params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    nutrition = {}
                    
                    if "nutrition" in data:
                        for nutrient in data["nutrition"]["nutrients"]:
                            name = nutrient["name"].lower()
                            if name == "calories":
                                nutrition["calories"] = int(nutrient["amount"])
                            elif name == "fat":
                                nutrition["fat"] = round(nutrient["amount"], 1)
                            elif name == "carbohydrates":
                                nutrition["carbs"] = round(nutrient["amount"], 1)
                            elif name == "protein":
                                nutrition["protein"] = round(nutrient["amount"], 1)
                    
                    return nutrition
                else:
                    return {}
        except Exception as e:
            logger.error(f"Error getting ingredient nutrition: {str(e)}")
            return {}

class EnhancedFoodEngine:
    """Engine for generating personalized food suggestions using Spoonacular and LLaMA"""
    
    def __init__(self):
        self.spoonacular = SpoonacularService()
        
        self.milestone_calorie_percentage = {
            MilestoneType.START: 0.3,         # 30% for breakfast
            MilestoneType.QUARTER: 0.15,      # 15% for mid-morning snack
            MilestoneType.HALF: 0.3,          # 30% for lunch
            MilestoneType.THREE_QUARTERS: 0.2, # 20% for dinner
            MilestoneType.ALMOST_COMPLETE: 0.05, # 5% for evening snack
            MilestoneType.COMPLETED: 0.05     # 5% for ultra-low calorie options
        }
        
        self.milestone_meal_types = {
            MilestoneType.START: "breakfast",
            MilestoneType.QUARTER: "snack",
            MilestoneType.HALF: "main course",
            MilestoneType.THREE_QUARTERS: "main course",
            MilestoneType.ALMOST_COMPLETE: "snack",
            MilestoneType.COMPLETED: "snack"
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
            return MilestoneType.COMPLETED

    async def generate_food_suggestions(self, request: FoodSuggestionRequest) -> FoodSuggestionResponse:
        """Generate personalized food suggestions using Spoonacular and LLaMA"""
        try:
            # Calculate current milestone and consumption percentage
            consumed_calories = request.consumedCalories
            total_calories = request.totalCalories
            percentage_consumed = consumed_calories / total_calories if total_calories > 0 else 0
            
            current_milestone = self.get_milestone_from_percentage(percentage_consumed)
            logger.info(f"Current milestone: {current_milestone.name} ({percentage_consumed:.2%} calories consumed)")
            
            # Calculate target calories
            target_calories = self._calculate_target_calories(current_milestone, total_calories, consumed_calories)
            logger.info(f"Target calories: {target_calories}")
            
            # Get meal type and determine if user has reached calorie goal
            meal_type = self.milestone_meal_types[current_milestone]
            is_calorie_goal_reached = percentage_consumed >= 0.9  # 90% or more of daily calories
            
            # Gather food options 
            food_pool = await self._gather_food_options(
                target_calories=target_calories,
                meal_type=meal_type,
                goal=request.goal,
                disliked_food_ids=request.dislikedFoodIds or [],
                is_calorie_goal_reached=is_calorie_goal_reached
            )
            
            # Log the number of options
            logger.info(f"Gathered {len(food_pool)} food options from Spoonacular")
            
            if len(food_pool) == 0:
                logger.warning("No food options found from Spoonacular, generating fallback suggestions")
                # Generate minimal fallback suggestions
                fallback_suggestions = self._generate_fallback_suggestions(
                    is_calorie_goal_reached=is_calorie_goal_reached
                )
                return FoodSuggestionResponse(
                    milestone=current_milestone,
                    suggestions=fallback_suggestions,
                    timestamp=datetime.now()
                )
            
            # Use LLaMA to select and explain the best options
            selected_suggestions = await self._select_and_explain_with_llama(
                food_pool=food_pool,
                milestone=current_milestone,
                goal=request.goal,
                percentage_consumed=percentage_consumed,
                is_calorie_goal_reached=is_calorie_goal_reached
            )
            
            logger.info(f"Selected {len(selected_suggestions)} food suggestions with LLaMA")
            
            # Create response
            return FoodSuggestionResponse(
                milestone=current_milestone,
                suggestions=selected_suggestions,
                timestamp=datetime.now()
            )
            
        except Exception as e:
            logger.error(f"Error generating food suggestions: {str(e)}", exc_info=True)
            # Return simple fallback suggestions
            return FoodSuggestionResponse(
                milestone=self.get_milestone_from_percentage(percentage_consumed),
                suggestions=self._generate_fallback_suggestions(percentage_consumed >= 0.9),
                timestamp=datetime.now()
            )
    
    def _calculate_target_calories(self, milestone: MilestoneType, total_calories: float, consumed_calories: float) -> float:
        """Calculate target calories for the next meal"""
        percentage = self.milestone_calorie_percentage[milestone]
        target = total_calories * percentage
        remaining = max(0, total_calories - consumed_calories)
        adjusted_target = min(target, remaining)
        
        # For completed milestone, further limit calories
        if milestone == MilestoneType.COMPLETED:
            return min(50, adjusted_target)
            
        return adjusted_target
            
    async def _gather_food_options(self, target_calories: float, meal_type: str, goal: str, 
                                  disliked_food_ids: List[str], is_calorie_goal_reached: bool) -> List[Dict[str, Any]]:
        """Gather food options from Spoonacular based on parameters"""
        # Calculate calorie ranges
        min_calories = max(10, target_calories * 0.7) if not is_calorie_goal_reached else 0
        max_calories = target_calories * 1.3 if not is_calorie_goal_reached else 50
        
        # Determine diet focus based on goal
        diet = "low-calorie" if "loss" in goal.lower() else None
        if "muscle" in goal.lower():
            diet = "high-protein"
            
        # Prepare tasks for parallel API calls
        tasks = []
        
        # If user hasn't reached calorie goal, get recipes and ingredients
        if not is_calorie_goal_reached:
            tasks.extend([
                # Recipes
                self.spoonacular.search_recipes(
                    min_calories=min_calories,
                    max_calories=max_calories,
                    meal_type=meal_type,
                    diet=diet,
                    exclude_ingredients=disliked_food_ids,
                    number=10
                ),
                
                # Ingredients
                self.spoonacular.search_ingredients(
                    min_calories=min_calories,
                    max_calories=max_calories,
                    number=10
                )
            ])
        # If user has reached calorie goal, get drinks and low-calorie ingredients
        else:
            tasks.extend([
                # Zero/Low-calorie drinks (focused on tea)
                self.spoonacular.search_drinks(
                    max_calories=20,
                    number=10,
                    query="tea OR herbal tea OR green tea OR water OR zero calorie"
                ),
                
                # Low-calorie ingredients
                self.spoonacular.search_ingredients(
                    max_calories=30,
                    number=10,
                    query="vegetable OR fruit OR greens"
                )
            ])
            
        # Run all API calls in parallel
        results = await asyncio.gather(*tasks)
        
        # Combine results
        food_pool = []
        for result in results:
            food_pool.extend(result)
            
        return food_pool

    async def _select_and_explain_with_llama(self, food_pool: List[Dict[str, Any]], 
                                          milestone: MilestoneType, goal: str,
                                          percentage_consumed: float,
                                          is_calorie_goal_reached: bool) -> List[FoodSuggestion]:
        """Use LLaMA to select and explain the best food options"""
        try:
            # Prepare food pool data for LLaMA
            food_pool_data = []
            for i, food in enumerate(food_pool):
                food_data = {
                    "id": str(i),
                    "original_id": food["id"],
                    "title": food["title"],
                    "type": food["foodType"],
                    "calories": food["calories"],
                    "protein": food["protein"],
                    "carbs": food["carbs"],
                    "fat": food["fat"],
                }
                food_pool_data.append(food_data)
                
            milestone_names = {
                MilestoneType.START: "breakfast (morning)",
                MilestoneType.QUARTER: "mid-morning snack",
                MilestoneType.HALF: "lunch (mid-day meal)",
                MilestoneType.THREE_QUARTERS: "dinner (evening meal)",
                MilestoneType.ALMOST_COMPLETE: "evening snack",
                MilestoneType.COMPLETED: "zero/ultra-low calorie option"
            }
            
            # Determine selection criteria based on calorie goal status
            if is_calorie_goal_reached:
                selection_instruction = "Select ONLY zero or ultra-low calorie options since the user has reached or nearly reached their daily calorie goal."
                selection_format = """
   - Two zero/ultra-low calorie drinks (preferably tea-based)
   - Two low-calorie simple ingredient options"""
            else:
                selection_instruction = "Select a balanced mix of options appropriate for this meal context."
                selection_format = """
   - Two recipes appropriate for this meal context
   - Two simple ingredient options that complement the recipes"""
                
            # Calculate remaining calories
            remaining_percentage = 1.0 - percentage_consumed
            remaining_percentage_text = f"{remaining_percentage * 100:.1f}%"
                
            # Create prompt for LLaMA
            prompt = f"""As a nutrition AI, select the best food suggestions from the options below for the user.

USER CONTEXT:
- Current meal: {milestone_names[milestone]}
- Fitness goal: {goal}
- Calories consumed: {percentage_consumed:.0%} of daily goal
- Calories remaining: {remaining_percentage_text}

FOOD OPTIONS:
{json.dumps(food_pool_data, indent=2)}

INSTRUCTIONS:
1. {selection_instruction}
2. Select EXACTLY 4 options from the available foods:{selection_format}
3. For each selection, provide a short personalized explanation of why it's beneficial.
4. Return your selections in valid JSON format as shown below:

```json
{{
  "selections": [
    {{
      "food_id": "1",
      "explanation": "This protein-rich option supports your fitness goals."
    }},
    {{
      "food_id": "5",
      "explanation": "A nutrient-dense choice that provides essential vitamins."
    }},
    {{
      "food_id": "9",
      "explanation": "Zero-calorie option to keep you hydrated."
    }},
    {{
      "food_id": "12",
      "explanation": "Low-calorie ingredient with fiber to keep you satisfied."
    }}
  ]
}}
```

Respond ONLY with valid JSON in the exact format shown above.
"""

            # Call LLama model
            logger.info("Sending request to LLama model")
            response = ollama.chat(
                model="llama3.2",
                messages=[
                    {
                        "role": "system", 
                        "content": "You are a nutrition expert that selects and explains personalized food suggestions. Always respond with valid JSON in the requested format with no additional text."
                    },
                    {"role": "user", "content": prompt}
                ],
                options={"temperature": 0.7}
            )
            
            content = response['message']['content'].strip()
            
            # Extract JSON from response
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0].strip()
            elif "```" in content:
                content = content.split("```")[1].split("```")[0].strip()
                
            # Parse LLaMA selections
            try:
                selections_data = json.loads(content)
                selections = selections_data.get("selections", [])
            except json.JSONDecodeError:
                logger.error("Failed to parse LLaMA response as JSON")
                return self._select_random_options(food_pool, is_calorie_goal_reached)
            
            # Create list of selected suggestions
            selected_suggestions = []
            for selection in selections:
                try:
                    food_id = int(selection["food_id"])
                    if food_id < 0 or food_id >= len(food_pool):
                        continue
                        
                    food = food_pool[food_id]
                    
                    suggestion = FoodSuggestion(
                        id=food["id"],
                        title=food["title"],
                        image=food["image"],
                        calories=food["calories"],
                        protein=food["protein"],
                        carbs=food["carbs"],
                        fat=food["fat"],
                        sourceUrl=food.get("sourceUrl", ""),
                        readyInMinutes=food.get("readyInMinutes", 0),
                        servings=food.get("servings", 1),
                        explanation=selection["explanation"],
                        foodType=food.get("foodType", "")
                    )
                    
                    selected_suggestions.append(suggestion)
                except Exception as e:
                    logger.error(f"Error processing selection: {str(e)}")
                    continue
                    
            # If we didn't get enough suggestions, fill with random selections
            if len(selected_suggestions) < 4:
                logger.warning(f"Only got {len(selected_suggestions)} valid suggestions, filling with random selections")
                
                # Get IDs of already selected items
                selected_ids = [s.id for s in selected_suggestions]
                
                # Filter remaining food options
                remaining_options = [f for f in food_pool if f["id"] not in selected_ids]
                
                # Add random selections until we have 4
                while len(selected_suggestions) < 4 and remaining_options:
                    food = random.choice(remaining_options)
                    remaining_options.remove(food)
                    
                    explanation = self._generate_simple_explanation(food, is_calorie_goal_reached)
                    
                    suggestion = FoodSuggestion(
                        id=food["id"],
                        title=food["title"],
                        image=food["image"],
                        calories=food["calories"],
                        protein=food["protein"],
                        carbs=food["carbs"],
                        fat=food["fat"],
                        sourceUrl=food.get("sourceUrl", ""),
                        readyInMinutes=food.get("readyInMinutes", 0),
                        servings=food.get("servings", 1),
                        explanation=explanation,
                        foodType=food.get("foodType", "")
                    )
                    
                    selected_suggestions.append(suggestion)
            
            return selected_suggestions
            
        except Exception as e:
            logger.error(f"Error using LLaMA for selection: {str(e)}", exc_info=True)
            return self._select_random_options(food_pool, is_calorie_goal_reached)
            
    def _select_random_options(self, food_pool: List[Dict[str, Any]], 
                              is_calorie_goal_reached: bool) -> List[FoodSuggestion]:
        """Select random options if LLaMA fails"""
        if not food_pool:
            return self._generate_fallback_suggestions(is_calorie_goal_reached)
            
        # Categorize food options
        if is_calorie_goal_reached:
            # For calorie goal reached, prioritize drinks and ingredients
            drinks = [f for f in food_pool if f["foodType"] == "drink"]
            ingredients = [f for f in food_pool if f["foodType"] == "ingredient"]
            
            # Sort by calories (ascending)
            drinks = sorted(drinks, key=lambda x: x["calories"])
            ingredients = sorted(ingredients, key=lambda x: x["calories"])
            
            # Select options
            selected_foods = []
            
            # Add up to 2 drinks
            for i in range(min(2, len(drinks))):
                selected_foods.append(drinks[i])
                
            # Add up to 2 ingredients
            for i in range(min(2, len(ingredients))):
                selected_foods.append(ingredients[i])
                
            # If we still need more options, add any low-calorie options
            remaining_count = 4 - len(selected_foods)
            if remaining_count > 0:
                # Sort remaining options by calories
                remaining_options = [f for f in food_pool if f not in selected_foods]
                remaining_options = sorted(remaining_options, key=lambda x: x["calories"])
                
                # Add lowest calorie options
                for i in range(min(remaining_count, len(remaining_options))):
                    selected_foods.append(remaining_options[i])
        else:
            # For normal meals, prioritize recipes and ingredients
            recipes = [f for f in food_pool if f["foodType"] == "recipe"]
            ingredients = [f for f in food_pool if f["foodType"] == "ingredient"]
            
            # Select options
            selected_foods = []
            
            # Add up to 2 recipes
            for i in range(min(2, len(recipes))):
                selected_foods.append(random.choice(recipes))
                recipes.remove(selected_foods[-1])
                
            # Add up to 2 ingredients
            for i in range(min(2, len(ingredients))):
                selected_foods.append(random.choice(ingredients))
                ingredients.remove(selected_foods[-1])
                
            # If we still need more options, add any available options
            remaining_count = 4 - len(selected_foods)
            if remaining_count > 0:
                remaining_options = [f for f in food_pool if f not in selected_foods]
                
                for i in range(min(remaining_count, len(remaining_options))):
                    selected_foods.append(random.choice(remaining_options))
                    remaining_options.remove(selected_foods[-1])
                    
        # Convert to FoodSuggestion objects
        suggestions = []
        for food in selected_foods:
            explanation = self._generate_simple_explanation(food, is_calorie_goal_reached)
            
            suggestion = FoodSuggestion(
                id=food["id"],
                title=food["title"],
                image=food["image"],
                calories=food["calories"],
                protein=food["protein"],
                carbs=food["carbs"],
                fat=food["fat"],
                sourceUrl=food.get("sourceUrl", ""),
                readyInMinutes=food.get("readyInMinutes", 0),
                servings=food.get("servings", 1),
                explanation=explanation,
                foodType=food.get("foodType", "")
            )
            
            suggestions.append(suggestion)
            
        # If we still don't have enough, add fallbacks
        if len(suggestions) < 4:
            fallbacks = self._generate_fallback_suggestions(is_calorie_goal_reached)
            suggestions.extend(fallbacks[:(4 - len(suggestions))])
            
        return suggestions
    
    def _generate_simple_explanation(self, food: Dict[str, Any], is_calorie_goal_reached: bool) -> str:
        """Generate a simple explanation for a food option"""
        if is_calorie_goal_reached:
            if food["foodType"] == "drink" and food["calories"] <= 5:
                return "Zero-calorie beverage to keep you hydrated without adding calories."
            else:
                return f"Low-calorie option with only {food['calories']} calories."
        else:
            if food["foodType"] == "recipe":
                if food["protein"] > 15:
                    return f"Protein-rich recipe with {food['protein']}g of protein."
                else:
                    return f"Balanced recipe with {food['calories']} calories."
            elif food["foodType"] == "ingredient":
                return f"Nutritious ingredient with {food['calories']} calories."
            else:
                return f"Healthy option with {food['calories']} calories."
                
    def _generate_fallback_suggestions(self, is_calorie_goal_reached: bool) -> List[FoodSuggestion]:
        """Generate minimal fallback suggestions when no options are available"""
        current_date = datetime.now().timestamp()
        
        if is_calorie_goal_reached:
            # Ultra-low calorie options
            return [
                FoodSuggestion(
                    id=f"fallback_tea_{current_date}",
                    title="Green Tea",
                    image="https://spoonacular.com/cdn/ingredients_250x250/green-tea.jpg",
                    calories=0,
                    protein=0,
                    carbs=0,
                    fat=0,
                    explanation="Zero-calorie tea that keeps you hydrated without affecting your calorie intake.",
                    foodType="drink"
                ),
                FoodSuggestion(
                    id=f"fallback_water_{current_date}",
                    title="Herbal Tea",
                    image="https://spoonacular.com/cdn/ingredients_250x250/tea-bags.jpg",
                    calories=0,
                    protein=0,
                    carbs=0,
                    fat=0,
                    explanation="Caffeine-free herbal tea with zero calories.",
                    foodType="drink"
                ),
                FoodSuggestion(
                    id=f"fallback_celery_{current_date}",
                    title="Celery",
                    image="https://spoonacular.com/cdn/ingredients_250x250/celery.jpg",
                    calories=10,
                    protein=0.4,
                    carbs=1.9,
                    fat=0.1,
                    explanation="Very low calorie vegetable with high water content.",
                    foodType="ingredient"
                ),
                FoodSuggestion(
                    id=f"fallback_cucumber_{current_date}",
                    title="Cucumber",
                    image="https://spoonacular.com/cdn/ingredients_250x250/cucumber.jpg",
                    calories=8,
                    protein=0.3,
                    carbs=1.5,
                    fat=0.1,
                    explanation="Hydrating vegetable with minimal calories and refreshing taste.",
                    foodType="ingredient"
                )
            ]
        else:
            # Basic balanced options
            return [
                FoodSuggestion(
                    id=f"fallback_oatmeal_{current_date}",
                    title="Oatmeal",
                    image="https://spoonacular.com/recipeImages/715544-312x231.jpg",
                    calories=150,
                    protein=5,
                    carbs=27,
                    fat=3,
                    explanation="Balanced meal with slow-release carbohydrates for sustained energy.",
                    foodType="recipe"
                ),
                FoodSuggestion(
                    id=f"fallback_eggs_{current_date}",
                    title="Eggs",
                    image="https://spoonacular.com/recipeImages/123456-312x231.jpg",
                    calories=140,
                    protein=12,
                    carbs=1,
                    fat=10,
                    explanation="High-protein option that supports muscle maintenance and recovery.",
                    foodType="recipe"
                ),
                FoodSuggestion(
                    id=f"fallback_apple_{current_date}",
                    title="Apple",
                    image="https://spoonacular.com/cdn/ingredients_250x250/apple.jpg",
                    calories=95,
                    protein=0.5,
                    carbs=25,
                    fat=0.3,
                    explanation="Natural source of fiber and vitamins with moderate calorie content.",
                    foodType="ingredient"
                ),
                FoodSuggestion(
                    id=f"fallback_nuts_{current_date}",
                    title="Almonds",
                    image="https://spoonacular.com/cdn/ingredients_250x250/almonds.jpg",
                    calories=165,
                    protein=6,
                    carbs=6,
                    fat=14,
                    explanation="Nutrient-dense source of healthy fats and protein.",
                    foodType="ingredient"
                )
            ]