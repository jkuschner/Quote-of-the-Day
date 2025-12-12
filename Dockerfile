FROM python:3.9-slim
WORKDIR /app

# copy requirements and install dependencies
COPY flask-quote-app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# copy app files
COPY flask-quote-app/app.py .

EXPOSE 5000
CMD ["python", "app.py"]
