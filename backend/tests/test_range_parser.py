import pytest
from app.services.range_parser import range_parser_service

def test_specific_pocket_pair():
    # AA should yield exactly 6 combinations
    combos = range_parser_service.parse_range("AA")
    assert len(combos) == 6
    # Check that they are all Ace combinations
    for c1, c2 in combos:
        assert c1.rank == 14
        assert c2.rank == 14
        assert c1.suit != c2.suit

def test_specific_suited_combo():
    # AKs should yield exactly 4 suited combinations
    combos = range_parser_service.parse_range("AKs")
    assert len(combos) == 4
    for c1, c2 in combos:
        assert c1.rank == 14
        assert c2.rank == 13
        assert c1.suit == c2.suit

def test_specific_offsuited_combo():
    # AKo should yield exactly 12 offsuit combinations
    combos = range_parser_service.parse_range("AKo")
    assert len(combos) == 12
    for c1, c2 in combos:
        assert c1.rank == 14
        assert c2.rank == 13
        assert c1.suit != c2.suit

def test_pocket_pair_range():
    # KK+ should yield KK and AA (6 + 6 = 12 combos)
    combos = range_parser_service.parse_range("KK+")
    assert len(combos) == 12
    ranks = {c1.rank for c1, _ in combos}
    assert ranks == {13, 14}

def test_suited_range():
    # AQs+ should yield AQs and AKs (4 + 4 = 8 combos)
    combos = range_parser_service.parse_range("AQs+")
    assert len(combos) == 8
    second_ranks = {min(c1.rank, c2.rank) for c1, c2 in combos}
    assert second_ranks == {12, 13}

def test_percentage_range():
    # top_10% should expand to top 10% of 169 categories
    combos = range_parser_service.parse_range("top_10%")
    assert len(combos) > 0
    # top_0% should yield 0
    assert len(range_parser_service.parse_range("top_0%")) == 0

def test_comma_separated_token():
    # JJ+, AQs+ -> (12 + 12 + 6 = 30 combos for JJ+) + (8 combos for AQs+) = 38 combos
    # Wait: JJ+ includes JJ, QQ, KK, AA (6 * 4 = 24 combos)
    # AQs+ includes AQs, AKs (4 * 2 = 8 combos)
    # Total = 24 + 8 = 32 combos
    combos = range_parser_service.parse_range("JJ+, AQs+")
    assert len(combos) == 32

def test_specific_combo():
    combos = range_parser_service.parse_range("AhKd")
    assert len(combos) == 1
    c1, c2 = combos[0]
    assert (c1.rank == 14 and c1.suit == 'h' and c2.rank == 13 and c2.suit == 'd') or \
           (c2.rank == 14 and c2.suit == 'h' and c1.rank == 13 and c1.suit == 'd')
