from flask import request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from models import db, User
from app import app
import bcrypt
from elevenlabs import ElevenLabs
import os
import time
import glob

@app.route('/signup', methods=['POST'])
def signup():
    data = request.json
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    age = data.get('age')
    status = data.get('status', 'active')
    isAdmin = data.get('isAdmin', False)

    if not all([username, email, password, age]):
        return jsonify({'error': 'Missing required fields'}), 400

    if User.query.filter_by(username=username).first() or User.query.filter_by(email=email).first():
        return jsonify({'error': 'Username or email already exists'}), 400

    password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    new_user = User(
        username=username,
        email=email,
        password=password_hash,
        status=status,
        age=age,
        isAdmin=isAdmin
    )
    db.session.add(new_user)
    db.session.commit()

    return jsonify({'message': 'User created successfully'}), 201

@app.route('/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')

    user = User.query.filter_by(username=username).first()
    if not user or not bcrypt.checkpw(password.encode('utf-8'), user.password.encode('utf-8')):
        return jsonify({'error': 'Invalid username or password'}), 401

    access_token = create_access_token(identity=str(user.id))  # String identity
    return jsonify({
        'message': 'Login successful',
        'access_token': access_token,
        'user': {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'status': user.status,
            'age': user.age,
            'isAdmin': user.isAdmin
        }
    }), 200


@app.route('/protected', methods=['GET'])
@jwt_required()
def protected():
    user_id = get_jwt_identity()  # Returns string
    user = User.query.get(int(user_id))  # Convert to int
    if not user:
        return jsonify({'error': 'User not found'}), 404
    return jsonify({
        'message': 'Protected endpoint',
        'user': {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'status': user.status,
            'age': user.age,
            'isAdmin': user.isAdmin
        }
    }), 200




@app.route('/tts', methods=['POST'])
def text_to_speech():
    data = request.json
    text = data.get('text')
    voice_id = data.get('voice_id', '21m00Tcm4TlvDq8ikWAM')
    stability = data.get('stability', 0.5)
    similarity = data.get('similarity', 0.75)
    speed = data.get('speed', 1.0)
    model_id = data.get('model_id', 'eleven_multilingual_v2')

    if not text:
        return jsonify({'error': 'Text is required'}), 400

    client = ElevenLabs(api_key=os.getenv('ELEVENLABS_API_KEY'))
    try:
        # Ensure static directory exists
        static_dir = os.path.join(os.path.dirname(__file__), 'static')
        os.makedirs(static_dir, exist_ok=True)

        # Clean up old files (older than 1 hour)
        now = time.time()
        for old_file in glob.glob(os.path.join(static_dir, 'output_*.mp3')):
            if os.path.getmtime(old_file) < now - 3600:  # 1 hour
                os.remove(old_file)

        # Generate unique filename
        timestamp = int(time.time() * 1000)
        output_filename = f'output_{timestamp}.mp3'
        output_path = os.path.join(static_dir, output_filename)

        # Generate audio (returns a generator)
        audio_generator = client.text_to_speech.convert(
            text=text,
            voice_id=voice_id,
            model_id=model_id,
            voice_settings={
                'stability': stability,
                'similarity_boost': similarity,
                'style': 0.0,
                'speed': speed
            },
            output_format='mp3_44100_128'
        )

        # Write audio chunks to file
        with open(output_path, 'wb') as f:
            for chunk in audio_generator:
                if chunk:  # Ensure chunk is not empty
                    f.write(chunk)

        return jsonify({'message': 'Audio generated', 'file': f'/static/{output_filename}'}), 200
    except Exception as e:
        return jsonify({'error': f'Failed to generate audio: {str(e)}'}), 500