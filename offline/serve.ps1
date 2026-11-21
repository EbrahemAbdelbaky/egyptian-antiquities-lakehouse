# serve.ps1 - a tiny web server for Gold Explorer. It serves the folder "site" on http://localhost:8090/ and needs no internet and no admin rights.
$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'site'))
$port = 8090
if (-not (Test-Path -LiteralPath (Join-Path $root 'index.html'))) {
    Write-Host 'The folder "site" with index.html was not found next to this script. Unzip the whole package first, then run this again.'
    exit 1
}
$mime = @{
    '.html' = 'text/html; charset=utf-8'
    '.js'   = 'text/javascript; charset=utf-8'
    '.mjs'  = 'text/javascript; charset=utf-8'
    '.json' = 'application/json; charset=utf-8'
    '.css'  = 'text/css; charset=utf-8'
    '.txt'  = 'text/plain; charset=utf-8'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.svg'  = 'image/svg+xml'
    '.ico'  = 'image/x-icon'
    '.wasm' = 'application/wasm'
    '.otf'  = 'font/otf'
    '.ttf'  = 'font/ttf'
    '.woff2' = 'font/woff2'
}
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
try {
    $listener.Start()
} catch {
    Write-Host "Port $port is already in use. Close the other Gold Explorer window (or the program that uses port $port) and try again."
    exit 1
}
Write-Host "Gold Explorer is running at http://localhost:$port/"
Start-Process "http://localhost:$port/"
while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    try {
        $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
        if ($path -eq '/') { $path = '/index.html' }
        $full = [System.IO.Path]::GetFullPath((Join-Path $root ($path.TrimStart('/') -replace '/', '\')))
        if ($full.StartsWith($root) -and (Test-Path -LiteralPath $full -PathType Leaf)) {
            $ext = [System.IO.Path]::GetExtension($full).ToLower()
            if ($mime.ContainsKey($ext)) { $ctx.Response.ContentType = $mime[$ext] } else { $ctx.Response.ContentType = 'application/octet-stream' }
            $bytes = [System.IO.File]::ReadAllBytes($full)
            $ctx.Response.ContentLength64 = $bytes.Length
            $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $ctx.Response.StatusCode = 404
        }
    } catch {
        $ctx.Response.StatusCode = 500
    } finally {
        $ctx.Response.Close()
    }
}
