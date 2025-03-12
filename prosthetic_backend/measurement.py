from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import cv2
import mediapipe as mp
import numpy as np
from typing import List, Dict, Optional
import os
import tensorflow as tf
import time
from pydantic import BaseModel
import math

# Suppress TensorFlow warnings
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
tf.get_logger().setLevel('ERROR')

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ProstheticMeasurement(BaseModel):
    limb_type: str
    coordinates: Dict[str, float]
    confidence: float
    recommended_size: Dict[str, float]
    measurement_points: List[Dict[str, float]]
    reference_points: List[Dict[str, float]]

class ProstheticPoseEstimator:
    def __init__(self):
        self.mp_pose = mp.solutions.pose
        # Adjusted model complexity and detection confidence
        self.pose = self.mp_pose.Pose(
            static_image_mode=True,
            model_complexity=2,
            min_detection_confidence=0.3  # Lowered from 0.5 for better detection
        )
        self.mp_drawing = mp.solutions.drawing_utils
    
    def estimate_pose(self, frame):
        try:
            # Check if image needs to be rotated based on orientation
            height, width = frame.shape[:2]
            if height > width:
                print("Rotating image to landscape orientation")
                frame = cv2.rotate(frame, cv2.ROTATE_90_CLOCKWISE)
            
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            print("Processing image with dimensions:", frame_rgb.shape)
            results = self.pose.process(frame_rgb)
            return results, frame
        except Exception as e:
            print(f"Error in pose estimation: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"Error during pose estimation: {str(e)}"
            )

    def get_landmarks(self, results):
        if not results.pose_landmarks:
            print("No pose landmarks detected in results")
            return []
        print("Successfully extracted landmarks")
        return results.pose_landmarks.landmark

    def calculate_distance(self, point1, point2, frame_height):
        """Calculate distance between two points in real-world units (cm)"""
        try:
            # Reference height of an average adult in cm
            REFERENCE_HEIGHT = 170
            pixel_distance = math.sqrt(
                (point1.x - point2.x) ** 2 + 
                (point1.y - point2.y) ** 2
            ) * frame_height
            # Scale the distance according to the reference height
            return (pixel_distance * REFERENCE_HEIGHT) / frame_height
        except Exception as e:
            print(f"Error calculating distance: {str(e)}")
            return 0

    def get_measurement_points(self, landmarks, limb_type, frame_width, frame_height):
        """Get measurement points for visualization"""
        try:
            points = []
            distances = []

            if "Left" in limb_type:
                if "Knee" in limb_type:
                    print("Processing left knee measurements")
                    hip = landmarks[self.mp_pose.PoseLandmark.LEFT_HIP]
                    knee = landmarks[self.mp_pose.PoseLandmark.LEFT_KNEE]
                    ankle = landmarks[self.mp_pose.PoseLandmark.LEFT_ANKLE]
                    
                    points = [
                        {"x": hip.x * frame_width, "y": hip.y * frame_height},
                        {"x": knee.x * frame_width, "y": knee.y * frame_height},
                        {"x": ankle.x * frame_width, "y": ankle.y * frame_height}
                    ]
                    
                    hip_to_knee = self.calculate_distance(hip, knee, frame_height)
                    knee_to_ankle = self.calculate_distance(knee, ankle, frame_height)
                    distances = [hip_to_knee, knee_to_ankle]
                    
                elif "Ankle" in limb_type:
                    print("Processing left ankle measurements")
                    knee = landmarks[self.mp_pose.PoseLandmark.LEFT_KNEE]
                    ankle = landmarks[self.mp_pose.PoseLandmark.LEFT_ANKLE]
                    foot = landmarks[self.mp_pose.PoseLandmark.LEFT_FOOT_INDEX]
                    
                    points = [
                        {"x": knee.x * frame_width, "y": knee.y * frame_height},
                        {"x": ankle.x * frame_width, "y": ankle.y * frame_height},
                        {"x": foot.x * frame_width, "y": foot.y * frame_height}
                    ]
                    
                    knee_to_ankle = self.calculate_distance(knee, ankle, frame_height)
                    ankle_to_foot = self.calculate_distance(ankle, foot, frame_height)
                    distances = [knee_to_ankle, ankle_to_foot]

            else:  # Right side
                if "Knee" in limb_type:
                    print("Processing right knee measurements")
                    hip = landmarks[self.mp_pose.PoseLandmark.RIGHT_HIP]
                    knee = landmarks[self.mp_pose.PoseLandmark.RIGHT_KNEE]
                    ankle = landmarks[self.mp_pose.PoseLandmark.RIGHT_ANKLE]
                    
                    points = [
                        {"x": hip.x * frame_width, "y": hip.y * frame_height},
                        {"x": knee.x * frame_width, "y": knee.y * frame_height},
                        {"x": ankle.x * frame_width, "y": ankle.y * frame_height}
                    ]
                    
                    hip_to_knee = self.calculate_distance(hip, knee, frame_height)
                    knee_to_ankle = self.calculate_distance(knee, ankle, frame_height)
                    distances = [hip_to_knee, knee_to_ankle]
                    
                elif "Ankle" in limb_type:
                    print("Processing right ankle measurements")
                    knee = landmarks[self.mp_pose.PoseLandmark.RIGHT_KNEE]
                    ankle = landmarks[self.mp_pose.PoseLandmark.RIGHT_ANKLE]
                    foot = landmarks[self.mp_pose.PoseLandmark.RIGHT_FOOT_INDEX]
                    
                    points = [
                        {"x": knee.x * frame_width, "y": knee.y * frame_height},
                        {"x": ankle.x * frame_width, "y": ankle.y * frame_height},
                        {"x": foot.x * frame_width, "y": foot.y * frame_height}
                    ]
                    
                    knee_to_ankle = self.calculate_distance(knee, ankle, frame_height)
                    ankle_to_foot = self.calculate_distance(ankle, foot, frame_height)
                    distances = [knee_to_ankle, ankle_to_foot]

            print(f"Generated {len(points)} measurement points for {limb_type}")
            return points, distances
        except Exception as e:
            print(f"Error getting measurement points: {str(e)}")
            return [], []

    def detect_asymmetry(self, landmarks, frame_height):
        """Detect asymmetry between left and right limbs"""
        try:
            # Calculate distances for left and right limbs
            left_hip = landmarks[self.mp_pose.PoseLandmark.LEFT_HIP]
            left_knee = landmarks[self.mp_pose.PoseLandmark.LEFT_KNEE]
            left_ankle = landmarks[self.mp_pose.PoseLandmark.LEFT_ANKLE]
            left_foot = landmarks[self.mp_pose.PoseLandmark.LEFT_FOOT_INDEX]
            
            right_hip = landmarks[self.mp_pose.PoseLandmark.RIGHT_HIP]
            right_knee = landmarks[self.mp_pose.PoseLandmark.RIGHT_KNEE]
            right_ankle = landmarks[self.mp_pose.PoseLandmark.RIGHT_ANKLE]
            right_foot = landmarks[self.mp_pose.PoseLandmark.RIGHT_FOOT_INDEX]
            
            # Calculate key distances
            left_hip_knee = self.calculate_distance(left_hip, left_knee, frame_height)
            left_knee_ankle = self.calculate_distance(left_knee, left_ankle, frame_height)
            
            right_hip_knee = self.calculate_distance(right_hip, right_knee, frame_height)
            right_knee_ankle = self.calculate_distance(right_knee, right_ankle, frame_height)
            
            # Calculate asymmetry scores (0 = perfectly symmetric, higher = more asymmetric)
            hip_knee_asymmetry = abs(left_hip_knee - right_hip_knee) / max(left_hip_knee, right_hip_knee) if max(left_hip_knee, right_hip_knee) > 0 else 0
            knee_ankle_asymmetry = abs(left_knee_ankle - right_knee_ankle) / max(left_knee_ankle, right_knee_ankle) if max(left_knee_ankle, right_knee_ankle) > 0 else 0
            
            print(f"Hip-knee asymmetry score: {hip_knee_asymmetry:.4f}")
            print(f"Knee-ankle asymmetry score: {knee_ankle_asymmetry:.4f}")
            
            # Return asymmetry data
            return {
                "hip_knee_asymmetry": float(hip_knee_asymmetry),
                "knee_ankle_asymmetry": float(knee_ankle_asymmetry),
                "left_hip_knee": float(left_hip_knee),
                "right_hip_knee": float(right_hip_knee),
                "left_knee_ankle": float(left_knee_ankle),
                "right_knee_ankle": float(right_knee_ankle)
            }
            
        except Exception as e:
            print(f"Error calculating asymmetry: {str(e)}")
            return {
                "hip_knee_asymmetry": 0,
                "knee_ankle_asymmetry": 0,
                "left_hip_knee": 0,
                "right_hip_knee": 0,
                "left_knee_ankle": 0,
                "right_knee_ankle": 0
            }

    def detect_potential_prosthetic_needs(self, landmarks, frame_width, frame_height):
        """Detect limbs that might need prosthetic support using multiple criteria"""
        potential_needs = []
        
        if not landmarks:
            print("No landmarks provided for detection")
            return potential_needs

        # Define limb positions to analyze
        limb_positions = {
            "Left_Knee": self.mp_pose.PoseLandmark.LEFT_KNEE,
            "Right_Knee": self.mp_pose.PoseLandmark.RIGHT_KNEE,
            "Left_Ankle": self.mp_pose.PoseLandmark.LEFT_ANKLE,
            "Right_Ankle": self.mp_pose.PoseLandmark.RIGHT_ANKLE,
        }
        
        # Calculate asymmetry scores between left and right limbs
        asymmetry_data = self.detect_asymmetry(landmarks, frame_height)
        
        # Set detection thresholds
        ASYMMETRY_THRESHOLD = 0.15  # 15% difference between limbs indicates potential need
        VISIBILITY_THRESHOLD = 0.65  # Lower visibility might indicate obstruction or assistive device
        
        # Analyze each limb
        for limb_name, landmark in limb_positions.items():
            print(f"Analyzing {limb_name}: visibility {landmarks[landmark].visibility:.4f}")
            
            # Prepare detection criteria results
            detection_reasons = []
            confidence_score = 0.0
            
            # Check visibility - might indicate a prosthetic already in place
            if landmarks[landmark].visibility < VISIBILITY_THRESHOLD:
                detection_reasons.append(f"Low visibility ({landmarks[landmark].visibility:.2f})")
                confidence_score += 0.3
            
            # Check asymmetry between left and right limbs
            if "Knee" in limb_name:
                asymmetry = asymmetry_data["hip_knee_asymmetry"]
                if asymmetry > ASYMMETRY_THRESHOLD:
                    detection_reasons.append(f"Hip-knee asymmetry detected ({asymmetry:.2f})")
                    confidence_score += 0.4
            elif "Ankle" in limb_name:
                asymmetry = asymmetry_data["knee_ankle_asymmetry"]
                if asymmetry > ASYMMETRY_THRESHOLD:
                    detection_reasons.append(f"Knee-ankle asymmetry detected ({asymmetry:.2f})")
                    confidence_score += 0.4
            
            # If any detection criteria met, add this limb to potential needs
            if detection_reasons or True:  # Always include for testing
                x_pixel = int(landmarks[landmark].x * frame_width)
                y_pixel = int(landmarks[landmark].y * frame_height)
                
                points, distances = self.get_measurement_points(
                    landmarks, limb_name, frame_width, frame_height)
                
                measurements = self.calculate_measurements(
                    landmarks, limb_name, frame_height, distances)
                
                # Calculate final confidence (cap at 1.0)
                final_confidence = min(confidence_score + 0.3, 1.0)  # Add base confidence
                
                potential_needs.append({
                    "limb_type": limb_name,
                    "coordinates": {"x": x_pixel, "y": y_pixel},
                    "confidence": final_confidence,
                    "detection_reasons": detection_reasons,
                    "recommended_size": measurements,
                    "points": points,
                    "distances": distances,
                    "asymmetry_data": asymmetry_data
                })
                print(f"Added {limb_name} as potential prosthetic need with confidence {final_confidence:.2f}")
        
        return potential_needs

    def calculate_measurements(self, landmarks, limb_type, frame_height, distances):
        """Calculate recommended prosthetic measurements"""
        try:
            measurements = {}
            
            if "Knee" in limb_type:
                primary_length = distances[0]
                measurements = {
                    "length": float(primary_length),
                    "circumference": float(primary_length * 0.35),
                    "width": float(primary_length * 0.12)
                }
                
            elif "Ankle" in limb_type:
                primary_length = distances[0]
                measurements = {
                    "length": float(primary_length),
                    "circumference": float(primary_length * 0.25),
                    "width": float(primary_length * 0.08)
                }
            
            print(f"Calculated measurements for {limb_type}: {measurements}")
            return measurements
        except Exception as e:
            print(f"Error calculating measurements: {str(e)}")
            return {"length": 0, "circumference": 0, "width": 0}

    def create_visualization(self, image, landmarks, potential_needs, width, height):
        """Create visualization with landmarks and measurements"""
        try:
            # Create a copy of the image for visualization
            vis_image = image.copy()
            
            # Draw pose landmarks
            mp_drawing = mp.solutions.drawing_utils
            mp_drawing_styles = mp.solutions.drawing_styles
            
            # Draw the pose landmarks
            mp_drawing.draw_landmarks(
                vis_image,
                mp.solutions.pose.PoseLandmark(landmarks),
                mp.solutions.pose.POSE_CONNECTIONS,
                landmark_drawing_spec=mp_drawing_styles.get_default_pose_landmarks_style()
            )
            
            # Draw measurements for each detected need
            for need in potential_needs:
                # Draw measurement points
                for point in need['points']:
                    cv2.circle(
                        vis_image, 
                        (int(point['x']), int(point['y'])), 
                        radius=5, 
                        color=(0, 0, 255),  # Red
                        thickness=-1  # Filled circle
                    )
                
                # Draw lines between points
                for i in range(len(need['points']) - 1):
                    pt1 = (int(need['points'][i]['x']), int(need['points'][i]['y']))
                    pt2 = (int(need['points'][i+1]['x']), int(need['points'][i+1]['y']))
                    cv2.line(vis_image, pt1, pt2, (0, 255, 0), 2)  # Green line
                    
                    # Add measurement text
                    mid_x = (pt1[0] + pt2[0]) // 2
                    mid_y = (pt1[1] + pt2[1]) // 2
                    cv2.putText(
                        vis_image,
                        f"{need['distances'][i]:.1f} cm",
                        (mid_x, mid_y - 10),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.5,
                        (255, 255, 255),  # White text
                        2  # Thickness
                    )
                
                # Indicate the potential prosthetic need with a label
                coord_x = int(need['coordinates']['x'])
                coord_y = int(need['coordinates']['y'])
                confidence = need['confidence']
                cv2.putText(
                    vis_image,
                    f"{need['limb_type']} ({confidence:.2f})",
                    (coord_x - 10, coord_y - 20),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.7,
                    (0, 0, 255),  # Red text
                    2  # Thickness
                )
                
            # Convert back to JPEG for returning to client
            _, buffer = cv2.imencode('.jpg', vis_image)
            return buffer.tobytes()
            
        except Exception as e:
            print(f"Error creating visualization: {str(e)}")
            return None

pose_estimator = ProstheticPoseEstimator()

@app.post("/analyze/image")
async def analyze_image(file: UploadFile = File(...)):
    print("Received image analysis request")
    try:
        # Read and process the image
        contents = await file.read()
        print("Successfully read file contents")
        
        nparr = np.frombuffer(contents, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            print("Failed to decode image")
            return {
                "success": False,
                "message": "Invalid image data. Please try a different image.",
                "missing_limbs": []
            }
        
        print(f"Successfully decoded image with shape: {image.shape}")
        height, width = image.shape[:2]
        
        # Estimate pose
        results, processed_image = pose_estimator.estimate_pose(image)
        if not results.pose_landmarks:
            print("No pose landmarks detected in image")
            return {
                "success": False,
                "message": "Could not detect body pose clearly in the image. Please ensure the full body is visible.",
                "missing_limbs": []
            }
        
        # Get landmarks
        landmarks = pose_estimator.get_landmarks(results)
        if not landmarks:
            print("Failed to extract landmarks from results")
            return {
                "success": False,
                "message": "Failed to extract pose landmarks. Please try again with a clearer image.",
                "missing_limbs": []
            }
        
        # Detect potential prosthetic needs
        potential_needs = pose_estimator.detect_potential_prosthetic_needs(landmarks, width, height)
        
        # Create visualization with annotations
        visualization = pose_estimator.create_visualization(
            processed_image, results.pose_landmarks, potential_needs, width, height)
        
        # Always return results, even if no potential needs detected
        if not potential_needs:
            print("No potential prosthetic needs detected")
            return {
                "success": True,
                "message": "Analysis complete. No specific prosthetic needs detected based on current criteria.",
                "missing_limbs": [],
                "image_dimensions": {"width": width, "height": height}
            }
        
        print(f"Analysis complete. Found {len(potential_needs)} potential prosthetic needs")
        return {
            "success": True,
            "message": f"Analysis complete. Found {len(potential_needs)} potential prosthetic needs.",
            "missing_limbs": potential_needs,
            "image_dimensions": {"width": width, "height": height}
        }
        
    except Exception as e:
        print(f"Error during image analysis: {str(e)}")
        return {
            "success": False,
            "message": f"An error occurred during image analysis: {str(e)}",
            "missing_limbs": []
        }

@app.get("/")
async def root():
    return {
        "message": "Prosthetic Measurement API is running",
        "version": "2.1",
        "features": [
            "Pose detection",
            "Asymmetry analysis",
            "Prosthetic need identification",
            "Measurement calculation",
            "Visualization points"
        ]
    }