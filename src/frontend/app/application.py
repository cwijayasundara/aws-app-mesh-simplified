from flask import Flask, render_template
import requests
import os 

from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

patch_all()

app = Flask(__name__)
xray_recorder.configure(service='FrontEnd')
XRayMiddleware(app, xray_recorder)

@app.route("/")
def hello_world():
    return render_template("main.html")

@app.route("/api_request")
def api_request():
    API_ENDPOINT = os.getenv("API_ENDPOINT", "http://localhost:5001")
    try:
        r = requests.get(API_ENDPOINT, verify=False, timeout=10)
        return render_template("main.html", body=f"API says: <b>{r.text} </b>") 
    except:
        return render_template("main.html", body="API says: <b>hit an error </b>") 
        
        
@app.route("/api_external_request")
def api_external_request():
    try:
        r = requests.get("https://deckofcardsapi.com/api/deck/new/shuffle/?deck_count=1", verify=False, timeout=10)
        return f"<p>External API says: {r.text} </p>"
    except:
        return f"<p>External API says: hit an error </p>"


@app.route("/ping")
def ping():
    return "<p>I'm here!</p>"