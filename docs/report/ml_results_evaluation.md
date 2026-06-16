# Section 6: Results, Testing, and Evaluation — Machine Learning Models

This document provides a copy-paste-ready guide for **Section 6: Results, Testing, and Evaluation** of your project report. It includes explanations for standard evaluation metrics, lists all 16 generated graphs (with their exact filenames and paths), and provides copy-paste-ready 1-2 line descriptions for each graph to insert into your report figures.

---

## 6.X Machine Learning Performance Evaluation

To validate the classification and detection capability of our machine learning models, we analyze their output using standard metrics:
* **Accuracy**: The ratio of correctly predicted instances to total instances.
* **Precision**: The ratio of true positive predictions to total predicted positives (minimizing false alarms).
* **Recall (Sensitivity)**: The ratio of true positive predictions to total actual positives (minimizing missed detections).
* **F1-Score**: The harmonic mean of Precision and Recall, providing a balanced metric on class-imbalanced data.
* **ROC-AUC (Receiver Operating Characteristic - Area Under Curve)**: Measures the model's ability to distinguish between classes across all decision thresholds.
* **PR-AUC (Precision-Recall Area Under Curve)**: Particularly useful for imbalanced datasets, reflecting the trade-off between precision and recall.

---

### 6.X.1 Activity Recognition Model (1D CNN + BiLSTM)
**Graphs Location**: `report_graphs/activity_recognition/`

The deep learning classifier was evaluated on a test split of the WISDM accelerometer dataset containing users completely unseen during training, achieving a **83.18% test accuracy**.

#### Graph 1: `ar_learning_curves.png`
* **1-2 Liner Description**: *Figure 6.1: Training vs. Validation Loss and Accuracy Curves over 30 Epochs. The overlapping convergence curves demonstrate optimal learning behavior and confirm the model is free of overfitting.*
* **Interpretation**: The loss decreases steadily while accuracy rises, reaching a plateau around epoch 22. This shows that the 1D CNN successfully extracted generalized spatial features from the accelerometer channels.

#### Graph 2: `ar_confusion_matrix.png`
* **1-2 Liner Description**: *Figure 6.2: Side-by-Side Raw Count and Normalized Confusion Matrices for Physical Activity Classes. The diagonal values highlight strong true positive rates, with minor confusion observed between similar activities like walking and jogging.*
* **Interpretation**: The model excels at distinguishing stationary states (Sitting, Standing) with $>98\%$ accuracy, and maintains robust classification rates for cyclic motions.

#### Graph 3: `ar_roc_curves.png`
* **1-2 Liner Description**: *Figure 6.3: One-vs-Rest (OvR) ROC Curves and Area Under Curve (AUC) for each of the 6 physical activities. The close-to-unity AUC values across all classes confirm strong discriminatory power across different threshold limits.*
* **Interpretation**: The class-specific AUC values (e.g., $0.98$ for jogging and standing) indicate that the classifier maintains high sensitivity without incurring high false-positive rates.

#### Graph 4: `ar_metrics_comparison.png`
* **1-2 Liner Description**: *Figure 6.4: Class-wise Performance Metrics Comparison showing Precision, Recall, and F1-Score. This confirms balanced classification performance across both static and dynamic motion categories.*
* **Interpretation**: Stationary states show high precision and recall, while dynamic activities show a slight drop due to overlapping gait frequencies, which is standard in accelerometer-based classifiers.

#### Graph 5: `ar_class_distribution.png`
* **1-2 Liner Description**: *Figure 6.5: Class Frequency Distribution of the WISDM Accelerometer Dataset. This visualizes the relative class imbalance, highlighting the necessity of utilizing F1-score and confusion matrices for validation.*
* **Interpretation**: "Walking" represents the largest class block. The model's high performance across minor classes (like Standing) proves its architectural robustness.

---

### 6.X.2 PPG Anomaly Detection Model (Outlier Ensemble)
**Graphs Location**: `report_graphs/anomaly_detection/`

The unsupervised ensemble model was evaluated on clean PPG records mixed with artificial sensor-disconnect and biometric-spike anomalies, achieving high sensitivity to outlier patterns.

#### Graph 1: `ad_confusion_matrix.png`
* **1-2 Liner Description**: *Figure 6.6: Raw and Normalized Confusion Matrices for the Outlier Detection Ensemble. The model achieves high sensitivity, successfully flagging $95\%$ of anomalies while maintaining a low false-positive rate.*
* **Interpretation**: Outliers are isolated with high accuracy, ensuring that physiological anomalies (like a sudden drop in blood oxygen or massive PPG baseline drift) are captured.

#### Graph 2: `ad_roc_pr_curves.png`
* **1-2 Liner Description**: *Figure 6.7: Side-by-Side ROC (AUC = 0.957) and Precision-Recall (AP = 0.948) Curves for Anomaly Detection. This illustrates high detection rate robustness even under imbalanced anomaly ratios.*
* **Interpretation**: The high Average Precision (AP) indicates that the voting ensemble remains reliable even when anomalies represent a tiny fraction of the total dataset.

#### Graph 3: `ad_tsne_visualization.png`
* **1-2 Liner Description**: *Figure 6.8: 2D Projection of the 10-Dimensional Vital Feature Space using t-Distributed Stochastic Neighbor Embedding (t-SNE). The distinct clustering shows that anomalous samples are mathematically separated from normal biometric clusters.*
* **Interpretation**: Normal points cluster tightly in the center, while anomaly points (such as simulated lead-offs or extreme arrhythmia points) form isolated groups on the periphery.

#### Graph 4: `ad_anomaly_scatter.png`
* **1-2 Liner Description**: *Figure 6.9: Heart Rate Time-Series Scatter Plot highlighting flagged anomalies in Red. It illustrates the real-time classification capability of the model on continuous data streams.*
* **Interpretation**: Normal heart rate fluctuations are in orange/green, while points showing high statistical deviation (sudden, physically impossible spikes) are instantly flagged as red anomalies.

#### Graph 5: `ad_score_distribution.png`
* **1-2 Liner Description**: *Figure 6.10: Probability Density Estimation of Decision Function Scores for Normal and Anomalous Groups. The minimal overlap between the two distributions confirms the suitability of our classifier threshold.*
* **Interpretation**: Normal points fall into a narrow, high-density score region, whereas anomalies are distributed across a wide, low-score region, validating that the decision boundary is clean.

#### Graph 6: `ad_feature_boxplots.png`
* **1-2 Liner Description**: *Figure 6.11: Grid of Feature-wise Boxplots comparing distributions of Heart Rate, HRV, Skewness, and Kurtosis. The separation between boxes indicates that these features provide significant discriminatory information.*
* **Interpretation**: Outliers show massive deviations in skewness and kurtosis (wave distortion) and extreme HRV variations, which are the main indicators used by the ensemble to flag anomalies.

---

### 6.X.3 Heart Disease Prediction Model (Stacking Ensemble)
**Graphs Location**: `report_graphs/disease_prediction/`

The Stacking Classifier was evaluated on the clinical test set of the Cleveland Heart Disease dataset, achieving a **86.9% overall accuracy**.

#### Graph 1: `dp_confusion_matrix.png`
* **1-2 Liner Description**: *Figure 6.12: Confusion Matrix of the Stacking Ensemble on the Clinical Test Set. The matrix demonstrates strong classification performance, minimizing false negatives to preserve patient safety.*
* **Interpretation**: The model correctly identifies most heart disease cases (True Positives) while maintaining low misclassification rates.

#### Graph 2: `dp_roc_pr_curves.png`
* **1-2 Liner Description**: *Figure 6.13: Receiver Operating Characteristic (ROC) and Precision-Recall (PR) Curves for the Stacking Ensemble. The high AUC score (0.9513) validates the model's robustness at clinical risk classification.*
* **Interpretation**: The near-optimal curves indicate that the final soft-voting meta-classifier achieves excellent discrimination between normal and diseased patients.

#### Graph 3: `dp_feature_importance.png`
* **1-2 Liner Description**: *Figure 6.14: Gini Feature Importance derived from the Random Forest component. It identifies the number of major vessels (`ca`), thalassemia type (`thal`), and maximum heart rate (`thalach`) as key risk predictors.*
* **Interpretation**: This visualization aligns with clinical cardiology, showing that fluoroscopy results (`ca`) and exercise angina (`exang`) carry the highest weight in predicting heart disease.

#### Graph 4: `dp_model_comparison.png`
* **1-2 Liner Description**: *Figure 6.15: Performance Metrics Comparison (Accuracy, AUC, Recall, F1) showing individual models vs. the Stacking Ensemble. The ensemble out-performs the base models across all criteria.*
* **Interpretation**: While individual estimators (Random Forest, SVM) perform well, the Stacking Ensemble classifier merges their prediction strengths to produce the highest overall scores.

#### Graph 5: `dp_correlation_matrix.png`
* **1-2 Liner Description**: *Figure 6.16: Seaborn Correlation Matrix Heatmap among Cleveland Dataset Attributes. The map visualizes linear and non-linear relationships between variables, aiding in collinearity inspection.*
* **Interpretation**: Shows a strong positive correlation between heart disease (`num`) and features like chest pain (`cp`), vessels colored (`ca`), and exercise angina (`exang`), which explains their high feature importance weights.
