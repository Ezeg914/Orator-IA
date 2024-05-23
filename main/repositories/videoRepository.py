
from main.models.videoModels import Video
from sqlmodel import Session, select

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
    def read_video(video_id: str, session: Session):
        video = session.get(Video, video_id)
        return video

    @staticmethod
    def update_video(video_id: str, video: Video, session: Session):
        video_db = session.get(Video, video_id)
        if video_db:
            video_db.title = video.title
            video_db.description = video.description
            session.add(video_db)
            session.commit()
            session.refresh(video_db)
            return video_db
        return None

    @staticmethod
    def delete_video(video_id: str, session: Session):
        video = session.get(Video, video_id)
        if video:
            session.delete(video)
            session.commit()
            return True
        return False