<#
.SYNOPSIS
    Konvertiert handbuch.md → handbuch.html mit Blau-Gold-Template
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DocsDir = (Resolve-Path "$ScriptDir\..\docs").Path
$mdPath = "$DocsDir\handbuch\handbuch.md"
$htmlPath = "$DocsDir\handbuch\handbuch.html"

if (-not (Test-Path $mdPath)) {
    Write-Host "❌ $mdPath nicht gefunden" -ForegroundColor Red
    exit 1
}

$md = Get-Content $mdPath -Raw

# ─── Markdown → HTML ─────────────────────────────────────────────────────────

# Code-Blöcke zuerst (vor anderen Ersetzungen)
$md = $md -replace '```(\w*)\r?\n(.*?)\r?\n```', '<pre><code>$2</code></pre>'
$md = $md -replace '`([^`]+)`', '<code>$1</code>'

# Überschriften
$md = $md -replace '^#### (.+)$', '<h4>$1</h4>'
$md = $md -replace '^### (.+)$', '<h3>$1</h3>'
$md = $md -replace '^## (.+)$', '<h2>$1</h2>'
$md = $md -replace '^# (.+)$', '<h1>$1</h1>'

# Horizontale Linie
$md = $md -replace '^---$', '<hr>'

# Fett & Kursiv
$md = $md -replace '\*\*\*(.+?)\*\*\*', '<strong><em>$1</em></strong>'
$md = $md -replace '\*\*(.+?)\*\*', '<strong>$1</strong>'
$md = $md -replace '\*(.+?)\*', '<em>$1</em>'

# Links
$md = $md -replace '\[([^\]]+)\]\(([^)]+)\)', '<a href="$2">$1</a>'

# Unsorted Lists (- Item)
$md = $md -replace '(?m)^- (.+)$', '<li>$1</li>'

# Sortierte Lists (1. Item)
$md = $md -replace '(?m)^\d+\.\s(.+)$', '<li>$1</li>'

# List items in <ul> wrappen
$md = $md -replace '(<li>.*?</li>\r?\n)+', '<ul>$0</ul>'

# Blockquotes
$md = $md -replace '(?m)^> (.+)$', '<blockquote>$1</blockquote>'
$md = $md -replace '</blockquote>\r?\n<blockquote>', '<br>'

# Tabellen (einfach – Spalten mit |)
$lines = $md -split "`n"
$inTable = $false
$tableHtml = @()
$result = @()

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match '^\|.*\|$') {
        if (-not $inTable) {
            $tableHtml = @('<table>')
            $inTable = $true
        }
        # Überspringe Trennzeile (|---|---|)
        if ($line -notmatch '^\|[\s\-:]+\|') {
            $cells = $line -split '\|' | Where-Object { $_ -ne '' } | ForEach-Object { $_.Trim() }
            $tag = if ($tableHtml.Count -eq 1) { 'th' } else { 'td' }
            $row = '<tr>' + ($cells | ForEach-Object { "<$tag>$_</$tag>" }) + '</tr>'
            $tableHtml += $row
        }
    }
    else {
        if ($inTable) {
            $tableHtml += '</table>'
            $result += ($tableHtml -join "`n")
            $tableHtml = @()
            $inTable = $false
        }
        $result += $line
    }
}
if ($inTable) {
    $tableHtml += '</table>'
    $result += ($tableHtml -join "`n")
}
$md = $result -join "`n"

# Paragraphen (leerzeilengetrennte Textblöcke, die nicht schon HTML sind)
$md = $md -replace '(?m)^(?!<)([^<\n].+)$', '<p>$1</p>'

# Doppelte <p> um bereits vorhandene HTML-Tags bereinigen
$md = $md -replace '<p>(<(h[1-4]|hr|ul|ol|li|table|blockquote|pre|div)[^>]*>)', '$1'
$md = $md -replace '(</(h[1-4]|hr|ul|ol|li|table|blockquote|pre|div)>)</p>', '$1'

# Leere <p> entfernen
$md = $md -replace '<p>\s*</p>', ''

# &quot; in HTML-Entities umwandeln für Sicherheit (nur in Attributen)
# (überspringen – unser Inhalt ist vertrauenswürdig)

# ─── In Template einbetten ───────────────────────────────────────────────────
$title = "Rosenkranz – Handbuch"
$html = @"
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title</title>
    <style>
        :root {
            --deep: #0D1B2A; --navy: #1B2D45; --royal: #2C4270;
            --gold: #D4AF37; --lightGold: #E8D48B; --cream: #F5F0E8;
            --soft: #E8E0D0; --muted: #8B7530;
        }
        * { margin:0; padding:0; box-sizing:border-box; }
        body {
            background: var(--deep); color: var(--cream);
            font-family: Georgia, 'Times New Roman', serif;
            line-height: 1.8; max-width: 800px; margin: 0 auto; padding: 40px 24px;
        }
        h1, h2, h3, h4 { color: var(--gold); font-weight: 300; }
        h1 { font-size: 2.4em; margin: 32px 0 16px; letter-spacing: 2px; }
        h2 { font-size: 1.7em; margin: 28px 0 12px; border-bottom: 1px solid var(--royal); padding-bottom: 8px; }
        h3 { font-size: 1.3em; margin: 20px 0 8px; }
        h4 { font-size: 1.1em; margin: 16px 0 6px; }
        p { margin-bottom: 14px; opacity: 0.92; }
        a { color: var(--lightGold); text-decoration: none; }
        a:hover { color: var(--gold); }
        strong { color: var(--gold); font-weight: 600; }
        em { color: var(--soft); }
        code { background: var(--navy); padding: 2px 8px; border-radius: 4px; font-size: 0.9em; }
        pre { background: var(--navy); padding: 16px; border-radius: 8px; overflow-x: auto; margin: 16px 0; }
        pre code { background: none; padding: 0; }
        hr { border: none; border-top: 1px solid var(--royal); margin: 24px 0; }
        blockquote {
            border-left: 3px solid var(--gold); padding: 12px 20px;
            margin: 16px 0; background: rgba(27,45,69,0.4);
            border-radius: 0 8px 8px 0; font-style: italic; color: var(--soft);
        }
        ul, ol { margin: 12px 0 12px 24px; }
        li { margin-bottom: 6px; opacity: 0.92; }
        table { width:100%; border-collapse:collapse; margin: 16px 0; }
        th { background: var(--navy); color: var(--gold); padding: 10px; text-align: left; font-weight: 600; }
        td { padding: 10px; border-bottom: 1px solid var(--royal); }
        tr:hover td { background: rgba(27,45,69,0.3); }

        nav { margin-bottom: 32px; }
        nav a { margin-right: 16px; font-size: 0.95em; }
        .back-link { display: inline-block; margin-bottom: 24px; }
        footer { margin-top: 48px; padding-top: 24px; border-top: 1px solid var(--royal); text-align: center; color: var(--muted); font-size: 0.85em; }
        @media (max-width:640px) { body { padding: 20px 16px; } h1 { font-size: 1.8em; } }
    </style>
</head>
<body>
<nav>
    <a href="index.html" class="back-link">← Zurück zur Startseite</a>
</nav>
$md
<footer>
    <p>Rosenkranz-App © 2026</p>
</footer>
</body>
</html>
"@

Set-Content -Path $htmlPath -Value $html -Encoding UTF8
Write-Host "✅ handbuch.html generiert: $htmlPath" -ForegroundColor Green
