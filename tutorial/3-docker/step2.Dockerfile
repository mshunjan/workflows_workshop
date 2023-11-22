# Start from a Python base image
FROM python:3.8-slim

# Set environment variables
ENV PLOTLY_VERSION=5.0.0 \
    PANDAS_VERSION=1.2.5 \
    PYTHONUNBUFFERED=1

# Install system dependencies (if any)
RUN apt-get update && \
    apt-get install -y --no-install-recommends some-package && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir pandas==$PANDAS_VERSION plotly==$PLOTLY_VERSION

# Create a directory for the app
WORKDIR /app

# Copy only the requirements first to leverage Docker cache
COPY requirements.txt /app/

# Install any Python packages listed in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application's code
COPY . /app

# Set a non-root user and switch to it
RUN useradd -m appuser
USER appuser

# Set the default command for the container
CMD ["python", "/app/plot_data.py"]
