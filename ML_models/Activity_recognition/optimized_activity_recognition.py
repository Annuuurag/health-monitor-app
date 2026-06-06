# -*- coding: utf-8 -*-
"""
Optimized Activity Recognition using 1D CNN + Bidirectional LSTM
Dataset: WISDM (raw accelerometer x, y, z)
Improvements:
- Grouped split by User ID using GroupShuffleSplit to prevent data leakage.
- Standard scaling based strictly on the training set features.
- 1D Convolutional layers (Conv1D + MaxPool1D) for spatial-temporal feature extraction.
- Bidirectional LSTM layers (BiLSTM) for sequential modeling in both directions.
- ReduceLROnPlateau & EarlyStopping callbacks to optimize training convergence.
- Class weighting to handle dataset imbalance.
- Save model as 'activity_model.keras' for cloud deployment.
"""

# =====================================================================
# IMPORTS
# =====================================================================
import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import GroupShuffleSplit
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
from sklearn.utils import class_weight
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, regularizers
import warnings
warnings.filterwarnings('ignore')

print("TensorFlow Version:", tf.__version__)
print("GPU Available:", len(tf.config.list_physical_devices('GPU')) > 0)

# =====================================================================
# STEP 1: UPLOAD + LOAD WISDM DATASET
# =====================================================================
# Try to auto-load or prompt upload in Colab
filename = "WISDM_ar_v1.1_raw.txt"

if not os.path.exists(filename):
    try:
        from google.colab import files
        print("Please upload the WISDM dataset ('WISDM_ar_v1.1_raw.txt')")
        uploaded = files.upload()
        filename = list(uploaded.keys())[0]
    except ImportError:
        print(f"Error: {filename} not found in the current directory.")
        print("Please download it from WISDM lab and place it in the same directory.")

def load_wisdm_data(file_path):
    """Load WISDM raw text data safely, skipping malformed lines."""
    print(f"Loading dataset from {file_path}...")
    data_list = []
    skipped = 0

    with open(file_path, 'r') as f:
        for line in f:
            line = line.strip().replace(';', '')
            if not line:
                continue
            parts = line.split(',')
            try:
                if len(parts) >= 6:
                    user = int(parts[0])
                    activity = parts[1].strip()
                    timestamp = int(parts[2])
                    x, y, z = map(float, parts[3:6])
                    data_list.append([user, activity, timestamp, x, y, z])
                else:
                    skipped += 1
            except (ValueError, IndexError):
                skipped += 1
                continue

    df = pd.DataFrame(data_list, columns=['user', 'activity', 'timestamp', 'x', 'y', 'z'])
    print(f"[OK] Loaded {len(df):,} samples ({skipped:,} skipped rows).")
    print(f"Unique Users: {df['user'].nunique()} | Unique Activities: {df['activity'].nunique()}")
    print("\nActivity counts:")
    print(df['activity'].value_counts())
    return df

df_wisdm = load_wisdm_data(filename)

# =====================================================================
# STEP 2: CREATE SLIDING WINDOW SEGMENTS (with User Tracking)
# =====================================================================
def create_segments_with_user(data, window_size=80, step=40):
    """
    Generate sliding windows for LSTM.
    Includes user tracking to ensure we split by group.
    """
    segments, labels, users = [], [], []
    for user in data['user'].unique():
        user_data = data[data['user'] == user]
        for activity in user_data['activity'].unique():
            act_data = user_data[user_data['activity'] == activity]
            values = act_data[['x', 'y', 'z']].values
            for i in range(0, len(values) - window_size, step):
                segments.append(values[i:i+window_size])
                labels.append(activity)
                users.append(user)
    return np.array(segments), np.array(labels), np.array(users)

X, y, users = create_segments_with_user(df_wisdm, window_size=80, step=40)
print(f"Generated {len(X):,} segments. Shape: {X.shape}")

# Encode labels
label_encoder = LabelEncoder()
y_encoded = label_encoder.fit_transform(y)
num_classes = len(label_encoder.classes_)
print("Encoded classes:", list(label_encoder.classes_))

# =====================================================================
# STEP 3: GROUPED TRAIN/VAL/TEST SPLITS (No Data Leakage)
# =====================================================================
# 1. Split out Test set (20% of users)
gss_test = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
train_val_idx, test_idx = next(gss_test.split(X, y_encoded, groups=users))

X_train_val, X_test = X[train_val_idx], X[test_idx]
y_train_val, y_test = y_encoded[train_val_idx], y_encoded[test_idx]
users_train_val, users_test = users[train_val_idx], users[test_idx]

# 2. Split Train_Val -> Train (80%) and Val (20%) by users
gss_val = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=24)
train_idx, val_idx = next(gss_val.split(X_train_val, y_train_val, groups=users_train_val))

X_train, X_val = X_train_val[train_idx], X_train_val[val_idx]
y_train, y_val = y_train_val[train_idx], y_train_val[val_idx]
users_train, users_val = users_train_val[train_idx], users_train_val[val_idx]

print(f"Split completed:\n - Train samples: {len(X_train)} (Users: {np.unique(users_train)})\n - Val samples:   {len(X_val)} (Users: {np.unique(users_val)})\n - Test samples:  {len(X_test)} (Users: {np.unique(users_test)})")

# =====================================================================
# STEP 4: STANDARD NORMALIZATION (Scaling)
# =====================================================================
# Compute scaler parameters solely on training data
mean = X_train.mean(axis=(0, 1))
std = X_train.std(axis=(0, 1)) + 1e-8

# Normalize
X_train = (X_train - mean) / std
X_val = (X_val - mean) / std
X_test = (X_test - mean) / std

# Save mean and std for real-time inference
np.save('activity_mean.npy', mean)
np.save('activity_std.npy', std)
print("[OK] Saved normalization parameters: activity_mean.npy and activity_std.npy")

# =====================================================================
# STEP 5: BUILD CNN-LSTM MODEL
# =====================================================================
input_shape = (X_train.shape[1], X_train.shape[2]) # (80, 3)

def build_cnn_lstm_model(input_shape=input_shape, num_classes=num_classes):
    model = keras.Sequential([
        # 1. Convolutional Head for Spatial Feature Extraction
        layers.Conv1D(filters=64, kernel_size=5, activation='relu', 
                      kernel_regularizer=regularizers.l2(1e-4), input_shape=input_shape),
        layers.BatchNormalization(),
        layers.MaxPooling1D(pool_size=2),
        layers.SpatialDropout1D(0.3),

        layers.Conv1D(filters=128, kernel_size=3, activation='relu', 
                      kernel_regularizer=regularizers.l2(1e-4)),
        layers.BatchNormalization(),
        layers.MaxPooling1D(pool_size=2),
        layers.SpatialDropout1D(0.3),

        # 2. Sequential Processing Head (Bidirectional LSTM)
        layers.Bidirectional(layers.LSTM(64, return_sequences=True, recurrent_dropout=0.15)),
        layers.Dropout(0.4),
        layers.Bidirectional(layers.LSTM(32, recurrent_dropout=0.15)),
        layers.Dropout(0.4),

        # 3. Dense Classification Head
        layers.Dense(64, activation='relu', kernel_regularizer=regularizers.l2(1e-4)),
        layers.BatchNormalization(),
        layers.Dropout(0.3),
        layers.Dense(num_classes, activation='softmax')
    ])
    
    # We use Adam optimizer with learning rate decay
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=1e-3),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )
    return model

model = build_cnn_lstm_model()
model.summary()

# =====================================================================
# STEP 6: TRAIN MODEL WITH ADVANCED CALLBACKS
# =====================================================================
# Implement class weights to balance the loss update
class_weights = class_weight.compute_class_weight(
    'balanced',
    classes=np.unique(y_train),
    y=y_train
)
class_weight_dict = dict(enumerate(class_weights))

# Advanced training callbacks
es = keras.callbacks.EarlyStopping(
    monitor='val_loss', 
    patience=8, 
    restore_best_weights=True, 
    verbose=1
)

rlr = keras.callbacks.ReduceLROnPlateau(
    monitor='val_loss', 
    factor=0.5, 
    patience=3, 
    min_lr=1e-6, 
    verbose=1
)

# Save the best model weights dynamically
checkpoint = keras.callbacks.ModelCheckpoint(
    filepath='activity_model.keras',
    monitor='val_accuracy',
    save_best_only=True,
    verbose=1
)

print("\n[INFO] Starting model training...")
history = model.fit(
    X_train, y_train,
    validation_data=(X_val, y_val),
    epochs=50,
    batch_size=64,
    class_weight=class_weight_dict,
    callbacks=[es, rlr, checkpoint],
    verbose=1
)
print("[OK] Training completed!")

# =====================================================================
# STEP 7: MODEL EVALUATION ON UNSEEN GROUPS
# =====================================================================
# Load best model
best_model = keras.models.load_model('activity_model.keras')

test_loss, test_acc = best_model.evaluate(X_test, y_test, verbose=0)
print(f"\n{'='*60}")
print(f"GROUPED TEST ACCURACY (Unseen Users): {test_acc*100:.2f}%")
print(f"Grouped Test Loss: {test_loss:.4f}")
print(f"{'='*60}")

y_pred = np.argmax(best_model.predict(X_test, verbose=0), axis=1)

print("\n[INFO] Classification Report:")
print(classification_report(y_test, y_pred, target_names=label_encoder.classes_, digits=4))

# Confusion Matrix Visualizations
cm = confusion_matrix(y_test, y_pred)
fig, axes = plt.subplots(1, 2, figsize=(16, 6))

sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
            xticklabels=label_encoder.classes_,
            yticklabels=label_encoder.classes_, ax=axes[0])
axes[0].set_title('Confusion Matrix (Raw Count)', fontweight='bold')
axes[0].set_xlabel('Predicted')
axes[0].set_ylabel('True')

# Normalized matrix
cm_norm = cm.astype('float') / cm.sum(axis=1)[:, np.newaxis] * 100
sns.heatmap(cm_norm, annot=True, fmt='.1f', cmap='Greens',
            xticklabels=label_encoder.classes_,
            yticklabels=label_encoder.classes_, ax=axes[1])
axes[1].set_title('Confusion Matrix (Normalized %)', fontweight='bold')
axes[1].set_xlabel('Predicted')
axes[1].set_ylabel('True')

plt.tight_layout()
plt.savefig('activity_confusion_matrix.png', dpi=300)
plt.show()

# Learning Curves
plt.figure(figsize=(12, 4))
plt.subplot(1, 2, 1)
plt.plot(history.history['accuracy'], label='Train Accuracy', lw=2)
plt.plot(history.history['val_accuracy'], label='Val Accuracy', lw=2)
plt.title('Training and Validation Accuracy')
plt.xlabel('Epoch')
plt.ylabel('Accuracy')
plt.legend()
plt.grid(alpha=0.3)

plt.subplot(1, 2, 2)
plt.plot(history.history['loss'], label='Train Loss', lw=2)
plt.plot(history.history['val_loss'], label='Val Loss', lw=2)
plt.title('Training and Validation Loss')
plt.xlabel('Epoch')
plt.ylabel('Loss')
plt.legend()
plt.grid(alpha=0.3)

plt.tight_layout()
plt.savefig('activity_learning_curves.png', dpi=300)
plt.show()

print("[OK] Model successfully saved to: activity_model.keras")
