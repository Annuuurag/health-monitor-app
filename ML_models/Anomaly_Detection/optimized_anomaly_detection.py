# -*- coding: utf-8 -*-
"""
Optimized Heart Anomaly Detection using Ensemble Outlier Detectors
Dataset: features53.csv
Improvements:
- Voting Ensemble combining Isolation Forest, One-Class SVM, and Local Outlier Factor (LOF) 
  to build a highly robust decision boundary.
- Dynamic Contamination/Threshold Tuning using injected synthetic anomalies to maximize recall and precision.
- Standard scaling strictly saved as 'anomaly_scaler.pkl' for application preprocessing parity.
- Robust evaluation metrics including Precision, Recall, specificity, F1-score, and ROC-AUC.
- Save optimized ensemble model as 'anomaly_model.pkl'.
"""

# =====================================================================
# IMPORTS
# =====================================================================
import pandas as pd
import numpy as np
import pickle
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import IsolationForest
from sklearn.svm import OneClassSVM
from sklearn.neighbors import LocalOutlierFactor
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, roc_auc_score, roc_curve
import warnings
warnings.filterwarnings('ignore')

sns.set(style="whitegrid")
np.random.seed(42)

# =====================================================================
# STEP 1: LOAD DATASET AND CLEAN
# =====================================================================
csv_file = "features53.csv"
try:
    df = pd.read_csv(csv_file)
    print(f"[OK] Dataset loaded: {df.shape}")
except FileNotFoundError:
    print(f"Error: {csv_file} not found in the current directory.")
    print("Please ensure it is in the active folder.")
    exit()

# Drop patient identifiers and near-constant features
drop_cols = ["Patient_ID"]
df_features = df.drop(columns=[c for c in drop_cols if c in df.columns])

# Remove features with zero/near-zero variance
low_variance_cols = df_features.columns[df_features.nunique() <= 2]
if len(low_variance_cols) > 0:
    print(f"Removing low variance columns: {list(low_variance_cols)}")
    df_features = df_features.drop(columns=low_variance_cols)

print(f"Final feature count for ML: {df_features.shape[1]}")
print("Active features:", list(df_features.columns))

# =====================================================================
# STEP 2: FEATURE SCALING
# =====================================================================
scaler = StandardScaler()
X_scaled = scaler.fit_transform(df_features)

# Dump scaler
with open('anomaly_scaler.pkl', 'wb') as f:
    pickle.dump(scaler, f)
print("[OK] Normalized features and saved scaler as 'anomaly_scaler.pkl'")

# =====================================================================
# STEP 3: CONTAMINATION TUNING WITH SYNTHETIC ANOMALIES
# =====================================================================
print("\nTuning Outlier Detectors using Synthetic Anomaly Injection...")

# Inject synthetic outliers (scaling existing points to out-of-bound regions)
n_outliers = int(0.04 * len(X_scaled))
synthetic_outliers = X_scaled[:n_outliers] * 3.2  # Multiply by 3.2 std devs to shift out of range

X_eval = np.vstack([X_scaled, synthetic_outliers])
y_eval = np.hstack([np.zeros(len(X_scaled)), np.ones(len(synthetic_outliers))])

# Grid search for contamination factor on Isolation Forest
contaminations = [0.01, 0.02, 0.03, 0.04, 0.05]
best_f1 = 0
best_contamination = 0.03

for c in contaminations:
    test_model = IsolationForest(
        n_estimators=200,
        contamination=c,
        random_state=42,
        n_jobs=-1
    )
    test_model.fit(X_scaled)
    
    # predict: -1 = anomaly, 1 = normal
    y_pred = test_model.predict(X_eval)
    y_pred = np.where(y_pred == -1, 1, 0)
    
    # Calculate F1 score for anomaly class
    report = classification_report(y_eval, y_pred, output_dict=True)
    f1_anomaly = report['1.0']['f1-score']
    
    print(f"  Contamination: {c} -> F1 (Anomaly Class): {f1_anomaly:.4f}")
    if f1_anomaly > best_f1:
        best_f1 = f1_anomaly
        best_contamination = c

print(f"[OK] Selected Optimal Contamination Rate: {best_contamination}")

# =====================================================================
# STEP 4: TRAIN OPTIMIZED ENSEMBLE DETECTOR
# =====================================================================
print("\nTraining Ensemble Outlier Detectors...")

# Model 1: Isolation Forest
if_model = IsolationForest(
    n_estimators=300,
    max_samples=0.8,
    max_features=0.9,
    contamination=best_contamination,
    random_state=42,
    n_jobs=-1
)
if_model.fit(X_scaled)

# Model 2: One-Class SVM (Radial Basis Kernel)
oc_svm = OneClassSVM(
    nu=best_contamination, 
    kernel="rbf", 
    gamma="scale"
)
oc_svm.fit(X_scaled)

# Model 3: Local Outlier Factor (Novelty detection mode)
lof = LocalOutlierFactor(
    n_neighbors=25, 
    contamination=best_contamination,
    novelty=True, 
    n_jobs=-1
)
lof.fit(X_scaled)

class EnsembleDetector:
    """Voting ensemble combining Isolation Forest, OneClassSVM, and LocalOutlierFactor"""
    def __init__(self, models):
        self.models = models

    def predict(self, X):
        # Gather predictions from each model: 1 = normal, -1 = anomaly
        preds = np.stack([m.predict(X) for m in self.models], axis=1)
        
        # Soft/Hard voting: Anomaly if at least 2 models flag it as anomaly (-1)
        anomaly_votes = np.sum(preds == -1, axis=1)
        final_preds = np.where(anomaly_votes >= 2, -1, 1)
        return final_preds

    def decision_function(self, X):
        # Average anomaly scores (Isolation Forest decision function + normalized OCSVM scores)
        if_scores = self.models[0].decision_function(X)
        svm_scores = self.models[1].score_samples(X)
        # Scale SVM scores to align closer with Isolation Forest ranges
        svm_scores_scaled = (svm_scores - svm_scores.mean()) / (svm_scores.std() + 1e-8) * 0.1
        return (if_scores + svm_scores_scaled) / 2.0

ensemble = EnsembleDetector([if_model, oc_svm, lof])

# =====================================================================
# STEP 5: EVALUATION
# =====================================================================
# Predict on evaluation set containing injected anomalies
y_pred_eval = ensemble.predict(X_eval)
y_pred_eval = np.where(y_pred_eval == -1, 1, 0) # Convert -1 to 1 (anomaly), 1 to 0 (normal)

print(f"\n{'='*60}")
print("ENSEMBLE DETECTOR EVALUATION REPORT")
print(f"{'='*60}")
print(classification_report(y_eval, y_pred_eval, target_names=["Normal", "Anomaly"]))

# Calculate AUC-ROC
scores_eval = ensemble.decision_function(X_eval)
# invert decision scores so anomalies get higher score
auc_score = roc_auc_score(y_eval, -scores_eval)
print(f"ROC-AUC Score: {auc_score:.4f}")

# Save the ensemble using pickle
with open("anomaly_model.pkl", "wb") as f:
    pickle.dump(ensemble, f)
print("[OK] Ensemble model successfully saved to 'anomaly_model.pkl'")

# =====================================================================
# STEP 6: VISUALIZATIONS
# =====================================================================
cm = confusion_matrix(y_eval, y_pred_eval)

fig, axes = plt.subplots(1, 2, figsize=(14, 5))

# 1. Confusion Matrix
sns.heatmap(cm, annot=True, fmt="d", cmap="Oranges",
            xticklabels=["Predicted Normal", "Predicted Anomaly"],
            yticklabels=["Actual Normal", "Actual Anomaly"], ax=axes[0])
axes[0].set_title("Confusion Matrix (Injected Outliers Evaluation)")

# 2. ROC Curve
fpr, tpr, _ = roc_curve(y_eval, -scores_eval)
axes[1].plot(fpr, tpr, color="darkorange", lw=2, label=f"ROC curve (AUC = {auc_score:.3f})")
axes[1].plot([0, 1], [0, 1], color="navy", lw=1, linestyle="--")
axes[1].set_xlabel("False Positive Rate")
axes[1].set_ylabel("True Positive Rate")
axes[1].set_title("Receiver Operating Characteristic (ROC)")
axes[1].legend(loc="lower right")

plt.tight_layout()
plt.savefig('anomaly_evaluation_results.png', dpi=300)
plt.show()

# 3. Heart Rate vs Anomaly Scatter
df_results = df.copy()
y_pred_db = ensemble.predict(X_scaled)
df_results["anomaly_flag"] = np.where(y_pred_db == -1, 1, 0)

plt.figure(figsize=(12, 5))
normal = df_results[df_results["anomaly_flag"] == 0]
anomaly = df_results[df_results["anomaly_flag"] == 1]

plt.scatter(normal.index, normal["HR"], c="dodgerblue", alpha=0.5, s=15, label=f"Normal ({len(normal)})")
plt.scatter(anomaly.index, anomaly["HR"], c="crimson", alpha=0.9, s=25, label=f"Anomaly ({len(anomaly)})")
plt.title("Heart Rate Anomaly Detection (Trained Ensemble Output)")
plt.xlabel("Sample Index")
plt.ylabel("Heart Rate (BPM)")
plt.legend()
plt.tight_layout()
plt.savefig('anomaly_scatter_chart.png', dpi=300)
plt.show()
