import json
import mysql.connector
import pytz
from datetime import datetime, timedelta
import feedparser
import boto3
import os
import joblib
from fuzzywuzzy import fuzz

# RSS URLs
rss_urls = {
    "cna_singapore": "https://www.channelnewsasia.com/api/v1/rss-outbound-feed?_format=xml&category=10416",
    "cna_asia": "https://www.channelnewsasia.com/api/v1/rss-outbound-feed?_format=xml&category=6511",
    "cna_world": "https://www.channelnewsasia.com/api/v1/rss-outbound-feed?_format=xml&category=6311",
    "bbc": "https://feeds.bbci.co.uk/news/rss.xml?edition=int",
}

# S3 Configuration
model_s3_path = "newsmodel/trained_model.joblib"
local_model_path = "/tmp/trained_model.joblib"

# Helper Functions
def fetch_rss(url):
    """Fetch and parse RSS feed from a given URL."""
    return feedparser.parse(url)

def get_news_items(rss_data, limit=None):
    """Extract news items from the parsed RSS data."""
    return rss_data.entries[:limit]

def download_model_from_s3():
    """Download the trained model from S3."""
    s3 = boto3.client("s3")
    bucket, key = model_s3_path.split("/", 1)
    s3.download_file(bucket, key, local_model_path)
    return joblib.load(local_model_path)

def is_similar(new_title, existing_entries, threshold=55):
    """
    Check if the new title is similar to any existing title in the table,
    regardless of the source.
    """
    for existing_title, existing_source in existing_entries:
        if fuzz.token_sort_ratio(new_title, existing_title) > threshold:
            return True
    return False


def get_table_name(publish_date):
    """Generate the weekly table name based on the publish date."""
    start_of_week = publish_date - timedelta(days=publish_date.weekday())
    end_of_week = start_of_week + timedelta(days=6)
    return f"{start_of_week.strftime('%d%m%y')}-{end_of_week.strftime('%d%m%y')}"

def get_current_week_table_name():
    """Generate the weekly table name based on today's date."""
    today = datetime.now(tz=pytz.timezone("Asia/Singapore"))
    start_of_week = today - timedelta(days=today.weekday())
    end_of_week = start_of_week + timedelta(days=6)
    return f"{start_of_week.strftime('%d%m%y')}-{end_of_week.strftime('%d%m%y')}"


def lambda_handler(event, context):
    # Timezone configuration
    tz_singapore = pytz.timezone("Asia/Singapore")
    tz_gmt = pytz.timezone("GMT")

    # MySQL Configuration
    config = {
        'user': '',
        'password': '',
        'host': '',
        'database': '',
        'raise_on_warnings': True
    }

    try:
        # Connect to the database
        cnx = mysql.connector.connect(**config)
        print("Database connection established.")
        cursor = cnx.cursor()

        # Load the model
        if not os.path.exists(local_model_path):
            print("Downloading model from S3...")
            model = download_model_from_s3()
        else:
            print("Loading local model...")
            model = joblib.load(local_model_path)
            
        current_week_table = get_current_week_table_name()
        if not table_exists(cursor, current_week_table):
            create_table(cursor, current_week_table)
            print(f"Current week table {current_week_table} created.")
        # Delete old tables
        delete_old_tables(cursor)

        # Fetch and process RSS feeds
        high_impact_titles = []  # To store titles of high-impact news

        for source_name, rss_url in rss_urls.items():
            rss_data = fetch_rss(rss_url)
            news_items = get_news_items(rss_data)

            for item in news_items:
                try:
                    
                    # Skip video RSS feeds
                    if "/videos/" in item.link:
                        # print(f"Skipping video feed: {item.title} - {item.link}")
                        continue
                    # Parse publish date
                    if hasattr(item, "published"):
                        publish_date_str = item.published.replace("GMT", "+0000")
                        publish_date = datetime.strptime(publish_date_str, "%a, %d %b %Y %H:%M:%S %z")
                    else:
                        print(f"Skipping item without published date: {item}")
                        continue

                    # Adjust timezone if necessary
                    if source_name == "bbc":
                        publish_date = publish_date.astimezone(tz_singapore)

                    # Determine the table name
                    table_name = get_table_name(publish_date.date())

                    # Ensure the table exists
                    if not table_exists(cursor, table_name):
                        create_table(cursor, table_name)

                    # Fetch existing entries
                    existing_entries = get_existing_titles_and_sources(cursor, table_name)

                    # Extract and process news data
                    title = item.title
                    description = getattr(item, "summary", "")
                    impact_level = int(model.predict([title])[0])

                    # Only process and insert impact levels 2 and 3
                    if impact_level < 2:
                        continue

                    # Check for duplicates across all sources
                    if is_similar(title, existing_entries):
                        continue

                    # Collect high-impact titles for logging
                    if impact_level == 3:
                        high_impact_titles.append(title)

                    # Insert the news into the table
                    news_item = (title, impact_level, item.link, source_name, publish_date)
                    insert_news(cursor, table_name, news_item)

                except Exception as e:
                    print(f"Error processing item: {item}, error: {e}")
                    continue

        # Log high-impact titles
        if high_impact_titles:
            print("High Impact News Titles:")
            for title in high_impact_titles:
                print(f"- {title}")
        else:
            print("No high-impact news found.")

        # Commit changes
        cnx.commit()
        print("Database changes committed.")
    except mysql.connector.Error as err:
        print(f"Database operation failed: {err}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Issue: {err}")
        }
    finally:
        if 'cursor' in locals():
            cursor.close()
            print("Cursor closed.")
        if 'cnx' in locals():
            cnx.close()
            print("Database connection closed.")

    return {
        'statusCode': 200,
        'body': json.dumps('RSS feeds processed successfully.')
    }

def table_exists(cursor, table_name):
    """Check if a table exists in the database."""
    query = f"SHOW TABLES LIKE '{table_name}';"
    cursor.execute(query)
    return cursor.fetchone() is not None

def create_table(cursor, table_name):
    """Create a table if it does not exist."""
    create_table_sql = f"""
    CREATE TABLE `{table_name}` (
        news_id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(255),
        impact_level TINYINT,
        url VARCHAR(255),
        source VARCHAR(50),
        datetime DATETIME
    )
    """
    try:
        cursor.execute(create_table_sql)
        print(f"Table created: {table_name}")
    except mysql.connector.Error as err:
        print(f"Failed creating table: {err}")
        raise
    
def delete_old_tables(cursor):
    """Delete tables whose ending date is more than three months ago."""
    three_months_ago = datetime.now() - timedelta(days=90)
    query = "SHOW TABLES;"
    cursor.execute(query)
    all_tables = cursor.fetchall()

    for (table_name,) in all_tables:
        if '-' in table_name:
            end_date_str = table_name.split('-')[1]
            try:
                end_date = datetime.strptime(end_date_str, '%d%m%y')
                if end_date < three_months_ago:
                    cursor.execute(f"DROP TABLE `{table_name}`")
                    print(f"Dropped old table: {table_name}")
            except ValueError:
                continue

def get_existing_titles_and_sources(cursor, table_name):
    """Fetch all existing titles and sources from the table."""
    query = f"SELECT title, source FROM `{table_name}`;"
    cursor.execute(query)
    return cursor.fetchall()


def insert_news(cursor, table_name, news_item):
    """Insert a news item into the table."""
    insert_query = f"""
    INSERT INTO `{table_name}` (title, impact_level, url, source, datetime)
    VALUES (%s, %s, %s, %s, %s)
    """
    cursor.execute(insert_query, news_item)
if __name__ == "__main__":
    lambda_handler(None, None)
