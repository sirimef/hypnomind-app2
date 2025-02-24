@echo off
title GitHub Actions APK Build
cd /d C:\Users\LENOVO\Documents\dd

:: GitHub 설정
set GITHUB_USER=sirimef
set REPO_NAME=hypnomind-app2

:: Load GitHub Token from environment variable
set GITHUB_TOKEN=%GITHUB_TOKEN%
if "%GITHUB_TOKEN%"=="" (
    echo ERROR: GitHub Token is not set!
    echo Please set your token using: setx GITHUB_TOKEN "your_personal_access_token_here"
    pause
    exit
)

:: Check Git installation
git --version > nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Git is not installed!
    echo Download Git: https://git-scm.com/downloads
    pause
    exit
)

:: Set Git user identity
git config --global user.name "sirimef"
git config --global user.email "eptagon0102@naver.com"

:: Remove existing Git repository if exists
if exist .git (
    echo Removing existing Git repository...
    rmdir /s /q .git
)

:: Initialize new Git repository
echo Initializing Git repository...
git init
git add .
git commit -m "Initial commit"
git branch -M main

:: Check if GitHub repository exists
echo Checking if repository already exists...
curl -s -o nul -w "%%{http_code}" -u %GITHUB_USER%:%GITHUB_TOKEN% https://api.github.com/repos/%GITHUB_USER%/%REPO_NAME% > status.txt
set /p HTTP_STATUS=<status.txt
del status.txt

if "%HTTP_STATUS%"=="404" (
    echo Repository not found. Creating a new one...
    curl -u %GITHUB_USER%:%GITHUB_TOKEN% https://api.github.com/user/repos -d "{\"name\":\"%REPO_NAME%\"}"
) else (
    echo Repository already exists. Proceeding with push...
)

:: Add remote repository & push
git remote add origin https://%GITHUB_USER%:%GITHUB_TOKEN%@github.com/%GITHUB_USER%/%REPO_NAME%.git
git push -u origin main

:: Create GitHub Actions workflow
mkdir .github
mkdir .github\workflows
(
echo name: Build Flutter APK
echo.
echo on:
echo   workflow_dispatch:
echo   push:
echo     branches:
echo       - main
echo.
echo jobs:
echo   build:
echo     runs-on: ubuntu-latest
echo.
echo     steps:
echo       - name: Checkout Repository
echo         uses: actions/checkout@v3
echo.
echo       - name: Install Flutter
echo         uses: subosito/flutter-action@v2
echo         with:
echo           flutter-version: '3.x'
echo.
echo       - name: Install Dependencies
echo         run: flutter pub get
echo.
echo       - name: Build APK
echo         run: flutter build apk --release
echo.
echo       - name: Upload APK
echo         uses: actions/upload-artifact@v4
echo         with:
echo           name: hypnomind-apk
echo           path: build/app/outputs/flutter-apk/app-release.apk
) > .github\workflows\flutter-build.yml

:: Push GitHub Actions workflow
git add .
git commit -m "Updated GitHub Actions to use upload-artifact@v4"
git push origin main

:: Display GitHub Actions link
echo.
echo ✅ GitHub Actions setup complete!
echo Open the following link and click "Run workflow":
echo 🔗 https://github.com/%GITHUB_USER%/%REPO_NAME%/actions
echo.
echo 🎯 Once the build is complete, download the APK from "Artifacts".
echo.
pause
exit
