import torch
import torchvision.transforms as transforms
from torchvision import models
from PIL import Image
import requests
import os
import logging
from typing import Tuple, Dict, Any, Optional

# Configure logging
logging.basicConfig(level=logging.INFO, 
                   format='%(asctime)s [%(levelname)s] - %(message)s',
                   datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger("food_recognition_engine")

class FoodRecognitionEngine:
    """Engine for recognizing food from images using ResNet50 model"""
    
    def __init__(self, model_path: str = "data/models/resnet50model.pth"):
        self.model_path = model_path
        self.model = None
        self.transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ])
        
        # Check if CUDA is available
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu") #GPU
        #self.device = torch.device("cpu")

        logger.info(f"Using device: {self.device}")
        
        # Food101 class names
        self.class_names = [
            "apple_pie", "baby_back_ribs", "baklava", "beef_carpaccio", "beef_tartare",
            "beet_salad", "beignets", "bibimbap", "bread_pudding", "breakfast_burrito",
            "bruschetta", "caesar_salad", "cannoli", "caprese_salad", "carrot_cake",
            "ceviche", "cheesecake", "cheese_plate", "chicken_curry", "chicken_quesadilla",
            "chicken_wings", "chocolate_cake", "chocolate_mousse", "churros", "clam_chowder",
            "club_sandwich", "crab_cakes", "creme_brulee", "croque_madame", "cup_cakes",
            "deviled_eggs", "donuts", "dumplings", "edamame", "eggs_benedict",
            "escargots", "falafel", "filet_mignon", "fish_and_chips", "foie_gras",
            "french_fries", "french_onion_soup", "french_toast", "fried_calamari",
            "fried_rice", "frozen_yogurt", "garlic_bread", "gnocchi", "greek_salad",
            "grilled_cheese_sandwich", "grilled_salmon", "guacamole", "gyoza", "hamburger",
            "hot_and_sour_soup", "hot_dog", "huevos_rancheros", "hummus", "ice_cream",
            "lasagna", "lobster_bisque", "lobster_roll_sandwich", "macaroni_and_cheese",
            "macarons", "miso_soup", "mussels", "nachos", "omelette",
            "onion_rings", "oysters", "pad_thai", "paella", "pancakes",
            "panna_cotta", "peking_duck", "pho", "pizza", "pork_chop",
            "poutine", "prime_rib", "pulled_pork_sandwich", "ramen", "ravioli",
            "red_velvet_cake", "risotto", "samosa", "sashimi", "scallops",
            "seaweed_salad", "shrimp_and_grits", "spaghetti_bolognese", "spaghetti_carbonara",
            "spring_rolls", "steak", "strawberry_shortcake", "sushi", "tacos",
            "takoyaki", "tiramisu", "tuna_tartare", "waffles"
        ]
        
        # Load the model
        self._load_model()
        
        # Ensure uploads directory exists
        os.makedirs("data/uploads", exist_ok=True)
    
    def _load_model(self):
        """Load the ResNet50 model with Food101 weights"""
        try:
            # Initialize model architecture
            self.model = models.resnet50(pretrained=True)
            self.model.fc = torch.nn.Linear(self.model.fc.in_features, 101)  # 101 food classes
            
            # Load weights
            logger.info(f"Loading model from {self.model_path}")
            
            # Map to appropriate device when loading
            map_location = self.device
            checkpoint = torch.load(self.model_path, map_location=map_location, weights_only=False)
            
            # Handle different checkpoint formats
            if "model_state" in checkpoint:
                self.model.load_state_dict(checkpoint["model_state"])
            elif "state_dict" in checkpoint:
                self.model.load_state_dict(checkpoint["state_dict"])
            else:
                self.model.load_state_dict(checkpoint)
                
            # Move model to GPU if available
            self.model = self.model.to(self.device)
                
            # Set to evaluation mode
            self.model.eval()
            logger.info(f"Food recognition model loaded successfully on {self.device}!")
            
            # Print GPU memory usage if using CUDA
            if self.device.type == 'cuda':
                logger.info(f"GPU Memory allocated: {torch.cuda.memory_allocated(self.device)/1024**2:.2f} MB")
                logger.info(f"GPU Memory reserved: {torch.cuda.memory_reserved(self.device)/1024**2:.2f} MB")
            
        except Exception as e:
            logger.error(f"Error loading food recognition model: {str(e)}", exc_info=True)
            self.model = None
    
    def predict_food(self, image_path: str) -> Tuple[str, float]:
        """
        Predict food type from an image
        
        Args:
            image_path: Path to the food image
            
        Returns:
            Tuple of (food_name, confidence_score)
        """
        try:
            if self.model is None:
                return "Error: Model not loaded", 0.0
                
            # Open and preprocess image
            img = Image.open(image_path).convert("RGB")
            img_tensor = self.transform(img).unsqueeze(0)
            
            # Move tensor to appropriate device
            img_tensor = img_tensor.to(self.device)
            
            # Make prediction
            with torch.no_grad():
                outputs = self.model(img_tensor)
                probabilities = torch.nn.functional.softmax(outputs, dim=1)
                _, predicted = torch.max(outputs, 1)
                
                # Get confidence score
                confidence_score = probabilities[0][predicted.item()].item()
                predicted_class = self.class_names[predicted.item()]
                
                logger.info(f"Predicted food: {predicted_class} with confidence: {confidence_score:.4f}")
                return predicted_class, confidence_score
                
        except Exception as e:
            logger.error(f"Error in food prediction: {str(e)}", exc_info=True)
            return f"Error in prediction: {str(e)}", 0.0
    
    def get_nutritional_info(self, food_name: str) -> Dict[str, Any]:
        """
        Get nutritional information for a food using USDA Food Data Central API
        
        Args:
            food_name: Name of the food to look up
            
        Returns:
            Dictionary with nutritional information
        """
        try:
            # API key for USDA Food Data Central
            api_key = 'iPfFkObG0Lc4NwBdM8l58Bt3nipiy8aNmMGjm1CQ'
            
            # Format food name
            food_name = food_name.replace('_', ' ')
            logger.info(f"Getting nutritional information for: {food_name}")
            
            # First try: Direct food lookup by name
            fdc_id_url = f"https://api.nal.usda.gov/fdc/v1/food/{food_name}?api_key={api_key}"
            fdc_id_response = requests.get(fdc_id_url)
            
            if fdc_id_response.status_code == 200:
                fdc_id_data = fdc_id_response.json()
                if 'error' not in fdc_id_data:
                    nutrients = {n['nutrientName']: n['value'] for n in fdc_id_data['foodNutrients']}
                    return {
                        'Food Name': fdc_id_data.get('description', 'N/A'),
                        'Calories': nutrients.get('Energy', 'N/A'),
                        'Protein': nutrients.get('Protein', 'N/A'),
                        'Carbs': nutrients.get('Carbohydrate, by difference', 'N/A'),
                        'Fats': nutrients.get('Total lipid (fat)', 'N/A')
                    }
            
            # Second try: Search for the food
            search_url = f"https://api.nal.usda.gov/fdc/v1/foods/search?api_key={api_key}&query={food_name}"
            search_response = requests.get(search_url)
            
            if search_response.status_code == 200:
                search_data = search_response.json()
                
                if search_data['foods']:
                    food = search_data['foods'][0]
                    nutrients = {n['nutrientName']: n['value'] for n in food['foodNutrients']}
                    return {
                        'Food Name': food.get('description', 'N/A'),
                        'Calories': nutrients.get('Energy', 'N/A'),
                        'Protein': nutrients.get('Protein', 'N/A'),
                        'Carbs': nutrients.get('Carbohydrate, by difference', 'N/A'),
                        'Fats': nutrients.get('Total lipid (fat)', 'N/A')
                    }
                else:
                    # Third try: Just use the first word of the food name
                    first_word = food_name.split()[0]
                    search_url = f"https://api.nal.usda.gov/fdc/v1/foods/search?api_key={api_key}&query={first_word}"
                    search_response = requests.get(search_url)
                    
                    if search_response.status_code == 200:
                        search_data = search_response.json()
                        
                        if search_data['foods']:
                            food = search_data['foods'][0]
                            nutrients = {n['nutrientName']: n['value'] for n in food['foodNutrients']}
                            return {
                                'Food Name': food.get('description', 'N/A'),
                                'Calories': nutrients.get('Energy', 'N/A'),
                                'Protein': nutrients.get('Protein', 'N/A'),
                                'Carbs': nutrients.get('Carbohydrate, by difference', 'N/A'),
                                'Fats': nutrients.get('Total lipid (fat)', 'N/A')
                            }
                        else:
                            logger.warning(f"No food data found for: {food_name}")
                            return {'error': 'Food not found'}
                    else:
                        logger.error(f"API request failed with status: {search_response.status_code}")
                        return {'error': 'API request failed'}
            else:
                logger.error(f"API request failed with status: {search_response.status_code}")
                return {'error': 'API request failed'}
                
        except Exception as e:
            logger.error(f"Error getting nutritional information: {str(e)}", exc_info=True)
            return {'error': str(e)}
            
    def process_food_image(self, image_file, filename: str) -> Dict[str, Any]:
        """
        Process a food image file and return recognition results with nutritional info
        
        Args:
            image_file: The uploaded image file object
            filename: The filename to save the image as
            
        Returns:
            Dictionary with recognition results and nutritional information
        """
        try:
            # Save the uploaded image
            upload_dir = "data/uploads"
            os.makedirs(upload_dir, exist_ok=True)
            image_path = os.path.join(upload_dir, filename)
            
            # Save the file
            with open(image_path, "wb") as f:
                f.write(image_file.read())
            
            # Predict food type
            food_name, confidence = self.predict_food(image_path)
            
            # Check for prediction errors
            if isinstance(food_name, str) and "Error" in food_name:
                logger.error(f"Food prediction error: {food_name}")
                return {'error': food_name}
            
            # Get nutritional information
            nutritional_info = self.get_nutritional_info(food_name)
            
            # Return combined results
            return {
                'food_name': food_name,
                'confidence': confidence,
                'nutritional_info': nutritional_info
            }
            
        except Exception as e:
            logger.error(f"Error processing food image: {str(e)}", exc_info=True)
            return {'error': str(e)}