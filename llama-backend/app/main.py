from fastapi import FastAPI, HTTPException, Request
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
import os
from app.models.schemas import WorkoutRequest, WorkoutResponse, WorkoutOptionsResponse
from app.engine.workout import WorkoutEngine

app = FastAPI()

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

@app.post("/generate_workout/")
def generate_workout(data: WorkoutRequest):
    try:
        print(f"Received request data: {data}")
        engine = WorkoutEngine()
        print("Workout engine initialized")
        
        try:
            result = engine.generate_workout(data)
            print(f"Generated workout result: {result}")
            return result
        except Exception as e:
            print(f"Error in workout generation: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Workout generation failed: {str(e)}")
            
    except Exception as e:
        print(f"Error in endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/generate_workout_options/")
def generate_workout_options(data: WorkoutRequest):
    try:
        print(f"Received request for multiple workout options: {data}")
        engine = WorkoutEngine()
        
        try:
            # Generate 3 workout variations in a single Llama model call
            result = engine.generate_workout_options(data, num_options=3)
            print(f"Generated workout options: {result}")
            return result
        except Exception as e:
            print(f"Error in workout options generation: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Workout options generation failed: {str(e)}")
            
    except Exception as e:
        print(f"Error in endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/workout-images/{image_name}")
async def get_workout_image(image_name: str):
    try:
        # Convert URL-encoded spaces to hyphens
        formatted_name = image_name.replace("%20", "-")
        image_path = os.path.join(workout_images_dir, formatted_name)
        
        print(f"Attempting to serve image: {image_path}")
        
        if os.path.exists(image_path):
            return FileResponse(image_path)
        else:
            print(f"Image not found: {image_path}")
            raise HTTPException(status_code=404, detail="Image not found")
            
    except Exception as e:
        print(f"Error serving workout image: {str(e)}")
        raise HTTPException(status_code=404, detail=str(e))

@app.get("/workout-images/icons/{icon_name}")
async def get_icon_image(icon_name: str):
    try:
        # Convert URL-encoded spaces to hyphens
        formatted_name = icon_name.replace("%20", "-")
        icon_path = os.path.join(icons_dir, formatted_name)
        
        print(f"Attempting to serve icon: {icon_path}")
        
        if os.path.exists(icon_path):
            return FileResponse(icon_path)
        else:
            print(f"Icon not found: {icon_path}")
            raise HTTPException(status_code=404, detail="Icon not found")
            
    except Exception as e:
        print(f"Error serving icon: {str(e)}")
        raise HTTPException(status_code=404, detail=str(e))

# Middleware to log image requests
@app.middleware("http")
async def log_requests(request: Request, call_next):
    if "/workout-images/" in request.url.path:
        print(f"Image requested: {request.url.path}")
    response = await call_next(request)
    return response

# Verify directories exist
if not os.path.exists(workout_images_dir):
    print(f"Warning: Workout images directory does not exist at {workout_images_dir}")
    os.makedirs(workout_images_dir, exist_ok=True)
    print(f"Created workout images directory at {workout_images_dir}")

if not os.path.exists(icons_dir):
    print(f"Warning: Icons directory does not exist at {icons_dir}")
    os.makedirs(icons_dir, exist_ok=True)
    print(f"Created icons directory at {icons_dir}")