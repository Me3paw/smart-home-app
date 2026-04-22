from flask import Flask, request
import subprocess
import logging
import os

import json

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

# --- CONFIGURATION ---
DATA_FOLDER = "iot_data"
PRICE_FILE = "prices.json"
if not os.path.exists(DATA_FOLDER):
    os.makedirs(DATA_FOLDER)

def load_prices():
    """Loads prices from JSON file."""
    try:
        with open(PRICE_FILE, 'r') as f:
            return json.load(f)
    except:
        return {
            "avg": 2424.48,
            "tiers": [1984, 2380, 2998, 3571, 3967],
            "limits": [100, 200, 400, 700],
            "vat": 1.10
        }

def calculate_tier_cost(kwh):
    """Calculates cost based on tiered pricing + VAT from config."""
    p = load_prices()
    total = 0
    remaining = kwh
    prev_limit = 0
    for i in range(len(p["limits"])):
        limit = p["limits"][i]
        price = p["tiers"][i]
        tier_usage = min(remaining, limit - prev_limit)
        if tier_usage <= 0: break
        total += tier_usage * price
        remaining -= tier_usage
        prev_limit = limit
    
    if remaining > 0:
        total += remaining * p["tiers"][-1]
    return total * p["vat"]

@app.route('/price', methods=['GET'])
def get_price():
    """Returns the latest pricing and average in JSON."""
    p = load_prices()
    app.logger.info("ESP32 requested electricity price.")
    return {
        "avg": p["avg"],
        "tiers": p["tiers"],
        "limits": p["limits"]
    }, 200

@app.route('/calculate_cost', methods=['GET'])
def get_cost():
    """Calculates cost for a given kWh value."""
    try:
        kwh = float(request.args.get('kwh', 0))
        return {"kwh": kwh, "cost": calculate_tier_cost(kwh)}, 200
    except:
        return {"error": "Invalid kWh"}, 400

@app.route('/upload_csv', methods=['POST'])
def upload_file():
    """Receives monthly energy data from ESP32 and saves it with a timestamped filename."""
    app.logger.info("Received data upload from ESP32.")
    try:
        import datetime
        now = datetime.datetime.now()
        # Lưu file theo tháng trước đó (vì ESP32 thường push vào ngày 1 của tháng mới)
        # Hoặc đơn giản là dùng timestamp hiện tại
        date_str = now.strftime("%Y_%m_%d_%H%M%S")
        data = request.data.decode('utf-8')
        filename = os.path.join(DATA_FOLDER, f"monthly_report_{date_str}.csv")
        
        with open(filename, "w") as f:
            f.write(data)
            
        app.logger.info(f"Data successfully saved to {filename}")
        return "Upload Successful", 200
    except Exception as e:
        app.logger.error(f"Failed to save upload: {str(e)}")
        return "Internal Server Error", 500

@app.route('/shutdown', methods=['GET'])
def shutdown():
    """Triggers PC Shutdown."""
    app.logger.info("!!! SHUTDOWN REQUEST RECEIVED FROM ESP32 !!!")
    try:
        # Executes sudo poweroff (requires NOPASSWD in sudoers for the user running this)
        subprocess.run(['sudo', 'poweroff'], check=True)
        return "PC is shutting down...", 200
    except Exception as e:
        app.logger.error(f"Shutdown failed: {str(e)}")
        return f"Error: {str(e)}", 500

if __name__ == '__main__':
    print("------------------------------------------")
    print("Smart Home Server Running on Port 5000")
    print("Endpoints: /price, /upload_csv, /shutdown")
    print("------------------------------------------")
    app.run(host='0.0.0.0', port=5000)
