@echo off
setlocal enabledelayedexpansion

echo Testing Categories API...
curl "https://awnyapp.com/api/category-list?page=1&per_page=50" > categories.json
echo Categories saved to categories.json

echo.
echo Testing Services by Category...
echo Category ID,Service Status > category_service_results.txt

rem Extract category IDs with a simple approach
findstr /C:"\"id\":" categories.json > category_ids.txt

rem Process each category ID
for /f "tokens=1,2 delims=:," %%a in (category_ids.txt) do (
    if "%%a"=="    \"id\"" (
        set "category_id=%%b"
        set "category_id=!category_id: =!"
        
        echo Testing services for category ID !category_id!
        curl "https://awnyapp.com/api/search-list?category_id=!category_id!&page=1&per_page=10" > services_category_!category_id!.json
        
        rem Check if we got results by looking for a successful response
        findstr /C:"\"data\":" services_category_!category_id!.json > nul
        if !errorlevel! equ 0 (
            echo !category_id!,SUCCESS >> category_service_results.txt
            echo SUCCESS - Services found
        ) else (
            echo !category_id!,FAILED >> category_service_results.txt
            echo FAILED - No services found
        )
        
        echo Results saved to services_category_!category_id!.json
        echo.
    )
)

echo Testing completed. Check category_service_results.txt for results summary. 