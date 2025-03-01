###################################################
#    FSLogix Setup Installation Python Rest API  #
#    Written by Aavisek Choudhury
###################################################
from flask import Flask, jsonify
import os
import requests
import zipfile
import subprocess
import winreg

app = Flask(__name__)

LOCAL_AVD_PATH = "C:\\temp\\avd"
FSLOGIX_DOWNLOAD_URL = "https://aka.ms/fslogix_download"
FSINSTALLER_ZIP = os.path.join(LOCAL_AVD_PATH, "FSLogixAppsSetup.zip")
FSINSTALLER_PATH = os.path.join(LOCAL_AVD_PATH, "FSLogix")
PROFILE_PATH = "\\\aznonprodavdsa.file.core.windows.net\profiles"

@app.route('/install_fslogix', methods=['POST'])
def install_fslogix():
    try:
        os.makedirs(LOCAL_AVD_PATH, exist_ok=True)

        # Download FSLogix
        response = requests.get(FSLOGIX_DOWNLOAD_URL)
        with open(FSINSTALLER_ZIP, 'wb') as f:
            f.write(response.content)

        # Extract FSLogix
        with zipfile.ZipFile(FSINSTALLER_ZIP, 'r') as zip_ref:
            zip_ref.extractall(FSINSTALLER_PATH)

        # Install FSLogix
        fslogix_exe = os.path.join(FSINSTALLER_PATH, "x64", "Release", "FSLogixAppsSetup.exe")
        fslogix_msi = os.path.join(FSINSTALLER_PATH, "FSLogixAppsSetup.msi")

        if os.path.exists(fslogix_exe):
            subprocess.run([fslogix_exe, "/install", "/quiet"], check=True)
        elif os.path.exists(fslogix_msi):
            subprocess.run(["msiexec.exe", "/i", fslogix_msi, "/quiet", "/norestart"], check=True)
        else:
            return jsonify({"error": "FSLogix installer not found"}), 500

        return jsonify({"message": "FSLogix installed successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/configure_fslogix', methods=['POST'])
def configure_fslogix():
    try:
        fslogix_settings = {
            "Enabled": 1,
            "VHDLocations": PROFILE_PATH,
            "SizeInMBs": 15360,
            "IsDynamic": 1,
            "ClearCacheOnLogoff": 1,
            "VolumeType": "vhdx",
            "LockedRetryCount": 12,
            "DeleteLocalProfileWhenVHDShouldApply": 1,
            "LockedRetryInterval": 5,
            "ProfileType": 3,
            "ConcurrentUserSessions": 1,
            "RoamSearch": 2,
            "FlipFlopProfileDirectoryName": 1,
            "SIDDirNamePattern": "%username%%sid%",
            "SIDDirNameMatch": "%username%%sid%"
        }

        key_path = r"Software\FSLogix\Profiles"
        with winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, key_path) as key:
            for name, value in fslogix_settings.items():
                winreg.SetValueEx(key, name, 0, winreg.REG_SZ if isinstance(value, str) else winreg.REG_DWORD, value)

        return jsonify({"message": "FSLogix profile settings configured successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
