#!/usr/bin/env python3
"""
Test script for the "remove last word" functionality.
This script tests the new endpoint that removes only the last word from a session.
"""

import requests
import json
import time

# Backend base URL
BASE_URL = "http://127.0.0.1:5000"

def test_remove_last_word_functionality():
    """Test the remove last word from session functionality."""
    print("=== Testing Remove Last Word Functionality ===")
    
    # Generate a test session ID
    session_id = str(int(time.time() * 1000))
    print(f"Test session ID: {session_id}")
    
    # Simulate adding words to a session by calling the detect-video-signs endpoint
    # with mock data (we'll use empty video data since we're testing session management)
    
    print("\n1. Simulating adding words to session...")
    
    # We'll simulate having words in the session by making multiple calls
    # Since we don't have actual video files, we'll need to check if the endpoint
    # can handle the session management part
    
    # First, let's check if we can get session info (should return 404 for new session)
    response = requests.get(f"{BASE_URL}/session-info/{session_id}")
    print(f"Initial session info: {response.status_code}")
    
    # Since we can't easily add words without video files, let's test the remove endpoint
    # directly to see how it handles edge cases
    
    print("\n2. Testing remove last word from empty session...")
    response = requests.delete(f"{BASE_URL}/remove-last-word-from-session/{session_id}")
    print(f"Status: {response.status_code}")
    if response.status_code != 200:
        print(f"Response: {response.json()}")
    
    print("\n3. Testing remove last word from non-existent session...")
    fake_session_id = "fake_session_123"
    response = requests.delete(f"{BASE_URL}/remove-last-word-from-session/{fake_session_id}")
    print(f"Status: {response.status_code}")
    if response.status_code != 200:
        print(f"Response: {response.json()}")
    
    print("\n4. Testing health check...")
    response = requests.get(f"{BASE_URL}/health")
    if response.status_code == 200:
        health_data = response.json()
        print(f"Server status: {health_data['status']}")
        print(f"Active sessions: {health_data['active_sessions']}")
    else:
        print(f"Health check failed: {response.status_code}")
    
    print("\n5. Testing list sessions...")
    response = requests.get(f"{BASE_URL}/list-sessions")
    if response.status_code == 200:
        sessions_data = response.json()
        print(f"Active sessions count: {sessions_data['active_sessions']}")
        print(f"Sessions: {sessions_data['sessions']}")
    else:
        print(f"List sessions failed: {response.status_code}")

def test_endpoint_availability():
    """Test if the new endpoint is available."""
    print("\n=== Testing Endpoint Availability ===")
    
    # Test with a dummy session ID to see if the endpoint exists
    test_session = "test_123"
    
    try:
        response = requests.delete(f"{BASE_URL}/remove-last-word-from-session/{test_session}")
        print(f"Remove last word endpoint available: {response.status_code}")
        if response.status_code in [200, 404, 400]:  # These are expected responses
            print("✓ Endpoint is working (404/400 expected for non-existent session)")
        else:
            print(f"✗ Unexpected response: {response.status_code}")
    except requests.exceptions.ConnectionError:
        print("✗ Cannot connect to backend server. Is it running on port 5000?")
        return False
    except Exception as e:
        print(f"✗ Error testing endpoint: {e}")
        return False
    
    return True

if __name__ == "__main__":
    print("Remove Last Word Functionality Test")
    print("=" * 50)
    
    # First check if the backend is running
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        if response.status_code == 200:
            print("✓ Backend server is running")
        else:
            print(f"✗ Backend server returned unexpected status: {response.status_code}")
            exit(1)
    except requests.exceptions.ConnectionError:
        print("✗ Cannot connect to backend server.")
        print("Please make sure the backend server is running on port 5000")
        print("Run: cd backend && python start_server.py")
        exit(1)
    except Exception as e:
        print(f"✗ Error connecting to backend: {e}")
        exit(1)
    
    # Test endpoint availability
    if test_endpoint_availability():
        # Run main functionality tests
        test_remove_last_word_functionality()
        
        print("\n" + "=" * 50)
        print("Test completed!")
        print("\nTo test the full functionality:")
        print("1. Start the Flutter app")
        print("2. Go to Sequential Sign Recording")
        print("3. Record some signs")
        print("4. Use the 'Undo Last Word' button to remove the last word")
        print("5. Check that only the last word is removed")
    else:
        print("✗ Endpoint tests failed")
