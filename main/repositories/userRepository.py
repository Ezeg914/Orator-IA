from main.models.userModels import User
from sqlmodel import Session, select

class UserRepository:
    @staticmethod
    def create_user(user: User, session: Session):
        session.add(user)
        session.commit()
        session.refresh(user)
        return user

    @staticmethod
    def read_users(session: Session):
        users = session.exec(select(User)).all()
        return users

    @staticmethod
    def read_user(user_id: str, session: Session):
        user = session.get(User, user_id)
        return user

    @staticmethod
    def update_user(user_id: str, user: User, session: Session):
        user_db = session.get(User, user_id)
        if user_db:
            user_db.name = user.name
            user_db.email = user.email
            session.add(user_db)
            session.commit()
            session.refresh(user_db)
            return user_db
        return None

    @staticmethod
    def delete_user(user_id: str, session: Session):
        user = session.get(User, user_id)
        if user:
            session.delete(user)
            session.commit()
            return True
        return False
