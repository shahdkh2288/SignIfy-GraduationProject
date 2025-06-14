from app import app
from app.models import db
import sqlite3

def check_db_structure():
    conn = sqlite3.connect('app.db')
    cursor = conn.cursor()
    
    # Get table info for user table
    cursor.execute("PRAGMA table_info(user);")
    columns = cursor.fetchall()
    
    print("\nUser table structure:")
    for col in columns:
        print(f"Column: {col[1]}, Type: {col[2]}, Nullable: {not col[3]}")
    
    conn.close()

if __name__ == '__main__':
    check_db_structure()
