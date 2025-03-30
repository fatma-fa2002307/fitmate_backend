from fastapi import FastAPI, HTTPException, Request
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
import os
from datetime import datetime
from app.models.schemas import WorkoutRequest, FoodSuggestionRequest, FoodSuggestionResponse, TipRequest
from app.engine.workout import WorkoutEngine
from app.engine.food import EnhancedFoodEngine
from app.engine.tip import TipEngine
import logging

app = FastAPI()
logger = logging.getLogger(__name__)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Get base directory path
base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
workout_images_dir = os.path.join(base_dir, "data", "workout-images")
icons_dir = os.path.join(workout_images_dir, "icons")
cardio_images_dir = os.path.join(workout_images_dir, "cardio")
food_images_dir = os.path.join(base_dir, "data", "food-images")

# Initialize engines
workout_engine = WorkoutEngine()
enhanced_food_engine = EnhancedFoodEngine()
tip_engine = TipEngine()

# Create directories if they don't exist
for directory in [workout_images_dir, icons_dir, cardio_images_dir, food_images_dir]:
    os.makedirs(directory, exist_ok=True)

@app.post("/generate_workout_options/")
def generate_workout_options(data: WorkoutRequest):
    try:
        print(f"Received request for multiple workout options: {data}")
        
        try:
            # Generate workout variations based on user goals and preferences
            result = workout_engine.generate_workout_options(data, num_options=3)
            print(f"Generated workout options: {result}")
            return result
        except Exception as e:
            print(f"Error in workout options generation: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Workout options generation failed: {str(e)}")
            
    except Exception as e:
        print(f"Error in endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/generate_food_suggestions/")
async def generate_food_suggestions(data: FoodSuggestionRequest) -> FoodSuggestionResponse:
    """
    Generate personalized food suggestions using Spoonacular and LLaMA
    
    This endpoint combines the capabilities of the Spoonacular API with
    LLaMA's reasoning to provide personalized food recommendations based on
    the user's calorie consumption, goals, and preferences.
    """
    try:
        logger.info(f"Received food suggestion request for user {data.userId}")
        
        # Generate suggestions using the enhanced engine
        response = await enhanced_food_engine.generate_food_suggestions(data)
        
        logger.info(f"Generated {len(response.suggestions)} food suggestions for milestone: {response.milestone}")
        return response
        
    except Exception as e:
        logger.error(f"Error generating food suggestions: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Food suggestion generation failed: {str(e)}")

@app.post("/generate_personalized_tip/")
async def generate_personalized_tip(data: TipRequest):
    """
    Generate a personalized fitness or nutrition tip using LLaMA
    
    This endpoint provides contextual and personalized tips based on the
    user's goals, workout history, and nutrition data.
    """
    try:
        logger.info(f"Received tip request for user {data.userId}")
        
        # Convert Pydantic model to dict
        user_data = data.dict()
        
        # Generate tip using the tip engine
        response = await tip_engine.generate_personalized_tip(user_data)
        
        logger.info(f"Generated {response['category']} tip for user")
        return response
        
    except Exception as e:
        logger.error(f"Error generating tip: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Tip generation failed: {str(e)}")

@app.get("/workout-images/cardio/{image_name}")
async def get_cardio_image(image_name: str):
    try:
        # Convert URL-encoded spaces to hyphens for consistency
        formatted_name = image_name.replace("%20", "-")
        
        # Construct full path to the cardio image
        image_path = os.path.join(cardio_images_dir, formatted_name)
        
        if os.path.exists(image_path):
            return FileResponse(image_path)
        else:
            # Try to return a default image
            default_cardio = os.path.join(cardio_images_dir, "cardio.webp")
            if os.path.exists(default_cardio):
                return FileResponse(default_cardio)
            
            raise HTTPException(status_code=404, detail=f"Cardio image not found: {formatted_name}")
            
    except Exception as e:
        print(f"Error serving cardio image: {str(e)}")
        raise HTTPException(status_code=404, detail=str(e))

@app.get("/workout-images/{image_name}")
async def get_workout_image(image_name: str):
    try:
        # Convert URL-encoded spaces to hyphens
        formatted_name = image_name.replace("%20", "-")
        
        # First try in the main images directory
        image_path = os.path.join(workout_images_dir, formatted_name)
        
        if os.path.exists(image_path):
            return FileResponse(image_path)
        else:
            # Try to return a default image
            default_image = os.path.join(workout_images_dir, "default-icon.png")
            if os.path.exists(default_image):
                return FileResponse(default_image)
            
            raise HTTPException(status_code=404, detail=f"Image not found: {formatted_name}")
            
    except Exception as e:
        print(f"Error serving workout image: {str(e)}")
        raise HTTPException(status_code=404, detail=str(e))

@app.get("/workout-images/icons/{icon_name}")
async def get_icon_image(icon_name: str):
    try:
        # Convert URL-encoded spaces to hyphens
        formatted_name = icon_name.replace("%20", "-")
        icon_path = os.path.join(icons_dir, formatted_name)
        
        if os.path.exists(icon_path):
            return FileResponse(icon_path)
        else:
            # Try to serve a default icon if available
            default_icon = os.path.join(icons_dir, "default-icon.png")
            if os.path.exists(default_icon):
                return FileResponse(default_icon)
            
            raise HTTPException(status_code=404, detail=f"Icon not found: {formatted_name}")
            
    except Exception as e:
        print(f"Error serving icon: {str(e)}")
        raise HTTPException(status_code=404, detail=str(e))

# New endpoint to serve food images
@app.get("/food-images/{image_name}")
async def get_food_image(image_name: str):
    try:
        # Convert URL-encoded spaces to hyphens for consistency
        formatted_name = image_name.replace("%20", "-")
        
        # Construct full path to the food image
        image_path = os.path.join(food_images_dir, formatted_name)
        
        if os.path.exists(image_path):
            return FileResponse(image_path)
        else:
            # Try to return a default image
            default_image = os.path.join(food_images_dir, "default-food.jpg")
            if os.path.exists(default_image):
                return FileResponse(default_image)
            
            raise HTTPException(status_code=404, detail=f"Food image not found: {formatted_name}")
            
    except Exception as e:
        print(f"Error serving food image: {str(e)}")
        raise HTTPException(status_code=404, detail=str(e))