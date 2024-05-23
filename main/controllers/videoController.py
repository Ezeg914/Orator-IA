from fastapi import HTTPException
from main.models.videoModels import Video
from main.repositories.videoRepository import VideoRepository
from sqlmodel import Session

class VideoController:

    @staticmethod
    def create_video(video: Video, session: Session):
        return VideoRepository.create_video(video, session)
    
    @staticmethod
    def read_videos(session: Session):
        return VideoRepository.read_videos(session)
    
    @staticmethod
    def read_video(video_id: str, session: Session):
        video = VideoRepository.read_video(video_id, session)
        if video:
            return video
        raise HTTPException(status_code=404, detail="Video not found")
    
    @staticmethod
    def update_video(video_id: str, video: Video, session: Session):
        updated_video = VideoRepository.update_video(video_id, video, session)
        if updated_video:
            return updated_video
        raise HTTPException(status_code=404, detail="Video not found")
    
    @staticmethod
    def delete_video(video_id: str, session: Session):
        if VideoRepository.delete_video(video_id, session):
            return {"message": "Video deleted successfully"}
        raise HTTPException(status_code=404, detail="Video not found")
    