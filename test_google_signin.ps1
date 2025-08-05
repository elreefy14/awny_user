# Google Sign-In API Test Script for PowerShell
# Based on the Flutter app's Google sign-in implementation

Write-Host "=== Google Sign-In API Test ===" -ForegroundColor Green
Write-Host "Testing endpoint: https://awnyapp.com/api/social-login" -ForegroundColor Yellow
Write-Host ""

# Test Case 1: Valid Google Sign-In Request
Write-Host "Test Case 1: Valid Google Sign-In Request" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan

$headers = @{
    'Content-Type' = 'application/json'
    'Accept' = 'application/json'
}

$body = @{
    email = "test@gmail.com"
    login_type = "google"
    first_name = "Test"
    last_name = "User"
    username = "testuser"
    user_type = "user"
    display_name = "Test User"
    uid = "google_uid_123"
    social_image = "https://example.com/photo.jpg"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "https://awnyapp.com/api/social-login" -Method Post -Headers $headers -Body $body -TimeoutSec 30
    Write-Host "SUCCESS: API Response received" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10) -ForegroundColor White
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "HTTP Status Code: $statusCode" -ForegroundColor Red
        
        # Try to read the response content
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseContent = $reader.ReadToEnd()
            Write-Host "Response Content: $responseContent" -ForegroundColor Yellow
        } catch {
            Write-Host "Could not read response content" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Green

# Alternative using curl if available
Write-Host ""
Write-Host "Alternative curl command:" -ForegroundColor Yellow
Write-Host 'curl -X POST "https://awnyapp.com/api/social-login" -H "Content-Type: application/json" -d "{\"email\":\"test@gmail.com\",\"login_type\":\"google\",\"first_name\":\"Test\",\"last_name\":\"User\",\"username\":\"testuser\",\"user_type\":\"user\",\"display_name\":\"Test User\",\"uid\":\"google_uid_123\",\"social_image\":\"https://example.com/photo.jpg\"}"' -ForegroundColor White 