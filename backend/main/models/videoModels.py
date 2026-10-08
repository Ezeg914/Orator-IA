from typing import TYPE_CHECKING, Optional
from sqlmodel import SQLModel, Field, Relationship

if TYPE_CHECKING:
    from main.models.userModels import User

class Video(SQLModel, table=True):
    video_id: int = Field(primary_key=True)
    title: str = Field(nullable=False)
    emotion_json: str = Field(nullable=True)
    video_data: str = Field(nullable=True)
    user_id: int = Field(foreign_key="users.user_id", index=True, nullable=False)

    user: Optional["User"] = Relationship(back_populates="videos")
