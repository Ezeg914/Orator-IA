from typing import TYPE_CHECKING, List, Optional
from pydantic import EmailStr
from sqlmodel import SQLModel, Field, Relationship

if TYPE_CHECKING:
    from main.models.videoModels import Video

class User(SQLModel, table=True):
    __tablename__ = 'users'
    user_id: int = Field(default=None, primary_key=True)
    username: str = Field(nullable=False)
    hashed_password: str = Field(nullable=False)
    email: str = Field(nullable=False, unique=True)

    # Un usuario tiene muchos videos; al borrar el usuario se borran sus videos
    videos: List["Video"] = Relationship(
        back_populates="user",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )


# Esquemas de entrada/salida (nunca exponen hashed_password)
class UserCreate(SQLModel):
    username: str = Field(min_length=1, max_length=50)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)

class UserLogin(SQLModel):
    email: str
    password: str

class UserUpdate(SQLModel):
    username: Optional[str] = Field(default=None, min_length=1, max_length=50)
    email: Optional[EmailStr] = None

class UserRead(SQLModel):
    user_id: int
    username: str
    email: str

class AuthResponse(SQLModel):
    access_token: str
    token_type: str = "bearer"
    user: UserRead
