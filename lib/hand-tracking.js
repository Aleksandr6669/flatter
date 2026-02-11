(() => {
    // --- URLs for dynamic loading ---
    const MEDIAPIPE_HANDS_URL = 'https://cdn.jsdelivr.net/npm/@mediapipe/hands/hands.js';
    const MEDIAPIPE_DRAWING_URL = 'https://cdn.jsdelivr.net/npm/@mediapipe/drawing_utils/drawing_utils.js';

    // --- Element and state variables ---
    let video, canvas, ctx, handCursor, hands;
    let handControlActive = false, isPinching = false;
    let activeWindow = null, offset = { x: 0, y: 0 };
    let smoothedLandmarks = [], isFirstFrame = true;
    const smoothingFactor = 0.2;

    function injectHandTrackingStyles() {
        const styles = `
            #hand-canvas {
                position: fixed;
                inset: 0;
                z-index: 6000; /* Higher than modal (5000) */
                pointer-events: none;
                transform: scaleX(-1);
            }
            #hand-cursor {
                position: fixed;
                width: 20px;
                height: 20px;
                border: 3px solid #06b6d4;
                border-radius: 50%;
                background: rgba(6, 182, 212, 0.3);
                z-index: 6001; /* Higher than canvas */
                pointer-events: none;
                transform: translate(-50%, -50%);
                transition: background-color 0.2s, width 0.2s, height 0.2s, transform 0.2s ease-out;
            }
            #hand-cursor.clicking {
                background: rgba(6, 182, 212, 0.8);
                transform: translate(-50%, -50%) scale(0.8);
            }
            #video-hidden { display: none; }

            .cart {
                position: absolute;
            }
        `;
        const styleSheet = document.createElement("style");
        styleSheet.type = "text/css";
        styleSheet.innerText = styles;
        document.head.appendChild(styleSheet);
    }

    function createHandTrackingElements() {
        canvas = document.createElement('canvas');
        canvas.id = 'hand-canvas';

        handCursor = document.createElement('div');
        handCursor.id = 'hand-cursor';
        handCursor.className = 'hidden';

        video = document.createElement('video');
        video.id = 'video-hidden';
        video.playsInline = true;

        const btn = document.createElement('button');
        btn.id = 'start-hand-control-btn';
        btn.className = 'btn-ui fixed bottom-5 right-5 z-[1002]';
        btn.textContent = 'Enable Hand Control';
        btn.addEventListener('click', startHandTracking);

        document.body.append(canvas, handCursor, video, btn);
        ctx = canvas.getContext('2d');
    }

    function loadScript(src) {
        return new Promise((resolve, reject) => {
            if (document.querySelector(`script[src="${src}"]`)) return resolve();
            const script = document.createElement('script');
            script.src = src;
            script.crossOrigin = 'anonymous';
            script.onload = resolve;
            script.onerror = () => reject(`Failed to load script: ${src}`);
            document.head.appendChild(script);
        });
    }

    function onResults(results) {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        const btn = document.getElementById('start-hand-control-btn');
        if (btn && btn.textContent === "Калибровка...") {
             btn.textContent = "Управление активно";
             btn.style.backgroundColor = '#059669';
        }

        if (!results.multiHandLandmarks || results.multiHandLandmarks.length === 0) {
            releaseWindow();
            if(!isFirstFrame) handCursor.classList.add('hidden');
            return;
        }
        handCursor.classList.remove('hidden');

        const rawLandmarks = results.multiHandLandmarks[0];
        if (isFirstFrame) {
            smoothedLandmarks = rawLandmarks.map(lm => ({...lm}));
            isFirstFrame = false;
        } else {
            for (let i = 0; i < rawLandmarks.length; i++) {
                smoothedLandmarks[i].x += (rawLandmarks[i].x - smoothedLandmarks[i].x) * smoothingFactor;
                smoothedLandmarks[i].y += (rawLandmarks[i].y - smoothedLandmarks[i].y) * smoothingFactor;
                smoothedLandmarks[i].z += (rawLandmarks[i].z - smoothedLandmarks[i].z) * smoothingFactor;
            }
        }

        if (window.drawConnectors) {
            drawConnectors(ctx, smoothedLandmarks, window.HAND_CONNECTIONS, {color: 'rgba(6, 182, 212, 0.5)', lineWidth: 2});
            drawLandmarks(ctx, smoothedLandmarks, {color: '#ffffff', radius: 2});
        }

        const index = smoothedLandmarks[8], thumb = smoothedLandmarks[4], middle = smoothedLandmarks[12], pinky = smoothedLandmarks[20];
        const cursorX = (1 - index.x) * window.innerWidth;
        const cursorY = index.y * window.innerHeight;
        handCursor.style.left = `${cursorX}px`;
        handCursor.style.top = `${cursorY}px`;

        const dThumbIndex = Math.hypot(thumb.x-index.x, thumb.y-index.y);
        const dIndexMiddle = Math.hypot(index.x-middle.x, index.y-middle.y);

        if (dThumbIndex < 0.07 && dIndexMiddle < 0.08) {
            if (!activeWindow) {
                const el = document.elementFromPoint(cursorX, cursorY);
                const win = el?.closest('.cart, .cart_m'); 
                if (win) {
                    activeWindow = win;
                    const rect = win.getBoundingClientRect();
                    offset.x = cursorX - rect.left;
                    offset.y = cursorY - rect.top;
                    win.classList.add('dragging');
                }
                
            }
            if (activeWindow) {
                activeWindow.style.left = `${cursorX - offset.x}px`;
                activeWindow.style.top = `${cursorY - offset.y}px`;
            }
        } else {
            releaseWindow();
        }

        if (dThumbIndex < 0.04) {
            handCursor.classList.add('clicking');
            if (!isPinching) {
                isPinching = true;
                document.elementFromPoint(cursorX, cursorY)?.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
            }
        } else {
            handCursor.classList.remove('clicking');
            isPinching = false;
        }
        
        const dThumbPinky = Math.hypot(thumb.x - pinky.x, thumb.y - pinky.y);
        const modalBody = document.querySelector('#overlay-modal.visible #modal-body');
        if (dThumbPinky > 0.2 && modalBody) {
            const handCenterY = (smoothedLandmarks.reduce((sum, lm) => sum + lm.y, 0) / smoothedLandmarks.length);
            modalBody.scrollTop += (handCenterY - 0.5) * 20;
        }
    }

    function releaseWindow() {
        if (activeWindow) {
            activeWindow.classList.remove('dragging');
            if (!activeWindow.classList.contains('cart')) {
                try {
                    const positions = JSON.parse(localStorage.getItem('cartPositions') || '{}');
                    positions[activeWindow.id] = {
                        top: activeWindow.style.top,
                        left: activeWindow.style.left
                    };
                    localStorage.setItem('cartPositions', JSON.stringify(positions));
                } catch (e) {
                    console.error("Failed to save cart positions:", e);
                }
            }
        }
        activeWindow = null;
    }

    async function update() {
        if (!handControlActive) return;
        await hands.send({ image: video });
        requestAnimationFrame(update);
    }

    async function startHandTracking() {
        const btn = document.getElementById('start-hand-control-btn');
        if (handControlActive) return;
        btn.textContent = "Загрузка...";
        btn.disabled = true;

        try {
            await Promise.all([loadScript(MEDIAPIPE_HANDS_URL), loadScript(MEDIAPIPE_DRAWING_URL)]);

            hands = new window.Hands({ locateFile: (f) => `https://cdn.jsdelivr.net/npm/@mediapipe/hands/${f}` });
            hands.setOptions({ maxNumHands: 1, modelComplexity: 0, minDetectionConfidence: 0.6, minTrackingConfidence: 0.6 });
            hands.onResults(onResults);

            const stream = await navigator.mediaDevices.getUserMedia({ video: { width: 320, height: 240 } });
            video.srcObject = stream;
            await video.play();
            handControlActive = true;
            isFirstFrame = true;
            btn.textContent = "Калибровка...";
            update();
        } catch(err) {
            console.error("Hand tracking failed:", err);
            btn.textContent = "Камера не найдена";
            btn.style.backgroundColor = '#4b5563';
        }
    }

    function init() {
        createHandTrackingElements();
        injectHandTrackingStyles();
        window.addEventListener('load', startHandTracking);
    }

    init();

})();


function loadCartPositions() {
    try {
        const positions = JSON.parse(localStorage.getItem('cartPositions'));
        if (positions) {
            Object.keys(positions).forEach(id => {
                const cartElement = document.getElementById(id);
                if (cartElement) {
                    cartElement.style.top = positions[id].top;
                    cartElement.style.left = positions[id].left;
                }
            });
        }
    } catch (e) {
        console.error("Failed to load cart positions:", e);
    }
}

loadCartPositions()