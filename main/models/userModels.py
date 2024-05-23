
from sqlmodel import SQLModel, Field, Relationship

class User(SQLModel, table=True):
    __tablename__ = 'users'
    user_id: int = Field(default=None, primary_key=True)
    username: str = Field(nullable=False)
    hashed_password: str = Field(nullable=False)
    email: str = Field(nullable=False, unique=True)

    #videos: list["Video"] = Relationship(back_populates="user")
