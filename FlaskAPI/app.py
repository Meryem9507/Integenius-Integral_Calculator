# Python base image
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy app
COPY app.py .

# Expose port
EXPOSE 8080

# Prod entrypoint
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:8080", "app:app"]
