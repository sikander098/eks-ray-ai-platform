#!/bin/bash
kubectl exec -n ai-inference phi-3-mini-6bb987979c-7692l -- \
  curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "wangyiqun/Phi-3-mini-4k-instruct-awq",
    "messages": [
      {
        "role": "user",
        "content": "Say hello and tell me what you are in one sentence!"
      }
    ],
    "max_tokens": 50,
    "temperature": 0.7
  }'
