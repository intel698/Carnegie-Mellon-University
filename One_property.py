import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn.metrics.pairwise import haversine_distances
from datetime import datetime
import plotly.express as px
from sklearn.ensemble import RandomForestRegressor
import shap


# Load the Excel file
df = pd.read_excel("c:\\data\\Book1.xlsx")  # Make sure Book1.xlsx is in your working directory
df = df.fillna(0)

# Set SOLD DATE for the target row (index 0) to today
reference_date = pd.Timestamp(datetime.today().date())
reference_year = reference_date.year
df.loc[0, "SOLD DATE"] = reference_date
df["SOLD DATE"] = pd.to_datetime(df["SOLD DATE"], errors='coerce')

df["DAYS SINCE SOLD"] = (reference_date - df["SOLD DATE"]).dt.days
df['YEAR BUILT'] = (reference_year - df['YEAR BUILT']).astype(int)

target = "PRICE" 
features = ["SQUARE FEET", "BEDS", "BATHS", "YEAR BUILT", "LOT SIZE", "DAYS SINCE SOLD", 'PROPERTY TYPE']
df = df[[target] + features + ["LATITUDE", "LONGITUDE", "ADDRESS"]]

df = pd.get_dummies(df, columns=["PROPERTY TYPE"], drop_first=True)

# Separate the target row (property we want to predict for)
target_row = df.iloc[0]

# Create training dataset, drop rows with missing critical values
train_df = df.iloc[1:].dropna()

# Define function to convert degrees to radians for Haversine
def deg2rad(df, lat_col='LATITUDE', lon_col='LONGITUDE'):
    return np.radians(df[[lat_col, lon_col]].to_numpy())

# Compute distances
target_coords_rad = deg2rad(pd.DataFrame([target_row]))
train_coords_rad = deg2rad(train_df)
distances_rad = haversine_distances(train_coords_rad, target_coords_rad)
distances_km = distances_rad * 6371  # Radius of the Earth in km
distances_km[distances_km == 0] = 0.0001  # Avoid division by zero

# Inverse distance weights
weights = 1 / np.maximum(distances_km.flatten(), 0.0001)

# Select features and target
X = train_df.drop(columns=[target] + ["LATITUDE", "LONGITUDE", "ADDRESS"])
y = train_df["PRICE"]
X_target = target_row.to_frame().T.drop(columns=[target] + ["LATITUDE", "LONGITUDE", "ADDRESS"])

plot_df = train_df.copy()
plot_df["Distance to Target (km)"] = distances_km.flatten()
plot_df["Weight (1 / distance²)"] = weights

def plot_distance_effect(train_df, distances_km, weights):
    """
    Plot the effect of distance on weight (inverse distance squared).
    """
    fig = px.scatter(
        train_df,
        x=distances_km.flatten(),
        y='PRICE',
        color=weights,
        hover_data=["ADDRESS", 'PRICE'],
        title="Effect of Distance on Weight (Inverse Distance Squared)"
    )
    
    fig.update_layout(
        xaxis_title="Distance to Target (km)",
        yaxis_title="Weight (1 / distance²)",
        template="plotly_white"
    )
    
    fig.show()



# Weighted Linear Regression
model = LinearRegression()
model.fit(X, y, sample_weight=weights)
lr_predicted_price_weighted = model.predict(X_target)[0]

plot_distance_effect(train_df, distances_km, weights)

# Random Forest Regression
rf_model = RandomForestRegressor(n_estimators=100, random_state=42)
rf_model.fit(X, y, sample_weight=weights)
rf_predicted_price = rf_model.predict(X_target)[0]


weights = 1 / np.maximum(distances_km.flatten(), 0.0001) ** 2
model = LinearRegression()
model.fit(X, y, sample_weight=weights)
lr_predicted_price_inv_weighted = model.predict(X_target)[0]


plot_distance_effect(train_df, distances_km, weights)

# Random Forest Regression
rf_model = RandomForestRegressor(n_estimators=100, random_state=42)
rf_model.fit(X, y, sample_weight=weights)
rf_inv_predicted_price = rf_model.predict(X_target)[0]

print(f"Linear weighted Linear Regression: ${lr_predicted_price_weighted:,.0f}")
print(f"Linear weighted Random Forest: ${rf_predicted_price:,.0f}")
print(f"Exponential Weighted Linear Regression): ${lr_predicted_price_inv_weighted:,.0f}")
print(f"Exponential weighted Random Forest Predicted Price: ${rf_inv_predicted_price:,.0f}")


# SHAP Analysis
explainer = shap.TreeExplainer(rf_model)
shap_values = explainer(X_target)

shap.initjs()
shap.plots.waterfall(shap_values[0])

print(explainer.expected_value)