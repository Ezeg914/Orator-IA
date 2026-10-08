import cv2
import numpy as np
from keras.models import model_from_json
from io import BytesIO
import base64
import os
import tempfile

emotion_dict = {0: "Angry", 1: "Disgusted", 2: "Fearful", 3: "Happy", 4: "Neutral", 5: "Sad", 6: "Surprised"}

json_file = open('detector/models/modelv3.json', 'r')
loaded_model_json = json_file.read()
json_file.close()
model = model_from_json(loaded_model_json)

model.load_weights("detector/models/model.h5v3")
print("Loaded model from disk")

face_detector = cv2.CascadeClassifier('detector/models/haarcascade_frontalface_default.xml')

ESCALA_DETECCION = 0.5
MIN_ROSTRO = (50, 50)

PASO = 2

def analyze_video(data):
    temp_filename = os.path.join(tempfile.gettempdir(), "temp_video.mp4")
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
    ultimas = []
    indice = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        if indice % PASO == 0:
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            chico = cv2.resize(gray, None, fx=ESCALA_DETECCION, fy=ESCALA_DETECCION, interpolation=cv2.INTER_AREA)
            detectados = face_detector.detectMultiScale(chico, scaleFactor=1.1, minNeighbors=9, minSize=MIN_ROSTRO)
            ultimas = []
            for d in detectados:
                x, y, w, h = (int(v / ESCALA_DETECCION) for v in d)
                roi_gray = gray[y:y + h, x:x + w]
                cropped_img = np.expand_dims(np.expand_dims(cv2.resize(roi_gray, (48, 48)), -1), 0)
                emotion_prediction = model(cropped_img.astype('float32'), training=False).numpy()
                emotion = emotion_dict[int(np.argmax(emotion_prediction))]
                emotions_list.append(emotion)
                ultimas.append((x, y, w, h, emotion))
        indice += 1

        for (x, y, w, h, emotion) in ultimas:
            cv2.rectangle(frame, (x, y - 50), (x + w, y + h + 10), (255, 0, 0), 2)
            cv2.putText(frame, emotion, (x + 20, y - 60), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2, cv2.LINE_AA)

        out.write(frame)

    cap.release()
    out.release()
    cv2.destroyAllWindows()

    with open('output.avi', 'rb') as f:
        video_data = f.read()
        video_data_base64 = base64.b64encode(video_data).decode('utf-8')

    return video_data_base64, emotions_list
