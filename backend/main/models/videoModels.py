from sqlmodel import SQLModel, Field

class Video(SQLModel, table=True):
    video_id: int = Field(primary_key=True)
    title: str = Field(nullable=False)
    emotion_json: str = Field(nullable=True) 
    video_data: str = Field(nullable=True)

