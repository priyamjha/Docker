docker pull hello-world

docker run helloo-world

docker run --rm helloo-world

--

docker run python:3.12-slim

docker run --rm python:3.12-slim python -c "print('Hello World')"
>> Hello World

--

docker image ls

docker images

--

docker run -d busybox sleep 3600

docker run -d busybox

--

docker ps

docker ps -a

--

docker logs <Container ID>

--

docker stop <Container ID>

--

docker start <Container ID>

--

docker rm <Container ID>

--

docker container prune

--

docker system prune

--

docker run -d busybox sleep 3600

docker exec -it <Container ID> /bin/sh
/ # ls
bin    data   dev    etc    home   lib    lib64  proc   root   sys    tmp    usr    var
/ # exit

--

docker volume create testvolume
>> testvolume

docker run -d -v testvolume:/<Custom-Path> busybox sleep 3600

I delete the container and again make a new container

docker run -d -v testvolume:/<Custom-Path> busybox sleep 3600

--

docker run -d -p 8000:80 nginx:1.27.4

--

docker run --name pj_container -d busybox

--

docker rmi nginx:1.27.4

--

# Use an official Python base image
FROM python:3.12.9-slim-bookworm

# Set working directory
WORKDIR /app

# Copy the rest of the app
COPY . /app

# Install dependencies
RUN pip install -r requirements.txt

# Run the app
CMD ["python", "app.py"]

OK BUT NOT OPTIMIZED

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

Terminal:

docker build -t python:1.0 .

docker run -d -p 8000:8000 python:1.0


--

# Django DockerFile - dockerfile

# Use an official Python base image
FROM python:3.12.9-slim-bookworm

# Don’t buffer logs (show instantly)
ENV PYTHONUNBUFFERED=1

# Don’t write .pyc files
ENV PYTHONDONTWRITEBYTECODE=1

# Set working directory
WORKDIR /django_project

# Copy requirements first for caching
COPY requirements.txt .

# Upgrade pip 
RUN pip install --no-cache-dir --upgrade pip

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the app
COPY . .

# Expose the Django port
EXPOSE 8000

# Run the app
CMD python manage.py runserver 0.0.0.0:8000
OR
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]


Terminal:

docker build -t django-docker-image .

docker run -d -p 8888:8000 django-docker-image

--

# PROFESSIONAL Django DockerFile - dockerfile

# Use an official lightweight Python base image
FROM python:3.12.9-slim-bookworm

# Environment settings
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Set working directory inside container
WORKDIR /app

# Copy only requirements first (better caching)
COPY requirements.txt .

# Upgrade pip and install dependencies in one step
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy the entire project
COPY . .

# Expose Django default port
EXPOSE 8000

# Run Django development server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]


Notes

For development → keep the runserver command.

For production → replace CMD with Gunicorn:

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "django_project.wsgi:application"]


Terminal:

docker build -t django-docker-image .

docker run -d --name django-container -p 8888:8000 django-docker-image

AND Integrate Docker Volume For Real Time Updates

Terminal:

docker run -d --name django-container -v .:/django_docker_project -p 8888:8000 django-docker-image

WORKDIR /django_docker_project  <-- that name goes to volume DIR

--

# Docker Compose - docker-compose.yml

name: docker-project

services:
  app:
    image: django-docker-image
    container_name: django-docker-container
    ports:
      - "8000:8000"
    volumes:
      - .:/django_docker_project


Terminal:

# If I have docker image
docker compose up -d


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


Terminal:

# If not, but after that remove --build and remove build:... from docker-compose.yml file
docker compose up -d --build

--

# Containerise Postgres DB - docker-compose.yml

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
    db:
      image: postgres:17
      container_name: postgres-container
      restart: always
      environment:
        POSTGRES_USER: my_user
        POSTGRES_PASSWORD: my_password
        POSTGRES_DB: my_database
      ports:
        - "5432:5432"

# PostgreSQL configuration - settings.py

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'my_database',
        'USER': 'my_user',
        'PASSWORD': 'my_password',
        'HOST': 'db',  # This should match the service name in docker-compose.yml
        'PORT': '5432',
    }
}

Terminal:

docker compose up -d --build

docker exec -it django-docker-container python manage.py migrate

docker exec -it django-docker-container python manage.py createsuperuser 

# Persist Data With Docker Volume

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


Terminal:

docker compose up -d --build

docker exec -it django-docker-container python manage.py migrate

docker exec -it django-docker-container python manage.py createsuperuser 


-----------------------


# PROFESSIONAL Django DockerFile - dockerfile

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

# Collect static files
RUN python manage.py collectstatic --noinput

# Expose Django default port
EXPOSE 8000

# Run Django development server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

--

Notes

For development → keep the runserver command.

For production → replace CMD with Gunicorn:

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "django_project.wsgi:application"]

--

# PostgreSQL configuration - settings.py

https://render.com/

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


Terminal:

python manage.py migrate

--

# Docker Compose - docker-compose.yml

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


Terminal:

# If not, but after that remove --build and remove build:... from docker-compose.yml file
docker compose up -d --build

# If have docker image
docker compose up -d

--

# Handle Static Assets - WhiteNoise

https://whitenoise.readthedocs.io/en/latest/

STATICFILES_DIRS = [BASE_DIR / 'static']

STATIC_ROOT = BASE_DIR / 'staticfiles'

STORAGES = {
    "staticfiles": {
        "BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage",
    },
}

Terminal:


python manage.py collectstatic

--

Terminal:

docker login ghcr.io --username <GitHub UserName> --password <GitHub Personal Access Token>

docker build -t ghcr.io/priyamjha2003/app-image .

docker push ghcr.io/priyamjha2003/app-image

--

# Deploy Docker Image TO render

https://youtu.be/HcgV-8QY-0c?si=fxexydHhdzDQa8G9&t=4340

