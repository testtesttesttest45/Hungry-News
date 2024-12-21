# Hungry News Overview

+ Hungry News is an app for Android phones. It offers a user friendly interface and displays quality, impactful articles all of which are worthy of reading.

+ Every news articles is a takeaway of something happening around the world, with importance and legitimacy. Hence, readers are then able to stay up to date and can share with their friends and family. The app contains news that are always up to date. There is option to view detailed article. Lengthy news? Use the Summarise feature! If readers want more information about a news article they are reading, they can click the citation links. Don't want to read? Use the Listen feature!

+ News are sorted by weeks. Readers can view news from the past weeks. They can also search for news articles. The app also has a feature to save news articles. The app also has a feature to view the news articles from Singapore.

+ Fast and friendly interface with no bugs or ads.

+ Project started on 16 November 2024 and completed on 21 December 2024.

## Installation

### Android
1. Download the APK file <a href="https://github.com/testtesttesttest45/Hungry-News/releases/download/v1/hungry_news.apk" download>here</a>.

### Documentation attached <a href="https://drive.google.com/file/d/1qOgbexXZgI0abr6tl8q_WpDy54jWeFfa/view?usp=drive_link" target="_blank">here</a>.



## How is this app made?

### Frontend

+ The frontend of Hungry News was built using Flutter, an open-source framework developed by Google that enables developers to create cross-platform applications from a single codebase.

+ Flutter leverages the Dart programming language, which features a syntax similar to other C-like languages such as Java and JavaScript. This made it easier to build a robust and dynamic interface for the application.

+ User preferences, such as the app's theme and bookmarked news, are stored locally on the device. This eliminates the need for authentication, allowing multiple users to use the app on the same device without any login requirements.

+ Smooth user experience: The app design ensures a clean and responsive interface for browsing, reading, and managing news.

### Backend
+ The backend was developed in Python, which provides flexibility and efficiency for handling server-side logic. It includes:

+ APIs: A set of methods and endpoints that the frontend calls to fetch news and interact with the database.
Hosting: The backend code is hosted on Render, a cloud platform, ensuring that the application remains online and responsive at all times.

### Database
+ The news headlines and their details, such as publication date, source, and impact level, are stored in a MySQL database. The database is part of a Hostinger plan that offers unlimited database storage for a limited time.

+ Database optimizations include:

+ Table management: News older than three months is periodically deleted to reduce database size and improve performance.

### Machine Learning
+ To deliver high-quality and impactful news that meets the project’s requirements, machine learning was integrated into the backend.

### Model Creation and Training
+ The machine learning model was built using scikit-learn (sklearn), a Python library offering tools for classification, regression, clustering, and dimensionality reduction.
+ A dataset of approximately 1200 RSS news headlines from CNA and BBC was manually annotated based on perceived impact levels. Special attention was given to high-impact news, which is less frequent. Additional high-impact news was manually added to the dataset to balance the training process.
+ The trained model was exported using joblib, resulting in a lightweight (~100KB) file.

### Model Hosting
+ The model file was uploaded to AWS S3
+ An AWS Lambda function was created to utilize the model for classifying and sorting current news headlines from RSS feeds. The Lambda function uses a container image to package the model and its dependencies, overcoming the size limitations of direct zip uploads.


### Regular News Updates:

+ The Lambda function is triggered every hour using AWS EventBridge. It:
+ Fetches the latest news headlines from CNA and BBC.
+ Filters duplicates and similar news items using custom anti-duplication logic.
+ Classifies news into impact levels using the trained model.
+ Inserts unique news into the database, organized by publication date.

# Pages

## Major News Page
- This is the main page and purpose of the app. It displays only the highest impact news. Click on a news on this page or any other page to view the details and contents of the news. You can also Summarise the news, Listen to the news, or click on the citation links to view more information about the news.
- This is made possible thanks to a Lambda script that executes occationally for the extraction of RSS feed from the news websites (CNA and BBC) and inserted into a database.

## Past News Page
- Displays major news from the past weeks, up to 12 weeks.

## Curated News Page
- Displays local Singapore news as well as global medium impact news.
- Easy to use toggle buttons to filter news here based on "Singapore" and "All".

## Saved News Page
- Displays news that you have saved. You can save news by clicking on the "Save" icon on the news details page of any news.

## Search News Page
- Search for news articles by title. Searches up to 12 weeks of news.

## Settings Page
- Change the theme of the app to light or dark mode.
- App state management: Reset the app to its initial state. All saved news, theme settings, and news marked as read will all be cleared.
