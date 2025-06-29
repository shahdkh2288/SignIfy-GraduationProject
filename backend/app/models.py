from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime, timedelta

db = SQLAlchemy()

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False, index=True)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password = db.Column(db.String(128), nullable=False)
    status = db.Column(db.String(50), nullable=False, default='active')
    age = db.Column(db.Integer, nullable=False)
    isAdmin = db.Column(db.Boolean, nullable=False, default=False)
    fullname = db.Column(db.String(120), nullable=False, default='')
    dateofbirth = db.Column(db.Date, nullable=False, default=datetime(1970, 1, 1).date())
    role = db.Column(db.String(50), nullable=False, default='normal user')
    profile_image = db.Column(db.String(255), nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)


    tts_preferences = db.relationship('TTSPreferences', back_populates='user', uselist=False)
    stt_preferences = db.relationship('STTPreferences', back_populates='user', uselist=False)



    def __repr__(self):
        return f'<User {self.username}>'
    

class TTSPreferences(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False, unique=True)
    voice_id = db.Column(db.String(50), nullable=False, default='21m00Tcm4TlvDq8ikWAM')  # Rachel
    stability = db.Column(db.Float, nullable=False, default=0.5)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = db.relationship('User', back_populates='tts_preferences')

    def __repr__(self):
        return f'<TTSPreferences user_id={self.user_id}>'

class STTPreferences(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False, unique=True)
    language = db.Column(db.String(10), nullable=False, default='en')
    smart_format = db.Column(db.Boolean, nullable=False, default=True)
    profanity_filter = db.Column(db.Boolean, nullable=False, default=False)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = db.relationship('User', back_populates='stt_preferences')

    def __repr__(self):
        return f'<STTPreferences user_id={self.user_id}>'
    


class OTP(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), nullable=False, index=True)
    otp = db.Column(db.String(6), nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    expires_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.utcnow() + timedelta(minutes=10))

    #composite index for email and otp
    # This index will speed up queries that filter by both email and otp
    __table_args__ = (db.Index('ix_otp_email_otp', 'email', 'otp'),)


    def __repr__(self):
        return f'<OTP {self.email}>'