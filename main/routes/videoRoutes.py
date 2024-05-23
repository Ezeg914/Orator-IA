from fastapi import APIRouter, Depends
from main.models.videoModels import Video
from main.controllers.videoController import VideoController
from db.database import get_session
from sqlmodel import Session

router = APIRouter()

# Operaciones CRUD de video
@router.post("/videos/", response_model=Video)
def create_video(video: Video, session: Session = Depends(get_session)):
    return VideoController.create_video(video,session)

@router.get("/videos/", response_model=list[Video])
def read_videos(session: Session = Depends(get_session)):
    return VideoController.read_videos(session)

@router.get("/videos/{video_id}", response_model=Video)
def read_video(video_id: str, session: Session = Depends(get_session)):
    return VideoController.read_video(video_id, session)

@router.put("/videos/{video_id}", response_model=Video)
def update_video(video_id: str, video: Video, session: Session = Depends(get_session)):
    return VideoController.update_video(video_id, video, session)

@router.delete("/videos/{video_id}", response_model=dict)
def delete_video(video_id: str, session: Session = Depends(get_session)):
    return VideoController.delete_video(video_id, session)
