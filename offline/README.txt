Gold Explorer - offline package
===============================

How to run (Windows, no internet needed, no Flutter needed):
1. Unzip the whole package (right-click, Extract All). Do not run it from inside the zip.
2. Double-click start_gold_explorer.bat. A black window opens and then your browser opens http://localhost:8090/
3. Keep the black window open while you present. Close it to stop.

If the double-click does not work, open PowerShell in this folder and run:
    powershell -NoProfile -ExecutionPolicy Bypass -File .\serve.ps1

Why a script: the site is a Flutter web app. Browsers do not run it from a file:// address, so a small local server (serve.ps1) hands the files to the browser. Nothing leaves your computer.

The site is the same as https://ebrahemabdelbaky.github.io/egyptian-antiquities-lakehouse/ (credits and licences: site/licenses/README.txt and the page "Sources and licences").
