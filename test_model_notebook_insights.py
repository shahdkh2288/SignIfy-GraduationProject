"""
Test script based on insights from the training notebook.
This script demonstrates how to properly use the TFLite model and label encoder.
"""

import numpy as np
import tensorflow as tf
import pickle
import os
import cv2
import mediapipe as mp
from pathlib import Path

# Configuration matching the training notebook EXACTLY
MAX_FRAMES = 143  # From notebook: max_frames = 143
TOTAL_LANDMARKS = 100  # Model expects exactly 100 landmarks

# Landmark indices from training notebook - EXACT MATCH
filtered_hand = list(range(21))
filtered_pose = [11, 12, 13, 14, 15, 16]
filtered_face = [4, 6, 8, 9, 33, 37, 40, 46, 52, 55, 61, 70, 80, 82, 84,
                 87, 88, 91, 105, 107, 133, 145, 154, 157, 159, 161, 163,
                 263, 267, 270, 276, 282, 285, 291, 300, 310, 312, 314, 317,
                 318, 321, 334, 336, 362, 374, 381, 384, 386, 388, 390, 468, 473]

HAND_NUM = len(filtered_hand)  # 21
POSE_NUM = len(filtered_pose)  # 6
FACE_NUM = len(filtered_face)  # 51
# Total: 21 + 21 + 6 + 51 = 99, with 1 padding = 100

def load_model_and_encoder():
    """Load TFLite model and label encoder exactly as in the training notebook."""
    model_path = 'backend/app/models/model.tflite'
    encoder_path = 'backend/app/models/label_encoder.pkl'
    
    # Load TFLite model
    if os.path.exists(model_path):
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        print("✅ TFLite model loaded successfully")
        print(f"Input shape: {input_details[0]['shape']}")
        print(f"Input dtype: {input_details[0]['dtype']}")
    else:
        print("❌ TFLite model not found")
        return None, None, None, None
    
    # Load label encoder
    if os.path.exists(encoder_path):
        with open(encoder_path, 'rb') as f:
            label_encoder = pickle.load(f)
        print("✅ Label encoder loaded successfully")
        print(f"Number of classes: {len(label_encoder.classes_)}")
        print(f"Sample classes: {list(label_encoder.classes_[:10])}")
    else:
        print("❌ Label encoder not found")
        return interpreter, input_details, output_details, None
    
    return interpreter, input_details, output_details, label_encoder

def get_frame_landmarks(frame, hands, pose, face_mesh):
    """
    Extract landmarks from a single frame - EXACT MATCH to training notebook.
    This function replicates the exact logic from the notebook.
    """
    # Initialize with exactly 100 landmarks (99 + 1 padding)
    all_landmarks = np.zeros((100, 3))

    # Process hands - match training logic exactly
    results_hands = hands.process(frame)
    if results_hands.multi_hand_landmarks:
        for i, hand_landmarks in enumerate(results_hands.multi_hand_landmarks):
            if results_hands.multi_handedness[i].classification[0].index == 0:
                # Left hand
                all_landmarks[:HAND_NUM, :] = np.array(
                    [(lm.x, lm.y, lm.z) for lm in hand_landmarks.landmark])
            else:
                # Right hand
                all_landmarks[HAND_NUM:HAND_NUM * 2, :] = np.array(
                    [(lm.x, lm.y, lm.z) for lm in hand_landmarks.landmark])

    # Process pose - match training logic exactly
    results_pose = pose.process(frame)
    if results_pose.pose_landmarks:
        all_landmarks[HAND_NUM * 2:HAND_NUM * 2 + POSE_NUM, :] = np.array(
            [(lm.x, lm.y, lm.z) for lm in results_pose.pose_landmarks.landmark])[filtered_pose]

    # Process face - match training logic exactly
    results_face = face_mesh.process(frame)
    if results_face.multi_face_landmarks:
        all_landmarks[HAND_NUM * 2 + POSE_NUM:HAND_NUM * 2 + POSE_NUM + FACE_NUM, :] = np.array(
            [(lm.x, lm.y, lm.z) for lm in results_face.multi_face_landmarks[0].landmark])[filtered_face]

    return all_landmarks

def padding(X, length=MAX_FRAMES, pad=0):
    """
    Pad/truncate sequence to target length - EXACT MATCH to training notebook.
    """
    if len(X) > length:
        return X[:length]  # Truncate
    else:
        pad_length = length - len(X)
        return np.pad(X, ((0, pad_length), (0, 0), (0, 0)), 
                     mode='constant', constant_values=pad)

def test_single_frame_inference():
    """Test inference with a single frame (static sign detection)."""
    print("\n🧪 Testing single frame inference...")
    
    # Load model and encoder
    interpreter, input_details, output_details, label_encoder = load_model_and_encoder()
    if interpreter is None:
        return
    
    # Create dummy landmarks for testing (simulating a single frame)
    # This mimics having captured landmarks from one frame
    single_frame_landmarks = np.random.rand(100, 3).astype(np.float32)
    print(f"Single frame landmarks shape: {single_frame_landmarks.shape}")
    
    # Convert to sequence format (add time dimension)
    sequence = np.array([single_frame_landmarks])  # Shape: (1, 100, 3)
    print(f"Sequence shape: {sequence.shape}")
    
    # Pad to model's expected length
    padded_sequence = padding(sequence, MAX_FRAMES)
    print(f"Padded sequence shape: {padded_sequence.shape}")
    
    # Reshape to model input format: (batch_size, max_frames, num_landmarks, coordinates)
    model_input = padded_sequence.reshape(1, MAX_FRAMES, 100, 3)
    print(f"Model input shape: {model_input.shape}")
    
    # Run inference
    interpreter.set_tensor(input_details[0]['index'], model_input)
    interpreter.invoke()
    output_data = interpreter.get_tensor(output_details[0]['index'])
    
    # Get prediction
    pred_probs = output_data[0]
    top5_indices = np.argsort(pred_probs)[-5:][::-1]
    
    print("\n🎯 Top 5 Predictions:")
    if label_encoder:
        for i, idx in enumerate(top5_indices):
            try:
                word = label_encoder.inverse_transform([idx])[0]
                confidence = pred_probs[idx]
                print(f"{i+1}. {word}: {confidence:.4f}")
            except:
                print(f"{i+1}. Class_{idx}: {pred_probs[idx]:.4f}")
    else:
        for i, idx in enumerate(top5_indices):
            print(f"{i+1}. Class_{idx}: {pred_probs[idx]:.4f}")

def test_video_sequence_inference():
    """Test inference with a video sequence (dynamic sign detection)."""
    print("\n🎬 Testing video sequence inference...")
    
    # Load model and encoder
    interpreter, input_details, output_details, label_encoder = load_model_and_encoder()
    if interpreter is None:
        return
    
    # Simulate a video sequence with varying lengths
    sequence_lengths = [30, 50, 100, 200]  # Different video lengths
    
    for seq_len in sequence_lengths:
        print(f"\n📹 Testing sequence of {seq_len} frames...")
        
        # Create dummy video landmarks
        video_landmarks = np.random.rand(seq_len, 100, 3).astype(np.float32)
        print(f"Original video shape: {video_landmarks.shape}")
        
        # Pad/truncate to model's expected length
        padded_video = padding(video_landmarks, MAX_FRAMES)
        print(f"Padded video shape: {padded_video.shape}")
        
        # Reshape for model input
        model_input = padded_video.reshape(1, MAX_FRAMES, 100, 3)
        print(f"Model input shape: {model_input.shape}")
        
        # Run inference
        interpreter.set_tensor(input_details[0]['index'], model_input)
        interpreter.invoke()
        output_data = interpreter.get_tensor(output_details[0]['index'])
        
        # Get top prediction
        predicted_index = np.argmax(output_data)
        confidence = np.max(output_data)
        
        if label_encoder:
            try:
                predicted_word = label_encoder.inverse_transform([predicted_index])[0]
            except:
                predicted_word = f'Class_{predicted_index}'
        else:
            predicted_word = f'Class_{predicted_index}'
        
        print(f"✅ Prediction: {predicted_word} (confidence: {confidence:.4f})")

def test_mediapipe_integration():
    """Test the complete pipeline with MediaPipe landmark extraction."""
    print("\n👁️ Testing MediaPipe integration...")
    
    # Initialize MediaPipe - match training configuration
    hands = mp.solutions.hands.Hands(
        static_image_mode=True, 
        max_num_hands=2, 
        min_detection_confidence=0.5
    )
    pose = mp.solutions.pose.Pose(
        static_image_mode=True, 
        min_detection_confidence=0.5
    )
    face_mesh = mp.solutions.face_mesh.FaceMesh(
        static_image_mode=True, 
        max_num_faces=1, 
        refine_landmarks=True, 
        min_detection_confidence=0.5
    )
    
    # Create a dummy image (black image)
    dummy_image = np.zeros((480, 640, 3), dtype=np.uint8)
    
    try:
        # Extract landmarks
        landmarks = get_frame_landmarks(dummy_image, hands, pose, face_mesh)
        print(f"✅ Extracted landmarks shape: {landmarks.shape}")
        print(f"Non-zero landmarks: {np.count_nonzero(landmarks)}")
        
        # Test inference with extracted landmarks
        if landmarks.shape == (100, 3):
            print("✅ Landmark shape matches model expectations")
        else:
            print(f"❌ Landmark shape mismatch. Expected (100, 3), got {landmarks.shape}")
            
    except Exception as e:
        print(f"❌ Error in MediaPipe integration: {e}")
    
    finally:
        hands.close()
        pose.close()
        face_mesh.close()

def main():
    """Run all tests to validate the model integration."""
    print("🚀 Testing SignIfy Model Integration")
    print("Based on insights from the training notebook")
    print("="*50)
    
    # Test model loading
    print("\n📦 Testing model and encoder loading...")
    interpreter, input_details, output_details, label_encoder = load_model_and_encoder()
    
    if interpreter is None:
        print("❌ Cannot proceed without model. Please ensure model.tflite exists in backend/app/models/")
        return
    
    # Run tests
    test_single_frame_inference()
    test_video_sequence_inference()
    test_mediapipe_integration()
    
    print("\n✅ All tests completed!")
    print("\n📝 Summary:")
    print("- Model expects input shape: (1, 143, 100, 3)")
    print("- 143 = max frames (time steps)")
    print("- 100 = landmarks (21+21+6+51+1 padding)")
    print("- 3 = coordinates (x, y, z)")
    print("- Use padding/truncation for variable length sequences")
    print("- Label encoder maps predictions to actual words")

if __name__ == "__main__":
    main()
