FROM python:3.9-slim-buster

COPY app /app

WORKDIR /app

RUN pip3 install -r requirements.txt && \
    apt update  && \
    apt install -y procps curl dnsutils

EXPOSE 9080

ENV FLASK_APP=application.py

CMD flask run --host 0.0.0.0 --port 9080