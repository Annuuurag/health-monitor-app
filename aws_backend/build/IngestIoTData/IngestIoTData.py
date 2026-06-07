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

def load_models():
    global anomaly_model, anomaly_scaler
    if anomaly_model is None or anomaly_scaler is None:
        print("Loading anomaly detection models from disk...")
        with open(MODEL_PATH, 'rb') as f:
            anomaly_model = pickle.load(f)
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
        hr_list, spo2_list, temp_list = [], [], []
        
        for r in readings:
            if r.get('hr') is not None:
                hr_list.append(float(r['hr']))
            if r.get('spo2') is not None:
                spo2_list.append(float(r['spo2']))
            if r.get('temp') is not None:
                temp_list.append(float(r['temp']))
                
        avg_hr = np.mean(hr_list) if hr_list else 72.0
        avg_spo2 = np.mean(spo2_list) if spo2_list else 97.0
        avg_temp = np.mean(temp_list) if temp_list else 36.5
        
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
        
        # Load models and predict
        load_models()
        features_scaled = anomaly_scaler.transform(features_vector)
        pred = anomaly_model.predict(features_scaled)
        
        # Predict values: -1 = Anomaly, 1 = Normal
        is_anomaly = bool(pred[0] == -1)
        
        # Generate diagnostic text summary
        overall_status = "Warning" if is_anomaly else "Normal"
        if is_anomaly:
            if avg_hr > 100 or avg_hr < 55:
                summary_text = f"Abnormal heart rate detected: {avg_hr:.0f} BPM. Rest recommended."
            elif avg_spo2 < 95:
                summary_text = f"Low blood oxygen levels detected: {avg_spo2:.0f}%. Please sit down."
            else:
                summary_text = "Anomaly pattern detected in biometric telemetry. Keep calm and rest."
        else:
            summary_text = "Your vitals are looking good."
            
        timestamp = readings[0].get('timestamp') if readings[0].get('timestamp') else boto3.client('dynamodb').system_clock_name
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
