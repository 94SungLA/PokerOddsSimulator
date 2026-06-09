import re
from typing import List, Tuple, Set
from app.services.evaluator import Card

# Pre-defined equity order from strongest to weakest starting hand categories
EQUITY_ORDER_169 = [
    # Top 5%
    "AA", "KK", "QQ", "JJ", "AKs", "TT", "AQs", "AJs", "AKo", "ATs",
    # Top 10%
    "AQo", "99", "KQs", "AJo", "KJs", "88", "ATo", "QJs", "KTs", "QTs",
    # Top 15%
    "JTs", "KQo", "77", "A9s", "KJo", "A8s", "A7s", "A5s", "A6s", "A4s",
    # Top 20%
    "QJo", "KTo", "A3s", "A2s", "66", "QTo", "K9s", "JTo", "T9s", "A9o",
    # Top 30%
    "55", "Q9s", "K8s", "K7s", "K6s", "K5s", "K4s", "K3s", "K2s", "A8o",
    # Top 40%
    "J9s", "T8s", "98s", "A7o", "A5o", "A6o", "A4o", "A3o", "A2o", "44",
    # Rest
    "Q8s", "K9o", "Q9o", "J8s", "T9o", "J9o", "Q7s", "T7s", "97s", "87s",
    "Q6s", "Q5s", "Q4s", "Q3s", "Q2s", "K8o", "K7o", "K6o", "K5o", "K4o",
    "K3o", "K2o", "33", "J7s", "T8o", "J8o", "98o", "96s", "86s", "76s",
    "22", "J6s", "J5s", "J4s", "J3s", "J2s", "T6s", "95s", "85s", "75s",
    "65s", "T7o", "97o", "87o", "Q8o", "Q7o", "Q6o", "Q5o", "Q4o", "Q3o",
    "Q2o", "J7o", "J6o", "J5o", "J4o", "J3o", "J2o", "T6o", "T5o", "T4o",
    "T3o", "T2o", "T5s", "T4s", "T3s", "T2s", "94s", "84s", "74s", "64s",
    "54s", "96o", "86o", "76o", "65o", "93s", "92s", "83s", "73s", "63s",
    "53s", "43s", "95o", "85o", "75o", "64o", "54o", "82s", "72s", "62s",
    "52s", "42s", "32s", "94o", "93o", "92o", "84o", "83o", "82o", "74o",
    "73o", "72o", "63o", "62o", "53o", "52o", "43o", "42o", "32o"
]

RANKS = '23456789TJQKA'
RANK_VALUES = {RANKS[i]: i + 2 for i in range(len(RANKS))}
SUITS = ['s', 'h', 'd', 'c']

class RangeParser:
    def __init__(self):
        # Pre-build all 52 card objects to avoid allocations
        self.card_cache = {}
        for r in RANKS:
            for s in SUITS:
                self.card_cache[r + s] = Card(RANK_VALUES[r], s)
                
        # Generate complete 169 hands and sort them
        self.sorted_169 = self._build_sorted_169()

    def _build_sorted_169(self) -> List[str]:
        hands = []
        for i in range(13):
            r1 = RANKS[i]
            for j in range(i, 13):
                r2 = RANKS[j]
                if r1 == r2:
                    hands.append(r1 + r2)
                else:
                    # In 169 notation, higher rank goes first
                    hands.append(r2 + r1 + "s")
                    hands.append(r2 + r1 + "o")
        
        # Sort based on EQUITY_ORDER_169
        equity_map = {hand: idx for idx, hand in enumerate(EQUITY_ORDER_169)}
        hands.sort(key=lambda x: equity_map.get(x, 1000))
        return hands

    def parse_range(self, range_str: str) -> List[Tuple[Card, Card]]:
        """
        Parses a range string and returns a list of 2-card combinations.
        Examples: 'JJ+', 'AQs+', 'AKo', 'top_15%', 'JJ+, AQs+'
        """
        if not range_str or range_str.strip() == '':
            return []

        combos: Set[Tuple[Card, Card]] = set()
        tokens = [t.strip() for t in range_str.split(',')]

        for token in tokens:
            if not token:
                continue
                
            # 1. Percentage match (e.g. top_15% or top 15% or 15%)
            pct_match = re.match(r'^(?:top_)?(\d+)%?$', token, re.IGNORECASE)
            if pct_match:
                pct = int(pct_match.group(1))
                combos.update(self._expand_percentage(pct))
                continue

            # 2. Pocket pair range (e.g. TT+)
            pp_range_match = re.match(r'^([2-9TJQKA])\1\+$', token)
            if pp_range_match:
                rank = pp_range_match.group(1)
                combos.update(self._expand_pocket_pair_range(rank))
                continue

            # 3. Pocket pair single (e.g. QQ)
            pp_single_match = re.match(r'^([2-9TJQKA])\1$', token)
            if pp_single_match:
                rank = pp_single_match.group(1)
                combos.update(self._expand_pocket_pair(rank))
                continue

            # 4. Suited range (e.g. AQs+)
            suited_range_match = re.match(r'^([2-9TJQKA])([2-9TJQKA])s\+$', token)
            if suited_range_match:
                r1, r2 = suited_range_match.group(1), suited_range_match.group(2)
                if RANK_VALUES[r1] > RANK_VALUES[r2]:
                    combos.update(self._expand_suited_range(r1, r2))
                continue

            # 5. Offsuit range (e.g. AQo+)
            offsuit_range_match = re.match(r'^([2-9TJQKA])([2-9TJQKA])o\+$', token)
            if offsuit_range_match:
                r1, r2 = offsuit_range_match.group(1), offsuit_range_match.group(2)
                if RANK_VALUES[r1] > RANK_VALUES[r2]:
                    combos.update(self._expand_offsuit_range(r1, r2))
                continue

            # 6. Suited single (e.g. AQs)
            suited_single_match = re.match(r'^([2-9TJQKA])([2-9TJQKA])s$', token)
            if suited_single_match:
                r1, r2 = suited_single_match.group(1), suited_single_match.group(2)
                combos.update(self._expand_suited_single(r1, r2))
                continue

            # 7. Offsuit single (e.g. AQo)
            offsuit_single_match = re.match(r'^([2-9TJQKA])([2-9TJQKA])o$', token)
            if offsuit_single_match:
                r1, r2 = offsuit_single_match.group(1), offsuit_single_match.group(2)
                combos.update(self._expand_offsuit_single(r1, r2))
                continue

            # 8. Both suited/offsuited (e.g. AQ)
            both_match = re.match(r'^([2-9TJQKA])([2-9TJQKA])$', token)
            if both_match:
                r1, r2 = both_match.group(1), both_match.group(2)
                if r1 == r2:
                    combos.update(self._expand_pocket_pair(r1))
                else:
                    combos.update(self._expand_suited_single(r1, r2))
                    combos.update(self._expand_offsuit_single(r1, r2))
                continue

            # 9. Specific card pair (e.g. AhKs or AsKd)
            specific_match = re.match(r'^([2-9TJQKA][shdc])([2-9TJQKA][shdc])$', token)
            if specific_match:
                c1_str, c2_str = specific_match.group(1), specific_match.group(2)
                if c1_str != c2_str:
                    c1 = self.card_cache[c1_str]
                    c2 = self.card_cache[c2_str]
                    # Canonical order: sort combo
                    combos.add(self._make_canonical(c1, c2))
                continue

        return list(combos)

    def _make_canonical(self, c1: Card, c2: Card) -> Tuple[Card, Card]:
        # Keep card with higher rank first; if same rank, sort by suit
        if c1.rank > c2.rank:
            return (c1, c2)
        elif c2.rank > c1.rank:
            return (c2, c1)
        else:
            return (c1, c2) if c1.suit > c2.suit else (c2, c1)

    def _expand_percentage(self, pct: int) -> Set[Tuple[Card, Card]]:
        combos = set()
        pct = max(0, min(100, pct))
        num_categories = round((pct / 100.0) * len(self.sorted_169))
        selected_categories = self.sorted_169[:num_categories]
        
        for category in selected_categories:
            combos.update(self._expand_category(category))
        return combos

    def _expand_category(self, category: str) -> Set[Tuple[Card, Card]]:
        if len(category) == 2:
            return self._expand_pocket_pair(category[0])
        elif category.endswith('s'):
            return self._expand_suited_single(category[0], category[1])
        elif category.endswith('o'):
            return self._expand_offsuit_single(category[0], category[1])
        return set()

    def _expand_pocket_pair(self, rank: str) -> Set[Tuple[Card, Card]]:
        combos = set()
        for i in range(len(SUITS)):
            for j in range(i + 1, len(SUITS)):
                c1 = self.card_cache[rank + SUITS[i]]
                c2 = self.card_cache[rank + SUITS[j]]
                combos.add((c1, c2))
        return combos

    def _expand_pocket_pair_range(self, rank: str) -> Set[Tuple[Card, Card]]:
        combos = set()
        start_val = RANK_VALUES[rank]
        for r in RANKS:
            if RANK_VALUES[r] >= start_val:
                combos.update(self._expand_pocket_pair(r))
        return combos

    def _expand_suited_single(self, r1: str, r2: str) -> Set[Tuple[Card, Card]]:
        combos = set()
        for s in SUITS:
            c1 = self.card_cache[r1 + s]
            c2 = self.card_cache[r2 + s]
            combos.add(self._make_canonical(c1, c2))
        return combos

    def _expand_suited_range(self, r1: str, r2: str) -> Set[Tuple[Card, Card]]:
        combos = set()
        r1_val = RANK_VALUES[r1]
        r2_val = RANK_VALUES[r2]
        
        # Keep r1 constant, and raise r2 up to r1 - 1
        for r in RANKS:
            r_val = RANK_VALUES[r]
            if r2_val <= r_val < r1_val:
                combos.update(self._expand_suited_single(r1, r))
        return combos

    def _expand_offsuit_single(self, r1: str, r2: str) -> Set[Tuple[Card, Card]]:
        combos = set()
        for s1 in SUITS:
            for s2 in SUITS:
                if s1 != s2:
                    c1 = self.card_cache[r1 + s1]
                    c2 = self.card_cache[r2 + s2]
                    combos.add(self._make_canonical(c1, c2))
        return combos

    def _expand_offsuit_range(self, r1: str, r2: str) -> Set[Tuple[Card, Card]]:
        combos = set()
        r1_val = RANK_VALUES[r1]
        r2_val = RANK_VALUES[r2]
        
        for r in RANKS:
            r_val = RANK_VALUES[r]
            if r2_val <= r_val < r1_val:
                combos.update(self._expand_offsuit_single(r1, r))
        return combos

range_parser_service = RangeParser()
