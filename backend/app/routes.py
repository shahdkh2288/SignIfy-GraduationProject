from datetime import datetime, timedelta
from flask import request, jsonify, current_app, Response, Blueprint
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from .models import db, User, TTSPreferences, STTPreferences, OTP, Feedback
import bcrypt
from elevenlabs import ElevenLabs
from deepgram import DeepgramClient, PrerecordedOptions
import os
import time
import glob
import smtplib
import random
import string
from email.mime.text import MIMEText
import traceback
import numpy as np
import cv2
import mediapipe as mp
import tensorflow as tf
import pickle
import openai
from io import BytesIO
from PIL import Image
import tensorflow as tf
import pickle

bp = Blueprint('main', __name__)

#----------------------------SIGN UP------------------------------------------------
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
            return jsonify({'error': f'Invalid voice_id. Valid options: male, female'}), 400
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
        
        # Determine voice type based on voice_id
        if user.tts_preferences and user.tts_preferences.voice_id == "pNInz6obpgDQGcFmaJgB":
            voice_type = "male"
        elif user.tts_preferences and user.tts_preferences.voice_id == "21m00Tcm4TlvDq8ikWAM":
            voice_type = "female"
        
        return jsonify({
            'message': 'Preferences updated successfully',
            'tts_preferences': {
                'voice_id': voice_type,
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
    

#---------------------------FORGOT PASSWORD-----------------------------------
def send_otp_email(email, otp):
    try:
        sender = os.getenv('GMAIL_ADDRESS')
        password = os.getenv('GMAIL_APP_PASSWORD')
        msg = MIMEText(f'Your SignIfy password reset OTP is: {otp}. It expires in 10 minutes.')
        msg['Subject'] = 'SignIfy Password Reset OTP'
        msg['From'] = sender
        msg['To'] = email

        with smtplib.SMTP_SSL('smtp.gmail.com', 465) as server:
            server.login(sender, password)
            server.sendmail(sender, email, msg.as_string())
        return True
    except Exception as e:
        print(f"Failed to send OTP email: {str(e)}")
        return False




@bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    data = request.json
    email = data.get('email')
    if not email:
        return jsonify({'error': 'Email is required'}), 400

    user = User.query.filter_by(email=email).first()
    if not user:
        return jsonify({'error': 'Email not found'}), 404

    # Generate 6-digit OTP
    otp = ''.join(random.choices(string.digits, k=6))
    expires_at = datetime.utcnow() + timedelta(minutes=10)

    # Delete old OTPs for this email
    OTP.query.filter_by(email=email).delete()

    # Store new OTP
    new_otp = OTP(email=email, otp=otp, expires_at=expires_at)
    db.session.add(new_otp)
    try:
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to store OTP: {str(e)}'}), 500

    # Send OTP email
    if not send_otp_email(email, otp):
        return jsonify({'error': 'Failed to send OTP email'}), 500

    return jsonify({'message': 'OTP sent to email'}), 200


#---------------------------VERIFY OTP-----------------------------------
@bp.route('/verify-otp', methods=['POST'])
def verify_otp():
    data = request.json
    email = data.get('email')
    otp = data.get('otp')

    if not all([email, otp]):
        return jsonify({'error': 'Email and OTP are required'}), 400

    user = User.query.filter_by(email=email).first()
    if not user:
        return jsonify({'error': 'Email not found'}), 404

    otp_record = OTP.query.filter_by(email=email, otp=otp).first()
    if not otp_record:
        return jsonify({'error': 'Invalid OTP'}), 400

    if otp_record.expires_at < datetime.utcnow():
        OTP.query.filter_by(email=email).delete()
        db.session.commit()
        return jsonify({'error': 'OTP has expired'}), 400

    # Generate a short-lived reset token (5 minutes)
    reset_token = ''.join(random.choices(string.ascii_letters + string.digits, k=6))
    
    # Update the OTP record to store the reset token and shorter expiry
    otp_record.otp = reset_token  # Reuse otp field for reset token
    otp_record.expires_at = datetime.utcnow() + timedelta(minutes=5)  # 5 minute window for password reset
    
    try:
        db.session.commit()
        return jsonify({
            'message': 'OTP verified successfully',
            'reset_token': reset_token
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to verify OTP: {str(e)}'}), 500


#---------------------------RESET PASSWORD-----------------------------------
@bp.route('/reset-password', methods=['POST'])
def reset_password():
    data = request.json
    reset_token = data.get('reset_token')
    new_password = data.get('new_password')

    if not all([reset_token, new_password]):
        return jsonify({'error': 'Reset token and new password are required'}), 400

    # Find the OTP record with the reset token
    token_record = OTP.query.filter_by(otp=reset_token).first()
    if not token_record:
        return jsonify({'error': 'Invalid or expired reset token'}), 400

    if token_record.expires_at < datetime.utcnow():
        OTP.query.filter_by(otp=reset_token).delete()
        db.session.commit()
        return jsonify({'error': 'Reset token has expired'}), 400

    # Find user by email
    user = User.query.filter_by(email=token_record.email).first()
    if not user:
        return jsonify({'error': 'User not found'}), 404

    # Update password
    new_password_hash = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    user.password = new_password_hash
    user.updated_at = datetime.utcnow()

    # Delete used reset token
    OTP.query.filter_by(otp=reset_token).delete()

    try:
        db.session.commit()
        return jsonify({'message': 'Password reset successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to reset password: {str(e)}'}), 500


#---------------------------SIGN LANGUAGE DETECTION-----------------------------------------------
# Initialize MediaPipe components for full landmark extraction
mp_hands = mp.solutions.hands
mp_pose = mp.solutions.pose
mp_face_mesh = mp.solutions.face_mesh

hands = mp_hands.Hands(
    static_image_mode=False, 
    max_num_hands=2,  # Allow both hands
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

pose = mp_pose.Pose(
    static_image_mode=False,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

face_mesh = mp_face_mesh.FaceMesh(
    static_image_mode=False,
    refine_landmarks=True,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

# Landmark indices from your notebook - EXACT MATCH from the training notebook
filtered_hand = list(range(21))
filtered_pose = [11, 12, 13, 14, 15, 16]
filtered_face = [4, 6, 8, 9, 33, 37, 40, 46, 52, 55, 61, 70, 80, 82, 84,
                 87, 88, 91, 105, 107, 133, 145, 154, 157, 159, 161, 163,
                 263, 267, 270, 276, 282, 285, 291, 300, 310, 312, 314, 317,
                 318, 321, 334, 336, 362, 374, 381, 384, 386, 388, 390, 468, 473]

HAND_NUM = len(filtered_hand)  # 21
POSE_NUM = len(filtered_pose)  # 6  
FACE_NUM = len(filtered_face)  # 51 initially, but notebook shows 52

# Create the landmark index mapping exactly as in training notebook
landmarks_indices = (
    [x for x in filtered_hand] +
    [x + HAND_NUM for x in filtered_hand] +
    [x + HAND_NUM * 2 for x in filtered_pose] +
    [x + HAND_NUM * 2 + POSE_NUM for x in filtered_face]
)

print(f"Backend landmarks indices total: {len(landmarks_indices)}")
print(f"Backend total landmarks: {HAND_NUM * 2 + POSE_NUM + FACE_NUM}")
TOTAL_LANDMARKS = 100  # Model expects exactly 100 landmarks as confirmed by notebook output

# Try to load TFLite model and label encoder
try:
    model_path = os.path.join(os.path.dirname(__file__), 'models', 'model.tflite')
    label_encoder_path = os.path.join(os.path.dirname(__file__), 'models', 'label_encoder.pkl')
    
    if os.path.exists(model_path):
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        print("TFLite model loaded successfully")
        
        # Load label encoder
        if os.path.exists(label_encoder_path):
            with open(label_encoder_path, 'rb') as f:
                label_encoder = pickle.load(f)
            print(f"Label encoder loaded successfully with {len(label_encoder.classes_)} classes")
            print(f"Label encoder classes: {label_encoder.classes_[:10]}...")  # Show first 10 classes
        else:
            label_encoder = None
            print("Label encoder not found, using default word dictionary")
    else:
        interpreter = None
        label_encoder = None
        print("TFLite model not found, using mock predictions")
except Exception as e:
    interpreter = None
    label_encoder = None
    print(f"Failed to load TFLite model or label encoder: {e}")

# Fallback word dictionary (used when label encoder is not available)
word_dict = {
    0: 'A', 1: 'B', 2: 'C', 3: 'D', 4: 'E', 5: 'F', 6: 'G', 7: 'H', 8: 'I', 9: 'K', 
    10: 'L', 11: 'M', 12: 'N', 13: 'O', 14: 'P', 15: 'Q', 16: 'R', 17: 'S', 18: 'T', 
    19: 'U', 20: 'V', 21: 'W', 22: 'X', 23: 'Y', 24: 'space'
}

# Add constants for model input
MAX_FRAMES = 140  # From your notebook

def extract_full_landmarks(image_np):
    """Extract landmarks exactly as in the training notebook's get_frame_landmarks function."""
    # Initialize landmarks array exactly as in notebook: (HAND_NUM * 2 + POSE_NUM + FACE_NUM, 3) = (99, 3)
    all_landmarks = np.zeros((HAND_NUM * 2 + POSE_NUM + FACE_NUM, 3))
    
    try:
        # Process hands - exact match to notebook
        results_hands = hands.process(image_np)
        if results_hands.multi_hand_landmarks:
            for i, hand_landmarks in enumerate(results_hands.multi_hand_landmarks):
                if results_hands.multi_handedness[i].classification[0].index == 0:
                    # Left hand
                    all_landmarks[:HAND_NUM, :] = np.array(
                        [(lm.x, lm.y, lm.z) for lm in hand_landmarks.landmark])
                else:
                    # Right hand
                    all_landmarks[HAND_NUM:HAND_NUM * 2, :] = np.array(
                        [(lm.x, lm.y, lm.z) for lm in hand_landmarks.landmark])

        # Process pose - exact match to notebook
        results_pose = pose.process(image_np)
        if results_pose.pose_landmarks:
            all_landmarks[HAND_NUM * 2:HAND_NUM * 2 + POSE_NUM, :] = np.array(
                [(lm.x, lm.y, lm.z) for lm in results_pose.pose_landmarks.landmark])[filtered_pose]

        # Process face - exact match to notebook
        results_face = face_mesh.process(image_np)
        if results_face.multi_face_landmarks:
            all_landmarks[HAND_NUM * 2 + POSE_NUM:, :] = np.array(
                [(lm.x, lm.y, lm.z) for lm in results_face.multi_face_landmarks[0].landmark])[filtered_face]

        # The notebook's get_frame_landmarks returns 99 landmarks, but the model expects 100
        # We need to pad or use the landmark indices to get to 100
        model_landmarks = np.zeros((TOTAL_LANDMARKS, 3))
        
        # For now, copy the 99 landmarks and add one padding landmark
        if len(all_landmarks) == 99:
            model_landmarks[:99, :] = all_landmarks
            # The 100th landmark remains zeros (padding)
        else:
            # If we somehow get a different count, copy what we have
            copy_count = min(len(all_landmarks), TOTAL_LANDMARKS)
            model_landmarks[:copy_count, :] = all_landmarks[:copy_count]
        
        return model_landmarks
        
    except Exception as e:
        print(f"Error extracting landmarks: {e}")
        return None

def pad_sequence(landmarks_sequence, target_length=MAX_FRAMES):
    """Pad or truncate sequence to target length."""
    current_length = len(landmarks_sequence)
    
    if current_length >= target_length:
        return landmarks_sequence[:target_length]
    else:
        pad_length = target_length - current_length
        return np.pad(landmarks_sequence, ((0, pad_length), (0, 0), (0, 0)), 
                     mode='constant', constant_values=0)

@bp.route('/detect-video-signs', methods=['POST'])
def detect_video_signs():
    """Process individual sign videos for sequential recording workflow with session management."""
    if 'video' not in request.files:
        return jsonify({'error': 'Video file is required'}), 400

    video_file = request.files['video']
    if video_file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    # Check parameters
    debug_mode = request.form.get('debug', 'false').lower() == 'true'
    flip_camera = request.form.get('flip_camera', 'auto').lower()  # auto, true, false
    session_id = request.form.get('session_id', None)  # Session ID for multi-sign recording
    sequence_number = int(request.form.get('sequence_number', 1))  # Position in sequence
    is_final = request.form.get('is_final', 'false').lower() == 'true'  # Last sign in sequence
    
    temp_path = None
    try:
        # Save video temporarily
        static_dir = os.path.join(os.path.dirname(__file__), 'static')
        os.makedirs(static_dir, exist_ok=True)
        timestamp = int(time.time() * 1000)
        temp_path = os.path.join(static_dir, f'temp_video_{timestamp}.mp4')
        video_file.save(temp_path)

        # Extract frames and landmarks for SINGLE SIGN
        cap = cv2.VideoCapture(temp_path)
        landmarks_sequence = []
        frame_count = 0
        debug_info = []
        flip_applied = False
        
        # Get video properties
        fps = cap.get(cv2.CAP_PROP_FPS)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        duration = total_frames / fps if fps > 0 else 0
        print(f"Processing single sign video: {fps} FPS, {total_frames} frames, {duration:.2f}s duration")
        
        # Camera flip logic
        force_flip = flip_camera == 'true'
        auto_flip = flip_camera == 'auto'
        
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
                
            frame_count += 1
            # Convert BGR to RGB for MediaPipe
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # # Resize frame for better MediaPipe processing
            # height, width = frame_rgb.shape[:2]
            # original_size = (width, height)
            # if width > 640:
            #     scale = 640 / width
            #     new_width = 640
            #     new_height = int(height * scale)
            #     frame_rgb = cv2.resize(frame_rgb, (new_width, new_height))
            #     processed_size = (new_width, new_height)
            # else:
            #     processed_size = original_size
            
            # Use original frame size without resizing
            height, width = frame_rgb.shape[:2]
            original_size = (width, height)
            processed_size = original_size
            
            # Apply camera flip correction if needed
            if force_flip or (auto_flip and should_flip_camera(frame_count, landmarks_sequence)):
                frame_rgb = cv2.flip(frame_rgb, 1)  # Horizontal flip
                flip_applied = True
            
            # Extract landmarks from each frame
            frame_landmarks = extract_full_landmarks(frame_rgb)
            
            if frame_landmarks is not None:
                landmarks_sequence.append(frame_landmarks)
                # Only print every 20th frame to reduce log spam
                if frame_count % 20 == 0:
                    print(f"Frame {frame_count}: landmarks extracted successfully")
                
                # Store debug information if requested (simplified)
                if debug_mode:
                    debug_frame_info = {
                        'frame_number': frame_count,
                        'landmarks_detected': True,
                        'landmarks_count': len(frame_landmarks),
                        'non_zero_landmarks': np.count_nonzero(frame_landmarks),
                        'flip_applied': flip_applied
                    }
                    debug_info.append(debug_frame_info)
            else:
                # Only print every 20th frame to reduce log spam
                if frame_count % 20 == 0:
                    print(f"Frame {frame_count}: no landmarks detected")
                if debug_mode:
                    debug_info.append({
                        'frame_number': frame_count,
                        'landmarks_detected': False,
                        'flip_applied': flip_applied
                    })
            
            # For single signs, limit to MAX_FRAMES (not 3x like multi-sign)
            if frame_count >= MAX_FRAMES:
                print(f"Reached maximum frames limit for single sign: {MAX_FRAMES}")
                break
        
        cap.release()
        print(f"Extracted landmarks from {len(landmarks_sequence)} frames")
        print(f"Camera flip applied: {flip_applied}")

        if not landmarks_sequence:
            return jsonify({'error': 'No hands detected in video'}), 400

        # Process single sign (no segmentation needed)
        prediction = predict_single_sign(landmarks_sequence)
        print(f"Prediction: '{prediction['word']}' (confidence: {prediction['confidence']:.2f})")
        
        # Check if prediction is valid but don't block it
        if prediction['word'] in ['unknown', 'error'] or prediction['confidence'] < 0.1:
            print(f"Warning: Low confidence or invalid prediction")
        
        # Always return a prediction, even if it's 'unknown'
        if not prediction or 'word' not in prediction:
            print("Error: prediction is invalid, creating fallback")
            prediction = {'word': 'unknown', 'confidence': 0.0, 'predicted_index': -1}
        
        # Handle session management for sequential recording
        if session_id:
            # Store/update sign in session
            session_data = manage_sign_session(session_id, sequence_number, prediction, is_final)
            
            if is_final:
                # Return complete sentence when user finishes
                response_data = {
                    'word': prediction['word'],
                    'confidence': prediction['confidence'],
                    'session_id': session_id,
                    'sequence_number': sequence_number,
                    'is_final': True,
                    'complete_sequence': session_data['signs'],
                    'complete_sentence': session_data['sentence'],
                    'gpt_sentence': session_data.get('gpt_sentence', session_data['sentence']),
                    'raw_sentence': session_data.get('raw_sentence', session_data['sentence']),
                    'words': [sign['word'] for sign in session_data['signs'] if sign['word'] not in ['unknown', 'error']],
                    'total_signs': len(session_data['signs']),
                    'overall_confidence': session_data['overall_confidence'],
                    'frames_processed': len(landmarks_sequence),
                    'video_duration': duration,
                    'camera_flip_applied': flip_applied,
                    'flip_mode': flip_camera,
                    'message': f'Sequence complete: {session_data["sentence"]}',
                    'debug_info': debug_info if debug_mode else None
                }
                return jsonify(response_data), 200
            else:
                # Return individual sign result and continue session
                response_data = {
                    'word': prediction['word'],
                    'confidence': prediction['confidence'],
                    'session_id': session_id,
                    'sequence_number': sequence_number,
                    'is_final': False,
                    'current_sequence': session_data['signs'],
                    'partial_sentence': session_data['sentence'],
                    'signs_so_far': len(session_data['signs']),
                    'frames_processed': len(landmarks_sequence),
                    'video_duration': duration,
                    'camera_flip_applied': flip_applied,
                    'flip_mode': flip_camera,
                    'message': f'Sign {sequence_number} detected: {prediction["word"]}',
                    'debug_info': debug_info if debug_mode else None
                }
                return jsonify(response_data), 200
        else:
            # Single sign mode (no session)
            response_data = {
                'word': prediction['word'],
                'confidence': prediction['confidence'],
                'frames_processed': len(landmarks_sequence),
                'video_duration': duration,
                'camera_flip_applied': flip_applied,
                'flip_mode': flip_camera,
                'message': f'Single sign detected: {prediction["word"]}',
                'debug_info': debug_info if debug_mode else None
            }
            return jsonify(response_data), 200

    except Exception as e:
        print(f"Error in video processing: {str(e)}")
        traceback.print_exc()
        return jsonify({'error': f'Failed to process video: {str(e)}'}), 500
    finally:
        # Clean up temporary file
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except OSError as cleanup_error:
                print(f"Failed to clean up video file: {cleanup_error}")

def should_flip_camera(frame_count, landmarks_sequence, sample_frames=10):
    """
    Auto-detect if camera flip should be applied based on hand positioning patterns.
    This is called during the first few frames to make a decision.
    """
    if frame_count > sample_frames or len(landmarks_sequence) < 5:
        return False  # Decision already made or not enough data
    
    # For now, we'll use a simple heuristic
    # In practice, you might analyze hand positions relative to face/body
    return False  # Default to no flip for auto mode

def detect_motion_pause(landmarks_sequence, window_size=5, motion_threshold=0.02):
    """Detect motion and pause segments in landmark sequence for sign segmentation."""
    if len(landmarks_sequence) < window_size:
        return [True] * len(landmarks_sequence)  # All frames are motion if too short
    
    motion_flags = []
    
    for i in range(len(landmarks_sequence)):
        if i < window_size:
            motion_flags.append(True)  # Assume motion at the beginning
            continue
            
        # Calculate motion by comparing current frame with previous frames
        current_landmarks = landmarks_sequence[i]
        prev_landmarks = landmarks_sequence[i - window_size]
        
        # Calculate average movement across all landmarks
        movement = np.mean(np.abs(current_landmarks - prev_landmarks))
        
        # If movement is above threshold, it's motion; otherwise it's a pause
        is_motion = movement > motion_threshold
        motion_flags.append(is_motion)
    
    return motion_flags

def segment_video_signs(landmarks_sequence, min_sign_frames=10, max_pause_frames=15):
    """Segment continuous landmarks into individual sign segments based on motion detection."""
    if not landmarks_sequence:
        return []
    
    # Detect motion/pause frames
    motion_flags = detect_motion_pause(landmarks_sequence)
    
    segments = []
    current_segment = []
    pause_count = 0
    
    for i, (landmarks, is_motion) in enumerate(zip(landmarks_sequence, motion_flags)):
        if is_motion:
            # Motion detected - add to current segment and reset pause count
            current_segment.append(landmarks)
            pause_count = 0
        else:
            # Pause detected
            pause_count += 1
            
            # If we have a significant segment and pause is long enough, finalize segment
            if len(current_segment) >= min_sign_frames and pause_count >= max_pause_frames:
                segments.append(current_segment)
                current_segment = []
                pause_count = 0
            elif len(current_segment) > 0:
                # Short pause - keep adding to segment
                current_segment.append(landmarks)
    
    # Add final segment if it exists and is significant
    if len(current_segment) >= min_sign_frames:
        segments.append(current_segment)
    
    print(f"Segmented video into {len(segments)} sign segments")
    for i, segment in enumerate(segments):
        print(f"  Segment {i+1}: {len(segment)} frames")
    
    return segments

def predict_sign_from_segment(segment):
    """Predict a single sign from a landmark segment."""
    if not segment or interpreter is None:
        return {'word': 'unknown', 'confidence': 0.0}
    
    try:
        # Convert segment to numpy array
        segment_array = np.array(segment, dtype=np.float32)
        
        # Pad or truncate to model's expected sequence length
        padded_segment = pad_sequence(segment_array, MAX_FRAMES)
        
        # Prepare for model input (add batch dimension)
        model_input = np.expand_dims(padded_segment, axis=0)
        
        # Set input tensor and run inference
        interpreter.set_tensor(input_details[0]['index'], model_input)
        interpreter.invoke()
        
        # Get output
        output_data = interpreter.get_tensor(output_details[0]['index'])
        predicted_index = np.argmax(output_data, axis=1)[0]
        confidence = float(np.max(output_data))
        
        # Use label encoder if available
        if label_encoder is not None:
            try:
                predicted_word = label_encoder.inverse_transform([predicted_index])[0]
            except (ValueError, IndexError):
                predicted_word = f'Class_{predicted_index}'
        else:
            predicted_word = word_dict.get(predicted_index, 'Unknown')
        
        return {
            'word': predicted_word,
            'confidence': confidence,
            'predicted_index': int(predicted_index)
        }
        
    except Exception as e:
        print(f"Error predicting sign from segment: {e}")
        return {'word': 'error', 'confidence': 0.0}

# Initialize OpenAI client
try:
    openai_client = openai.OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
    print("OpenAI client initialized successfully")
except Exception as e:
    openai_client = None
    print(f"Failed to initialize OpenAI client: {e}")

def sign_words_to_sentence_with_gpt(sign_words):
    """Convert detected sign words into a grammatically correct sentence using GPT."""
    if not openai_client:
        # Fallback: just join words with spaces
        return ' '.join(sign_words)
    
    try:
        # Filter out error/unknown words
        valid_words = [word for word in sign_words if word not in ['unknown', 'error', '']]
        
        if not valid_words:
            return "No valid words detected"
        
        # Create a prompt for GPT to form a grammatical sentence
        words_string = ', '.join(valid_words)
        prompt = f"Convert this list of sign language words into a grammatically correct and natural sentence: {words_string}. Only return the sentence, nothing else."

        response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {
                    "role": "system", 
                    "content": "You are a helpful assistant that converts sign language word outputs into complete, grammatically correct sentences. Return only the sentence without any explanations or additional text."
                },
                {
                    "role": "user", 
                    "content": prompt
                }
            ],
            max_tokens=100,
            temperature=0.7
        )

        gpt_sentence = response.choices[0].message.content.strip()
        #print(f"GPT converted '{words_string}' to: '{gpt_sentence}'")
        return gpt_sentence
        
    except Exception as e:
        print(f"Error with GPT sentence generation: {e}")
        # Fallback: just join words with spaces
        return ' '.join(valid_words)

# Global variable to store sign sessions in memory
sign_sessions = {}

def predict_single_sign(landmarks_sequence):
    """Predict a single sign from a landmarks sequence for sequential recording workflow."""
    if not landmarks_sequence or interpreter is None:
        return {'word': 'unknown', 'confidence': 0.0}
    
    try:
        # Convert landmarks sequence to numpy array
        sequence_array = np.array(landmarks_sequence, dtype=np.float32)
        
        # Pad or truncate to model's expected sequence length (140 frames)
        padded_ = sequence_array[:100, :, :]
        padded_sequence = pad_sequence(padded_, target_length=MAX_FRAMES)
        
        # Prepare for model input (add batch dimension)
        model_input = np.expand_dims(padded_sequence, axis=0)
        
        # Set input tensor and run inference
        interpreter.set_tensor(input_details[0]['index'], model_input)
        interpreter.invoke()
        
        # Get output
        output_data = interpreter.get_tensor(output_details[0]['index'])
        predicted_index = np.argmax(output_data, axis=1)[0]
        confidence = float(np.max(output_data))
        
        # Use label encoder if available
        if label_encoder is not None:
            try:
                predicted_word = label_encoder.inverse_transform([predicted_index])[0]
            except (ValueError, IndexError) as e:
                # Try to get the number of classes from the label encoder
                try:
                    num_classes = len(label_encoder.classes_)
                    # If the predicted index is too high, try using modulo to wrap around
                    if predicted_index >= num_classes:
                        # Try wrapping around or use a fallback approach
                        wrapped_index = predicted_index % num_classes
                        try:
                            predicted_word = label_encoder.inverse_transform([wrapped_index])[0]
                        except:
                            predicted_word = 'sign_detected'  # More meaningful than 'unknown'
                    else:
                        predicted_word = f'Class_{predicted_index}'
                except Exception as inner_e:
                    predicted_word = 'sign_detected'  # More meaningful than 'unknown'
        else:
            predicted_word = word_dict.get(predicted_index, 'Unknown')
            # Add extra check for word_dict
            if predicted_index not in word_dict:
                predicted_word = 'unknown'
        
        return {
            'word': predicted_word,
            'confidence': confidence,
            'predicted_index': int(predicted_index)
        }
        
    except Exception as e:
        print(f"Error predicting single sign: {e}")
        traceback.print_exc()
        return {'word': 'error', 'confidence': 0.0}

def manage_sign_session(session_id, sequence_number, prediction, is_final):
    """Manage sign sessions for sequential recording workflow."""
    try:
        # Initialize session if it doesn't exist
        if session_id not in sign_sessions:
            sign_sessions[session_id] = {
                'signs': [],
                'created_at': datetime.utcnow(),
                'last_updated': datetime.utcnow()
            }
        
        session = sign_sessions[session_id]
        
        # Add or update the sign at the specified sequence number
        sign_entry = {
            'sequence_number': sequence_number,
            'word': prediction['word'],
            'confidence': prediction['confidence'],
            'predicted_index': prediction.get('predicted_index', -1),
            'timestamp': datetime.utcnow()
        }
        
        # Find if this sequence number already exists and update it, or add new
        updated = False
        for i, existing_sign in enumerate(session['signs']):
            if existing_sign['sequence_number'] == sequence_number:
                session['signs'][i] = sign_entry
                updated = True
                break
        
        if not updated:
            session['signs'].append(sign_entry)
        
        # Sort signs by sequence number
        session['signs'].sort(key=lambda x: x['sequence_number'])
        
        # Update session metadata
        session['last_updated'] = datetime.utcnow()
        session['total_signs'] = len(session['signs'])
        
        # Create sentence from all signs
        words = [sign['word'] for sign in session['signs'] if sign['word'] not in ['unknown', 'error']]
        all_words = [sign['word'] for sign in session['signs']]  # Include all words for debugging
        
        print(f"All detected words: {all_words}")
        print(f"Valid words for sentence: {words}")
        
        # Use GPT to generate grammatical sentence when session is final
        if is_final:
            if words:
                print(f"Final sequence detected. Generate sentence from words: {words}")
                session['gpt_sentence'] = sign_words_to_sentence_with_gpt(words)
                session['raw_sentence'] = ' '.join(words)  # Keep the original for reference
                session['sentence'] = session['gpt_sentence']  # Use GPT sentence as primary
                print(f"GPT generated sentence: '{session['gpt_sentence']}'")
            else:
                print("No valid words found for final sequence")
                session['gpt_sentence'] = "No valid signs detected"
                session['raw_sentence'] = ' '.join(all_words)  # Show all words including unknowns
                session['sentence'] = session['gpt_sentence']
        else:
            session['sentence'] = ' '.join(words) if words else ' '.join(all_words)
        
        # Calculate overall confidence
        if session['signs']:
            confidences = [sign['confidence'] for sign in session['signs'] if sign['confidence'] > 0]
            session['overall_confidence'] = sum(confidences) / len(confidences) if confidences else 0.0
        else:
            session['overall_confidence'] = 0.0
        
        print(f"Session {session_id} updated: {len(session['signs'])} signs, sentence: '{session['sentence']}'")
        
        # Clean up session if final (optional - you might want to keep it for a while)
        if is_final:
            # You could clean up the session after some time or keep it for reference
            session['is_complete'] = True
            session['completed_at'] = datetime.utcnow()
        
        return session
        
    except Exception as e:
        print(f"Error managing sign session: {e}")
        traceback.print_exc()
        return {
            'signs': [],
            'sentence': '',
            'overall_confidence': 0.0,
            'error': str(e)
        }

#---------------------------SESSION MANAGEMENT ROUTES-----------------------------------
@bp.route('/session-info/<session_id>', methods=['GET'])
def get_session_info(session_id):
    """Get information about a specific sign recording session."""
    print(f"=== GET SESSION INFO DEBUG ===")
    print(f"Requested session: {session_id}")
    print(f"Active sessions: {list(sign_sessions.keys())}")
    
    if session_id not in sign_sessions:
        print(f"Session {session_id} not found")
        return jsonify({'error': 'Session not found'}), 404
    
    session = sign_sessions[session_id]
    print(f"Session found. Signs: {session['signs']}")
    
    return jsonify({
        'session_id': session_id,
        'signs': session['signs'],
        'sentence': session.get('sentence', ''),
        'total_signs': session.get('total_signs', 0),
        'overall_confidence': session.get('overall_confidence', 0.0),
        'created_at': session['created_at'].isoformat(),
        'last_updated': session['last_updated'].isoformat(),
        'is_complete': session.get('is_complete', False),
        'completed_at': session.get('completed_at', '').isoformat() if session.get('completed_at') else None
    }), 200

@bp.route('/clear-session/<session_id>', methods=['DELETE'])
def clear_session(session_id):
    """Clear a specific sign recording session."""
    if session_id in sign_sessions:
        del sign_sessions[session_id]
        return jsonify({'message': f'Session {session_id} cleared successfully'}), 200
    else:
        return jsonify({'error': 'Session not found'}), 404

@bp.route('/list-sessions', methods=['GET'])
def list_sessions():
    """List all active sign recording sessions."""
    sessions_info = {}
    for session_id, session in sign_sessions.items():
        sessions_info[session_id] = {
            'total_signs': session.get('total_signs', 0),
            'sentence': session.get('sentence', ''),
            'overall_confidence': session.get('overall_confidence', 0.0),
            'created_at': session['created_at'].isoformat(),
            'last_updated': session['last_updated'].isoformat(),
            'is_complete': session.get('is_complete', False)
        }
    
    return jsonify({
        'active_sessions': len(sign_sessions),
        'sessions': sessions_info
    }), 200

@bp.route('/remove-last-word-from-session/<session_id>', methods=['DELETE'])
def remove_last_word_from_session(session_id):
    """Remove the last word from a sign recording session."""
    print(f"=== REMOVE LAST WORD DEBUG ===")
    print(f"Attempting to remove last word from session {session_id}")
    print(f"Active sessions: {list(sign_sessions.keys())}")
    
    if session_id not in sign_sessions:
        print(f"Session {session_id} not found in active sessions")
        return jsonify({'error': 'Session not found'}), 404
    
    session = sign_sessions[session_id]
    print(f"Session found. Current signs: {session['signs']}")
    
    if not session['signs']:
        print("No signs to remove")
        return jsonify({'error': 'No words in session to remove'}), 400
    
    # Find the sign with the highest sequence number (last word)
    last_sign = max(session['signs'], key=lambda x: x['sequence_number'])
    last_sequence_number = last_sign['sequence_number']
    
    print(f"Removing last word: {last_sign}")
    
    # Remove the last sign
    session['signs'] = [sign for sign in session['signs'] if sign['sequence_number'] != last_sequence_number]
    print(f"Signs after removal: {session['signs']}")
    
    # Update session metadata
    session['last_updated'] = datetime.utcnow()
    session['total_signs'] = len(session['signs'])
    
    # Regenerate sentence from remaining signs
    words = [sign['word'] for sign in session['signs'] if sign['word'] not in ['unknown', 'error']]
    all_words = [sign['word'] for sign in session['signs']]
    
    # Update sentences
    if words:
        session['raw_sentence'] = ' '.join(words)
        session['sentence'] = ' '.join(words)  # Simple sentence for now
        session['gpt_sentence'] = None  # Clear GPT sentence since words changed
    else:
        session['raw_sentence'] = ''
        session['sentence'] = ''
        session['gpt_sentence'] = None
    
    # Recalculate overall confidence
    if session['signs']:
        confidences = [sign['confidence'] for sign in session['signs'] if sign['confidence'] > 0]
        session['overall_confidence'] = sum(confidences) / len(confidences) if confidences else 0.0
    else:
        session['overall_confidence'] = 0.0
    
    # Mark session as incomplete if it was marked as complete
    if session.get('is_complete'):
        session['is_complete'] = False
        session.pop('completed_at', None)
    
    print(f"Removed last word from session {session_id}")
    print(f"Updated sentence: '{session['sentence']}'")
    
    return jsonify({
        'message': f'Last word "{last_sign["word"]}" removed successfully',
        'session_id': session_id,
        'signs': session['signs'],
        'sentence': session.get('sentence', ''),
        'raw_sentence': session.get('raw_sentence', ''),
        'total_signs': session.get('total_signs', 0),
        'overall_confidence': session.get('overall_confidence', 0.0),
        'words': words,
        'removed_word': last_sign['word']
    }), 200

#---------------------------REGENERATE SENTENCE-----------------------------------
@bp.route('/regenerate-sentence/<session_id>', methods=['POST'])
def regenerate_sentence(session_id):
    """Regenerate GPT sentence from current words in session."""
    if session_id not in sign_sessions:
        return jsonify({'error': 'Session not found'}), 404
    
    session = sign_sessions[session_id]
    
    # Get current valid words from session
    words = [sign['word'] for sign in session['signs'] if sign['word'] not in ['unknown', 'error']]
    
    if not words:
        return jsonify({'error': 'No valid words in session to generate sentence'}), 400
    
    try:
        # Generate new GPT sentence
        gpt_sentence = sign_words_to_sentence_with_gpt(words)
        raw_sentence = ' '.join(words)
        
        # Update session with new sentences
        session['gpt_sentence'] = gpt_sentence
        session['raw_sentence'] = raw_sentence
        session['sentence'] = gpt_sentence
        session['last_updated'] = datetime.utcnow()
        
        return jsonify({
            'message': 'Sentence regenerated successfully',
            'session_id': session_id,
            'gpt_sentence': gpt_sentence,
            'raw_sentence': raw_sentence,
            'complete_sentence': gpt_sentence,
            'words': words,
            'is_final': True
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Failed to regenerate sentence: {str(e)}'}), 500
