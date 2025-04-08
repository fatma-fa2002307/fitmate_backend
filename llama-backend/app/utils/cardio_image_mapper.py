from typing import Dict, List, Optional

class CardioImageMapper:
    """
    A utility class that maps cardio exercise names to appropriate image files.
    This class uses keyword matching to determine the most appropriate image for any cardio workout.
    """
    
    # Available cardio images
    CARDIO_IMAGES = {
        'bicycle': 'bicycle.webp',              # Outdoor cycling 
        'cardio': 'cardio.webp',                # Generic cardio machinery
        'exercise-bike': 'exercise-bike.webp',  # Indoor cycling
        'hiking': 'hiking.webp',                # Hiking/trail walking
        'jumping-rope': 'jumping-rope.webp',    # Jump rope activities
        'rowing': 'rowing.jpg',                 # Rowing activities
        'running': 'running.webp',              # Outdoor running/jogging
        'swimming': 'swimming.webp',            # Swimming/water activities
        'treadmill': 'treadmill.webp',          # Treadmill running
        'walking': 'walking.webp',              # Walking
        'squash': 'squash.jpg',                 # Squash
        'volleyball': 'volleyball.jpg',         # Volleyball
        'yoga': 'yoga.jpg',                     # Yoga
        'climbing-stairs': 'climbing-stairs.jpg', # Stair climbing
        'tennis': 'tennis.jpg',                 # Tennis
        'basketball': 'basketball.jpg',         # Basketball
        'football': 'football.jpg'              # Football/Soccer
    }
    
    # Keyword mappings to images - order matters (more specific first)
    KEYWORD_MAPPINGS = [
        # Water activities
        (['swim', 'pool', 'aqua', 'water', 'ocean', 'lake'], 'swimming'),
        
        # Running activities
        (['treadmill', 'indoor run'], 'treadmill'),
        (['sprint', 'jog', 'run', 'marathon', 'dash', '5k', '10k'], 'running'),
        
        # Walking activities
        (['stair', 'step', 'climber', 'stairmaster'], 'climbing-stairs'),
        (['hike', 'trek', 'trail'], 'hiking'),
        (['walk', 'stroll'], 'walking'),
        
        # Cycling activities
        (['spinning', 'stationary bike', 'exercise bike', 'indoor cycl', 'indoor bik'], 'exercise-bike'),
        (['cycl', 'bicycle', 'bike', 'biking'], 'bicycle'),
        
        # Jumping activities
        (['jump rope', 'skipping rope', 'jump', 'skipping'], 'jumping-rope'),
        
        # Rowing activities
        (['row', 'rower', 'rowing machine', 'ergometer'], 'rowing'),
        
        # Sports
        (['tennis', 'racket'], 'tennis'),
        (['basketball', 'hoops'], 'basketball'),
        (['football', 'soccer'], 'football'),
        (['squash'], 'squash'),
        (['volleyball', 'beach volleyball'], 'volleyball'),
        
        # Other
        (['yoga', 'stretch'], 'yoga'),
    ]
    
    # Default image to use if no match
    DEFAULT_IMAGE = 'cardio.webp'
    
    @classmethod
    def get_image_path(cls, exercise_name: str) -> str:
        """
        Maps a cardio exercise name to the most appropriate image file path.
        
        Args:
            exercise_name: The name of the cardio exercise
            
        Returns:
            The relative path to the most appropriate image
        """
        if not exercise_name:
            return f"/workout-images/cardio/{cls.DEFAULT_IMAGE}"
            
        exercise_lower = exercise_name.lower()
        
        # First check for direct matches with image keys
        for image_key in cls.CARDIO_IMAGES.keys():
            if image_key in exercise_lower:
                return f"/workout-images/cardio/{cls.CARDIO_IMAGES[image_key]}"
        
        # Then check for keyword matches
        for keywords, image_key in cls.KEYWORD_MAPPINGS:
            if any(keyword in exercise_lower for keyword in keywords):
                return f"/workout-images/cardio/{cls.CARDIO_IMAGES[image_key]}"
        
        # Default image if no match found
        return f"/workout-images/cardio/{cls.DEFAULT_IMAGE}"
    
    @classmethod
    def get_available_cardio_exercises(cls) -> List[Dict[str, str]]:
        """
        Returns a list of common cardio exercises with their appropriate images.
        Useful for providing examples to LLM-based workout generators.
        
        Returns:
            List of dictionaries with Title, Image, and Icon fields
        """
        cardio_exercises = [
            {"Title": "Treadmill Running", "Image": "treadmill.webp", "Icon": "cardio.webp"},
            {"Title": "Outdoor Running", "Image": "running.webp", "Icon": "cardio.webp"},
            {"Title": "Walking", "Image": "walking.webp", "Icon": "cardio.webp"},
            {"Title": "Hiking", "Image": "hiking.webp", "Icon": "cardio.webp"},
            {"Title": "Stair Climbing", "Image": "climbing-stairs.jpg", "Icon": "cardio.webp"},
            {"Title": "Cycling", "Image": "bicycle.webp", "Icon": "cardio.webp"},
            {"Title": "Exercise Bike", "Image": "exercise-bike.webp", "Icon": "cardio.webp"},
            {"Title": "Rowing Machine", "Image": "rowing.jpg", "Icon": "cardio.webp"},
            {"Title": "Jump Rope", "Image": "jumping-rope.webp", "Icon": "cardio.webp"},
            {"Title": "Swimming", "Image": "swimming.webp", "Icon": "cardio.webp"},
            {"Title": "Basketball", "Image": "basketball.jpg", "Icon": "cardio.webp"},
            {"Title": "Tennis", "Image": "tennis.jpg", "Icon": "cardio.webp"},
            {"Title": "Football", "Image": "football.jpg", "Icon": "cardio.webp"},
            {"Title": "Volleyball", "Image": "volleyball.jpg", "Icon": "cardio.webp"},
            {"Title": "Squash", "Image": "squash.jpg", "Icon": "cardio.webp"},
            {"Title": "Yoga", "Image": "yoga.jpg", "Icon": "cardio.webp"},
        ]
        return cardio_exercises