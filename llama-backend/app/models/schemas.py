from pydantic import BaseModel
from typing import Optional, List
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
    sets: str
    reps: str
    instruction: str

class WorkoutResponse(BaseModel):
    workouts: List[Exercise]
    category: str