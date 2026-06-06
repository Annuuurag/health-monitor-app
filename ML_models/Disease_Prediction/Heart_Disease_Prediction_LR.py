import pandas as pd
import numpy as np
import pickle

from sklearn.linear_model import LogisticRegression
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
pickle.dump(scaler, open('heart_scaler.pkl', 'wb'))


# Step 10: Train Logistic Regression model
model = LogisticRegression(max_iter=1000)
model.fit(X_train_scaled, y_train)


# Step 11: Predictions
y_pred = model.predict(X_test_scaled)


# Step 12: Evaluation
accuracy = accuracy_score(y_test, y_pred)
print("Accuracy:", accuracy)

print("\nClassification Report:")
print(classification_report(y_test, y_pred))

print("\nConfusion Matrix:")
print(confusion_matrix(y_test, y_pred))

# Coefficients of Logistic Regression
coefficients = pd.Series(
    model.coef_[0],
    index=X.columns
).sort_values(ascending=False)

print("\nLogistic Regression Coefficients:")
print(coefficients)

# Odds ratios
odds_ratios = pd.Series(
    np.exp(model.coef_[0]),
    index=X.columns
)

print("\nTop Risk Factors:")
print(odds_ratios.sort_values(ascending=False).head(5))

#==============================================================
# Visualizations
#==============================================================

##Confusion Matrix Visualization
import matplotlib.pyplot as plt
import seaborn as sns

cm = confusion_matrix(y_test, y_pred)

plt.figure(figsize=(5,4))
sns.heatmap(cm, annot=True, fmt="d", cmap="Blues")
plt.xlabel("Predicted")
plt.ylabel("Actual")
plt.title("Confusion Matrix")
plt.show()

##Roc Curve Visualization
from sklearn.metrics import roc_curve, auc

y_prob = model.predict_proba(X_test_scaled)[:, 1]

fpr, tpr, _ = roc_curve(y_test, y_prob)
roc_auc = auc(fpr, tpr)

plt.figure()
plt.plot(fpr, tpr, label=f"AUC = {roc_auc:.2f}")
plt.plot([0, 1], [0, 1], linestyle="--")

plt.xlabel("False Positive Rate")
plt.ylabel("True Positive Rate")
plt.title("ROC Curve")
plt.legend(loc="lower right")
plt.tight_layout()
plt.show()

##Feature Importance Visualization
coefficients.sort_values().plot(
    kind="barh",
    figsize=(8, 6)
)

plt.title("Feature Importance (Logistic Regression Coefficients)")
plt.xlabel("Coefficient Value")
plt.ylabel("Feature")
plt.tight_layout()
plt.show()

##Odds Ratios Visualization
odds_ratios.sort_values(ascending=False).head(5).plot(
    kind="bar",
    figsize=(6, 4)
)

plt.title("Top 5 Risk Factors for Heart Disease")
plt.ylabel("Odds Ratio")
plt.xlabel("Feature")
plt.tight_layout()
plt.show()

with open("prediction_model.pkl", "wb") as f:
    pickle.dump(model, f)