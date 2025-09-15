# Use an official Python base image
FROM python:3.12.9-slim-bookworm

# Set working directory
WORKDIR /app

# Copy requirements first for caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the app
COPY . .

# Expose the Flask port
EXPOSE 8000

# Run the app
CMD ["python", "app.py"]