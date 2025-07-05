#!/usr/bin/env python3
"""
Debug script to test the sign detection model and check prediction indices.
"""

import os
import sys
import pickle
import numpy as np
import tensorflow as tf
from pathlib import Path

# Add backend to path
backend_path = Path(__file__).parent / "backend"
sys.path.append(str(backend_path))

def test_model_and_encoder():
    """Test the model and label encoder to understand prediction ranges."""
    
    # Paths
    model_path = backend_path / "app" / "models" / "model.tflite"
    label_encoder_path = backend_path / "app" / "models" / "label_encoder.pkl"
    
    print(f"Model path: {model_path}")
    print(f"Label encoder path: {label_encoder_path}")
    print(f"Model exists: {model_path.exists()}")
    print(f"Label encoder exists: {label_encoder_path.exists()}")
    
    # Load model
    if model_path.exists():
        try:
            interpreter = tf.lite.Interpreter(model_path=str(model_path))
            interpreter.allocate_tensors()
            input_details = interpreter.get_input_details()
            output_details = interpreter.get_output_details()
            
            print("\n=== MODEL INFO ===")
            print(f"Input details: {input_details}")
            print(f"Output details: {output_details}")
            print(f"Input shape: {input_details[0]['shape']}")
            print(f"Output shape: {output_details[0]['shape']}")
            
            # Test with dummy data
            dummy_input = np.random.random(input_details[0]['shape']).astype(np.float32)
            interpreter.set_tensor(input_details[0]['index'], dummy_input)
            interpreter.invoke()
            
            output_data = interpreter.get_tensor(output_details[0]['index'])
            predicted_index = np.argmax(output_data, axis=1)[0]
            confidence = float(np.max(output_data))
            
            print(f"\n=== DUMMY PREDICTION ===")
            print(f"Output shape: {output_data.shape}")
            print(f"Number of classes: {output_data.shape[1] if len(output_data.shape) > 1 else 1}")
            print(f"Predicted index: {predicted_index}")
            print(f"Confidence: {confidence}")
            print(f"Output data range: {np.min(output_data)} to {np.max(output_data)}")
            
        except Exception as e:
            print(f"Error loading model: {e}")
    else:
        print("Model file not found!")
    
    # Load label encoder
    if label_encoder_path.exists():
        try:
            with open(label_encoder_path, 'rb') as f:
                label_encoder = pickle.load(f)
            
            print(f"\n=== LABEL ENCODER INFO ===")
            print(f"Number of classes: {len(label_encoder.classes_)}")
            print(f"Classes (first 20): {label_encoder.classes_[:20]}")
            print(f"Classes (last 20): {label_encoder.classes_[-20:]}")
            
            # Test encoding/decoding
            test_indices = [0, 10, 50, 100, 200, len(label_encoder.classes_)-1]
            for idx in test_indices:
                try:
                    if idx < len(label_encoder.classes_):
                        word = label_encoder.inverse_transform([idx])[0]
                        print(f"Index {idx} -> '{word}'")
                    else:
                        print(f"Index {idx} -> OUT OF RANGE")
                except Exception as e:
                    print(f"Index {idx} -> ERROR: {e}")
                    
        except Exception as e:
            print(f"Error loading label encoder: {e}")
    else:
        print("Label encoder file not found!")
    
    # Check fallback word dict
    word_dict = {
        0: 'A', 1: 'B', 2: 'C', 3: 'D', 4: 'E', 5: 'F', 6: 'G', 7: 'H', 8: 'I', 9: 'K', 
        10: 'L', 11: 'M', 12: 'N', 13: 'O', 14: 'P', 15: 'Q', 16: 'R', 17: 'S', 18: 'T', 
        19: 'U', 20: 'V', 21: 'W', 22: 'X', 23: 'Y', 24: 'space'
    }
    
    print(f"\n=== FALLBACK WORD DICT ===")
    print(f"Number of classes: {len(word_dict)}")
    print(f"Max index: {max(word_dict.keys())}")
    print(f"Classes: {list(word_dict.values())}")

if __name__ == "__main__":
    test_model_and_encoder()
