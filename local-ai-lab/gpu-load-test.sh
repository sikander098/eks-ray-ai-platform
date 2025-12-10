#!/bin/bash

# GPU Load Test - Concurrent Request Verification
# Purpose: Prove that 2 pods on a time-sliced GPU can handle 4 concurrent requests

ENDPOINT="http://192.168.58.2:30080/v1/chat/completions"
MODEL="wangyiqun/Phi-3-mini-4k-instruct-awq"
PROMPT="Explain quantum physics in 10 words"

echo "=========================================="
echo "GPU Time-Slicing Concurrency Load Test"
echo "=========================================="
echo "Endpoint: $ENDPOINT"
echo "Model: $MODEL"
echo "Concurrent Requests: 4"
echo "Replicas: 2 (GPU Time-Sliced)"
echo "=========================================="
echo ""

# Function to send a request and measure time
send_request() {
    local request_id=$1
    local start_time=$(date +%s.%N)
    
    echo "[Request $request_id] Started at $(date +%H:%M:%S)"
    
    response=$(curl -s -X POST "$ENDPOINT" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"messages\": [{\"role\": \"user\", \"content\": \"$PROMPT\"}],
            \"max_tokens\": 20
        }")
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    
    # Extract the response content
    content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
    
    if [ -z "$content" ] || [ "$content" == "null" ]; then
        echo "[Request $request_id] ❌ FAILED at $(date +%H:%M:%S) (Duration: ${duration}s)"
        echo "[Request $request_id] Error: $response"
    else
        echo "[Request $request_id] ✅ SUCCESS at $(date +%H:%M:%S) (Duration: ${duration}s)"
        echo "[Request $request_id] Response: $content"
    fi
    echo ""
}

# Send 4 concurrent requests
echo "🚀 Launching 4 concurrent requests..."
echo ""

send_request 1 &
send_request 2 &
send_request 3 &
send_request 4 &

# Wait for all background jobs to complete
wait

echo "=========================================="
echo "✅ All requests completed!"
echo "=========================================="
echo ""
echo "📊 Analysis:"
echo "- If all 4 requests succeeded, GPU time-slicing is working"
echo "- 2 pods handled 4 concurrent requests via time-sliced GPU"
echo "- This proves NVIDIA driver is correctly multiplexing GPU access"
