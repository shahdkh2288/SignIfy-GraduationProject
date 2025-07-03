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


#----------------------------FEEDBACK ROUTES------------------------------------------------
@bp.route('/submit-feedback', methods=['POST'])
@jwt_required()
def submit_feedback():
    """Submit user feedback with star rating and optional text"""
    try:
        current_user_id = get_jwt_identity()
        data = request.json

        stars = data.get('stars')
        feedback_text = data.get('feedback_text', '').strip()

        # Validation
        if not stars or not isinstance(stars, int):
            return jsonify({'error': 'Stars rating is required and must be an integer'}), 400

        if stars < 1 or stars > 5:
            return jsonify({'error': 'Stars rating must be between 1 and 5'}), 400

        if len(feedback_text) > 1000:
            return jsonify({'error': 'Feedback text cannot exceed 1000 characters'}), 400

        # Create new feedback
        new_feedback = Feedback(
            user_id=current_user_id,
            stars=stars,
            feedback_text=feedback_text if feedback_text else None
        )

        db.session.add(new_feedback)
        db.session.commit()

        return jsonify({
            'message': 'Feedback submitted successfully',
            'feedback_id': new_feedback.id,
            'stars': new_feedback.stars
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to submit feedback: {str(e)}'}), 500



# Admin route to get all feedback
@bp.route('/admin/all-feedback', methods=['GET'])
@jwt_required()
def get_all_feedback():
    """Get all feedback for admin users (requires admin privileges)"""
    try:
        current_user_id = get_jwt_identity()
        
        # Check if user is admin
        current_user = User.query.get(current_user_id)
        if not current_user or not current_user.isAdmin:
            return jsonify({'error': 'Admin access required'}), 403

        # Get pagination parameters
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 50, type=int)
        min_stars = request.args.get('min_stars', type=int)

        # Build query
        query = db.session.query(Feedback, User.username)\
                          .join(User, Feedback.user_id == User.id)

        if min_stars:
            query = query.filter(Feedback.stars >= min_stars)

        # Order by most recent
        query = query.order_by(Feedback.created_at.desc())

        # Paginate
        paginated_feedback = query.paginate(
            page=page, per_page=per_page, error_out=False
        )

        feedback_data = []
        for feedback, username in paginated_feedback.items:
            feedback_dict = feedback.to_dict()
            feedback_dict['username'] = username
            feedback_data.append(feedback_dict)

        return jsonify({
            'feedback': feedback_data,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': paginated_feedback.total,
                'pages': paginated_feedback.pages
            }
        }), 200

    except Exception as e:
        return jsonify({'error': f'Failed to retrieve feedback: {str(e)}'}), 500