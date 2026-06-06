import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import pickle

from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import IsolationForest
from sklearn.metrics import classification_report
from sklearn.metrics import classification_report, confusion_matrix

sns.set(style="whitegrid")
np.random.seed(42)

df = pd.read_csv("features53.csv")

##Feature Selection and Cleaning
# Drop non-ML identifiers
drop_cols = ["Patient_ID"]
df_features = df.drop(columns=[c for c in drop_cols if c in df.columns])

# Remove constant / near-constant features
low_variance_cols = df_features.columns[df_features.nunique() <= 2]
df_features = df_features.drop(columns=low_variance_cols)

print("Final feature count:", df_features.shape[1])

##Feature Scaling
scaler = StandardScaler()
X_scaled = scaler.fit_transform(df_features)
pickle.dump(scaler, open('anomaly_scaler.pkl', 'wb'))

print("Features normalized.")

##Train Isolation Forest Model
iso_model = IsolationForest(
    n_estimators=500,
    max_samples=0.8,
    max_features=0.8,
    contamination=0.03,
    random_state=42,
    n_jobs=-1
)

iso_model.fit(X_scaled)
print("Isolation Forest training complete.")

##Predict Anomalies and Scores
df_results = df.copy()

df_results["anomaly_raw"] = iso_model.predict(X_scaled)
df_results["anomaly_flag"] = df_results["anomaly_raw"].map({1: 0, -1: 1})

df_results["anomaly_score"] = iso_model.decision_function(X_scaled)

print(df_results["anomaly_flag"].value_counts())

##Synthetic Anomaly Injection for Evaluation
n_fake = int(0.05 * len(X_scaled))
synthetic_anomalies = X_scaled[:n_fake] * 3

X_eval = np.vstack([X_scaled, synthetic_anomalies])
y_eval = np.hstack([
    np.zeros(len(X_scaled)),
    np.ones(len(synthetic_anomalies))
])

y_pred = iso_model.predict(X_eval)
y_pred = np.where(y_pred == -1, 1, 0)

print(classification_report(y_eval, y_pred))

#===========================================================================
# Visualizations
#===========================================================================

##Confusion Matrix Visualization
plt.figure(figsize=(5,4))
sns.heatmap(confusion_matrix(y_eval, y_pred), annot=True, fmt="d", cmap="Blues")
plt.xlabel("Predicted")
plt.ylabel("Actual")
plt.title("Confusion Matrix")
plt.show()

##Anomaly Score Distribution
plt.figure(figsize=(6,4))
sns.countplot(x="anomaly_flag", data=df_results)
plt.xticks([0,1], ["Normal", "Anomaly"])
plt.title("Anomaly Distribution")
plt.tight_layout()
plt.show()

##Heart Rate vs Anomaly Detection
plt.figure(figsize=(12,5))

normal = df_results[df_results["anomaly_flag"] == 0]
anomaly = df_results[df_results["anomaly_flag"] == 1]

plt.scatter(normal.index, normal["HR"],
            c="blue", alpha=0.4, s=20, label="Normal")

plt.scatter(anomaly.index, anomaly["HR"],
            c="red", alpha=0.9, s=20, label="Anomaly")

plt.title("Heart Rate Anomaly Detection")
plt.xlabel("Sample Index")
plt.ylabel("Heart Rate")
plt.legend()
plt.tight_layout()
plt.show()

with open("anomaly_model.pkl", "wb") as f:
    pickle.dump(iso_model, f)