# -*- coding: utf-8 -*-
"""
Heart Disease Prediction Evaluator Script
Loads ensemble prediction model and processed Cleveland dataset to generate high-resolution evaluation graphs.
Saves all outputs to report_graphs/disease_prediction/
"""

import os
import pickle
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, roc_curve, auc, precision_recall_curve, average_precision_score, roc_auc_score

# Define output directory
OUTPUT_DIR = "d:/Anurag/b.tech/final_year_project/health_monitor_app/report_graphs/disease_prediction"
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

print("Starting Disease Prediction Evaluation Pipeline...")

# =====================================================================
# STEP 1: LOAD AND CLEAN DATASET
# =====================================================================
columns = [
    "age", "sex", "cp", "trestbps", "chol",
    "fbs", "restecg", "thalach", "exang",
    "oldpeak", "slope", "ca", "thal", "target"
]

data_file = "processed.cleveland.data"
if not os.path.exists(data_file):
    data_file = "ML_models/Disease_Prediction/processed.cleveland.data"

print(f"Loading Cleveland Heart Disease dataset from: {data_file}")
df = pd.read_csv(data_file, header=None, names=columns, na_values="?")

# Fill missing values
for col in ["ca", "thal"]:
    if df[col].isnull().sum() > 0:
        median_val = df[col].median()
        df[col] = df[col].fillna(median_val)

# Target target to binary: 0 = No Disease, 1 = Disease
df["target"] = df["target"].apply(lambda x: 1 if x > 0 else 0)

# Split features and target
feature_names = [col for col in df.columns if col != "target"]
X = df[feature_names].values
y = df["target"].values

# Train-test split (exact same split as optimized_disease_prediction.py)
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# =====================================================================
# CHART 5: Dataset Correlation Matrix Heatmap
# =====================================================================
plt.figure(figsize=(11, 8.5))
corr = df.corr()
mask = np.triu(np.ones_like(corr, dtype=bool))
sns.heatmap(corr, mask=mask, annot=True, fmt='.2f', cmap='coolwarm', square=True,
            linewidths=0.5, cbar_kws={"shrink": 0.75})
plt.title("Cleveland Dataset: Attribute Correlation Heatmap", fontweight='bold', pad=15)
plt.tight_layout()
corr_path = os.path.join(OUTPUT_DIR, "dp_correlation_matrix.png")
plt.savefig(corr_path, dpi=300)
plt.close()
print(f"[SAVED] {corr_path}")

# =====================================================================
# STEP 2: LOAD MODEL AND SCALER
# =====================================================================
scaler_path = "heart_scaler.pkl"
model_path = "prediction_model.pkl"
if not os.path.exists(scaler_path):
    scaler_path = "ML_models/Disease_Prediction/heart_scaler.pkl"
    model_path = "ML_models/Disease_Prediction/prediction_model.pkl"

print(f"Loading scaler from: {scaler_path}")
with open(scaler_path, 'rb') as f:
    scaler = pickle.load(f)

print(f"Loading model from: {model_path}")
with open(model_path, 'rb') as f:
    voting_ensemble = pickle.load(f)

# Scale data
X_test_scaled = scaler.transform(X_test)

# Run prediction
y_pred = voting_ensemble.predict(X_test_scaled)
y_prob = voting_ensemble.predict_proba(X_test_scaled)[:, 1]
acc = accuracy_score(y_test, y_pred)

print(f"Ensemble Test Accuracy: {acc*100:.2f}%")

# =====================================================================
# CHART 1: Confusion Matrix (Raw & Normalized)
# =====================================================================
cm = confusion_matrix(y_test, y_pred)
fig, axes = plt.subplots(1, 2, figsize=(14, 5.5))

# Raw Heatmap
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', ax=axes[0], cbar=False,
            xticklabels=['No Disease', 'Disease'],
            yticklabels=['No Disease', 'Disease'])
axes[0].set_title("Confusion Matrix (Raw Counts)", fontweight='bold')
axes[0].set_ylabel("True Label")
axes[0].set_xlabel("Predicted Label")

# Normalized Heatmap
cm_norm = cm.astype('float') / cm.sum(axis=1)[:, np.newaxis] * 100
sns.heatmap(cm_norm, annot=True, fmt='.1f', cmap='Blues', ax=axes[1], cbar=False,
            xticklabels=['No Disease', 'Disease'],
            yticklabels=['No Disease', 'Disease'])
axes[1].set_title("Confusion Matrix (Normalized %)", fontweight='bold')
axes[1].set_ylabel("True Label")
axes[1].set_xlabel("Predicted Label")

plt.suptitle(f"Soft-Voting Stacking Ensemble performance (Test Acc: {acc*100:.1f}%)", fontweight='bold', y=1.02)
plt.tight_layout()
cm_path = os.path.join(OUTPUT_DIR, "dp_confusion_matrix.png")
plt.savefig(cm_path, dpi=300, bbox_inches='tight')
plt.close()
print(f"[SAVED] {cm_path}")

# =====================================================================
# CHART 2: ROC and PR Curves
# =====================================================================
fig, axes = plt.subplots(1, 2, figsize=(14, 5.5))

# ROC Curve
fpr, tpr, _ = roc_curve(y_test, y_prob)
roc_auc = auc(fpr, tpr)
axes[0].plot(fpr, tpr, color='crimson', lw=2.5, label=f"ROC curve (AUC = {roc_auc:.4f})")
axes[0].plot([0, 1], [0, 1], color='gray', lw=1.5, linestyle='--')
axes[0].set_xlim([-0.01, 1.0])
axes[0].set_ylim([0.0, 1.05])
axes[0].set_xlabel("False Positive Rate (FPR)")
axes[0].set_ylabel("True Positive Rate (TPR)")
axes[0].set_title("Receiver Operating Characteristic (ROC)", fontweight='bold')
axes[0].legend(loc="lower right")
axes[0].grid(True, alpha=0.3)

# PR Curve
precision, recall, _ = precision_recall_curve(y_test, y_prob)
average_precision = average_precision_score(y_test, y_prob)
axes[1].plot(recall, precision, color='purple', lw=2.5, label=f"PR curve (AP = {average_precision:.4f})")
axes[1].set_xlim([-0.01, 1.0])
axes[1].set_ylim([0.0, 1.05])
axes[1].set_xlabel("Recall (Sensitivity)")
axes[1].set_ylabel("Precision")
axes[1].set_title("Precision-Recall (PR) Curve", fontweight='bold')
axes[1].legend(loc="lower left")
axes[1].grid(True, alpha=0.3)

plt.suptitle("Heart Disease Prediction Evaluation Curves", fontweight='bold', y=1.02)
plt.tight_layout()
curves_path = os.path.join(OUTPUT_DIR, "dp_roc_pr_curves.png")
plt.savefig(curves_path, dpi=300, bbox_inches='tight')
plt.close()
print(f"[SAVED] {curves_path}")

# =====================================================================
# CHART 3: Feature Importance (Random Forest Component)
# =====================================================================
rf_clf = voting_ensemble.named_estimators_['rf']
importances = rf_clf.feature_importances_
indices = np.argsort(importances)[::-1]

# Sort feature names and importances
sorted_features = [feature_names[i] for i in indices]
sorted_importances = importances[indices]

# Standard feature abbreviations to user-friendly titles
feature_labels = {
    'age': 'Age', 'sex': 'Sex (Gender)', 'cp': 'Chest Pain Type (cp)',
    'trestbps': 'Resting Blood Pressure (trestbps)', 'chol': 'Serum Cholesterol (chol)',
    'fbs': 'Fasting Blood Sugar (fbs)', 'restecg': 'Resting ECG (restecg)',
    'thalach': 'Max Heart Rate Achieved (thalach)', 'exang': 'Exercise Induced Angina (exang)',
    'oldpeak': 'ST Depression (oldpeak)', 'slope': 'Slope of Peak Exercise ST (slope)',
    'ca': 'Major Vessels Colored (ca)', 'thal': 'Thalassemia Type (thal)'
}
sorted_labels = [feature_labels.get(f, f) for f in sorted_features]

plt.figure(figsize=(10, 6.5))
sns.barplot(x=sorted_importances, y=sorted_labels, palette="viridis")
plt.title("Heart Disease Prediction: Clinical Feature Importance (Random Forest)", fontweight='bold', pad=15)
plt.xlabel("Gini Importance Value")
plt.ylabel("Clinical Attribute")
plt.tight_layout()
importance_path = os.path.join(OUTPUT_DIR, "dp_feature_importance.png")
plt.savefig(importance_path, dpi=300)
plt.close()
print(f"[SAVED] {importance_path}")

# =====================================================================
# CHART 4: Base Models vs. Ensemble Stacking Comparison
# =====================================================================
print("Computing individual model performances for comparison...")
model_metrics = []

# Base models
for name, clf in voting_ensemble.named_estimators_.items():
    clf_pred = clf.predict(X_test_scaled)
    clf_prob = clf.predict_proba(X_test_scaled)[:, 1]
    
    clf_acc = accuracy_score(y_test, clf_pred)
    clf_auc = roc_auc_score(y_test, clf_prob)
    
    # Sensitivity and Specificity
    clf_cm = confusion_matrix(y_test, clf_pred)
    clf_sens = clf_cm[1, 1] / (clf_cm[1, 1] + clf_cm[1, 0])
    clf_spec = clf_cm[0, 0] / (clf_cm[0, 0] + clf_cm[0, 1])
    
    model_name = {
        'rf': 'Random Forest',
        'svm': 'Support Vector Machine (SVC)',
        'hgb': 'HistGradientBoosting'
    }.get(name, name)
    
    model_metrics.append({
        'Model': model_name,
        'Accuracy': clf_acc,
        'ROC-AUC': clf_auc,
        'Sensitivity': clf_sens,
        'Specificity': clf_spec
    })

# Add Ensemble Stacking
ens_cm = confusion_matrix(y_test, y_pred)
ens_sens = ens_cm[1, 1] / (ens_cm[1, 1] + ens_cm[1, 0])
ens_spec = ens_cm[0, 0] / (ens_cm[0, 0] + ens_cm[0, 1])
model_metrics.append({
    'Model': 'Soft-Voting Ensemble (Stack)',
    'Accuracy': acc,
    'ROC-AUC': roc_auc_score(y_test, y_prob),
    'Sensitivity': ens_sens,
    'Specificity': ens_spec
})

metrics_df = pd.DataFrame(model_metrics)
print("Metric calculations completed:")
print(metrics_df.to_string())

# Plot comparison
metrics_melted = pd.melt(metrics_df, id_vars="Model", var_name="Metric", value_name="Value")
plt.figure(figsize=(11, 6.5))
ax = sns.barplot(data=metrics_melted, x="Metric", y="Value", hue="Model", palette="muted")
plt.title("Performance Comparison: Individual Models vs. Stacking Ensemble", fontweight='bold', pad=15)
plt.xlabel("Performance Metric")
plt.ylabel("Score (0.0 to 1.0)")
plt.ylim([0.65, 1.03]) # Zoom in to see performance differences clearly
plt.legend(loc="lower right", frameon=True)
plt.grid(axis='y', alpha=0.3)

# Put value labels on top of bars
for p in ax.patches:
    h = p.get_height()
    if h > 0:
        ax.annotate(f"{h*100:.1f}%", (p.get_x() + p.get_width() / 2., h),
                    ha='center', va='bottom', fontsize=8, color='black', xytext=(0, 2),
                    textcoords='offset points', fontweight='bold')

plt.tight_layout()
comp_path = os.path.join(OUTPUT_DIR, "dp_model_comparison.png")
plt.savefig(comp_path, dpi=300)
plt.close()
print(f"[SAVED] {comp_path}")

print("Disease Prediction Visualization Pipeline Completed Successfully!")
