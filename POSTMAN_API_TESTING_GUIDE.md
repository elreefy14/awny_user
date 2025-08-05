# Awny App API Testing Guide - Postman Collection

This guide provides comprehensive Postman collection and environment files for testing the Awny App API endpoints, specifically the **Sign-Up** and **Social Login** functionalities.

## 📁 Files Included

1. **`Awny_App_API_Collection.postman_collection.json`** - Complete Postman collection with all API requests
2. **`Awny_App_Environment.postman_environment.json`** - Environment variables for easy configuration
3. **`POSTMAN_API_TESTING_GUIDE.md`** - This guide

## 🚀 Quick Setup

### Step 1: Import Collection
1. Open Postman
2. Click **Import** button
3. Select `Awny_App_API_Collection.postman_collection.json`
4. Click **Import**

### Step 2: Import Environment
1. Click **Import** button again
2. Select `Awny_App_Environment.postman_environment.json`
3. Click **Import**
4. Select "Awny App Environment" from the environment dropdown (top right)

## 📋 API Endpoints Included

### 🔐 Authentication Endpoints

#### **Sign-Up Endpoint**: `POST /api/register`

**Test Cases Included:**
1. **Complete Registration** - Full user registration with Egyptian phone
2. **Saudi Phone Number** - Registration with Saudi Arabian phone (+966)
3. **Missing Email (Error Test)** - Validation testing
4. **Invalid Email Format** - Email validation testing

**Required Fields:**
```json
{
    "first_name": "string",
    "last_name": "string", 
    "username": "string",
    "email": "string",
    "password": "string",
    "contact_number": "string (+countrycode-number)",
    "user_type": "user",
    "login_type": "user"
}
```

#### **Social Login Endpoint**: `POST /api/social-login`

**Test Cases Included:**
1. **Complete Google Login** - Full social login with all fields
2. **With Phone Number** - Social login including phone verification
3. **Minimal Fields** - Login with required fields only
4. **Missing Email (Error Test)** - Validation testing

**Required Fields:**
```json
{
    "email": "string",
    "login_type": "google",
    "first_name": "string",
    "last_name": "string",
    "username": "string",
    "user_type": "user",
    "uid": "string (Firebase UID)",
    "display_name": "string (optional)",
    "social_image": "string (optional)"
}
```

## 🔧 Environment Variables

The environment file includes these pre-configured variables:

| Variable | Value | Description |
|----------|-------|-------------|
| `base_url` | `https://awnyapp.com/api` | Base API URL |
| `register_endpoint` | `{{base_url}}/register` | Registration endpoint |
| `social_login_endpoint` | `{{base_url}}/social-login` | Social login endpoint |
| `test_email_egypt` | `test.egypt@example.com` | Test email for Egypt |
| `test_email_saudi` | `test.saudi@example.com` | Test email for Saudi |
| `test_phone_egypt` | `+20-1234567890` | Egyptian phone format |
| `test_phone_saudi` | `+966-501234567` | Saudi phone format |
| `google_uid_test` | `google_firebase_uid_123456789` | Test Firebase UID |

## 📱 Phone Number Formats

### Egyptian Numbers (+20)
- Format: `+20-XXXXXXXXXX`
- Length: 10 digits after country code
- Valid prefixes: `10`, `11`, `12`, `15`
- Example: `+20-1234567890`

### Saudi Arabian Numbers (+966)
- Format: `+966-XXXXXXXXX`
- Length: 9 digits after country code
- Must start with: `5`
- Example: `+966-501234567`

## 🧪 Testing Scenarios

### ✅ Successful Registration Test
```json
{
    "first_name": "John",
    "last_name": "Doe",
    "username": "johndoe123",
    "email": "john.doe.test@example.com",
    "password": "SecurePassword123!",
    "contact_number": "+20-1234567890",
    "user_type": "user",
    "login_type": "user"
}
```

### ✅ Successful Google Social Login Test
```json
{
    "email": "test@gmail.com",
    "login_type": "google",
    "first_name": "Test",
    "last_name": "User",
    "username": "testuser",
    "user_type": "user",
    "display_name": "Test User",
    "uid": "google_firebase_uid_123456789",
    "social_image": "https://lh3.googleusercontent.com/a/default-user"
}
```

## 🔍 Expected Responses

### Successful Registration/Login
```json
{
    "status": true,
    "message": "User registered successfully",
    "data": {
        "user": {
            "id": 123,
            "first_name": "John",
            "last_name": "Doe",
            "email": "john.doe@example.com",
            "username": "johndoe123",
            "contact_number": "+20-1234567890",
            "user_type": "user"
        },
        "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
    }
}
```

### Error Response
```json
{
    "status": false,
    "message": "Validation failed",
    "errors": {
        "email": ["The email field is required."],
        "password": ["The password field is required."]
    }
}
```

## ⚠️ Current Known Issues

**500 Internal Server Error**: Currently, both endpoints are returning server errors. This indicates server-side issues that need to be resolved:

1. **Database connectivity problems**
2. **Server configuration issues**
3. **Missing environment variables**
4. **Code errors in the backend**

## 🛠️ Troubleshooting

### If you get 500 errors:
1. Check server logs (`storage/logs/laravel.log`)
2. Verify database connectivity
3. Check `.env` file configuration
4. Ensure all required environment variables are set
5. Test in local development environment

### If you get 404 errors:
1. Verify the base URL is correct
2. Check if the API endpoints exist
3. Ensure the server is running

### If you get CORS errors:
1. Check if CORS is properly configured on the server
2. Verify the allowed origins include your domain

## 📝 How to Use

1. **Import both files** into Postman
2. **Select the environment** from the dropdown
3. **Choose a request** from the collection
4. **Modify the request body** if needed (change email, username, etc.)
5. **Click Send** to execute the request
6. **Review the response** in the bottom panel

## 🔄 Customizing Requests

You can easily customize the requests by:
- Changing email addresses to avoid duplicates
- Modifying usernames for uniqueness
- Testing different phone number formats
- Adding/removing optional fields

## 📞 Support

If you encounter issues:
1. Check the server logs first
2. Verify your request format matches the examples
3. Ensure all required fields are included
4. Test with different data to isolate the issue

---

**Note**: Remember to change email addresses and usernames between tests to avoid duplicate entry errors! 