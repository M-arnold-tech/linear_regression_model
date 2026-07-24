# Precision Agriculture Crop Yield Prediction Model

## Mission & Problem Description
To enhance agricultural planning and food security, this project builds an automated machine learning system predicting crop yields using multi-spectral satellite indices (NDVI, SAVI, GNDVI, NDWI) and climate observations (soil moisture, temperature, rainfall). The system provides accessible yield estimations via a cloud-hosted REST API and Flutter mobile client.

## Data Source & Description
* **Source:** Satellite spectral index observations and weather station recordings across agricultural field plots.
* **Volume & Variety:** Includes 13 features capturing spatial coordinates, 4 vegetation/water spectral indices, environmental indicators, and categorical crop types across multiple harvest cycles.

## Visualizations
The analysis notebook (`summative/linear_regression/multivariate.ipynb`) generates:
1. **Correlation Heatmap:** Highlights strong linear reliance between SAVI/NDVI indices and final yield outputs.
2. **Variable Distributions:** Histogram and scatter distributions illustrating yield separation by crop species and rainfall dependency.

## Public API & Documentation
* **Swagger UI Documentation:** `https://your-render-app-name.onrender.com/docs`
* **Prediction Endpoint:** `POST https://your-render-app-name.onrender.com/predict`
* **Retraining Endpoint:** `POST https://your-render-app-name.onrender.com/retrain`

## Demonstration Video
* **YouTube Video Link:** `https://www.youtube.com/watch?v=YOUR_VIDEO_ID`

## Mobile App Execution Instructions
1. Ensure Flutter SDK is installed (`flutter doctor`).
2. Navigate to the app directory:
   ```bash
   cd summative/FlutterApp