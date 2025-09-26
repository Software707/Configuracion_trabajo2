FROM python:3.12
ENV PYTHONUNBUFFERED=1

# Instalar Node.js, compiladores y dependencias
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update -qq \
    && apt-get install -y nodejs build-essential python3-dev dos2unix

# Crear usuario django
RUN groupadd -r django && useradd -r -g django django

# Copiar dependencias y código
COPY ./requirements.txt /requirements.txt
RUN pip3 install --no-cache-dir -r /requirements.txt
COPY . /app

# Convertir archivos Windows a Unix
RUN find /app -type f -exec dos2unix {} \;
RUN find /app -name "*.py" -exec dos2unix {} \;
RUN find /app -name "*.sh" -exec dos2unix {} \;

# Cambiar a usuario django para todo lo siguiente
USER django
WORKDIR /app

# Verificar que manage.py existe y dar permisos
RUN ls -l src/sandbox/
RUN [ -f src/sandbox/manage.py ] && chmod +x src/sandbox/manage.py || echo "manage.py no encontrado"
RUN chmod +x scripts/*.sh || true

# Instalar dependencias y construir sandbox como usuario django
RUN make install
RUN make build_sandbox || cat /app/src/sandbox/logs/error.log

# Copiar archivos necesarios y asegurar permisos
RUN cp --remove-destination /app/src/oscar/static/oscar/img/image_not_found.jpg /app/src/sandbox/public/media/ || true

WORKDIR /app/src/sandbox/

# Comando por defecto
CMD ["uwsgi", "--ini", "uwsgi.ini"]

