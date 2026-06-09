from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.models.history import HistoryRecord
from app.schemas.history import HistoryRecordCreate, HistoryRecordResponse

router = APIRouter()

@router.get("", response_model=List[HistoryRecordResponse])
def get_history(db: Session = Depends(get_db)):
    return db.query(HistoryRecord).order_by(HistoryRecord.timestamp.desc()).all()

@router.post("", response_model=HistoryRecordResponse, status_code=status.HTTP_201_CREATED)
def create_history_record(record: HistoryRecordCreate, db: Session = Depends(get_db)):
    db_record = HistoryRecord(
        hero_hand=record.hero_hand,
        opponent_ranges=record.opponent_ranges,
        community_cards=record.community_cards,
        win_rate=record.win_rate,
        tie_rate=record.tie_rate,
        lose_rate=record.lose_rate
    )
    db.add(db_record)
    db.commit()
    db.refresh(db_record)
    return db_record

@router.delete("/{record_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_history_record(record_id: int, db: Session = Depends(get_db)):
    db_record = db.query(HistoryRecord).filter(HistoryRecord.id == record_id).first()
    if not db_record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"History record with ID {record_id} not found"
        )
    db.delete(db_record)
    db.commit()
    return
