# African Municipal Solid Waste (MSW) Generation Prediction & Deployment System

## Mission Statement & Use Case
Our mission is to support regional waste management planners, environmental policymakers, and municipal authorities in African countries by accurately predicting annual Municipal Solid Waste (MSW) generation (in tons/year). Predicting solid waste generation based on socio-economic indicators and waste composition enables proactive urban planning, optimized waste collection logistics, and sustainable infrastructure development across African nations.

## Dataset Description & Source
* **Source:** World Bank What a Waste 2.0 Database (`country_level_data_0.csv`).
* **Description:** The dataset contains country-level records detailing population figures, Gross Domestic Product (GDP in USD), waste collection coverage, and waste composition percentages (food & organic waste, paper & cardboard, plastic). The dataset was filtered specifically for Sub-Saharan Africa (`SSF`) and North African countries (`MEA`) to train localized regression models.

## Public API Documentation
* **Swagger UI Documentation:** `https://linear-regression-model-iurj.onrender.com/docs`

## Demo Video
* **YouTube Video Link:** `https://youtu.be/YOUR_VIDEO_LINK`

## How to Run the Flutter Mobile App
1. Ensure Flutter SDK is installed: `flutter doctor`
2. Navigate to the Flutter app folder: `cd summative/FlutterApp`
3. Fetch dependencies: `flutter pub get`
4. Run on an attached device or emulator: `flutter run`