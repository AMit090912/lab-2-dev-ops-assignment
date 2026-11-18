# Lab 2 - sample app image
FROM python:3.12-slim

ARG APP_VERSION=1.0
ARG BROKEN=0
ENV APP_VERSION=${APP_VERSION} \
    BROKEN=${BROKEN} \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Dependencies first so this layer is cached when only the code changes
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/app.py .

# Run as a non-root user
RUN useradd --create-home appuser
USER appuser

EXPOSE 5000
HEALTHCHECK --interval=15s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
