# Chapter 5: Cloud and Software Integration

## 5.1 Serverless Infrastructure as Code: AWS SAM template.yaml
To manage, provision, and deploy the backend infrastructure, the project uses the **AWS Serverless Application Model (SAM)**. All cloud resources are defined declaratively in a `template.yaml` configuration file, which is compiled and deployed as a CloudFormation stack.

Key sections of the SAM template define the serverless database, functions, permissions, and API endpoints:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: Serverless Backend for IoT Health Monitor

Resources:
  # 1. DynamoDB Table for time-series telemetry data storage
  HealthTelemetryTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: HealthTelemetrySummaries
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: deviceId
          AttributeType: S
        - AttributeName: timestamp
          AttributeType: S
      KeySchema:
        - AttributeName: deviceId
          KeyType: HASH # Partition Key
        - AttributeName: timestamp
          KeyType: RANGE # Sort Key

  # 2. Ingestion Lambda Function triggered by MQTT rules
  IngestIoTDataFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: ./build/IngestIoTData
      Handler: IngestIoTData.handler
      Runtime: python3.12
      Timeout: 15
      MemorySize: 512
      Policies:
        - DynamoDBCrudPolicy:
            TableName: HealthTelemetrySummaries
      Environment:
        Variables:
          TABLE_NAME: HealthTelemetrySummaries

  # 3. Disease Prediction API Lambda Function
  PredictDiseaseFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: ./build/PredictDisease
      Handler: PredictDisease.handler
      Runtime: python3.12
      Timeout: 10
      MemorySize: 512
      Events:
        PredictDiseaseAPI:
          Type: Api
          Properties:
            Path: /disease-prediction
            Method: post

  # 4. Fetch Telemetry API Lambda Function
  FetchAppTelemetryFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: ./aws_backend/FetchAppTelemetry
      Handler: FetchAppTelemetry.handler
      Runtime: nodejs22.x
      Timeout: 10
      MemorySize: 256
      Policies:
        - DynamoDBReadPolicy:
            TableName: HealthTelemetrySummaries
      Environment:
        Variables:
          TABLE_NAME: HealthTelemetrySummaries
      Events:
        GetTelemetryAPI:
          Type: Api
          Properties:
            Path: /telemetry
            Method: get
```

---

## 5.2 Ingestion Lambda Function (IngestIoTData) Implementation

### 5.2.1 Data Validation and Raw Payload Decoding
The `IngestIoTData` Lambda function is written in Python 3.12. It processes batches of sensor telemetry routed from AWS IoT Core. The function parses incoming JSON, averages readings over the transmission window, and formats variables (floats, integers, booleans).

### 5.2.2 Mathematical Feature Extraction Code
To calculate Heart Rate Variability (HRV), the function computes the RMSSD metric. It also calculates the skewness and kurtosis of the vital signs sample buffer:

```python
def calculate_stats(values):
    """Calculate skewness and kurtosis manually to avoid scipy dependency"""
    n = len(values)
    if n < 3:
        # Default baselines from standard distributions
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
```

### 5.2.3 Custom Unpickler for Isolation Forest Model Deserialization
When machine learning models are trained in local Jupyter notebooks, they are pickled under the local scope (`__main__`). When unpickled in the AWS Lambda runtime namespace, Python throws a `ModuleNotFoundError` because it cannot locate the custom classes (such as `EnsembleDetector`). 

To resolve this, we implement a `CustomUnpickler` subclass that overrides `find_class` to redirect the unpickling namespace to the current module scope:

```python
# Define EnsembleDetector class so it can be resolved during unpickling
class EnsembleDetector:
    def __init__(self, models):
        self.models = models

    def predict(self, X):
        preds = np.stack([m.predict(X) for m in self.models], axis=1)
        anomaly_votes = np.sum(preds == -1, axis=1)
        final_preds = np.where(anomaly_votes >= 2, -1, 1) # Majority voting
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
```

---

## 5.3 Disease Prediction Lambda Function (PredictDisease) Implementation

### 5.3.1 Soft-Voting Ensemble Logic
The `PredictDisease` Lambda function handles supervised risk evaluation. It accepts 13 clinical features and passes them to a pre-trained soft-voting ensemble model.

### 5.3.2 Machine Learning Model Inference Python Code
The ensemble model calculates the heart disease probability and returns suggestions based on the risk category:

```python
def handler(event, context):
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
        body_str = event.get('body', '{}')
        body = json.loads(body_str) if body_str else {}
        
        required_features = [
            "age", "sex", "cp", "trestbps", "chol",
            "fbs", "restecg", "thalach", "exang",
            "oldpeak", "slope", "ca", "thal"
        ]
        
        # Populate input list, providing reasonable normal defaults
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
            
        input_array = np.array([input_data])
        
        # Scale and run inference
        load_models()
        input_scaled = disease_scaler.transform(input_array)
        
        prob = disease_model.predict_proba(input_scaled)[0][1] # Class 1 (Heart Disease) probability
        pred = int(disease_model.predict(input_scaled)[0])
        
        risk_pct = prob * 100
        
        # Generate risk category and clinical suggestions
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
        ...
```

---

## 5.4 App Telemetry Data Query Layer (FetchAppTelemetry)
The `FetchAppTelemetry` Lambda function is written in Node.js 22.x. It queries DynamoDB and returns a snapshot of the latest telemetry along with the most recent 20 samples:

```javascript
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, QueryCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const TABLE_NAME = process.env.TABLE_NAME || 'HealthTelemetrySummaries';

exports.handler = async (event) => {
    try {
        const deviceId = event.queryStringParameters?.deviceId || 'esp32-user-1';
        
        const params = {
            TableName: TABLE_NAME,
            KeyConditionExpression: 'deviceId = :did',
            ExpressionAttributeValues: {
                ':did': deviceId
            },
            ScanIndexForward: false, // Descending order
            Limit: 20
        };

        const result = await dynamo.send(new QueryCommand(params));
        const items = result.Items || [];

        // Map NoSQL decimal fields to floating point values for mobile app compatibility
        const responseData = items.map(item => ({
            deviceId: item.deviceId,
            timestamp: item.timestamp,
            heartRateBpm: item.avgHeartRate,
            spo2Percent: item.avgSpo2,
            bodyTempC: item.avgTemp,
            readingsCount: item.readingsCount || 1,
            signalQuality: item.signalQuality || 0.95,
            activityLabel: item.activityLabel || 'Resting',
            stepCount: item.steps !== undefined ? Number(item.steps) : 0,
            source: 'AWS Backend',
            isAnomaly: item.isAnomaly !== undefined ? item.isAnomaly : false,
            overallStatus: item.overallStatus || 'Normal',
            summary: item.summary || 'Your vitals are looking good.'
        }));

        const latest = responseData.length > 0 ? responseData[0] : null;
        
        let snapshot = null;
        if (latest) {
            snapshot = {
                deviceId: latest.deviceId,
                timestamp: latest.timestamp,
                heartRateBpm: latest.heartRateBpm,
                spo2Percent: latest.spo2Percent,
                bodyTempC: latest.bodyTempC,
                activityLabel: latest.activityLabel,
                stepCount: latest.stepCount,
                signalQuality: latest.signalQuality,
                overallStatus: latest.overallStatus,
                isAnomaly: latest.isAnomaly,
                summary: latest.summary
            };
        }

        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                snapshot: snapshot,
                samples: responseData
            })
        };
    } catch (error) { ... }
};
```

---

## 5.5 Amazon DynamoDB Database Schema Design
The table structure is configured as follows:
*   **Hash Key (Partition Key)**: `deviceId` (String) — e.g. `"esp32-user-1"`.
*   **Range Key (Sort Key)**: `timestamp` (String) — e.g. `"2026-06-15T08:30:12.441Z"`.
*   **Attributes**:
    *   `avgHeartRate`: Numeric (Decimal) — mean BPM.
    *   `avgSpo2`: Numeric (Decimal) — arterial oxygen saturation.
    *   `avgTemp`: Numeric (Decimal) — skin temperature in °C.
    *   `activityLabel`: String — `"Resting"`, `"Walking"`, or `"Jogging"`.
    *   `steps`: Number (Integer) — cumulative steps.
    *   `isAnomaly`: Boolean — anomaly state.
    *   `overallStatus`: String — `"Normal"` or `"Warning"`.
    *   `summary`: String — diagnostic summary.

---

## 5.6 Flutter Mobile Application Implementation

### 5.6.1 Clean Architecture Pattern Layout
The Flutter codebase is structured as follows:
```
lib/
├── app/
│   ├── theme/
│   │   └── app_theme.dart
│   └── state/
│       └── app_controller.dart        <-- ChangeNotifier State Orchestrator
├── domain/
│   ├── models/
│   │   ├── health_snapshot.dart      <-- Step count entity properties
│   │   └── telemetry_sample.dart     <-- Historical sample models
│   └── repositories/
│       └── telemetry_repository.dart <-- Repository Contract
└── data/
    ├── api/
    │   └── api_telemetry_repository.dart <-- Fetches real-time AWS API Gateway
    └── mock/
        └── mock_seed_data.dart
```

### 5.6.2 State Management Orchestration (AppController)
The `AppController` extends `ChangeNotifier`. It acts as the central state orchestrator, updating components and notifying listeners:

```dart
class AppController extends ChangeNotifier {
  AppController({required this.telemetryRepository, ...});

  final TelemetryRepository telemetryRepository;
  HealthSnapshot? _snapshot;
  List<TelemetrySample> _samples = const [];
  
  HealthSnapshot? get snapshot => _snapshot;
  List<TelemetrySample> get samples => _samples;

  Future<void> refresh() async {
    _setLoading(true);
    try {
      final snapshot = await telemetryRepository.getLatestSnapshot();
      final samples = await telemetryRepository.getRecentSamples();
      _snapshot = snapshot;
      _samples = samples;
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Could not refresh health data.';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
}
```

### 5.6.3 AWS API Gateway Repository Integration
The `ApiTelemetryRepository` maps JSON keys returned from the API Gateway endpoint directly to domain models:

```dart
class ApiTelemetryRepository implements TelemetryRepository {
  final String apiUrl = 'https://vfeh40pll0.execute-api.ap-south-1.amazonaws.com/Prod/telemetry'; 

  @override
  Future<HealthSnapshot> getLatestSnapshot() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final s = data['snapshot'];
        if (s != null) {
          return HealthSnapshot(
            deviceId: s['deviceId'],
            timestamp: DateTime.parse(s['timestamp']),
            heartRateBpm: (s['heartRateBpm'] as num).toDouble(),
            spo2Percent: (s['spo2Percent'] as num).toDouble(),
            bodyTempC: (s['bodyTempC'] as num).toDouble(),
            activityLabel: s['activityLabel'],
            stepCount: (s['stepCount'] as num?)?.toInt() ?? 0,
            signalQuality: (s['signalQuality'] as num).toDouble(),
            overallStatus: s['overallStatus'],
            isAnomaly: s['isAnomaly'],
            summary: s['summary'],
          );
        }
      }
    } catch (e) { ... }
    return MockSeedData.latestSnapshot(); // Fallback on error
  }
  ...
}
```
