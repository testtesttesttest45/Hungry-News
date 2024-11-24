import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import make_pipeline
import joblib

def load_data(filepath):
    """Load data from a CSV file, attempting different encodings if necessary."""
    encodings = ['utf-8-sig', 'latin1', 'ISO-8859-1', 'cp1252']
    for encoding in encodings:
        try:
            return pd.read_csv(filepath, encoding=encoding)
        except UnicodeDecodeError as e:
            print(f"Failed to decode with {encoding}, trying next...")
    raise ValueError("Could not decode the file with any known encodings.")


def train_model(data, model_path='trained_model.joblib'):
    """Train a model and save it to the specified path."""
    data['description'] = data['description'].fillna('no description')
    X_train, X_test, y_train, y_test = train_test_split(data['description'], data['impact'], test_size=0.2, random_state=42)
    model = make_pipeline(TfidfVectorizer(), MultinomialNB())
    model.fit(X_train, y_train)
    joblib.dump(model, model_path)  # serialize the model
    print("Model training complete with accuracy:", model.score(X_test, y_test))
    return model

def load_model(model_path='trained_model.joblib'):
    """Load a pre-trained model from the specified path."""
    return joblib.load(model_path)

def predict(model, text):
    """Predict the impact level of a news article."""
    return model.predict([text])[0]
