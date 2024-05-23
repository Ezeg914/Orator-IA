#!/bin/bash
source .venv/bin/activate
uvicorn app:app --reload --port 5000