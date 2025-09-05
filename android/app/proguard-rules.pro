# Key Properties for Release Signing
# Copy this file to key.properties and fill in your keystore details
# DO NOT commit key.properties to version control

storeFile=upload-keystore.jks
storePassword=YOUR_KEYSTORE_PASSWORD
keyAlias=office-syndrome-helper
keyPassword=YOUR_KEY_PASSWORD

# Instructions to create keystore:
# 1. Run: keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias office-syndrome-helper
# 2. Follow the prompts to set passwords and details
# 3. Copy the generated upload-keystore.jks to android/app/
# 4. Update the passwords in key.properties
# 5. Add key.properties to .gitignore