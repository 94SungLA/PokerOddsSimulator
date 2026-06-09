import pytest
from app.services.simulator import simulator_service
from app.schemas.simulator import SimulationRequest
from pydantic import ValidationError

def test_deterministic_AA_vs_KK():
    # Aces vs Kings on a dry board, 100 simulations
    result = simulator_service.simulate(
        player_hand_strs=["As", "Ah"],
        opponent_hands_strs=[["Ks", "Kh"]],
        community_cards_strs=["2c", "3d", "4h", "7s", "8c"],
        total_players=2,
        simulations=100
    )
    assert result["simulations_run"] == 100
    p0 = result["player_results"][0]
    p1 = result["player_results"][1]
    
    # Player 0 has One Pair (Aces), Player 1 has One Pair (Kings)
    # Player 0 wins 100%
    assert p0["win_rate"] == 1.0
    assert p0["hand_type_distribution"]["One Pair"] == 1.0
    assert p1["win_rate"] == 0.0
    assert p1["hand_type_distribution"]["One Pair"] == 1.0

def test_validation_duplicates():
    # Duplicate cards should raise ValidationError
    with pytest.raises(ValidationError) as excinfo:
        SimulationRequest(
            player_hand=["As", "Ah"],
            opponent_hands=[["As", "Kd"]], # duplicate As
            community_cards=["Js", "Ts", "3c"],
            total_players=2,
            simulations=1000
        )
    assert "Duplicate cards found" in str(excinfo.value)

def test_validation_invalid_rank_suit():
    # Invalid rank
    with pytest.raises(ValidationError) as excinfo:
        SimulationRequest(
            player_hand=["1s", "Ah"],
            total_players=2,
            simulations=1000
        )
    assert "Card rank '1' in '1s' is invalid" in str(excinfo.value)

    # Invalid suit
    with pytest.raises(ValidationError) as excinfo:
        SimulationRequest(
            player_hand=["Ax", "Ah"],
            total_players=2,
            simulations=1000
        )
    assert "Card suit 'x' in 'Ax' is invalid" in str(excinfo.value)

def test_validation_incorrect_hand_length():
    with pytest.raises(ValidationError) as excinfo:
        SimulationRequest(
            player_hand=["As"], # only 1 card
            total_players=2,
            simulations=1000
        )
    assert "Player hand must contain exactly 2 cards" in str(excinfo.value)
