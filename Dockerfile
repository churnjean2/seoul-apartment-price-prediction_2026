FROM python:3.10.10

# XGBoost needs the OpenMP runtime, which slim images do not include
RUN apt-get update && apt-get install -y --no-install-recommends libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install packages first: this layer is cached until requirements change
COPY requirements-api.txt .
RUN pip install --no-cache-dir -r requirements-api.txt

# Then copy code and the trained model
COPY app/ app/
COPY artifacts/ artifacts/

# Render provides PORT; fall back to 8000 for local runs
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]