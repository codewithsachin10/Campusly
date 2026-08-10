import urllib.request
import json
url = "https://firestore.googleapis.com/v1/projects/campusly-app-2026/databases/(default)/documents/classes/section-b/schedule"
req = urllib.request.Request(url)
with urllib.request.urlopen(req) as response:
    print(response.read().decode('utf-8'))
