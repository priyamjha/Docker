# 🐳 Docker Notes (Step by Step with Explanations)

## 🔹 Basic Docker Commands

### `docker pull`
```bash
docker pull hello-world
````

* **pull** → downloads an image from Docker Hub to local system.
* `hello-world` → a very small test image provided by Docker to check installation.

---

### `docker run`

```bash
docker run hello-world
```

* **run** = create a container from an image + start it.
* If the image doesn’t exist locally, Docker will **pull** it first.
* Container runs once and prints a message, then exits.

```bash
docker run --rm hello-world
```

* `--rm` → automatically removes the container after it exits.
* Useful for temporary tests (keeps system clean).

---

### Run Python image

```bash
docker run python:3.12-slim
```

* Starts a Python container (slim = minimal OS + Python).
* Opens Python REPL (interactive shell) if no command given.

```bash
docker run --rm python:3.12-slim python -c "print('Hello World')"
```

* Here we pass a **command** to container: `python -c ...`.
* Output → `Hello World`.
* `--rm` cleans up container immediately after running.

---

### List Images

```bash
docker image ls
docker images
```

* Both commands show local images available.

---

### Run container in background

```bash
docker run -d busybox sleep 3600
```

* `-d` → detached mode (runs in background).
* **busybox** → lightweight Linux image.
* Command: `sleep 3600` → container will run for 1 hour.

```bash
docker run -d busybox
```

* No command given → container starts, but immediately exits (nothing to do).

---

### Check Running Containers

```bash
docker ps        # only running containers
docker ps -a     # all containers (running + stopped)
```

---

### Container Logs

```bash
docker logs <Container ID>
```

* Shows stdout/stderr logs of a container.

---

### Start/Stop Containers

```bash
docker stop <Container ID>   # stops a running container
docker start <Container ID>  # restarts a stopped container
```

---

### Remove Container

```bash
docker rm <Container ID>
```

* Removes a stopped container.
* If running → use `-f` to force remove.

```bash
docker container prune
```

* Removes **all stopped containers**.

```bash
docker system prune
```

* Cleans **containers, images, volumes, networks** (careful!).

---

### Shell inside a container

```bash
docker run -d busybox sleep 3600
docker exec -it <Container ID> /bin/sh
```

* `exec` → run a command inside an existing container.
* `-it` → interactive + terminal.
* `/bin/sh` → shell inside container.
* Once inside → we can run Linux commands (`ls`, `cd`, etc).

Exit with:

```bash
exit
```

---

## 🔹 Docker Volumes (Persist Data)

```bash
docker volume create testvolume
```

* Creates a **named volume**.
* Volumes = special Docker-managed storage (data persists even if container is deleted).

```bash
docker run -d -v testvolume:/data busybox sleep 3600
```

* `-v testvolume:/data` → mount volume at `/data` inside container.

Even if we delete the container:

```bash
docker rm -f <Container ID>
```

Then run a new container with same volume:

```bash
docker run -d -v testvolume:/data busybox sleep 3600
```

* The data inside `/data` will **still be available**.

---

## 🔹 Ports (Expose Services)

```bash
docker run -d -p 8000:80 nginx:1.27.4
```

* `-p host:container` → maps **host port 8000** → **container port 80**.
* So → open browser `http://localhost:8000` to access Nginx.

---

## 🔹 Container Naming

```bash
docker run --name pj_container -d busybox
```

* `--name` → gives human-readable name instead of random ID.

---

## 🔹 Remove Images

```bash
docker rmi nginx:1.27.4
```

* `rmi` = remove image.
* Container must be deleted before removing its image.

---

## 🔹 Writing Dockerfiles

### Simple Python App

```dockerfile
FROM python:3.12.9-slim-bookworm
WORKDIR /app
COPY . /app
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
```

* `FROM` → base image.
* `WORKDIR` → working directory inside container.
* `COPY` → copies files from host → container.
* `RUN` → execute commands during build (install dependencies).
* `CMD` → default command when container starts.

---

### Optimized Python Dockerfile

```dockerfile
FROM python:3.12.9-slim-bookworm
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["python", "app.py"]
```

* Install dependencies **before copying rest of files** → better caching.
* `--no-cache-dir` → avoids pip cache → reduces image size.
* `EXPOSE` → documents container port (not mandatory, just for clarity).

---

### Build & Run

```bash
docker build -t python:1.0 .
docker run -d -p 8000:8000 python:1.0
```

---

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