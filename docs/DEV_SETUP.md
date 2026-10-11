# Dairy Farm Management System - Local Development Setup Guide

## 1. System Prerequisites

The following development environment baseline has been detected and verified on your Windows system:

| Tool | Verified Version | Detected System Path |
| :--- | :--- | :--- |
| **Node.js** | `v20.19.6` (LTS) | `C:\Program Files\nodejs\node.EXE` |
| **npm** | `10.8.2` | `C:\Program Files\nodejs\npm.CMD` |
| **Flutter** | `3.38.5` (channel stable) | `C:\src\flutter\flutter\bin\flutter.BAT` |
| **Dart** | `3.10.4` | `C:\src\flutter\flutter\bin\dart.BAT` |
| **MySQL / MariaDB** | `10.4.32-MariaDB` (via XAMPP) | `C:\xampp\mysql\bin\mysql.exe` |
| **Git** | `2.x` | `C:\Program Files\Git\cmd\git.EXE` |

> [!NOTE]
> `mysql.exe` is located at `C:\xampp\mysql\bin\mysql.exe`. If you wish to use the `mysql` command directly in PowerShell or Command Prompt, add `C:\xampp\mysql\bin` to your Windows user or system `PATH` environment variable.

---

## 2. Monorepo Structure

```
dairy-farm-app/
  apps/
    mobile/              # Flutter Android/Tablet mobile application
    api/                 # NestJS REST API server (TypeScript)
  packages/
    api-contracts/       # Shared TypeScript enums, DTOs & response envelopes
  database/
    migrations/          # SQL DDL migrations (strict DECIMAL precision)
    seeds/               # Seed scripts for roles, settings & stock
  docs/                  # Complete system architectural specifications
  scripts/               # Windows developer batch runners (.bat)
  .github/workflows/     # GitHub Actions CI verification pipeline
  .gitignore             # Multi-layer secret & build artifact protection
  README.md              # Repository overview
```

---

## 3. Step-by-Step Setup Instructions (Windows)

### Step 1: Database Initialization (MySQL / XAMPP)
1. Start MySQL from the **XAMPP Control Panel** (or your local Windows MySQL service).
2. Create the application database:
   ```cmd
   C:\xampp\mysql\bin\mysql.exe -u root -e "CREATE DATABASE IF NOT EXISTS dairy_farm_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
   ```
3. Apply the initial schema migration:
   ```cmd
   C:\xampp\mysql\bin\mysql.exe -u root dairy_farm_db < database\migrations\001_initial_schema.sql
   ```
4. Apply seed master data (11 standard roles, farm settings, initial stock items):
   ```cmd
   C:\xampp\mysql\bin\mysql.exe -u root dairy_farm_db < database\seeds\001_seed_master_data.sql
   ```

### Step 2: Configure Environment Variables
1. Navigate to `apps/api`:
   ```cmd
   copy apps\api\.env.example apps\api\.env
   ```
2. Verify database credentials in `apps\api\.env`:
   ```ini
   PORT=3000
   DB_HOST=localhost
   DB_PORT=3306
   DB_USERNAME=root
   DB_PASSWORD=
   DB_DATABASE=dairy_farm_db
   JWT_SECRET=super_secret_development_key_min_32_chars
   ```

### Step 3: Run the NestJS Backend API
From the repository root:
```cmd
scripts\dev-api.bat
```
*(Or manually: `cd apps\api && npm run start:dev`)*

* **API Health Endpoint:** [http://localhost:3000/api/v1/health](http://localhost:3000/api/v1/health)
* **Interactive Swagger Documentation:** [http://localhost:3000/api/docs](http://localhost:3000/api/docs)

### Step 4: Run the Flutter Mobile Application
Ensure an Android emulator is running or an Android physical device is connected via USB:
```cmd
scripts\dev-mobile.bat
```
*(Or manually: `cd apps\mobile && flutter run`)*

---

## 4. Verification & Testing

To execute all automated unit, integration, and widget tests across the entire repository:

```cmd
scripts\test-all.bat
```

Or run suites independently:
* **Backend Unit Tests:** `cd apps\api && npm run test`
* **Mobile Widget Tests:** `cd apps\mobile && flutter test`
* **Mobile Static Analysis:** `cd apps\mobile && flutter analyze`
