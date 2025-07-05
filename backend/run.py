#!/usr/bin/env python3
"""
Simple Flask app runner for SignIfy backend.
"""

import os
import sys

# Add current directory to Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

try:
    from app.app import create_app
    app = create_app()
    
    if __name__ == '__main__':
        print("🚀 Starting SignIfy Flask Server...")
        print("📍 Available endpoints:")
        print("  - /detect-video-signs (POST) - Main sign detection")
        print("  - Session management endpoints")
        print("  - User authentication endpoints")
        print("📊 Server running on http://0.0.0.0:5000")
        print("🌐 Accessible from network at http://192.168.1.3:5000")
        app.run(debug=True, host='0.0.0.0', port=5000)
        
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("Make sure you're in the backend directory and all dependencies are installed.")
except Exception as e:
    print(f"❌ Error starting server: {e}")
