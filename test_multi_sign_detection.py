#!/usr/bin/env python3
"""
Test script for multi-sign video detection endpoint.
Tests the new /detect-multiple-signs endpoint with various scenarios.
"""

import requests
import numpy as np
import cv2
import json
import time
import os

def create_test_video_with_motion_patterns():
    """Create a test video that simulates multiple signs with motion and pauses."""
    # Create a simple video with different motion patterns
    width, height = 320, 240
    fps = 30
    duration_per_sign = 2  # seconds per sign
    pause_duration = 1     # seconds pause between signs
    num_signs = 3
    
    # Calculate total frames
    frames_per_sign = int(fps * duration_per_sign)
    frames_per_pause = int(fps * pause_duration)
    total_frames = (frames_per_sign + frames_per_pause) * num_signs
    
    # Create video writer
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    video_path = 'test_multi_signs.mp4'
    out = cv2.VideoWriter(video_path, fourcc, fps, (width, height))
    
    print(f"Creating test video with {num_signs} signs...")
    print(f"  - {frames_per_sign} frames per sign ({duration_per_sign}s)")
    print(f"  - {frames_per_pause} frames per pause ({pause_duration}s)")
    print(f"  - Total: {total_frames} frames")
    
    frame_count = 0
    
    for sign_num in range(num_signs):
        print(f"  Creating sign {sign_num + 1}...")
        
        # Generate sign frames (with motion)
        for frame_in_sign in range(frames_per_sign):
            frame = np.zeros((height, width, 3), dtype=np.uint8)
            
            # Create a moving hand-like object
            t = frame_in_sign / frames_per_sign
            
            # Different motion patterns for different signs
            if sign_num == 0:  # Circular motion
                center_x = int(width/2 + 50 * np.cos(t * 4 * np.pi))
                center_y = int(height/2 + 30 * np.sin(t * 4 * np.pi))
            elif sign_num == 1:  # Horizontal motion
                center_x = int(width/4 + (width/2) * t)
                center_y = int(height/2)
            else:  # Vertical motion
                center_x = int(width/2)
                center_y = int(height/4 + (height/2) * t)
            
            # Draw hand-like shape
            cv2.circle(frame, (center_x, center_y), 30, (255, 200, 150), -1)
            cv2.circle(frame, (center_x-10, center_y-10), 8, (255, 180, 130), -1)
            cv2.circle(frame, (center_x+10, center_y-10), 8, (255, 180, 130), -1)
            cv2.circle(frame, (center_x, center_y+15), 8, (255, 180, 130), -1)
            
            out.write(frame)
            frame_count += 1
        
        # Generate pause frames (minimal motion)
        if sign_num < num_signs - 1:  # Don't add pause after last sign
            print(f"  Adding pause after sign {sign_num + 1}...")
            for frame_in_pause in range(frames_per_pause):
                frame = np.zeros((height, width, 3), dtype=np.uint8)
                
                # Static hand position with minimal movement
                center_x = int(width/2 + 2 * np.sin(frame_in_pause * 0.1))
                center_y = int(height/2 + 2 * np.cos(frame_in_pause * 0.1))
                
                # Draw static hand
                cv2.circle(frame, (center_x, center_y), 30, (200, 150, 100), -1)
                
                out.write(frame)
                frame_count += 1
    
    out.release()
    print(f"Test video created: {video_path} ({frame_count} frames)")
    return video_path

def test_multi_sign_detection():
    """Test the /detect-multiple-signs endpoint."""
    base_url = "http://localhost:5000"
    
    print("🎬 Testing Multi-Sign Detection Endpoint")
    print("=" * 50)
    
    try:
        # Create test video
        video_path = create_test_video_with_motion_patterns()
        
        # Test multi-sign detection
        print("\n1. Testing multi-sign video detection...")
        
        with open(video_path, 'rb') as video_file:
            files = {'video': video_file}
            response = requests.post(f"{base_url}/detect-multiple-signs", files=files)
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Multi-sign detection successful!")
            
            # Display results
            words = result.get('words', [])
            sentence = result.get('sentence', '')
            segments = result.get('segments', [])
            total_segments = result.get('total_segments', 0)
            
            print(f"\n📊 Results:")
            print(f"  Words detected: {words}")
            print(f"  Complete sentence: '{sentence}'")
            print(f"  Total segments: {total_segments}")
            print(f"  Total frames processed: {result.get('total_frames_processed', 'N/A')}")
            print(f"  Video duration: {result.get('video_duration', 'N/A')}s")
            
            if segments:
                print(f"\n🔍 Segment Details:")
                for segment in segments:
                    print(f"    Segment {segment['segment_id']}: '{segment['word']}' "
                          f"(confidence: {segment['confidence']:.3f}, "
                          f"frames: {segment['frame_count']})")
            
        else:
            print(f"❌ Multi-sign detection failed: {response.status_code}")
            try:
                error_info = response.json()
                print(f"   Error: {error_info.get('error', 'Unknown error')}")
            except:
                print(f"   Response: {response.text}")
        
        # Compare with single-sign detection
        print("\n2. Comparing with single-sign detection...")
        
        with open(video_path, 'rb') as video_file:
            files = {'video': video_file}
            response = requests.post(f"{base_url}/detect-video-signs", files=files)
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Single-sign detection:")
            print(f"  Word: '{result.get('word', 'N/A')}'")
            print(f"  Confidence: {result.get('confidence', 'N/A')}")
            print(f"  Frames processed: {result.get('frames_processed', 'N/A')}")
        else:
            print(f"❌ Single-sign detection failed: {response.status_code}")
        
        # Clean up
        os.remove(video_path)
        print(f"\n🧹 Cleaned up test video: {video_path}")
        
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to backend server!")
        print("Please make sure the Flask server is running on port 5000")
    except Exception as e:
        print(f"❌ Test failed: {e}")
        import traceback
        traceback.print_exc()

def test_edge_cases():
    """Test edge cases for multi-sign detection."""
    base_url = "http://localhost:5000"
    
    print("\n🧪 Testing Edge Cases")
    print("=" * 30)
    
    # Test 1: No video file
    print("1. Testing missing video file...")
    try:
        response = requests.post(f"{base_url}/detect-multiple-signs")
        if response.status_code == 400:
            error = response.json()
            if 'Video file is required' in error.get('error', ''):
                print("✅ Properly handles missing video file")
            else:
                print(f"⚠️ Unexpected error message: {error}")
        else:
            print(f"⚠️ Unexpected status code: {response.status_code}")
    except Exception as e:
        print(f"❌ Test failed: {e}")
    
    # Test 2: Empty video file
    print("\n2. Testing empty video file...")
    try:
        files = {'video': ('empty.mp4', b'', 'video/mp4')}
        response = requests.post(f"{base_url}/detect-multiple-signs", files=files)
        print(f"   Status: {response.status_code}")
        if response.status_code != 200:
            try:
                error = response.json()
                print(f"   Error: {error.get('error', 'Unknown')}")
            except:
                print(f"   Response: {response.text[:100]}...")
    except Exception as e:
        print(f"❌ Test failed: {e}")

if __name__ == "__main__":
    print("🚀 SignIfy Multi-Sign Detection Testing")
    print("Make sure your Flask server is running!")
    print()
    
    test_multi_sign_detection()
    test_edge_cases()
    
    print("\n🎉 Multi-sign detection testing completed!")
    print("\n📱 Next Steps:")
    print("1. Test the Flutter app with the enhanced video recording")
    print("2. Record a video with multiple signs separated by pauses")
    print("3. See automatic segmentation and detection in action!")
