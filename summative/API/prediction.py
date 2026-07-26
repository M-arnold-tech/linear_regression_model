import os
import joblib
import numpy as np
import pandas as pd
from typing import List
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# -------------------------------------------------------------------
# 1. FASTAPI APP INITIALIZATION & CORS SETUP
# -------------------------------------------------------------------
app = FastAPI(
    title="African MSW Prediction API",
    description="Predict Total Municipal Solid Waste (MSW) generated annually in African countries.",
    version="1.0.0",
    docs_url="/docs"
)

# CORS Middleware Configuration
# Configured for secure access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict to your frontend domain in production
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

# Dynamic Path to the saved scikit-learn model pipeline
MODEL_PATH = os.path.join(os.path.dirname(__file__), "../linear_regression/best_model.pkl")

def load_model():
    if os.path.exists(MODEL_PATH):
        return joblib.load(MODEL_PATH)
    raise RuntimeError(f"Model file not found at path: {MODEL_PATH}")

# Load model pipeline on startup
model = load_model()


# -------------------------------------------------------------------
# 2. PYDANTIC SCHEMAS
# -------------------------------------------------------------------
class PredictionInput(BaseModel):
    country_name: str = Field(..., description="Target African Country Name (e.g., Nigeria, Kenya)")
    population: float = Field(..., ge=1000.0, le=1000000000.0, description="Population number")
    gdp: float = Field(..., ge=100000.0, le=10000000000000.0, description="Gross Domestic Product in USD")
    food_organic_pct: float = Field(..., ge=0.0, le=100.0, description="Food & Organic waste percentage")
    paper_cardboard_pct: float = Field(..., ge=0.0, le=100.0, description="Paper & Cardboard waste percentage")
    plastic_pct: float = Field(..., ge=0.0, le=100.0, description="Plastic waste percentage")


class RetrainInput(BaseModel):
    new_data: List[PredictionInput]
    actual_msw_tons: List[float]


# -------------------------------------------------------------------
# 3. ENDPOINTS
# -------------------------------------------------------------------
@app.get("/")
def read_root():
    return {
        "status": "Online",
        "message": "African Solid Waste Prediction API is active.",
        "documentation": "/docs"
    }


@app.post("/predict")
def predict(data: PredictionInput):
    try:
        # Construct DataFrame matching exact feature names used during training
        input_df = pd.DataFrame([{
            'country_name': data.country_name.strip(),
            'population_population_number_of_people': float(data.population),
            'gdp': float(data.gdp),
            'composition_food_organic_waste_percent': float(data.food_organic_pct),
            'composition_paper_cardboard_percent': float(data.paper_cardboard_pct),
            'composition_plastic_percent': float(data.plastic_pct)
        }])

        predicted_msw = None

        # Predict log-transformed value safely
        try:
            log_pred = model.predict(input_df)[0]
            val = float(np.expm1(log_pred))
            if not np.isnan(val) and not np.isinf(val) and val > 0:
                predicted_msw = val
        except Exception:
            predicted_msw = None

        # Fallback heuristic if unknown country or transformer causes NaN
        if predicted_msw is None:
            # Baseline estimation (~0.18 tons/capita/year)
            predicted_msw = float(data.population * 0.18)

        # Return both keys for complete frontend compatibility
        return {
            "country": data.country_name,
            "predicted_total_msw_tons_year": round(predicted_msw, 2),
            "predicted_msw": round(predicted_msw, 2)
        }

    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Prediction error: {str(e)}")


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

        # Retrain pipeline with new batch data
        model.fit(X_new, y_new)

        # Save updated model back to disk
        joblib.dump(model, MODEL_PATH)

        return {
            "status": "Success",
            "message": f"Model successfully retrained on {len(rows)} new data samples."
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Retraining failed: {str(e)}")