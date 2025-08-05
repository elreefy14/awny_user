# Test script for Sign-Up API endpoint
# Base URL: https://awnyapp.com/api/register

$baseUrl = "https://awnyapp.com/api/register"
$headers = @{
    "Content-Type" = "application/json"
    "Accept" = "application/json"
    "User-Agent" = "PostmanRuntime/7.32.3"
}

function Test-SignUp {
    param(
        [string]$testName,
        [hashtable]$requestData
    )
    
    Write-Host "`n=== $testName ===" -ForegroundColor Cyan
    Write-Host "Endpoint: $baseUrl" -ForegroundColor Yellow
    
    $jsonBody = $requestData | ConvertTo-Json -Depth 10
    Write-Host "Request Body:" -ForegroundColor Green
    Write-Host $jsonBody -ForegroundColor White
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        $response = Invoke-RestMethod -Uri $baseUrl -Method POST -Headers $headers -Body $jsonBody -ErrorAction Stop
        
        $stopwatch.Stop()
        Write-Host "✅ Success! Response time: $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Green
        Write-Host "Response:" -ForegroundColor Green
        Write-Host ($response | ConvertTo-Json -Depth 10) -ForegroundColor White
        
    } catch {
        $stopwatch.Stop()
        Write-Host "❌ Error! Response time: $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Red
        Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        Write-Host "Status Description: $($_.Exception.Response.StatusDescription)" -ForegroundColor Red
        
        # Try to read error response content
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorContent = $reader.ReadToEnd()
            if ($errorContent) {
                Write-Host "Error Response:" -ForegroundColor Red
                Write-Host $errorContent -ForegroundColor White
            }
        } catch {
            Write-Host "Could not read error response content" -ForegroundColor Yellow
        }
    }
    
    Write-Host ("-" * 80) -ForegroundColor Gray
}

# Test Case 1: Complete valid registration request
Write-Host "Starting Sign-Up API Tests..." -ForegroundColor Magenta

$validRequest = @{
    first_name = "John"
    last_name = "Doe"
    username = "johndoe123"
    email = "john.doe.test@example.com"
    password = "SecurePassword123!"
    contact_number = "+20-1234567890"
    user_type = "user"
    login_type = "user"
}

Test-SignUp -testName "Test 1: Complete Valid Registration" -requestData $validRequest

# Test Case 2: Registration with Saudi phone number
$saudiRequest = @{
    first_name = "Ahmed"
    last_name = "Al-Rashid"
    username = "ahmed_rashid"
    email = "ahmed.rashid.test@example.com"
    password = "MyPassword456!"
    contact_number = "+966-501234567"
    user_type = "user"
    login_type = "user"
}

Test-SignUp -testName "Test 2: Registration with Saudi Phone Number" -requestData $saudiRequest

# Test Case 3: Registration with Egyptian phone number
$egyptRequest = @{
    first_name = "Mohamed"
    last_name = "Hassan"
    username = "mohamed_hassan"
    email = "mohamed.hassan.test@example.com"
    password = "EgyptPass789!"
    contact_number = "+20-01123456789"
    user_type = "user"
    login_type = "user"
}

Test-SignUp -testName "Test 3: Registration with Egyptian Phone Number" -requestData $egyptRequest

# Test Case 4: Missing required field (email)
$missingEmailRequest = @{
    first_name = "Test"
    last_name = "User"
    username = "testuser"
    password = "TestPass123!"
    contact_number = "+20-1234567890"
    user_type = "user"
    login_type = "user"
}

Test-SignUp -testName "Test 4: Missing Required Field (Email)" -requestData $missingEmailRequest

# Test Case 5: Invalid email format
$invalidEmailRequest = @{
    first_name = "Invalid"
    last_name = "Email"
    username = "invalidemail"
    email = "not-an-email"
    password = "ValidPass123!"
    contact_number = "+20-1234567890"
    user_type = "user"
    login_type = "user"
}

Test-SignUp -testName "Test 5: Invalid Email Format" -requestData $invalidEmailRequest

# Test Case 6: Weak password
$weakPasswordRequest = @{
    first_name = "Weak"
    last_name = "Password"
    username = "weakpass"
    email = "weak.password.test@example.com"
    password = "123"
    contact_number = "+20-1234567890"
    user_type = "user"
    login_type = "user"
}

Test-SignUp -testName "Test 6: Weak Password" -requestData $weakPasswordRequest

Write-Host "`n=== Test Summary ===" -ForegroundColor Magenta
Write-Host "All sign-up API tests completed!" -ForegroundColor Green
Write-Host "`nIf you're getting 500 errors, check:" -ForegroundColor Yellow
Write-Host "1. Server logs (storage/logs/laravel.log)" -ForegroundColor White
Write-Host "2. Database connectivity" -ForegroundColor White
Write-Host "3. Environment configuration (.env file)" -ForegroundColor White
Write-Host "4. Required field validation on server" -ForegroundColor White
Write-Host "5. Email uniqueness constraints" -ForegroundColor White

Write-Host "`n=== Curl Commands for Manual Testing ===" -ForegroundColor Magenta

Write-Host "`nBasic Registration Test:" -ForegroundColor Yellow
Write-Host 'curl -X POST "https://awnyapp.com/api/register" \' -ForegroundColor White
Write-Host '  -H "Content-Type: application/json" \' -ForegroundColor White
Write-Host '  -H "Accept: application/json" \' -ForegroundColor White
Write-Host '  -d "{' -ForegroundColor White
Write-Host '    \"first_name\": \"Test\",' -ForegroundColor White
Write-Host '    \"last_name\": \"User\",' -ForegroundColor White
Write-Host '    \"username\": \"testuser123\",' -ForegroundColor White
Write-Host '    \"email\": \"test.user@example.com\",' -ForegroundColor White
Write-Host '    \"password\": \"SecurePass123!\",' -ForegroundColor White
Write-Host '    \"contact_number\": \"+20-1234567890\",' -ForegroundColor White
Write-Host '    \"user_type\": \"user\",' -ForegroundColor White
Write-Host '    \"login_type\": \"user\"' -ForegroundColor White
Write-Host '  }"' -ForegroundColor White

Write-Host "`nVerbose Registration Test:" -ForegroundColor Yellow
Write-Host 'curl -X POST "https://awnyapp.com/api/register" \' -ForegroundColor White
Write-Host '  -H "Content-Type: application/json" \' -ForegroundColor White
Write-Host '  -H "Accept: application/json" \' -ForegroundColor White
Write-Host '  -H "User-Agent: curl/7.68.0" \' -ForegroundColor White
Write-Host '  -v \' -ForegroundColor White
Write-Host '  -d "{' -ForegroundColor White
Write-Host '    \"first_name\": \"John\",' -ForegroundColor White
Write-Host '    \"last_name\": \"Doe\",' -ForegroundColor White
Write-Host '    \"username\": \"johndoe456\",' -ForegroundColor White
Write-Host '    \"email\": \"john.doe456@example.com\",' -ForegroundColor White
Write-Host '    \"password\": \"MySecurePassword123!\",' -ForegroundColor White
Write-Host '    \"contact_number\": \"+20-01123456789\",' -ForegroundColor White
Write-Host '    \"user_type\": \"user\",' -ForegroundColor White
Write-Host '    \"login_type\": \"user\"' -ForegroundColor White
Write-Host '  }"' -ForegroundColor White 