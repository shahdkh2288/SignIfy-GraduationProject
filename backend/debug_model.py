#!/usr/bin/env python3
"""
Debug script to check model and label encoder compatibility
"""

import os
import pickle
import tensorflow as tf
import numpy as np

def debug_model_and_labels():
    """Debug the TFLite model and label encoder"""
    
    model_path = os.path.join('app', 'models', 'model.tflite')
    label_encoder_path = os.path.join('app', 'models', 'label_encoder.pkl')
    
    print("=== MODEL AND LABEL ENCODER DEBUG ===")
    
    # Check if files exist
    print(f"Model file exists: {os.path.exists(model_path)}")
    print(f"Label encoder file exists: {os.path.exists(label_encoder_path)}")
    
    if not os.path.exists(model_path):
        print("ERROR: Model file not found!")
        return
    
    # Load and inspect model
    try:
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"\n=== MODEL DETAILS ===")
        print(f"Input shape: {input_details[0]['shape']}")
        print(f"Input dtype: {input_details[0]['dtype']}")
        print(f"Output shape: {output_details[0]['shape']}")
        print(f"Output dtype: {output_details[0]['dtype']}")
        
        # Check number of output classes
        output_shape = output_details[0]['shape']
        if len(output_shape) > 1:
            num_classes = output_shape[1]
            print(f"Number of output classes: {num_classes}")
        else:
            print(f"Output shape: {output_shape}")
        
    except Exception as e:
        print(f"Error loading model: {e}")
        return
    
    # Load and inspect label encoder
    if os.path.exists(label_encoder_path):
        try:
            with open(label_encoder_path, 'rb') as f:
                label_encoder = pickle.load(f)
            
            print(f"\n=== LABEL ENCODER DETAILS ===")
            print(f"Label encoder type: {type(label_encoder)}")
            print(f"Number of classes: {len(label_encoder.classes_)}")
            print(f"Classes (first 20): {label_encoder.classes_[:20].tolist()}")
            print(f"Classes (last 20): {label_encoder.classes_[-20:].tolist()}")
            print(f"Max class index: {len(label_encoder.classes_) - 1}")
            
            # Check for compatibility
            if len(output_shape) > 1:
                model_classes = output_shape[1]
                encoder_classes = len(label_encoder.classes_)
                print(f"\n=== COMPATIBILITY CHECK ===")
                print(f"Model output classes: {model_classes}")
                print(f"Label encoder classes: {encoder_classes}")
                print(f"Compatible: {model_classes == encoder_classes}")
                
                if model_classes != encoder_classes:
                    print("WARNING: Model and label encoder have different number of classes!")
                    print("This could cause the index 226 error you're seeing.")
            
        except Exception as e:
            print(f"Error loading label encoder: {e}")
    else:
        print("\n=== NO LABEL ENCODER ===")
        print("Label encoder file not found. Using fallback word dictionary.")
        
        # Show fallback dictionary
        word_dict = {
            0: 'A', 1: 'B', 2: 'C', 3: 'D', 4: 'E', 5: 'F', 6: 'G', 7: 'H', 8: 'I', 9: 'K', 
            10: 'L', 11: 'M', 12: 'N', 13: 'O', 14: 'P', 15: 'Q', 16: 'R', 17: 'S', 18: 'T', 
            19: 'U', 20: 'V', 21: 'W', 22: 'X', 23: 'Y', 24: 'space'
        }
        print(f"Fallback dictionary has {len(word_dict)} classes")
        print(f"Max index in fallback: {max(word_dict.keys())}")
        
        if len(output_shape) > 1:
            model_classes = output_shape[1]
            print(f"Model has {model_classes} classes but fallback only has {len(word_dict)}")
            if model_classes > len(word_dict):
                print("WARNING: Model has more classes than fallback dictionary!")
    
    # Test with dummy input
    print(f"\n=== TEST PREDICTION ===")
    try:
        # Create dummy input matching expected shape
        input_shape = input_details[0]['shape']
        dummy_input = np.random.random(input_shape).astype(np.float32)
        
        interpreter.set_tensor(input_details[0]['index'], dummy_input)
        interpreter.invoke()
        
        output_data = interpreter.get_tensor(output_details[0]['index'])
        predicted_index = np.argmax(output_data, axis=1)[0]
        confidence = float(np.max(output_data))
        
        print(f"Test prediction index: {predicted_index}")
        print(f"Test confidence: {confidence}")
        print(f"Output min: {np.min(output_data)}")
        print(f"Output max: {np.max(output_data)}")
        print(f"Output shape: {output_data.shape}")
        
        # Test decoding
        if os.path.exists(label_encoder_path):
            try:
                predicted_word = label_encoder.inverse_transform([predicted_index])[0]
                print(f"Decoded word: {predicted_word}")
            except Exception as e:
                print(f"Failed to decode index {predicted_index}: {e}")
        else:
            word_dict = {
                0: 'A', 1: 'B', 2: 'C', 3: 'D', 4: 'E', 5: 'F', 6: 'G', 7: 'H', 8: 'I', 9: 'K', 
                10: 'L', 11: 'M', 12: 'N', 13: 'O', 14: 'P', 15: 'Q', 16: 'R', 17: 'S', 18: 'T', 
                19: 'U', 20: 'V', 21: 'W', 22: 'X', 23: 'Y', 24: 'space'
            }
            predicted_word = word_dict.get(predicted_index, 'Unknown')
            print(f"Fallback word: {predicted_word}")
    
    except Exception as e:
        print(f"Error running test prediction: {e}")
    
    print("=== END DEBUG ===")

if __name__ == "__main__":
    debug_model_and_labels()
