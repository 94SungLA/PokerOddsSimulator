from pydantic import BaseModel, ConfigDict
from typing import List, Union
from datetime import datetime

class HistoryRecordCreate(BaseModel):
    hero_hand: List[str]
    opponent_ranges: List[Union[str, List[str]]]
    community_cards: List[str]
    win_rate: float
    tie_rate: float
    lose_rate: float

class HistoryRecordResponse(BaseModel):
    id: int
    hero_hand: List[str]
    opponent_ranges: List[Union[str, List[str]]]
    community_cards: List[str]
    win_rate: float
    tie_rate: float
    lose_rate: float
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True)
