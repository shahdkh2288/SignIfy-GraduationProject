"""
Test script for the SignIfy sign language detection model
Based on the 200 Word TFLite2 notebook
"""

import numpy as np
import tensorflow as tf
import pickle
import os

def test_model():
    """Test the TFLite model with dummy data"""
    
    # Load model
    model_path = 'backend/app/models/model.tflite'
    label_encoder_path = 'backend/app/models/label_encoder.pkl'
    
    print("Testing SignIfy Model...")
    print("=" * 50)
    
    try:
        # Load TFLite interpreter
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"✅ Model loaded successfully!")
        print(f"Input shape: {input_details[0]['shape']}")
        print(f"Input dtype: {input_details[0]['dtype']}")
        print(f"Output shape: {output_details[0]['shape']}")
        
        # Load label encoder
        with open(label_encoder_path, 'rb') as f:
            label_encoder = pickle.load(f)
        
        print(f"✅ Label encoder loaded with {len(label_encoder.classes_)} classes")
        print(f"Sample classes: {list(label_encoder.classes_[:10])}")
        
        # Test with dummy data
        # Expected input: (1, 143, 100, 3)
        batch_size, max_frames, num_landmarks, coords = input_details[0]['shape']
        
        print(f"\nTesting with dummy data...")
        print(f"Expected input: batch={batch_size}, frames={max_frames}, landmarks={num_landmarks}, coords={coords}")
        
        # Create random landmarks data
        dummy_input = np.random.rand(batch_size, max_frames, num_landmarks, coords).astype(np.float32)
        
        # Run inference
        interpreter.set_tensor(input_details[0]['index'], dummy_input)
        interpreter.invoke()
        
        # Get output
        output_data = interpreter.get_tensor(output_details[0]['index'])
        
        print(f"✅ Inference successful!")
        print(f"Output shape: {output_data.shape}")
        
        # Get prediction
        predicted_index = np.argmax(output_data, axis=1)[0]
        confidence = float(np.max(output_data))
        predicted_word = label_encoder.inverse_transform([predicted_index])[0]
        
        print(f"\nPrediction Results:")
        print(f"Predicted index: {predicted_index}")
        print(f"Predicted word: '{predicted_word}'")
        print(f"Confidence: {confidence:.4f}")
        
        # Show top 5 predictions
        top5_indices = np.argsort(output_data[0])[-5:][::-1]
        top5_words = label_encoder.inverse_transform(top5_indices)
        top5_probs = output_data[0][top5_indices]
        
        print(f"\nTop 5 predictions:")
        for i, (word, prob) in enumerate(zip(top5_words, top5_probs)):
            print(f"{i+1}. {word}: {prob:.4f}")
            
        print(f"\n✅ Model test completed successfully!")
        
    except FileNotFoundError as e:
        print(f"❌ File not found: {e}")
        print("Make sure model.tflite and label_encoder.pkl are in backend/app/models/")
    except Exception as e:
        print(f"❌ Error during testing: {e}")
        import traceback
        traceback.print_exc()

def verify_landmark_extraction():
    """Verify that landmark extraction produces the right format"""
    print("\nVerifying landmark extraction format...")
    print("=" * 50)
    
    # From your notebook
    filtered_hand = list(range(21))
    filtered_pose = [11, 12, 13, 14, 15, 16]
    filtered_face = [4, 6, 8, 9, 33, 37, 40, 46, 52, 55, 61, 70, 80, 82, 84,
                     87, 88, 91, 105, 107, 133, 145, 154, 157, 159, 161, 163,
                     263, 267, 270, 276, 282, 285, 291, 300, 310, 312, 314, 317,
                     318, 321, 334, 336, 362, 374, 381, 384, 386, 388, 390, 468, 473]

    HAND_NUM = len(filtered_hand)  # 21
    POSE_NUM = len(filtered_pose)  # 6
    FACE_NUM = len(filtered_face)  # 52
    
    total_landmarks = HAND_NUM * 2 + POSE_NUM + FACE_NUM  # 42 + 6 + 52 = 100
    
    print(f"Hand landmarks: {HAND_NUM} x 2 hands = {HAND_NUM * 2}")
    print(f"Pose landmarks: {POSE_NUM}")
    print(f"Face landmarks: {FACE_NUM}")
    print(f"Total landmarks: {total_landmarks}")
    
    # Note: Your model expects 100 landmarks, but calculation gives 99
    # You might need to add one more landmark or adjust the model
    if total_landmarks != 100:
        print(f"⚠️  Warning: Total landmarks ({total_landmarks}) != model expected (100)")
        print("You may need to adjust the landmark extraction or model input")
    else:
        print(f"✅ Landmark count matches model expectation")

if __name__ == "__main__":
    test_model()
    verify_landmark_extraction()
