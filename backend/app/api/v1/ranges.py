from fastapi import APIRouter
from typing import List
from app.schemas.ranges import RangePresetResponse

router = APIRouter()

PRESETS = [
    {"name": "Random (任何兩張牌)", "range_str": "100%", "description": "100% of hands"},
    {"name": "Top 5% (最強 5%)", "range_str": "top_5%", "description": "AA-TT, AKs, AQs, AJs, AKo"},
    {"name": "Top 10% (最強 10%)", "range_str": "top_10%", "description": "Top 10% equity hands"},
    {"name": "Top 15% (最強 15%)", "range_str": "top_15%", "description": "Top 15% equity hands"},
    {"name": "Top 20% (最強 20%)", "range_str": "top_20%", "description": "Top 20% equity hands"},
    {"name": "Top 30% (最強 30%)", "range_str": "top_30%", "description": "Top 30% equity hands"},
    {"name": "Pocket Pairs (所有對子 22+)", "range_str": "22+", "description": "AA, KK, QQ, JJ, TT, 99, 88, 77, 66, 55, 44, 33, 22"},
    {"name": "Pocket Pairs (大口袋對子 TT+)", "range_str": "TT+", "description": "AA, KK, QQ, JJ, TT"},
    {"name": "Broadways (高張同花 AQs+)", "range_str": "AQs+", "description": "AKs, AQs"},
    {"name": "Broadways (所有高張 AQ)", "range_str": "AQ", "description": "AKs, AQs, AKo, AQo"},
    {"name": "Suited Connectors (同花連張)", "range_str": "T9s, 98s, 87s, 76s, 65s, 54s", "description": "Suited consecutive cards"},
]

@router.get("", response_model=List[RangePresetResponse])
def get_presets():
    return PRESETS
