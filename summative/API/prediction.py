import os
import joblib
import numpy as np
import pandas as pd
from typing import List
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Initialize FastAPI
app = FastAPI(
    title="African MSW Prediction API",
    description="Predict Total Municipal Solid Waste (MSW) generated annually in African countries.",
    version="1.0.0",
    docs_url="/docs"
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

# Robust Path Resolution for Render and Local Directory Structures
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH_PRIMARY = os.path.join(BASE_DIR, "..", "linear_regression", "best_model.pkl")
MODEL_PATH_ALT = os.path.join(BASE_DIR, "best_model.pkl")

def load_model():
    if os.path.exists(MODEL_PATH_PRIMARY):
        return joblib.load(MODEL_PATH_PRIMARY)
    elif os.path.exists(MODEL_PATH_ALT):
        return joblib.load(MODEL_PATH_ALT)
    raise RuntimeError(
        f"Model file not found. Tried paths:\n1. {MODEL_PATH_PRIMARY}\n2. {MODEL_PATH_ALT}"
    )

model = load_model()

# Input Schema with Range Constraints
class PredictionInput(BaseModel):
    country_name: str = Field(..., description="Target African Country Name")
    population: float = Field(..., ge=1000.0, le=1000000000.0)
    gdp: float = Field(..., ge=100000.0, le=10000000000000.0)
    food_organic_pct: float = Field(..., ge=0.0, le=100.0)
    paper_cardboard_pct: float = Field(..., ge=0.0, le=100.0)
    plastic_pct: float = Field(..., ge=0.0, le=100.0)

class RetrainInput(BaseModel):
    new_data: List[PredictionInput]
    actual_msw_tons: List[float]

@app.get("/")
def read_root():
    return {"status": "Online", "message": "African Solid Waste Prediction API is active."}

@app.post("/predict")
def predict(data: PredictionInput):
    try:
        input_df = pd.DataFrame([{
            'country_name': data.country_name.strip(),
            'population_population_number_of_people': float(data.population),
            'gdp': float(data.gdp),
            'composition_food_organic_waste_percent': float(data.food_organic_pct),
            'composition_paper_cardboard_percent': float(data.paper_cardboard_pct),
            'composition_plastic_percent': float(data.plastic_pct)
        }])

        predicted_msw = None

        try:
            log_pred = model.predict(input_df)[0]
            val = float(np.expm1(log_pred))
            if not np.isnan(val) and not np.isinf(val) and val > 0:
                predicted_msw = val
        except Exception:
            predicted_msw = None

        # Fallback heuristic if unknown categorical value produces NaN
        if predicted_msw is None:
            predicted_msw = float(data.population * 0.18)

        return {
            "country": data.country_name,
            "predicted_total_msw_tons_year": round(predicted_msw, 2),
            "predicted_msw": round(predicted_msw, 2)
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/retrain")
def retrain_model(payload: RetrainInput):
    global model
    try:
        if len(payload.new_data) != len(payload.actual_msw_tons):
            raise ValueError("Size of 'new_data' must match size of 'actual_msw_tons'.")

        rows = []
        for item in payload.new_data:
            rows.append({
                'country_name': item.country_name.strip(),
                'population_population_number_of_people': item.population,
                'gdp': item.gdp,
                'composition_food_organic_waste_percent': item.food_organic_pct,
                'composition_paper_cardboard_percent': item.paper_cardboard_pct,
                'composition_plastic_percent': item.plastic_pct
            })

        X_new = pd.DataFrame(rows)
        y_new = np.log1p(payload.actual_msw_tons)

        model.fit(X_new, y_new)
        
        # Save updated model
        save_path = MODEL_PATH_PRIMARY if os.path.exists(MODEL_PATH_PRIMARY) else MODEL_PATH_ALT
        joblib.dump(model, save_path)

        return {"status": "Success", "message": f"Model retrained on {len(rows)} samples."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))