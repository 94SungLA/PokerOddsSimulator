from pydantic import BaseModel, Field, field_validator, model_validator
from typing import List, Dict

def validate_card_str(card: str) -> str:
    if len(card) != 2:
        raise ValueError(f"Card '{card}' must be exactly 2 characters")
    r, s = card[0], card[1]
    if r not in "23456789TJQKA":
        raise ValueError(f"Card rank '{r}' in '{card}' is invalid")
    if s not in "shdc":
        raise ValueError(f"Card suit '{s}' in '{card}' is invalid")
    return card

class SimulationRequest(BaseModel):
    player_hand: List[str] = Field(
        ..., 
        description="Hole cards of player 0 (exactly 2 cards)"
    )
    opponent_hands: List[List[str]] = Field(
        default_factory=list, 
        description="Hole cards of opponents (each must be 0 or 2 cards)"
    )
    opponent_ranges: List[str] = Field(
        default_factory=list,
        description="Hand ranges for opponents (e.g. 'JJ+, AQs+' or 'top_15%')"
    )
    community_cards: List[str] = Field(
        default_factory=list, 
        description="Community cards (0, 3, 4, or 5 cards)"
    )
    total_players: int = Field(
        default=2, 
        ge=2, 
        le=9, 
        description="Total number of players on the table (2 to 9)"
    )
    simulations: int = Field(
        default=10000, 
        ge=100, 
        le=100000, 
        description="Number of Monte Carlo iterations"
    )

    @field_validator('player_hand')
    @classmethod
    def validate_player_hand(cls, v: List[str]) -> List[str]:
        if len(v) != 2:
            raise ValueError("Player hand must contain exactly 2 cards")
        for card in v:
            validate_card_str(card)
        return v

    @field_validator('opponent_hands')
    @classmethod
    def validate_opponent_hands(cls, v: List[List[str]]) -> List[List[str]]:
        for opp in v:
            if len(opp) not in (0, 2):
                raise ValueError("Each opponent hand must contain either 0 or 2 cards")
            for card in opp:
                validate_card_str(card)
        return v

    @field_validator('community_cards')
    @classmethod
    def validate_community(cls, v: List[str]) -> List[str]:
        if len(v) not in (0, 3, 4, 5):
            raise ValueError("Community cards must be 0, 3, 4, or 5 cards")
        for card in v:
            validate_card_str(card)
        return v

    @model_validator(mode='after')
    def validate_game_state(self) -> 'SimulationRequest':
        # Check duplicate cards
        all_cards = list(self.player_hand) + list(self.community_cards)
        for opp in self.opponent_hands:
            all_cards.extend(opp)
        if len(all_cards) != len(set(all_cards)):
            duplicates = list(set([c for c in all_cards if all_cards.count(c) > 1]))
            raise ValueError(f"Duplicate cards found in input: {duplicates}")

        # Ensure total_players matches or accommodates opponent_hands and opponent_ranges
        min_players_needed = max(len(self.opponent_hands), len(self.opponent_ranges)) + 1
        if self.total_players < min_players_needed:
            raise ValueError(
                f"total_players ({self.total_players}) cannot be less than "
                f"the number of specified opponents + 1 ({min_players_needed})"
            )
        return self

class PlayerResult(BaseModel):
    player_index: int
    hand: List[str]
    win_rate: float
    tie_rate: float
    lose_rate: float
    hand_type_distribution: Dict[str, float]

class SimulationResponse(BaseModel):
    simulations_run: int
    elapsed_time_ms: float
    player_results: List[PlayerResult]
