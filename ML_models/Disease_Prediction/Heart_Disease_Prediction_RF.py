import pandas as pd
import numpy as np

from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix


# Step 1: Column names (from heart-disease.names)
columns = [
    "age", "sex", "cp", "trestbps", "chol",
    "fbs", "restecg", "thalach", "exang",
    "oldpeak", "slope", "ca", "thal", "target"
]


# Step 2: Load the Cleveland dataset
data = pd.read_csv(
    "processed.cleveland.data",
    header=None,
    names=columns
)


# Step 3: Replace '?' with NaN
data.replace("?", np.nan, inplace=True)


# Step 4: Convert columns to numeric
data = data.apply(pd.to_numeric)


# Step 5: Drop rows with missing values
data.dropna(inplace=True)


# Step 6: Convert target to binary
# 0 -> 0 (No disease)
# 1-4 -> 1 (Disease)
data["target"] = data["target"].apply(lambda x: 1 if x > 0 else 0)


# Step 7: Split features and target
X = data.drop("target", axis=1)
y = data["target"]


# Step 8: Train-test split
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)


# Step 9: Feature scaling
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)


# Step 10: Train Random Forest model
rf_model = RandomForestClassifier(
    n_estimators=200,
    max_depth=None,
    random_state=42
)

rf_model.fit(X_train, y_train)



# Step 11: Predictions
y_pred = rf_model.predict(X_test)



# Step 12: Evaluation
accuracy = accuracy_score(y_test, y_pred)
print("Accuracy:", accuracy)

print("\nClassification Report:")
print(classification_report(y_test, y_pred))

print("\nConfusion Matrix:")
print(confusion_matrix(y_test, y_pred))

feature_importance = pd.Series(
    rf_model.feature_importances_,
    index=X.columns
).sort_values(ascending=False)

print("\nFeature Importance:")
print(feature_importance)
