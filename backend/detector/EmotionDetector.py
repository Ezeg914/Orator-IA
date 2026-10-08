import cv2
import numpy as np
from keras.models import model_from_json
from io import BytesIO
import base64

emotion_dict = {0: "Angry", 1: "Disgusted", 2: "Fearful", 3: "Happy", 4: "Neutral", 5: "Sad", 6: "Surprised"}

json_file = open('detector/models/modelv3.json', 'r')
loaded_model_json = json_file.read()
json_file.close()
model = model_from_json(loaded_model_json)

model.load_weights("detector/models/model.h5v3")
print("Loaded model from disk")

def analyze_video(data):
    temp_filename = "/tmp/temp_video.mp4"
    with open(temp_filename, 'wb') as f:
        f.write(data)
    
    cap = cv2.VideoCapture(temp_filename)
    if not cap.isOpened():
        raise ValueError(f"Error opening video stream or file: {temp_filename}")

    frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = int(cap.get(cv2.CAP_PROP_FPS))

    out = cv2.VideoWriter('output.avi', cv2.VideoWriter_fourcc('X', 'V', 'I', 'D'), fps, (frame_width, frame_height))

    emotions_list = []

    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        face_detector = cv2.CascadeClassifier('detector/models/haarcascade_frontalface_default.xml')
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        num_faces = face_detector.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=9)
        for (x, y, w, h) in num_faces:
            cv2.rectangle(frame, (x, y - 50), (x + w, y + h + 10), (255, 0, 0), 2)
            roi_gray = gray[y:y + h, x:x + w]
            cropped_img = np.expand_dims(np.expand_dims(cv2.resize(roi_gray, (48, 48)), -1), 0)

           
            emotion_prediction = model.predict(cropped_img)
            maxindex = int(np.argmax(emotion_prediction))
            emotion = emotion_dict[maxindex]

            emotions_list.append(emotion) 
            cv2.putText(frame, emotion, (x + 20, y - 60), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2, cv2.LINE_AA)

        out.write(frame)

    cap.release()
    out.release()
    cv2.destroyAllWindows()

    with open('output.avi', 'rb') as f:
        video_data = f.read()
        video_data_base64 = base64.b64encode(video_data).decode('utf-8')

    return video_data_base64, emotions_list
