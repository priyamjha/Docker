## 🔹 Django Dockerfile

```dockerfile
FROM python:3.12.9-slim-bookworm
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
WORKDIR /django_project
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
```

* `PYTHONUNBUFFERED=1` → logs appear instantly.
* `PYTHONDONTWRITEBYTECODE=1` → avoids `.pyc` cache files.
* `0.0.0.0` → bind Django to all network interfaces (needed inside container).

---

### Professional Django Dockerfile

```dockerfile
FROM python:3.12.9-slim-bookworm
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
```

👉 For production → replace CMD with Gunicorn:

```dockerfile
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "django_project.wsgi:application"]
```

---

### Run Django with Volume (Live Code Updates)

```bash
docker build -t django-docker-image .
docker run -d --name django-container -v .:/django_docker_project -p 8888:8000 django-docker-image
```

* `-v .:/django_docker_project` → mounts local project folder into container.
* Real-time updates: when I edit files locally → changes reflect inside container.

---

## 🔹 Docker Compose

Compose = define multiple containers in one YAML file.

### Example: Single Django Service

```yaml
name: docker-project
services:
  app:
    image: django-docker-image
    container_name: django-docker-container
    ports:
      - "8000:8000"
    volumes:
      - .:/django_docker_project
```

Run:

```bash
docker compose up -d
```

---

### Example: Build + Run

```yaml
name: docker-project
services:
  app:
    build:
      context: .
      dockerfile: dockerfile
    image: django-docker-image
    container_name: django-docker-container
    ports:
      - "8000:8000"
    volumes:
      - .:/django_docker_project
```

Run:

```bash
docker compose up -d --build
```

---

## 🔹 PostgreSQL with Django (Compose)

```yaml
name: docker-project
services:
  app:
    build:
      context: .
      dockerfile: dockerfile
    image: django-docker-image
    container_name: django-docker-container
    ports:
      - "8000:8000"
    volumes:
      - .:/django_docker_project
    depends_on:
      - db

  db:
    image: postgres:17
    container_name: postgres-container
    restart: always
    environment:
      POSTGRES_USER: my_user
      POSTGRES_PASSWORD: my_password
      POSTGRES_DB: my_database
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

### Django `settings.py`

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'my_database',
        'USER': 'my_user',
        'PASSWORD': 'my_password',
        'HOST': 'db',   # same as service name
        'PORT': '5432',
    }
}
```

### Run

```bash
docker compose up -d --build
docker exec -it django-docker-container python manage.py migrate
docker exec -it django-docker-container python manage.py createsuperuser
```

---

## 🔹 Persist Data With Docker Volume (Compose)

This is the section that needs focus — a clear Compose setup for Django + Postgres while persisting DB data using a named volume:


### docker-compose.yml
```yaml
name: docker-project

services:
  app:
    build:
      context: .
      dockerfile: dockerfile
    image: django-docker-image
    container_name: django-docker-container
    ports:
      - "8000:8000"
    volumes:
      - .:/django_docker_project
    depends_on:
      - db   # app waits for db service

  db:
    image: postgres:17
    container_name: postgres-container
    restart: always
    environment:
      POSTGRES_USER: my_user
      POSTGRES_PASSWORD: my_password
      POSTGRES_DB: my_database
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

### Run

```bash
docker compose up -d --build
docker exec -it django-docker-container python manage.py migrate
docker exec -it django-docker-container python manage.py createsuperuser
```

* **`postgres_data:/var/lib/postgresql/data/`**

  * Left side (`postgres_data`) → a **named volume** managed by Docker.
  * Right side (`/var/lib/postgresql/data/`) → the **internal directory** where PostgreSQL stores all its database files.
  * Result → even if the container is removed, the actual database files remain inside the `postgres_data` volume.

* This is why, after restarting or recreating the container:

  * Your tables, users, and data are **still available**.
  * Without this, everything would reset when the container is deleted.

* Think of volumes as an **external hard disk** for your containers.

---

# ✅ Summary

* `docker run` → start container.
* `docker ps` → list containers.
* `docker stop/start/rm` → manage lifecycle.
* `-v` → volumes for persistence.
* `-p` → port mapping.
* Dockerfile → define container image.
* Docker Compose → run multiple services together.
* Volumes + Compose = production-like setup.