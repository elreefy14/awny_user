# Awny App API Documentation

**Base URL:** `https://awnyapp.com/api`  
**Version:** 1.0  
**Content-Type:** `application/json`  
**Accept:** `application/json`

---

## 📋 Table of Contents

1. [Authentication Endpoints](#authentication-endpoints)
2. [Request Examples](#request-examples)
3. [Response Examples](#response-examples)
4. [Error Handling](#error-handling)
5. [Phone Number Formats](#phone-number-formats)
6. [Testing Guidelines](#testing-guidelines)

---

## 🔐 Authentication Endpoints

### 1. User Registration
**Endpoint:** `POST /register`  
**Description:** Register a new user account  
**Authentication:** None required

**Headers:**
```
Content-Type: application/json
Accept: application/json
User-Agent: PostmanRuntime/7.32.3
```

**Request Body:**
```json
{
    "first_name": "{{$randomFirstName}}",
    "last_name": "{{$randomLastName}}",
    "username": "{{$randomUserName}}",
    "email": "{{$randomEmail}}",
    "password": "SecurePass123!",
    "contact_number": "+20-1234567890",
    "user_type": "user",
    "login_type": "user"
}
```

**Required Fields:**
- `first_name` (string, max: 255)
- `last_name` (string, max: 255)
- `username` (string, unique, max: 255)
- `email` (string, unique, valid email format)
- `password` (string, min: 8, must contain letters and numbers)
- `contact_number` (string, format: +countrycode-number)
- `user_type` (string, always "user")
- `login_type` (string, always "user")

---

### 2. User Login
**Endpoint:** `POST /login`  
**Description:** Authenticate existing user  
**Authentication:** None required

**Headers:**
```
Content-Type: application/json
Accept: application/json
```

**Request Body:**
```json
{
    "email": "user@example.com",
    "password": "SecurePass123!",
    "login_type": "user"
}
```

**Required Fields:**
- `email` (string, valid email format)
- `password` (string)
- `login_type` (string, always "user")

---

### 3. Social Login (Google)
**Endpoint:** `POST /social-login`  
**Description:** Authenticate or register user via Google OAuth  
**Authentication:** None required

**Headers:**
```
Content-Type: application/json; charset=utf-8
Accept: application/json; charset=utf-8
Cache-Control: no-cache
User-Agent: PostmanRuntime/7.32.3
```

**Request Body (Complete):**
```json
{
    "email": "{{$randomEmail}}",
    "login_type": "google",
    "first_name": "{{$randomFirstName}}",
    "last_name": "{{$randomLastName}}",
    "username": "{{$randomUserName}}",
    "user_type": "user",
    "display_name": "{{$randomFirstName}} {{$randomLastName}}",
    "uid": "google_firebase_uid_{{$randomInt}}",
    "social_image": "https://lh3.googleusercontent.com/a/default-user"
}
```

**Request Body (With Phone):**
```json
{
    "email": "{{$randomEmail}}",
    "login_type": "google",
    "first_name": "{{$randomFirstName}}",
    "last_name": "{{$randomLastName}}",
    "username": "{{$randomUserName}}",
    "user_type": "user",
    "display_name": "{{$randomFirstName}} {{$randomLastName}}",
    "uid": "google_firebase_uid_{{$randomInt}}",
    "social_image": "https://lh3.googleusercontent.com/a/default-user",
    "contact_number": "+201234567890",
    "phone_verified": true
}
```

**Required Fields:**
- `email` (string, valid email format)
- `login_type` (string, always "google")
- `first_name` (string, max: 255)
- `last_name` (string, max: 255)
- `username` (string, unique, max: 255)
- `user_type` (string, always "user")
- `uid` (string, Firebase UID)

**Optional Fields:**
- `display_name` (string)
- `social_image` (string, valid URL)
- `contact_number` (string, phone format)
- `phone_verified` (boolean)

---

## 📝 Request Examples

### Registration Example (Egyptian User)
```json
{
    "first_name": "Ahmed",
    "last_name": "Hassan",
    "username": "ahmed_hassan_123",
    "email": "ahmed.hassan@example.com",
    "password": "MySecurePass123!",
    "contact_number": "+20-1123456789",
    "user_type": "user",
    "login_type": "user"
}
```

### Registration Example (Saudi User)
```json
{
    "first_name": "Mohammed",
    "last_name": "Al-Rashid",
    "username": "mohammed_rashid",
    "email": "mohammed.rashid@example.com",
    "password": "SecurePassword456!",
    "contact_number": "+966-501234567",
    "user_type": "user",
    "login_type": "user"
}
```

### Login Example
```json
{
    "email": "ahmed.hassan@example.com",
    "password": "MySecurePass123!",
    "login_type": "user"
}
```

### Google Social Login Example
```json
{
    "email": "john.doe@gmail.com",
    "login_type": "google",
    "first_name": "John",
    "last_name": "Doe",
    "username": "john_doe_google",
    "user_type": "user",
    "display_name": "John Doe",
    "uid": "google_firebase_uid_123456789",
    "social_image": "https://lh3.googleusercontent.com/a/ACg8ocK..."
}
```

---

## 📤 Response Examples

### Successful Registration/Login Response
```json
{
    "status": true,
    "message": "User registered successfully",
    "data": {
        "user": {
            "id": 123,
            "first_name": "Ahmed",
            "last_name": "Hassan",
            "email": "ahmed.hassan@example.com",
            "username": "ahmed_hassan_123",
            "contact_number": "+20-1123456789",
            "user_type": "user",
            "profile_image": null,
            "status": 1,
            "email_verified_at": null,
            "created_at": "2024-01-15T10:30:00.000000Z",
            "updated_at": "2024-01-15T10:30:00.000000Z"
        },
        "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvYXdueWFwcC5jb21cL2FwaVwvcmVnaXN0ZXIiLCJpYXQiOjE2NDIyNDQ2MDAsImV4cCI6MTY0MjMzMTAwMCwibmJmIjoxNjQyMjQ0NjAwLCJqdGkiOiJhYmMxMjMiLCJzdWIiOjEyMywicHJ2IjoiMjNiZDVjODk0OWY2MDBhZGIzOWU3MDFjNDAwODcyZGI3YTU5NzZmNyJ9.signature",
        "api_token": "bearer_token_here"
    }
}
```

### Successful Social Login Response
```json
{
    "status": true,
    "message": "Social login successful",
    "data": {
        "user": {
            "id": 124,
            "first_name": "John",
            "last_name": "Doe",
            "email": "john.doe@gmail.com",
            "username": "john_doe_google",
            "contact_number": null,
            "user_type": "user",
            "profile_image": "https://lh3.googleusercontent.com/a/ACg8ocK...",
            "status": 1,
            "social_id": "google_firebase_uid_123456789",
            "login_type": "google",
            "created_at": "2024-01-15T10:35:00.000000Z",
            "updated_at": "2024-01-15T10:35:00.000000Z"
        },
        "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
        "api_token": "bearer_token_here"
    }
}
```

---

## ❌ Error Handling

### Validation Error Response (422)
```json
{
    "status": false,
    "message": "The given data was invalid.",
    "errors": {
        "email": [
            "The email field is required."
        ],
        "password": [
            "The password field is required."
        ],
        "contact_number": [
            "The contact number format is invalid."
        ]
    }
}
```

### Duplicate Email Error (422)
```json
{
    "status": false,
    "message": "The email has already been taken.",
    "errors": {
        "email": [
            "The email has already been taken."
        ]
    }
}
```

### Invalid Credentials Error (401)
```json
{
    "status": false,
    "message": "Invalid credentials",
    "data": null
}
```

### Server Error (500)
```json
{
    "status": false,
    "message": "Internal Server Error",
    "error": "Something went wrong on the server"
}
```

---

## 📱 Phone Number Formats

### Egyptian Numbers (+20)
- **Format:** `+20-XXXXXXXXXX`
- **Length:** 10 digits after country code
- **Valid Prefixes:** 10, 11, 12, 15
- **Examples:**
  - `+20-1012345678` (Vodafone)
  - `+20-1123456789` (Etisalat)
  - `+20-1234567890` (Orange)
  - `+20-1512345678` (WE)

### Saudi Arabian Numbers (+966)
- **Format:** `+966-XXXXXXXXX`
- **Length:** 9 digits after country code
- **Must Start With:** 5
- **Examples:**
  - `+966-501234567` (STC)
  - `+966-551234567` (Mobily)
  - `+966-591234567` (Zain)

---

## 🧪 Testing Guidelines

### Pre-Test Setup
1. **Import Collection:** Use the provided Postman collection file
2. **Set Environment:** Import and select the Awny App environment
3. **Update Variables:** Modify test emails and usernames to avoid duplicates

### Test Scenarios

#### Registration Tests
1. **Valid Registration (Egypt)** - Complete user data with Egyptian phone
2. **Valid Registration (Saudi)** - Complete user data with Saudi phone
3. **Missing Required Fields** - Test validation (remove email)
4. **Invalid Email Format** - Test email validation
5. **Weak Password** - Test password requirements
6. **Duplicate Email** - Test uniqueness constraints

#### Login Tests
1. **Valid Credentials** - Successful login
2. **Invalid Email** - Non-existent email
3. **Wrong Password** - Incorrect password
4. **Missing Fields** - Incomplete request

#### Social Login Tests
1. **New Google User** - First-time Google login (registration)
2. **Existing Google User** - Returning Google user (login)
3. **Google with Phone** - Social login including phone number
4. **Minimal Fields** - Required fields only
5. **Missing UID** - Test Firebase UID requirement

### Postman Variables for Testing
```javascript
// Use these in your request bodies for dynamic testing
{{$randomFirstName}}     // Random first name
{{$randomLastName}}      // Random last name
{{$randomUserName}}      // Random username
{{$randomEmail}}         // Random email
{{$randomInt}}           // Random integer
{{$timestamp}}           // Current timestamp
```

### Test Scripts (Add to Postman Tests tab)

#### Registration Test Script
```javascript
pm.test("Status code is 200 or 201", function () {
    pm.expect(pm.response.code).to.be.oneOf([200, 201]);
});

pm.test("Response has required fields", function () {
    const responseJson = pm.response.json();
    pm.expect(responseJson).to.have.property('status');
    pm.expect(responseJson).to.have.property('data');
    pm.expect(responseJson.data).to.have.property('user');
    pm.expect(responseJson.data).to.have.property('token');
});

pm.test("User data is correct", function () {
    const responseJson = pm.response.json();
    const user = responseJson.data.user;
    pm.expect(user).to.have.property('email');
    pm.expect(user).to.have.property('first_name');
    pm.expect(user).to.have.property('last_name');
});
```

#### Login Test Script
```javascript
pm.test("Login successful", function () {
    pm.response.to.have.status(200);
    const responseJson = pm.response.json();
    pm.expect(responseJson.status).to.be.true;
    pm.expect(responseJson.data.token).to.not.be.empty;
});

// Save token for future requests
if (pm.response.code === 200) {
    const responseJson = pm.response.json();
    pm.environment.set("auth_token", responseJson.data.token);
}
```

---

## 🔧 Environment Variables

Create these variables in your Postman environment:

| Variable | Initial Value | Current Value | Description |
|----------|---------------|---------------|-------------|
| `base_url` | `https://awnyapp.com/api` | `https://awnyapp.com/api` | Base API URL |
| `auth_token` | | | JWT token from login |
| `test_email_egypt` | `test.egypt@example.com` | | Egyptian test email |
| `test_email_saudi` | `test.saudi@example.com` | | Saudi test email |
| `test_phone_egypt` | `+20-1234567890` | | Egyptian phone format |
| `test_phone_saudi` | `+966-501234567` | | Saudi phone format |
| `google_uid` | `google_firebase_uid_123456789` | | Test Firebase UID |

---

## 📞 Support & Troubleshooting

### Common Issues

1. **500 Internal Server Error**
   - Check server logs
   - Verify database connectivity
   - Ensure environment variables are set

2. **422 Validation Error**
   - Check required fields
   - Verify data formats
   - Ensure unique constraints

3. **CORS Issues**
   - Verify server CORS configuration
   - Check allowed origins

### Contact Information
- **API Base URL:** https://awnyapp.com/api
- **Documentation Version:** 1.0
- **Last Updated:** January 2024

---

**Note:** Remember to update email addresses and usernames between tests to avoid duplicate entry errors. Use Postman's dynamic variables for automated unique data generation. 