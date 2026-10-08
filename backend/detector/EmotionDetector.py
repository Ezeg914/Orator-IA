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

# Detector de rostros YuNet (red neuronal de OpenCV). El Haar cascade anterior perdía la
# cara en primeros planos y a veces tomaba un ojo como si fuera un rostro
ANCHO_DETECCION = 320
face_detector = cv2.FaceDetectorYN.create(
    'detector/models/face_detection_yunet_2023mar.onnx', "", (ANCHO_DETECCION, ANCHO_DETECCION),
    score_threshold=0.6, nms_threshold=0.3, top_k=50,
)

PASO = 2


# Recorte cuadrado centrado en el rostro, rellenando con el borde si la cara se sale del cuadro
def recortar_rostro(gray, x, y, w, h):
    alto, ancho = gray.shape[:2]
    lado = int(round(max(w, h)))
    x0 = int(round(x + w / 2 - lado / 2))
    y0 = int(round(y + h / 2 - lado / 2))
    x1, y1 = x0 + lado, y0 + lado
    borde = max(0, -x0, -y0, x1 - ancho, y1 - alto)
    if borde:
        gray = cv2.copyMakeBorder(gray, borde, borde, borde, borde, cv2.BORDER_REPLICATE)
    return cv2.resize(gray[y0 + borde:y1 + borde, x0 + borde:x1 + borde], (48, 48), interpolation=cv2.INTER_AREA)


def analyze_video(data):
    temp_filename = os.path.join(tempfile.gettempdir(), "temp_video.mp4")
    with open(temp_filename, 'wb') as f:
        f.write(data)

    cap = cv2.VideoCapture(temp_filename)
    if not cap.isOpened():
        raise ValueError(f"Error opening video stream or file: {temp_filename}")

    # Los celulares graban apaisado y guardan el giro en los metadatos: aplicarlo
    # para que los frames lleguen derechos al detector (y al video de salida)
    cap.set(cv2.CAP_PROP_ORIENTATION_AUTO, 1)

    frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = int(cap.get(cv2.CAP_PROP_FPS))

    out = cv2.VideoWriter('output.avi', cv2.VideoWriter_fourcc('X', 'V', 'I', 'D'), fps, (frame_width, frame_height))

    # La detección corre sobre una copia reducida del frame
    escala = ANCHO_DETECCION / frame_width
    tamano_deteccion = (ANCHO_DETECCION, int(round(frame_height * escala)))
    face_detector.setInputSize(tamano_deteccion)

    # Texto y líneas proporcionales al tamaño del video para que se lean en 1080p
    grosor = max(2, frame_width // 270)
    tamano_texto = max(1.0, frame_width / 360)

    emotions_list = []
    ultimas = []
    indice = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        if indice % PASO == 0:
            chico = cv2.resize(frame, tamano_deteccion, interpolation=cv2.INTER_AREA)
            _, detectados = face_detector.detect(chico)
            ultimas = []
            if detectados is not None and len(detectados) > 0:
                # Solo el rostro más grande: el del orador
                d = max(detectados, key=lambda r: r[2] * r[3])
                x, y, w, h = (float(v) / escala for v in d[:4])
                gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
                cropped_img = np.expand_dims(np.expand_dims(recortar_rostro(gray, x, y, w, h), -1), 0)
                # El modelo espera píxeles en [0, 1]; con 0-255 satura y responde casi siempre "Fearful"
                emotion_prediction = model(cropped_img.astype('float32') / 255.0, training=False).numpy()
                emotion = emotion_dict[int(np.argmax(emotion_prediction))]
                emotions_list.append(emotion)
                ultimas.append((int(x), int(y), int(w), int(h), emotion))
        indice += 1

        for (x, y, w, h, emotion) in ultimas:
            cv2.rectangle(frame, (x, y), (x + w, y + h), (255, 0, 0), grosor)
            cv2.putText(frame, emotion, (max(0, x), max(int(40 * tamano_texto), y - 3 * grosor)), cv2.FONT_HERSHEY_SIMPLEX, tamano_texto, (255, 0, 0), grosor, cv2.LINE_AA)

        out.write(frame)

    cap.release()
    out.release()
    cv2.destroyAllWindows()

    with open('output.avi', 'rb') as f:
        video_data = f.read()
        video_data_base64 = base64.b64encode(video_data).decode('utf-8')

    return video_data_base64, emotions_list
