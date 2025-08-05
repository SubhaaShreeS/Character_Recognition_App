#multi_character_recognitze
from flask import Flask, request, jsonify
import numpy as np
import cv2
from PIL import Image
from tensorflow.keras.models import load_model

app = Flask(__name__)

# Load trained model
model = load_model("alphabets_model_final.keras")

# Maps class index 0–25 to a–z
class_names = [chr(i) for i in range(97, 123)]

# Preprocess a single character image (28x28 grayscale white char on black)
def preprocess_character(pil_img):
    gray = pil_img.convert("L")
    img_np = np.array(gray)

    if np.mean(img_np) > 127:
        img_np = 255 - img_np

    _, thresh = cv2.threshold(img_np, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    coords = cv2.findNonZero(thresh)
    if coords is None:
        raise ValueError("No character found in image.")

    x, y, w, h = cv2.boundingRect(coords)
    cropped = thresh[y:y+h, x:x+w]

    padding = max(w, h) // 4
    padded = cv2.copyMakeBorder(
        cropped, padding, padding, padding, padding,
        borderType=cv2.BORDER_CONSTANT, value=0
    )

    resized = cv2.resize(padded, (28, 28), interpolation=cv2.INTER_AREA)
    normalized = resized.astype("float32") / 255.0
    normalized = np.expand_dims(normalized, axis=-1)  # (28, 28, 1)

    return normalized

# Segment characters from multi-character image using vertical projection
def segment_characters(pil_img):
    gray = pil_img.convert("L")
    img_np = np.array(gray)

    if np.mean(img_np) > 127:
        img_np = 255 - img_np

    _, binary = cv2.threshold(img_np, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    projection = np.sum(binary == 255, axis=0)
    threshold = 1  # Minimum pixels to be considered as character column

    segments = []
    in_char = False
    start = 0

    for i, val in enumerate(projection):
        if val > threshold and not in_char:
            start = i
            in_char = True
        elif val <= threshold and in_char:
            end = i
            if end - start > 2:  # Ignore tiny gaps
                char_img = binary[:, start:end]
                segments.append(char_img)
            in_char = False

    if in_char: #ensures the last character isn't missed
        end = len(projection)
        char_img = binary[:, start:end]
        segments.append(char_img)

    return segments

@app.route("/predict", methods=["POST"])
def predict():
    if 'image' not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    try:
        file = request.files['image']
        image = Image.open(file.stream).convert("RGB")

        # Convert to grayscale for segmentation
        gray = image.convert("L")
        np_img = np.array(gray)

        if np.mean(np_img) > 127:
            np_img = 255 - np_img

        _, binary = cv2.threshold(np_img, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

        # Count distinct characters using vertical projection
        projection = np.sum(binary == 255, axis=0)
        non_zero_columns = np.sum(projection > 0)

        # Heuristic: if very few columns, it's single character
        if non_zero_columns < 40:
            processed = preprocess_character(image)
            processed = np.expand_dims(processed, axis=0)  # (1, 28, 28, 1)
            prediction = model.predict(processed)[0]
            index = int(np.argmax(prediction))
            confidence = float(prediction[index])
            predicted_char = class_names[index]

            return jsonify({
                "type": "single",
                "prediction": predicted_char,
                "confidence": round(confidence, 4)
            })

        # Multi-character handling
        segments = segment_characters(image)
        predictions = []
        full_word = ""

        for char_np in segments:
            # Convert NumPy back to PIL for consistent preprocessing
            pil_char = Image.fromarray(char_np)
            processed = preprocess_character(pil_char)
            processed = np.expand_dims(processed, axis=0)
            prediction = model.predict(processed)[0]
            index = int(np.argmax(prediction))
            confidence = float(prediction[index])
            predicted_char = class_names[index]
            full_word += predicted_char
            predictions.append({
                "character": predicted_char,
                "confidence": round(confidence, 4)
            })

        return jsonify({
            "type": "multi",
            "prediction": full_word,
            "characters": predictions
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=9010)

