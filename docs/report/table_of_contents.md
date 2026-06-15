# B.Tech Project Report: Table of Contents

---

## Preliminary Materials
1. Title Page (Jorhat Engineering College CSE/Instrumentation format)
2. Candidates' Declaration
3. Certificate of Approval
4. Certificate of Guidance
5. Certificate of Examination
6. Acknowledgements
7. Abstract
8. List of Figures
9. List of Tables
10. List of Abbreviations

---

## Chapter 1: Introduction
1.1 Project Overview & Motivation
1.2 Problem Statement
&nbsp;&nbsp;&nbsp;&nbsp;1.2.1 Limitations of Traditional Wearables
&nbsp;&nbsp;&nbsp;&nbsp;1.2.2 The Need for Hybrid Edge-Cloud Processing
1.3 Objectives of the Project
1.4 Scope and Significance
1.5 Project Timeline & Gantt Chart
1.6 Report Organization

---

## Chapter 2: Theoretical Background & Components
2.1 Overview of Internet of Things (IoT) in Healthcare
2.2 Hardware Architecture & Sensor Components
&nbsp;&nbsp;&nbsp;&nbsp;2.2.1 ESP32 Microcontroller: Architecture and Features
&nbsp;&nbsp;&nbsp;&nbsp;2.2.2 MAX30102 Photoplethysmography (PPG) Sensor Working Principle
&nbsp;&nbsp;&nbsp;&nbsp;2.2.3 MPU6050 Inertial Measurement Unit (IMU): Working Principle
&nbsp;&nbsp;&nbsp;&nbsp;2.2.4 Inter-Integrated Circuit (I2C) Communication Protocol
2.3 Cloud Computing & Database Technologies
&nbsp;&nbsp;&nbsp;&nbsp;2.3.1 AWS IoT Core Message Broker & MQTT Protocol
&nbsp;&nbsp;&nbsp;&nbsp;2.3.2 AWS Lambda Serverless Computing
&nbsp;&nbsp;&nbsp;&nbsp;2.3.3 Amazon DynamoDB NoSQL Database
2.4 Machine Learning Foundations
&nbsp;&nbsp;&nbsp;&nbsp;2.4.1 Unsupervised Anomaly Detection: Isolation Forest
&nbsp;&nbsp;&nbsp;&nbsp;2.4.2 Supervised Cardiac Risk Assessment Ensemble Models
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.4.2.1 Random Forest Classifier
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.4.2.2 Histogram-based Gradient Boosting
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.4.2.3 Support Vector Classifier (SVC)
2.5 Literature Survey & Research Gaps

---

## Chapter 3: System Design & Methodology
3.1 Proposed Hybrid Edge-Cloud Architecture
3.2 Data Flow Diagrams (DFD)
&nbsp;&nbsp;&nbsp;&nbsp;3.2.1 DFD Level 0 (Context Diagram)
&nbsp;&nbsp;&nbsp;&nbsp;3.2.2 DFD Level 1 (Data Flow Overview)
&nbsp;&nbsp;&nbsp;&nbsp;3.2.3 DFD Level 2 (Detailed Flow)
3.3 Unified Modeling Language (UML) Sequence Diagram
3.4 Edge-Side Data Processing Methodology
&nbsp;&nbsp;&nbsp;&nbsp;3.4.1 Gravity-Compensated Acceleration Magnitude
&nbsp;&nbsp;&nbsp;&nbsp;3.4.2 Sliding Window & Peak-to-Peak Feature Extraction
&nbsp;&nbsp;&nbsp;&nbsp;3.4.3 Peak-Detection and Hysteresis Step Count Algorithm
&nbsp;&nbsp;&nbsp;&nbsp;3.4.4 Heuristic Edge Activity Classification
3.5 Cloud-Side Data Ingestion & Analytics Pipeline
&nbsp;&nbsp;&nbsp;&nbsp;3.5.1 Biometric Feature Extraction & HRV Calculation (RMSSD)
&nbsp;&nbsp;&nbsp;&nbsp;3.5.2 Ensembled Anomaly Isolation Pipeline
&nbsp;&nbsp;&nbsp;&nbsp;3.5.3 Ensembled Cardiac Risk Inference Pipeline
3.6 Client-Side Mobile Application Architecture

---

## Chapter 4: Hardware & Firmware Implementation
4.1 System Circuit Connections and Wiring Schematics
4.2 Microcontroller Pinout Allocations (SDA: GPIO 21, SCL: GPIO 22)
4.3 ESP32 Firmware Implementation Details
&nbsp;&nbsp;&nbsp;&nbsp;4.3.1 Sensor Drivers & Bus Management
&nbsp;&nbsp;&nbsp;&nbsp;4.3.2 Non-Blocking Data Polling & Buffer Logic
&nbsp;&nbsp;&nbsp;&nbsp;4.3.3 Edge Step Count Implementation
&nbsp;&nbsp;&nbsp;&nbsp;4.3.4 Activity Recognition Heuristics Code
&nbsp;&nbsp;&nbsp;&nbsp;4.3.5 Local HTTP Web Dashboard & JSON Endpoint
&nbsp;&nbsp;&nbsp;&nbsp;4.3.6 Secure WiFi & SSL/TLS MQTT Handshake

---

## Chapter 5: Cloud and Software Integration
5.1 Serverless Infrastructure as Code: AWS SAM template.yaml
5.2 Ingestion Lambda Function (IngestIoTData) Implementation
&nbsp;&nbsp;&nbsp;&nbsp;5.2.1 Data Validation and Raw Payload Decoding
&nbsp;&nbsp;&nbsp;&nbsp;5.2.2 Mathematical Feature Extraction Code
&nbsp;&nbsp;&nbsp;&nbsp;5.2.3 Custom Unpickler for Isolation Forest Model Deserialization
5.3 Disease Prediction Lambda Function (PredictDisease) Implementation
&nbsp;&nbsp;&nbsp;&nbsp;5.3.1 Soft-Voting Ensemble Logic
&nbsp;&nbsp;&nbsp;&nbsp;5.3.2 Machine Learning Model Inference
5.4 App Telemetry Data Query Layer (FetchAppTelemetry)
5.5 Amazon DynamoDB Database Schema Design
5.6 Flutter Mobile Application Implementation
&nbsp;&nbsp;&nbsp;&nbsp;5.6.1 Clean Architecture Pattern Layout
&nbsp;&nbsp;&nbsp;&nbsp;5.6.2 State Management Orchestration (AppController)
&nbsp;&nbsp;&nbsp;&nbsp;5.6.3 AWS API Gateway Repository Integration

---

## Chapter 6: Results, Testing, and Evaluation
6.1 Hardware Prototype Calibration and Sensor Tuning
6.2 Edge Step Counter and Activity Recognition Field Testing
6.3 Machine Learning Pipeline Evaluation Results
&nbsp;&nbsp;&nbsp;&nbsp;6.3.1 Unsupervised Isolation Forest Anomaly Detection Metrics
&nbsp;&nbsp;&nbsp;&nbsp;6.3.2 Cardiac Risk Assessment Ensemble Classifier Performance
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;6.3.2.1 Accuracy, Precision, Recall, and F1-Score
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;6.3.2.2 ROC-AUC Performance Curves
6.4 Database Ingestion Verification & Latency Statistics
6.5 Flutter Mobile Application UI Verification & Live Telemetry Rendering

---

## Chapter 7: Conclusions & Future Scope
7.1 Summary of Work Completed
7.2 Summary of Key Contributions
7.3 Limitations of Current System
7.4 Future Recommendations & Extensions

---

## Bibliography
Academic Papers, Books, Technical Datasheets, Web Resources
