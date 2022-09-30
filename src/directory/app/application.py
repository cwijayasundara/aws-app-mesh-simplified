from flask import Flask
import os

app = Flask(__name__)

@app.route("/api")
def hello_world():
    VERSION = os.getenv("VERSION", "not set")
    return f"I don't do much! VERSION: {VERSION}"


@app.route("/ping")
def ping():
    return "I'm here!"