#!/usr/bin/env python3
"""
Start server script for SignIfy backend
"""
import sys
import os
import argparse
from dotenv import load_dotenv

# Add the current directory to the Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Load environment variables
load_dotenv()

from app.app import create_app

def start_server(host='0.0.0.0', port=5000, debug=True):
    """Start the Flask server"""
    try:
        print("🚀 Starting SignIfy Backend Server...")
        print(f"📡 Server will be available at: http://{host}:{port}")
        
        # Create the Flask app
        app = create_app()
        
        # Import models to ensure they're registered
        from app.models import db, User, TTSPreferences, STTPreferences, Feedback, OTP
        
        print("✅ Models loaded successfully")
        print("📋 Available models: User, TTSPreferences, STTPreferences, Feedback, OTP")
        
        # Print some useful information
        print("\n📊 Server Configuration:")
        print(f"   • Host: {host}")
        print(f"   • Port: {port}")
        print(f"   • Debug Mode: {debug}")
        print(f"   • Database: Connected")
        
        print("\n🛠️  Available API Endpoints:")
        print("   • POST /register - User registration")
        print("   • POST /login - User login")
        print("   • POST /submit-feedback - Submit user feedback")
        print("   • GET /admin/all-feedback - Get all feedback (admin only)")
        print("   • POST /single-sign-detection - Single sign detection")
        print("   • POST /multi-sign-detection - Multi sign detection")
        print("   • And many more...")
        
        print("\n🔥 Starting server...")
        print("   Press Ctrl+C to stop the server")
        print("=" * 50)
        
        # Start the server
        app.run(
            host=host,
            port=port,
            debug=debug,
            use_reloader=debug,
            threaded=True
        )
        
    except KeyboardInterrupt:
        print("\n\n⛔ Server stopped by user")
    except Exception as e:
        print(f"\n❌ Error starting server: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

def main():
    """Main function with command line argument parsing"""
    parser = argparse.ArgumentParser(description='Start SignIfy Backend Server')
    parser.add_argument('--host', default='0.0.0.0', help='Host to bind to (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=5000, help='Port to bind to (default: 5000)')
    parser.add_argument('--no-debug', action='store_true', help='Disable debug mode')
    parser.add_argument('--production', action='store_true', help='Run in production mode (no debug, no reloader)')
    
    args = parser.parse_args()
    
    # Determine debug mode
    debug = not args.no_debug and not args.production
    
    if args.production:
        print("🏭 Running in PRODUCTION mode")
        debug = False
    
    start_server(
        host=args.host,
        port=args.port,
        debug=debug
    )

if __name__ == '__main__':
    main()
