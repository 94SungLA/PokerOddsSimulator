class Card:
    __slots__ = ('rank', 'suit')

    def __init__(self, rank: int, suit: str):
        self.rank = rank
        self.suit = suit

    @classmethod
    def from_str(cls, card_str: str) -> 'Card':
        if len(card_str) != 2:
            raise ValueError(f"Invalid card string: {card_str}")
        r_char, s_char = card_str[0], card_str[1]
        rank_map = {
            '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
            'T': 10, 'J': 11, 'Q': 12, 'K': 13, 'A': 14
        }
        if r_char not in rank_map:
            raise ValueError(f"Invalid rank: {r_char}")
        if s_char not in ('s', 'h', 'd', 'c'):
            raise ValueError(f"Invalid suit: {s_char}")
        return cls(rank_map[r_char], s_char)

    def __repr__(self):
        inv_rank = {
            2: '2', 3: '3', 4: '4', 5: '5', 6: '6', 7: '7', 8: '8', 9: '9',
            10: 'T', 11: 'J', 12: 'Q', 13: 'K', 14: 'A'
        }
        return f"{inv_rank[self.rank]}{self.suit}"

    def __eq__(self, other):
        if not isinstance(other, Card):
            return False
        return self.rank == other.rank and self.suit == other.suit

    def __hash__(self):
        return hash((self.rank, self.suit))


def evaluate_hand(cards: list[Card]) -> tuple[int, str, tuple[int, ...]]:
    """
    Evaluates a 5 to 7 card hand and returns:
    (rank_class, hand_name, tie_breakers)
    
    Rank classes:
      9: Royal Flush
      8: Straight Flush
      7: Four of a Kind
      6: Full House
      5: Flush
      4: Straight
      3: Three of a Kind
      2: Two Pair
      1: One Pair
      0: High Card
    """
    # 1. Check Flush
    suits = {}
    for card in cards:
        suits.setdefault(card.suit, []).append(card)

    flush_suit = None
    for suit, suit_cards in suits.items():
        if len(suit_cards) >= 5:
            flush_suit = suit
            break

    if flush_suit:
        flush_cards = suits[flush_suit]
        sorted_flush_ranks = sorted(list({c.rank for c in flush_cards}), reverse=True)
        
        # Check for straight flush
        straight_flush_high = None
        for i in range(len(sorted_flush_ranks) - 4):
            high = sorted_flush_ranks[i]
            if (high - 1 in sorted_flush_ranks and
                high - 2 in sorted_flush_ranks and
                high - 3 in sorted_flush_ranks and
                high - 4 in sorted_flush_ranks):
                straight_flush_high = high
                break
        
        # Ace-low straight flush (A, 2, 3, 4, 5)
        if not straight_flush_high and 14 in sorted_flush_ranks:
            if {5, 4, 3, 2}.issubset(sorted_flush_ranks):
                straight_flush_high = 5

        if straight_flush_high:
            if straight_flush_high == 14:
                return (9, "Royal Flush", (14,))
            return (8, "Straight Flush", (straight_flush_high,))
        
        # Normal Flush: 5 highest cards
        return (5, "Flush", tuple(sorted_flush_ranks[:5]))

    # 2. Check groups and straights
    rank_counts = {}
    for card in cards:
        rank_counts[card.rank] = rank_counts.get(card.rank, 0) + 1

    # Sort ranks by count descending, then by rank descending
    sorted_rank_groups = sorted(rank_counts.items(), key=lambda x: (x[1], x[0]), reverse=True)

    # Pre-calculate straight check
    unique_ranks = sorted(list(rank_counts.keys()), reverse=True)
    straight_high = None
    for i in range(len(unique_ranks) - 4):
        high = unique_ranks[i]
        if (high - 1 in unique_ranks and
            high - 2 in unique_ranks and
            high - 3 in unique_ranks and
            high - 4 in unique_ranks):
            straight_high = high
            break
    if not straight_high and 14 in unique_ranks:
        if {5, 4, 3, 2}.issubset(unique_ranks):
            straight_high = 5

    # Check Four of a Kind
    if sorted_rank_groups[0][1] == 4:
        four_rank = sorted_rank_groups[0][0]
        # Find kicker (highest rank that is not four_rank)
        kickers = [r for r, _ in sorted_rank_groups if r != four_rank]
        return (7, "Four of a Kind", (four_rank, kickers[0]))

    # Check Full House
    if sorted_rank_groups[0][1] == 3 and len(sorted_rank_groups) > 1 and sorted_rank_groups[1][1] >= 2:
        three_rank = sorted_rank_groups[0][0]
        pair_rank = sorted_rank_groups[1][0]
        return (6, "Full House", (three_rank, pair_rank))

    # Check Straight
    if straight_high:
        return (4, "Straight", (straight_high,))

    # Check Three of a Kind
    if sorted_rank_groups[0][1] == 3:
        three_rank = sorted_rank_groups[0][0]
        kickers = [r for r, _ in sorted_rank_groups if r != three_rank]
        return (3, "Three of a Kind", (three_rank, kickers[0], kickers[1]))

    # Check Two Pair
    if sorted_rank_groups[0][1] == 2 and len(sorted_rank_groups) > 1 and sorted_rank_groups[1][1] == 2:
        pair1_rank = sorted_rank_groups[0][0]
        pair2_rank = sorted_rank_groups[1][0]
        # Kicker is the highest rank among all other cards
        kickers = [r for r, _ in sorted_rank_groups if r != pair1_rank and r != pair2_rank]
        return (2, "Two Pair", (pair1_rank, pair2_rank, kickers[0]))

    # Check One Pair
    if sorted_rank_groups[0][1] == 2:
        pair_rank = sorted_rank_groups[0][0]
        kickers = [r for r, _ in sorted_rank_groups if r != pair_rank]
        return (1, "One Pair", (pair_rank, kickers[0], kickers[1], kickers[2]))

    return (0, "High Card", tuple(unique_ranks[:5]))


def analyze_hand_improvements(cards: list[Card]) -> dict:
    current_rank, current_name, current_ties = evaluate_hand(cards)
    
    # Generate all 52 cards
    ranks = '23456789TJQKA'
    suits = 'shdc'
    rank_map = {
        '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
        'T': 10, 'J': 11, 'Q': 12, 'K': 13, 'A': 14
    }
    deck = []
    for r in ranks:
        for s in suits:
            deck.append(Card(rank_map[r], s))
            
    # Remove cards already in hand/community
    used = set(cards)
    remaining_deck = [c for c in deck if c not in used]
    
    improvements = {}
    if len(cards) < 7:
        for next_card in remaining_deck:
            new_rank, new_name, _ = evaluate_hand(cards + [next_card])
            if new_rank > current_rank:
                improvements.setdefault(new_name, []).append(next_card)
                
    # Build results list
    improvements_list = []
    total_remaining = len(remaining_deck)
    for imp_name, outs_cards in improvements.items():
        outs_count = len(outs_cards)
        prob = round(outs_count / total_remaining, 4)
        improvements_list.append({
            "improvement": imp_name,
            "outs": outs_count,
            "outs_cards": [str(c) for c in outs_cards],
            "probability": prob
        })
        
    # Sort improvements by outs descending
    improvements_list.sort(key=lambda x: x["outs"], reverse=True)
    
    # Summary statement
    summaries = {
        9: "超強牌型！皇家同花順，立於不敗之地。",
        8: "非常強大的牌型！同花順，幾乎穩贏。",
        7: "極強牌型！鐵支（四條），極高勝率。",
        6: "非常強大的牌型！葫蘆，通常是獲勝大熱門。",
        5: "強大牌型！同花，注意對手是否有更大同花或葫蘆。",
        4: "不錯的牌型！順子，注意公牌是否有同花或葫蘆可能。",
        3: "中等強度牌型！三條，隱蔽性高且極具威脅。",
        2: "中等強度牌型！兩對，注意牌局發展。",
        1: "弱牌！一對，需要小心對手更大的對子或發展牌型。",
        0: "極弱！目前僅是高牌，需要等待公牌改善。"
    }
    summary = summaries.get(current_rank, "未知牌型")
    
    return {
        "hand_type": current_name,
        "rank_class": current_rank,
        "potential_improvements": improvements_list,
        "hand_strength_summary": summary
    }

