from flask import Flask, request, jsonify
import torch
import torchvision.transforms as transforms
from torchvision import models
from PIL import Image
import requests
import os

app = Flask(__name__)

MODEL_PATH = "resnet50model.pth"

model = models.resnet50(pretrained=True)
model.fc = torch.nn.Linear(model.fc.in_features, 101)

try:
    checkpoint = torch.load(MODEL_PATH, map_location=torch.device("cpu"), weights_only=False)
    if "model_state" in checkpoint:
        model.load_state_dict(checkpoint["model_state"])
    elif "state_dict" in checkpoint:
        model.load_state_dict(checkpoint["state_dict"])
    else:
        model.load_state_dict(checkpoint)
    model.eval()
    print("Model loaded successfully!")
except Exception as e:
    print("Error loading model:", e)

transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])

class_names = [
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

def predict_food(image_path):
    try:
        img = Image.open(image_path).convert("RGB")
        img = transform(img).unsqueeze(0)
        with torch.no_grad():
            outputs = model(img)
            probabilities = torch.nn.functional.softmax(outputs, dim=1)
            _, predicted = torch.max(outputs, 1)
       
            # Get the confidence score for the top prediction
            confidence_score = probabilities[0][predicted.item()].item()
        
            # Return both the predicted class and the confidence score
            return class_names[predicted.item()], confidence_score
    except Exception as e:
        return f"Error in prediction: {e}", 0.0

def get_nutritional_info(food_name):
    api_key = 'iPfFkObG0Lc4NwBdM8l58Bt3nipiy8aNmMGjm1CQ'
    food_name = food_name.replace('_', ' ')
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
                    return {'error': 'Food not found'}
            else:
                return {'error': 'API request failed'}
    else:
        return {'error': 'API request failed'}

@app.route('/recognize_food', methods=['POST'])
def recognize_food():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400
    image_file = request.files['image']
    image_path = os.path.join("uploads", image_file.filename)
    image_file.save(image_path)
    
    # Now receive both the food name and confidence score
    food_name, confidence = predict_food(image_path)
    
    if isinstance(food_name, str) and "Error" in food_name:
        return jsonify({'error': food_name}), 500
    
    nutritional_info = get_nutritional_info(food_name)
    if 'error' in nutritional_info:
        return jsonify({'error': nutritional_info['error']}), 500
    
    return jsonify({
        'food_name': food_name,
        'confidence': confidence,  # Include the confidence score in the response
        'nutritional_info': nutritional_info
    }), 200

if __name__ == '__main__':
    if not os.path.exists("uploads"):
        os.makedirs("uploads")
    app.run(host='0.0.0.0', port=5000, debug=True)