import feedparser

def fetch_rss(url):
    """Fetch and parse RSS feed from a given URL."""
    return feedparser.parse(url)

def get_news_items(rss_data):
    """Extract news items from the parsed RSS data."""
    return rss_data.entries
