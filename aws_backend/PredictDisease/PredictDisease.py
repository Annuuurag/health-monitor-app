import json
import os
import pickle
import numpy as np

# Path to model files (placed in the same folder during build)
MODEL_PATH = os.path.join(os.path.dirname(__file__), 'prediction_model.pkl')
SCALER_PATH = os.path.join(os.path.dirname(__file__), 'heart_scaler.pkl')

# Global variables for caching model and scaler in warm container
disease_model = None
disease_scaler = None

def load_models():
    global disease_model, disease_scaler
    if disease_model is None or disease_scaler is None:
        print("Loading disease prediction models from disk...")
        with open(MODEL_PATH, 'rb') as f:
            disease_model = pickle.load(f)
        with open(SCALER_PATH, 'rb') as f:
            disease_scaler = pickle.load(f)

def handler(event, context):
    print("Received event:", json.dumps(event))
    
    # Handle CORS preflight
    if event.get('httpMethod') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': ''
        }

    try:
        # Load body
        body_str = event.get('body', '{}')
        body = json.loads(body_str) if body_str else {}
        
        # Define the 13 required clinical features (matching Cleveland dataset)
        # 1. age (years)
        # 2. sex (1 = male; 0 = female)
        # 3. cp (chest pain type: 1 = typical angina, 2 = atypical, 3 = non-anginal, 4 = asymptomatic)
        # 4. trestbps (resting blood pressure in mm Hg)
        # 5. chol (serum cholesterol in mg/dl)
        # 6. fbs (fasting blood sugar > 120 mg/dl: 1 = true; 0 = false)
        # 7. restecg (resting electrocardiographic results: 0, 1, 2)
        # 8. thalach (maximum heart rate achieved)
        # 9. exang (exercise induced angina: 1 = yes; 0 = no)
        # 10. oldpeak (ST depression induced by exercise relative to rest)
        # 11. slope (the slope of the peak exercise ST segment: 1 = upsloping, 2 = flat, 3 = downsloping)
        # 12. ca (number of major vessels colored by flourosopy: 0-3)
        # 13. thal (3 = normal; 6 = fixed defect; 7 = reversable defect)
        
        required_features = [
            "age", "sex", "cp", "trestbps", "chol",
            "fbs", "restecg", "thalach", "exang",
            "oldpeak", "slope", "ca", "thal"
        ]
        
        # Populate input list, providing reasonable normal defaults for missing parameters
        input_data = []
        defaults = {
            "age": 45.0, "sex": 1.0, "cp": 3.0, "trestbps": 120.0, "chol": 200.0,
            "fbs": 0.0, "restecg": 1.0, "thalach": 150.0, "exang": 0.0,
            "oldpeak": 0.0, "slope": 1.0, "ca": 0.0, "thal": 3.0
        }
        
        for feature in required_features:
            val = body.get(feature)
            if val is None:
                val = defaults[feature]
            input_data.append(float(val))
            
        # Reshape for inference (1, 13)
        input_array = np.array([input_data])
        
        # Load model & scale input
        load_models()
        input_scaled = disease_scaler.transform(input_array)
        
        # Compute risk probability (Soft-Voting Stacking Ensemble)
        prob = disease_model.predict_proba(input_scaled)[0][1] # Probability of Class 1 (Heart Disease)
        pred = int(disease_model.predict(input_scaled)[0])
        
        risk_pct = prob * 100
        
        # Map output details
        if risk_pct >= 70:
            severity = "High Risk"
            suggestion = "Based on clinical factors, the ensemble identifies high indicators for heart disease. We strongly suggest consulting a cardiologist for a complete screening."
        elif risk_pct >= 40:
            severity = "Moderate Risk"
            suggestion = "Biometrics fall in a moderate risk zone. Consider updating diet, monitoring blood pressure daily, and discussing these vitals with your practitioner."
        else:
            severity = "Low Risk"
            suggestion = "Clinical values are within healthy limits. Keep maintaining a balanced diet and tracking your daily vitals."
            
        response_body = {
            'riskProbability': float(prob),
            'riskPercentage': float(round(risk_pct, 2)),
            'prediction': pred,
            'riskLabel': severity,
            'suggestion': suggestion
        }
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps(response_body)
        }
        
    except Exception as e:
        print("Error during disease prediction:", str(e))
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({'error': str(e)})
        }
