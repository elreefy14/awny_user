@echo off
curl -X POST "https://awnyapp.com/api/register" -H "Content-Type: application/json" -d @request.json -o response.txt
echo Response saved to response.txt 