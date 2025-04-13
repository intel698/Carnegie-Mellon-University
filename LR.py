#%%
import warnings
warnings.filterwarnings('ignore')
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.stats import shapiro, boxcox
from scipy.special import inv_boxcox, exp10

import plotly.express as px

from statsmodels.formula.api import ols
from statsmodels.api import OLS
import statsmodels.stats.api as sms
import statsmodels.api as sm
import statsmodels.formula.api as smf
from statsmodels.regression.linear_model import RegressionResultsWrapper
from statsmodels.stats.outliers_influence import variance_inflation_factor

import numpy as np
import pandas as pd
import math

from patsy import dmatrices
from sklearn.preprocessing import PolynomialFeatures, StandardScaler, PowerTransformer
from sklearn.compose import make_column_transformer, ColumnTransformer, TransformedTargetRegressor
from sklearn.preprocessing import OneHotEncoder
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.datasets import fetch_openml

from sklearn.linear_model import RidgeCV
from sklearn.pipeline import make_pipeline
from sklearn.model_selection import cross_validate, RepeatedKFold, cross_validate

# Set pandas options for float formatting
pd.options.display.float_format = '{:.2f}'.format  # Show 2 decimals by default
pd.set_option('display.float_format', '{:.2f}'.format)  # Alternative approach

class cyclical_transformer(BaseEstimator, TransformerMixin):      # Transform cyclical features into sin and cos
    def __init__(self, mdict):
        self.mdict = mdict
        self.get_features = []

    def fit(self, X, y=None): return self 
    def transform(self, X):
        if not isinstance(X, pd.DataFrame): X = pd.DataFrame(X)
        
        for i in self.mdict.keys():
            if i in X.columns:
                X[i + '_sin'] = np.sin(2 * np.pi * X[i] / self.mdict[i])
                X[i + '_cos'] = np.cos(2 * np.pi * X[i] / self.mdict[i])
            else:
                print(f'Column {i} not found in dataframe')

        self.get_features = [i + '_sin' for i in self.mdict.keys()] + [i + '_cos' for i in self.mdict.keys()] 
        X.drop(columns=list(self.mdict.keys()), inplace=True)
        return X 

    def get_feature_names_out(self): return self.get_features
   
class lag_transformer(BaseEstimator, TransformerMixin):           # Create lags for a given column list
    def __init__(self, mdict):
        self.mdict = mdict
        self.get_features = []

    def fit(self, X, y=None): return self
    def transform(self, X):
        lag_list_holder = []                                        
        #{'count': 12}
        for lag_i, lag_j in self.mdict.items():
            if isinstance(lag_j, list):                     # Lags for a given list
                for i in lag_j: 
                    X[f'lagged{i}'] = X[lag_i].shift(i)
                    lag_list_holder.append(f'lagged{i}')
            else:                                           # Lags for a given range
                for i in range(1, lag_j + 1):
                    X[f'lagged{i}'] = X[lag_i].shift(i)
                    lag_list_holder.append(f'lagged{i}')
        X.drop(columns=list(self.mdict.keys()), inplace=True)
        self.get_features = lag_list_holder
        return X 

    def get_feature_names_out(self): return self.get_features   
          
class trans_df():           # Preprocess data for linear regression
  def __init__(self, data, num_col=[], cat_col=[], std_col = [], cyclical_encode={}, lag_dict= {}, target=None):
    self.cat_col = cat_col
    self.num_col = num_col
    self.std_col = std_col
    self.target = target
    self.raw_data = data
    self.lag_dict = list(lag_dict.keys())
    self.cyclical_encode = list(cyclical_encode.keys())
    
    transformers=[
      ('cyclical', cyclical_transformer(cyclical_encode), self.cyclical_encode),            # Cyclical transformation for month
      ('std', StandardScaler(), std_col),                                                   # Standard scaling for numeric features
      ('cat', OneHotEncoder(drop='first', handle_unknown='ignore'), cat_col),           # One-hot encoding for categorical features
      ('lags', lag_transformer(lag_dict), self.lag_dict),
      ('passthrough', 'passthrough', num_col),
      ('targets', 'passthrough', [target])
      ]
    
    remainder='drop'                                                                     # Pass through any remaining columns
    verbose_feature_names_out=False
    
    tran = ColumnTransformer(transformers=transformers
                             , remainder=remainder
                             , verbose_feature_names_out=verbose_feature_names_out
                             , sparse_threshold=0.0)
 
    self.d =   pd.DataFrame(tran.fit_transform(self.raw_data)
                         , columns = tran.get_feature_names_out()
                         , index = self.raw_data.index).dropna() 
      

  def plot_pairplot(self, labels=None):
    if labels is None: labels = self.num_col
    sns.pairplot(self.raw_data[labels + [self.target]], corner=True, kind = 'reg')
    plt.show()
  
  def plot_cat(self, labels=None): 
    if labels is None: labels = self.cat_col
    target = self.target
    data_in = self.raw_data
    n_labels = len(labels)
    n_cols = 3  # Set a maximum of 3 items per row
    n_rows = math.ceil(n_labels / n_cols)

    fig, axs = plt.subplots(n_rows, n_cols, figsize=(12, 6 * n_rows), sharey=False)
    axs = axs.flatten()  # Convert to 1D array

    for i, (ax, label) in enumerate(zip(axs, labels)):
        
        aa = data_in.groupby(label).agg({target:'mean'})

        sns.barplot(aa, x=label, y=target, ax=axs[i])
        
        axs[i].set_title(f"{target} by {label}")
        axs[i].set_xlabel(label)
        axs[i].set_ylabel(target)
        axs[i].tick_params(axis='x', rotation=45)
        ab = aa.std().iloc[0]
        axs[i].set_ylim(aa.min().iloc[0] - ab, aa.max().iloc[0] + ab)

    for j in range(i + 1, len(axs)): fig.delaxes(axs[j])

    plt.tight_layout()
    plt.show()
  
def inspect(df_inspect):
  print(f"Shape: {df_inspect.shape}")
  analysis_results = []

  for column in df_inspect.columns:
    is_unique = df_inspect[column].is_unique
    num_unique_values = df_inspect[column].nunique()
    has_nan_values = df_inspect[column].isna().any()
    missing_df = df_inspect[column].isnull().sum()
    missing_df_per = round((df_inspect.shape[0] - missing_df) / df_inspect.shape[0] * 100,1)

    analysis_results.append({
        'Column': column,
        'Is Unique': is_unique,
        'Num Unique Values': num_unique_values,
        'Has NaN Values': has_nan_values,
        'Missing Values': missing_df,
        'Missing Values (%)': missing_df_per,
        'Col type': df_inspect[column].dtypes
        })
  return pd.DataFrame(analysis_results)

class stats(RegressionResultsWrapper):
  def __init__(self, reg_results):
    super().__init__(reg_results)
    self.reg_results = reg_results
    self.XX = reg_results.model.exog
    self.yy = reg_results.model.endog
    self.feature_names = reg_results.model.exog_names
    self.target_name = reg_results.model.endog_names
    self.resid = reg_results.resid
    self.inluence_df = None
    self.data = (pd.DataFrame(self.XX, columns = self.feature_names)
           .join(pd.DataFrame(self.yy, columns = [self.target_name])))
    
  def __call__(self): return self.report()
  
  def format_thousands(self, val): return '{:,.2f}'.format(val)
  def highlight_pval(self, val): return 'background-color: lightblue; color: black;' if val < 0.05 else ''
  
  def test_normality(self):
    statistic, p_value = shapiro(self.resid)
    if p_value > 0.05:
        print(f"Residuals are normally distributed. Shapiro {statistic:.2f} p-value {p_value:.2f}. Mean of {self.resid.mean():.2f}")
    else:
        print(f"Residuals are not normally distributed. Shapiro {statistic:.2f} p-value {p_value:.2f}. Mean of {self.resid.mean():.2f}")

  def test_autocorrelation(self):
    dw_statistic = sms.durbin_watson(self.resid)
    if 1.5 < dw_statistic < 2.5:
        print(f"Residuals are not autocorrelated. DW Statistic {dw_statistic:.3f}")
    else:
        print(f"Residuals are autocorrelated. DW Statistic {dw_statistic:.3f}")

  def test_homoscedasticity(self):
    _, p_value, _, _ = sms.het_breuschpagan(self.resid, self.XX)
    if p_value > 0.05:
        print(f"Residuals are homoscedastic. p-value = {p_value:.3f}")
    else:
        print(f"Residuals are not homoscedastic.  p-value = {p_value:.3f}")

  def test_residuals(self):
    self.test_normality()
    self.test_autocorrelation()
    self.test_homoscedasticity()

  def print_summary(self, result_wrapper = None):
    
    result_wrapper = self.reg_results
    exog = result_wrapper.model.exog
    feature_names = result_wrapper.model.exog_names
    table_data = result_wrapper.summary().tables[1].data
    summary_coef = pd.DataFrame(table_data[1:], columns=table_data[0])
    summary_coef.set_index('', inplace=True)
    summary_coef = summary_coef.astype(float).round(2)

    vif = pd.DataFrame(index = feature_names)
    vif["VIF"] = [variance_inflation_factor(exog, i) for i in range(exog.shape[1])]
    summary_coef = pd.merge(summary_coef, vif, left_index=True, right_index=True, how='outer')

    summary_coef['sort'] = (summary_coef.index != 'Intercept')  
    summary_coef = summary_coef.sort_values(by='sort').drop(columns=['sort'])
    return summary_coef
  
  def test_interactions(self):
    if self.reg_results.model.k_constant:
        df_interactions = self.XX[:, 1:]
        features_interactions = self.feature_names[1:]
        
    poly_transformer = PolynomialFeatures(degree=2, include_bias=False, interaction_only=True)
    expanded_x = poly_transformer.fit_transform(df_interactions)
    X_poly_df = pd.DataFrame(expanded_x, 
                             columns = poly_transformer.get_feature_names_out(
                             features_interactions))
    
    X_poly_df.rename(columns={'1': 'Intercept'}, inplace=True)
    
    results = sm.OLS(self.yy, sm.add_constant(X_poly_df)).fit()

    return self.print_summary(results)
  
  def get_influence(self): 
    influence = self.reg_results.get_influence()
    self.cooks_d = influence.cooks_distance[0]
    self.leverage = influence.hat_matrix_diag
    self.std_resid = influence.resid_studentized_internal    
    self.dfbetas = influence.dfbetas             
    
    self.inluence_df = pd.DataFrame({
        'cooks_d': self.cooks_d,
        'hat_diag': self.leverage,
        'student_resid': self.std_resid
    }) ##.sort_values(by='cooks_d', ascending=False).round(2)
  
  def plot_influence(self):
    fig = px.scatter(self.influence_df, x='Leverage', y='Studentized Residuals',
                    color='Cook\'s Distance', hover_data= ['CALENDAR_DATE', 'PRICE'],
                    labels={'Leverage': 'Leverage', 'Standardized Residuals': 'Standardized Residuals'},
                    title="Influence Plot (Leverage vs Standardized Residuals)",
                    color_continuous_scale='Viridis')

    # Add labels for Cook's Distance
    fig.update_traces(marker=dict(size=12),
                      selector=dict(mode='markers'))
    fig.show()
    plt.show()
  
  def bootstrap_coeff(self, scale=False):
    n_iterations = 100
    n_samples = int(self.XX.shape[0] * .98)
    n_features = self.XX.shape[1] 

    coefficients = np.zeros((n_features, 100))
    
    for i in range(n_iterations):
      # Resample the data
      indices = list(np.random.choice(n_samples, n_samples, replace=True))
      model = sm.OLS(self.yy[indices], self.XX[indices,:]).fit()

      coefficients[:, i] = model.params

    
    std_dev = self.XX.std(axis=0)
    std_coefficients = coefficients.T * std_dev 
    df_out_std = pd.DataFrame(std_coefficients, columns = self.feature_names)
    df_out = pd.DataFrame(coefficients.T, columns = self.feature_names)
      
    return df_out_std.iloc[:,1:] if scale else df_out.iloc[:,1:]

  def plot_bootstrap_coefficients(self, scale=False):     
    df_out = self.bootstrap_coeff(scale)
    
    sns.stripplot(data=df_out, orient="h", palette="dark:k", alpha=0.5)
    sns.boxplot(data=df_out, orient="h", color="cyan", saturation=0.5, whis=10)
    plt.axvline(x=0, color=".5") 
    plt.show()
     
  def residual_plots(self, ax=None):
    if ax is None: fig, ax = plt.subplots()  
    sns.residplot(
        x=self.reg_results.fittedvalues,    
        y=self.reg_results.resid,
        lowess=True,
        scatter_kws={"alpha": 0.5},
        line_kws={"color": "red", "lw": 1, "alpha": 0.8},
        ax=ax
    )
    ax.set_xlabel("Estimates")
    ax.set_ylabel("Residuals")
    return ax 

  def fitted_plot(self, ax=None):

    sns.scatterplot(x=self.reg_results.fittedvalues, y=self.yy, ax=ax)
    sns.lineplot(x=self.reg_results.fittedvalues, 
                    y=self.reg_results.fittedvalues, 
                    color="red", 
                    label="Perfect fit",
                    ax=ax)
    ax.set_aspect('equal') 
    ax.set_title("Residuals vs Fitted")
    ax.set_xlabel("Fitted values")
    ax.set_ylabel("Actuals")
    return ax
  
  def plot_fitted(self):
    fig, ax = plt.subplots(figsize=(8, 8)) 
    self.fitted_plot(ax=ax) 
    plt.show()  
  
  def plot_residuals(self):
    fig, ax = plt.subplots() 
    self.residual_plots(ax=ax) 
    plt.show()
  
   
  def plot_diagnostics(self):
    fig, axes = plt.subplots(nrows=2, ncols=2, figsize=(10, 10))
    self.residual_plots(ax=axes[0, 0])  # Top-left subplot
    sm.qqplot(self.reg_results.resid, line="s", ax=axes[0,1])
    sns.histplot(self.reg_results.resid, kde=True, ax=axes[1,0])
        
    fig.tight_layout()
    plt.show()
         
  def plot_residuals_all(self, data_in=None, labels=None):
    if self.inluence_df is None: self.get_influence()
    if data_in is None: data_in = self.data

    n_labels = len(labels)
    n_cols = 3  # Set a maximum of 3 items per row
    n_rows = math.ceil(n_labels / n_cols)

    fig, axs = plt.subplots(n_rows, n_cols, figsize=(12, 6 * n_rows), sharey=False)
    axs = axs.flatten()  # Convert to 1D array

    for i, predictor in enumerate(labels):

        sns.scatterplot(x = data_in[predictor].values, y= self.inluence_df['student_resid'], alpha=0.5, ax=axs[i])
        axs[i].axhline(0, color='red', linestyle='--')
        axs[i].set_xlabel(predictor)
        axs[i].set_ylabel("Residuals")
        axs[i].set_title(f"Residuals vs {predictor}")

    for j in range(i + 1, len(axs)): fig.delaxes(axs[j])

    plt.tight_layout()
    plt.show()
  

 
#%%


import statsmodels.api as sm

# Load dataset
data = sm.datasets.longley.load_pandas().data

# Define response and predictors
y = data['TOTEMP']
X = data.drop(columns='TOTEMP')

# Add constant
X = sm.add_constant(X)

# Fit OLS model
model = sm.OLS(y, X).fit()

# View results
print(model.summary())

##  Demo  ###########################################

wrap = stats(model)

wrap.print_summary()
wrap.test_autocorrelation()
wrap.test_normality()
wrap.test_homoscedasticity()

wrap.test_residuals()

# Constructed features  

# df_raw = pd.read_csv(r'C:\data\boston_all.csv', parse_dates=['SOLD DATE'])
# df_raw = pd.read_excel(r'C:\data\Boston_all.xlsx',  sheet_name='Boston')


# relevant_columns = [ 'PRICE'
#                     , 'BEDS'
#                     , 'BATHS'
#                     , 'SQUARE FEET'
#                     , 'YEAR BUILT'
#                     , 'ZIP'
#                     , 'SOLD DATE']       

# df_raw = df_raw[relevant_columns]
# df_raw['parsed_dates'] = pd.to_datetime(df_raw['SOLD DATE']
#                                           , errors='coerce'
#                                           , infer_datetime_format=True)

# df_raw.dropna(inplace=True)
# df_raw['is_winter'] = df_raw['parsed_dates'].apply(lambda x: 1 if x.month in [12, 1, 2] else 0)
# #df_raw['month'] = df_raw['Sold date'].dt.month


# filter = (
#     (df_raw['PRICE'] > 50000) & 
#     (df_raw['PRICE'] < 2000000) &
#     (df_raw['BEDS'] < 8 ) &
#     (df_raw['BATHS'] > 0) 
#     )


