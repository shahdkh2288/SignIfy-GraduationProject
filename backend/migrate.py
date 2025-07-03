#!/usr/bin/env python3
"""
Script to run database migrations
"""
import sys
import os

# Add the current directory to the Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.app import create_app
from flask_migrate import upgrade

def run_migration():
    """Run the database migration"""
    app = create_app()
    
    with app.app_context():
        try:
            print("Running database migrations...")
            upgrade()
            print("✅ Migration completed successfully!")
        except Exception as e:
            print(f"❌ Migration failed: {str(e)}")
            return False
    return True

if __name__ == '__main__':
    success = run_migration()
    sys.exit(0 if success else 1)
