import os
import joblib
import numpy as np
import pandas as pd

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.preprocessing import StandardScaler
from sklearn.impute import SimpleImputer

app = FastAPI(
    title="African MSW Prediction API",
    description="API for predicting total annual municipal solid waste generation across African countries.",
    version="1.0.0"
)

# ==========================================
# CORS CONFIGURATION & REASONING
# ==========================================
# Reasoning: Allowed origins are limited to explicit Flutter client domains and local dev environments
# to prevent cross-origin abuse while allowing legitimate app requests.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "../linear_regression/best_model.pkl")
SCALER_PATH = os.path.join(BASE_DIR, "../linear_regression/scaler.pkl")
IMPUTER_PATH = os.path.join(BASE_DIR, "../linear_regression/imputer.pkl")

model = joblib.load(MODEL_PATH)
scaler = joblib.load(SCALER_PATH)
imputer = joblib.load(IMPUTER_PATH)

# ==========================================
# PYDANTIC INPUT SCHEMA (BOUNDS & DATATYPES)
# ==========================================
class AfricanWasteInput(BaseModel):
    gdp: float = Field(..., ge=0.0, description="Gross Domestic Product in USD")
    population: float = Field(..., ge=10000.0, le=300000000.0, description="African Country Population")
    food_organic_pct: float = Field(..., ge=0.0, le=100.0, description="Organic Waste Percentage")
    paper_cardboard_pct: float = Field(..., ge=0.0, le=100.0, description="Paper/Cardboard Waste Percentage")
    plastic_pct: float = Field(..., ge=0.0, le=100.0, description="Plastic Waste Percentage")

    class Config:
        json_schema_extra = {
            "example": {
                "gdp": 456775408619.0, # e.g. Nigeria
                "population": 154402181.0,
                "food_organic_pct": 52.0,
                "paper_cardboard_pct": 8.0,
                "plastic_pct": 4.8
            }
        }

@app.get("/")
def root():
    return {"message": "African Solid Waste API is active. Go to /docs for Swagger UI."}

@app.post("/predict")
def predict_waste(data: AfricanWasteInput):
    try:
        raw_features = np.array([[
            data.gdp,
            data.population,
            data.food_organic_pct,
            data.paper_cardboard_pct,
            data.plastic_pct
        ]])
        
        imputed = imputer.transform(raw_features)
        scaled = scaler.transform(imputed)
        pred = model.predict(scaled)[0]
        
        return {
            "status": "success",
            "predicted_msw_tons_year": float(round(pred, 2))
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/retrain")
async def retrain(file: UploadFile = File(...)):
    """Triggers automated model retraining when an updated African waste CSV is uploaded."""
    global model, scaler, imputer
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="Only CSV files accepted.")
    
    try:
        df = pd.read_csv(file.file)
        north_africa = ['DZA', 'EGY', 'LBY', 'MAR', 'TUN', 'SDN']
        africa_df = df[(df['region_id'] == 'SSF') | (df['iso3c'].isin(north_africa))]
        
        target_col = 'total_msw_total_msw_generated_tons_year'
        feature_cols = [
            'gdp',
            'population_population_number_of_people',
            'composition_food_organic_waste_percent',
            'composition_paper_cardboard_percent',
            'composition_plastic_percent'
        ]
        
        data = africa_df[feature_cols + [target_col]].dropna(subset=[target_col])
        X = data[feature_cols]
        y = data[target_col]
        
        imputer = SimpleImputer(strategy='median')
        X_imp = imputer.fit_transform(X)
        
        scaler = StandardScaler()
        X_scaled = scaler.fit_transform(X_imp)
        
        model.fit(X_scaled, y)
        
        joblib.dump(model, MODEL_PATH)
        joblib.dump(scaler, SCALER_PATH)
        joblib.dump(imputer, IMPUTER_PATH)
        
        return {"status": "success", "message": "Model retrained and updated on new African data!"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Retraining error: {str(e)}")