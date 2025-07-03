#!/usr/bin/env python3
"""
Script to reset and run database migrations
"""
import sys
import os

# Add the current directory to the Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.app import create_app
from flask_migrate import upgrade, stamp
from sqlalchemy import text

def reset_and_migrate():
    """Reset migration state and run migrations"""
    app = create_app()
    
    with app.app_context():
        try:
            # Import db from the app
            from app.models import db
            
            print("Checking database connection...")
            
            # Check if alembic_version table exists
            with db.engine.connect() as conn:
                result = conn.execute(text("""
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables 
                        WHERE table_name = 'alembic_version'
                    );
                """))
                
                table_exists = result.fetchone()[0]
                
                if table_exists:
                    print("Found existing alembic_version table. Checking current revision...")
                    result = conn.execute(text("SELECT version_num FROM alembic_version;"))
                    current_revision = result.fetchone()
                    if current_revision:
                        print(f"Current revision in database: {current_revision[0]}")
                        
                    print("Clearing alembic_version table...")
                    conn.execute(text("DELETE FROM alembic_version;"))
                    conn.commit()
                else:
                    print("No alembic_version table found.")
            
            print("Stamping database with initial migration...")
            # Stamp with the first migration
            stamp('21592d5001aa')
            
            print("Running remaining migrations...")
            upgrade()
            
            print("✅ Migration reset and upgrade completed successfully!")
            return True
            
        except Exception as e:
            print(f"❌ Migration failed: {str(e)}")
            import traceback
            traceback.print_exc()
            return False

if __name__ == '__main__':
    success = reset_and_migrate()
    sys.exit(0 if success else 1)
