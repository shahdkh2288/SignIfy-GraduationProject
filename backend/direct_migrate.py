#!/usr/bin/env python3
"""
Script to directly execute SQL migrations
"""
import sys
import os

# Add the current directory to the Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.app import create_app
from sqlalchemy import text

def run_direct_migration():
    """Run migrations by directly executing SQL"""
    app = create_app()
    
    with app.app_context():
        try:
            # Import db from the app
            from app.models import db
            
            print("Checking database connection...")
            
            with db.engine.connect() as conn:
                # Clear any existing alembic version
                print("Clearing alembic_version table...")
                conn.execute(text("DROP TABLE IF EXISTS alembic_version;"))
                conn.commit()
                
                # Create all tables based on current models
                print("Creating tables from models...")
                db.create_all()
                
                # Create alembic_version table and set it to the latest migration
                print("Setting up alembic version tracking...")
                conn.execute(text("""
                    CREATE TABLE IF NOT EXISTS alembic_version (
                        version_num VARCHAR(32) NOT NULL,
                        CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num)
                    );
                """))
                
                # Insert the latest migration version
                conn.execute(text("DELETE FROM alembic_version;"))
                conn.execute(text("INSERT INTO alembic_version (version_num) VALUES ('feedback_table_001');"))
                conn.commit()
                
                print("✅ Database setup completed successfully!")
                print("All tables created and migration state set to latest version.")
                return True
            
        except Exception as e:
            print(f"❌ Migration failed: {str(e)}")
            import traceback
            traceback.print_exc()
            return False

if __name__ == '__main__':
    success = run_direct_migration()
    sys.exit(0 if success else 1)
