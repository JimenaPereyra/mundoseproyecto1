import os
from flask import Flask, render_template, request, jsonify
from  flask_wtf.csrf import  CSRFProtect
import requests

app = Flask(__name__)

app.config['SECRET_KEY']=os.environ['SECRET_KEY']

csrf = CSRFprotect(app)

API_KEY = os.getenv("WEATHER_API_KEY")


@app.route("/")
def home():
    return render_template("index.html")


@app.route("/clima", methods=["GET"])
def clima():
    ciudad = request.args.get("ciudad")
    if not ciudad:
        return jsonify({"error": "Debe ingresar una ciudad"}), 400

    url = f"https://api.openweathermap.org/data/2.5/weather?q={ciudad}&appid={API_KEY}&units=metric&lang=es"
    resp = requests.get(url)
    datos = resp.json()

    if resp.status_code != 200:
        return jsonify({"error": "Ciudad no encontrada"}), 404

    resultado = {
        "ciudad": datos["name"],
        "temp": datos["main"]["temp"],
        "descripcion": datos["weather"][0]["description"],
    }
    return jsonify(resultado)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

