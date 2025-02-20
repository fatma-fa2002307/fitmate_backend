from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv
import openai
from app.models.schemas import WorkoutRequest, WorkoutResponse
from app.engine.workout import WorkoutEngine

# Load environment variables
load_dotenv()

# Set OpenAI API key
openai.api_key = os.getenv("OPENAI_API_KEY")

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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

# Mount static files for images
try:
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    icons_dir = os.path.join(base_dir, "data", "workout-images", "icons")
    print(f"Icons directory path: {icons_dir}")
    
    if not os.path.exists(icons_dir):
        print(f"Warning: Icons directory does not exist at {icons_dir}")
    
    app.mount("/workout-images/icons", StaticFiles(directory=icons_dir), name="icons")
except Exception as e:
    print(f"Error mounting static files: {str(e)}")