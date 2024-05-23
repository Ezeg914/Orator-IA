from fastapi import HTTPException
from main.models.userModels import User
from main.repositories.userRepository import UserRepository
from sqlmodel import Session

class UserController:
    
    @staticmethod
    def create_user(user: User, session: Session):
        return UserRepository.create_user(user, session)
    
    @staticmethod
    def read_users(session: Session):
        return UserRepository.read_users(session)

    @staticmethod
    def read_user(user_id: str, session: Session):
        user = UserRepository.read_user(user_id, session)
        if user:
            return user
        raise HTTPException(status_code=404, detail="User not found")
    
    @staticmethod
    def update_user(user_id: str, user: User, session: Session):
        updated_user = UserRepository.update_user(user_id, user, session)
        if updated_user:
            return updated_user
        raise HTTPException(status_code=404, detail="User not found")
    
    @staticmethod
    def delete_user(user_id: str, session: Session):
        if UserRepository.delete_user(user_id, session):
            return {"message": "User deleted successfully"}
        raise HTTPException(status_code=404, detail="User not found")
    

   
