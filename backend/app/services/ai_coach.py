import os
import httpx
from typing import List, Union

def load_dotenv():
    # .env is located in the backend root directory (two levels up from this file)
    current_dir = os.path.dirname(os.path.abspath(__file__))
    dotenv_path = os.path.abspath(os.path.join(current_dir, "..", "..", ".env"))
    if os.path.exists(dotenv_path):
        with open(dotenv_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, val = line.split("=", 1)
                    os.environ[key.strip()] = val.strip().strip('"').strip("'")

# Load environment variables on module import
load_dotenv()

class AICoachService:
    def __init__(self):
        self.api_key = os.environ.get("GEMINI_API_KEY", "")
        self.model = "gemini-flash-latest"


    def get_explanation(
        self,
        hero_hand: List[str],
        community_cards: List[str],
        opponent_ranges: List[Union[str, List[str]]],
        win_rate: float,
        tie_rate: float,
        lose_rate: float
    ) -> str:
        # Construct the context description
        hero_hand_str = ", ".join(hero_hand)
        board_str = ", ".join(community_cards) if community_cards else "無（Pre-flop 階段）"
        
        opponents_str_list = []
        for i, opp in enumerate(opponent_ranges):
            if isinstance(opp, list):
                opponents_str_list.append(f"對手 {i+1} 手牌: " + (", ".join(opp) if opp else "隨機"))
            else:
                opponents_str_list.append(f"對手 {i+1} 範圍: " + (opp if opp else "隨機"))
        opponents_str = " | ".join(opponents_str_list)

        prompt = (
            f"您是一位專業的德州撲克教練與分析大師。請使用「繁體中文」針對以下德州撲克對局進行精準的策略剖析：\n\n"
            f"【對局狀態】\n"
            f"• Hero 手牌: {hero_hand_str}\n"
            f"• 公共牌面 (Board): {board_str}\n"
            f"• 對手配置: {opponents_str}\n\n"
            f"【計算勝率】\n"
            f"• 贏率 (Win): {win_rate * 100:.2f}%\n"
            f"• 平手率 (Tie): {tie_rate * 100:.2f}%\n"
            f"• 輸率 (Lose): {lose_rate * 100:.2f}%\n\n"
            f"請寫一份簡短且結構化的分析，包含以下四個部分：\n"
            f"1. 勝率解讀 (Equity Interpretation)：解讀目前的勝率狀況與領先/落後形勢。\n"
            f"2. 對手範圍強度 (Opponent Range Strength)：評估對手可能做出的牌型強度。\n"
            f"3. 潛在風險與警訊 (Risk Factors)：警示聽牌、成牌或被反超的危險因素。\n"
            f"4. 新手策略建議 (Beginner-Friendly Advice)：給新手的具體行動指引（過牌/跟注/下注/棄牌）。"
        )

        # Prioritize the hardcoded key in self.api_key, fall back to environment variable if empty
        api_key = self.api_key or os.environ.get("GEMINI_API_KEY")
        if api_key:
            masked_key = (api_key[:12] + "..." + api_key[-6:]) if len(api_key) > 18 else "short_or_invalid"
            print(f"[Gemini API] 啟動請求，目前使用的金鑰為: {masked_key}")
            models_to_try = [
                "gemini-2.5-flash",
                "gemini-1.5-flash-latest",
                "gemini-1.5-pro-latest",
            ]
            
            headers = {"Content-Type": "application/json"}
            payload = {
                "contents": [
                    {
                        "parts": [
                            {"text": prompt + "\n\n【重要要求】請直接從『### 1. 勝率解讀 (Equity Interpretation)』開始輸出，不要加上任何前言、問候語、或重複手牌與公牌等輸入狀態回顧，確保內容精簡且完全聚焦於策略建議。"}
                        ]
                    }
                ],
                "generationConfig": {
                    "temperature": 0.3,
                    "maxOutputTokens": 8192
                }
            }

            for model in models_to_try:
                url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
                print(f"[Gemini API] 嘗試使用模型: {model}")
                try:
                    response = httpx.post(url, json=payload, headers=headers, timeout=25.0)
                    if response.status_code == 200:
                        data = response.json()
                        text = data["candidates"][0]["content"]["parts"][0]["text"]
                        print(f"[Gemini API] 模型 {model} 呼叫成功！")
                        print(f"[Gemini API] 回傳內容如下：\n{text}\n[Gemini API] 回傳內容結束")
                        return text.strip()
                    else:
                        print(f"[Gemini API] 模型 {model} 失敗 (狀態碼 {response.status_code}): {response.text}")
                except (httpx.ConnectTimeout, httpx.ConnectError) as e:
                    print(f"[Gemini API] 連線至 Google API 失敗 (連線逾時/網路錯誤): {e}。跳過其他模型嘗試。")
                    break
                except Exception as e:
                    print(f"[Gemini API] 模型 {model} 呼叫異常: {e}")




        # Fallback rule-based explanation if Gemini is unavailable or not configured
        return self._generate_fallback(hero_hand, community_cards, win_rate, tie_rate, lose_rate)

    def _generate_fallback(
        self,
        hero_hand: List[str],
        community_cards: List[str],
        win_rate: float,
        tie_rate: float,
        lose_rate: float
    ) -> str:
        win_pct = win_rate * 100
        
        # Categorize situation
        if win_pct >= 65:
            title = "【極佳領先】"
            equity_desc = f"您處於絕對優勢（勝率 {win_pct:.1f}%）。此時您是牌桌上的強勢方，做成大牌或強對子的機率極高。"
            opp_desc = "對手範圍非常落後。對手此時可能在追尋某種聽牌，或者是持有弱一對、兩對等邊緣牌型。"
            risk_desc = "注意公共牌是否成對（防備葫蘆），或公牌是否有多張同花/順子可能。避免對手用小成本在轉牌或河牌完成反超。"
            advice_desc = "建議進行價值下注（Value Bet）以獲取最大籌碼量，也可以在對手下注時進行加注（Raise）。不宜過於被動地過牌過多。"
        elif win_pct >= 40:
            title = "【中等均勢】"
            equity_desc = f"您處於均勢對局（勝率 {win_pct:.1f}%）。此時通常擁有一對或強聽牌，仍有很大的勝負懸念。"
            opp_desc = "對手的範圍分佈均勻，可能包含相似強度的一對、高牌聽牌。對手極有機會與您形成激烈的對攻。"
            risk_desc = "需要警惕高張牌的出現。如果對手持續下大注，表明其可能持有更強的對子，您的跟注需要考慮底池限額與聽牌勝率。"
            advice_desc = "控制底池大小（Pot Control）是此時的關鍵。多採取過牌跟注（Check-Call）或小額下注。避免隨意推入全部籌碼。"
        elif win_pct >= 15:
            title = "【落後追趕】"
            equity_desc = f"您目前處於落後局勢（勝率 {win_pct:.1f}%）。手牌可能尚未成型，需要公牌的幫助才能獲勝。"
            opp_desc = "對手很有可能已經持有成牌（一對以上）。如果是多人對局，至少有一位對手此時手牌強於您。"
            risk_desc = "如果您的聽牌（如順子、同花聽牌）沒有在下一張牌中擊中，您的勝率將進一步崩潰。切忌盲目高額跟注。"
            advice_desc = "如果您擁有強聽牌（如同花聽牌或兩頭順子聽牌，有 8-9 個 Outs），在賠率合適時可以選擇跟注（Call）。否則，面對重注應果斷棄牌（Fold）。"
        else:
            title = "【極度落後】"
            equity_desc = f"您的形勢非常嚴峻（勝率 {win_pct:.1f}%）。此時手牌幾乎沒有成牌價值，極大概率落後於所有對手。"
            opp_desc = "對手極大概率已經形成實質性的強大成牌型。您的底牌在此時沒有任何攤牌優勢。"
            risk_desc = "繼續投入籌碼將面臨極高機率的虧損，任何試圖詐唬（Bluff）的行為都極具風險。"
            advice_desc = "如果面臨任何對手下注，請立即棄牌（Fold）。這局應該放棄，等待下一把更好的起手牌。"

        has_key = bool(os.environ.get("GEMINI_API_KEY", self.api_key))
        if has_key:
            footer = "*註：已偵測到 `GEMINI_API_KEY`，但目前 Gemini API 連線異常（如 503 伺服器忙碌或 429 限流）。此報告為教練系統產生的即時規則分析備援，服務恢復後即可取得 AI 分析！*"
        else:
            footer = "*註：目前未配置 `GEMINI_API_KEY` 環境變數，此報告為教練系統產生的即時規則分析。配置 API Key 後即可取得更具體多變的 AI 解說！*"

        return (
            f"### {title} AI 教練策略報告 (Rule-based Fallback)\n\n"
            f"#### 1. 勝率解讀 (Equity Interpretation)\n"
            f"{equity_desc}\n\n"
            f"#### 2. 對手範圍強度 (Opponent Range Strength)\n"
            f"{opp_desc}\n\n"
            f"#### 3. 潛在風險與警訊 (Risk Factors)\n"
            f"{risk_desc}\n\n"
            f"#### 4. 新手策略建議 (Beginner-Friendly Advice)\n"
            f"{advice_desc}\n\n"
            f"{footer}"
        )

ai_coach_service = AICoachService()
