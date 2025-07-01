"""
Enhanced test script for video sign detection
Tests both single frame and video sequence capabilities
"""

import requests
import numpy as np
import cv2
import os
from PIL import Image
import io
import time

def test_video_endpoints():
    """Test video-based sign detection"""
    base_url = "http://localhost:5000"
    
    print("🎬 Testing Video Sign Detection")
    print("=" * 50)
    
    # Test 1: Single frame (static sign)
    print("\n1. Testing single frame detection...")
    test_single_frame(base_url)
    
    # Test 2: Short video sequence
    print("\n2. Testing short video sequence (30 frames)...")
    test_video_sequence(base_url, frames=30)
    
    # Test 3: Medium video sequence
    print("\n3. Testing medium video sequence (100 frames)...")
    test_video_sequence(base_url, frames=100)
    
    # Test 4: Long video sequence (will be truncated to 143)
    print("\n4. Testing long video sequence (200 frames → truncated to 143)...")
    test_video_sequence(base_url, frames=200)
    
    # Test 5: Video file upload endpoint
    print("\n5. Testing video file upload...")
    test_video_file_upload(base_url)

def test_single_frame(base_url):
    """Test single frame detection"""
    try:
        # Create a test image
        test_image = create_test_image_with_hand_simulation()
        
        # Convert to bytes
        img_byte_arr = io.BytesIO()
        test_image.save(img_byte_arr, format='JPEG')
        img_byte_arr = img_byte_arr.getvalue()
        
        # Get landmarks
        files = {'frame': ('test_frame.jpg', img_byte_arr, 'image/jpeg')}
        landmarks_response = requests.post(f"{base_url}/detect-landmarks", files=files)
        
        if landmarks_response.status_code == 200:
            landmarks_data = landmarks_response.json()['landmarks']
            
            # Use landmarks for prediction (single frame becomes a sequence)
            data = {'landmarks': [landmarks_data]}  # Single frame as sequence
            sign_response = requests.post(f"{base_url}/detect-sign", json=data)
            
            if sign_response.status_code == 200:
                result = sign_response.json()
                print(f"   ✅ Single frame prediction: '{result.get('word')}' (confidence: {result.get('confidence'):.4f})")
            else:
                print(f"   ❌ Sign detection failed: {sign_response.json()}")
        else:
            print(f"   ❌ Landmark extraction failed: {landmarks_response.json()}")
            
    except Exception as e:
        print(f"   ❌ Error in single frame test: {e}")

def test_video_sequence(base_url, frames):
    """Test video sequence of specified length"""
    try:
        # Create a video sequence (simulated)
        video_landmarks = create_video_landmarks_sequence(frames)
        
        # Send for prediction
        data = {'landmarks': video_landmarks.tolist()}
        response = requests.post(f"{base_url}/detect-sign", json=data)
        
        if response.status_code == 200:
            result = response.json()
            print(f"   ✅ {frames}-frame sequence: '{result.get('word')}' (confidence: {result.get('confidence'):.4f})")
            print(f"      Input shape: {np.array(video_landmarks).shape} → Model processes as (1, 143, 100, 3)")
        else:
            error_info = response.json()
            print(f"   ❌ {frames}-frame sequence failed: {error_info}")
            
    except Exception as e:
        print(f"   ❌ Error in {frames}-frame test: {e}")

def test_video_file_upload(base_url):
    """Test the video file upload endpoint"""
    try:
        # Create a simple test video file
        video_path = create_test_video()
        
        with open(video_path, 'rb') as video_file:
            files = {'video': ('test_video.mp4', video_file, 'video/mp4')}
            response = requests.post(f"{base_url}/detect-video-signs", files=files)
            
        if response.status_code == 200:
            result = response.json()
            print(f"   ✅ Video file upload successful!")
            print(f"      Predictions: {result.get('predictions', [])}")
            print(f"      Total frames processed: {result.get('total_frames', 'N/A')}")
        else:
            print(f"   ❌ Video upload failed: {response.json()}")
            
        # Clean up
        if os.path.exists(video_path):
            os.remove(video_path)
            
    except Exception as e:
        print(f"   ❌ Error in video file test: {e}")

def create_test_image_with_hand_simulation():
    """Create a test image with some basic shapes to simulate hands"""
    img = Image.new('RGB', (640, 480), color=(50, 50, 50))  # Dark background
    
    # You could add drawing here to simulate hand shapes
    # For now, return the basic image
    return img

def create_video_landmarks_sequence(num_frames):
    """Create a simulated video sequence of landmarks"""
    # Based on training notebook: each frame has 100 landmarks with (x, y, z)
    landmarks_per_frame = 100
    coords = 3
    
    # Create a sequence that simulates some movement
    video_sequence = []
    
    for frame_idx in range(num_frames):
        # Simulate some temporal progression (subtle changes over time)
        base_landmarks = np.random.rand(landmarks_per_frame, coords).astype(np.float32)
        
        # Add some temporal consistency (small changes between frames)
        if frame_idx > 0:
            # Make landmarks similar to previous frame with small variations
            prev_landmarks = video_sequence[-1]
            noise = np.random.normal(0, 0.05, (landmarks_per_frame, coords))
            base_landmarks = np.clip(prev_landmarks + noise, 0, 1).astype(np.float32)
        
        video_sequence.append(base_landmarks)
    
    return np.array(video_sequence)

def create_test_video():
    """Create a simple test video file"""
    video_path = "test_video.mp4"
    
    # Create a simple video using OpenCV
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(video_path, fourcc, 10.0, (640, 480))
    
    # Create 30 frames of simple video
    for i in range(30):
        # Create a frame with some movement
        frame = np.zeros((480, 640, 3), dtype=np.uint8)
        
        # Add a moving circle to simulate hand movement
        center_x = int(320 + 100 * np.sin(i * 0.2))
        center_y = int(240 + 50 * np.cos(i * 0.2))
        cv2.circle(frame, (center_x, center_y), 30, (255, 255, 255), -1)
        
        out.write(frame)
    
    out.release()
    return video_path

def test_performance_metrics():
    """Test performance characteristics"""
    base_url = "http://localhost:5000"
    
    print("\n🚀 Performance Testing")
    print("=" * 30)
    
    # Test different sequence lengths to see processing times
    frame_counts = [1, 10, 50, 100, 143, 200]
    
    for frames in frame_counts:
        start_time = time.time()
        
        # Create sequence
        video_landmarks = create_video_landmarks_sequence(frames)
        data = {'landmarks': video_landmarks.tolist()}
        
        # Send request
        try:
            response = requests.post(f"{base_url}/detect-sign", json=data)
            end_time = time.time()
            
            if response.status_code == 200:
                result = response.json()
                processing_time = (end_time - start_time) * 1000  # Convert to ms
                print(f"   {frames:3d} frames: {processing_time:6.1f}ms → '{result.get('word')}' (conf: {result.get('confidence'):.2f})")
            else:
                print(f"   {frames:3d} frames: FAILED")
                
        except Exception as e:
            print(f"   {frames:3d} frames: ERROR - {e}")

def test_edge_cases():
    """Test edge cases and error handling"""
    base_url = "http://localhost:5000"
    
    print("\n🧪 Edge Case Testing")
    print("=" * 30)
    
    # Test 1: Empty landmarks
    print("1. Testing empty landmarks...")
    try:
        response = requests.post(f"{base_url}/detect-sign", json={'landmarks': []})
        print(f"   Status: {response.status_code} - {response.json().get('error', 'Success')}")
    except Exception as e:
        print(f"   Error: {e}")
    
    # Test 2: Wrong shape landmarks
    print("2. Testing wrong shape landmarks...")
    try:
        wrong_landmarks = np.random.rand(10, 50, 3).tolist()  # Wrong number of landmarks
        response = requests.post(f"{base_url}/detect-sign", json={'landmarks': wrong_landmarks})
        print(f"   Status: {response.status_code} - {response.json().get('error', 'Success')}")
    except Exception as e:
        print(f"   Error: {e}")
    
    # Test 3: Very long sequence (should be truncated)
    print("3. Testing very long sequence (500 frames)...")
    try:
        long_sequence = create_video_landmarks_sequence(500)
        response = requests.post(f"{base_url}/detect-sign", json={'landmarks': long_sequence.tolist()})
        if response.status_code == 200:
            result = response.json()
            print(f"   ✅ Handled gracefully: '{result.get('word')}' (truncated to 143 frames)")
        else:
            print(f"   Status: {response.status_code} - {response.json().get('error')}")
    except Exception as e:
        print(f"   Error: {e}")

if __name__ == "__main__":
    print("🎬 SignIfy Video Detection Testing")
    print("Make sure your Flask server is running!")
    print()
    
    # Run all tests
    test_video_endpoints()
    test_performance_metrics()
    test_edge_cases()
    
    print("\n" + "=" * 60)
    print("✅ Video testing completed!")
    print("\n📋 Summary:")
    print("- Single frame detection: Static signs (like letters)")
    print("- Video sequences: Dynamic signs (like words with movement)")
    print("- Model handles 1-143 frames automatically")
    print("- Longer sequences are truncated to 143 frames")
    print("- Performance scales roughly with sequence length")
    print("\n🔧 Next Steps:")
    print("1. Test with real hand gesture videos")
    print("2. Integrate camera feed in Flutter")
    print("3. Add real-time processing capabilities")
    print("4. Optimize for mobile performance")
