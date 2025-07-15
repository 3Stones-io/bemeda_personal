#!/bin/bash

# Start local development server for BemedaPersonal documentation

echo "🚀 Starting BemedaPersonal Documentation Server..."
echo "📁 Serving from: $(pwd)"
echo ""

# Function to find an available port
find_available_port() {
    for port in 8080 8081 8082 8083 8084 8085 3000 3001 4000 4001; do
        if ! lsof -i :$port > /dev/null 2>&1; then
            echo $port
            return
        fi
    done
    echo "8090"  # fallback
}

# Find available port
PORT=$(find_available_port)

echo "📍 URL: http://localhost:$PORT"
echo "Press Ctrl+C to stop the server"
echo ""

# Try Python 3 first, then Python 2
if command -v python3 &> /dev/null; then
    python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    python -m http.server $PORT
else
    echo "❌ Python not found. Please install Python to run the local server."
    echo "💡 Alternatively, you can use any other static file server."
    echo "💡 Or try: npx serve . -p $PORT"
    exit 1
fi