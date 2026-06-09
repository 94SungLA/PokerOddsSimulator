import random
import time
from app.services.evaluator import Card, evaluate_hand
from app.services.range_parser import range_parser_service

class TexasHoldemSimulator:
    def __init__(self):
        # Pre-create all 52 card objects
        self.deck = []
        ranks = '23456789TJQKA'
        suits = 'shdc'
        self.card_cache = {}
        for r in ranks:
            for s in suits:
                card_str = r + s
                card = Card.from_str(card_str)
                self.deck.append(card)
                self.card_cache[card_str] = card

    def get_card(self, card_str: str) -> Card:
        if card_str not in self.card_cache:
            self.card_cache[card_str] = Card.from_str(card_str)
        return self.card_cache[card_str]

    def simulate(
        self,
        player_hand_strs: list[str],
        opponent_hands_strs: list[list[str]],
        opponent_ranges_strs: list[str] = None,
        community_cards_strs: list[str] = None,
        total_players: int = 2,
        simulations: int = 10000
    ) -> dict:
        start_time = time.perf_counter()

        if community_cards_strs is None:
            community_cards_strs = []
        if opponent_ranges_strs is None:
            opponent_ranges_strs = []

        # Parse inputs
        player_hand = [self.get_card(c) for c in player_hand_strs]
        
        # Normalize/pad opponent hands and ranges
        opponent_hands = []
        for opp in opponent_hands_strs:
            opponent_hands.append([self.get_card(c) for c in opp])
        while len(opponent_hands) < total_players - 1:
            opponent_hands.append([])

        while len(opponent_ranges_strs) < total_players - 1:
            opponent_ranges_strs.append("")

        community_cards = [self.get_card(c) for c in community_cards_strs]

        # Gather all known cards
        known_cards = set(player_hand)
        for opp in opponent_hands:
            known_cards.update(opp)
        known_cards.update(community_cards)

        # Parse and pre-filter opponent ranges (remove combos containing known cards)
        opponent_ranges = []
        for range_str in opponent_ranges_strs:
            if range_str and range_str.strip() != "":
                parsed_combos = range_parser_service.parse_range(range_str)
                # Keep only combos where neither card is permanently known/dead
                filtered = [
                    combo for combo in parsed_combos
                    if combo[0] not in known_cards and combo[1] not in known_cards
                ]
                opponent_ranges.append(filtered)
            else:
                opponent_ranges.append([])

        # Remaining deck
        remaining_deck = [c for c in self.deck if c not in known_cards]

        # Simulation stats setup
        # Player 0 is the main player, Players 1 to total_players - 1 are opponents
        stats = []
        for i in range(total_players):
            stats.append({
                "wins": 0,
                "ties": 0,
                "losses": 0,
                "hand_type_counts": {
                    "High Card": 0,
                    "One Pair": 0,
                    "Two Pair": 0,
                    "Three of a Kind": 0,
                    "Straight": 0,
                    "Flush": 0,
                    "Full House": 0,
                    "Four of a Kind": 0,
                    "Straight Flush": 0,
                    "Royal Flush": 0
                }
            })

        num_missing_community = 5 - len(community_cards)

        # Run simulations
        eval_hand = evaluate_hand
        rand_sample = random.sample
        rand_choice = random.choice

        for _ in range(simulations):
            current_deck = list(remaining_deck)
            iteration_dead = set()
            opp_hands_run = [None] * len(opponent_hands)

            # 1. Resolve opponents with hand ranges
            for idx, opp in enumerate(opponent_hands):
                if len(opp) > 0:
                    opp_hands_run[idx] = opp
                elif len(opponent_ranges[idx]) > 0:
                    # Filter combos against dynamically dealt cards in this iteration
                    if not iteration_dead:
                        valid_combos = opponent_ranges[idx]
                    else:
                        valid_combos = [
                            combo for combo in opponent_ranges[idx]
                            if combo[0] not in iteration_dead and combo[1] not in iteration_dead
                        ]

                    if valid_combos:
                        chosen = rand_choice(valid_combos)
                    else:
                        # Fallback to random if range is fully blocked
                        c1, c2 = rand_sample(current_deck, 2)
                        chosen = (c1, c2)

                    opp_hands_run[idx] = list(chosen)
                    current_deck.remove(chosen[0])
                    current_deck.remove(chosen[1])
                    iteration_dead.add(chosen[0])
                    iteration_dead.add(chosen[1])

            # 2. Resolve community board
            if num_missing_community > 0:
                comm_drawn = rand_sample(current_deck, num_missing_community)
                board = community_cards + comm_drawn
                for c in comm_drawn:
                    current_deck.remove(c)
            else:
                board = community_cards

            # 3. Resolve opponents with completely random hands
            for idx, opp in enumerate(opponent_hands):
                if opp_hands_run[idx] is None:
                    opp_drawn = rand_sample(current_deck, 2)
                    opp_hands_run[idx] = opp_drawn
                    for c in opp_drawn:
                        current_deck.remove(c)

            # Evaluate hands
            scores = [] # list of (rank_class, tie_breakers, player_idx, hand_name)
            
            # Player 0 (main player)
            p0_eval = eval_hand(player_hand + board)
            scores.append((p0_eval[0], p0_eval[2], 0, p0_eval[1]))
            
            # Opponents
            for idx, opp_hand in enumerate(opp_hands_run):
                player_idx = idx + 1
                opp_eval = eval_hand(opp_hand + board)
                scores.append((opp_eval[0], opp_eval[2], player_idx, opp_eval[1]))

            # Determine winner(s)
            scores.sort(key=lambda x: (x[0], x[1]), reverse=True)
            
            best_rank = scores[0][0]
            best_ties = scores[0][1]
            
            winners = []
            for score in scores:
                if score[0] == best_rank and score[1] == best_ties:
                    winners.append(score[2])
                else:
                    break
            
            # Update stats
            is_tie = len(winners) > 1
            winner_set = set(winners)
            
            for score in scores:
                p_idx = score[2]
                hand_name = score[3]
                
                # Record hand type
                stats[p_idx]["hand_type_counts"][hand_name] += 1
                
                if p_idx in winner_set:
                    if is_tie:
                        stats[p_idx]["ties"] += 1
                    else:
                        stats[p_idx]["wins"] += 1
                else:
                    stats[p_idx]["losses"] += 1

        elapsed_time_ms = (time.perf_counter() - start_time) * 1000.0

        # Construct response
        player_results = []
        
        # Player 0 results
        p0_stats = stats[0]
        player_results.append({
            "player_index": 0,
            "hand": player_hand_strs,
            "win_rate": round(p0_stats["wins"] / simulations, 4),
            "tie_rate": round(p0_stats["ties"] / simulations, 4),
            "lose_rate": round(p0_stats["losses"] / simulations, 4),
            "hand_type_distribution": {
                k: round(v / simulations, 4) for k, v in p0_stats["hand_type_counts"].items()
            }
        })
        
        # Opponent results
        for idx, opp in enumerate(opponent_hands):
            player_idx = idx + 1
            opp_stats = stats[player_idx]
            
            # If the opponent had a range set, return the range label in place of concrete card strings
            has_range = opponent_ranges_strs[idx] != ""
            hand_label = [opponent_ranges_strs[idx]] if has_range else [str(c) for c in opp] if opp else []
            if not has_range and opp:
                hand_label = opponent_hands_strs[idx]

            player_results.append({
                "player_index": player_idx,
                "hand": hand_label,
                "win_rate": round(opp_stats["wins"] / simulations, 4),
                "tie_rate": round(opp_stats["ties"] / simulations, 4),
                "lose_rate": round(opp_stats["losses"] / simulations, 4),
                "hand_type_distribution": {
                    k: round(v / simulations, 4) for k, v in opp_stats["hand_type_counts"].items()
                }
            })

        return {
            "simulations_run": simulations,
            "elapsed_time_ms": round(elapsed_time_ms, 2),
            "player_results": player_results
        }

simulator_service = TexasHoldemSimulator()
