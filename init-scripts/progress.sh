#!/bin/bash

echo "Waiting for services to be ready..."
for i in {1..15}; do echo -n "..."; sleep 1; done
echo ""
