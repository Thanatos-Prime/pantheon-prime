<!DOCTYPE html>

<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Moon Constellations 🌌</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

```
    body {
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        background: radial-gradient(ellipse at center, #1a1a2e 0%, #0f0f1e 100%);
        color: #ffffff;
        overflow-x: hidden;
        min-height: 100vh;
    }

    .container {
        max-width: 1200px;
        margin: 0 auto;
        padding: 20px;
    }

    .header {
        text-align: center;
        margin-bottom: 40px;
        padding: 40px 0;
    }

    .title {
        font-size: 3.5em;
        font-weight: 300;
        margin-bottom: 10px;
        background: linear-gradient(45deg, #4facfe, #00f2fe);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
    }

    .subtitle {
        font-size: 1.2em;
        opacity: 0.8;
        max-width: 600px;
        margin: 0 auto 30px;
        line-height: 1.6;
    }

    .controls {
        display: flex;
        justify-content: center;
        gap: 20px;
        margin-bottom: 40px;
        flex-wrap: wrap;
    }

    .btn {
        padding: 12px 24px;
        border: 2px solid #4facfe;
        background: transparent;
        color: #4facfe;
        border-radius: 25px;
        cursor: pointer;
        font-size: 1em;
        transition: all 0.3s ease;
        text-decoration: none;
        display: inline-block;
    }

    .btn:hover {
        background: #4facfe;
        color: #1a1a2e;
        transform: translateY(-2px);
        box-shadow: 0 10px 20px rgba(79, 172, 254, 0.3);
    }

    .btn.primary {
        background: linear-gradient(45deg, #4facfe, #00f2fe);
        border: none;
        color: #1a1a2e;
    }

    .btn.primary:hover {
        transform: translateY(-2px);
        box-shadow: 0 10px 30px rgba(79, 172, 254, 0.5);
    }

    .main-content {
        display: grid;
        grid-template-columns: 1fr 400px;
        gap: 40px;
        align-items: start;
    }

    .constellation-container {
        position: relative;
        background: rgba(0, 20, 40, 0.6);
        border-radius: 20px;
        padding: 20px;
        border: 1px solid rgba(79, 172, 254, 0.3);
        backdrop-filter: blur(10px);
    }

    .canvas-container {
        position: relative;
        width: 100%;
        height: 500px;
        border-radius: 15px;
        overflow: hidden;
        background: radial-gradient(ellipse at 30% 20%, rgba(79, 172, 254, 0.1) 0%, transparent 50%);
    }

    #constellation-canvas {
        width: 100%;
        height: 100%;
        cursor: grab;
    }

    #constellation-canvas:active {
        cursor: grabbing;
    }

    .story-panel {
        background: rgba(0, 20, 40, 0.8);
        border-radius: 20px;
        padding: 30px;
        border: 1px solid rgba(79, 172, 254, 0.3);
        backdrop-filter: blur(10px);
        position: sticky;
        top: 20px;
    }

    .constellation-name {
        font-size: 1.8em;
        margin-bottom: 20px;
        color: #4facfe;
        text-align: center;
    }

    .constellation-story {
        line-height: 1.8;
        font-size: 1.1em;
        opacity: 0.9;
        margin-bottom: 25px;
        text-align: justify;
    }

    .constellation-stats {
        font-size: 0.9em;
        opacity: 0.7;
        border-top: 1px solid rgba(79, 172, 254, 0.2);
        padding-top: 15px;
    }

    .export-section {
        margin-top: 30px;
        text-align: center;
    }

    .loading {
        display: none;
        text-align: center;
        padding: 20px;
        font-style: italic;
        opacity: 0.7;
    }

    @keyframes twinkle {
        0%, 100% { opacity: 0.3; }
        50% { opacity: 1; }
    }

    .star {
        animation: twinkle 2s infinite;
    }

    @media (max-width: 768px) {
        .main-content {
            grid-template-columns: 1fr;
        }
        
        .title {
            font-size: 2.5em;
        }
        
        .controls {
            flex-direction: column;
            align-items: center;
        }
    }

    .hashtag {
        color: #4facfe;
        font-weight: bold;
        margin-top: 15px;
        font-size: 1.1em;
    }
</style>
```

</head>
<body>
    <div class="container">
        <div class="header">
            <h1 class="title">Moon Constellations 🌌</h1>
            <p class="subtitle">
                See Earth as a sky: connect city lights into constellations, and let AI write their myths.
                Each constellation tells a story of human connection across our luminous planet.
            </p>
            <div class="controls">
                <button class="btn primary" onclick="generateConstellation()">Generate New Constellation</button>
                <button class="btn" onclick="exportImage()">Export as PNG</button>
                <a href="#" class="btn" onclick="shareOnTwitter()">Share on X/Twitter</a>
            </div>
        </div>

```
    <div class="main-content">
        <div class="constellation-container">
            <div class="canvas-container">
                <canvas id="constellation-canvas"></canvas>
            </div>
        </div>

        <div class="story-panel">
            <div class="loading" id="loading">Generating constellation story...</div>
            <div id="story-content">
                <h2 class="constellation-name" id="constellation-name">The Digital Heartlands</h2>
                <div class="constellation-story" id="constellation-story">
                    In the age before memory, when cities first learned to dream in electric light, seven great nodes awakened across the continents. These were not mere settlements, but luminous hearts pumping data through fiber-optic arteries. The constellation of the Digital Heartlands connects New York to Tokyo, London to São Paulo, forming a crown of human ambition that glitters against the cosmic dark.
                </div>
                <div class="constellation-stats" id="constellation-stats">
                    Stars: 7 • Connections: 12 • Spanning: 3 continents
                </div>
                <div class="hashtag">#MoonConstellations</div>
            </div>
            <div class="export-section">
                <button class="btn" onclick="generateConstellation()">New Story</button>
            </div>
        </div>
    </div>
</div>

<script>
    const canvas = document.getElementById('constellation-canvas');
    const ctx = canvas.getContext('2d');
    let currentConstellation = null;
    
    // Constellation data and stories
    const constellationTemplates = [
        {
            name: "The Digital Heartlands",
            story: "In the age before memory, when cities first learned to dream in electric light, seven great nodes awakened across the continents. These were not mere settlements, but luminous hearts pumping data through fiber-optic arteries. The constellation of the Digital Heartlands connects New York to Tokyo, London to São Paulo, forming a crown of human ambition that glitters against the cosmic dark.",
            cities: ["New York", "Tokyo", "London", "São Paulo", "Singapore", "Dubai", "Sydney"]
        },
        {
            name: "The Midnight Travelers",
            story: "When the world sleeps, the Midnight Travelers emerge—a constellation born from red-eye flights and late-night connections. These lights dance across time zones, carrying dreams between sleeping cities. Each point of light represents a soul in transit, suspended between yesterday and tomorrow, weaving stories across the globe's dark canvas.",
            cities: ["Los Angeles", "Amsterdam", "Bangkok", "Cairo", "Mumbai", "Toronto"]
        },
        {
            name: "The Silicon Rivers",
            story: "Like ancient rivers of gold, the Silicon Rivers flow through valleys and across plains, connecting innovation hubs in a web of possibility. From the original Silicon Valley to Bangalore's tech gardens, from Stockholm's digital archipelago to Tel Aviv's startup shores—this constellation pulses with the rhythm of human creativity.",
            cities: ["San Francisco", "Bangalore", "Stockholm", "Tel Aviv", "Austin", "Berlin", "Shenzhen"]
        },
        {
            name: "The Ocean's Edge",
            story: "Where land meets sea, the Ocean's Edge constellation traces humanity's eternal relationship with the horizon. These coastal cities have always been gateways—for trade, for dreams, for those who dare to look beyond. Their lights reflect in dark waters, doubling their beauty and their promise.",
            cities: ["Barcelona", "Vancouver", "Rio de Janeiro", "Cape Town", "Melbourne", "Miami"]
        },
        {
            name: "The Ancient Modern",
            story: "In cities where pyramids cast shadows on fiber optic cables, where Roman roads lead to data centers, the Ancient Modern constellation bridges millennia. These lights represent humanity's longest conversations—between past and future, tradition and innovation, the eternal and the electric.",
            cities: ["Rome", "Athens", "Istanbul", "Jerusalem", "Beijing", "Kyoto", "Delhi"]
        }
    ];

    function resizeCanvas() {
        const container = canvas.parentElement;
        canvas.width = container.clientWidth;
        canvas.height = container.clientHeight;
        if (currentConstellation) {
            drawConstellation(currentConstellation);
        }
    }

    function generateRandomConstellation() {
        const template = constellationTemplates[Math.floor(Math.random() * constellationTemplates.length)];
        const numStars = template.cities.length;
        const stars = [];
        const connections = [];

        // Generate star positions
        for (let i = 0; i < numStars; i++) {
            stars.push({
                x: Math.random() * (canvas.width - 100) + 50,
                y: Math.random() * (canvas.height - 100) + 50,
                brightness: 0.5 + Math.random() * 0.5,
                size: 2 + Math.random() * 3,
                city: template.cities[i]
            });
        }

        // Generate connections (create a connected graph)
        const visited = new Set();
        const queue = [0];
        visited.add(0);

        while (queue.length > 0 && visited.size < stars.length) {
            const current = queue.shift();
            const unvisited = stars.filter((_, i) => !visited.has(i));
            
            if (unvisited.length > 0) {
                const target = Math.floor(Math.random() * stars.length);
                if (!visited.has(target)) {
                    connections.push({ from: current, to: target });
                    visited.add(target);
                    queue.push(target);
                }
            }
        }

        // Add some additional random connections for complexity
        for (let i = 0; i < Math.floor(numStars * 0.3); i++) {
            const from = Math.floor(Math.random() * numStars);
            const to = Math.floor(Math.random() * numStars);
            if (from !== to && !connections.some(c => (c.from === from && c.to === to) || (c.from === to && c.to === from))) {
                connections.push({ from, to });
            }
        }

        return {
            name: template.name,
            story: template.story,
            stars,
            connections,
            cities: template.cities
        };
    }

    function drawConstellation(constellation) {
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Draw connections first
        ctx.strokeStyle = 'rgba(79, 172, 254, 0.4)';
        ctx.lineWidth = 1;
        ctx.setLineDash([5, 3]);

        constellation.connections.forEach(conn => {
            const star1 = constellation.stars[conn.from];
            const star2 = constellation.stars[conn.to];
            
            ctx.beginPath();
            ctx.moveTo(star1.x, star1.y);
            ctx.lineTo(star2.x, star2.y);
            ctx.stroke();
        });

        ctx.setLineDash([]);

        // Draw stars
        constellation.stars.forEach((star, index) => {
            // Outer glow
            const gradient = ctx.createRadialGradient(star.x, star.y, 0, star.x, star.y, star.size * 3);
            gradient.addColorStop(0, `rgba(79, 172, 254, ${star.brightness})`);
            gradient.addColorStop(1, 'rgba(79, 172, 254, 0)');
            
            ctx.fillStyle = gradient;
            ctx.beginPath();
            ctx.arc(star.x, star.y, star.size * 3, 0, Math.PI * 2);
            ctx.fill();

            // Inner bright star
            ctx.fillStyle = `rgba(255, 255, 255, ${star.brightness})`;
            ctx.beginPath();
            ctx.arc(star.x, star.y, star.size, 0, Math.PI * 2);
            ctx.fill();

            // City label
            ctx.fillStyle = 'rgba(255, 255, 255, 0.8)';
            ctx.font = '12px sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText(star.city, star.x, star.y - star.size * 4);
        });
    }

    function updateStoryPanel(constellation) {
        document.getElementById('constellation-name').textContent = constellation.name;
        document.getElementById('constellation-story').textContent = constellation.story;
        document.getElementById('constellation-stats').textContent = 
            `Stars: ${constellation.stars.length} • Connections: ${constellation.connections.length} • Cities: ${constellation.cities.join(', ')}`;
    }

    function generateConstellation() {
        const loading = document.getElementById('loading');
        const content = document.getElementById('story-content');
        
        loading.style.display = 'block';
        content.style.display = 'none';

        setTimeout(() => {
            currentConstellation = generateRandomConstellation();
            drawConstellation(currentConstellation);
            updateStoryPanel(currentConstellation);
            
            loading.style.display = 'none';
            content.style.display = 'block';
        }, 1000);
    }

    function exportImage() {
        const link = document.createElement('a');
        link.download = `moon-constellation-${currentConstellation.name.toLowerCase().replace(/\s+/g, '-')}.png`;
        link.href = canvas.toDataURL();
        link.click();
    }

    function shareOnTwitter() {
        if (!currentConstellation) return;
        
        const text = `Just discovered "${currentConstellation.name}" constellation! ${currentConstellation.story.substring(0, 100)}... #MoonConstellations`;
        const url = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}`;
        window.open(url, '_blank');
    }

    // Initialize
    window.addEventListener('resize', resizeCanvas);
    window.addEventListener('load', () => {
        resizeCanvas();
        generateConstellation();
    });

    // Add some interactivity
    let isDragging = false;
    let dragStart = { x: 0, y: 0 };

    canvas.addEventListener('mousedown', (e) => {
        isDragging = true;
        dragStart = { x: e.offsetX, y: e.offsetY };
    });

    canvas.addEventListener('mousemove', (e) => {
        if (!isDragging || !currentConstellation) return;
        
        // Simple pan effect - could be enhanced
        const dx = e.offsetX - dragStart.x;
        const dy = e.offsetY - dragStart.y;
        
        // Update star positions slightly for interactive feel
        currentConstellation.stars.forEach(star => {
            star.x += dx * 0.01;
            star.y += dy * 0.01;
        });
        
        drawConstellation(currentConstellation);
        dragStart = { x: e.offsetX, y: e.offsetY };
    });

    canvas.addEventListener('mouseup', () => {
        isDragging = false;
    });

    // Animate stars twinkling
    setInterval(() => {
        if (currentConstellation) {
            currentConstellation.stars.forEach(star => {
                star.brightness = 0.5 + Math.random() * 0.5;
            });
            drawConstellation(currentConstellation);
        }
    }, 2000);
</script>
```

</body>
</html>