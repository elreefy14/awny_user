@echo off
REM Google Sign-In API Test Script for Windows
REM Based on the Flutter app's Google sign-in implementation

echo === Google Sign-In API Test ===
echo Testing endpoint: https://awnyapp.com/api/social-login
echo.

echo Test Case 1: Valid Google Sign-In Request
echo ----------------------------------------
curl -X POST "https://awnyapp.com/api/social-login" ^
  -H "Content-Type: application/json; charset=utf-8" ^
  -H "Accept: application/json; charset=utf-8" ^
  -H "Cache-Control: no-cache" ^
  -H "Access-Control-Allow-Headers: *" ^
  -H "Access-Control-Allow-Origin: *" ^
  -d "{\"email\":\"test.user@gmail.com\",\"login_type\":\"google\",\"first_name\":\"Test\",\"last_name\":\"User\",\"username\":\"testuser\",\"user_type\":\"user\",\"display_name\":\"Test User\",\"uid\":\"google_firebase_uid_123456789\",\"social_image\":\"https://lh3.googleusercontent.com/a/default-user\"}" ^
  --verbose ^
  --write-out "Response Time: %%{time_total}s HTTP Code: %%{http_code}" ^
  --max-time 30

echo.
echo.

echo Test Case 2: New User Registration via Google
echo ---------------------------------------------
curl -X POST "https://awnyapp.com/api/social-login" ^
  -H "Content-Type: application/json; charset=utf-8" ^
  -H "Accept: application/json; charset=utf-8" ^
  -H "Cache-Control: no-cache" ^
  -H "Access-Control-Allow-Headers: *" ^
  -H "Access-Control-Allow-Origin: *" ^
  -d "{\"email\":\"newuser@gmail.com\",\"login_type\":\"google\",\"first_name\":\"New\",\"last_name\":\"User\",\"username\":\"newuser\",\"user_type\":\"user\",\"display_name\":\"New User\",\"uid\":\"google_firebase_uid_987654321\",\"social_image\":\"https://lh3.googleusercontent.com/a/new-user-photo\"}" ^
  --verbose ^
  --write-out "Response Time: %%{time_total}s HTTP Code: %%{http_code}" ^
  --max-time 30

echo.
echo.

echo === Test Complete ===
echo.
echo Quick Test Command (copy and paste):
echo ------------------------------------
echo curl -X POST "https://awnyapp.com/api/social-login" -H "Content-Type: application/json" -d "{\"email\":\"test@gmail.com\",\"login_type\":\"google\",\"first_name\":\"Test\",\"last_name\":\"User\",\"username\":\"testuser\",\"user_type\":\"user\",\"display_name\":\"Test User\",\"uid\":\"google_uid_123\",\"social_image\":\"https://example.com/photo.jpg\"}"

pause 