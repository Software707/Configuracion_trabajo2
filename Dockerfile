FROM python:3.12
ENV PYTHONUNBUFFERED=1

RUN curl -sL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get update -qq && apt-get install -y nodejs build-essential python3-dev

COPY ./requirements.txt /requirements.txt
RUN pip3 install -r /requirements.txt

RUN groupadd -r django && useradd -r -g django django
COPY . /app
RUN apt-get update -qq && apt-get install -y dos2unix && find /app -type f -exec dos2unix {} \;
WORKDIR /app
RUN apt-get update -qq && apt-get install -y dos2unix && find /app -name "*.py" -exec dos2unix {} \; && find /app -name "*.sh" -exec dos2unix {} \;

RUN make install
RUN make build_sandbox
RUN cp --remove-destination /app/src/oscar/static/oscar/img/image_not_found.jpg /app/src/sandbox/public/media/
RUN chown -R django:django /app

USER django

WORKDIR /app/src/sandbox/
CMD ["uwsgi", "--ini", "uwsgi.ini"]