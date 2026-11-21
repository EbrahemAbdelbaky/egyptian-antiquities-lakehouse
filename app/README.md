# Gold Explorer (Flutter web)

Live: https://ebrahemabdelbaky.github.io/egyptian-antiquities-lakehouse/

The site that shows the Gold layer of the Egyptian Antiquities Provenance Lakehouse. It reads two exported files and calls no server:

- `assets/gold_data.json`: the Gold tables, samples and views (written by `export_gold_json.ps1` from the SQL Server database)
- `assets/gold_checks.json`: the result of the Gold checks

Run it: `flutter pub get`, then `flutter run -d web-server --web-port 8080`.
Build it: `flutter build web --release`.
Licences and credits of the data and the fonts: `web/licenses/README.txt` and the page "Sources and licences" of the site.
