# -*- coding: utf-8 -*-
"""
PPG Anomaly Detection Evaluator Script
Loads ensemble outlier detection models and PPG data to generate high-resolution evaluation graphs.
Saves all outputs to report_graphs/anomaly_detection/
"""

import os
import pickle
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.manifold import TSNE
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, roc_curve, auc, precision_recall_curve, average_precision_score

# Define output directory
OUTPUT_DIR = "d:/Anurag/b.tech/final_year_project/health_monitor_app/report_graphs/anomaly_detection"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Set styling
sns.set_theme(style="whitegrid")
plt.rcParams.update({
    'font.family': 'sans-serif',
    'font.size': 11,
    'axes.labelsize': 12,
    'axes.titlesize': 14,
    'xtick.labelsize': 10,
    'ytick.labelsize': 10,
    'figure.titlesize': 16
})

# Define the EnsembleDetector class so pickle can resolve it
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

print("Starting Anomaly Detection Evaluation Pipeline...")

# =====================================================================
# STEP 1: LOAD DATASET
# =====================================================================
csv_file = "features53.csv"
if not os.path.exists(csv_file):
    csv_file = "ML_models/Anomaly_Detection/features53.csv"

print(f"Loading data from: {csv_file}")
df = pd.read_csv(csv_file)

drop_cols = ["Patient_ID"]
df_features = df.drop(columns=[c for c in drop_cols if c in df.columns])
low_variance_cols = df_features.columns[df_features.nunique() <= 2]
if len(low_variance_cols) > 0:
    df_features = df_features.drop(columns=low_variance_cols)

print(f"Loaded feature matrix: {df_features.shape}")

# =====================================================================
# STEP 2: LOAD MODEL AND SCALER
# =====================================================================
scaler_path = "anomaly_scaler.pkl"
model_path = "anomaly_model.pkl"
if not os.path.exists(scaler_path):
    scaler_path = "ML_models/Anomaly_Detection/anomaly_scaler.pkl"
    model_path = "ML_models/Anomaly_Detection/anomaly_model.pkl"

print(f"Loading scaler from: {scaler_path}")
with open(scaler_path, 'rb') as f:
    scaler = pickle.load(f)

print(f"Loading model from: {model_path}")
with open(model_path, 'rb') as f:
    ensemble_model = pickle.load(f)

# Scale features
X_scaled = scaler.transform(df_features)

# =====================================================================
# STEP 3: CREATE EVALUATION SET (Injected Outliers Evaluation)
# =====================================================================
n_outliers = int(0.04 * len(X_scaled))
np.random.seed(42)
synthetic_outliers = X_scaled[:n_outliers] * 3.2
X_eval = np.vstack([X_scaled, synthetic_outliers])
y_eval = np.hstack([np.zeros(len(X_scaled)), np.ones(len(synthetic_outliers))])

# Run predictions
preds = ensemble_model.predict(X_eval)
# Convert -1 = Anomaly (1), 1 = Normal (0)
y_pred_eval = np.where(preds == -1, 1, 0)
scores_eval = -ensemble_model.decision_function(X_eval) # Invert scores so high = anomaly

print("Evaluation complete on evaluation set.")

# =====================================================================
# CHART 1: Confusion Matrix (Raw & Normalized)
# =====================================================================
cm = confusion_matrix(y_eval, y_pred_eval)
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

# Raw Heatmap
sns.heatmap(cm, annot=True, fmt='d', cmap='Oranges', ax=axes[0], cbar=False,
            xticklabels=["Predicted Normal", "Predicted Anomaly"],
            yticklabels=["Actual Normal", "Actual Anomaly"])
axes[0].set_title("Confusion Matrix (Raw Counts)", fontweight='bold', pad=10)

# Normalized Heatmap
cm_norm = cm.astype('float') / cm.sum(axis=1)[:, np.newaxis] * 100
sns.heatmap(cm_norm, annot=True, fmt='.1f', cmap='Oranges', ax=axes[1], cbar=False,
            xticklabels=["Predicted Normal", "Predicted Anomaly"],
            yticklabels=["Actual Normal", "Actual Anomaly"])
axes[1].set_title("Confusion Matrix (Normalized %)", fontweight='bold', pad=10)

plt.suptitle("PPG Anomaly Detection: Outlier Ensemble Confusion Matrix", fontweight='bold', y=1.02)
plt.tight_layout()
cm_path = os.path.join(OUTPUT_DIR, "ad_confusion_matrix.png")
plt.savefig(cm_path, dpi=300, bbox_inches='tight')
plt.close()
print(f"[SAVED] {cm_path}")

# =====================================================================
# CHART 2: ROC and PR Curves
# =====================================================================
fig, axes = plt.subplots(1, 2, figsize=(14, 5.5))

# ROC Curve
fpr, tpr, _ = roc_curve(y_eval, scores_eval)
roc_auc = auc(fpr, tpr)
axes[0].plot(fpr, tpr, color='darkorange', lw=2.5, label=f"ROC curve (AUC = {roc_auc:.4f})")
axes[0].plot([0, 1], [0, 1], color='navy', lw=1.5, linestyle='--')
axes[0].set_xlim([-0.01, 1.0])
axes[0].set_ylim([0.0, 1.05])
axes[0].set_xlabel("False Positive Rate (FPR)")
axes[0].set_ylabel("True Positive Rate (TPR)")
axes[0].set_title("Receiver Operating Characteristic (ROC)", fontweight='bold')
axes[0].legend(loc="lower right")
axes[0].grid(True, alpha=0.3)

# Precision-Recall Curve
precision, recall, _ = precision_recall_curve(y_eval, scores_eval)
average_precision = average_precision_score(y_eval, scores_eval)
axes[1].plot(recall, precision, color='teal', lw=2.5, label=f"PR curve (AP = {average_precision:.4f})")
axes[1].set_xlim([-0.01, 1.0])
axes[1].set_ylim([0.0, 1.05])
axes[1].set_xlabel("Recall (Sensitivity)")
axes[1].set_ylabel("Precision")
axes[1].set_title("Precision-Recall (PR) Curve", fontweight='bold')
axes[1].legend(loc="lower left")
axes[1].grid(True, alpha=0.3)

plt.suptitle("Outlier Detection Curves", fontweight='bold', y=1.02)
plt.tight_layout()
curves_path = os.path.join(OUTPUT_DIR, "ad_roc_pr_curves.png")
plt.savefig(curves_path, dpi=300, bbox_inches='tight')
plt.close()
print(f"[SAVED] {curves_path}")

# =====================================================================
# CHART 3: Dimensionality Reduction using t-SNE
# =====================================================================
print("Running t-SNE projection (sampling 1500 points for clear visualization)...")
sample_indices = np.random.choice(len(X_eval), min(1500, len(X_eval)), replace=False)
X_tsne_input = X_eval[sample_indices]
y_tsne_labels = y_eval[sample_indices]

tsne = TSNE(n_components=2, random_state=42, perplexity=30)
X_tsne = tsne.fit_transform(X_tsne_input)

plt.figure(figsize=(9, 6.5))
colors = ['#1f77b4', '#d62728'] # Blue for normal, Red for anomalies
labels = ['Normal', 'Injected Outlier']

for i, class_val in enumerate([0, 1]):
    idx = np.where(y_tsne_labels == class_val)[0]
    plt.scatter(X_tsne[idx, 0], X_tsne[idx, 1], c=colors[i], label=labels[i],
                alpha=0.6 if class_val == 0 else 0.9, s=20 if class_val == 0 else 35,
                edgecolors='none' if class_val == 0 else 'black', linewidths=0.5)

plt.title("PPG Vital Signal Clustering: 2D t-SNE Visualization", fontweight='bold', pad=15)
plt.xlabel("t-SNE Component 1")
plt.ylabel("t-SNE Component 2")
plt.legend(loc="best", frameon=True, facecolor='white', framealpha=0.9)
plt.tight_layout()
tsne_path = os.path.join(OUTPUT_DIR, "ad_tsne_visualization.png")
plt.savefig(tsne_path, dpi=300)
plt.close()
print(f"[SAVED] {tsne_path}")

# =====================================================================
# CHART 4: Heart Rate Timeline Anomaly Scatter
# =====================================================================
# Predict on database points
preds_db = ensemble_model.predict(X_scaled)
anomaly_flag_db = np.where(preds_db == -1, 1, 0)

plt.figure(figsize=(12, 5))
normal_idx = np.where(anomaly_flag_db == 0)[0]
anomaly_idx = np.where(anomaly_flag_db == 1)[0]

# Extract Heart Rate (usually the first feature, or 'HR' column)
hr_col = 'HR' if 'HR' in df.columns else df.columns[0]
hr_values = df[hr_col].values

plt.scatter(normal_idx, hr_values[normal_idx], c="dodgerblue", alpha=0.5, s=15, label=f"Normal ({len(normal_idx)})")
plt.scatter(anomaly_idx, hr_values[anomaly_idx], c="crimson", alpha=0.9, s=30, label=f"Anomaly ({len(anomaly_idx)})",
            edgecolors='black', linewidths=0.5)

plt.title("Heart Rate Anomaly Timeline (Trained Ensemble Output)", fontweight='bold', pad=15)
plt.xlabel("Time Sample Index")
plt.ylabel("Heart Rate (BPM)")
plt.legend(loc="upper right", frameon=True)
plt.grid(True, alpha=0.3)
plt.tight_layout()
scatter_path = os.path.join(OUTPUT_DIR, "ad_anomaly_scatter.png")
plt.savefig(scatter_path, dpi=300)
plt.close()
print(f"[SAVED] {scatter_path}")

# =====================================================================
# CHART 5: Anomaly Score Distribution Plot
# =====================================================================
plt.figure(figsize=(9, 5))
normal_scores = scores_eval[y_eval == 0]
anomaly_scores = scores_eval[y_eval == 1]

sns.kdeplot(normal_scores, fill=True, color="dodgerblue", alpha=0.4, label="Normal Vitals", lw=2)
sns.kdeplot(anomaly_scores, fill=True, color="crimson", alpha=0.4, label="Abnormal/Anomaly Vitals", lw=2)

plt.axvline(x=-0.0, color='gray', linestyle='--', lw=1.5, label="Decision Boundary")
plt.title("PPG Anomaly Score Distribution & Separation Margin", fontweight='bold', pad=15)
plt.xlabel("Ensemble Outlier Score (Higher = More Anomalous)")
plt.ylabel("Density Estimation")
plt.legend(loc="upper right")
plt.tight_layout()
score_path = os.path.join(OUTPUT_DIR, "ad_score_distribution.png")
plt.savefig(score_path, dpi=300)
plt.close()
print(f"[SAVED] {score_path}")

# =====================================================================
# CHART 6: Feature Distribution Boxplots
# Boxplots of the top features (e.g. Heart Rate, HRV, Skewness) comparing classes
# =====================================================================
# Map anomaly flags back to features
df_features_with_target = df_features.copy()
df_features_with_target['anomaly_status'] = np.where(preds_db == -1, 'Anomaly', 'Normal')

top_features = []
# Match common feature names, fallback to first 4 columns
known_feats = ['HR', 'HRV', 'Skewness', 'Kurtosis', 'avgHeartRate', 'hrv', 'skew', 'kurt']
for f in known_feats:
    if f in df_features_with_target.columns:
        top_features.append(f)
if len(top_features) < 4:
    for c in df_features_with_target.columns:
        if c not in top_features and c != 'anomaly_status' and len(top_features) < 4:
            top_features.append(c)

fig, axes = plt.subplots(2, 2, figsize=(12, 9))
axes = axes.flatten()

for i, feat in enumerate(top_features[:4]):
    sns.boxplot(data=df_features_with_target, x='anomaly_status', y=feat,
                palette={'Normal': 'skyblue', 'Anomaly': 'salmon'}, ax=axes[i], width=0.5)
    axes[i].set_title(f"{feat} Value Distribution", fontweight='bold')
    axes[i].set_xlabel("Vitals Status")
    axes[i].set_ylabel(feat)

plt.suptitle("PPG Features Distribution: Normal vs Anomaly Vitals", fontweight='bold', y=0.98)
plt.tight_layout()
boxplot_path = os.path.join(OUTPUT_DIR, "ad_feature_boxplots.png")
plt.savefig(boxplot_path, dpi=300)
plt.close()
print(f"[SAVED] {boxplot_path}")

print("Anomaly Detection Visualization Pipeline Completed Successfully!")
