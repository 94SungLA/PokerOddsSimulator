from pydantic import BaseModel

class RangePresetResponse(BaseModel):
    name: str
    range_str: str
    description: str
