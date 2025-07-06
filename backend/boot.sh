#!/bin/bash
source .venv/bin/activate
uvicorn app:app --reload --host 0.0.0.0 --port 5000