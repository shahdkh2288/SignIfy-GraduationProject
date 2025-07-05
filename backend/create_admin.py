#!/usr/bin/env python3
"""
Script to create an admin user for testing admin endpoints
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.app import create_app
from app.models import db, User
from werkzeug.security import generate_password_hash
from datetime import datetime

def create_admin_user():
    """Create an admin user for testing"""
    app = create_app()
    
    with app.app_context():
        # Check if admin already exists
        existing_admin = User.query.filter_by(email='admin@test.com').first()
        if existing_admin:
            print(f"Admin user already exists: {existing_admin.username} ({existing_admin.email})")
            print(f"Admin status: {existing_admin.isAdmin}")
            return
        
        # Create admin user
        admin_user = User(
            username='admin',
            email='admin@test.com',
            password=generate_password_hash('adminpass123'),
            fullname='System Administrator',
            age=30,
            dateofbirth=datetime(1993, 1, 1).date(),
            role='administrator',
            status='active',
            isAdmin=True
        )
        
        try:
            db.session.add(admin_user)
            db.session.commit()
            print("✅ Admin user created successfully!")
            print(f"Email: admin@test.com")
            print(f"Password: adminpass123")
            print(f"Username: admin")
        except Exception as e:
            db.session.rollback()
            print(f"❌ Failed to create admin user: {e}")

if __name__ == "__main__":
    create_admin_user()
