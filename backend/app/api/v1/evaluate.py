from fastapi import APIRouter, HTTPException
from app.schemas.evaluate import EvaluateRequest, EvaluateResponse
from app.services.evaluator import Card, analyze_hand_improvements

router = APIRouter()

@router.post("", response_model=EvaluateResponse)
def evaluate_hand_endpoint(request: EvaluateRequest):
    if len(request.cards) not in (5, 6, 7):
        raise HTTPException(
            status_code=400,
            detail="You must provide exactly 5, 6, or 7 cards for evaluation"
        )
    
    try:
        parsed_cards = [Card.from_str(c) for c in request.cards]
        results = analyze_hand_improvements(parsed_cards)
        return results
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Hand evaluation failed: {str(e)}")
