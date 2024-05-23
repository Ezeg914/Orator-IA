from sqlmodel import create_engine, Session, SQLModel
import os
from dotenv import load_dotenv

load_dotenv()
# URL de conexión a la base de datos MySQL

# Crear el motor de SQLAlchemy

DATABASE_URL = os.getenv("DATABASE_URL")

db = create_engine(DATABASE_URL, echo=True)


def init_db():
    SQLModel.metadata.create_all(db)


def get_session():
    with Session(db) as session:
        yield session
