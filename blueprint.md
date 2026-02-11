# Project Blueprint

## Overview

This is a native Android application built with Flutter. It uses the device's front-facing camera to perform real-time pose detection and visualizes the user's upper body skeleton on the screen.

## Features

*   **Native Android Focus:** The application is built exclusively for the Android platform.
*   **Front Camera View:** The app initializes the front-facing camera for a selfie-style user experience.
*   **Real-time Pose Detection:** It utilizes Google's ML Kit Pose Detection to identify and track 33 key body landmarks from the camera feed.
*   **Skeleton Visualization:** A custom `CustomPainter` is implemented to draw the detected pose on a canvas. It renders key landmarks as circles and connects them with lines to form a visible skeleton of the user's arms, shoulders, and torso.
*   **Dark Theme:** The application runs in a dark theme with a black background, upon which the camera feed and skeleton are displayed.

## Implementation Details

*   **`camera` package:** Used to access and manage the device's camera stream.
*   **`google_mlkit_pose_detection` package:** The core of the pose detection functionality.
*   **`PosePainter` (CustomPainter):** A custom widget responsible for drawing the skeleton. It takes the list of detected `Pose` objects and the camera image size to correctly scale and position the skeleton on the screen, handling coordinate transformations for the front-facing camera.
