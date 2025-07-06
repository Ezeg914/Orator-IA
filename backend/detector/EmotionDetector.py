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


# import cv2
# import numpy as np
# from keras.models import model_from_json
# import subprocess

# emotion_dict = {0: "Angry", 1: "Disgusted", 2: "Fearful", 3: "Happy", 4: "Neutral", 5: "Sad", 6: "Surprised"}

# # Load the model from the files
# json_file = open('detector/models/modelv3.json', 'r')
# loaded_model_json = json_file.read()
# json_file.close()
# model = model_from_json(loaded_model_json)

# # Load the weights
# model.load_weights("detector/models/model.h5v3")
# print("Loaded model from disk")

# def analyze_video(input_path: str, output_path: str) -> (str, dict):
#     cap = cv2.VideoCapture(input_path)

#     # Get the frame width and height from the video capture
#     frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
#     frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
#     fps = int(cap.get(cv2.CAP_PROP_FPS))

#     # Define the codec and create VideoWriter object
#     out_avi = cv2.VideoWriter('output.avi', cv2.VideoWriter_fourcc('X', 'V', 'I', 'D'), fps, (frame_width, frame_height))

#     emotion_counts = {emotion: 0 for emotion in emotion_dict.values()}

#     while True:
#         ret, frame = cap.read()
#         if not ret:
#             break
        
#         face_detector = cv2.CascadeClassifier('detector/models/haarcascade_frontalface_default.xml')    
#         gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

#         num_faces = face_detector.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=9)
#         for (x, y, w, h) in num_faces:
#             cv2.rectangle(frame, (x, y - 50), (x + w, y + h + 10), (255, 0, 0), 2)
#             roi_gray = gray[y:y + h, x:x + w]
#             cropped_img = np.expand_dims(np.expand_dims(cv2.resize(roi_gray, (48, 48)), -1), 0)

#             # Hacer una predicción
#             emotion_prediction = model.predict(cropped_img)
#             maxindex = int(np.argmax(emotion_prediction))
#             emotion = emotion_dict[maxindex]

#             emotion_counts[emotion] += 1
#             cv2.putText(frame, emotion, (x + 20, y - 60), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2, cv2.LINE_AA)

#         # Write the frame with the detection and predictions to the output video
#         out_avi.write(frame)

#     cap.release()
#     out_avi.release()
#     cv2.destroyAllWindows()

#     # Convertir el archivo .avi a .mp4 usando FFmpeg si es necesario
#     subprocess.run(['ffmpeg', '-i', 'output.avi', '-vcodec', 'libx264', output_path])

#     return output_path, emotion_counts



# import cv2
# import numpy as np
# from keras.models import model_from_json
# import json
# import subprocess

# emotion_dict = {0: "Angry", 1: "Disgusted", 2: "Fearful", 3: "Happy", 4: "Neutral", 5: "Sad", 6: "Surprised"}

# # Load the model from the files
# json_file = open('detector/models/modelv3.json', 'r')
# loaded_model_json = json_file.read()
# json_file.close()
# model = model_from_json(loaded_model_json)

# # Load the weights
# model.load_weights("detector/models/model.h5v3")
# print("Loaded model from disk")

# def analyze_video(input_path: str, output_path: str) -> str:
#     cap = cv2.VideoCapture(input_path)

#     # Get the frame width and height from the video capture
#     frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
#     frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
#     fps = int(cap.get(cv2.CAP_PROP_FPS))

#     # Define the codec and create VideoWriter object
#     out_avi = cv2.VideoWriter('output.avi', cv2.VideoWriter_fourcc('X', 'V', 'I', 'D'), fps, (frame_width, frame_height))

#     while True:
#         ret, frame = cap.read()
#         if not ret:
#             break
        
#         face_detector = cv2.CascadeClassifier('detector/models/haarcascade_frontalface_default.xml')    
#         gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

#         num_faces = face_detector.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=9)
#         for (x, y, w, h) in num_faces:
#             cv2.rectangle(frame, (x, y - 50), (x + w, y + h + 10), (255, 0, 0), 2)
#             roi_gray = gray[y:y + h, x:x + w]
#             cropped_img = np.expand_dims(np.expand_dims(cv2.resize(roi_gray, (48, 48)), -1), 0)

#             # Hacer una predicción
#             emotion_prediction = model.predict(cropped_img)
#             maxindex = int(np.argmax(emotion_prediction))
#             emotion = emotion_dict[maxindex]

#             cv2.putText(frame, emotion, (x + 20, y - 60), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2, cv2.LINE_AA)

#         # Write the frame with the detection and predictions to the output video
#         out_avi.write(frame)

#     cap.release()
#     out_avi.release()
#     cv2.destroyAllWindows()

#     # Convertir el archivo .avi a .mp4 usando FFmpeg si es necesario
#     subprocess.run(['ffmpeg', '-i', 'output.avi', '-vcodec', 'libx264', output_path])

#     return output_path


# import cv2
# import numpy as np
# from keras.models import model_from_json
# import json

# emotion_dict = {0: "Angry", 1: "Disgusted", 2: "Fearful", 3: "Happy", 4: "Neutral", 5: "Sad", 6: "Surprised"}

# # Load the model from the files
# json_file = open('detector/models/modelv3.json', 'r')
# loaded_model_json = json_file.read()
# json_file.close()
# model = model_from_json(loaded_model_json)

# # Load the weights
# model.load_weights("detector/models/model.h5v3")
# print("Loaded model from disk")

# cap = cv2.VideoCapture("/home/ezequiel/model ia/test/test9.mp4")

# # Get the frame width and height from the video capture
# frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
# frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
# fps = int(cap.get(cv2.CAP_PROP_FPS))

# # Define the codec and create VideoWriter object
# out_avi = cv2.VideoWriter('output.avi', cv2.VideoWriter_fourcc('X', 'V', 'I', 'D'), fps, (frame_width, frame_height))

# # Resultados frame por frame
# frame_results = []

# while True:
#     ret, frame = cap.read()
#     if not ret:
#         break
    
#     face_detector = cv2.CascadeClassifier('detector/models/haarcascade_frontalface_default.xml')    
#     gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

#     num_faces = face_detector.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=9)
#     frame_result = {"emotions": []}
#     for (x, y, w, h) in num_faces:
#         cv2.rectangle(frame, (x, y - 50), (x + w, y + h + 10), (255, 0, 0), 2)
#         roi_gray = gray[y:y + h, x:x + w]
#         cropped_img = np.expand_dims(np.expand_dims(cv2.resize(roi_gray, (48, 48)), -1), 0)

#         # Hacer una predicción
#         emotion_prediction = model.predict(cropped_img)
#         maxindex = int(np.argmax(emotion_prediction))
#         emotion = emotion_dict[maxindex]
#         frame_result["emotions"].append(emotion)

#         cv2.putText(frame, emotion, (x + 20, y - 60), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2, cv2.LINE_AA)

#     frame_results.append(frame_result)

#     # Write the frame with the detection and predictions to the output video
#     out_avi.write(frame)

#     cv2.imshow('emotion', frame)
#     if cv2.waitKey(1) & 0xFF == ord('q'):
#         break

# cap.release()
# out_avi.release()
# cv2.destroyAllWindows()

# # Guardar los resultados frame por frame en un archivo JSON
# with open("emotion_results_frame_by_frame.json", "w") as outfile:
#     json.dump(frame_results, outfile)

# # Convertir el archivo .avi a .mp4 usando FFmpeg si es necesario
# import subprocess
# subprocess.run(['ffmpeg', '-i', 'output.avi', '-vcodec', 'libx264', 'output.mp4'])
