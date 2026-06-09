import pytest
from app.services.evaluator import Card, evaluate_hand

def parse_cards(card_strs):
    return [Card.from_str(c) for c in card_strs]

def test_royal_flush():
    cards = parse_cards(["As", "Ks", "Qs", "Js", "Ts", "2c", "3d"])
    rank_class, hand_name, tie_breakers = evaluate_hand(cards)
    assert rank_class == 9
    assert hand_name == "Royal Flush"
    assert tie_breakers == (14,)

def test_straight_flush():
    cards = parse_cards(["Ks", "Qs", "Js", "Ts", "9s", "2c", "3d"])
    rank_class, hand_name, tie_breakers = evaluate_hand(cards)
    assert rank_class == 8
    assert hand_name == "Straight Flush"
    assert tie_breakers == (13,)

def test_ace_low_straight_flush():
    cards = parse_cards(["5h", "4h", "3h", "2h", "Ah", "Kd", "Qc"])
    rank_class, hand_name, tie_breakers = evaluate_hand(cards)
    assert rank_class == 8
    assert hand_name == "Straight Flush"
    assert tie_breakers == (5,)

def test_four_of_a_kind():
    cards = parse_cards(["As", "Ah", "Ad", "Ac", "Ks", "Qc", "2d"])
    rank_class, hand_name, tie_breakers = evaluate_hand(cards)
    assert rank_class == 7
    assert hand_name == "Four of a Kind"
    assert tie_breakers == (14, 13)

def test_full_house():
    cards = parse_cards(["As", "Ah", "Ad", "Ks", "Kh", "Qc", "2d"])
    rank_class, hand_name, tie_breakers = evaluate_hand(cards)
    assert rank_class == 6
    assert hand_name == "Full House"
    assert tie_breakers == (14, 13)

def test_flush():
    cards = parse_cards(["As", "Qs", "Ts", "8s", "6s", "2c", "3d"])
    rank_class, hand_name, tie_breakers = evaluate_hand(cards)
    assert rank_class == 5
    assert hand_name == "Flush"
    assert tie_breakers == (14, 12, 10, 8, 6)

def test_straight():
    cards = parse_cards(["As", "Kd", "Qh", "Jc", "Ts", "2c", "3d"])
    rank_class, hand_name, tie_breakers = evaluate_hand(cards)
    assert rank_class == 4
    assert hand_name == "Straight"
    assert tie_breakers == (14,)

def test_ace_low_straight():
    cards = parse_cards(["As", "2d", "3h", "4c", "5s", "Tc", "Qd"])
    rank_class, hand_name, tie_breakers = evaluate_hand(cards)
    assert rank_class == 4
    assert hand_name == "Straight"
    assert tie_breakers == (5,)

def test_three_of_a_kind():
    cards = parse_cards(["As", "Ah", "Ad", "9c", "8d", "2c", "3h"])
    rank_class, hand_name, tie_breakers = evaluate_hand(cards)
    assert rank_class == 3
    assert hand_name == "Three of a Kind"
    assert tie_breakers == (14, 9, 8)

def test_two_pair():
    # Aces and Kings, with Queen kicker (take the 2 highest pairs out of 3)
    cards = parse_cards(["As", "Ah", "Ks", "Kh", "Qs", "Qh", "2d"])
    rank_class, hand_name, tie_breakers = evaluate_hand(cards)
    assert rank_class == 2
    assert hand_name == "Two Pair"
    assert tie_breakers == (14, 13, 12)

def test_one_pair():
    cards = parse_cards(["As", "Ah", "Ks", "Qd", "Jc", "2s", "3c"])
    rank_class, hand_name, tie_breakers = evaluate_hand(cards)
    assert rank_class == 1
    assert hand_name == "One Pair"
    assert tie_breakers == (14, 13, 12, 11)

def test_high_card():
    cards = parse_cards(["As", "Kd", "Qc", "9d", "8h", "2c", "3s"])
    rank_class, hand_name, tie_breakers = evaluate_hand(cards)
    assert rank_class == 0
    assert hand_name == "High Card"
    assert tie_breakers == (14, 13, 12, 9, 8)


def test_analyze_hand_improvements():
    from app.services.evaluator import analyze_hand_improvements
    cards = parse_cards(["As", "Kd", "Qs", "Js", "2c"])
    res = analyze_hand_improvements(cards)
    assert res["hand_type"] == "High Card"
    assert res["rank_class"] == 0
    straight_imp = next(imp for imp in res["potential_improvements"] if imp["improvement"] == "Straight")
    assert straight_imp["outs"] == 4  # Ts, Th, Td, Tc

