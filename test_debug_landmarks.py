"""
Test script for debugging landmark extraction from video.
This script tests the new debug endpoints to verify landmark extraction.
"""

import requests
import json
import os

# Backend URL (adjust if needed)
BASE_URL = "http://127.0.0.1:5000"

def test_debug_video_landmarks():
    """Test the debug video landmarks endpoint."""
    # You would need to provide a test video file
    test_video_path = "test_video.mp4"  # Replace with actual test video path
    
    if not os.path.exists(test_video_path):
        print(f"Test video not found: {test_video_path}")
        print("Please provide a test video file to test the debugging functionality.")
        return
    
    print("Testing debug video landmarks endpoint...")
    
    # Test with debug mode
    with open(test_video_path, 'rb') as video_file:
        files = {'video': video_file}
        data = {
            'max_frames': '20',  # Limit frames for testing
            'include_raw_landmarks': 'false'  # Set to 'true' if you want raw landmarks
        }
        
        try:
            response = requests.post(f"{BASE_URL}/debug-video-landmarks", files=files, data=data)
            
            if response.status_code == 200:
                result = response.json()
                print("\n=== DEBUG ANALYSIS RESULTS ===")
                print(f"Video Info: {json.dumps(result['video_info'], indent=2)}")
                print(f"Landmark Analysis: {json.dumps(result['landmark_analysis'], indent=2)}")
                print(f"Model Requirements: {json.dumps(result['model_requirements'], indent=2)}")
                print(f"Message: {result['message']}")
                
                # Show frame details summary
                frame_details = result['frame_details']
                print(f"\nFrame Details Summary:")
                print(f"Total frames analyzed: {len(frame_details)}")
                frames_with_landmarks = sum(1 for frame in frame_details if frame['landmarks_detected'])
                print(f"Frames with landmarks: {frames_with_landmarks}")
                print(f"Detection rate: {frames_with_landmarks/len(frame_details)*100:.1f}%")
                
                # Show sample frame analysis
                if frame_details:
                    print(f"\nSample frame analysis (first frame):")
                    print(json.dumps(frame_details[0], indent=2))
                    
            else:
                print(f"Error: {response.status_code}")
                print(response.text)
                
        except Exception as e:
            print(f"Request failed: {e}")

def test_video_detection_with_debug():
    """Test the regular video detection endpoint with debug mode."""
    test_video_path = "test_video.mp4"  # Replace with actual test video path
    
    if not os.path.exists(test_video_path):
        print(f"Test video not found: {test_video_path}")
        return
    
    print("\nTesting video detection with debug mode...")
    
    with open(test_video_path, 'rb') as video_file:
        files = {'video': video_file}
        data = {'debug': 'true'}
        
        try:
            response = requests.post(f"{BASE_URL}/detect-video-signs", files=files, data=data)
            
            if response.status_code == 200:
                result = response.json()
                print("\n=== VIDEO DETECTION WITH DEBUG ===")
                print(f"Predicted word: {result['word']}")
                print(f"Confidence: {result['confidence']}")
                print(f"Frames processed: {result['frames_processed']}")
                
                if result.get('debug_info'):
                    print(f"Debug info available for {len(result['debug_info'])} frames")
                    print(f"Sequence shape: {result.get('sequence_shape')}")
                    print(f"Padded shape: {result.get('padded_shape')}")
                    print(f"Model input shape: {result.get('model_input_shape')}")
                    
                    # Show sample debug info
                    if result['debug_info']:
                        print(f"\nSample debug info (first frame):")
                        print(json.dumps(result['debug_info'][0], indent=2))
                        
            else:
                print(f"Error: {response.status_code}")
                print(response.text)
                
        except Exception as e:
            print(f"Request failed: {e}")

def check_server_status():
    """Check if the backend server is running."""
    try:
        response = requests.get(f"{BASE_URL}/")
        print(f"Server status: {response.status_code}")
        return response.status_code == 200
    except Exception as e:
        print(f"Server not accessible: {e}")
        return False

if __name__ == "__main__":
    print("Sign Language Recognition - Debug Test Script")
    print("=" * 50)
    
    # Check server status
    if not check_server_status():
        print("Backend server is not running. Please start it first:")
        print("cd backend && python run.py")
        exit(1)
    
    print("Server is running. Starting debug tests...")
    
    # Run tests
    test_debug_video_landmarks()
    test_video_detection_with_debug()
    
    print("\n" + "=" * 50)
    print("Debug tests completed!")
    print("\nHow to use the debug endpoints:")
    print("1. /debug-video-landmarks - Get detailed landmark analysis")
    print("2. /detect-video-signs with debug=true - Get debug info with prediction")
    print("\nParameters for debugging:")
    print("- max_frames: Limit number of frames to process")
    print("- include_raw_landmarks: Include raw landmark coordinates (warning: large)")
    print("- debug: Enable debug mode in regular prediction endpoint")
