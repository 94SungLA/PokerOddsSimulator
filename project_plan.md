# 德州撲克勝率模擬器 (PokerOddsSimulator) 專案規劃書

本文件為「德州撲克勝率模擬器」專案的系統規劃，包含系統架構、API 規格、資料夾結構以及開發 Roadmap。本專案將採用 **Flutter** 作為前端框架，**FastAPI** 作為後端 API 服務，並使用 **Monte Carlo 演算法**進行德州撲克的勝率與牌型模擬。

---

## 1. 系統架構 (System Architecture)

系統採用前後端分離（Client-Server）架構。前端負責卡牌選擇、盤面配置與模擬結果展示；後端負責執行高密度的 Monte Carlo 模擬與牌型判定演算法，並提供歷史紀錄的管理。

```mermaid
graph TD
    subgraph Frontend (Flutter App)
        UI[UI / 互動介面] --> State[狀態管理 Riverpod/Bloc]
        State --> API_Client[HTTP Client / Dio]
    end

    subgraph Backend (FastAPI Server)
        API_Client -->|REST API / JSON| API_Router[API Router]
        API_Router --> Service[模擬/計算服務]
        API_Router --> DB_Service[歷史紀錄服務]
        
        subgraph Core Engines
            Service --> Evaluator[牌型判斷器 Hand Evaluator]
            Service --> MCSimulator[蒙特卡羅模擬器 Monte Carlo Simulator]
        end
        
        DB_Service --> DB[(SQLite / PostgreSQL)]
    end
    
    subgraph Future Extensions
        API_Router -->|HTTPS| AI_Service[AI 解說服務 Gemini API]
    end
```

### 架構說明：
1. **Frontend (Flutter)**:
   - 提供直覺的拖放或點選式撲克牌輸入介面（包含玩家手牌與公共牌）。
   - 使用異步狀態管理，支援即時顯示模擬進度。
   - 本地快取與歷史紀錄呈現。
2. **Backend (FastAPI)**:
   - 選擇 FastAPI 是因為其基於 Python，擁有強大的數值計算生態系，且能利用 `asyncio` 輕量化處理並行請求。
   - 核心模擬器使用高效的位元運算（Bitwise operations）或快速查表法來優化 5 張/7 張牌的牌型判定（Hand Evaluation），確保 Monte Carlo 模擬（通常需要 10,000 次以上迭代）能在數毫秒內完成。
3. **Database (SQLite)**:
   - 用於存儲使用者的模擬歷史紀錄（輸入的牌組、計算出的勝率、模擬時間等）。

---

## 2. API 規格 (API Specifications)

API 基礎路徑：`/api/v1`

### 2.1 德州撲克勝率模擬 API
* **Endpoint**: `POST /simulator/simulate`
* **功能**: 根據輸入的玩家手牌與公共牌，執行 Monte Carlo 模擬，回傳勝率與牌型分布。
* **Request Body (JSON)**:
  ```json
  {
    "player_hand": ["As", "Kd"], 
    "opponent_hands": [
      ["Qh", "Qc"],
      [] 
    ],
    "community_cards": ["Js", "Ts", "3c"],
    "total_players": 3,
    "simulations": 20000
  }
  ```
  > *說明：卡牌格式使用兩個字元表示，如 "As" 代表 Ace of Spades (黑桃 A)，"Kd" 代表 King of Diamonds (方塊 K)。若對手手牌為空陣列 `[]`，表示該對手手牌隨機發牌。*
* **Response Body (JSON)**:
  ```json
  {
    "simulations_run": 20000,
    "elapsed_time_ms": 125.4,
    "player_results": [
      {
        "player_index": 0,
        "hand": ["As", "Kd"],
        "win_rate": 0.385,
        "tie_rate": 0.012,
        "lose_rate": 0.603,
        "hand_type_distribution": {
          "High Card": 0.05,
          "One Pair": 0.42,
          "Two Pair": 0.31,
          "Three of a Kind": 0.08,
          "Straight": 0.11,
          "Flush": 0.02,
          "Full House": 0.01,
          "Four of a Kind": 0.00,
          "Straight Flush": 0.00,
          "Royal Flush": 0.00
        }
      },
      {
        "player_index": 1,
        "hand": ["Qh", "Qc"],
        "win_rate": 0.603,
        "tie_rate": 0.012,
        "lose_rate": 0.385,
        "hand_type_distribution": {
          "High Card": 0.00,
          "One Pair": 0.35,
          "Two Pair": 0.40,
          "Three of a Kind": 0.15,
          "Straight": 0.05,
          "Flush": 0.01,
          "Full House": 0.04,
          "Four of a Kind": 0.00,
          "Straight Flush": 0.00,
          "Royal Flush": 0.00
        }
      }
    ]
  }
  ```

### 2.2 歷史紀錄 API
* **Endpoint**: `GET /history/`
* **功能**: 獲取歷史模擬紀錄列表（分頁）。
* **Query Parameters**:
  - `page`: int (default: 1)
  - `size`: int (default: 10)
* **Response Body (JSON)**:
  ```json
  {
    "items": [
      {
        "id": 1,
        "created_at": "2026-06-03T13:45:00Z",
        "player_hand": ["As", "Kd"],
        "community_cards": ["Js", "Ts", "3c"],
        "win_rate": 0.385,
        "total_players": 3
      }
    ],
    "total": 1,
    "page": 1,
    "size": 10,
    "pages": 1
  }
  ```

* **Endpoint**: `POST /history/`
* **功能**: 儲存單次模擬紀錄。
* **Request Body (JSON)**:
  ```json
  {
    "player_hand": ["As", "Kd"],
    "opponent_hands": [["Qh", "Qc"]],
    "community_cards": ["Js", "Ts", "3c"],
    "win_rate": 0.385,
    "total_players": 3
  }
  ```
* **Response Body (JSON)**:
  ```json
  {
    "id": 1,
    "status": "success"
  }
  ```

* **Endpoint**: `GET /history/{id}`
* **功能**: 獲取特定紀錄詳細資訊。
* **Response Body (JSON)**: 同上述 Simulate API 的 Response 結構，外加歷史紀錄 ID 與創建時間。

---

## 3. 資料夾結構 (Folder Structure)

專案目錄區分為 `frontend` 與 `backend` 兩個獨立的子專案。

```text
PokerOddsSimulator/
├── backend/                  # FastAPI 後端專案
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py           # 應用程式入口
│   │   ├── api/              # API 路由
│   │   │   ├── __init__.py
│   │   │   ├── v1/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── simulator.py
│   │   │   │   └── history.py
│   │   ├── core/             # 核心配置與資料庫連接
│   │   │   ├── config.py
│   │   │   └── database.py
│   │   ├── models/           # SQLAlchemy/SQLModel 資料庫模型
│   │   │   └── history.py
│   │   ├── schemas/          # Pydantic 資料驗證模型
│   │   │   ├── simulator.py
│   │   │   └── history.py
│   │   └── services/         # 業務邏輯與核心演算法
│   │       ├── evaluator.py  # 牌型判定演算法
│   │       └── simulator.py  # Monte Carlo 模擬器
│   ├── tests/                # 單元測試
│   ├── requirements.txt      # Python 依賴包
│   └── Dockerfile
│
├── frontend/                 # Flutter 前端專案
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── lib/
│   │   ├── core/             # 全域通用模組
│   │   │   ├── constants/    # 顏色、卡牌圖示、字型
│   │   │   ├── network/      # API 請求封裝 (Dio)
│   │   │   └── theme/        # 精緻深色/淺色主題設計
│   │   ├── features/         # 依功能模組劃分 (Clean Architecture)
│   │   │   ├── simulator/    # 模擬器模組
│   │   │   │   ├── data/     # 模擬器 API 介接與 Model
│   │   │   │   ├── domain/   # 核心模擬狀態與邏輯
│   │   │   │   └── ui/       # 牌桌、卡牌選擇器、勝率圖表
│   │   │   └── history/      # 歷史紀錄模組
│   │   │       ├── data/
│   │   │       ├── domain/
│   │   │       └── ui/       # 歷史紀錄列表與詳情頁
│   │   └── main.dart         # 前端入口
│   ├── pubspec.yaml          # Flutter 依賴配置
│   └── README.md
│
└── README.md                 # 專案總覽
```

---

## 4. 開發 Roadmap (Development Roadmap)

開發過程預計分為 5 個主要階段，由核心邏輯向下延伸至 UI 及歷史功能：

### 階段一：後端核心演算法與 API 開發（核心）
* **目標**: 完成德州撲克牌型判斷器與 Monte Carlo 模擬引擎。
* **開發細節**:
  1. 實作 5 張/7 張牌的牌型大小判斷演算法 (Evaluator)。透過 bitwise 或 rank hashing 優化速度。
  2. 實作 Monte Carlo 模擬核心：在手牌/公共牌未滿的情況下，隨機補滿剩餘卡牌，重複模擬 $N$ 次以得出勝率。
  3. 建立 FastAPI 專案，包裝 `/simulator/simulate` API。
  4. 撰寫單元測試驗證各式牌型（如：皇家同花順 vs 同花順、葫蘆 vs 三條）之判定正確性。

### 階段二：前端介面設計與卡牌選擇器（基礎 UI）
* **目標**: 實作精美且動態的 Flutter 撲克牌選擇介面與牌桌佈局。
* **開發細節**:
  1. 建立 Flutter 專案，配置配色系統（以深色木質或精緻賭場綠/深灰為背景）。
  2. 實作互動式撲克牌選擇組件（Card Selector Widget），支援拖拽或點擊將牌放入對應欄位（玩家手牌、公共牌等）。
  3. 實作動態微動畫（如發牌特效、卡牌翻面動畫）。
  4. 使用狀態管理（如 Riverpod）管理當前牌桌狀態（以防重複選擇同一張卡牌）。

### 階段三：前後端整合與模擬結果視覺化（核心整合）
* **目標**: 將前端牌桌狀態與後端 API 對接，並呈現視覺化的模擬結果。
* **開發細節**:
  1. 前端使用 Dio 串接 `/simulator/simulate` API。
  2. 實作模擬結果展示介面：
     - 各玩家勝率、平手率、敗率（以環狀圖或進度條呈現）。
     - 各玩家最終可能牌型的機率分佈直方圖。
  3. 實作載入動畫與防呆機制（手牌數量不足時禁止模擬）。

### 階段四：歷史紀錄功能（持久化與管理）
* **目標**: 支援儲存與讀取歷史模擬紀錄。
* **開發細節**:
  1. 後端建立 SQLite 資料庫，設計 History Table。
  2. 實作歷史紀錄 REST API (`GET /history/`, `POST /history/`)。
  3. 前端實作歷史紀錄頁面（包含歷史卡牌配置小縮圖、勝率摘要）。
  4. 支援點擊歷史紀錄可直接「載入牌桌」重新計算或修改。

### 階段五：優化、AI 準備與部署（Polish）
* **目標**: 效能調優與部署準備。
* **開發細節**:
  1. 後端模擬器效能調優（利用多線程或 Numba 加速 Monte Carlo 迭代）。
  2. 預留 AI 解說 API 介面（定義 `POST /history/{id}/explain`，為下一階段串接 LLM 做準備）。
  3. 使用 Docker 包裝後端，以利一鍵啟動與雲端部署。
