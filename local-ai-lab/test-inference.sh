#!/bin/bash
curl -X POST http://192.168.58.2:30080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "wangyiqun/Phi-3-mini-4k-instruct-awq",
    "messages": [{"role": "user", "content": "Hello! What is 2+2?"}],
    "max_tokens": 50
  }'
