FROM python:3.8-slim

# Install Pandas and Plotly
RUN pip install pandas plotly

# Copy the Python script into the container
COPY plot_data.py /path/to/plot_data.py

# Set the default command (can be overridden)
CMD ["python", "/path/to/plot_data.py"]
