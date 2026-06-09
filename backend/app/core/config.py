import os
from pydantic import BaseModel

class Settings(BaseModel):
    PROJECT_NAME: str = "Poker Odds Simulator API"
    API_V1_STR: str = "/api/v1"

settings = Settings()
