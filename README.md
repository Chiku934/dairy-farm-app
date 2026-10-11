# Dairy Farm Management System

Enterprise-grade management platform for dairy farm and milk processing operations, supporting herd care, milk intake, batch processing, packaging, inventory, and cost reconciliation.

---

## 1. Architecture & Tech Stack

* **Mobile Client:** Flutter 3.x (Dart) Android-first application using `flutter_riverpod` for state management and `go_router` for declarative navigation.
* **Backend:** Node.js, NestJS (TypeScript), TypeORM, and Swagger/OpenAPI.
* **Database:** MySQL 8.0 / MariaDB (InnoDB, utf8mb4) using strict `DECIMAL` types for monetary amounts and measured quantities.
* **Security:** JWT authentication with role-based access control across 11 logical user roles.

---

## 2. Monorepo Organization

```
dairy-farm-app/
├── apps/
│   ├── mobile/              # Flutter mobile app with feature-first architecture
│   └── api/                 # NestJS REST API with versioning, Swagger & validation
├── packages/
│   └── api-contracts/       # Shared TypeScript enums, response envelopes & DTOs
├── database/
│   ├── migrations/          # 001_initial_schema.sql (ACID schema DDL)
│   └── seeds/               # 001_seed_master_data.sql (Roles, settings, stock)
├── docs/                    # Architectural specifications and RTM
│   ├── REQUIREMENTS.md      # Full 24-module Requirement Traceability Matrix
│   ├── ARCHITECTURE.md      # Multi-tier system architecture & diagrams
│   ├── DATABASE_DESIGN.md   # Relational schema, ERD & data dictionary
│   ├── API_CONTRACTS.md     # REST endpoint specifications & Swagger schemas
│   ├── UI_DESIGN_SYSTEM.md  # Design tokens, typography & component library
│   ├── IMPLEMENTATION_STATUS.md # 24-module phase status matrix
│   ├── TEST_STRATEGY.md     # Unit, integration, E2E & widget test plan
│   ├── OPEN_QUESTIONS.md    # Domain clarifications & calculation rules
│   └── DEV_SETUP.md         # Windows developer onboarding guide
├── scripts/
│   ├── dev-api.bat          # Launch NestJS in dev mode
│   ├── dev-mobile.bat       # Launch Flutter mobile application
│   └── test-all.bat         # Run all automated test suites
├── .github/workflows/ci.yml # Continuous Integration workflow
├── .env.example             # Placeholder environment template
├── .gitignore               # Multi-tier ignore rules
└── README.md
```

---

## 3. Quick Launch Commands (Windows)

### Launch NestJS Backend API
```cmd
scripts\dev-api.bat
```
* **API Versioned Base:** `http://localhost:3000/api/v1`
* **Swagger OpenAPI Documentation:** `http://localhost:3000/api/docs`

### Launch Flutter Mobile Application
```cmd
scripts\dev-mobile.bat
```

### Run All Monorepo Test Suites
```cmd
scripts\test-all.bat
```

For detailed prerequisite setup and database initialization, see [docs/DEV_SETUP.md](docs/DEV_SETUP.md).
