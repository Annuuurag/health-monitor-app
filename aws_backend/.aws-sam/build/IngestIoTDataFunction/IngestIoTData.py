import json
import os
import pickle
import numpy as np
import boto3
from decimal import Decimal

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('TABLE_NAME', 'HealthTelemetrySummaries')
table = dynamodb.Table(TABLE_NAME)

# Path to model files (placed in the same folder during build)
MODEL_PATH = os.path.join(os.path.dirname(__file__), 'anomaly_model.pkl')
SCALER_PATH = os.path.join(os.path.dirname(__file__), 'anomaly_scaler.pkl')

# Global variables for caching model and scaler in warm container
anomaly_model = None
anomaly_scaler = None

# Define EnsembleDetector class so it can be resolved during unpickling
class EnsembleDetector:
    def __init__(self, models):
        self.models = models

    def predict(self, X):
        preds = np.stack([m.predict(X) for m in self.models], axis=1)
        anomaly_votes = np.sum(preds == -1, axis=1)
        final_preds = np.where(anomaly_votes >= 2, -1, 1)
        return final_preds

    def decision_function(self, X):
        if_scores = self.models[0].decision_function(X)
        svm_scores = self.models[1].score_samples(X)
        svm_scores_scaled = (svm_scores - svm_scores.mean()) / (svm_scores.std() + 1e-8) * 0.1
        return (if_scores + svm_scores_scaled) / 2.0

class CustomUnpickler(pickle.Unpickler):
    def find_class(self, module, name):
        if name == 'EnsembleDetector':
            return EnsembleDetector
        return super().find_class(module, name)

def load_models():
    global anomaly_model, anomaly_scaler
    if anomaly_model is None or anomaly_scaler is None:
        print("Loading anomaly detection models from disk...")
        with open(MODEL_PATH, 'rb') as f:
            anomaly_model = CustomUnpickler(f).load()
        with open(SCALER_PATH, 'rb') as f:
            anomaly_scaler = pickle.load(f)

def calculate_stats(values):
    """Calculate skewness and kurtosis manually to avoid scipy dependency"""
    n = len(values)
    if n < 3:
        # Default baselines from WISDM/PPG typical distributions
        return 0.70, -0.75
    
    mean = np.mean(values)
    std = np.std(values, ddof=1)
    if std < 1e-6:
        return 0.0, 0.0
        
    # Skewness: E[(X - mu)^3] / std^3
    skew = np.sum((values - mean)**3) / (n * (std**3))
    
    # Kurtosis: E[(X - mu)^4] / std^4 - 3 (excess kurtosis)
    kurt = np.sum((values - mean)**4) / (n * (std**4)) - 3
    
    return float(skew), float(kurt)

def float_to_decimal(val):
    """Convert float values to Decimal for DynamoDB storage compatibility"""
    return Decimal(str(round(val, 2)))

def handler(event, context):
    print("Received event:", json.dumps(event))
    
    try:
        # Extract readings list (supports batching from IoT Core)
        readings = []
        if isinstance(event, list):
            readings = event
        elif isinstance(event, dict):
            if 'data' in event:
                if isinstance(event['data'], list):
                    readings = event['data']
                else:
                    readings = [event['data']]
            else:
                readings = [event]
        else:
            readings = [event]
            
        if not readings:
            return {'statusCode': 200, 'body': 'No telemetry data to process'}

        # Calculate averages and lists for statistics
        # Only include HR/SpO2 from readings where finger is present AND value > 0
        # (ESP sends hr=0, spo2=0 when no finger detected — must exclude these)
        hr_list, spo2_list, temp_list = [], [], []
        
        for r in readings:
            finger_on = str(r.get('finger', 'true')).lower() == 'true'
            hr_val = float(r['hr']) if r.get('hr') is not None else 0.0
            spo2_val = float(r['spo2']) if r.get('spo2') is not None else 0.0

            # Only average HR / SpO2 when finger is detected and value is non-zero
            if finger_on and hr_val > 0:
                hr_list.append(hr_val)
            if finger_on and spo2_val > 0:
                spo2_list.append(spo2_val)
            if r.get('temp') is not None:
                temp_list.append(float(r['temp']))
                
        # Convert numpy types to Python native types for DynamoDB compatibility
        # (numpy.float64 comparisons return numpy.bool_ which DynamoDB cannot serialize)
        avg_hr   = float(np.mean(hr_list))   if hr_list   else 0.0
        avg_spo2 = float(np.mean(spo2_list)) if spo2_list else 0.0
        avg_temp = float(np.mean(temp_list)) if temp_list else 36.5
        
        # Calculate HRV (RMSSD of heart rate if multiple readings, else baseline)
        if len(hr_list) > 1:
            diffs = np.diff(hr_list)
            hrv = np.sqrt(np.mean(diffs ** 2))
            std_hr = np.std(hr_list)
            min_hr = np.min(hr_list)
            max_hr = np.max(hr_list)
            skew, kurt = calculate_stats(hr_list)
        else:
            hrv = 0.12
            std_hr = 2.5
            min_hr = avg_hr - 2.0
            max_hr = avg_hr + 2.0
            skew, kurt = 0.70, -0.75
            
        # Standardize baseline PPG-like features for anomaly input vector
        # features list: [HR, HRV, Mean, Std, Min, Max, Skewness, Kurtosis, DominantFreq, SpectralEntropy]
        mean_sig = 0.52   # normalized baseline mean
        min_sig = 0.32    # normalized baseline min
        max_sig = 0.83    # normalized baseline max
        dom_freq = 1.6    # dominant frequency constant
        spec_entropy = 3.6  # spectral entropy constant
        
        # Assemble input feature vector
        features_vector = np.array([[
            avg_hr,
            hrv,
            mean_sig,
            std_hr,
            min_sig,
            max_sig,
            skew,
            kurt,
            dom_freq,
            spec_entropy
        ]])
        
        # Extract steps and finger detection status
        # Default finger_detected to False — only set True if explicitly sent as true
        steps = 0
        finger_detected = False
        
        # Prefer reading from the sensor data dict (readings[0])
        if readings:
            r0 = readings[0]
            finger_val = r0.get('finger')
            if finger_val is not None:
                finger_detected = (finger_val is True) or (str(finger_val).lower() == 'true')
            # Fall back to checking root event
            elif 'finger' in event:
                fv = event['finger']
                finger_detected = (fv is True) or (str(fv).lower() == 'true')
            
            # Steps: prefer root event (ESP sends it at root level)
            if 'steps' in event:
                try:
                    steps = int(event['steps'])
                except:
                    pass
            elif 'steps' in r0:
                try:
                    steps = int(r0['steps'])
                except:
                    pass
            
        # Load models and predict only if finger is detected
        if not finger_detected:
            is_anomaly = False
            overall_status = "Normal"
            summary_text = "Wearable active. Place finger on sensor for vitals."
            avg_hr = 0.0
            avg_spo2 = 0.0
        elif avg_hr == 0.0 or avg_spo2 == 0.0:
            # Finger detected but beatAvg/spo2Avg not yet computed (needs ~8 beats)
            is_anomaly = False
            overall_status = "Normal"
            summary_text = "Finger detected. Measuring heart rate and SpO2, hold still..."
        else:
            # Valid finger + valid readings — try ML anomaly model, fall back to rules
            try:
                load_models()
                features_scaled = anomaly_scaler.transform(features_vector)
                pred = anomaly_model.predict(features_scaled)
                is_anomaly = bool(pred[0] == -1)
                print(f"ML model prediction: {'Anomaly' if is_anomaly else 'Normal'}")
            except Exception as ml_err:
                # ML model failed — use simple threshold rules instead
                print(f"ML model error (using rule-based fallback): {ml_err}")
                is_anomaly = bool(avg_hr < 50 or avg_hr > 120 or avg_spo2 < 94)

            # Generate summary text
            overall_status = "Warning" if is_anomaly else "Normal"
            if is_anomaly:
                if avg_hr > 120 or avg_hr < 50:
                    summary_text = f"Abnormal heart rate detected: {avg_hr:.0f} BPM. Rest recommended."
                elif avg_spo2 < 94:
                    summary_text = f"Low blood oxygen: {avg_spo2:.0f}%. Please sit down."
                else:
                    summary_text = "Anomaly pattern detected. Keep calm and rest."
            else:
                summary_text = f"Vitals look good. HR: {avg_hr:.0f} BPM, SpO2: {avg_spo2:.0f}%."


            
        timestamp = readings[0].get('timestamp') if readings[0].get('timestamp') else None
        # Use current time if none provided
        if not timestamp or timestamp == 'system_clock':
            from datetime import datetime
            timestamp = datetime.utcnow().isoformat() + 'Z'
            
        device_id = event.get('deviceId') or readings[0].get('deviceId') or 'esp32-user-1'
        activity_label = event.get('activityLabel') or readings[0].get('activityLabel') or 'Resting'

        # Construct DynamoDB summary document
        item = {
            'deviceId': device_id,
            'timestamp': timestamp,
            'avgHeartRate': float_to_decimal(avg_hr),
            'avgSpo2': float_to_decimal(avg_spo2),
            'avgTemp': float_to_decimal(avg_temp),
            'readingsCount': len(readings),
            'signalQuality': float_to_decimal(0.98),
            'activityLabel': activity_label,
            'steps': int(steps),
            'fingerDetected': finger_detected,
            'isAnomaly': is_anomaly,
            'overallStatus': overall_status,
            'summary': summary_text
        }
        
        print("Saving summary to DynamoDB:", item)
        table.put_item(Item=item)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Telemetry summary successfully processed and stored.',
                'isAnomaly': is_anomaly,
                'overallStatus': overall_status
            })
        }
        
    except Exception as e:
        print("Error processing IoT data:", str(e))
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
