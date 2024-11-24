from rss_fetcher import fetch_rss, get_news_items  # Ensure these are defined or import them if they're external
from model import load_data, train_model, predict, load_model
import os
import pandas as pd
import csv
import html
from fuzzywuzzy import fuzz

rss_urls = {
    "cna_latest": "https://www.channelnewsasia.com/api/v1/rss-outbound-feed?_format=xml",
    "cna_singapore": "https://www.channelnewsasia.com/api/v1/rss-outbound-feed?_format=xml&category=10416",
    "cna_asia": "https://www.channelnewsasia.com/api/v1/rss-outbound-feed?_format=xml&category=6511",
    "cna_world": "https://www.channelnewsasia.com/api/v1/rss-outbound-feed?_format=xml&category=6311",
    "bbc": "https://feeds.bbci.co.uk/news/rss.xml?edition=int",
}

def sanitize_text(text):
    """Decode HTML entities to text."""
    return html.unescape(text)

def is_similar(new_item, existing_items, threshold=80):
    """Check if the new item is similar to any of the existing items based on a similarity threshold."""
    for existing_item in existing_items:
        if fuzz.token_sort_ratio(new_item, existing_item) > threshold:
            return True
    return False

def append_to_csv(headlines, filepath):
    """Append new headlines to a CSV file if they don't already exist, ensuring correct encoding and formatting."""
    new_data = pd.DataFrame(headlines)
    new_data['impact'] = new_data['impact'].astype(int)
    
    if os.path.exists(filepath):
        old_data = pd.read_csv(filepath, encoding='utf-8-sig')
        all_titles = old_data['title'].tolist()  # similar to the existing titles
        all_descriptions = old_data['description'].tolist()

        # filter out similar headlines
        filtered_new_data = []
        for index, row in new_data.iterrows():
            if not is_similar(row['title'], all_titles) and not is_similar(row['description'], all_descriptions):
                filtered_new_data.append(row)

        combined_data = pd.concat([old_data, pd.DataFrame(filtered_new_data)]).drop_duplicates(subset='title', keep='first', ignore_index=True)
    else:
        combined_data = new_data.drop_duplicates(subset='title', keep='first', ignore_index=True)

    combined_data.to_csv(filepath, index=False, encoding='utf-8-sig', quoting=csv.QUOTE_NONNUMERIC)
    print(f"Appended new headlines to {filepath}.")
    
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

    for name, url in rss_urls.items():
        rss_data = fetch_rss(url)
        news_items = get_news_items(rss_data)
        for item in news_items:
            if 'summary' in item:
                item.title = sanitize_text(item.title)
                item.summary = sanitize_text(item.summary)
                impact = int(predict(model, item.summary))
                all_headlines.append({
                    'title': item.title,
                    'description': item.summary,
                    'impact': impact,
                    'source': name
                })
                if impact == 3:
                    print(f"High impact news from {name}: {item.title}")

    append_to_csv(all_headlines, 'dataset_copy.csv')

if __name__ == "__main__":
    main()
