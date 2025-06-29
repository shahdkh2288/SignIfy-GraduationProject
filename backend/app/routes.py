from datetime import datetime
from flask import request, jsonify, current_app, Response
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from .models import db, User, TTSPreferences, STTPreferences
from flask import Blueprint
import bcrypt
from elevenlabs import ElevenLabs
from deepgram import DeepgramClient, PrerecordedOptions
import os
import time

bp = Blueprint('main', __name__)


#-------------------------SIGN UP------------------------------------------------
@bp.route('/signup', methods=['POST'])
def signup():
    data = request.json
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    fullname = data.get('fullname', '')
    dateofbirth = data.get('dateofbirth')  # Expected: YYYY-MM-DD format
    role = data.get('role', "normal user")

    if not all([username, email, password, dateofbirth, fullname]):
        return jsonify({'error': 'Missing required fields: username, email, password, fullname and dateofbirth are required'}), 400

    if User.query.filter_by(username=username).first() or User.query.filter_by(email=email).first():
        return jsonify({'error': 'Username or email already exists'}), 400
    
    # Validate Roles
    valid_roles = ['normal user', 'hearing-impaired', 'speech-impaired']
    if role not in valid_roles:
        return jsonify({'error': f'Invalid role. Valid roles are: {", ".join(valid_roles)}'}), 400

    # Parse dateofbirth
    try:
        dob = datetime.strptime(dateofbirth, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'Invalid dateofbirth format. Use YYYY-MM-DD'}), 400
    
    # Calculate age based on dateofbirth
    today = datetime.now().date()
    age = today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))

    # encrypt password using bcrypt
    password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    # Create new user
    new_user = User(
        username=username,
        email=email,
        password=password_hash,
        status="active",
        age=age,
        isAdmin=False,
        fullname=fullname,
        dateofbirth=dob,
        role=role,
        profile_image='',
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    db.session.add(new_user)
    db.session.flush()  # Get user.id before commit

    tts= TTSPreferences(
        user_id=new_user.id,
        voice_id='21m00Tcm4TlvDq8ikWAM',  # Default voice ID (Rachel)
        stability=0.5,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )

    stt= STTPreferences(
        user_id=new_user.id,
        language='en',  # Default language
        smart_format=True,  # Default smart format
        profanity_filter=False,  # Default profanity filter off
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )

    db.session.add(tts)
    db.session.add(stt)
    db.session.commit()

    return jsonify({'message': 'User created successfully'}), 201


#-------------------------LOGIN------------------------------------------------

@bp.route('/login', methods=['POST'])
def login():
    data = request.json
    email = data.get('email')
    username = data.get('username')
    password = data.get('password')

    if not email:
        user = User.query.filter_by(username=username).first()
        if not user or not bcrypt.checkpw(password.encode('utf-8'), user.password.encode('utf-8')):
            return jsonify({'error': 'Invalid username or password'}), 401
    else:
        user = User.query.filter_by(email=email).first()
        if not user or not bcrypt.checkpw(password.encode('utf-8'), user.password.encode('utf-8')):
            return jsonify({'error': 'Invalid email or password'}), 401
        
    if user.status != "active":
        return jsonify({'error': 'User account is not active'}), 403

    access_token = create_access_token(identity=str(user.id))  # String identity
    return jsonify({
        'message': 'Login successful',
        'access_token': access_token,
        'user': {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'fullname': user.fullname,
            'role': user.role,
            'status': user.status,
            'age': user.age,
            'dateofbirth': user.dateofbirth.strftime('%Y-%m-%d'),
            'profile_image': user.profile_image,
            'isAdmin': user.isAdmin,
            'created_at': user.created_at.isoformat(),
            'updated_at': user.updated_at.isoformat()
        }
    }), 200


#-------------------------PROTECTED -------------------------------------------------
@bp.route('/protected', methods=['GET'])
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
            'fullname': user.fullname,
            'role': user.role,
            'status': user.status,
            'age': user.age,
            'dateofbirth': user.dateofbirth.strftime('%Y-%m-%d'),
            'profile_image': user.profile_image,
            'isAdmin': user.isAdmin,
            'created_at': user.created_at.isoformat(),
            'updated_at': user.updated_at.isoformat()
        }
    }), 200



#--------------------------TTS------------------------------------------------
@bp.route('/tts', methods=['POST'])
@jwt_required()
def text_to_speech_direct():
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    tts_prefs = user.tts_preferences
    if not tts_prefs:
        return jsonify({'error': 'TTS preferences not found for user'}), 404
    
    data = request.json
    text = data.get('text')
    if not text:
        return jsonify({'error': 'Text is required'}), 400
    

    voice_id = tts_prefs.voice_id  # Access model attribute directly
    stability = tts_prefs.stability     #range (0.0 to 1.0)

    
    #Pable (male)  or Rachel (female)
    if voice_id not in ["pNInz6obpgDQGcFmaJgB","21m00Tcm4TlvDq8ikWAM"]:
        return jsonify({'error': 'Invalid voice type, choose either male or female'}), 400

    if stability<0.0 or stability>1.0:
        return jsonify({'error': 'Stability must be between 0.0 and 1.0'}), 400
    


    client = ElevenLabs(api_key=os.getenv('ELEVENLABS_API_KEY'))
    try:
        # Generate audio (returns a generator)
        # Note: ElevenLabs multilingual model automatically detects language
        audio_generator = client.text_to_speech.convert(
            text=text,
            voice_id=voice_id,
            model_id='eleven_multilingual_v2',
            voice_settings={
                'stability': stability,
                'similarity_boost': 0.75,
                'style': 0.0,
                'speed': 1.0
            },
            output_format='mp3_44100_128'
        )

        # Collect audio bytes
        audio_bytes = b''
        for chunk in audio_generator:
            if chunk:
                audio_bytes += chunk

        # Return audio file directly
        return Response(
            audio_bytes,
            mimetype='audio/mpeg',
            headers={
                'Content-Disposition': 'attachment; filename="tts_audio.mp3"',
                'Content-Length': str(len(audio_bytes))
            }
        )
    except Exception as e:
        return jsonify({'error': f'Failed to generate audio: {str(e)}'}), 500
    

#--------------------------GET TTS PREFERENCES--------------------------------
@bp.route('/get-tts-preferences', methods=['GET'])
@jwt_required()
def get_tts_preferences():
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    tts_prefs = user.tts_preferences
    if not tts_prefs:
        return jsonify({'error': 'TTS preferences not found for user'}), 404
    
    if tts_prefs.voice_id == "pNInz6obpgDQGcFmaJgB":
        voice_type= "male"
    elif tts_prefs.voice_id == "21m00Tcm4TlvDq8ikWAM":
        voice_type= "female"
    else:
        return jsonify({'error': 'Invalid voice_id'}), 400

    
    return jsonify({
        'voice_id': voice_type,
        'stability': tts_prefs.stability
    }), 200



#---------------------------STT-----------------------------------------------
@bp.route('/stt', methods=['POST'])
@jwt_required()
def speech_to_text():
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))
    if not user:
        return jsonify({'error': 'User not found'}), 404

    if 'audio' not in request.files:
        return jsonify({'error': 'Audio file is required'}), 400

    audio_file = request.files['audio']
    if audio_file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    # Validate file extension
    allowed_extensions = {'wav', 'mp3', 'm4a'}
    if not '.' in audio_file.filename or audio_file.filename.rsplit('.', 1)[1].lower() not in allowed_extensions:
        return jsonify({'error': 'Invalid file format. Use WAV, MP3, or M4A'}), 400
    

    stt_prefs = user.stt_preferences
    if not stt_prefs:
        return jsonify({'error': 'STT preferences not found for user'}), 404

    language =  stt_prefs.language
    smart_format = stt_prefs.smart_format
    profanity_filter = stt_prefs.profanity_filter

    # Choose appropriate model based on language
    if language == 'ar':
        # Arabic requires whisper model
        model = 'whisper-medium'
        valid_languages = ['en', 'es', 'fr', 'de', 'ar', 'it']
    else:
        # Other languages can use nova-2
        model = 'nova-2'
        valid_languages = ['en', 'es', 'fr', 'de', 'it']
    
    if language not in valid_languages:
        return jsonify({'error': f'Invalid language. Valid languages: {", ".join(valid_languages)}'}), 400

    try:
        # Save audio temporarily
        static_dir = os.path.join(os.path.dirname(__file__), 'static')
        os.makedirs(static_dir, exist_ok=True)
        timestamp = int(time.time() * 1000)
        audio_filename = f'stt_input_{timestamp}.{audio_file.filename.rsplit(".", 1)[1].lower()}'
        audio_path = os.path.join(static_dir, audio_filename)
        audio_file.save(audio_path)

        # Initialize Deepgram client
        deepgram = DeepgramClient(api_key=os.getenv('DEEPGRAM_API_KEY'))

        # Read file into memory and close it
        with open(audio_path, 'rb') as audio:
            audio_data = audio.read()
        source = {'buffer': audio_data, 'mimetype': f'audio/{audio_filename.rsplit(".", 1)[1].lower()}'}
        options = PrerecordedOptions(
            model=model,  # Use dynamic model based on language
            language=language,
            smart_format=smart_format,
            profanity_filter=profanity_filter
        )
        response = deepgram.listen.prerecorded.v("1").transcribe_file(source, options)
        print('Deepgram response:', response)  # Add this line

        # Clean up temporary file
        os.remove(audio_path)

        # Extract transcript
        transcript = response['results']['channels'][0]['alternatives'][0]['transcript']
        if not transcript:
            return jsonify({'error': 'No speech detected'}), 400

        return jsonify({'message': 'Transcription successful', 'transcript': transcript}), 200
    except Exception as e:
        import traceback
        traceback.print_exc()  
        # Clean up file if it exists
        if os.path.exists(audio_path):
            try:
                os.remove(audio_path)
            except OSError as cleanup_error:
                print(f"Failed to clean up file: {cleanup_error}")
        return jsonify({'error': f'Failed to transcribe audio: {str(e)}'}), 500
    


#---------------------------GET STT PREFERENCES-----------------------------------
@bp.route('/get-stt-preferences', methods=['GET'])
@jwt_required()
def get_stt_preferences():
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    stt_prefs= user.stt_preferences
    if not stt_prefs:
        return jsonify({'error': 'STT preferences not found for user'}), 404
    
    return jsonify({
        'language': stt_prefs.language,
        'smart_format': stt_prefs.smart_format,
        'profanity_filter': stt_prefs.profanity_filter
    }), 200
    


#---------------------------UPDATE PREFERENCES-----------------------------------
@bp.route('/update-preferences', methods=['PUT'])
@jwt_required()
def update_preferences():
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))
    if not user:
        return jsonify({'error': 'User not found'}), 404

    data = request.json
    if not data:
        return jsonify({'error': 'No preferences provided'}), 400

    voice_map = {
        'male': 'pNInz6obpgDQGcFmaJgB',
        'female': '21m00Tcm4TlvDq8ikWAM',
    }

    if 'tts' in data:
        tts = data['tts']
        tts_prefs = user.tts_preferences
        if not tts_prefs:
            tts_prefs = TTSPreferences(user_id=user.id)
            db.session.add(tts_prefs)

        if tts.get('voice_id') not in ["male", "female"]:
            return jsonify({'error': 'Invalid voice_id. Valid options male, female'}), 400
        

        voice_id = tts.get('voice_id', tts_prefs.voice_id)
        tts_prefs.voice_id = voice_map.get(voice_id, voice_id) if voice_id in voice_map else tts_prefs.voice_id
        tts_prefs.stability = tts.get('stability', tts_prefs.stability)
        tts_prefs.updated_at = datetime.utcnow()

        if tts_prefs.voice_id not in voice_map.values():
            return jsonify({'error': f'Invalid voice_id. Valid options: male, female, neutral'}), 400
        if tts_prefs.stability < 0.0 or tts_prefs.stability > 1.0:
            return jsonify({'error': 'TTS stability must be between 0.0 and 1.0'}), 400

    if 'stt' in data:
        stt = data['stt']
        stt_prefs = user.stt_preferences
        if not stt_prefs:
            stt_prefs = STTPreferences(user_id=user.id)
            db.session.add(stt_prefs)

        valid_languages = ['en', 'ar', 'es', 'fr', 'de', 'it']
    
        if stt.get('language') not in valid_languages:
            return jsonify({'error': f'Invalid language. Valid languages: {", ".join(valid_languages)}'}), 400

        stt_prefs.language = stt.get('language', stt_prefs.language)
        stt_prefs.smart_format = stt.get('smart_format', stt_prefs.smart_format)
        stt_prefs.profanity_filter = stt.get('profanity_filter', stt_prefs.profanity_filter)
        stt_prefs.updated_at = datetime.utcnow()


    try:
        db.session.commit()
        return jsonify({
            'message': 'Preferences updated successfully',
            'tts_preferences': {
                'voice_id': user.tts_preferences.voice_id,
                'stability': user.tts_preferences.stability
            } if user.tts_preferences else {},
            'stt_preferences': {
                'language': user.stt_preferences.language,
                'smart_format': user.stt_preferences.smart_format,
                'profanity_filter': user.stt_preferences.profanity_filter
            } if user.stt_preferences else {}
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to update preferences: {str(e)}'}), 500



#---------------------------UPDATE PROFILE-----------------------------------
@bp.route('/update-profile', methods=['PUT'])
@jwt_required()
def update_profile():
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))
    if not user:
        return jsonify({'error': 'User not found'}), 404

    # Accept both multipart/form-data and JSON
    if request.content_type and request.content_type.startswith('multipart/form-data'):
        data = request.form
    else:
        data = request.get_json()

    # Check if any data was provided (either form fields or files)
    if (not data or len(data) == 0) and len(request.files) == 0:
        return jsonify({'error': 'No data provided to update profile'}), 400
    
    # Fields that can be updated
    if 'fullname' in data:
        user.fullname = data['fullname']
    
    if 'email' in data:
        # Check if email is already taken by another user
        existing_user = User.query.filter_by(email=data['email']).first()
        if existing_user and existing_user.id != user.id:
            return jsonify({'error': 'Email already exists'}), 400
        user.email = data['email']
    
    if 'role' in data:
        valid_roles = ['normal user', 'hearing-impaired', 'speech-impaired']
        if data['role'] not in valid_roles:
            return jsonify({'error': f'Invalid role. Valid roles are: {", ".join(valid_roles)}'}), 400
        user.role = data['role']
    
    if 'dateofbirth' in data:
        try:
            dob = datetime.strptime(data['dateofbirth'], '%Y-%m-%d').date()
            user.dateofbirth = dob
            # Recalculate age
            today = datetime.now().date()
            user.age = today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))
        except ValueError:
            return jsonify({'error': 'Invalid dateofbirth format. Use YYYY-MM-DD'}), 400
        
    # Handle profile image removal or upload
    if 'profile_image' in data and data['profile_image'] == "":
        # User wants to remove their profile image
        if user.profile_image:
            old_image_path = os.path.join(os.path.dirname(__file__), 'static', user.profile_image.lstrip('/static/'))
            if os.path.exists(old_image_path):
                os.remove(old_image_path)
            user.profile_image = ''
    elif 'profile_image' in request.files:
        file = request.files['profile_image']
        if file and file.filename:
            # Validate file extension
            allowed_extensions = {'png', 'jpg', 'jpeg', 'gif'}
            if '.' in file.filename and file.filename.rsplit('.', 1)[1].lower() in allowed_extensions:
                # Delete old profile image if it exists
                if user.profile_image:
                    old_image_path = os.path.join(os.path.dirname(__file__), 'static', user.profile_image.lstrip('/static/'))
                    if os.path.exists(old_image_path):
                        os.remove(old_image_path)
                
                # Create unique filename
                timestamp = int(time.time() * 1000)
                filename = f'profile_{timestamp}.{file.filename.rsplit(".", 1)[1].lower()}'
                
                # Ensure profile images directory exists
                profile_dir = os.path.join(os.path.dirname(__file__), 'static', 'profile_images')
                os.makedirs(profile_dir, exist_ok=True)
                
                # Save file
                file_path = os.path.join(profile_dir, filename)
                file.save(file_path)
                user.profile_image = f'/static/profile_images/{filename}'
            else:
                return jsonify({'error': 'Invalid image format. Use PNG, JPG, JPEG, or GIF'}), 400

    # Update the updated_at timestamp
    user.updated_at = datetime.utcnow()
    
    try:
        db.session.commit()
        return jsonify({
            'message': 'Profile updated successfully',
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'fullname': user.fullname,
                'role': user.role,
                'status': user.status,
                'age': user.age,
                'dateofbirth': user.dateofbirth.strftime('%Y-%m-%d'),
                'profile_image': user.profile_image,
                'isAdmin': user.isAdmin
            }
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to update profile: {str(e)}'}), 500
    

#---------------------------CHANGE PASSWORD-----------------------------------
@bp.route('/change-password', methods=['PUT'])
@jwt_required()
def change_password():
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))
    if not user:
        return jsonify({'error': 'User not found'}), 404

    data = request.json
    old_password = data.get('old_password')
    new_password = data.get('new_password')

    if not old_password or not new_password:
        return jsonify({'error': 'Old password and new password are required'}), 400

    # Verify old password
    if not bcrypt.checkpw(old_password.encode('utf-8'), user.password.encode('utf-8')):
        return jsonify({'error': 'Old password is incorrect'}), 401

    # Hash new password
    new_password_hash = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    user.password = new_password_hash
    user.updated_at = datetime.utcnow()

    try:
        db.session.commit()
        return jsonify({'message': 'Password changed successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to change password: {str(e)}'}), 500
