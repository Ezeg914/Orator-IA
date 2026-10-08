from fastapi import APIRouter, Depends, File, UploadFile, HTTPException
from main.models.videoModels import Video
from main.models.userModels import User
from main.controllers.videoController import VideoController
from main.security import get_current_user
from detector.EmotionDetector import analyze_video
from db.database import get_session
from sqlmodel import Session
import json

router = APIRouter()

# Devuelve el video solo si pertenece al usuario; si no, 404 (no revela que existe)
def get_own_video(video_id: int, current_user: User, session: Session) -> Video:
    video = VideoController.read_video(video_id, session)
    if video.user_id != current_user.user_id:
        raise HTTPException(status_code=404, detail="Video not found")
    return video

@router.post("/videos/")
async def create_video(title: str, file: UploadFile = File(...), current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    print(f"Received title: {title}")
    user_id = current_user.user_id
    # Procesar el video directamente desde el archivo recibido
    video_data = await file.read()  # Leer el archivo en memoria

    # Procesar el video y obtener el diccionario de emociones y el video procesado en base64
    video_data_base64, emotion_counts = analyze_video(video_data)

    # Convertir el diccionario de emociones a JSON
    emotions_json = json.dumps(emotion_counts)

    # Crear el objeto Video, asociado al usuario autenticado
    video = Video(title=title, emotion_json=emotions_json, video_data=video_data_base64, user_id=user_id)

    # Guardar el video en la base de datos
    video = VideoController.create_video(video, session)

    return {"id": video.video_id, "title": video.title, "emotion_json": video.emotion_json}


# Solo los videos del usuario autenticado. No incluye video_data (pesa varios MB por video):
# el video se pide aparte con GET /videos/{video_id} al reproducirlo
@router.get("/videos/")
async def read_videos(current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    videos = VideoController.read_videos_by_user(current_user.user_id, session)
    return [{"id": video.video_id, "title": video.title, "emotion_json": video.emotion_json} for video in videos]

@router.get("/videos/{video_id}")
async def read_video(video_id: int, current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    video = get_own_video(video_id, current_user, session)
    return {"id": video.video_id, "title": video.title, "emotion_json": video.emotion_json, "video_data": video.video_data}

@router.put("/videos/{video_id}")
async def update_video(video_id: int, title: str, current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    video = get_own_video(video_id, current_user, session)

    video.title = title
    video = VideoController.update_video(video_id, video, session)

    return {"id": video.video_id, "title": video.title, "emotion_json": video.emotion_json}

@router.delete("/videos/{video_id}")
async def delete_video(video_id: int, current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    get_own_video(video_id, current_user, session)

    success = VideoController.delete_video(video_id, session)
    if not success:
        raise HTTPException(status_code=400, detail="Failed to delete video")

    return {"message": "Video deleted successfully"}
