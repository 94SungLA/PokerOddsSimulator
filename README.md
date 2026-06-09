# 🃏 PokerLab — 德州撲克勝率模擬器

> 使用 Monte Carlo 演算法即時計算德州撲克勝率，搭配 AI 教練策略分析

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python)](https://python.org)
[![Firebase](https://img.shields.io/badge/Firebase-Auth-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## ✨ 功能特色

| 功能 | 說明 |
|------|------|
| 🎴 **互動式牌桌** | 點選式 52 張撲克牌面板，直覺選擇手牌與公共牌 |
| 📊 **Monte Carlo 模擬** | 後端高效能模擬引擎，支援數千至數萬次模擬迭代 |
| 🤖 **AI 教練** | 串接 Google Gemini AI，針對牌面給出策略分析與操作建議 |
| 📈 **Outs 分析** | 即時計算可能牌型的 Outs 數量與成牌機率 |
| 📜 **歷史紀錄** | 自動儲存模擬紀錄至 SQLite，可回顧歷史牌局 |
| 🔐 **Google 登入** | Firebase Authentication，支援 Google Sign-In |
| 🌙 **深色/淺色主題** | Material Design 3 雙主題切換 |
| ⚙️ **可調整參數** | 自訂模擬次數、玩家人數 (2-9人) |

---

## 🏗️ 技術架構

```
┌─────────────────────┐     REST API (JSON)     ┌─────────────────────┐
│   Frontend          │ ◄──────────────────────► │   Backend           │
│   Flutter (Dart)    │       HTTP / Dio         │   FastAPI (Python)  │
│                     │                          │                     │
│ • Riverpod 狀態管理  │                          │ • Monte Carlo 模擬  │
│ • Firebase Auth     │                          │ • Hand Evaluator    │
│ • Material Design 3 │                          │ • Gemini AI 串接    │
│ • 深色/淺色主題      │                          │ • SQLite 資料庫     │
└─────────────────────┘                          └─────────────────────┘
```

---

## 🚀 快速開始

### 環境需求

- **Flutter** 3.x+
- **Python** 3.11+
- **Dart** SDK ^3.11.0

### 1. Clone 專案

```bash
git clone https://github.com/94SungLA/PokerOddsSimulator.git
cd PokerOddsSimulator
```

### 2. 啟動後端

```bash
cd backend

# 建立虛擬環境
python3 -m venv venv
source venv/bin/activate

# 安裝依賴
pip install -r requirements.txt

# 設定環境變數（可選，用於 AI 教練功能）
cp .env.example .env
# 編輯 .env，填入你的 Gemini API Key

# 啟動伺服器
uvicorn app.main:app --reload
```

後端將啟動於 `http://127.0.0.1:8000`

### 3. 啟動前端

```bash
cd frontend

# 安裝依賴
flutter pub get

# 啟動 App
flutter run
```

---

## 📁 專案結構

```
PokerOddsSimulator/
├── backend/                      # FastAPI 後端
│   ├── app/
│   │   ├── api/v1/               # API 路由（模擬、歷史、AI 解說）
│   │   ├── core/                 # 核心配置 & 資料庫
│   │   ├── models/               # SQLAlchemy ORM 模型
│   │   ├── schemas/              # Pydantic 資料驗證
│   │   └── services/             # 核心服務
│   │       ├── evaluator.py      # 牌型判斷演算法
│   │       ├── simulator.py      # Monte Carlo 模擬引擎
│   │       └── ai_coach.py       # Gemini AI 教練服務
│   ├── tests/                    # 單元測試
│   ├── requirements.txt
│   ├── .env.example              # 環境變數範本
│   └── Dockerfile
│
├── frontend/                     # Flutter 前端
│   └── lib/
│       ├── core/
│       │   ├── network/          # API Client (Dio)
│       │   └── theme/            # 主題設計系統
│       └── features/
│           ├── auth/             # Firebase 認證模組
│           └── simulator/        # 模擬器模組
│               ├── data/         # 資料模型
│               ├── domain/       # 狀態管理 (Riverpod)
│               └── ui/           # 頁面 & 元件
│
└── project_plan.md               # 專案規劃書
```

---

## 📦 主要依賴

### Frontend (Flutter)

| 套件 | 版本 | 用途 |
|------|------|------|
| `flutter_riverpod` | ^2.5.0 | 狀態管理 |
| `dio` | ^5.4.0 | HTTP 網路請求 |
| `google_fonts` | ^6.2.0 | Google Fonts 字型 |
| `flutter_animate` | ^4.5.0 | 微動畫效果 |
| `flutter_markdown` | ^0.7.7 | Markdown 渲染 |
| `firebase_core` | ^3.1.0 | Firebase 核心 |
| `firebase_auth` | ^5.1.1 | Firebase 認證 |
| `google_sign_in` | ^6.2.1 | Google 登入 |

### Backend (Python)

| 套件 | 用途 |
|------|------|
| `fastapi` | Web API 框架 |
| `uvicorn` | ASGI 伺服器 |
| `sqlalchemy` | ORM 資料庫操作 |
| `google-generativeai` | Gemini AI API |
| `pydantic` | 資料驗證 |

---

## 🔑 環境變數

| 變數 | 說明 | 必要 |
|------|------|------|
| `GEMINI_API_KEY` | Google Gemini API 金鑰 | 選填（未設定時使用規則教練） |

---

## 📄 API 文件

後端啟動後，可在以下網址查看自動生成的 API 文件：

- **Swagger UI**: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- **ReDoc**: [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)

### 主要 API 端點

| Method | Endpoint | 說明 |
|--------|----------|------|
| `POST` | `/api/v1/simulator/simulate` | 執行 Monte Carlo 勝率模擬 |
| `POST` | `/api/v1/evaluate` | 評估手牌 + 公共牌的 Outs |
| `POST` | `/api/v1/explain` | AI 教練策略解說 |
| `GET` | `/api/v1/history/` | 取得歷史模擬紀錄 |
| `POST` | `/api/v1/history/` | 儲存模擬紀錄 |
| `GET` | `/api/v1/ranges/presets` | 取得對手範圍預設 |

---

## 🧪 測試

```bash
cd backend
source venv/bin/activate
pytest tests/ -v
```

---

## 📝 License

MIT License
