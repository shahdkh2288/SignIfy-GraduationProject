#!/usr/bin/env python3
"""
Test script for the unified /detect-video-signs endpoint with camera flip support
"""
import requests
import json
import sys
import os

# Configuration
BASE_URL = "http://127.0.0.1:5000"

def test_health():
    """Test health endpoint"""
    print("=== Testing Health Endpoint ===")
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print(f"Response: {response.json()}")
            return True
    except Exception as e:
        print(f"Health check failed: {e}")
    return False

def test_video_detection(video_path=None, flip_camera='auto', debug=True):
    """Test the unified video detection endpoint"""
    print(f"\n=== Testing /detect-video-signs ===")
    print(f"Flip camera mode: {flip_camera}")
    print(f"Debug mode: {debug}")
    
    # Create a dummy video file if none provided
    if not video_path:
        print("No video file provided. You can test with an actual video file.")
        return False
    
    if not os.path.exists(video_path):
        print(f"Video file not found: {video_path}")
        return False
    
    try:
        # Prepare multipart form data
        with open(video_path, 'rb') as video_file:
            files = {'video': ('test_video.mp4', video_file, 'video/mp4')}
            data = {
                'debug': str(debug).lower(),
                'flip_camera': flip_camera
            }
            
            print("Uploading and processing video...")
            response = requests.post(
                f"{BASE_URL}/detect-video-signs",
                files=files,
                data=data,
                timeout=30  # 30 second timeout for video processing
            )
            
            print(f"Status Code: {response.status_code}")
            
            if response.status_code == 200:
                result = response.json()
                print("✅ Video detection successful!")
                print(f"Detected words: {result.get('words', [])}")
                print(f"Sentence: {result.get('sentence', '')}")
                print(f"Total segments: {result.get('total_segments', 0)}")
                print(f"Overall confidence: {result.get('overall_confidence', 0)}")
                print(f"Camera flip applied: {result.get('camera_flip_applied', False)}")
                print(f"Frames processed: {result.get('total_frames_processed', 0)}")
                
                # Show segment details
                segments = result.get('segments', [])
                if segments:
                    print("\nSegment Details:")
                    for seg in segments:
                        print(f"  Segment {seg['segment_id']}: '{seg['word']}' "
                              f"(confidence: {seg['confidence']:.2f}, "
                              f"frames: {seg['frame_count']})")
                
                # Show debug info if available
                if debug and result.get('debug_info'):
                    debug_info = result['debug_info']
                    print(f"\nDebug Info: {len(debug_info)} frames analyzed")
                    if debug_info:
                        first_frame = debug_info[0]
                        print(f"  First frame landmarks: {first_frame.get('landmarks_count', 'N/A')}")
                        print(f"  Flip applied: {first_frame.get('flip_applied', False)}")
                
                return True
            else:
                print(f"❌ Error: {response.text}")
                return False
                
    except Exception as e:
        print(f"❌ Exception during video detection: {e}")
        return False

def test_different_flip_modes():
    """Test different camera flip modes"""
    print("\n=== Testing Different Camera Flip Modes ===")
    
    # This would need an actual video file to test properly
    video_path = "test_video.mp4"  # Replace with actual video path
    
    flip_modes = ['auto', 'true', 'false']
    
    for flip_mode in flip_modes:
        print(f"\n--- Testing flip_camera='{flip_mode}' ---")
        if os.path.exists(video_path):
            test_video_detection(video_path, flip_camera=flip_mode, debug=False)
        else:
            print(f"Skipped (no video file: {video_path})")

def main():
    print("Testing Unified Video Sign Detection Endpoint")
    print("============================================")
    
    # Test health first
    if not test_health():
        print("❌ Server is not responding. Please start the backend server first.")
        sys.exit(1)
    
    print("✅ Server is healthy")
    
    # Test video detection with different scenarios
    print("\n=== Available Test Scenarios ===")
    print("1. Test with debug mode and auto flip")
    print("2. Test with forced camera flip")
    print("3. Test with no camera flip")
    
    # For actual testing, you would provide a real video file path
    sample_video_path = "sample_sign_video.mp4"  # Replace with actual path
    
    if os.path.exists(sample_video_path):
        print(f"\nTesting with video: {sample_video_path}")
        
        # Test 1: Auto flip with debug
        print("\n--- Test 1: Auto flip with debug ---")
        test_video_detection(sample_video_path, flip_camera='auto', debug=True)
        
        # Test 2: Force flip
        print("\n--- Test 2: Force camera flip ---")
        test_video_detection(sample_video_path, flip_camera='true', debug=False)
        
        # Test 3: No flip
        print("\n--- Test 3: No camera flip ---")
        test_video_detection(sample_video_path, flip_camera='false', debug=False)
        
    else:
        print(f"\n⚠️  Sample video not found: {sample_video_path}")
        print("To test with your own video:")
        print("1. Place a video file in the same directory as this script")
        print("2. Update the 'sample_video_path' variable with your video filename")
        print("3. Run this script again")
    
    print("\n=== Endpoint Summary ===")
    print("✅ Unified video detection endpoint: /detect-video-signs")
    print("📹 Supports multiple word sequences")
    print("🔄 Camera flip correction (auto/true/false)")
    print("🐛 Debug mode for detailed analysis")
    print("📊 Automatic video segmentation")
    print("🎯 Confidence scoring per segment")
    
    print("\n=== Usage Examples ===")
    print("curl -X POST http://127.0.0.1:5000/detect-video-signs \\")
    print("  -F 'video=@your_video.mp4' \\")
    print("  -F 'flip_camera=true' \\")
    print("  -F 'debug=true'")

if __name__ == "__main__":
    main()
