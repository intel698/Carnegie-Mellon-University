import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline, make_pipeline
from sklearn.compose import make_column_transformer
from sklearn.preprocessing import OneHotEncoder
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import mean_absolute_error, mean_squared_error
from sklearn.base import BaseEstimator, TransformerMixin
from lightgbm import LGBMRegressor
from sklearn.linear_model import LinearRegression 
from sklearn.ensemble import RandomForestRegressor

pd.set_option('display.float_format', '{:,.2f}'.format)

# ========== Custom Transformer to Convert Coordinates to Radians ==========
class Deg2RadTransformer(BaseEstimator, TransformerMixin):
    def __init__(self, lat_col='LATITUDE', lon_col='LONGITUDE'):
        self.lat_col = lat_col
        self.lon_col = lon_col

    def fit(self, X, y=None):
        return self

    def transform(self, X):
        X = X.copy()
        X[[self.lat_col, self.lon_col]] = np.radians(X[[self.lat_col, self.lon_col]])
        return X

# ========== Load and Prepare Data ==========
file_path = "c:\data\Book11.xlsx"  # Replace with your actual file path
boston_df = pd.read_excel(file_path, sheet_name="Boston")

# Select relevant columns
features = ['PRICE', 'BEDS', 'BATHS', 'PROPERTY TYPE', 'CITY',
            'ZIP OR POSTAL CODE', 'LATITUDE', 'LONGITUDE', 'Desctiption']
df = boston_df[features].dropna()

X = df.drop(columns=['PRICE'])
y = df['PRICE']

# Define columns
categorical_features = ['PROPERTY TYPE', 'CITY']
text_feature = 'Desctiption'
numeric_features = ['BEDS', 'BATHS', 'ZIP OR POSTAL CODE', 'LATITUDE', 'LONGITUDE']

# Define column transformer separately
column_transformer = make_column_transformer(
    (OneHotEncoder(), ['PROPERTY TYPE', 'CITY']),
    (TfidfVectorizer(stop_words='english', max_df=0.7, min_df=0.01 ), 'Desctiption'),
    remainder='passthrough'
)

# Build pipeline
model_lr = make_pipeline(
    Deg2RadTransformer(),  # Custom transformer to convert LAT/LON to radians
    column_transformer,    # Column transformer
    LinearRegression()     # Or replace with LGBMRegressor()
)

model_rf = make_pipeline(
    Deg2RadTransformer(),  # Custom transformer to convert LAT/LON to radians
    column_transformer,    # Column transformer
    LGBMRegressor()    # Or replace with LGBMRegressor()
)

# ========== Train/Test Split and Fit ==========
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
model_lr.fit(X_train, y_train)

# ========== Evaluate Model ==========
y_pred = model_lr.predict(X_test)
mae = mean_absolute_error(y_test, y_pred)
rmse = np.sqrt(mean_squared_error(y_test, y_pred))

print(f"\nLR Model Performance:")
print(f"  MAE:  ${mae:,.0f}")
print(f"  RMSE: ${rmse:,.0f}")

model_rf.fit(X_train, y_train)

# ========== Evaluate Model ==========
y_pred = model_rf.predict(X_test)
mae = mean_absolute_error(y_test, y_pred)
rmse = np.sqrt(mean_squared_error(y_test, y_pred))

print(f"\nRF Model Performance:")
print(f"  MAE:  ${mae:,.0f}")
print(f"  RMSE: ${rmse:,.0f}")


# 1. Get fitted components
preprocessor_fitted = model_lr.named_steps['columntransformer']
regressor = model_lr.named_steps['linearregression']

# 2. Get feature names
tfidf = preprocessor_fitted.named_transformers_['tfidfvectorizer']
tfidf_features = tfidf.get_feature_names_out()

ohe = preprocessor_fitted.named_transformers_['onehotencoder']
ohe_features = ohe.get_feature_names_out(categorical_features)

all_features = list(ohe_features) + list(tfidf_features) + numeric_features

# 3. Get coefficients
coefficients = regressor.coef_

# 4. Create a DataFrame of features + effects
coef_df = pd.DataFrame({
    'Feature': all_features,
    'Effect_on_Price': coefficients
}).sort_values(by='Effect_on_Price', ascending=False)

# 5. Filter to show words only (optional)
top_words = coef_df[coef_df['Feature'].isin(tfidf_features)]

print("Top Positive Words:")
print(top_words.sort_values(by='Effect_on_Price', ascending=False).head(10))

print("\nTop Negative Words:")
print(top_words.sort_values(by='Effect_on_Price').head(40))



