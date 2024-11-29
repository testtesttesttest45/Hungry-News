from flask import Flask, jsonify
import pymysql
import pymysql.cursors
import os
from flask_cors import CORS
from dotenv import load_dotenv

app = Flask(__name__)
load_dotenv()
CORS(app)

@app.route('/news')
def get_news():
    config = {
        'user': os.getenv('DB_USER'),
        'password': os.getenv('DB_PASSWORD'),
        'host': os.getenv('DB_HOST'),
        'database': os.getenv('DB_NAME'),
        'cursorclass': pymysql.cursors.DictCursor
    }
    conn = pymysql.connect(**config)
    with conn.cursor() as cursor:
        cursor.execute("SELECT title, url, datetime, is_read FROM `251124-011224` WHERE impact_level = 3")
        results = cursor.fetchall()
    conn.close()
    return jsonify(results) 

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)  # Bind to all network interfaces
