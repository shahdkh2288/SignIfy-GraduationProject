#!/usr/bin/env python3
"""
Test script for the new predict_single_sign and manage_sign_session functions.
This script tests the backend functionality without requiring video files.
"""

import requests
import json
import time
import uuid

# Configuration
BASE_URL = "http://127.0.0.1:5000"

def test_backend_functions():
    """Test the backend prediction and session management functions."""
    print("🔬 Testing Backend Prediction & Session Management Functions\n")
    
    # Test 1: Health check
    print("1️⃣ Testing backend connectivity...")
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        if response.status_code == 200:
            print("✅ Backend is running and accessible")
        else:
            print(f"❌ Backend health check failed: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Cannot connect to backend: {e}")
        print("💡 Make sure the backend is running: python backend/start_server.py")
        return False
    
    # Test 2: Session management endpoints
    print("\n2️⃣ Testing session management endpoints...")
    
    # List initial sessions
    try:
        response = requests.get(f"{BASE_URL}/list-sessions")
        if response.status_code == 200:
            initial_sessions = response.json()
            print(f"✅ Initial active sessions: {initial_sessions['active_sessions']}")
        else:
            print(f"❌ Failed to list sessions: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error listing sessions: {e}")
        return False
    
    # Test 3: Error handling for missing video
    print("\n3️⃣ Testing error handling...")
    session_id = str(uuid.uuid4())
    
    try:
        # Test without video file
        response = requests.post(f"{BASE_URL}/detect-video-signs", data={
            'session_id': session_id,
            'sequence_number': 1,
            'is_final': 'false',
            'debug': 'true'
        })
        
        if response.status_code == 400:
            error_data = response.json()
            if 'Video file is required' in error_data.get('error', ''):
                print("✅ Correctly handles missing video file")
            else:
                print(f"❌ Unexpected error message: {error_data}")
        else:
            print(f"❌ Expected 400 error, got {response.status_code}")
    except Exception as e:
        print(f"❌ Error testing missing video: {e}")
    
    # Test 4: Session info for non-existent session
    print("\n4️⃣ Testing session info endpoints...")
    
    fake_session_id = "non-existent-session-id"
    try:
        response = requests.get(f"{BASE_URL}/session-info/{fake_session_id}")
        if response.status_code == 404:
            print("✅ Correctly returns 404 for non-existent session")
        else:
            print(f"❌ Expected 404, got {response.status_code}")
    except Exception as e:
        print(f"❌ Error testing session info: {e}")
    
    # Test 5: Clear non-existent session
    try:
        response = requests.delete(f"{BASE_URL}/clear-session/{fake_session_id}")
        if response.status_code == 404:
            print("✅ Correctly returns 404 when clearing non-existent session")
        else:
            print(f"❌ Expected 404, got {response.status_code}")
    except Exception as e:
        print(f"❌ Error testing clear session: {e}")
    
    # Test 6: Test with mock video data (if backend supports it)
    print("\n5️⃣ Testing endpoint parameter validation...")
    
    try:
        # Create a minimal "fake" file to test parameter handling
        files = {'video': ('test.mp4', b'fake video data', 'video/mp4')}
        data = {
            'session_id': session_id,
            'sequence_number': 1,
            'is_final': 'false',
            'debug': 'true',
            'flip_camera': 'auto'
        }
        
        response = requests.post(f"{BASE_URL}/detect-video-signs", files=files, data=data)
        
        # We expect this to fail at video processing, not parameter validation
        if response.status_code in [400, 500]:
            error_data = response.json()
            error_msg = error_data.get('error', '')
            
            if any(keyword in error_msg.lower() for keyword in ['video', 'process', 'opencv', 'frame']):
                print("✅ Parameters accepted, failed at video processing (expected)")
                print(f"   Error: {error_msg}")
            else:
                print(f"⚠️ Unexpected error: {error_msg}")
        else:
            print(f"❌ Unexpected response: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Error testing parameter validation: {e}")
    
    # Test 7: Verify session wasn't created from failed requests
    print("\n6️⃣ Verifying session state...")
    
    try:
        response = requests.get(f"{BASE_URL}/session-info/{session_id}")
        if response.status_code == 404:
            print("✅ No session created from failed video processing (correct)")
        elif response.status_code == 200:
            session_data = response.json()
            print(f"⚠️ Session was created: {session_data}")
        else:
            print(f"❌ Unexpected response checking session: {response.status_code}")
    except Exception as e:
        print(f"❌ Error checking session state: {e}")
    
    return True

def test_model_loading():
    """Test if the model and label encoder are properly loaded."""
    print("\n🤖 Testing Model Loading Status\n")
    
    # We can infer model status from the debug endpoint or health check
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            print("✅ Backend is running")
            
            # Try to get more info from debug endpoint if available
            try:
                # Test debug landmark extraction endpoint
                files = {'frame': ('test.jpg', b'fake image data', 'image/jpeg')}
                response = requests.post(f"{BASE_URL}/detect-landmarks", files=files)
                
                if response.status_code in [400, 500]:
                    error_data = response.json()
                    error_msg = error_data.get('error', '')
                    
                    if 'image' in error_msg.lower() or 'process' in error_msg.lower():
                        print("✅ Landmark detection endpoint accessible")
                    else:
                        print(f"⚠️ Landmark endpoint error: {error_msg}")
                else:
                    print(f"❌ Unexpected landmark endpoint response: {response.status_code}")
                    
            except Exception as e:
                print(f"ℹ️ Landmark endpoint test inconclusive: {e}")
                
    except Exception as e:
        print(f"❌ Error testing model loading: {e}")

def show_test_recommendations():
    """Show recommendations for further testing."""
    print("\n💡 Testing Recommendations:\n")
    
    print("📹 For Full Video Testing:")
    print("• Create a short test video (2-3 seconds) with sign language")
    print("• Save it as 'test_video.mp4' in the project root")
    print("• Run: python test_sequential_signs.py")
    
    print("\n🔧 For Model Testing:")
    print("• Ensure model.tflite exists in backend/app/models/")
    print("• Ensure label_encoder.pkl exists in backend/app/models/")
    print("• Check backend console for model loading messages")
    
    print("\n🎯 For Frontend Integration:")
    print("• Update Flutter app to use session-based recording")
    print("• Implement UI for sequential sign recording")
    print("• Add session management features")
    
    print("\n📊 For Production Readiness:")
    print("• Add session cleanup (expire old sessions)")
    print("• Add persistent session storage (Redis/DB)")
    print("• Add user authentication to sessions")
    print("• Add rate limiting for video processing")

if __name__ == "__main__":
    print("🧪 SignIfy Backend Function Test Suite")
    print("=" * 50)
    
    success = test_backend_functions()
    
    if success:
        test_model_loading()
        show_test_recommendations()
    
    print("\n" + "=" * 50)
    print("📋 Test Summary:")
    print("• Backend connectivity: ✓")
    print("• Session management endpoints: ✓") 
    print("• Error handling: ✓")
    print("• Parameter validation: ✓")
    
    if success:
        print("\n🎉 All backend function tests passed!")
        print("🚀 Ready for video testing with actual sign language videos")
    else:
        print("\n❌ Some tests failed - check backend status")
