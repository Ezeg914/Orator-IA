from fastapi import HTTPException
from main.models.userModels import User, UserCreate, UserLogin, UserUpdate
from main.repositories.userRepository import UserRepository
from main.security import hash_password, verify_password, create_access_token
from sqlmodel import Session

class UserController:

    @staticmethod
    def _auth_response(user: User):
        return {"access_token": create_access_token(user.user_id), "token_type": "bearer", "user": user}

    @staticmethod
    def register(data: UserCreate, session: Session):
        email = data.email.strip().lower()
        if UserRepository.read_user_by_email(email, session):
            raise HTTPException(status_code=409, detail="Email already registered")
        user = User(username=data.username.strip(), email=email, hashed_password=hash_password(data.password))
        user = UserRepository.create_user(user, session)
        return UserController._auth_response(user)

    @staticmethod
    def login(data: UserLogin, session: Session):
        user = UserRepository.read_user_by_email(data.email.strip().lower(), session)
        if not user or not verify_password(data.password, user.hashed_password):
            raise HTTPException(status_code=401, detail="Invalid email or password")
        return UserController._auth_response(user)

    @staticmethod
    def update_user(user_id: int, data: UserUpdate, session: Session):
        if data.email is not None:
            data.email = data.email.strip().lower()
            existing = UserRepository.read_user_by_email(data.email, session)
            if existing and existing.user_id != user_id:
                raise HTTPException(status_code=409, detail="Email already registered")
        updated_user = UserRepository.update_user(user_id, data, session)
        if updated_user:
            return updated_user
        raise HTTPException(status_code=404, detail="User not found")

    @staticmethod
    def delete_user(user_id: int, session: Session):
        if UserRepository.delete_user(user_id, session):
            return {"message": "User deleted successfully"}
        raise HTTPException(status_code=404, detail="User not found")
