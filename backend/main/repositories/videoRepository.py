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
    def read_videos_by_user(user_id: int, session: Session):
        # Sin video_data: es pesado y el listado no lo necesita
        videos = session.exec(
            select(Video.video_id, Video.title, Video.emotion_json).where(Video.user_id == user_id)
        ).all()
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
