from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

# Existing schema
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

# New schemas for food suggestions
class MilestoneType(str, Enum):
    START = "START"              # 0% milestone
    QUARTER = "QUARTER"          # 25% milestone
    HALF = "HALF"                # 50% milestone 
    THREE_QUARTERS = "THREE_QUARTERS"  # 75% milestone
    ALMOST_COMPLETE = "ALMOST_COMPLETE"  # 90% milestone
    COMPLETED = "COMPLETED"      # 100%+ milestone 


class FoodSuggestion(BaseModel):
    id: str
    title: str
    image: str
    calories: int
    protein: float
    carbs: float
    fat: float

class FoodSuggestionRequest(BaseModel):
    userId: str
    totalCalories: float
    consumedCalories: float
    goal: str  # User's fitness goal
    dislikedFoodIds: Optional[List[str]] = None

class FoodSuggestionResponse(BaseModel):
    milestone: MilestoneType
    suggestions: List[FoodSuggestion]
    timestamp: datetime = datetime.now()