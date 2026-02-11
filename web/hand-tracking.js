
// Global variables
let videoElement;
let hands;
let canvasElement;
let canvasCtx;
let isTracking = false;
let animationFrameId;

// Function to start hand tracking
async function startHandTracking() {
    if (isTracking) return;

    // Get elements from the DOM
    videoElement = document.querySelector('.input_video');
    canvasElement = document.querySelector('.output_canvas');
    canvasCtx = canvasElement.getContext('2d');

    // Initialize MediaPipe Hands
    hands = new Hands({
        locateFile: (file) => {
            return `https://cdn.jsdelivr.net/npm/@mediapipe/hands/${file}`;
        }
    });

    hands.setOptions({
        maxNumHands: 1,
        modelComplexity: 1,
        minDetectionConfidence: 0.5,
        minTrackingConfidence: 0.5
    });

    // Set up the camera
    try {
        const stream = await navigator.mediaDevices.getUserMedia({ video: { width: 1280, height: 720 } });
        videoElement.srcObject = stream;
        videoElement.play();
        isTracking = true;
    } catch (err) {
        console.error("Error accessing camera: ", err);
        return; // Exit if camera access is denied
    }

    // Set up the onResults callback
    hands.onResults(onResults);

    // Start the animation loop
    runDetection();
}

// Function to stop hand tracking
function stopHandTracking() {
    if (!isTracking) return;

    isTracking = false;
    cancelAnimationFrame(animationFrameId);

    if (videoElement.srcObject) {
        videoElement.srcObject.getTracks().forEach(track => track.stop());
    }

    // Clear the canvas
    canvasCtx.clearRect(0, 0, canvasElement.width, canvasElement.height);
}

// The main loop for processing frames
async function runDetection() {
    if (!isTracking) return;
    await hands.send({ image: videoElement });
    animationFrameId = requestAnimationFrame(runDetection);
}

// Callback for when MediaPipe processes the results
function onResults(results) {
    canvasCtx.save();
    canvasCtx.clearRect(0, 0, canvasElement.width, canvasElement.height);

    if (results.multiHandLandmarks && results.multiHandLandmarks.length > 0) {
        const landmarks = results.multiHandLandmarks[0];
        
        // Draw connectors and landmarks
        drawConnectors(canvasCtx, landmarks, HAND_CONNECTIONS, { color: '#00FF00', lineWidth: 5 });
        drawLandmarks(canvasCtx, landmarks, { color: '#FF0000', lineWidth: 2 });

        // Send the primary hand landmark (wrist) position back to Flutter
        if (window.handDataReceiver) {
            const wrist = landmarks[0]; // Wrist landmark is at index 0
            window.handDataReceiver.updateHandPosition(wrist.x, wrist.y);
        }
    }
    canvasCtx.restore();
}
