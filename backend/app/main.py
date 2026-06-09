from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import Base, engine
from app.models.history import HistoryRecord  # Import to register with Base.metadata

# Initialize Database tables
Base.metadata.create_all(bind=engine)

# Import routes
from app.api.v1.simulator import router as simulator_router
from app.api.v1.history import router as history_router
from app.api.v1.ranges import router as ranges_router
from app.api.v1.evaluate import router as evaluate_router
from app.api.v1.explain import router as explain_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Set up CORS for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(simulator_router, prefix=f"{settings.API_V1_STR}/simulator", tags=["simulator"])
app.include_router(history_router, prefix=f"{settings.API_V1_STR}/history", tags=["history"])
app.include_router(ranges_router, prefix=f"{settings.API_V1_STR}/ranges", tags=["ranges"])
app.include_router(evaluate_router, prefix=f"{settings.API_V1_STR}/evaluate", tags=["evaluate"])
app.include_router(explain_router, prefix=f"{settings.API_V1_STR}/explain", tags=["explain"])

@app.get("/")
def read_root():
    return {"message": "Welcome to Poker Odds Simulator API"}

