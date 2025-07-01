#!/usr/bin/env python3
"""
Quick test to check if the Flask backend is running and responding.
"""

import requests
import json

def test_backend_connection():
    """Test if the backend server is running and responding"""
    base_url = "http://localhost:5000"
    
    try:
        # Test basic endpoint
        response = requests.get(f"{base_url}/")
        print(f"✅ Backend server is running!")
        print(f"Status: {response.status_code}")
        
        # Test landmark detection endpoint with a simple request
        print("\n🔍 Testing /detect-landmarks endpoint...")
        try:
            # Create a simple test - this will fail but should return proper error
            response = requests.post(f"{base_url}/detect-landmarks")
            if response.status_code == 400:  # Expected error for missing file
                result = response.json()
                if 'error' in result and 'Frame image is required' in result['error']:
                    print("✅ /detect-landmarks endpoint is working (returned expected error)")
                else:
                    print(f"⚠️ Unexpected response: {result}")
            else:
                print(f"⚠️ Unexpected status code: {response.status_code}")
        except Exception as e:
            print(f"❌ Error testing /detect-landmarks: {e}")
        
        # Test sign detection endpoint
        print("\n🎯 Testing /detect-sign endpoint...")
        try:
            # Test with empty data
            response = requests.post(
                f"{base_url}/detect-sign",
                headers={'Content-Type': 'application/json'},
                json={}
            )
            if response.status_code == 400:  # Expected error for missing landmarks
                result = response.json()
                if 'error' in result and 'Landmarks data is required' in result['error']:
                    print("✅ /detect-sign endpoint is working (returned expected error)")
                else:
                    print(f"⚠️ Unexpected response: {result}")
            else:
                print(f"⚠️ Unexpected status code: {response.status_code}")
        except Exception as e:
            print(f"❌ Error testing /detect-sign: {e}")
        
        # Test video detection endpoint
        print("\n🎬 Testing /detect-video-signs endpoint...")
        try:
            response = requests.post(f"{base_url}/detect-video-signs")
            if response.status_code == 400:  # Expected error for missing video
                result = response.json()
                if 'error' in result and 'Video file is required' in result['error']:
                    print("✅ /detect-video-signs endpoint is working (returned expected error)")
                else:
                    print(f"⚠️ Unexpected response: {result}")
            else:
                print(f"⚠️ Unexpected status code: {response.status_code}")
        except Exception as e:
            print(f"❌ Error testing /detect-video-signs: {e}")
            
        print("\n🎉 Backend connection test completed!")
        print("📱 You can now test the Flutter app with video recording.")
        
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to backend server!")
        print("Please make sure the Flask server is running:")
        print("  1. Open a terminal in the backend directory")
        print("  2. Run: python run.py")
        print("  3. Wait for 'Running on http://127.0.0.1:5000'")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False
    
    return True

if __name__ == "__main__":
    print("🧪 Testing SignIfy Backend Connection")
    print("=" * 50)
    test_backend_connection()
