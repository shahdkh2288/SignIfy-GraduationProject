#!/usr/bin/env python3
"""
Test script for sequential sign recording workflow.
Tests the new session-based multi-sign detection endpoint.
"""

import requests
import json
import time
import uuid
from pathlib import Path

# Configuration
BASE_URL = "http://127.0.0.1:5000"
VIDEO_PATH = "WhatsApp Video 2025-07-03 at 3.54.36 PM.mp4"  # You need to provide a test video

def test_sequential_sign_recording():
    """Test the sequential sign recording workflow."""
    print("🚀 Testing Sequential Sign Recording Workflow\n")
    
    # Generate a unique session ID
    session_id = str(uuid.uuid4())
    print(f"📝 Session ID: {session_id}\n")
    
    # Test 1: Check if backend is available
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        if response.status_code == 200:
            print("✅ Backend health check passed")
        else:
            print(f"❌ Backend health check failed: {response.status_code}")
            return
    except requests.exceptions.RequestException as e:
        print(f"❌ Cannot connect to backend: {e}")
        return
    
    # Test 2: List current sessions (should be empty initially)
    print("\n📋 Checking current sessions...")
    try:
        response = requests.get(f"{BASE_URL}/list-sessions")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Active sessions: {data['active_sessions']}")
            if data['sessions']:
                print("Current sessions:", json.dumps(data['sessions'], indent=2))
        else:
            print(f"❌ Failed to list sessions: {response.status_code}")
    except Exception as e:
        print(f"❌ Error listing sessions: {e}")
    
    # Test 3: Simulate sequential sign recording
    if not Path(VIDEO_PATH).exists():
        print(f"\n⚠️ Test video not found at {VIDEO_PATH}")
        print("Creating a mock test by calling the endpoint without actual video...")
        
        # Test the endpoint structure without video file
        test_params_sequence = [
            {"session_id": session_id, "sequence_number": 1, "is_final": False},
            {"session_id": session_id, "sequence_number": 2, "is_final": False}, 
            {"session_id": session_id, "sequence_number": 3, "is_final": True}
        ]
        
        for i, params in enumerate(test_params_sequence):
            print(f"\n🎬 Testing sign {params['sequence_number']} (final: {params['is_final']})")
            
            # Since we don't have a video, just test the session management endpoints
            if i == 0:
                # For first call, test with missing video to see the error handling
                try:
                    response = requests.post(f"{BASE_URL}/detect-video-signs", data=params)
                    print(f"Response status: {response.status_code}")
                    if response.status_code == 400:
                        data = response.json()
                        if 'Video file is required' in data.get('error', ''):
                            print("✅ Correctly detected missing video file")
                        else:
                            print(f"❌ Unexpected error: {data}")
                    else:
                        print(f"❌ Expected 400 error, got {response.status_code}")
                except Exception as e:
                    print(f"❌ Error testing endpoint: {e}")
    else:
        print(f"\n🎬 Found test video: {VIDEO_PATH}")
        print("Testing sequential sign recording with actual video...")
        
        # Test with actual video file
        test_sequence = [
            {"sequence_number": 1, "is_final": False, "debug": True},
            {"sequence_number": 2, "is_final": False, "debug": True},
            {"sequence_number": 3, "is_final": True, "debug": True}
        ]
        
        for params in test_sequence:
            print(f"\n🎬 Recording sign {params['sequence_number']} (final: {params['is_final']})")
            
            try:
                with open(VIDEO_PATH, 'rb') as video_file:
                    files = {'video': video_file}
                    data = {
                        'session_id': session_id,
                        'sequence_number': params['sequence_number'],
                        'is_final': str(params['is_final']).lower(),
                        'debug': str(params['debug']).lower(),
                        'flip_camera': 'auto'
                    }
                    
                    response = requests.post(f"{BASE_URL}/detect-video-signs", files=files, data=data)
                    
                    if response.status_code == 200:
                        result = response.json()
                        print(f"✅ Sign detected: '{result.get('word', 'N/A')}' (confidence: {result.get('confidence', 0):.2f})")
                        print(f"   Sequence: {result.get('sequence_number', 'N/A')}, Final: {result.get('is_final', 'N/A')}")
                        
                        if result.get('is_final'):
                            print(f"   🏁 Complete sentence: '{result.get('complete_sentence', 'N/A')}'")
                            print(f"   📊 Total signs: {result.get('total_signs', 0)}")
                            print(f"   📈 Overall confidence: {result.get('overall_confidence', 0):.2f}")
                        else:
                            print(f"   📝 Partial sentence: '{result.get('partial_sentence', 'N/A')}'")
                            print(f"   📊 Signs so far: {result.get('signs_so_far', 0)}")
                        
                        if params['debug'] and result.get('debug_info'):
                            print(f"   🔍 Debug: {len(result['debug_info'])} frames processed")
                    else:
                        print(f"❌ Request failed: {response.status_code}")
                        try:
                            error_data = response.json()
                            print(f"   Error: {error_data.get('error', 'Unknown error')}")
                        except:
                            print(f"   Raw response: {response.text}")
                            
            except Exception as e:
                print(f"❌ Error processing sign {params['sequence_number']}: {e}")
            
            # Small delay between requests
            time.sleep(1)
    
    # Test 4: Check session info
    print(f"\n📋 Checking session info for {session_id}...")
    try:
        response = requests.get(f"{BASE_URL}/session-info/{session_id}")
        if response.status_code == 200:
            session_data = response.json()
            print("✅ Session info retrieved:")
            print(f"   Sentence: '{session_data.get('sentence', 'N/A')}'")
            print(f"   Total signs: {session_data.get('total_signs', 0)}")
            print(f"   Overall confidence: {session_data.get('overall_confidence', 0):.2f}")
            print(f"   Complete: {session_data.get('is_complete', False)}")
            
            if session_data.get('signs'):
                print("   Signs breakdown:")
                for sign in session_data['signs']:
                    print(f"     {sign['sequence_number']}: {sign['word']} ({sign['confidence']:.2f})")
        elif response.status_code == 404:
            print("ℹ️ Session not found (expected if no video was processed)")
        else:
            print(f"❌ Failed to get session info: {response.status_code}")
    except Exception as e:
        print(f"❌ Error getting session info: {e}")
    
    # Test 5: List sessions again to see the new session
    print("\n📋 Checking sessions after recording...")
    try:
        response = requests.get(f"{BASE_URL}/list-sessions")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Active sessions: {data['active_sessions']}")
            if session_id in data['sessions']:
                session_info = data['sessions'][session_id]
                print(f"   Our session: '{session_info['sentence']}' ({session_info['total_signs']} signs)")
        else:
            print(f"❌ Failed to list sessions: {response.status_code}")
    except Exception as e:
        print(f"❌ Error listing sessions: {e}")
    
    # Test 6: Clear the session
    print(f"\n🧹 Clearing session {session_id}...")
    try:
        response = requests.delete(f"{BASE_URL}/clear-session/{session_id}")
        if response.status_code == 200:
            result = response.json()
            print(f"✅ {result.get('message', 'Session cleared')}")
        elif response.status_code == 404:
            print("ℹ️ Session not found (already cleared or never created)")
        else:
            print(f"❌ Failed to clear session: {response.status_code}")
    except Exception as e:
        print(f"❌ Error clearing session: {e}")
    
    print("\n🎯 Sequential Sign Recording Test Complete!")

def test_individual_endpoints():
    """Test individual session management endpoints."""
    print("\n🔧 Testing Individual Session Management Endpoints\n")
    
    # Test session info for non-existent session
    fake_session = "non-existent-session"
    try:
        response = requests.get(f"{BASE_URL}/session-info/{fake_session}")
        if response.status_code == 404:
            print("✅ Correctly returns 404 for non-existent session")
        else:
            print(f"❌ Expected 404, got {response.status_code}")
    except Exception as e:
        print(f"❌ Error testing non-existent session: {e}")
    
    # Test clearing non-existent session
    try:
        response = requests.delete(f"{BASE_URL}/clear-session/{fake_session}")
        if response.status_code == 404:
            print("✅ Correctly returns 404 when clearing non-existent session")
        else:
            print(f"❌ Expected 404, got {response.status_code}")
    except Exception as e:
        print(f"❌ Error testing clear non-existent session: {e}")

if __name__ == "__main__":
    print("🎯 SignIfy Sequential Sign Recording Test Suite")
    print("=" * 50)
    
    test_sequential_sign_recording()
    test_individual_endpoints()
    
    print("\n" + "=" * 50)
    print("📋 Test Summary:")
    print("• Sequential sign recording workflow tested")
    print("• Session management endpoints tested")
    print("• Error handling verified")
    print("\n💡 To test with actual video:")
    print(f"• Place a test video file at: {VIDEO_PATH}")
    print("• Run the script again")
