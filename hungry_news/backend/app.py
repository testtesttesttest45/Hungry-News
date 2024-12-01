from flask import Flask, jsonify, request
import pymysql
import pymysql.cursors
import os
from flask_cors import CORS
from dotenv import load_dotenv
from datetime import datetime, timedelta
import requests  # To fetch external content

app = Flask(__name__)
load_dotenv()
CORS(app)

def get_week_table_name(today=None):
    """
    get table name for current week (monday to sunday)
    If today variable is not provided, use the current date.
    """
    today = today or datetime.now()
    print(f"Debugging: Using date {today.strftime('%d %B %Y')}")
    
    # Find the start and end of the week
    start_of_week = today - timedelta(days=today.weekday())  # Monday
    end_of_week = start_of_week + timedelta(days=6)          # Sunday
    return f"{start_of_week.strftime('%d%m%y')}-{end_of_week.strftime('%d%m%y')}"


@app.route('/major-news')
def get_news():
    config = {
        'user': os.getenv('DB_USER'),
        'password': os.getenv('DB_PASSWORD'),
        'host': os.getenv('DB_HOST'),
        'database': os.getenv('DB_NAME'),
        'cursorclass': pymysql.cursors.DictCursor
    }
    
    table_name = get_week_table_name()
    print(f"Checking table: {table_name}")
    
    conn = pymysql.connect(**config)
    try:
        with conn.cursor() as cursor:
            # check if the table exists
            cursor.execute(f"SHOW TABLES LIKE '{table_name}';")
            if not cursor.fetchone():
                return jsonify({"error": "Please wait while I generate this week's database"}), 503
            
            # see current week's table
            cursor.execute(f"SELECT news_id, title, url, datetime, is_read, is_saved, source FROM `{table_name}` WHERE impact_level = 3")
            results = cursor.fetchall()
    except pymysql.MySQLError as e:
        return jsonify({"error": f"Database error: {str(e)}"}), 500
    finally:
        conn.close()

    return jsonify(results)


@app.route('/proxy')
def proxy():
    """
    Fetch content from an external URL and return it to the frontend.
    """
    url = request.args.get('url')
    if not url:
        return jsonify({"error": "Missing URL parameter"}), 400

    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        return jsonify({"error": f"Error fetching URL: {str(e)}"}), 500

    # return as plain text
    return response.text, 200

@app.route('/update-news-save-status', methods=['POST'])
def update_save_status():
    """
    Update the 'is_saved' status for a specific news item.
    """
    data = request.json
    news_id = data.get('news_id')
    is_saved = data.get('is_saved')  # 0 or 1

    if news_id is None or is_saved not in [0, 1]:
        return jsonify({"error": "Invalid request data"}), 400

    config = {
        'user': os.getenv('DB_USER'),
        'password': os.getenv('DB_PASSWORD'),
        'host': os.getenv('DB_HOST'),
        'database': os.getenv('DB_NAME'),
        'cursorclass': pymysql.cursors.DictCursor
    }

    table_name = get_week_table_name()

    conn = pymysql.connect(**config)
    try:
        with conn.cursor() as cursor:
            cursor.execute(f"SHOW TABLES LIKE '{table_name}';")
            if not cursor.fetchone():
                return jsonify({"error": "Weekly table does not exist"}), 503

            cursor.execute(
                f"UPDATE `{table_name}` SET is_saved = %s WHERE news_id = %s",
                (is_saved, news_id)
            )
            conn.commit()
            if cursor.rowcount > 0:
                return jsonify({"success": True}), 200
            else:
                return jsonify({"error": "News item not found"}), 404
    except pymysql.MySQLError as e:
        return jsonify({"error": f"Database error: {str(e)}"}), 500
    finally:
        conn.close()

@app.route('/update-news-read-status', methods=['POST'])
def update_read_status():
    """
    Update the 'is_saved' status for a specific news item.
    """
    data = request.json
    news_id = data.get('news_id')
    is_read = data.get('is_read')  # 0 or 1

    if news_id is None or is_read not in [0, 1]:
        return jsonify({"error": "Invalid request data"}), 400

    config = {
        'user': os.getenv('DB_USER'),
        'password': os.getenv('DB_PASSWORD'),
        'host': os.getenv('DB_HOST'),
        'database': os.getenv('DB_NAME'),
        'cursorclass': pymysql.cursors.DictCursor
    }

    table_name = get_week_table_name()

    conn = pymysql.connect(**config)
    try:
        with conn.cursor() as cursor:
            cursor.execute(f"SHOW TABLES LIKE '{table_name}';")
            if not cursor.fetchone():
                return jsonify({"error": "Weekly table does not exist"}), 503

            cursor.execute(
                f"UPDATE `{table_name}` SET is_read = %s WHERE news_id = %s",
                (is_read, news_id)
            )
            conn.commit()
            if cursor.rowcount > 0:
                return jsonify({"success": True}), 200
            else:
                return jsonify({"error": "News item not found"}), 404
    except pymysql.MySQLError as e:
        return jsonify({"error": f"Database error: {str(e)}"}), 500
    finally:
        conn.close()


@app.route('/.well-known/assetlinks.json')
def assetlinks():
    return jsonify([
        {
            "relation": ["delegate_permission/common.handle_all_urls"],
            "target": {
                "namespace": "android_app",
                "package_name": "com.example.hungry_news",
                "sha256_cert_fingerprints": [
                    "55:49:E1:D9:DF:E7:17:20:81:F8:6B:E1:05:9D:67:B2:EA:2F:08:B2:05:04:12:02:5F:EC:E8:AF:1D:D6:66:79"
                ]
            }
        }
    ])


if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))  # default to 5000
    app.run(host='0.0.0.0', port=port)
