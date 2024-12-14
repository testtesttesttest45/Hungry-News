from flask import Flask, jsonify, request
import pymysql
import pymysql.cursors
import os
from flask_cors import CORS
from dotenv import load_dotenv
from datetime import datetime, timedelta
import requests  # To fetch external content
from pytz import timezone
import re


app = Flask(__name__)
load_dotenv()
CORS(app)

def get_week_table_name(today=None):
    """
    get table name for current week (monday to sunday)
    If today variable is not provided, use the current date.
    """
    
    singapore_tz  = timezone("Asia/Singapore")
    
    today = today or datetime.now(tz=singapore_tz)
    print(f"Debugging: Using date {today.strftime('%d %B %Y')}, time now is {today.strftime('%H:%M:%S')}")
    
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
            cursor.execute(f"SELECT news_id, title, url, datetime, source, impact_level FROM `{table_name}` WHERE impact_level = 3")
            results = cursor.fetchall()
    except pymysql.MySQLError as e:
        return jsonify({"error": f"Database error: {str(e)}"}), 500
    finally:
        conn.close()

    return jsonify(results)

@app.route('/past-news')
def get_past_news():
    config = {
        'user': os.getenv('DB_USER'),
        'password': os.getenv('DB_PASSWORD'),
        'host': os.getenv('DB_HOST'),
        'database': os.getenv('DB_NAME'),
        'cursorclass': pymysql.cursors.DictCursor
    }
    
    table_name = request.args.get('table_name')
    if not table_name:
        return jsonify({"error": "Missing table name"}), 400
    
    conn = pymysql.connect(**config)
    try:
        with conn.cursor() as cursor:
            # check if the table exists
            cursor.execute(f"SHOW TABLES LIKE '{table_name}';")
            if not cursor.fetchone():
                return jsonify({"error": "Table does not exist"}), 404
            
            # see current week's table
            cursor.execute(f"SELECT news_id, title, url, datetime, source, impact_level FROM `{table_name}` where impact_level = 3")
            results = cursor.fetchall()
    except pymysql.MySQLError as e:
        return jsonify({"error": f"Database error: {str(e)}"}), 500
    finally:
        conn.close()

    return jsonify(results)

@app.route('/curated-news')
def get_curated_news():
    config = {
        'user': os.getenv('DB_USER'),
        'password': os.getenv('DB_PASSWORD'),
        'host': os.getenv('DB_HOST'),
        'database': os.getenv('DB_NAME'),
        'cursorclass': pymysql.cursors.DictCursor
    }
    
    table_name = request.args.get('table_name')
    if not table_name:
        return jsonify({"error": "Missing table name"}), 400
    
    conn = pymysql.connect(**config)
    try:
        with conn.cursor() as cursor:
            cursor.execute(f"SHOW TABLES LIKE '{table_name}';")
            if not cursor.fetchone():
                return jsonify({"error": "Table does not exist"}), 404
            
            # curated news (Singapore and impact 2)
            query = f"""
            SELECT news_id, title, url, datetime, source, impact_level
            FROM `{table_name}`
            WHERE source = 'cna_singapore' OR impact_level = 2
            """
            cursor.execute(query)
            results = cursor.fetchall()
    except pymysql.MySQLError as e:
        return jsonify({"error": f"Database error: {str(e)}"}), 500
    finally:
        conn.close()

    return jsonify(results)

@app.route('/search-news', methods=['GET'])
def search_news():
    config = {
        'user': os.getenv('DB_USER'),
        'password': os.getenv('DB_PASSWORD'),
        'host': os.getenv('DB_HOST'),
        'database': os.getenv('DB_NAME'),
        'cursorclass': pymysql.cursors.DictCursor
    }

    query = request.args.get('query')
    if not query:
        return jsonify({"error": "Missing search query"}), 400

    conn = pymysql.connect(**config)
    try:
        with conn.cursor() as cursor:
            # fetch all table names
            cursor.execute("SHOW TABLES;")
            tables = cursor.fetchall()

            results = []
            for table in tables:
                table_name = list(table.values())[0]
                # ensure only tables with this format
                if re.match(r'\d{6}-\d{6}', table_name):
                    cursor.execute(
                        f"SELECT news_id, title, url, datetime, source, impact_level FROM `{table_name}` "
                        f"WHERE title LIKE %s", (f"%{query}%",)
                    )
                    results.extend([{
                        **row,
                        "table_name": table_name
                    } for row in cursor.fetchall()])

            # sort by datetime in descending order
            results.sort(key=lambda x: x['datetime'], reverse=True)

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


if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))  # default to 5000
    app.run(host='0.0.0.0', port=port)
