# Dairy Farm Management System - API Contracts & Specifications

## 1. REST API Conventions

All API endpoints follow RESTful standards and return a consistent JSON response envelope.

### 1.1 Base URL & Versioning
```
Base URL: /api/v1
Authentication: Bearer <JWT_ACCESS_TOKEN>
```

### 1.2 Standard Success Response Envelope
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Resource retrieved successfully",
  "data": {},
  "timestamp": "2026-10-11T06:30:00.000Z"
}
```

### 1.3 Standard Error Response Envelope
```json
{
  "success": false,
  "statusCode": 400,
  "error": "Bad Request",
  "message": [
    "yieldLitres must be greater than 0",
    "session must be one of: MORNING, EVENING"
  ],
  "path": "/api/v1/milking",
  "timestamp": "2026-10-11T06:30:00.000Z"
}
```

---

## 2. Core Endpoint Specifications

### 2.1 Authentication & Authorization
* **`POST /api/v1/auth/login`**
  * *Request Body:* `{ "email": "admin@dairy.com", "password": "SecurePassword123" }`
  * *Response Data:* `{ "accessToken": "eyJ...", "refreshToken": "eyJ...", "user": { "id": "uuid", "fullName": "Admin User", "roles": ["FARM_OWNER"] } }`
* **`POST /api/v1/auth/refresh`**
  * *Request Body:* `{ "refreshToken": "eyJ..." }`
  * *Response Data:* `{ "accessToken": "eyJ..." }`
* **`GET /api/v1/auth/me`**
  * *Response Data:* Current user profile and role permissions list.

---

### 2.2 Domain A: Your Dairy

#### Overview Dashboard
* **`GET /api/v1/dashboard/overview?period=daily&date=2026-10-05`**
  * *Response Data:*
    ```json
    {
      "period": "2026-10-05",
      "comparisonPeriod": "2026-10-04",
      "kpis": {
        "milkRecordedLitres": 25.0,
        "salesRevenue": 1500.00,
        "operatingCost": 1616.67,
        "dryFertiliserOutputKg": 0.0
      },
      "operatingValues": {
        "farmCost": 1336.67,
        "productionAndBiogasCost": 280.00,
        "acceptedBmcIntakeLitres": 25.0,
        "currentBmcBalanceLitres": 5.0,
        "openSalesOrders": 0
      },
      "alerts": [
        { "id": "ALT-1", "type": "LOW_FEED", "message": "Reorder Feed: Maize has 0 kg remaining" }
      ]
    }
    ```

#### Herd & Calves
* **`GET /api/v1/herd?status=LACTATING&search=Ganga`**
* **`POST /api/v1/herd`**
  * *Request Body:*
    ```json
    {
      "earTag": "210385",
      "name": "Ganga",
      "breed": "HF",
      "sex": "FEMALE",
      "dateOfBirth": "2022-03-15",
      "status": "LACTATING",
      "bodyWeightKg": 420.5,
      "damTag": "12001",
      "lastCalvingDate": "2026-08-10",
      "bodyConditionScore": 3.5,
      "notes": "High yield prime producer"
    }
    ```

#### Milking Log
* **`POST /api/v1/milking`**
  * *Request Body:*
    ```json
    {
      "recordDate": "2026-10-05",
      "animalTag": "210385",
      "session": "MORNING",
      "yieldLitres": 15.0,
      "disposition": "ELIGIBLE",
      "notes": "Good flow"
    }
    ```
  * *Server Validation:* If cow has active milk withdrawal date $> 2026-10-05$, server rejects `ELIGIBLE` and returns `400 Bad Request: Milk cannot be eligible for collection during active withdrawal period`.

#### Feed Planning & Entries
* **`GET /api/v1/feed/target?animalTag=210385`**
  * *Response Data:* `{ "animalTag": "210385", "averageYield7Days": 25.0, "targetConcentrateKg": 8.0, "rule": "1 kg base + 0.4 kg/L (max 8 kg)" }`
* **`POST /api/v1/feed`**
  * *Request Body:* `{ "recordDate": "2026-10-05", "animalTag": "210385", "stockItemId": "feed-item-uuid", "quantityKg": 7.5, "feedType": "CONCENTRATE" }`

#### Daily Farm Costing
* **`GET /api/v1/costing/daily-milk?date=2026-10-05`**
  * *Response Data:*
    ```json
    {
      "date": "2026-10-05",
      "isComplete": true,
      "eligibleMilkLitres": 25.0,
      "breakdown": {
        "feedConsumed": 0.00,
        "medicinesUsed": 0.00,
        "otherMaterials": 0.00,
        "farmSalariesDaily": 1266.67,
        "farmElectricity": 70.00,
        "otherFarmExpenses": 0.00
      },
      "totalDailyFarmCost": 1336.67,
      "costPerLitre": 53.47
    }
    ```

---

### 2.3 Domain B: Milk to Market

#### BMC & Milk Intake
* **`POST /api/v1/bmc/intake`**
  * *Request Body:*
    ```json
    {
      "recordDate": "2026-10-05",
      "source": "FARM",
      "supplierRoute": "Main Paddock",
      "quantityLitres": 25.0,
      "externalTotalCost": 0.0,
      "decision": "ACCEPTED",
      "temperatureC": 4.2,
      "fatPercentage": 4.1,
      "snfPercentage": 8.6,
      "clr": 29.5,
      "ph": 6.7,
      "notes": "Farm morning intake"
    }
    ```
* **`GET /api/v1/bmc/balance`**
  * *Response Data:* `{ "tankCapacityLitres": 2000.0, "availableBmcLitres": 5.0, "totalAcceptedLitres": 5.0, "totalRejectedLitres": 1000.0 }`

#### Production Batches
* **`POST /api/v1/production/batches`**
  * *Request Body:*
    ```json
    {
      "recordDate": "2026-10-05",
      "productType": "PANEER",
      "bmcMilkConsumedL": 50.0,
      "finishedQuantity": 9.2,
      "unitOfMeasure": "KG",
      "lpgStockItemId": "lpg-uuid",
      "lpgUsedKg": 1.5,
      "byproductQuantityKg": 40.0,
      "processRecord": "Heated to 85C, coagulated with citric acid",
      "expiryDate": "2026-10-12",
      "qualityRelease": "HOLD"
    }
    ```

#### Packaging Runs
* **`POST /api/v1/packaging/runs`**
  * *Request Body:*
    ```json
    {
      "recordDate": "2026-10-05",
      "productionBatchId": "batch-uuid",
      "packSize": 0.25,
      "packUnit": "KG",
      "numberOfPacks": 36,
      "packagingItemId": "pouch-uuid",
      "materialConsumed": 36.0
    }
    ```

#### Sales & Payments
* **`POST /api/v1/sales`**
  * *Request Body:*
    ```json
    {
      "recordDate": "2026-10-05",
      "packagingRunId": "pkg-uuid",
      "packsSold": 20,
      "customerName": "Dandiri General Store",
      "pricePerPack": 75.00,
      "amountReceived": 1000.00,
      "orderReference": null
    }
    ```
* **`POST /api/v1/payments`**
  * *Request Body:*
    ```json
    {
      "recordDate": "2026-10-06",
      "saleId": "sale-uuid",
      "amountReceived": 500.00,
      "paymentMethod": "CASH"
    }
    ```

---

### 2.4 Domain C: Business & Operations

#### Common Inventory
* **`POST /api/v1/inventory/items`**
* **`POST /api/v1/inventory/receipts`**
  * *Request Body:*
    ```json
    {
      "recordDate": "2026-10-05",
      "stockItemId": "item-uuid",
      "quantity": 100.0,
      "supplier": "Kisan Feeds",
      "supplierLot": "LOT-8891",
      "expiryDate": "2027-04-01",
      "totalCost": 2200.00
    }
    ```

#### Reports & Exports
* **`GET /api/v1/reports/summary?from=2026-10-01&to=2026-10-05`**
* **`GET /api/v1/reports/export/costs?from=2026-10-01&to=2026-10-05`** (Returns CSV)
* **`GET /api/v1/reports/export/materials?from=2026-10-01&to=2026-10-05`** (Returns CSV)
* **`GET /api/v1/reports/backup/json`** (Returns full JSON database dump)

#### Farm Settings
* **`GET /api/v1/settings`**
* **`PUT /api/v1/settings`**
  * *Request Body:*
    ```json
    {
      "bmcCapacityLitres": 2000.0,
      "feedBaseKg": 1.0,
      "feedRatePerLitre": 0.4,
      "feedMaxCapKg": 8.0,
      "electricityTariff": 1.40,
      "farmDefaultKwh": 50.0,
      "productionDefaultKwh": 200.0,
      "mgmtSalaryToFarmPct": 50.0
    }
    ```
