from typing import List
from sqlmodel import Session, select
from main.models.videoModels import Video
import base64
import json

class VideoRepository:
    @staticmethod
    def create_video(video: Video, session: Session):
        session.add(video)
        session.commit()
        session.refresh(video)
        return video

    @staticmethod
    def read_videos(session: Session):
        videos = session.exec(select(Video)).all()
        return videos

    @staticmethod
    def read_video(video_id: int, session: Session):
        video = session.get(Video, video_id)
        return video

    @staticmethod
    def update_video(video_id: int, video: Video, session: Session):
        video_db = session.get(Video, video_id)
        if video_db:
            video_db.title = video.title
            video_db.emotion_json = json.dumps(video.emotion_json)  # Convertir el diccionario a JSON
            video_db.video_data = base64.b64encode(video.video_data)
            session.add(video_db)
            session.commit()
            session.refresh(video_db)
            return video_db
        return None

    @staticmethod
    def delete_video(video_id: int, session: Session):
        video = session.get(Video, video_id)
        if video:
            session.delete(video)
            session.commit()
            return True
        return False
