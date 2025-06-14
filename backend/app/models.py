from flask_sqlalchemy import SQLAlchemy
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


    def __repr__(self):
        return f'<User {self.username}>'

class OTP(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), nullable=False, index=True)
    otp = db.Column(db.String(6), nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    expires_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.utcnow() + timedelta(minutes=10))

    def __repr__(self):
        return f'<OTP {self.email}>'