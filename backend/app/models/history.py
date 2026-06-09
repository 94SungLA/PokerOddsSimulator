import datetime
from sqlalchemy import Column, Integer, Float, DateTime, JSON
from app.core.database import Base

class HistoryRecord(Base):
    __tablename__ = "history_records"

    id = Column(Integer, primary_key=True, index=True)
    hero_hand = Column(JSON, nullable=False)
    opponent_ranges = Column(JSON, nullable=False) # list of hands or range strings
    community_cards = Column(JSON, nullable=False)
    win_rate = Column(Float, nullable=False)
    tie_rate = Column(Float, nullable=False)
    lose_rate = Column(Float, nullable=False)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
