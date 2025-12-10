#!/bin/bash

# Internal GPU Load Test - Using ClusterIP service
# Purpose: Prove GPU time-slicing with internal requests

ENDPOINT="http://phi-3-service.ai-inference.svc.cluster.local:8000/v1/chat/completions"
MODEL="wangyiqun/Phi-3-mini-4k-instruct-awq"
PROMPT="Explain quantum physics in 10 words"

echo "=========================================="
echo "GPU Time-Slicing Internal Load Test"
echo "=========================================="
echo "Testing from inside cluster..."
echo "Concurrent Requests: 4"
echo "=========================================="
echo ""

# Function to send a request
send_request() {
    local request_id=$1
    echo "[Request $request_id] Started at $(date +%H:%M:%S.%N)"
    
    response=$(curl -s -X POST "$ENDPOINT" \
        -H "Content-Type: application/json" \
        --max-time 30 \
        -d "{
            \"model\": \"$MODEL\",
            \"messages\": [{\"role\": \"user\", \"content\": \"$PROMPT\"}],
            \"max_tokens\": 15
        }")
    
    content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
    
    if [ -z "$content" ] || [ "$content" == "null" ]; then
        echo "[Request $request_id] ❌ FAILED at $(date +%H:%M:%S.%N)"
    else
        echo "[Request $request_id] ✅ SUCCESS at $(date +%H:%M:%S.%N)"
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

wait

echo "=========================================="
echo "✅ Test completed!"
echo "=========================================="
