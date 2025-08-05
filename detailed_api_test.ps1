# Detailed Google Sign-In API Test Script
# Based on the Flutter app's Google sign-in implementation

Write-Host "=== Detailed Google Sign-In API Test ===" -ForegroundColor Green
Write-Host "Testing endpoint: https://awnyapp.com/api/social-login" -ForegroundColor Yellow
Write-Host ""

function Test-GoogleSignIn {
    param(
        [string]$TestName,
        [hashtable]$RequestData
    )
    
    Write-Host "=== $TestName ===" -ForegroundColor Cyan
    Write-Host "Request Data:" -ForegroundColor Yellow
    Write-Host ($RequestData | ConvertTo-Json -Depth 3) -ForegroundColor White
    Write-Host ""
    
    $headers = @{
        'Content-Type' = 'application/json; charset=utf-8'
        'Accept' = 'application/json; charset=utf-8'
        'Cache-Control' = 'no-cache'
        'Access-Control-Allow-Headers' = '*'
        'Access-Control-Allow-Origin' = '*'
        'User-Agent' = 'PowerShell-Test/1.0'
    }
    
    $body = $RequestData | ConvertTo-Json -Depth 3
    
    try {
        Write-Host "Sending request..." -ForegroundColor Yellow
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        $response = Invoke-RestMethod -Uri "https://awnyapp.com/api/social-login" -Method Post -Headers $headers -Body $body -TimeoutSec 30
        
        $stopwatch.Stop()
        Write-Host "SUCCESS: API Response received in $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Green
        Write-Host "Response:" -ForegroundColor Green
        Write-Host ($response | ConvertTo-Json -Depth 10) -ForegroundColor White
        
    } catch {
        $stopwatch.Stop()
        Write-Host "ERROR after $($stopwatch.ElapsedMilliseconds)ms: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode
            $statusDescription = $_.Exception.Response.StatusDescription
            Write-Host "HTTP Status: $statusCode - $statusDescription" -ForegroundColor Red
            
            # Try to read the response content for more details
            try {
                $responseStream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($responseStream)
                $responseContent = $reader.ReadToEnd()
                $reader.Close()
                
                if ($responseContent) {
                    Write-Host "Error Response Content:" -ForegroundColor Yellow
                    try {
                        $errorJson = $responseContent | ConvertFrom-Json
                        Write-Host ($errorJson | ConvertTo-Json -Depth 5) -ForegroundColor Red
                    } catch {
                        Write-Host $responseContent -ForegroundColor Red
                    }
                }
            } catch {
                Write-Host "Could not read error response content: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host ""
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
}

# Test Case 1: Complete Valid Request
Test-GoogleSignIn -TestName "Test 1: Complete Valid Google Sign-In" -RequestData @{
    email = "test@gmail.com"
    login_type = "google"
    first_name = "Test"
    last_name = "User"
    username = "testuser"
    user_type = "user"
    display_name = "Test User"
    uid = "google_firebase_uid_123456789"
    social_image = "https://lh3.googleusercontent.com/a/default-user"
}

# Test Case 2: Minimal Required Fields
Test-GoogleSignIn -TestName "Test 2: Minimal Required Fields" -RequestData @{
    email = "minimal@gmail.com"
    login_type = "google"
    first_name = "Min"
    last_name = "User"
    username = "minuser"
    user_type = "user"
    uid = "google_uid_minimal"
}

# Test Case 3: With Phone Number
Test-GoogleSignIn -TestName "Test 3: With Phone Number" -RequestData @{
    email = "phone@gmail.com"
    login_type = "google"
    first_name = "Phone"
    last_name = "User"
    username = "phoneuser"
    user_type = "user"
    display_name = "Phone User"
    uid = "google_firebase_uid_phone_123"
    social_image = "https://lh3.googleusercontent.com/a/phone-user"
    contact_number = "+201234567890"
    phone_verified = $true
}

# Test Case 4: Missing Required Field (Error Test)
Test-GoogleSignIn -TestName "Test 4: Missing Email (Error Test)" -RequestData @{
    login_type = "google"
    first_name = "No"
    last_name = "Email"
    username = "noemail"
    user_type = "user"
    uid = "google_uid_no_email"
}

Write-Host "=== All Tests Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "- API Endpoint: https://awnyapp.com/api/social-login" -ForegroundColor White
Write-Host "- Method: POST" -ForegroundColor White
Write-Host "- Content-Type: application/json" -ForegroundColor White
Write-Host "- Expected Response: JSON with user data and authentication token" -ForegroundColor White
Write-Host ""
Write-Host "If you're getting 500 errors, check:" -ForegroundColor Yellow
Write-Host "1. Server logs for detailed error information" -ForegroundColor White
Write-Host "2. Database connectivity" -ForegroundColor White
Write-Host "3. Required fields validation on server side" -ForegroundColor White
Write-Host "4. Firebase configuration" -ForegroundColor White 