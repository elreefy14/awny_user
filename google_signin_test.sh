#!/bin/bash

# Google Sign-In API Test Script
# Based on the Flutter app's Google sign-in implementation

# API Configuration
BASE_URL="https://awnyapp.com/api"
ENDPOINT="social-login"
FULL_URL="${BASE_URL}/${ENDPOINT}"

echo "=== Google Sign-In API Test ==="
echo "Testing endpoint: ${FULL_URL}"
echo ""

# Test Case 1: Valid Google Sign-In Request
echo "Test Case 1: Valid Google Sign-In Request"
echo "----------------------------------------"

curl -X POST "${FULL_URL}" \
  -H "Content-Type: application/json; charset=utf-8" \
  -H "Accept: application/json; charset=utf-8" \
  -H "Cache-Control: no-cache" \
  -H "Access-Control-Allow-Headers: *" \
  -H "Access-Control-Allow-Origin: *" \
  -d '{
    "email": "test.user@gmail.com",
    "login_type": "google",
    "first_name": "Test",
    "last_name": "User",
    "username": "testuser",
    "user_type": "user",
    "display_name": "Test User",
    "uid": "google_firebase_uid_123456789",
    "social_image": "https://lh3.googleusercontent.com/a/default-user"
  }' \
  --verbose \
  --write-out "\n\nResponse Time: %{time_total}s\nHTTP Code: %{http_code}\n" \
  --max-time 30

echo -e "\n\n"

# Test Case 2: New User Registration via Google
echo "Test Case 2: New User Registration via Google"
echo "---------------------------------------------"

curl -X POST "${FULL_URL}" \
  -H "Content-Type: application/json; charset=utf-8" \
  -H "Accept: application/json; charset=utf-8" \
  -H "Cache-Control: no-cache" \
  -H "Access-Control-Allow-Headers: *" \
  -H "Access-Control-Allow-Origin: *" \
  -d '{
    "email": "newuser@gmail.com",
    "login_type": "google",
    "first_name": "New",
    "last_name": "User",
    "username": "newuser",
    "user_type": "user",
    "display_name": "New User",
    "uid": "google_firebase_uid_987654321",
    "social_image": "https://lh3.googleusercontent.com/a/new-user-photo"
  }' \
  --verbose \
  --write-out "\n\nResponse Time: %{time_total}s\nHTTP Code: %{http_code}\n" \
  --max-time 30

echo -e "\n\n"

# Test Case 3: Missing Required Fields
echo "Test Case 3: Missing Required Fields (Error Test)"
echo "-------------------------------------------------"

curl -X POST "${FULL_URL}" \
  -H "Content-Type: application/json; charset=utf-8" \
  -H "Accept: application/json; charset=utf-8" \
  -H "Cache-Control: no-cache" \
  -H "Access-Control-Allow-Headers: *" \
  -H "Access-Control-Allow-Origin: *" \
  -d '{
    "email": "incomplete@gmail.com",
    "login_type": "google"
  }' \
  --verbose \
  --write-out "\n\nResponse Time: %{time_total}s\nHTTP Code: %{http_code}\n" \
  --max-time 30

echo -e "\n\n"

# Test Case 4: Invalid Login Type
echo "Test Case 4: Invalid Login Type (Error Test)"
echo "---------------------------------------------"

curl -X POST "${FULL_URL}" \
  -H "Content-Type: application/json; charset=utf-8" \
  -H "Accept: application/json; charset=utf-8" \
  -H "Cache-Control: no-cache" \
  -H "Access-Control-Allow-Headers: *" \
  -H "Access-Control-Allow-Origin: *" \
  -d '{
    "email": "test@gmail.com",
    "login_type": "invalid_type",
    "first_name": "Test",
    "last_name": "User",
    "username": "testuser",
    "user_type": "user",
    "display_name": "Test User",
    "uid": "invalid_uid_123",
    "social_image": "https://example.com/photo.jpg"
  }' \
  --verbose \
  --write-out "\n\nResponse Time: %{time_total}s\nHTTP Code: %{http_code}\n" \
  --max-time 30

echo -e "\n\n"

# Test Case 5: With Phone Number (Complete Profile)
echo "Test Case 5: Google Sign-In with Phone Number"
echo "---------------------------------------------"

curl -X POST "${FULL_URL}" \
  -H "Content-Type: application/json; charset=utf-8" \
  -H "Accept: application/json; charset=utf-8" \
  -H "Cache-Control: no-cache" \
  -H "Access-Control-Allow-Headers: *" \
  -H "Access-Control-Allow-Origin: *" \
  -d '{
    "email": "complete.user@gmail.com",
    "login_type": "google",
    "first_name": "Complete",
    "last_name": "User",
    "username": "completeuser",
    "user_type": "user",
    "display_name": "Complete User",
    "uid": "google_firebase_uid_complete_123",
    "social_image": "https://lh3.googleusercontent.com/a/complete-user",
    "contact_number": "+201234567890",
    "phone_verified": true
  }' \
  --verbose \
  --write-out "\n\nResponse Time: %{time_total}s\nHTTP Code: %{http_code}\n" \
  --max-time 30

echo -e "\n\n=== Test Complete ==="

# Additional curl command for quick testing (one-liner)
echo ""
echo "Quick Test Command (copy and paste):"
echo "------------------------------------"
echo "curl -X POST 'https://awnyapp.com/api/social-login' \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"email\":\"test@gmail.com\",\"login_type\":\"google\",\"first_name\":\"Test\",\"last_name\":\"User\",\"username\":\"testuser\",\"user_type\":\"user\",\"display_name\":\"Test User\",\"uid\":\"google_uid_123\",\"social_image\":\"https://example.com/photo.jpg\"}'" 