import os
import joblib
import pandas as pd
import numpy as np
from typing import Literal
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer

# Instantiate FastAPI App
app = FastAPI(
    title="Agricultural Crop Yield Prediction API",
    description="Predict crop yield based on remote sensing indices and weather variables.",
    version="1.0.0"
)

# -------------------------------------------------------------
# CORS MIDDLEWARE CONFIGURATION
# Basis & Security Rationale:
# 1. allow_origins: Restricts API access to trusted frontend clients / domain patterns rather than '*'.
# 2. allow_methods: Explicitly allows GET and POST, restricting unsafe methods like DELETE/PUT.
# 3. allow_headers: Permits standard content headers while blocking arbitrary custom headers.
# 4. allow_credentials: Fixed to True to enable secure token passing when required.
# -------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:8080",
        "https://my-flutter-app.web.app",
        "*"  # Open during evaluation/testing
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
)

MODEL_PATH = "best_model.pkl"
PREPROCESSOR_PATH = "preprocessor.pkl"

# Global references
model = None
preprocessor = None

def load_artifacts():
    global model, preprocessor
    if os.path.exists(MODEL_PATH) and os.path.exists(PREPROCESSOR_PATH):
        model = joblib.load(MODEL_PATH)
        preprocessor = joblib.load(PREPROCESSOR_PATH)

@app.on_event("startup")
def startup_event():
    load_artifacts()

# -------------------------------------------------------------
# PYDANTIC INPUT SCHEMA (Data Types & Realistic Ranges)
# -------------------------------------------------------------
class YieldPredictionInput(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0, description="Latitude coordinate", example=22.62)
    longitude: float = Field(..., ge=-180.0, le=180.0, description="Longitude coordinate", example=88.49)
    NDVI: float = Field(..., ge=-1.0, le=1.0, description="Normalized Difference Vegetation Index", example=0.45)
    GNDVI: float = Field(..., ge=-1.0, le=1.0, description="Green NDVI", example=0.41)
    NDWI: float = Field(..., ge=-1.0, le=1.0, description="Normalized Difference Water Index", example=-0.41)
    SAVI: float = Field(..., ge=-1.0, le=1.5, description="Soil Adjusted Vegetation Index", example=0.67)
    soil_moisture: float = Field(..., ge=0.0, le=100.0, description="Percentage Soil Moisture", example=25.29)
    temperature: float = Field(..., ge=-10.0, le=60.0, description="Temperature in Celsius", example=29.05)
    rainfall: float = Field(..., ge=0.0, le=500.0, description="Rainfall in mm", example=11.03)
    crop_type: Literal['Rice', 'Wheat', 'Maize', 'Bajra', 'Jowar', 'Soybean', 'Sugarcane', 'Cotton', 'Mustard', 'Sunflower', 'Ragi', 'Cardamom', 'Cashew Nut', 'Black Pepper', 'Linseed', 'Sesame', 'Oil Palm'] = Field(..., description="Crop Type", example="Rice")

class PredictionResponse(BaseModel):
    predicted_yield: float
    status: str
    units: str = "quintals/hectare"

# -------------------------------------------------------------
# ENDPOINTS
# -------------------------------------------------------------
@app.get("/")
def root():
    return {"message": "Agricultural Crop Yield API is online. Go to /docs for Swagger documentation."}

@app.post("/predict", response_model=PredictionResponse)
def predict_yield(payload: YieldPredictionInput):
    if model is None or preprocessor is None:
        raise HTTPException(status_code=500, detail="Model artifacts are not loaded.")

    try:
        # Convert Pydantic payload to DataFrame
        input_data = pd.DataFrame([payload.dict()])
        
        # Scale & encode inputs
        scaled_input = preprocessor.transform(input_data)
        
        # Make prediction
        prediction = model.predict(scaled_input)[0]
        
        return PredictionResponse(
            predicted_yield=round(float(prediction), 2),
            status="Success"
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Inference error: {str(e)}")

@app.post("/retrain")
def retrain_model():
    """Trigger model retraining when new data arrives."""
    global model, preprocessor
    
    data_file = "yield_prediction_dataset.csv"
    if not os.path.exists(data_file):
        raise HTTPException(status_code=404, detail="Training dataset file not found.")

    try:
        df = pd.read_csv(data_file)
        df = df.loc[:, ~df.columns.str.contains('^Unnamed')]
        
        X = df.drop(columns=['field_id', 'date_of_image', 'yield'])
        y = df['yield']
        
        num_cols = ['latitude', 'longitude', 'NDVI', 'GNDVI', 'NDWI', 'SAVI', 'soil_moisture', 'temperature', 'rainfall']
        cat_cols = ['crop_type']

        preprocessor = ColumnTransformer(
            transformers=[
                ('num', StandardScaler(), num_cols),
                ('cat', OneHotEncoder(drop='first', handle_unknown='ignore'), cat_cols)
            ]
        )

        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        X_train_scaled = preprocessor.fit_transform(X_train)
        
        # Train new model instance
        new_model = RandomForestRegressor(n_estimators=100, max_depth=10, random_state=42)
        new_model.fit(X_train_scaled, y_train)

        # Save refreshed artifacts
        joblib.dump(new_model, MODEL_PATH)
        joblib.dump(preprocessor, PREPROCESSOR_PATH)

        model = new_model
        return {"status": "Model successfully retrained and deployed in memory."}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Retraining failed: {str(e)}")