"""
Test script for Flask sign detection endpoints
"""

import requests
import numpy as np
import cv2
import os
from PIL import Image
import io

def test_flask_endpoints():
    """Test the Flask sign detection endpoints"""
    base_url = "http://localhost:5000"
    
    print("Testing Flask Sign Detection Endpoints")
    print("=" * 50)
    
    # Test 1: detect-landmarks endpoint
    print("\n1. Testing /detect-landmarks endpoint...")
    
    try:
        # Create a simple test image (you can replace with actual image)
        test_image = create_test_image()
        
        # Convert to bytes
        img_byte_arr = io.BytesIO()
        test_image.save(img_byte_arr, format='JPEG')
        img_byte_arr = img_byte_arr.getvalue()
        
        # Send request
        files = {'frame': ('test_frame.jpg', img_byte_arr, 'image/jpeg')}
        response = requests.post(f"{base_url}/detect-landmarks", files=files)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Landmarks detected successfully!")
            print(f"Landmarks shape: {result.get('shape')}")
            print(f"Message: {result.get('message')}")
        else:
            print(f"❌ Error: {response.status_code} - {response.json()}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Could not connect to Flask server. Make sure it's running on localhost:5000")
        return
    except Exception as e:
        print(f"❌ Error testing landmarks endpoint: {e}")
    
    # Test 2: detect-sign endpoint (if landmarks worked)
    print("\n2. Testing /detect-sign endpoint...")
    
    try:
        # Create dummy landmarks data (should match your model's expected format)
        dummy_landmarks = create_dummy_landmarks_sequence()
        
        data = {'landmarks': dummy_landmarks.tolist()}
        response = requests.post(f"{base_url}/detect-sign", json=data)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Sign detected successfully!")
            print(f"Predicted word: '{result.get('word')}'")
            print(f"Confidence: {result.get('confidence'):.4f}")
            print(f"Predicted index: {result.get('predicted_index')}")
        else:
            print(f"❌ Error: {response.status_code} - {response.json()}")
            
    except Exception as e:
        print(f"❌ Error testing sign detection endpoint: {e}")

def create_test_image():
    """Create a simple test image for testing"""
    # Create a simple image (you could load an actual image here)
    img = Image.new('RGB', (640, 480), color='white')
    
    # You could add some simple shapes to simulate hands
    # For now, just return a blank image
    return img

def create_dummy_landmarks_sequence():
    """Create dummy landmarks sequence for testing"""
    # Based on your notebook: (frames, 100, 3)
    frames = 10  # Short sequence for testing
    landmarks = 100  # As expected by your model
    coords = 3  # x, y, z
    
    # Create random landmarks (in practice, these would come from MediaPipe)
    dummy_sequence = np.random.rand(frames, landmarks, coords).astype(np.float32)
    
    # Ensure values are in [0, 1] range as MediaPipe outputs
    dummy_sequence = np.clip(dummy_sequence, 0, 1)
    
    return dummy_sequence

def test_combined_workflow():
    """Test the complete workflow: image -> landmarks -> sign prediction"""
    print("\n3. Testing combined workflow...")
    
    base_url = "http://localhost:5000"
    
    try:
        # Step 1: Get landmarks from image
        test_image = create_test_image()
        img_byte_arr = io.BytesIO()
        test_image.save(img_byte_arr, format='JPEG')
        img_byte_arr = img_byte_arr.getvalue()
        
        files = {'frame': ('test_frame.jpg', img_byte_arr, 'image/jpeg')}
        landmarks_response = requests.post(f"{base_url}/detect-landmarks", files=files)
        
        if landmarks_response.status_code != 200:
            print(f"❌ Failed to get landmarks: {landmarks_response.json()}")
            return
            
        landmarks_data = landmarks_response.json()['landmarks']
        
        # Step 2: Use landmarks for sign prediction
        data = {'landmarks': [landmarks_data]}  # Wrap in sequence
        sign_response = requests.post(f"{base_url}/detect-sign", json=data)
        
        if sign_response.status_code == 200:
            result = sign_response.json()
            print(f"✅ Complete workflow successful!")
            print(f"Final prediction: '{result.get('word')}' (confidence: {result.get('confidence'):.4f})")
        else:
            print(f"❌ Sign detection failed: {sign_response.json()}")
            
    except Exception as e:
        print(f"❌ Error in combined workflow: {e}")

if __name__ == "__main__":
    print("Make sure your Flask server is running with:")
    print("cd backend && python -m flask run")
    print()
    
    test_flask_endpoints()
    test_combined_workflow()
    
    print("\n" + "=" * 50)
    print("Testing completed!")
    print("\nNext steps:")
    print("1. Test with real images containing hands")
    print("2. Verify landmark extraction quality")
    print("3. Test with video sequences for dynamic signs")
    print("4. Integrate with Flutter frontend")
