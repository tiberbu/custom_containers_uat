import json
import os

# Read the apps.json file
with open("ci/apps.json", "r") as json_file:
    apps_data = json.load(json_file)

# Replace the token in the URLs
github_token = os.environ.get("TOKEN")
for app in apps_data:
    if "<TOKEN>" in app["url"]:
        app["url"] = app["url"].replace("<TOKEN>", github_token)

# Write the updated data back to the apps.json file
with open("ci/apps.json", "w") as json_file:
    json.dump(apps_data, json_file, indent=2)

print("Token replaced in apps.json successfully.")
