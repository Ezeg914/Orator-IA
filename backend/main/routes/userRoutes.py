from fastapi import APIRouter, Depends
from main.models.userModels import User, UserCreate, UserLogin, UserUpdate, UserRead, AuthResponse
from main.controllers.userController import UserController
from main.security import get_current_user
from db.database import get_session
from sqlmodel import Session

router = APIRouter()

# Registro y login: devuelven el token y los datos del usuario
@router.post("/auth/register", response_model=AuthResponse)
def register(data: UserCreate, session: Session = Depends(get_session)):
    return UserController.register(data, session)

@router.post("/auth/login", response_model=AuthResponse)
def login(data: UserLogin, session: Session = Depends(get_session)):
    return UserController.login(data, session)

# Operaciones sobre el usuario autenticado
@router.get("/users/me", response_model=UserRead)
def read_me(current_user: User = Depends(get_current_user)):
    return current_user

@router.put("/users/me", response_model=UserRead)
def update_me(data: UserUpdate, current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    return UserController.update_user(current_user.user_id, data, session)

@router.delete("/users/me", response_model=dict)
def delete_me(current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    return UserController.delete_user(current_user.user_id, session)
