from pydantic import BaseModel, Field
from typing import List

class EvaluateRequest(BaseModel):
    cards: List[str] = Field(..., description="List of 5 to 7 cards to evaluate")

class PotentialImprovement(BaseModel):
    improvement: str
    outs: int
    outs_cards: List[str]
    probability: float

class EvaluateResponse(BaseModel):
    hand_type: str
    rank_class: int
    potential_improvements: List[PotentialImprovement]
    hand_strength_summary: str
