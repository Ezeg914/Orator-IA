from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from db.database import init_db
from main.routes import userRoutes, videoRoutes

app = FastAPI()

# Configuración de CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Puedes cambiar a la lista específica de dominios permitidos
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    init_db()

# Conectar rutas de usuario
app.include_router(userRoutes.router, tags=["Usuarios"], prefix="/api")
app.include_router(videoRoutes.router, tags=["Videos"], prefix="/api")