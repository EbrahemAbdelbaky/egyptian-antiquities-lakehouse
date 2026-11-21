# Egyptian Antiquities Provenance Lakehouse

A university project in data mining and data warehousing. It brings the Egyptian collections of three museums (The Metropolitan Museum of Art, the Cleveland Museum of Art and the Louvre) into one SQL Server lakehouse (Bronze, Silver, Gold), links their rulers and find sites to Wikidata, and measures what the museum records do not say.

**Live site (Gold Explorer):** https://ebrahemabdelbaky.github.io/egyptian-antiquities-lakehouse/

## What is in this repository

| Folder | Content |
|---|---|
| `app/` | Gold Explorer, a Flutter web site. It reads one exported file (`assets/gold_data.json`) and calls no server. |
| `.github/workflows/` | Builds the site from `app/` and publishes it on GitHub Pages at every change of `app/`. |

The SQL scripts of the three layers and the project notes will be added here when the project is complete.

## Data sources and licences

- The Metropolitan Museum of Art Open Access (CC0 1.0) and Cleveland Museum of Art Open Access (CC0 1.0)
- Musée du Louvre, collections.louvre.fr (Etalab Open Licence; credit the Louvre; data loaded on 13 November 2026). Louvre images are not used.
- Wikidata (CC0) and Pleiades (CC BY 3.0, DOI 10.5281/zenodo.1193921)
- Fonts: TeX Gyre Pagella (GUST Font License), Carlito (SIL OFL 1.1), DejaVu Sans Mono (Bitstream Vera / DejaVu licence)

The full credits and the licence texts are on the page "Sources and licences" of the site and in `app/web/licenses/`. The site shows no museum image.

This project is not endorsed by, or connected to, the museums or the other data providers named above. The repository has no licence file yet: the licence of the code and of the derived data will be chosen when the project is complete.
