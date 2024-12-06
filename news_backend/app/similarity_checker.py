from fuzzywuzzy import fuzz

def is_similar(title1, title2, threshold=55): # the higher the threshold, the more similar the titles need to be
    # print the similarity ratio
    print(fuzz.token_sort_ratio(title1, title2))
    return fuzz.token_sort_ratio(title1, title2) > threshold

title1 = "Red weather alert for Wales as Storm Darragh to hit"
title2 = "Rare red wind warning issued as Storm Darragh approaches UK"

if is_similar(title1, title2):
    print("Similar.")
else:
    print("Different.")
