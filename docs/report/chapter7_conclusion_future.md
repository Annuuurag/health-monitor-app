# Chapter 7: Conclusions & Future Scope

## 7.1 Summary of Work Completed
This project has successfully designed, implemented, and validated an intelligent, secure, and serverless **Hybrid Edge-Cloud IoT Health Monitoring System**. The system integrates physical biomedical sensing, edge computing, serverless cloud processing, and mobile visualization:

1.  **Edge Perception & Computing (ESP32)**: We successfully interfaced a classic ESP32 microcontroller with a MAX30102 PPG sensor and an MPU6050 IMU over a shared $\text{I}^2\text{C}$ bus. C++ firmware was developed to calculate gravity-compensated acceleration magnitude, run a non-blocking rolling buffer, count steps using a dynamic thresholding peak-detection algorithm, and classify user activities (Resting, Walking, Jogging) using heuristics.
2.  **Local Dashboard & Network Ingestion**: The ESP32 hosts a local HTTP web server that serves an HTML/JS dashboard displaying real-time metrics to devices on the same network. It establishes a secure MQTT over TLS connection to AWS IoT Core to publish summaries every 5 seconds.
3.  **AWS Serverless Analytics Pipeline**: Telemetry is routed to Python and Node.js Lambda functions. The ingestion function extracts biometric features (RMSSD HRV) and applies an unsupervised Isolation Forest ensemble to detect anomalies. The supervised risk assessment Lambda applies a soft-voting ensemble (Random Forest, Histogram Gradient Boosting, and SVC) to predict cardiac risk. Database records are stored dynamically in Amazon DynamoDB and exposed via API Gateway.
4.  **Flutter Client Application**: We built a cross-platform mobile application utilizing a Clean Architecture layout and state management. The app polls the AWS API Gateway, rendering live sensor parameters, step counts, and cardiac predictions.

---

## 7.2 Summary of Key Contributions
This project introduces several key contributions to the design of healthcare monitoring systems:
*   **Edge-Cloud Workload Partitioning**: Rather than streaming high-frequency raw sensor streams, the ESP32 performs data aggregation, step counting, and activity classification locally. This reduces cloud ingestion payload volume by over 90%, lowering network transmission costs and radio duty cycles.
*   **Dual-Sensor Correlation & Reduced False Alarms**: By correlating physical movement (accelerometer) with cardiac vital signs, the system reduces false-positive clinical alerts. If a high heart rate is detected while the user is jogging, the anomaly detection model does not flag a false alarm.
*   **Serverless Ingestion Footprint Optimization**: The cloud backend utilizes AWS serverless layers. By using the AWS Pandas SDK layer and a custom unpickling utility in Python, we packaged our machine learning models within the AWS Lambda code size limits.

---

## 7.3 Limitations of Current System
Despite its contributions, the current prototype has several technical limitations:
1.  **Local Web Server Access**: The local dashboard hosted on the ESP32 is only accessible to devices connected to the same WiFi network. Accessing the dashboard from outside requires manual router port forwarding.
2.  **PPG Motion Artifacts**: Photoplethysmography is highly sensitive to motion. Shaking the hand while holding the MAX30102 sensor introduces noise, which can result in inaccurate heart rate and $\text{SpO}_2$ calculations.
3.  **Lack of Authentication on API Gateway**: The public API Gateway endpoints are open. Securing access requires implementing token-based authorization.
4.  **Power Constraints**: While edge computing reduces radio power consumption, continuous WiFi connection and web server execution on the ESP32 require a stable power supply, limiting battery-powered portability.

---

## 7.4 Future Recommendations & Extensions
To transition the system from a prototype to a clinical-grade medical platform, several extensions are proposed:

### 1. TinyML Integration
The current heuristic activity recognition model can be replaced with a deep learning classifier running on the edge. By using frameworks like **Edge Impulse**, a Convolutional Neural Network (CNN) can be trained on linear acceleration vectors and deployed directly on the ESP32, improving classification accuracy.

### 2. AWS Cognito User Authentication
To secure API access, we can integrate **AWS Cognito User Pools**. This allows patients and medical professionals to sign up and log in securely, generating JSON Web Tokens (JWT) to authorize requests at the API Gateway.

### 3. Dual Vital Sensor Interfacing
The system can be expanded to include an **AD8232 ECG sensor** alongside the MAX30102 PPG sensor. This dual configuration allows the ESP32 to measure Pulse Transit Time (PTT)—the time delay between the R-peak of the ECG and the corresponding peak in the PPG waveform—enabling non-invasive, continuous blood pressure monitoring.

```
       AD8232 ECG Waveform (Electrical Signal)
              |
              |       PPG Waveform (Optical Signal)
              |            |
              v            v
      +----------------------------+
      |  R-Peak        PPG Peak    |
      |    |              |        |
      |    +----> PTT <---+        |
      +----------------------------+
                    |
                    v
         Continuous Blood Pressure
```

### 4. Advanced Noise Filtering
Applying digital signal processing (DSP) filters—such as bandpass Butterworth filters—directly in the ESP32 firmware can help remove high-frequency motion artifacts from the raw PPG signal before feature extraction.
