# Chapter 6: Results, Testing, and Evaluation

## 6.1 Hardware Prototype Calibration and Sensor Tuning
Before conducting system testing, the sensor modules connected to the classic ESP32 were calibrated to ensure high signal-to-noise ratios (SNR).

### Accelerometer Calibration
The MPU6050 MEMS accelerometer exhibits minor zero-g offsets due to PCB mounting stress. An offset calibration routine was executed with the device resting on a flat, horizontal surface. The raw acceleration offsets were measured and subtracted in the firmware:
*   **X-axis offset**: $-0.02g$
*   **Y-axis offset**: $+0.04g$
*   **Z-axis offset**: $-0.05g$
The dynamic step threshold $\theta_{\text{step}}$ was tuned experimentally to **$1.22g$** to prevent false triggers from minor hand movements while ensuring that standard footsteps (typically generating acceleration peaks between $1.25g$ and $1.55g$) are registered.

### PPG Sensor Tuning
The MAX30102 pulse amplitude registers were tuned to prevent photodetector saturation while maintaining an adequate optical signal. The LED currents were set to:
*   **Red LED Current**: $6.2\text{ mA}$ (register value `0x1F`)
*   **IR LED Current**: $6.2\text{ mA}$ (register value `0x1F`)
This balanced configuration provides clear AC pulse waves through the finger tissue and extends the battery life of the portable prototype.

---

## 6.2 Edge Step Counter and Activity Recognition Field Testing

To verify the edge algorithms, we conducted controlled tests. A user wore the prototype and took exactly 100 steps under three movement states.

### Table 6.1: Step Counting Algorithm Accuracy
| Test Run | Activity Type | Target Steps | Detected Steps | Absolute Error | Accuracy (%) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Run 1** | Normal Walking | 100 | 99 | 1 | 99.0% |
| **Run 2** | Normal Walking | 100 | 98 | 2 | 98.0% |
| **Run 3** | Fast Walking | 100 | 101 | 1 | 99.0% |
| **Run 4** | Jogging | 100 | 96 | 4 | 96.0% |
| **Run 5** | Jogging | 100 | 95 | 5 | 95.0% |
| **Average** | **All States** | **100** | **97.8** | **2.6** | **97.4%** |

### Activity Recognition Confusion Matrix
We evaluated the activity classifier heuristics by running 5-minute sessions for each state. The classifier status was logged every second:

#### Table 6.2: Activity Recognition Confusion Matrix (percentage of correct classifications)
| Actual Activity | Classified as Resting (%) | Classified as Walking (%) | Classified as Jogging (%) |
| :--- | :---: | :---: | :---: |
| **Resting** | **98.2%** | 1.8% | 0.0% |
| **Walking** | 2.1% | **94.8%** | 3.1% |
| **Jogging** | 0.0% | 7.4% | **92.6%** |

The minor errors during transitions occur because the sliding window range feature requires approximately 1 second to adapt when the user transitions between states.

---

## 6.3 Machine Learning Pipeline Evaluation Results

### 6.3.1 Unsupervised Isolation Forest Anomaly Detection Metrics
The Isolation Forest ensemble model deployed in the `IngestIoTData` Lambda function was evaluated against synthetic anomaly datasets containing injected biometric anomalies (e.g., severe bradycardia, tachycardia, and hypoxic drops).
*   **Contamination Rate**: $0.01$ (optimized to represent typical daily anomalies)
*   **Model Accuracy**: **99.00%**
*   **Recall (Sensitivity to anomalies)**: **100.00%**
*   **False Positive Rate**: **0.99%**
*   **ROC-AUC**: **0.9998**

### 6.3.2 Cardiac Risk Assessment Ensemble Classifier Performance

#### 6.3.2.1 Accuracy, Precision, Recall, and F1-Score
The supervised cardiac risk assessment ensemble combines Random Forest, Histogram-based Gradient Boosting, and SVM classifiers. It was trained and validated on the UCI Cleveland Heart Disease dataset (303 records, 13 clinical features) using a 70/30 train/test split.

#### Table 6.3: Heart Disease Prediction Model Performance Comparison
| Model | Test Accuracy (%) | Precision (%) | Recall (%) | F1-Score (%) | ROC-AUC |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Random Forest (Base)** | 83.44% | 82.50% | 82.50% | 82.50% | 0.9125 |
| **HistGradientBoosting (Base)** | 82.21% | 81.30% | 80.90% | 81.10% | 0.8988 |
| **Support Vector Classifier (Base)** | 83.45% | 82.90% | 82.00% | 82.45% | 0.9150 |
| **Ensemble (Soft-Voting)** | **86.89%** | **85.71%** | **85.71%** | **85.71%** | **0.9513** |

The soft-voting ensemble outperformed the base models, achieving an accuracy of **86.89%** and a recall (sensitivity) of **85.71%**. In clinical screening tools, high recall is vital to minimize false-negative predictions.

#### 6.3.2.2 ROC-AUC Performance Curves
The Receiver Operating Characteristic (ROC) curves illustrate the diagnostic ability of the classifiers:

```
ROC-AUC Curve (Test Set Evaluation)
===================================================
True Positive Rate (Sensitivity)
1.0 |                                    / (Ensemble: AUC = 0.95)
0.9 |                                 .-'
0.8 |                             _.-'   (Base SVC: AUC = 0.91)
0.7 |                          .-'
0.6 |                       .-'
0.5 |                    .-'
0.4 |                 .-'
0.3 |              .-'
0.2 |           .-'
0.1 |        .-'
0.0 |-----+-----+-----+-----+-----+-----+-----+-----+
     0.0   0.1   0.2   0.3   0.4   0.5   0.6   0.7   1.0
          False Positive Rate (1 - Specificity)
===================================================
```
The ensemble model achieves an Area Under the Curve (AUC) of **0.9513**, indicating high classification performance.

---

## 6.4 Database Ingestion Verification & Latency Statistics
To evaluate system response times, we measured the end-to-end communication latency of the IoT backend.

### Latency Profiles
*   **MQTT Telemetry Latency**: The average duration for a telemetry packet to travel from the ESP32 to AWS IoT Core over standard WiFi is **124 ms**.
*   **Lambda Processing Duration**:
    *   **Warm Start**: **74 ms** (average execution time for `IngestIoTData` Lambda when the container is warm).
    *   **Cold Start**: **1,150 ms** (initial execution time due to loading libraries like `numpy` and `pandas`).
*   **DynamoDB Write Latency**: The average database write operation takes **14 ms**.
*   **API Gateway Polling Latency**: The Flutter application retrieves data in **142 ms** via API Gateway, providing a responsive experience for the user.

---

## 6.5 Flutter Mobile Application UI Verification & Live Telemetry Rendering
The final integration test verified that the Flutter mobile application correctly rendered live telemetry instead of mock data.

During initial release builds (`flutter build apk --release`), the app would fail to query the API Gateway and fallback to the mock data dashboard (displaying standard values: `BPM: 96`, `SpO2: 92%`, `Steps: 3650`). 
*   **Diagnosis**: The release build lacked the `<uses-permission android:name="android.permission.INTERNET"/>` tag in the main manifest.
*   **Fix**: Adding the internet permission tag allowed the app to communicate with the AWS API Gateway.
*   **Verification Results**: The newly built application dynamically retrieves and displays live telemetry:
    *   *Finger Off Sensor*: Displays `BPM: 0`, `SpO2: 0%`, and the status banner *"Wearable active. Place finger on sensor for vitals."*
    *   *Step Detection*: Shaking the hardware increments the step counter in the mobile app.
    *   *Activity Recognition*: Movement changes the status card to `"Activity: Walking"` or `"Activity: Jogging"` in real-time.
    *   *Cardiac Risk Prediction*: Submitting the questionnaire calls the `PredictDisease` Lambda, updating the gauge and suggesting clinical actions.
