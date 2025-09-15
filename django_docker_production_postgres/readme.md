# 🚀 Django + Docker + PostgreSQL + Render Deployment

This guide covers **containerizing a Django app**, **managing PostgreSQL**, **handling static files**, and **deploying with Render & GitHub Container Registry (GHCR)**.

---

## 📌 PROFESSIONAL Django DockerFile - `dockerfile`

```dockerfile
# Use an official lightweight Python base image
FROM python:3.12.9-slim-bookworm

# Environment settings
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Set working directory inside container
WORKDIR /django_docker_project

# Copy only requirements first (better caching)
COPY requirements.txt .

# Upgrade pip and install dependencies in one step
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy the entire project
COPY . .

# Expose Django default port
EXPOSE 8000

# Run Django development server (development mode)
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
````

### 🔹 Notes

* For **development** → keep the `runserver` command.
* For **production** → replace `CMD` with **Gunicorn**:

```dockerfile
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "django_project.wsgi:application"]
```

---

## 📌 PostgreSQL Configuration - `settings.py`

If you are using **external DB services** (like [Render](https://render.com/)):

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'database_name',
        'USER': 'username',
        'PASSWORD': 'password',
        'HOST': 'External Database URL',
        'PORT': '5432',
    }
}
```

### Terminal

```bash
python manage.py migrate
```

---

## 📌 Docker Compose - `docker-compose.yml`

### Case 1 → Build image inside Compose

```yaml
name: docker-project

services:
  app:
    build:
      context: .
      dockerfile: dockerfile
    image: app-image
    container_name: app-container
    ports:
      - "8000:8000"
    volumes:
      - .:/django_docker_project
```

**Run:**

```bash
docker compose up -d --build
```

---

### Case 2 → If image already exists

```yaml
name: docker-project

services:
  app:
    image: app-image
    container_name: app-container
    ports:
      - "8000:8000"
    volumes:
      - .:/django_docker_project
```

**Run:**

```bash
docker compose up -d
```

---

## 📌 Handle Static Assets with WhiteNoise

📖 Docs: [WhiteNoise](https://whitenoise.readthedocs.io/en/latest/)

```python
STATICFILES_DIRS = [BASE_DIR / 'static']
STATIC_ROOT = BASE_DIR / 'staticfiles'

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
]

STORAGES = {
    "staticfiles": {
        "BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage",
    },
}
```

### Terminal

```bash
python manage.py collectstatic
```

---

## 📌 Push Docker Image to GitHub Container Registry (GHCR)

```bash
docker login ghcr.io --username <GitHubUserName> --password <GitHubPersonalAccessToken>

docker build -t ghcr.io/priyamjha2003/app-image .

docker push ghcr.io/priyamjha2003/app-image
```

---

## 📌 Deploy Docker Image to Render

🎥 Reference Video → [Render Deployment](https://youtu.be/HcgV-8QY-0c?si=fxexydHhdzDQa8G9&t=4340)

---

✅ With this setup:

* Local dev → use **Docker Compose** + volumes.
* Production → build image, push to GHCR, then deploy on Render with Gunicorn + WhiteNoise.