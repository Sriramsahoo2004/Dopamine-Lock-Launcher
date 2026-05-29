from datetime import datetime, timezone
from typing import List, Optional

from fastapi import FastAPI
from pydantic import BaseModel, Field


app = FastAPI(title="DopamineLock Sync API", version="0.1.0")


class Question(BaseModel):
    id: int
    question_text: str = Field(min_length=1)
    correct_answer: str = Field(min_length=1)
    options: List[str] = Field(min_length=2)
    category: str = Field(min_length=1)


class QuestionsResponse(BaseModel):
    questions: List[Question]
    last_sync: datetime


class AppStat(BaseModel):
    package_name: str = Field(min_length=1)
    app_opened: str = Field(min_length=1)
    unlock_time: datetime
    unlock_count: int = Field(ge=0)
    questions_answered: int = Field(ge=0)
    questions_failed: int = Field(ge=0)


class SyncStatsRequest(BaseModel):
    user_id: str = Field(min_length=1)
    stats: List[AppStat]
    failed_questions: List[int] = []


class SyncStatsResponse(BaseModel):
    status: str
    accepted_stats: int


MOCK_QUESTIONS = [
    Question(
        id=1,
        question_text="What is the average time complexity of QuickSort?",
        correct_answer="O(n log n)",
        options=["O(n^2)", "O(n log n)", "O(n)", "O(log n)"],
        category="Algorithms",
    ),
    Question(
        id=2,
        question_text="Which data structure is commonly used with a hash map in an LRU cache?",
        correct_answer="Doubly linked list",
        options=["Stack", "Queue", "Doubly linked list", "Binary search tree"],
        category="Data Structures",
    ),
    Question(
        id=3,
        question_text="In a binary heap, where is the minimum element in a min-heap?",
        correct_answer="Root",
        options=["Root", "Last leaf", "Leftmost leaf", "Any internal node"],
        category="Data Structures",
    ),
]


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/sync/questions", response_model=QuestionsResponse)
async def get_questions(last_sync: Optional[datetime] = None) -> QuestionsResponse:
    # TODO: Replace this with PostgreSQL/Supabase filtering by last_sync.
    return QuestionsResponse(
        questions=MOCK_QUESTIONS,
        last_sync=datetime.now(timezone.utc),
    )


@app.post("/sync/stats", response_model=SyncStatsResponse)
async def sync_stats(request: SyncStatsRequest) -> SyncStatsResponse:
    # TODO: Persist request.stats and request.failed_questions to PostgreSQL.
    print(
        f"Received {len(request.stats)} stats rows for user {request.user_id}; "
        f"failed questions={request.failed_questions}"
    )
    return SyncStatsResponse(status="success", accepted_stats=len(request.stats))
