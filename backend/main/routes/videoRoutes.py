from fastapi import APIRouter, Depends, File, UploadFile, HTTPException
from main.models.videoModels import Video
from main.controllers.videoController import VideoController
from detector.EmotionDetector import analyze_video
from db.database import get_session
from sqlmodel import Session
import json

router = APIRouter()

@router.post("/videos/")
async def create_video(title: str, file: UploadFile = File(...), session: Session = Depends(get_session)):
    print(f"Received title: {title}")
    # Procesar el video directamente desde el archivo recibido
    video_data = await file.read()  # Leer el archivo en memoria

    # Procesar el video y obtener el diccionario de emociones y el video procesado en base64
    video_data_base64, emotion_counts = analyze_video(video_data)

    # Convertir el diccionario de emociones a JSON
    emotions_json = json.dumps(emotion_counts)

    # Crear el objeto Video
    video = Video(title=title, emotion_json=emotions_json, video_data=video_data_base64)

    # Guardar el video en la base de datos
    video = VideoController.create_video(video, session)

    return {"id": video.video_id, "title": video.title, "emotion_json": video.emotion_json}


@router.get("/videos/")
async def read_videos(session: Session = Depends(get_session)):
    videos = VideoController.read_videos(session)
    return [{"id": video.video_id, "title": video.title, "emotion_json": video.emotion_json, "video_data": video.video_data } for video in videos]

@router.get("/videos/{video_id}")
async def read_video(video_id: int, session: Session = Depends(get_session)):
    video = VideoController.read_video(video_id, session)
    if not video:
        raise HTTPException(status_code=404, detail="Video not found")
    return {"id": video.video_id, "title": video.title, "emotion_json": video.emotion_json, "video_data": video.video_data}

@router.put("/videos/{video_id}")
async def update_video(video_id: int, title: str, session: Session = Depends(get_session)):
    video = VideoController.read_video(video_id, session)
    if not video:
        raise HTTPException(status_code=404, detail="Video not found")

    video.title = title
    video = VideoController.update_video(video_id, video, session)

    return {"id": video.video_id, "title": video.title, "emotion_json": video.emotion_json}

@router.delete("/videos/{video_id}")
async def delete_video(video_id: int, session: Session = Depends(get_session)):
    video = VideoController.read_video(video_id, session)
    if not video:
        raise HTTPException(status_code=404, detail="Video not found")

    success = VideoController.delete_video(video_id, session)
    if not success:
        raise HTTPException(status_code=400, detail="Failed to delete video")

    return {"message": "Video deleted successfully"}
