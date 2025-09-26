FROM python:3.12
ENV PYTHONUNBUFFERED=1

# Instalar Node.js y dependencias
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update -qq \
    && apt-get install -y nodejs build-essential python3-dev dos2unix

# Crear usuario django
RUN groupadd -r django && useradd -r -g django django

# Copiar dependencias y código
COPY requirements.txt /requirements.txt
RUN pip3 install --no-cache-dir -r /requirements.txt
COPY . /app

# Convertir archivos Windows a Unix
RUN find /app -type f -exec dos2unix {} \;
RUN find /app -name "*.py" -exec dos2unix {} \;
RUN find /app -name "*.sh" -exec dos2unix {} \;

WORKDIR /app

# Ejecutar Makefile y permisos como root
RUN make install
RUN chmod +x src/sandbox/manage.py
RUN make build_sandbox
RUN cp --remove-destination /app/src/oscar/static/oscar/img/image_not_found.jpg /app/src/sandbox/public/media/
RUN chown -R django:django /app
RUN chmod +x scripts/*.sh || true

# Cambiar a usuario django para ejecutar la app
USER django
WORKDIR /app/src/sandbox/

# Comando por defecto
CMD ["uwsgi", "--ini", "uwsgi.ini"]



