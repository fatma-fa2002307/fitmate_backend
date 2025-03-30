from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

# Workout-related schemas (existing)
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

# Food-related schemas (existing)
class MilestoneType(str, Enum):
    START = "START"              # 0% milestone
    QUARTER = "QUARTER"          # 25% milestone
    HALF = "HALF"                # 50% milestone 
    THREE_QUARTERS = "THREE_QUARTERS"  # 75% milestone
    ALMOST_COMPLETE = "ALMOST_COMPLETE"  # 90% milestone
    COMPLETED = "COMPLETED"      # 100%+ milestone 

# Food suggestion model
class FoodSuggestion(BaseModel):
    id: str
    title: str
    image: str
    calories: int
    protein: float
    carbs: float
    fat: float
    sourceUrl: Optional[str] = None
    readyInMinutes: Optional[int] = None
    servings: Optional[int] = None
    explanation: Optional[str] = None
    foodType: Optional[str] = None  # recipe, drink, or ingredient

# Input request model for food suggestions
class FoodSuggestionRequest(BaseModel):
    userId: str
    totalCalories: float
    consumedCalories: float
    goal: str  # User's fitness goal
    dislikedFoodIds: Optional[List[str]] = None

# Response model for food suggestions
class FoodSuggestionResponse(BaseModel):
    milestone: MilestoneType
    suggestions: List[FoodSuggestion]
    timestamp: datetime = datetime.now()

# Food parameter request model (existing)
class FoodParameterRequest(BaseModel):
    userId: str
    totalCalories: float
    consumedCalories: float
    goal: str  # User's fitness goal
    milestone: Optional[str] = None
    dislikedFoodIds: Optional[List[str]] = None

# Food parameter response model (existing)
class FoodParameterResponse(BaseModel):
    milestone: MilestoneType
    mealType: str  # breakfast, lunch, dinner, snack, etc.
    targetCalories: float
    macroRatios: Dict[str, float]  # protein, carbs, fat percentages
    explanations: List[str]  # Personalized nutritional explanations
    dietaryFocus: str  # e.g., "high-protein, low-carb"
    timestamp: datetime = datetime.now()

# Tip-related schemas (new)
class TipRequest(BaseModel):
    userId: str
    goal: str
    gender: Optional[str] = "Unspecified"
    fitnessLevel: Optional[str] = "Intermediate"
    workoutDays: Optional[int] = 3
    recentWorkouts: Optional[List[Dict[str, Any]]] = []
    foodLogs: Optional[List[Dict[str, Any]]] = []
    caloriePercentage: Optional[float] = 0.0