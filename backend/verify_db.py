#!/usr/bin/env python3
"""
Script to verify database setup
"""
import sys
import os

# Add the current directory to the Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.app import create_app
from sqlalchemy import text

def verify_database():
    """Verify database setup"""
    app = create_app()
    
    with app.app_context():
        try:
            from app.models import db
            
            print("Verifying database setup...")
            
            with db.engine.connect() as conn:
                # Check tables
                result = conn.execute(text("""
                    SELECT table_name 
                    FROM information_schema.tables 
                    WHERE table_schema = 'public'
                    ORDER BY table_name;
                """))
                
                tables = [row[0] for row in result.fetchall()]
                
                print("\n📋 Tables in database:")
                for table in tables:
                    print(f"  ✓ {table}")
                
                # Check feedback table structure
                if 'feedback' in tables:
                    print("\n🔍 Feedback table structure:")
                    result = conn.execute(text("""
                        SELECT column_name, data_type, is_nullable
                        FROM information_schema.columns
                        WHERE table_name = 'feedback'
                        ORDER BY ordinal_position;
                    """))
                    
                    for row in result.fetchall():
                        nullable = "NULL" if row[2] == "YES" else "NOT NULL"
                        print(f"  • {row[0]} ({row[1]}) {nullable}")
                
                # Check alembic version
                result = conn.execute(text("SELECT version_num FROM alembic_version;"))
                version = result.fetchone()
                if version:
                    print(f"\n📌 Current migration version: {version[0]}")
                
                print("\n✅ Database verification completed successfully!")
                return True
            
        except Exception as e:
            print(f"❌ Verification failed: {str(e)}")
            return False

if __name__ == '__main__':
    verify_database()
