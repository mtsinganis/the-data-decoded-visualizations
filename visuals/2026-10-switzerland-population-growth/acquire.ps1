# Run from the repository root. Writes a separate snapshot for review.
$ErrorActionPreference = 'Stop'
$project = 'visuals/2026-10-switzerland-population-growth'
$query = [System.IO.File]::ReadAllText((Resolve-Path "$project/data/query.json"))
$response = Invoke-WebRequest -UseBasicParsing -Method Post -Uri 'https://www.pxweb.bfs.admin.ch/api/v1/en/px-x-0102020000_101/px-x-0102020000_101.px' -ContentType 'application/json; charset=utf-8' -Body ([System.Text.Encoding]::UTF8.GetBytes($query))
$output = Join-Path (Get-Location) "$project/data/fso-response-new.json"
[System.IO.File]::WriteAllText($output, $response.Content, [System.Text.UTF8Encoding]::new($false))
Write-Output "Saved $output; review changes before replacing the archived response."
