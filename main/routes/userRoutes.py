from fastapi import APIRouter, Depends
from main.models.userModels import User
from main.controllers.userController import UserController
from db.database import get_session
from sqlmodel import Session

router = APIRouter()

# Operaciones CRUD de usuario
@router.post("/users/", response_model=User)
def create_user(user: User,session: Session = Depends(get_session)):
    return UserController.create_user(user,session)

@router.get("/users/", response_model=list[User])
def read_users(session: Session = Depends(get_session)):
    return UserController.read_users(session)

@router.get("/users/{user_id}", response_model=User)
def read_user(user_id: str, session: Session = Depends(get_session)):
    return UserController.read_user(user_id, session)

@router.put("/users/{user_id}", response_model=User)
def update_user(user_id: str, user: User, session: Session = Depends(get_session)):
    return UserController.update_user(user_id, user, session)

@router.delete("/users/{user_id}", response_model=dict)
def delete_user(user_id: str, session: Session = Depends(get_session)):
    return UserController.delete_user(user_id, session)
