#!/bin/bash
kubectl exec -n ai-inference phi-3-mini-6bb987979c-7692l -- \
  curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "wangyiqun/Phi-3-mini-4k-instruct-awq",
    "messages": [
      {
        "role": "user",
        "content": "What are the best strategies to prepare for and pass the NUST entrance test exam?"
      }
    ],
    "max_tokens": 300,
    "temperature": 0.7
  }'
