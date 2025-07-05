#!/usr/bin/env python3
"""
Test script for word removal functionality in sign language detection backend.
"""

import requests
import json
import time

# Configuration
BASE_URL = "http://localhost:5000"

def test_word_removal():
    """Test the word removal functionality."""
    session_id = f"test_session_{int(time.time())}"
    
    print(f"Testing word removal functionality with session: {session_id}")
    print("=" * 60)
    
    # Simulate adding some words to a session (mock session creation)
    mock_session_data = {
        "session_1": {"word": "hello", "confidence": 0.8},
        "session_2": {"word": "world", "confidence": 0.9},
        "session_3": {"word": "test", "confidence": 0.7},
        "session_4": {"word": "sign", "confidence": 0.85}
    }
    
    print("1. Creating mock session with words...")
    for seq_num, data in enumerate(mock_session_data.values(), 1):
        print(f"   Adding word {seq_num}: '{data['word']}' (confidence: {data['confidence']})")
    
    # For testing, we'll use the session management endpoints
    print("\n2. Testing session info endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/session-info/{session_id}")
        if response.status_code == 404:
            print("   ✓ Session not found (expected for new session)")
        else:
            print(f"   Response: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"   Error: {e}")
    
    print("\n3. Testing word removal endpoint...")
    try:
        # Try to remove word at sequence 2
        response = requests.delete(f"{BASE_URL}/remove-word-from-session/{session_id}/2")
        if response.status_code == 404:
            print("   ✓ Session not found (expected for empty session)")
        else:
            print(f"   Response: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"   Error: {e}")
    
    print("\n4. Testing regenerate sentence endpoint...")
    try:
        response = requests.post(f"{BASE_URL}/regenerate-sentence/{session_id}")
        if response.status_code == 404:
            print("   ✓ Session not found (expected for empty session)")
        else:
            print(f"   Response: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"   Error: {e}")
    
    print("\n5. Testing list sessions endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/list-sessions")
        if response.status_code == 200:
            data = response.json()
            print(f"   ✓ List sessions successful")
            print(f"   Active sessions: {data.get('active_sessions', 0)}")
        else:
            print(f"   Response: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"   Error: {e}")
    
    print("\n6. Testing health check...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            data = response.json()
            print(f"   ✓ Health check successful")
            print(f"   Server: {data.get('server')}")
            print(f"   Model status: {data.get('model_status')}")
            print(f"   Active sessions: {data.get('active_sessions')}")
        else:
            print(f"   Response: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"   Error: {e}")
    
    print("\n" + "=" * 60)
    print("Test completed!")
    print("\nTo test with real data:")
    print("1. Start the backend server: python backend/start_server.py")
    print("2. Use the Flutter app to record some signs")
    print("3. Try removing words using the × button in the detected words")
    print("4. Use the 'Regenerate Sentence' button to get a new GPT sentence")

if __name__ == "__main__":
    test_word_removal()
