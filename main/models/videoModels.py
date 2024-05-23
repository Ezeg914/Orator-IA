from sqlmodel import SQLModel, Field, Relationship

class Video(SQLModel, table=True):
    __tablename__ = 'videos'
    video_id: int = Field(default=None, primary_key=True)
    title: str = Field(nullable=False)
    emotions: str = Field(nullable=True)
    #user: 'User' = Relationship(back_populates="videos")
