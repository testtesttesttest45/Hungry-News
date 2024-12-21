import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report
from sklearn.metrics import accuracy_score
from sklearn.utils.class_weight import compute_class_weight
import numpy as np
import joblib

def preprocess_text(text):
    """Preprocess the text for training and prediction."""
    text = text.lower().strip()
    return text

def load_data(filepath):
    """Load data from a CSV file and preprocess it."""
    data = pd.read_csv(filepath, encoding='utf-8-sig')
    data['title'] = data['title'].fillna('no title').apply(preprocess_text)
    return data.drop_duplicates(subset=['title'])


def train_model(data, model_path='trained_model.joblib'):
    """Train a model using the title column and save it to the specified path."""
    data['title'] = data['title'].fillna('no title')
    X_train, X_test, y_train, y_test = train_test_split(
        data['title'], data['impact'], test_size=0.2, random_state=42, stratify=data['impact']
    )

    pipeline = Pipeline([
        ("vectorizer", TfidfVectorizer(max_features=10000, ngram_range=(1, 2))),  # Unigrams + bigrams
        ("classifier", MultinomialNB(alpha=0.5))  # Adjust smoothing parameter
    ])
    pipeline.fit(X_train, y_train)

    y_pred = pipeline.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    print(f"Model training complete with accuracy: {accuracy * 100:.2f}%")
    report = classification_report(y_test, y_pred, output_dict=True)

    # convert report to a DataFrame
    report_df = pd.DataFrame(report).transpose()

    print("\nClassification Report:")
    print(report_df.to_markdown(index=True))

    # Save model
    joblib.dump(pipeline, model_path)
    return pipeline

def load_model(model_path='trained_model.joblib'):
    """Load a pre-trained model from the specified path."""
    return joblib.load(model_path)
