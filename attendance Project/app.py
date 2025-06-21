from flask import Flask, request
from flask_socketio import SocketIO
import base64
from PIL import Image
from io import BytesIO
import numpy as np
import face_recognition
import cv2
from datetime import datetime
import os
import requests
import firebase_admin
from firebase_admin import credentials, firestore
import atexit

# Firebase Initialization
cred = credentials.Certificate('firebase_credentials.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

COLLECTION_NAME = "students"
ATTENDANCE_DIR = "attendance_logs"
TOLERANCE = 0.5
already_marked = set()

# Setup for attendance logging
timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')
attendance_file = os.path.join(ATTENDANCE_DIR, f"Attendance_{timestamp_str}.csv")

os.makedirs(ATTENDANCE_DIR, exist_ok=True)
if not os.path.exists(attendance_file):
    with open(attendance_file, 'w') as f:
        f.write("Name,Regd No.,Branch,Time\n")

# Initialize Flask app and SocketIO
app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")

# Firebase attendance document
session_id = datetime.now().strftime('attendance_%Y%m%d_%H%M%S')
attendance_doc_ref = db.collection('attendance').document(session_id)
attendance_data = {}
student_counter = 0
client_connected = False
recognized_students_count = 0

# Load known faces
print("🔄 Fetching face data from Firebase...")
students_ref = db.collection(COLLECTION_NAME)
docs = students_ref.stream()

known_face_encodings = []
known_face_names = []
known_face_regnos = []
known_face_branches = []


for doc in docs:
    data = doc.to_dict()
    branch = data.get('branch')
    name = data.get('name')
    reg_no = data.get('reg_no')
    photo_url = data.get('photo_url')
    


    try:
        response = requests.get(photo_url)
        img = Image.open(BytesIO(response.content)).convert('RGB')
        img_np = np.array(img)
        encodings = face_recognition.face_encodings(img_np)
        if encodings:
            known_face_encodings.append(encodings[0])
            known_face_branches.append(branch)
            known_face_names.append(name)
            known_face_regnos.append(reg_no)
            
            print(f"✅ Loaded: {name} ({reg_no})")
        else:
            print(f"❌ Face not found in image: {name}")
    except Exception as e:
        print(f"⚠ Error loading {name}: {e}")

print("✅ Face data loading complete.\n")

# Attendance marking
def mark_attendance(name, reg_no,branch):
    global student_counter, recognized_students_count
    if reg_no in already_marked:
        return

    now = datetime.now()
    timestamp = now.strftime('%I:%M %p')
    with open(attendance_file, 'a') as f:
        f.write(f"{name},{reg_no},{branch},{now.strftime('%Y-%m-%d %H:%M:%S')}\n")

    student_key = f"student_{student_counter}"
    attendance_data[student_key] = {
        'name': name,
        'reg_no': reg_no,
        'branch': branch,
        'time': timestamp
    }

    already_marked.add(reg_no)
    student_counter += 1
    recognized_students_count += 1
    print(f"🟢 Attendance marked for: {name} ({reg_no}) at {timestamp}")

# Upload attendance to Firebase
def upload_attendance_to_firebase():
    if attendance_data:
        try:
            attendance_doc_ref.set(attendance_data)
            print(f"📤 Attendance session uploaded to Firebase as '{session_id}'")
            print(f"👥 Total students recognized: {recognized_students_count}")
        except Exception as e:
            print(f"❌ Error uploading attendance: {e}")

atexit.register(upload_attendance_to_firebase)

@app.route('/upload_attendance', methods=['POST'])
def manual_upload():
    upload_attendance_to_firebase()
    return {"status": "uploaded", "session_id": session_id}, 200

@socketio.on('connect')
def handle_connect():
    global client_connected
    client_connected = True
    print("✅ Mobile client connected")

@socketio.on('disconnect')
def handle_disconnect():
    global client_connected
    client_connected = False
    print("❌ Mobile client disconnected")
    upload_attendance_to_firebase()

@socketio.on('frame')
def handle_frame(data):
    if not client_connected:
        return

    try:
        image_data = data['image'].split(',')[1]
        img_bytes = base64.b64decode(image_data)
        image = Image.open(BytesIO(img_bytes)).convert('RGB')
        frame_np = np.array(image)

        # Convert to proper format
        frame_np = cv2.cvtColor(frame_np, cv2.COLOR_RGB2BGR)
        rgb_frame = cv2.cvtColor(frame_np, cv2.COLOR_BGR2RGB)

        # Detect faces
        face_locations = face_recognition.face_locations(rgb_frame)
        face_encodings = face_recognition.face_encodings(rgb_frame, face_locations)

        for face_encoding in face_encodings:
            matches = face_recognition.compare_faces(known_face_encodings, face_encoding, tolerance=TOLERANCE)
            face_distances = face_recognition.face_distance(known_face_encodings, face_encoding)

            if face_distances.size > 0:
                best_match = np.argmin(face_distances)
                if matches[best_match]:
                    name = known_face_names[best_match]
                    reg_no = known_face_regnos[best_match]
                    branch = known_face_branches[best_match]
                    mark_attendance(name, reg_no, branch)
                    socketio.emit('recognized', {'name': name})

    except Exception as e:
        print(f"⚠ Error handling frame: {e}")

if __name__ == '__main__':
    print("🚀 Socket.IO server running...")
    socketio.run(app, host='0.0.0.0', port=5000)