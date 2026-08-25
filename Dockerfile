FROM python:3.11-alpine

ARG CI_JOB_TOKEN

# allow user NOBODY to access the needed folders
RUN mkdir /opt/app
RUN chown -R nobody /opt/app

RUN mkdir /.local
RUN chown -R nobody /.local

# switch to least privileged user
USER nobody

# Disable debug asserts and optimize layers
ENV PYTHONOPTIMIZE=1 PYTHONDONTWRITEBYTECODE=1 LANG=C.UTF-8 LC_ALL=C.UTF-8 PYTHONPATH="/opt/app/src" JSON_LOG_FORMAT=true PATH="$PATH:/.local/bin"

# Django settings module
ENV DJANGO_SETTINGS_MODULE="config.settings.production"

WORKDIR /opt/app

# Copy the requirements file
COPY Pipfile Pipfile.lock ./

# Install the dependencies
RUN pip install --quiet --no-cache-dir pipenv \
 && pipenv install -q --deploy --ignore-pipfile

# Copy the application code
COPY ./src /opt/app/src/

# Collect static files (dummy secret for build only - real one injected at runtime)
RUN cd src && DJANGO_SECRET_KEY=build-time-placeholder pipenv run python manage.py collectstatic --noinput

# Expose the port (required by ServiceShaper)
EXPOSE 8000

# Run the application with gunicorn
ENTRYPOINT ["pipenv", "run", "opentelemetry-instrument", "gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "2", "--threads", "4", "--access-logfile", "-", "--error-logfile", "-"]
