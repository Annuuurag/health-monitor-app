# -*- coding: utf-8 -*-
"""
Optimized Heart Disease Prediction using Soft Voting Stacking Ensemble
Dataset: Cleveland Heart Disease (processed.cleveland.data)
Improvements:
- Fix scaling inconsistencies: ensure Random Forest and all classifiers train on scaled data.
- Hyperparameter tuning using GridSearchCV for Random Forest and XGBoost.
- SVM Classifier (SVC) integration with RBF kernel to capture non-linear relationships.
- Soft-Voting Ensemble Classifier (VotingClassifier) combining tuned Random Forest, XGBoost, and SVM.
- Outputs prediction_model.pkl (ensemble) and heart_scaler.pkl.
- Complete performance reports (Accuracy, ROC-AUC, Sensitivity, Specificity, Confusion Matrix).
"""

# =====================================================================
# IMPORTS
# =====================================================================
import pandas as pd
import numpy as np
import pickle
import json
from datetime import datetime
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier, VotingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, roc_auc_score, roc_curve
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
import warnings
warnings.filterwarnings('ignore')

from sklearn.ensemble import HistGradientBoostingClassifier

print("="*75)
print("OPTIMIZED HEART DISEASE PREDICTION")
print("="*75)

# =====================================================================
# STEP 1: LOAD AND CLEAN DATASET
# =====================================================================
columns = [
    "age", "sex", "cp", "trestbps", "chol",
    "fbs", "restecg", "thalach", "exang",
    "oldpeak", "slope", "ca", "thal", "target"
]

data_file = "processed.cleveland.data"
try:
    df = pd.read_csv(data_file, header=None, names=columns, na_values="?")
    print(f"[OK] Cleveland dataset loaded: {df.shape}")
except FileNotFoundError:
    print(f"Error: {data_file} not found in the current directory.")
    print("Please download it and place it in the same directory.")
    exit()

# Handle missing values: fill 'ca' and 'thal' with their medians
for col in ["ca", "thal"]:
    if df[col].isnull().sum() > 0:
        median_val = df[col].median()
        df[col] = df[col].fillna(median_val)
        print(f"  Filled missing values in {col} with median ({median_val})")

# Convert target to binary: 0 = No Disease, 1 = Disease (target > 0)
df["target"] = df["target"].apply(lambda x: 1 if x > 0 else 0)
print(f"Binary Target distribution:\n{df['target'].value_counts()}")

# Split features and target
X = df.drop("target", axis=1).values
y = df["target"].values
feature_names = [col for col in df.columns if col != "target"]

# Train-test split (80% train, 20% test, stratified)
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# =====================================================================
# STEP 2: ROBUST FEATURE SCALING
# =====================================================================
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# Save the fitted scaler
with open("heart_scaler.pkl", "wb") as f:
    pickle.dump(scaler, f)
print("[OK] Saved fitted standard scaler to 'heart_scaler.pkl'")

# =====================================================================
# STEP 3: HYPERPARAMETER TUNING VIA GRID SEARCH
# =====================================================================
print("\nGridSearchCV Tuning for Random Forest Classifier...")
rf_param_grid = {
    'n_estimators': [100, 200, 300],
    'max_depth': [5, 8, 10, None],
    'min_samples_split': [2, 5, 10],
    'max_features': ['sqrt', 'log2', None]
}
rf_grid = GridSearchCV(
    estimator=RandomForestClassifier(random_state=42),
    param_grid=rf_param_grid,
    cv=5,
    scoring='accuracy',
    n_jobs=-1
)
rf_grid.fit(X_train_scaled, y_train)
best_rf = rf_grid.best_estimator_
print(f"  Best RF Params: {rf_grid.best_params_}")
print(f"  Best RF Train CV Accuracy: {rf_grid.best_score_*100:.2f}%")

print("\nGridSearchCV Tuning for HistGradientBoosting Classifier...")
hgb_param_grid = {
    'max_iter': [50, 100, 150],
    'max_depth': [3, 5, 7, None],
    'learning_rate': [0.01, 0.05, 0.1, 0.2],
    'l2_regularization': [0.0, 0.1, 1.0]
}
hgb_grid = GridSearchCV(
    estimator=HistGradientBoostingClassifier(random_state=42),
    param_grid=hgb_param_grid,
    cv=5,
    scoring='accuracy',
    n_jobs=-1
)
hgb_grid.fit(X_train_scaled, y_train)
best_hgb = hgb_grid.best_estimator_
print(f"  Best HGB Params: {hgb_grid.best_params_}")
print(f"  Best HGB Train CV Accuracy: {hgb_grid.best_score_*100:.2f}%")

# Support Vector Machine (SVM) Classifier
print("\nGridSearchCV Tuning for Support Vector Machine (SVC)...")
svm_param_grid = {
    'C': [0.1, 1, 10, 100],
    'gamma': ['scale', 'auto', 0.01, 0.1, 1],
    'kernel': ['rbf', 'linear']
}
svm_grid = GridSearchCV(
    estimator=SVC(probability=True, random_state=42),
    param_grid=svm_param_grid,
    cv=5,
    scoring='accuracy',
    n_jobs=-1
)
svm_grid.fit(X_train_scaled, y_train)
best_svm = svm_grid.best_estimator_
print(f"  Best SVM Params: {svm_grid.best_params_}")
print(f"  Best SVM Train CV Accuracy: {svm_grid.best_score_*100:.2f}%")

# =====================================================================
# STEP 4: ENSEMBLE VOTING CLASSIFIER
# =====================================================================
print("\nBuilding Soft-Voting Ensemble Classifier...")

estimators = [
    ('rf', best_rf),
    ('svm', best_svm),
    ('hgb', best_hgb)
]

voting_ensemble = VotingClassifier(
    estimators=estimators,
    voting='soft'
)
voting_ensemble.fit(X_train_scaled, y_train)
print("[OK] Soft-Voting Ensemble trained successfully!")

# Save the ensemble model
with open("prediction_model.pkl", "wb") as f:
    pickle.dump(voting_ensemble, f)
print("[OK] Saved optimized ensemble model to 'prediction_model.pkl'")

# =====================================================================
# STEP 5: EVALUATION AND COMPARISONS
# =====================================================================
y_pred_train = voting_ensemble.predict(X_train_scaled)
y_pred_test = voting_ensemble.predict(X_test_scaled)
y_prob_test = voting_ensemble.predict_proba(X_test_scaled)[:, 1]

train_acc = accuracy_score(y_train, y_pred_train)
test_acc = accuracy_score(y_test, y_pred_test)
test_auc = roc_auc_score(y_test, y_prob_test)

cm = confusion_matrix(y_test, y_pred_test)
sensitivity = cm[1, 1] / (cm[1, 1] + cm[1, 0])
specificity = cm[0, 0] / (cm[0, 0] + cm[0, 1])

print(f"\n{'='*60}")
print("MODEL EVALUATION METRICS (TEST SET)")
print(f"{'='*60}")
print(f"Training Accuracy:   {train_acc*100:.2f}%")
print(f"Test Accuracy:       {test_acc*100:.2f}%")
print(f"Test ROC-AUC Score:  {test_auc:.4f}")
print(f"Sensitivity (Recall): {sensitivity*100:.2f}%")
print(f"Specificity:         {specificity*100:.2f}%")
print(f"{'='*60}")

print("\n[INFO] Detailed Classification Report:")
print(classification_report(y_test, y_pred_test, target_names=["No Disease", "Disease"]))

# Save training summary configuration
config = {
    'model_type': 'SoftVotingEnsemble',
    'training_date': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
    'dataset': 'Cleveland Heart Disease',
    'accuracy': {
        'train': float(train_acc),
        'test': float(test_acc)
    },
    'auc_roc': float(test_auc),
    'sensitivity': float(sensitivity),
    'specificity': float(specificity),
    'components': [name for name, _ in estimators]
}
with open('heart_disease_config.json', 'w') as f:
    json.dump(config, f, indent=4)
print("[OK] Configuration metadata saved to 'heart_disease_config.json'")

# =====================================================================
# STEP 6: VISUALIZATIONS
# =====================================================================
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

# 1. Confusion Matrix
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', ax=axes[0],
            xticklabels=['No Disease', 'Disease'],
            yticklabels=['No Disease', 'Disease'])
axes[0].set_title(f'Confusion Matrix (Test Accuracy: {test_acc*100:.1f}%)', fontweight='bold')
axes[0].set_ylabel('True Label')
axes[0].set_xlabel('Predicted Label')

# 2. ROC Curve
fpr, tpr, _ = roc_curve(y_test, y_prob_test)
axes[1].plot(fpr, tpr, color='crimson', lw=2.5, label=f'ROC curve (AUC = {test_auc:.3f})')
axes[1].plot([0, 1], [0, 1], color='gray', lw=1, linestyle='--')
axes[1].set_xlabel('False Positive Rate')
axes[1].set_ylabel('True Positive Rate')
axes[1].set_title('Receiver Operating Characteristic (ROC)', fontweight='bold')
axes[1].legend(loc="lower right")

plt.tight_layout()
plt.savefig('heart_disease_optimized_evaluation.png', dpi=300)
plt.show()

print("\n[OK] Training pipeline completed successfully! Model is fully optimized.")
print("="*60)
