import pandas as pd
import numpy as np
from sklearn.neighbors import NearestNeighbors
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
from datetime import datetime
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split


df = pd.read_excel("c:\\data\\Book11.xlsx")  # Make sure Book1.xlsx is in your working directory
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


# Features and target
features = ['bedrooms', 'bathrooms', 'sqft', 'latitude', 'longitude']
target = 'PRICE'

# Generate spatial influence feature
coords = df[['LATITUDE', 'LONGITUDE']]
prices = df['PRICE'].values
k = 5  # You can tune this

def tuned_neighbors(k):
    knn = NearestNeighbors(n_neighbors=k+1, algorithm='ball_tree')  # k+1 because the point itself is included
    knn.fit(coords)
    distances, indices = knn.kneighbors(coords)

    # Compute weighted average of neighbor prices (excluding self)
    spatial_price = []
    for i, neighbors in enumerate(indices):
        neighbors = neighbors[1:]  # exclude self
        dists = distances[i][1:]
        weights = 1 / (dists + 1e-5)  # inverse distance weighting
        weighted_price = np.dot(prices[neighbors], weights) / weights.sum()
        spatial_price.append(weighted_price)

    df['spatial_price'] = spatial_price
    features.append('spatial_price')

    X_tran, X_test, y_train, y_test = (
        train_test_split(df.drop(columns=["LATITUDE", "LONGITUDE", "ADDRESS"]+[target])
                        , df[target]
                        , test_size=0.2, random_state=42))

    rf = RandomForestRegressor(n_estimators=100, random_state=42)
    rf.fit(X_tran, y_train)
    y_pred = rf.predict(X_test)

    mae = np.mean(np.abs(y_test - y_pred))
    return mae

for i in range(20):
    k = i + 1
    mae = tuned_neighbors(k)
    print(f"MAE for k={k}: {mae}")
