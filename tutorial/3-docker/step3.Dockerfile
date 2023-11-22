# Stage 1: Build stage
FROM python:3.8-slim as builder

WORKDIR /app

# Set environment variables for Python
ENV PLOTLY_VERSION=5.0.0 \
    PANDAS_VERSION=1.2.5

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt pandas==$PANDAS_VERSION plotly==$PLOTLY_VERSION

# Copy the Python script from the same directory as the Dockerfile
COPY plot_data.py .

# Stage 2: Runtime stage
FROM python:3.8-slim

# Create app directory and set permissions
WORKDIR /app
COPY --from=builder /app /app
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Set the default command for the container
CMD ["python", "/app/plot_data.py"]
