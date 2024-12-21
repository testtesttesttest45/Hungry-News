import feedparser
from fuzzywuzzy import fuzz
import pandas as pd
import html

rss_urls = {
    "cna_latest": "https://www.channelnewsasia.com/api/v1/rss-outbound-feed?_format=xml",
    "cna_singapore": "https://www.channelnewsasia.com/api/v1/rss-outbound-feed?_format=xml&category=10416",
    "cna_asia": "https://www.channelnewsasia.com/api/v1/rss-outbound-feed?_format=xml&category=6511",
    "cna_world": "https://www.channelnewsasia.com/api/v1/rss-outbound-feed?_format=xml&category=6311",
    "bbc": "https://feeds.bbci.co.uk/news/rss.xml?edition=int",
}

def fetch_rss(url):
    """Fetch and parse RSS feed from a given URL."""
    feed = feedparser.parse(url)
    # HTML entities to text
    for entry in feed.entries:
        if 'summary' in entry:
            entry.summary = html.unescape(entry.summary)
        if 'title' in entry:
            entry.title = html.unescape(entry.title)
    return feed

def is_similar(title, existing_titles):
    """Check if title is similar to any existing title."""
    for existing in existing_titles:
        if fuzz.ratio(title.lower(), existing.lower()) > 80:
            return True
    return False

def sanitize_text(text):
    """Sanitize text to replace common encoding issues."""
    replacements = {
        'â€™': "'",
        'â€œ': '"',
        'â€”': '—',
        'â€¦': '…',
        'â€˜': '`',
        'â€¢': '•',
    }
    for wrong, correct in replacements.items():
        text = text.replace(wrong, correct)
    return text

def main():
    articles = []
    titles_seen = []

    for source, url in rss_urls.items():
        feed = fetch_rss(url)
        for entry in feed.entries:
            title = sanitize_text(entry.title)
            if title not in titles_seen and not is_similar(title, titles_seen):
                description = sanitize_text(entry.summary) if 'summary' in entry else 'no description'
                articles.append({
                    "title": title,
                    "description": description,
                    "impact": 0,
                    "source": source
                })
                titles_seen.append(title)
    
    df = pd.DataFrame(articles)
    df.to_csv('dataset/sample_data.csv', index=False, encoding='utf-8-sig')

if __name__ == "__main__":
    main()
