from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report, accuracy_score
import pandas as pd
import joblib

def preprocess_text(text):
    text = text.lower().strip()
    return text

def load_data(filepath):
    data = pd.read_csv(filepath, encoding='utf-8-sig')
    data['title'] = data['title'].fillna('no title').apply(preprocess_text)
    return data.drop_duplicates(subset=['title'])

def train_model(data, model_path='trained_model.joblib'):
    """Train Random Forest model and save it."""
    data['title'] = data['title'].fillna('no title')
    X_train, X_test, y_train, y_test = train_test_split(
        data['title'], data['impact'], test_size=0.2, random_state=42, stratify=data['impact']
    )

    pipeline = Pipeline([
        ("vectorizer", TfidfVectorizer(max_features=10000, ngram_range=(1, 2))),  # Unigrams + bigrams
        ("classifier", RandomForestClassifier(n_estimators=200, random_state=42, class_weight='balanced'))
    ])
    pipeline.fit(X_train, y_train)

    y_pred = pipeline.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    print(f"Model training complete with accuracy: {accuracy * 100:.2f}%")
    report = classification_report(y_test, y_pred, output_dict=True)

    report_df = pd.DataFrame(report).transpose()
    print("\nClassification Report:")
    print(report_df.to_markdown(index=True))

    joblib.dump(pipeline, model_path)
    return pipeline

def load_model(model_path='trained_model.joblib'):
    """Load a pre-trained model from the specified path."""
    return joblib.load(model_path)
