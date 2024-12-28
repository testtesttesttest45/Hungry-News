from rss_fetcher import fetch_rss, get_news_items
from model import load_data, train_model, load_model
import os
import pandas as pd
import csv
import html
from fuzzywuzzy import fuzz
from bs4 import BeautifulSoup
import requests

rss_urls = {
    "cna_singapore": "https://www.channelnewsasia.com/api/v1/rss-outbound-feed?_format=xml&category=10416",
    "cna_asia": "https://www.channelnewsasia.com/api/v1/rss-outbound-feed?_format=xml&category=6511",
    "cna_world": "https://www.channelnewsasia.com/api/v1/rss-outbound-feed?_format=xml&category=6311",
    "bbc": "https://feeds.bbci.co.uk/news/rss.xml?edition=int",
}

def sanitize_text(text):
    """Decode HTML entities to text."""
    return html.unescape(text).strip() #strip will remove the leading and trailing spaces

def is_similar(new_item, existing_items, threshold=55):
    """similarity check between new item and existing items with 65% threshold"""
    for existing_item in existing_items:
        if fuzz.token_sort_ratio(new_item, existing_item) > threshold:
            return True
    return False

def append_to_csv(headlines, filepath):
    """Append new headlines to a CSV file if they don't already exist with encoding utf-8-sig"""
    new_data = pd.DataFrame(headlines)
    new_data['impact'] = new_data['impact'].astype(int)

    if os.path.exists(filepath):
        old_data = pd.read_csv(filepath, encoding='utf-8-sig')
        all_titles = old_data['title'].tolist()
        all_descriptions = old_data['description'].tolist()

        # search out similar headlines
        filtered_new_data = []
        for index, row in new_data.iterrows():
            if not is_similar(row['title'], all_titles) and not is_similar(row['description'], all_descriptions):
                filtered_new_data.append(row)

        combined_data = pd.concat([old_data, pd.DataFrame(filtered_new_data)]).drop_duplicates(
            subset='title', keep='first', ignore_index=True)
    else:
        combined_data = new_data.drop_duplicates(subset='title', keep='first', ignore_index=True)

    combined_data.to_csv(filepath, index=False, encoding='utf-8-sig', quoting=csv.QUOTE_NONNUMERIC)
    print(f"Appended new headlines to {filepath}.")
    
def extract_meta_description(html_content):
    soup = BeautifulSoup(html_content, "html.parser")
    meta_desc = soup.find("meta", attrs={"name": "description"})
    if meta_desc and "content" in meta_desc.attrs:
        return sanitize_text(meta_desc["content"])
    return None

def main():
    model_path = 'trained_model.joblib'
    if os.path.exists(model_path):
        model = load_model(model_path)
        print("Loaded pre-trained model.")
    else:
        data = load_data("dataset/dataset.csv")
        model = train_model(data, model_path)
        print("Trained and saved a new model.")

    all_headlines = []
    logged_titles = set() 
    for name, url in rss_urls.items():
        rss_data = fetch_rss(url)
        news_items = get_news_items(rss_data)
        for item in news_items:
            if 'summary' in item or 'link' in item:
                title = sanitize_text(item.title)
                description = sanitize_text(item.summary) if 'summary' in item else ""

                # fetc meta description if available
                meta_description = None
                if 'link' in item:
                    try:
                        response = requests.get(item.link)
                        if response.status_code == 200:
                            meta_description = extract_meta_description(response.text)
                    except Exception as e:
                        print(f"Failed to fetch meta description for {item.link}: {e}")

                # Prefer meta description
                description = meta_description if meta_description else description
                impact = int(model.predict([title])[0])

                if impact == 3 and title not in logged_titles:
                    print(f"High impact news from {name}: {title}")
                    logged_titles.add(title)

                all_headlines.append({
                    'title': title,
                    'description': description,
                    'impact': impact,
                    'source': name
                })


    append_to_csv(all_headlines, 'dataset_copy.csv')

if __name__ == "__main__":
    main()