#!/bin/bash

# Development startup script for Hailey's Garden Egg Shop

echo "🥚 Starting Hailey's Garden Egg Shop..."

# Check if frontend dependencies are installed
if [ ! -d "frontend/node_modules" ]; then
    echo "📦 Installing frontend dependencies..."
    cd frontend && npm install && cd ..
fi

# Start backend in background
echo "🚀 Starting backend server..."
go run . &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 2

# Start frontend dev server
echo "🎨 Starting frontend dev server..."
cd frontend && npm run dev

# Cleanup on exit
trap "kill $BACKEND_PID" EXIT
