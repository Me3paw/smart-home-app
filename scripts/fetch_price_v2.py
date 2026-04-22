#!/usr/bin/env python3
import requests
import re
import json
import os
import sys
import time
from bs4 import BeautifulSoup
from PIL import Image
from io import BytesIO
import easyocr
import numpy as np

# CONFIGURATION
PRICE_JSON_PATH = "/home/SYS_USER_PLACEHOLDER/Study/IoT/final/scripts/prices.json"
LIST_URL = "https://www.evn.com.vn/vi-VN/news-l/Gia-dien-60-28"
BASE_URL = "https://www.evn.com.vn"
FIREBASE_DB_URL = "FIREBASE_DB_URL_PLACEHOLDER"

def clean_price(text):
    # Remove dots/spaces and keep digits
    clean = re.sub(r'[^\d]', '', text)
    if len(clean) >= 4:
        # Most EVN prices are in 1.XXX, 2.XXX, 3.XXX format
        # We take the first 4 digits
        return float(clean[:4])
    return 0.0

def find_latest_news_url():
    try:
        headers = {'User-Agent': 'Mozilla/5.0'}
        response = requests.get(LIST_URL, headers=headers, timeout=15)
        soup = BeautifulSoup(response.content, 'html.parser')
        # Find first "Biểu giá bán lẻ điện" link
        for a in soup.find_all('a', class_='xanhEVN'):
            text = a.get_text()
            if "Biểu giá bán lẻ điện" in text:
                url = a['href']
                return BASE_URL + url if not url.startswith('http') else url
    except Exception as e:
        print(f"Error finding news URL: {e}")
    return None

def scrape_v2():
    news_url = find_latest_news_url()
    if not news_url:
        print("Could not find latest news URL.")
        return False

    print(f"Targeting: {news_url}")
    try:
        headers = {'User-Agent': 'Mozilla/5.0'}
        response = requests.get(news_url, headers=headers, timeout=15)
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Step 1: Find the section "GIÁ BÁN LẺ ĐIỆN CHO SINH HOẠT"
        img_url = None
        # Look for the span/strong containing the target text
        for span in soup.find_all(['span', 'strong']):
            if "GIÁ BÁN LẺ ĐIỆN CHO SINH HOẠT" in span.get_text():
                # The image is typically the next sibling or in the next paragraph
                parent = span.find_parent('p')
                if parent:
                    next_p = parent.find_next_sibling('p')
                    if next_p:
                        img = next_p.find('img')
                        if img:
                            img_url = img.get('src')
                            break
        
        if not img_url:
            print("Could not find image for 'GIÁ BÁN LẺ ĐIỆN CHO SINH HOẠT'. Fallback to keyword search.")
            # Fallback: find any img with "sinhhoat" in src
            for img in soup.find_all('img'):
                src = img.get('src', '').lower()
                if "sinhhoat" in src:
                    img_url = img.get('src')
                    break

        if not img_url:
            print("Failed to find infographic image.")
            return False

        if not img_url.startswith('http'):
            img_url = BASE_URL + img_url

        print(f"Downloading image: {img_url}")
        img_resp = requests.get(img_url, headers=headers, timeout=15)
        img_data = np.array(Image.open(BytesIO(img_resp.content)))

        print("Running OCR...")
        reader = easyocr.Reader(['vi', 'en'], gpu=False) # GPU=False for reliability in CPU environments
        results = reader.readtext(img_data, detail=0)
        full_text = " ".join(results)
        print(f"OCR Full Text: {full_text}")

        # Step 2: Extract prices and tier ranges
        # EVN 2025: Bậc 1 (0-50): 1.984, Bậc 2 (51-100): 2.050, Bậc 3 (101-200): 2.380, etc.
        # We need tiers: [1984, 2050, 2380, 2998, 3350]
        # and limits: [50, 100, 200, 300, 400]
        
        prices = []
        limits = []
        
        # Find all 1.xxx, 2.xxx, 3.xxx patterns for prices
        price_matches = re.findall(r'[123]\.\d{3}', full_text)
        seen_prices = set()
        for m in price_matches:
            val = clean_price(m)
            if 1500 < val < 4000 and val not in seen_prices:
                prices.append(val)
                seen_prices.add(val)
        prices.sort()

        # Find tier ranges (limits)
        # Look for "từ X - Y" or "đến Y" or just the numbers after "Bậc"
        # Example: "0 - 50", "51 100", "101 200"
        limit_matches = re.findall(r'(\d{1,3})\s*[-–]\s*(\d{2,3})|(?<=Bậc\s\d:)\s*(\d{2,3})', full_text)
        for m in limit_matches:
            # m is a tuple: (start, end, single_val)
            val = m[1] if m[1] else m[2]
            if val:
                l_val = float(val)
                if l_val not in limits and 40 <= l_val <= 400:
                    limits.append(l_val)
        limits.sort()

        # We need at least 5 tiers and 4-5 limits for our system
        if len(prices) >= 5:
            final_prices = prices[:5]
            # Standard EVN limits if OCR fails partially: [50, 100, 200, 300, 400]
            final_limits = limits[:4] if len(limits) >= 4 else [50.0, 100.0, 200.0, 300.0]
            
            with open(PRICE_JSON_PATH, 'r') as f:
                data = json.load(f)
            
            data["tiers"] = final_prices
            data["limits"] = final_limits
            
            with open(PRICE_JSON_PATH, 'w') as f:
                json.dump(data, f, indent=4)
            
            print(f"Successfully updated prices: {final_prices}")
            print(f"Successfully updated limits: {final_limits}")
            
            # Poke ESP32 via Firebase Command Node
            cmd = {"type": "sync_prices"}
            try:
                requests.patch(f"{FIREBASE_DB_URL}/device/cmd.json", json=cmd, timeout=10)
                print("Poked ESP32 via Firebase.")
            except:
                print("Failed to poke ESP32 (network issue), but JSON updated.")
            
            return True
        else:
            print(f"Found only {len(prices)} prices. Need at least 5.")
            return False

    except Exception as e:
        print(f"Error in scrape_v2: {e}")
        return False

if __name__ == "__main__":
    if scrape_v2():
        sys.exit(0)
    else:
        print("Failed to update prices.")
        sys.exit(1)
