from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List, Union
from app.services.ai_coach import ai_coach_service

router = APIRouter()

class ExplainRequest(BaseModel):
    player_hand: List[str] = Field(..., description="Hero hand")
    community_cards: List[str] = Field(default_factory=list, description="Community cards")
    opponent_ranges: List[Union[str, List[str]]] = Field(default_factory=list, description="Opponent ranges or hands")
    win_rate: float
    tie_rate: float
    lose_rate: float

class ExplainResponse(BaseModel):
    explanation: str

@router.post("", response_model=ExplainResponse)
def explain_simulation(request: ExplainRequest):
    try:
        explanation = ai_coach_service.get_explanation(
            hero_hand=request.player_hand,
            community_cards=request.community_cards,
            opponent_ranges=request.opponent_ranges,
            win_rate=request.win_rate,
            tie_rate=request.tie_rate,
            lose_rate=request.lose_rate
        )
        return ExplainResponse(explanation=explanation)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Explanation failed: {str(e)}")



