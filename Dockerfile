FROM python:3.12
ENV PYTHONUNBUFFERED=1

# Instalar Node.js y dependencias necesarias
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

# Cambiar a usuario django y definir WORKDIR
USER django
WORKDIR /app

# Verificar y dar permisos de ejecución
RUN [ -f src/sandbox/manage.py ] && chmod +x src/sandbox/manage.py || echo "manage.py no encontrado"
RUN chmod +x scripts/*.sh || true

# Instalar dependencias y construir sandbox
RUN make install || echo "make install falló"
RUN make build_sandbox || cat /app/src/sandbox/logs/error.log || echo "make build_sandbox falló"

# Copiar archivos necesarios y asegurar permisos
RUN cp --remove-destination /app/src/oscar/static/oscar/img/image_not_found.jpg /app/src/sandbox/public/media/ || echo "Archivo image_not_found.jpg no encontrado"
RUN chown -R django:django /app

# Definir WORKDIR final
WORKDIR /app/src/sandbox/

# Comando por defecto
CMD ["uwsgi", "--ini", "uwsgi.ini"]



