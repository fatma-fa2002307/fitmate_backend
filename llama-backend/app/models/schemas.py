from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime

class WorkoutRequest(BaseModel):
    age: int
    gender: str
    height: int
    weight: int
    goal: str
    workoutDays: int
    fitnessLevel: str
    lastWorkoutCategory: Optional[str] = None

class Exercise(BaseModel):
    workout: str
    image: str
    sets: Optional[str] = None
    reps: Optional[str] = None
    instruction: Optional[str] = None
    # Cardio-specific fields
    duration: Optional[str] = None
    intensity: Optional[str] = None
    format: Optional[str] = None
    calories: Optional[str] = None
    description: Optional[str] = None
    is_cardio: Optional[bool] = False

class WorkoutResponse(BaseModel):
    workouts: List[Exercise]
    category: str

# Response model for multiple workout options
class WorkoutOptionsResponse(BaseModel):
    options: List[List[Dict[str, Any]]]  # List of workout option lists
    category: str