from fastapi import APIRouter, HTTPException
from app.schemas.simulator import SimulationRequest, SimulationResponse
from app.services.simulator import simulator_service

router = APIRouter()

@router.post("/simulate", response_model=SimulationResponse)
def simulate_odds(request: SimulationRequest):
    try:
        results = simulator_service.simulate(
            player_hand_strs=request.player_hand,
            opponent_hands_strs=request.opponent_hands,
            opponent_ranges_strs=request.opponent_ranges,
            community_cards_strs=request.community_cards,
            total_players=request.total_players,
            simulations=request.simulations
        )
        return results
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Simulation failed: {str(e)}")
