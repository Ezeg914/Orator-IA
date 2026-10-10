<div align="center">
  <img src="docs/banner.svg" width="420" alt="Orator-IA">
  <p><b>App móvil para practicar oratoria: analiza las emociones del rostro mientras hablás.</b></p>
  <p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
    <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI">
    <img src="https://img.shields.io/badge/TensorFlow-2.12-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white" alt="TensorFlow 2.12">
    <img src="https://img.shields.io/badge/OpenCV-5C3EE8?style=for-the-badge&logo=opencv&logoColor=white" alt="OpenCV">
    <img src="https://img.shields.io/badge/SQLModel-7E56C2?style=for-the-badge" alt="SQLModel">
  </p>
</div>

---

## Sobre el proyecto

Orator-IA ayuda a ensayar una presentación. La persona se graba hablando desde la app, el backend sigue su rostro a lo largo del video y clasifica la emoción que transmite en cada momento. Al terminar, la app muestra qué emociones predominaron en un gráfico de radar y permite volver a ver el video con el rostro y la emoción marcados.

## Cómo funciona

```mermaid
flowchart LR
    A["App Flutter<br/>graba el video"] -- "POST /api/videos/" --> B["API FastAPI"]
    B --> C["YuNet<br/>detecta el rostro"]
    C --> D["Recorte 48 x 48<br/>en escala de grises"]
    D --> E["CNN en Keras<br/>7 emociones"]
    E --> F[("Base de datos")]
    F -- "emociones + video anotado" --> A
```

1. La app graba el video con la cámara y lo sube junto con un título.
2. El backend corrige la orientación de los videos grabados con el celular y recorre los cuadros.
3. En uno de cada dos cuadros, **YuNet** detecta los rostros sobre una versión reducida de la imagen y se queda con el más grande.
4. El rostro se recorta, se pasa a escala de grises de 48 x 48 y entra a una red convolucional que lo clasifica en una de 7 emociones: `Angry`, `Disgusted`, `Fearful`, `Happy`, `Neutral`, `Sad` o `Surprised`.
5. Se guarda la secuencia de emociones y un video nuevo con el recuadro del rostro y la emoción escrita encima.

## Funcionalidades

- **Cuentas de usuario.** Registro e inicio de sesión con JWT. Las contraseñas se guardan con hash PBKDF2-SHA256 y la app conserva la sesión en el almacenamiento seguro del dispositivo.
- **Grabación desde la app** con la cámara del celular.
- **Galería propia.** Cada usuario ve solo sus videos, con la emoción predominante de cada uno y su porcentaje. Se actualiza al deslizar hacia abajo y permite eliminar videos.
- **Detalle del análisis.** Gráfico de radar animado con las 7 emociones y el porcentaje de cada una.
- **Reproductor** del video ya anotado.

## Tecnologías

| Parte | Tecnologías |
| --- | --- |
| App | Flutter, Dart, `camera`, `video_player`, `fl_chart`, `flutter_secure_storage` |
| Backend | Python, FastAPI, SQLModel, Uvicorn, `python-jose`, `passlib` |
| IA | TensorFlow 2.12 y Keras para la clasificación, OpenCV con YuNet para la detección de rostros |

## Estructura

```
backend/
├── app.py              Punto de entrada de la API
├── detector/           Detección de rostros, clasificación de emociones y modelos
├── main/               Rutas, controladores, modelos y repositorios
└── db/                 Conexión a la base de datos
frontend/oratoria/
└── lib/
    ├── screens/        Login, grabación, detalle y reproductor
    └── services/       Autenticación y llamadas a la API
```

## Cómo correrlo

### Backend

Requiere Python 3.8 a 3.11, que son las versiones compatibles con TensorFlow 2.12.

```bash
cd backend
bash install.sh
```

`install.sh` crea el entorno virtual e instala las dependencias. Después hay que crear un archivo `.env` dentro de `backend/`:

```env
DATABASE_URL=sqlite:///db.sqlite3
SECRET_KEY=una_clave_larga_y_aleatoria
```

`DATABASE_URL` también acepta MySQL, por ejemplo `mysql+pymysql://usuario:password@localhost/oratoria`.

```bash
bash boot.sh
```

La API queda en el puerto 5000 y la documentación interactiva en `http://localhost:5000/docs`.

### App

```bash
cd frontend/oratoria
flutter pub get
flutter run
```

La dirección del backend se configura en la constante `apiBaseUrl` de [`frontend/oratoria/lib/services/auth_service.dart`](frontend/oratoria/lib/services/auth_service.dart). Hay que poner la IP de la computadora donde corre la API.

## Endpoints

Todos los endpoints de usuarios y videos requieren el encabezado `Authorization: Bearer <token>`.

| Método | Ruta | Qué hace |
| --- | --- | --- |
| `POST` | `/api/auth/register` | Crea una cuenta y devuelve el token |
| `POST` | `/api/auth/login` | Inicia sesión y devuelve el token |
| `GET` | `/api/users/me` | Devuelve el usuario autenticado |
| `PUT` | `/api/users/me` | Actualiza nombre de usuario o email |
| `DELETE` | `/api/users/me` | Elimina la cuenta y sus videos |
| `POST` | `/api/videos/?title=` | Recibe un video, lo analiza y guarda el resultado |
| `GET` | `/api/videos/` | Lista los videos del usuario con sus emociones |
| `GET` | `/api/videos/{video_id}` | Devuelve un video con el archivo anotado |
| `PUT` | `/api/videos/{video_id}?title=` | Cambia el título |
| `DELETE` | `/api/videos/{video_id}` | Elimina un video |

## Autor

[Ezequiel Garcia](https://github.com/Ezeg914)
