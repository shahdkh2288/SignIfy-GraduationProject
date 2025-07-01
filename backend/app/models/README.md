# SignIfy Sign Language Recognition Models

This directory contains the TensorFlow Lite model and label encoder for sign language recognition in the SignIfy project.

## Files

### model.tflite
- **Type**: TensorFlow Lite model for sign language recognition
- **Input Shape**: `(1, 143, 100, 3)`
  - 1: Batch size
  - 143: Maximum number of frames (time steps)
  - 100: Number of landmarks per frame
  - 3: Coordinates (x, y, z) for each landmark
- **Output**: Probability distribution over sign language classes
- **Architecture**: Custom Conv1D + Transformer-like model with ECA attention

### label_encoder.pkl
- **Type**: Scikit-learn LabelEncoder saved with pickle
- **Purpose**: Maps model output indices to actual word labels
- **Format**: Pickled LabelEncoder object
- **Usage**: `label_encoder.inverse_transform([predicted_index])[0]`

## Model Details (Based on Training Notebook)

### Landmark Structure (100 total landmarks)
The model expects exactly 100 landmarks per frame, structured as follows:

1. **Left Hand**: 21 landmarks (indices 0-20)
2. **Right Hand**: 21 landmarks (indices 21-41) 
3. **Pose**: 6 landmarks (indices 42-47)
   - Filtered pose indices: [11, 12, 13, 14, 15, 16] (shoulders, elbows, wrists)
4. **Face**: 51 landmarks (indices 48-98)
   - Specific facial landmarks for sign language recognition
5. **Padding**: 1 zero landmark (index 99) to reach exactly 100

### Input Preprocessing
1. **Landmark Extraction**: Use MediaPipe with exact filters from training:
   ```python
   filtered_hand = list(range(21))
   filtered_pose = [11, 12, 13, 14, 15, 16]
   filtered_face = [4, 6, 8, 9, 33, 37, 40, 46, 52, 55, 61, 70, 80, 82, 84,
                    87, 88, 91, 105, 107, 133, 145, 154, 157, 159, 161, 163,
                    263, 267, 270, 276, 282, 285, 291, 300, 310, 312, 314, 317,
                    318, 321, 334, 336, 362, 374, 381, 384, 386, 388, 390, 468, 473]
   ```

2. **Sequence Handling**:
   - **Truncation**: If video > 143 frames, take first 143
   - **Padding**: If video < 143 frames, pad with zeros
   - **Single Frame**: Duplicate frame or pad with zeros to reach 143

3. **Coordinate Normalization**: MediaPipe outputs normalized coordinates (0-1)

### Usage Examples

#### Single Frame (Static Sign)
```python
# Extract landmarks from single image
landmarks = extract_landmarks(image)  # Shape: (100, 3)

# Convert to sequence format
sequence = np.array([landmarks])  # Shape: (1, 100, 3)

# Pad to model length
padded = pad_sequence(sequence, 143)  # Shape: (143, 100, 3)

# Reshape for model
model_input = padded.reshape(1, 143, 100, 3)
```

#### Video Sequence (Dynamic Sign)
```python
# Extract landmarks from video frames
video_landmarks = []
for frame in video_frames:
    landmarks = extract_landmarks(frame)
    video_landmarks.append(landmarks)

# Convert to numpy array
sequence = np.array(video_landmarks)  # Shape: (num_frames, 100, 3)

# Pad/truncate to model length
padded = pad_sequence(sequence, 143)  # Shape: (143, 100, 3)

# Reshape for model
model_input = padded.reshape(1, 143, 100, 3)
```

### Integration Notes
- MediaPipe configuration must match training exactly
- Hand chirality (left/right) detection is critical
- Face landmarks improve accuracy for signs involving facial expressions
- Pose landmarks help with body movement signs
- Use the comprehensive test script `test_model_notebook_insights.py` to validate integration
