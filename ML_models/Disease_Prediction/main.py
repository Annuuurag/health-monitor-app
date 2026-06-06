"""
============================================================================
❤️ HEART DISEASE PREDICTION - LOGISTIC REGRESSION
============================================================================
Dataset: Cleveland Heart Disease (processed.cleveland.data)
Model: Logistic Regression
Time: ~5 minutes to complete
============================================================================
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, roc_auc_score, roc_curve
import matplotlib.pyplot as plt
import seaborn as sns
import pickle
import json
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

print("="*80)
print("❤️  HEART DISEASE PREDICTION - LOGISTIC REGRESSION")
print("="*80)

# ============================================================================
# STEP 1: Load Cleveland Dataset
# ============================================================================

print("\n[1/8] Loading Cleveland Dataset...")

# Column names from UCI repository
column_names = [
    'age',              # Age in years
    'sex',              # Sex (1 = male; 0 = female)
    'cp',               # Chest pain type (1-4)
    'trestbps',         # Resting blood pressure (mm Hg)
    'chol',             # Serum cholesterol (mg/dl)
    'fbs',              # Fasting blood sugar > 120 mg/dl
    'restecg',          # Resting ECG results (0-2)
    'thalach',          # Maximum heart rate achieved
    'exang',            # Exercise induced angina
    'oldpeak',          # ST depression
    'slope',            # Slope of peak exercise ST segment
    'ca',               # Number of major vessels (0-3)
    'thal',             # Thalassemia
    'target'            # Diagnosis (0-4)
]

# Load data file
DATA_FILE = "processed.cleveland.data"

try:
    df = pd.read_csv(DATA_FILE, names=column_names, na_values='?')
    print(f"✓ Dataset loaded: {df.shape}")
    print(f"  Rows: {df.shape[0]}")
    print(f"  Columns: {df.shape[1]}")
except FileNotFoundError:
    print(f"❌ Error: File not found: {DATA_FILE}")
    print("\n💡 Please ensure 'processed.cleveland.data' is in the current directory")
    print("   Download from: https://archive.ics.uci.edu/ml/datasets/heart+disease")
    exit()

print(f"\nColumn names:")
print(column_names)

print(f"\nFirst 5 rows:")
print(df.head())

# ============================================================================
# STEP 2: Data Exploration
# ============================================================================

print("\n" + "="*80)
print("[2/8] Data Exploration")
print("="*80)

print(f"\nDataset Info:")
print(f"  Total samples: {len(df)}")
print(f"  Features: {len(df.columns) - 1}")

# Check missing values
print(f"\n🔍 Missing Values:")
missing = df.isnull().sum()
if missing.sum() > 0:
    print(missing[missing > 0])
    print(f"\nTotal missing: {missing.sum()} values")
else:
    print("✓ No missing values")

# Target distribution
print(f"\n🎯 Target Distribution (Original):")
print(df['target'].value_counts().sort_index())

# Show data types
print(f"\n📊 Data Types:")
print(df.dtypes)

# ============================================================================
# STEP 3: Data Preprocessing
# ============================================================================

print("\n" + "="*80)
print("[3/8] Data Preprocessing")
print("="*80)

# Step 3.1: Handle Missing Values
print("\n⚙️ Handling missing values...")

if df.isnull().sum().sum() > 0:
    # For 'ca' and 'thal' which have missing values
    for col in ['ca', 'thal']:
        if col in df.columns and df[col].isnull().sum() > 0:
            median_val = df[col].median()
            df[col].fillna(median_val, inplace=True)
            print(f"  ✓ {col}: filled {df[col].isnull().sum()} missing values with median ({median_val})")
    
    # Check for any remaining missing values
    remaining_missing = df.isnull().sum().sum()
    if remaining_missing > 0:
        print(f"  ⚠️ Remaining missing values: {remaining_missing}")
        df.dropna(inplace=True)
        print(f"  ✓ Dropped rows with missing values. New size: {len(df)}")
    else:
        print(f"  ✓ All missing values handled")
else:
    print("  ✓ No missing values to handle")

# Step 3.2: Convert Target to Binary
print("\n⚙️ Converting target to binary classification...")
print(f"Original target values: {sorted(df['target'].unique())}")

# 0 = no disease, 1-4 = disease present
df['target'] = (df['target'] > 0).astype(int)

print(f"\nBinary target distribution:")
print(f"  0 (No Disease): {(df['target']==0).sum()} samples ({(df['target']==0).sum()/len(df)*100:.1f}%)")
print(f"  1 (Disease):    {(df['target']==1).sum()} samples ({(df['target']==1).sum()/len(df)*100:.1f}%)")

# Step 3.3: Check for outliers
print("\n📊 Statistical Summary:")
print(df.describe())

# ============================================================================
# STEP 4: Feature and Target Separation
# ============================================================================

print("\n" + "="*80)
print("[4/8] Preparing Features and Target")
print("="*80)

# Separate features and target
X = df.drop('target', axis=1).values
y = df['target'].values

feature_names = [col for col in df.columns if col != 'target']

print(f"\n✓ Feature matrix shape: {X.shape}")
print(f"✓ Target vector shape: {y.shape}")
print(f"\n✓ Feature names ({len(feature_names)}):")
for i, name in enumerate(feature_names, 1):
    print(f"  {i:2d}. {name}")

# ============================================================================
# STEP 5: Train-Test Split
# ============================================================================

print("\n" + "="*80)
print("[5/8] Train-Test Split")
print("="*80)

# Split dataset (80-20 split with stratification)
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y  # type: ignore
)

print(f"\n✓ Split Configuration:")
print(f"  Training set: {len(X_train)} samples ({len(X_train)/len(X)*100:.1f}%)")
print(f"  Test set:     {len(X_test)} samples ({len(X_test)/len(X)*100:.1f}%)")

print(f"\n  Train distribution:")
print(f"    No Disease: {(y_train==0).sum()} ({(y_train==0).sum()/len(y_train)*100:.1f}%)")
print(f"    Disease:    {(y_train==1).sum()} ({(y_train==1).sum()/len(y_train)*100:.1f}%)")

print(f"\n  Test distribution:")
print(f"    No Disease: {(y_test==0).sum()} ({(y_test==0).sum()/len(y_test)*100:.1f}%)")
print(f"    Disease:    {(y_test==1).sum()} ({(y_test==1).sum()/len(y_test)*100:.1f}%)")

# ============================================================================
# STEP 6: Feature Scaling
# ============================================================================

print("\n" + "="*80)
print("[6/8] Feature Scaling")
print("="*80)

scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

print(f"\n✓ Features scaled using StandardScaler")
print(f"  Training set scaled: {X_train_scaled.shape}")
print(f"  Test set scaled:     {X_test_scaled.shape}")

print(f"\n  Sample scaling (first feature):")
print(f"    Original mean: {X_train[:, 0].mean():.2f}")
print(f"    Scaled mean:   {X_train_scaled[:, 0].mean():.2f}")
print(f"    Scaled std:    {X_train_scaled[:, 0].std():.2f}")

# ============================================================================
# STEP 7: Train Logistic Regression Model
# ============================================================================

print("\n" + "="*80)
print("[7/8] Training Logistic Regression Model")
print("="*80)

print("\n⚙️ Model Configuration:")
print("  • Algorithm: Logistic Regression")
print("  • Solver: lbfgs")
print("  • Max iterations: 1000")
print("  • Random state: 42")

print("\n🔄 Training in progress...")

# Train model
model = LogisticRegression(
    max_iter=1000,
    random_state=42,
    solver='lbfgs'
)

model.fit(X_train_scaled, y_train)

print("✓ Training complete!")

# Get model coefficients
print("\n📊 Model Coefficients:")
coefficients = pd.DataFrame({
    'feature': feature_names,
    'coefficient': model.coef_[0]
}).sort_values('coefficient', key=abs, ascending=False)

print(coefficients)

print(f"\n  Intercept: {model.intercept_[0]:.4f}")

# ============================================================================
# STEP 8: Model Evaluation
# ============================================================================

print("\n" + "="*80)
print("[8/8] Model Evaluation")
print("="*80)

# Predictions
y_pred_train = model.predict(X_train_scaled)
y_pred_test = model.predict(X_test_scaled)

# Prediction probabilities
y_pred_proba_train = model.predict_proba(X_train_scaled)[:, 1]
y_pred_proba_test = model.predict_proba(X_test_scaled)[:, 1]

# Calculate metrics
train_accuracy = accuracy_score(y_train, y_pred_train)
test_accuracy = accuracy_score(y_test, y_pred_test)

train_auc = roc_auc_score(y_train, y_pred_proba_train)
test_auc = roc_auc_score(y_test, y_pred_proba_test)

print(f"\n📊 Performance Metrics:")
print(f"\n  Training Set:")
print(f"    Accuracy: {train_accuracy*100:.2f}%")
print(f"    ROC-AUC:  {train_auc:.4f}")

print(f"\n  Test Set:")
print(f"    Accuracy: {test_accuracy*100:.2f}%")
print(f"    ROC-AUC:  {test_auc:.4f}")

# Detailed classification report
print(f"\n📋 Classification Report (Test Set):")
print(classification_report(y_test, y_pred_test, 
                          target_names=['No Disease', 'Disease']))

# Confusion Matrix
cm = confusion_matrix(y_test, y_pred_test)
print(f"\n🔢 Confusion Matrix (Test Set):")
print(cm)
print(f"\n  True Negatives:  {cm[0,0]}")
print(f"  False Positives: {cm[0,1]}")
print(f"  False Negatives: {cm[1,0]}")
print(f"  True Positives:  {cm[1,1]}")

# Calculate additional metrics
sensitivity = cm[1,1] / (cm[1,1] + cm[1,0])  # Recall for disease class
specificity = cm[0,0] / (cm[0,0] + cm[0,1])  # Recall for no disease class

print(f"\n  Sensitivity (Recall): {sensitivity*100:.2f}%")
print(f"  Specificity:          {specificity*100:.2f}%")

# ============================================================================
# VISUALIZATIONS
# ============================================================================

print("\n" + "="*80)
print("Creating Visualizations...")
print("="*80)

fig, axes = plt.subplots(2, 2, figsize=(15, 12))

# 1. Confusion Matrix
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', ax=axes[0, 0],
           xticklabels=['No Disease', 'Disease'],
           yticklabels=['No Disease', 'Disease'])
axes[0, 0].set_title(f'Confusion Matrix\nTest Accuracy: {test_accuracy*100:.1f}%', 
                     fontweight='bold', fontsize=12)
axes[0, 0].set_ylabel('True Label', fontweight='bold')
axes[0, 0].set_xlabel('Predicted Label', fontweight='bold')

# 2. ROC Curve
fpr, tpr, thresholds = roc_curve(y_test, y_pred_proba_test)
axes[0, 1].plot(fpr, tpr, color='blue', lw=2, label=f'ROC curve (AUC = {test_auc:.3f})')
axes[0, 1].plot([0, 1], [0, 1], color='gray', lw=1, linestyle='--', label='Random')
axes[0, 1].set_xlim([0.0, 1.0])
axes[0, 1].set_ylim([0.0, 1.05])
axes[0, 1].set_xlabel('False Positive Rate', fontweight='bold')
axes[0, 1].set_ylabel('True Positive Rate', fontweight='bold')
axes[0, 1].set_title('ROC Curve', fontweight='bold', fontsize=12)
axes[0, 1].legend(loc="lower right")
axes[0, 1].grid(True, alpha=0.3)

# 3. Feature Coefficients
top_features = coefficients.head(10)
colors = ['red' if x < 0 else 'green' for x in top_features['coefficient']]
axes[1, 0].barh(top_features['feature'], top_features['coefficient'], color=colors, alpha=0.7)
axes[1, 0].set_xlabel('Coefficient Value', fontweight='bold')
axes[1, 0].set_title('Top 10 Feature Coefficients', fontweight='bold', fontsize=12)
axes[1, 0].axvline(x=0, color='black', linestyle='--', linewidth=1)
axes[1, 0].invert_yaxis()
axes[1, 0].grid(True, alpha=0.3, axis='x')

# 4. Prediction Probability Distribution
axes[1, 1].hist(y_pred_proba_test[y_test==0], bins=20, alpha=0.7, 
               label='No Disease', color='green', edgecolor='black')
axes[1, 1].hist(y_pred_proba_test[y_test==1], bins=20, alpha=0.7, 
               label='Disease', color='red', edgecolor='black')
axes[1, 1].axvline(x=0.5, color='black', linestyle='--', linewidth=2, label='Threshold (0.5)')
axes[1, 1].set_xlabel('Predicted Probability', fontweight='bold')
axes[1, 1].set_ylabel('Count', fontweight='bold')
axes[1, 1].set_title('Prediction Probability Distribution', fontweight='bold', fontsize=12)
axes[1, 1].legend()
axes[1, 1].grid(True, alpha=0.3, axis='y')

plt.tight_layout()
plt.savefig('heart_disease_logistic_regression.png', dpi=300, bbox_inches='tight')
print("✓ Visualization saved: heart_disease_logistic_regression.png")
plt.show()

# ============================================================================
# SAVE MODEL AND CONFIGURATION
# ============================================================================

print("\n" + "="*80)
print("Saving Model and Configuration")
print("="*80)

# Save model
with open('heart_disease_model.pkl', 'wb') as f:
    pickle.dump(model, f)
print("✓ Model saved: heart_disease_model.pkl")

# Save scaler
with open('heart_scaler.pkl', 'wb') as f:
    pickle.dump(scaler, f)
print("✓ Scaler saved: heart_scaler.pkl")

# Save configuration
config = {
    'model_type': 'LogisticRegression',
    'training_date': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
    'dataset': 'Cleveland Heart Disease',
    'dataset_size': len(df),
    'train_samples': len(X_train),
    'test_samples': len(X_test),
    'feature_names': feature_names,
    'solver': 'lbfgs',
    'max_iter': 1000,
    'performance': {
        'train_accuracy': float(train_accuracy),
        'test_accuracy': float(test_accuracy),
        'train_auc': float(train_auc),
        'test_auc': float(test_auc),
        'sensitivity': float(sensitivity),
        'specificity': float(specificity)
    },
    'feature_coefficients': {
        feat: float(coef) for feat, coef in 
        zip(coefficients['feature'], coefficients['coefficient'])
    }
}

with open('heart_disease_config.json', 'w') as f:
    json.dump(config, f, indent=4)
print("✓ Configuration saved: heart_disease_config.json")

# ============================================================================
# SUMMARY
# ============================================================================

print("\n" + "="*80)
print("✅ TRAINING COMPLETE!")
print("="*80)

print(f"""
╔════════════════════════════════════════════════════════════════╗
║     HEART DISEASE PREDICTION - LOGISTIC REGRESSION             ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  📊 Dataset:                                                   ║
║     • Source: Cleveland Heart Disease                          ║
║     • Total Samples: {len(df):<42} ║
║     • Training Set: {len(X_train):<43} ║
║     • Test Set: {len(X_test):<47} ║
║                                                                ║
║  🤖 Model Performance:                                         ║
║     • Training Accuracy: {train_accuracy*100:5.2f}%{' '*32}║
║     • Test Accuracy:     {test_accuracy*100:5.2f}%{' '*32}║
║     • Test ROC-AUC:      {test_auc:.4f}{' '*33}║
║     • Sensitivity:       {sensitivity*100:5.2f}%{' '*32}║
║     • Specificity:       {specificity*100:5.2f}%{' '*32}║
║                                                                ║
║  💾 Saved Files:                                               ║
║     ✓ heart_disease_model.pkl                                  ║
║     ✓ heart_scaler.pkl                                         ║
║     ✓ heart_disease_config.json                                ║
║     ✓ heart_disease_logistic_regression.png                    ║
║                                                                ║
║  🎯 Top 3 Most Important Features:                             ║
║     1. {coefficients.iloc[0]['feature']:<51} ║
║     2. {coefficients.iloc[1]['feature']:<51} ║
║     3. {coefficients.iloc[2]['feature']:<51} ║
║                                                                ║
║  🚀 Next Step:                                                 ║
║     Integrate into unified API with other models!              ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
""")

print(f"\n✅ Logistic Regression model trained successfully!")
print(f"📦 Model ready for deployment!\n")