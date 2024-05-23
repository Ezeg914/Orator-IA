from fastapi import FastAPI
from db.database import init_db
from main.routes import userRoutes
from main.routes import videoRoutes

app = FastAPI()

@app.on_event("startup")
def on_startup():
    init_db()

# Conectar rutas de usuario
app.include_router(userRoutes.router, tags=["Usuarios"], prefix="/api")
app.include_router(videoRoutes.router, tags=["Videos"], prefix="/api")