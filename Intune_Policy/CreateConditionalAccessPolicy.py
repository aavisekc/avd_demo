#    Created by Aavisek Choudhury
# 	 whyazure.com
#    Microsoft MVP for AVD and Windows 365

import requests
import json
from msal import ConfidentialClientApplication
# EntraID Credentials – Replace with your actual values
TENANT_ID = "your_tenant_id"
CLIENT_ID = "your_client_id"
CLIENT_SECRET = "your_client_secret"
AUTHORITY = f"https://login.microsoftonline.com/{TENANT_ID}"
GRAPH_API_URL = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
# Authenticate with MSAL
def get_access_token():
	app = ConfidentialClientApplication(CLIENT_ID, CLIENT_SECRET, AUTHORITY)
	token_response = app.acquire_token_for_client(scopes=["https://graph.microsoft.com/.default"])
	if "access_token" in token_response:
		return token_response["access_token"]
	else:
		raise Exception("Failed to obtain access token")
# Conditional Access Policy JSON
policy_json = {
"displayName": "Require MFA for Windows 365",
"state": "enabled",
"conditions": {
"applications": {
"includeApplications": [
"0af06dc6-e4b5-4f28-818e-e78e62d137a5", # Windows 365 App ID
"9cdead84-a844-4324-93f2-b2e6bb768d07", # Azure Virtual Desktop App ID
"a4a365df-50f1-4397-bc59-1a1564b8bb9c", # Microsoft Remote Desktop App ID
"270efc09-cd0d-444b-a71f-39af4910ec45" # Windows Cloud Login App ID
]
},
"users": {
"includeUsers": ["all"]
},
"platforms": {
"includePlatforms": ["windows"]
},
"locations": {
"includeLocations": ["allTrusted"] # Apply only to trusted locations
}
},
"grantControls": {
"operator": "AND",
"builtInControls": ["mfa"] # Enforce Multi-Factor Authentication
}
}
# Create Conditional Access Policy
def create_conditional_access_policy():
	access_token = get_access_token()
	headers = {
		"Authorization": f"Bearer {access_token}",
		"Content-Type": "application/json"
	}
	response = requests.post(GRAPH_API_URL, headers=headers, json=policy_json)
	if response.status_code == 201:
		print("✅ Conditional Access Policy created successfully!")
	else:
		print(f"❌ Error: {response.status_code}, {response.text}")
# Run the script
if __name__ == "__main__":
	create_conditional_access_policy()88888888888