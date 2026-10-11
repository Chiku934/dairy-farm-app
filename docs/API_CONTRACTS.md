# Dairy Farm Management System - API Contracts & Specifications

## 1. REST API Architecture & Standards

All endpoints follow RESTful standards and return a uniform JSON response envelope across every module.

### 1.1 Base URL & Security
* **Base URL:** `/api/v1`
* **Swagger OpenAPI Documentation:** `http://localhost:3000/api/docs`
* **Authentication Header:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`

### 1.2 Standard Success Envelope (`ResponseEnvelope<T>`)
Every 2xx response is wrapped by `TransformInterceptor`:
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Operation completed successfully",
  "data": {},
  "timestamp": "2026-10-11T10:30:00.000Z"
}
```

### 1.3 Standard Error Envelope (`ApiErrorResponse`)
All exceptions are formatted uniformly by `AllExceptionsFilter`:
```json
{
  "success": false,
  "statusCode": 400,
  "error": "Bad Request",
  "message": [
    "email must be an email",
    "password must be longer than or equal to 8 characters"
  ],
  "path": "/api/v1/users",
  "timestamp": "2026-10-11T10:30:00.000Z"
}
```

---

## 2. Standard Pagination, Sorting & Filtering Contracts

All list endpoints extend `PaginationQueryDto` and return `PaginatedResult<T>`:

### 2.1 Query Parameters
| Parameter | Type | Default | Constraints | Description |
| :--- | :--- | :--- | :--- | :--- |
| `page` | integer | `1` | Min: 1 | 1-indexed page number |
| `limit` | integer | `20` | Min: 1, Max: 100 | Items per page |
| `sortBy` | string | `'createdAt'` | Optional | Column field name to order by |
| `sortOrder`| enum | `'DESC'` | `'ASC'` or `'DESC'` | Sort direction |
| `search` | string | `null` | Optional | Free-text keyword search across indexed text fields |

### 2.2 Paginated Data Envelope (`PaginatedResult<T>`)
Inside the `data` property:
```json
{
  "items": [],
  "total": 142,
  "page": 1,
  "limit": 20,
  "totalPages": 8
}
```

---

## 3. Foundation Endpoint Specifications

### 3.1 Authentication & Sessions (`/api/v1/auth`)

#### `POST /api/v1/auth/login` (Public)
Authenticates a user and issues a short-lived access JWT and a long-lived rotating refresh token.
* **Request Body:**
```json
{
  "email": "admin@dairyfarm.local",
  "password": "Password@123"
}
```
* **Success Response (200):**
```json
{
  "accessToken": "eyJhbGciOi...",
  "refreshToken": "7c8e9b60-49...",
  "tokenType": "Bearer",
  "expiresInSeconds": 3600,
  "user": {
    "id": "usr-dev-admin",
    "email": "admin@dairyfarm.local",
    "fullName": "Arjun Patel",
    "roles": ["FARM_OWNER"],
    "permissions": ["farm:settings:read", "farm:settings:write", "..."]
  }
}
```

#### `POST /api/v1/auth/refresh` (Public)
Rotates the refresh token and issues a new access token atomically inside a database transaction.
* **Request Body:**
```json
{
  "refreshToken": "7c8e9b60-49..."
}
```

#### `GET /api/v1/auth/me` (Authenticated)
Returns identity, assigned roles, and aggregated permissions of the currently authenticated token bearer.

#### `POST /api/v1/auth/logout` (Authenticated)
Revokes the caller's active refresh token session in `user_sessions`.

---

### 3.2 Farm Settings & Identity (`/api/v1/settings`)

#### `GET /api/v1/settings` (Authenticated)
Returns enterprise profile, physical contact identity, and operational calculation constants.
* **Response (200):**
```json
{
  "id": 1,
  "farmName": "Kaivalya Dairy Farm & Processing",
  "address": "Dandiri, Near NH-26",
  "district": "Koraput",
  "state": "Odisha",
  "pincode": "764036",
  "contactPhone": "+91 9876543210",
  "contactEmail": "support@kaivalyadairy.com",
  "currencyCode": "INR",
  "currencySymbol": "₹",
  "bmcCapacityLitres": 2000.0,
  "feedBaseKg": 1.0,
  "feedRatePerLitre": 0.4,
  "feedMaxCapKg": 8.0,
  "electricityTariff": 1.4,
  "farmDefaultKwh": 50.0,
  "productionDefaultKwh": 200.0,
  "mgmtSalaryToFarmPct": 50.0,
  "operatorName": "Kaivalya Team",
  "timezone": "Asia/Kolkata",
  "updatedAt": "2026-10-11T10:14:00.000Z"
}
```

#### `PATCH /api/v1/settings` & `PUT /api/v1/settings` (Authenticated, `farm:settings:write`)
Partially or fully updates enterprise profile, phone numbers, or operational cost multipliers.

---

### 3.3 Users, Roles & RBAC (`/api/v1/users`)

#### `GET /api/v1/users`
Returns paginated staff users with eager-joined roles and permissions. Supports `isActive` and `roleCode` filters.

#### `POST /api/v1/users`
Creates a staff user account inside a database transaction, hashing password with bcrypt.
* **Request Body:**
```json
{
  "email": "veterinarian.patro@dairyfarm.local",
  "password": "SecurePassword@123",
  "fullName": "Dr. Subrat Patro",
  "phone": "+91 9876543220",
  "roleIds": ["role-03"]
}
```

#### `GET /api/v1/users/roles`
Returns all 11 system roles with their full set of mapped granular permissions.

#### `GET /api/v1/users/permissions`
Lists all 33 granular permission capabilities grouped by module.

#### `POST /api/v1/users/:id/roles`
Atomically assigns or updates role assignments for a user.

---

### 3.4 Master Data & Taxonomy Lookups (`/api/v1/master-data`)

#### `GET /api/v1/master-data/uoms`
Returns units of measurement (`LTR`, `KG`, `GM`, `UNIT`, `PKT`, `BOX`, `CAN`, `KWH`, `HR`) with dimension and conversion factors.

#### `POST /api/v1/master-data/uoms`
Registers a new unit of measurement with uniqueness check on `code`.

#### `GET /api/v1/master-data/categories`
Lists all lookup categories (`ANIMAL_BREED`, `ANIMAL_SPECIES`, `HEALTH_DIAGNOSIS`, `FEED_TYPE`, `PAYMENT_MODE`, `QUALITY_GRADE`) with their active values.

#### `GET /api/v1/master-data/categories/:categoryCode/values`
Fetches sorted values for a specific category (e.g., `ANIMAL_BREED`).

#### `POST /api/v1/master-data/values`
Adds a new lookup item with optional JSON metadata and composite uniqueness validation (`category_code`, `code`).

---

### 3.5 Audit Logs & Compliance (`/api/v1/audit-logs`)

#### `GET /api/v1/audit-logs`
Returns paginated immutable system audit trail entries. Supports filtering by `entityType`, `action`, `userId`, and date ranges.
* **Item Model:**
```json
{
  "id": "uuid",
  "userId": "usr-dev-admin",
  "action": "UPDATE_SETTINGS",
  "entityType": "FARM_SETTINGS",
  "entityId": "1",
  "oldValues": { "feedRatePerLitre": 0.4 },
  "newValues": { "feedRatePerLitre": 0.42 },
  "ipAddress": "127.0.0.1",
  "userAgent": "Mozilla/5.0 ...",
  "createdAt": "2026-10-11T10:20:00.000Z"
}
```
