#!/usr/bin/env python3
"""
Test script for WhatsApp video file against the /detect-video-signs endpoint
This will test the video with debug mode enabled to verify landmark extraction
"""

import requests
import os
import json
import time
from pathlib import Path

# Configuration
BACKEND_URL = "http://localhost:5000"  # Adjust if your backend runs on a different port
VIDEO_FILENAME = "WhatsApp Video 2025-07-01 at 6.41.40 PM.mp4"

def test_video_detection():
    """Test the WhatsApp video file with the backend detection endpoint."""
    
    # Find the video file in the project root
    project_root = Path(__file__).parent
    video_path = project_root / VIDEO_FILENAME
    
    if not video_path.exists():
        print(f"❌ Video file not found: {video_path}")
        print("Make sure the video file is in the project root directory")
        return False
    
    print(f"📹 Testing video: {video_path}")
    print(f"📊 File size: {video_path.stat().st_size / (1024*1024):.2f} MB")
    
    # Test endpoint URL
    endpoint_url = f"{BACKEND_URL}/detect-video-signs"
    
    try:
        # Prepare the request with debug mode enabled
        with open(video_path, 'rb') as video_file:
            files = {
                'video': (VIDEO_FILENAME, video_file, 'video/mp4')
            }
            data = {
                'debug': 'true'  # Enable debug mode to get detailed landmark info
            }
            
            print(f"🚀 Sending request to: {endpoint_url}")
            print("⚙️ Debug mode: ENABLED")
            print("⏳ Processing video... (this may take a moment)")
            
            start_time = time.time()
            response = requests.post(endpoint_url, files=files, data=data, timeout=120)
            end_time = time.time()
            
            print(f"⏱️ Processing time: {end_time - start_time:.2f} seconds")
            print(f"📡 Response status: {response.status_code}")
            
            if response.status_code == 200:
                result = response.json()
                print("\n✅ SUCCESS! Video processed successfully")
                print("=" * 60)
                
                # Main prediction results
                print(f"🎯 Predicted Word: '{result.get('word', 'N/A')}'")
                print(f"🎲 Confidence: {result.get('confidence', 0):.4f}")
                print(f"🎞️ Frames Processed: {result.get('frames_processed', 0)}")
                
                # Debug information
                if result.get('debug_info'):
                    debug_info = result['debug_info']
                    print(f"\n📊 DEBUG INFORMATION:")
                    print(f"   Total frames with debug info: {len(debug_info)}")
                    
                    # Show first few frames' debug info
                    for i, frame_debug in enumerate(debug_info[:5]):
                        print(f"\n   Frame {frame_debug.get('frame_number', i+1)}:")
                        if frame_debug.get('landmarks_detected', True):
                            print(f"     - Landmarks shape: {frame_debug.get('landmarks_shape', 'N/A')}")
                            print(f"     - Landmarks count: {frame_debug.get('landmarks_count', 'N/A')}")
                            print(f"     - Non-zero landmarks: {frame_debug.get('non_zero_landmarks', 'N/A')}")
                            print(f"     - Mean value: {frame_debug.get('landmarks_mean', 0):.6f}")
                            print(f"     - Std deviation: {frame_debug.get('landmarks_std', 0):.6f}")
                        else:
                            print(f"     - ❌ No landmarks detected")
                    
                    if len(debug_info) > 5:
                        print(f"   ... and {len(debug_info) - 5} more frames")
                
                # Shape information
                if result.get('sequence_shape'):
                    print(f"\n📏 SHAPE INFORMATION:")
                    print(f"   Original sequence shape: {result['sequence_shape']}")
                    print(f"   Padded sequence shape: {result.get('padded_shape', 'N/A')}")
                    print(f"   Model input shape: {result.get('model_input_shape', 'N/A')}")
                
                print("=" * 60)
                
                # Save detailed results to file
                output_file = f"video_test_results_{int(time.time())}.json"
                with open(output_file, 'w') as f:
                    json.dump(result, f, indent=2)
                print(f"💾 Detailed results saved to: {output_file}")
                
                return True
                
            else:
                print(f"\n❌ ERROR! Status code: {response.status_code}")
                try:
                    error_result = response.json()
                    print(f"Error message: {error_result.get('error', 'Unknown error')}")
                except:
                    print(f"Response text: {response.text}")
                return False
                
    except requests.exceptions.Timeout:
        print("❌ Request timed out. The video might be too long or the server is slow.")
        return False
    except requests.exceptions.ConnectionError:
        print(f"❌ Could not connect to backend at {BACKEND_URL}")
        print("Make sure the backend server is running!")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {str(e)}")
        return False

def test_backend_connection():
    """Test if the backend is accessible."""
    try:
        response = requests.get(f"{BACKEND_URL}/", timeout=5)
        return True
    except:
        return False

if __name__ == "__main__":
    print("🧪 WhatsApp Video Sign Detection Test")
    print("=" * 60)
    
    # Check backend connection first
    print("🔍 Checking backend connection...")
    if not test_backend_connection():
        print(f"❌ Cannot reach backend at {BACKEND_URL}")
        print("Please make sure the Flask backend is running:")
        print("  cd backend")
        print("  python run.py")
        exit(1)
    
    print("✅ Backend is accessible")
    
    # Run the video test
    success = test_video_detection()
    
    if success:
        print("\n🎉 Test completed successfully!")
        print("Check the detailed results in the JSON file for complete landmark analysis.")
    else:
        print("\n💥 Test failed. Check the error messages above.")
