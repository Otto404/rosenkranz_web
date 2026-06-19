# Rosenkranz – Web & Download

Landing Page und Download-Bereich für die Rosenkranz-App.

🌐 **GitHub Pages:** `https://OTTO.github.io/rosenkranz_web/`

## Struktur

```
docs/
├── index.html          ← Landing Page
├── downloads/
│   ├── windows/        ← Windows-Installer (.msix, .zip)
│   └── android/        ← Android-APK
├── news/
│   └── index.html      ← News-Seite (Browser)
├── handbuch.md          ← Vollständiges Handbuch
├── .nojekyll
└── README.md
```

## Deployment

Die Binaries werden vom Quellcode-Repo hierher kopiert:

```bash
# Im Quellcode-Repo:
cd ../rosenkranz_app
.\scripts\copy_to_web.ps1 -BuildVersion "1.0.1"
```

Danach in diesem Repo committen und pushen.
