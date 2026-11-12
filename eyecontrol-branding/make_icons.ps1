# Generates the EyeControl icons in every format RustDesk uses, from the EyeControl logo.
#   powershell -ExecutionPolicy Bypass -File eyecontrol-branding\make_icons.ps1
param([string]$Logo = (Resolve-Path "$PSScriptRoot\logo.png").Path)

$root = (Resolve-Path "$PSScriptRoot\..").Path
Add-Type -AssemblyName System.Drawing
$logoImg = [System.Drawing.Image]::FromFile($Logo)

# Eye + monitor area of the 1536x1024 logo (no "EyeControl" text), centred on a black square.
$crop = New-Object System.Drawing.Rectangle 360, 185, 810, 460
$side = 810
$square = New-Object System.Drawing.Bitmap $side, $side
$g = [System.Drawing.Graphics]::FromImage($square)
$g.Clear([System.Drawing.Color]::Black)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$top = [int](($side - $crop.Height) / 2)
$dest = New-Object System.Drawing.Rectangle 0, $top, $crop.Width, $crop.Height
$g.DrawImage($logoImg, $dest, $crop, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()

function Resize([System.Drawing.Image]$img, [int]$size) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $gr = [System.Drawing.Graphics]::FromImage($bmp)
    $gr.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gr.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $gr.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $gr.DrawImage($img, 0, 0, $size, $size)
    $gr.Dispose()
    return $bmp
}

function Save-Png([int]$size, [string]$path) {
    (Resize $square $size).Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Save-Ico([int[]]$sizes, [string]$path) {
    $pngs = foreach ($s in $sizes) {
        $ms = New-Object System.IO.MemoryStream
        (Resize $square $s).Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        , $ms.ToArray()
    }
    $out = New-Object System.IO.MemoryStream
    $w = New-Object System.IO.BinaryWriter $out
    $w.Write([UInt16]0); $w.Write([UInt16]1); $w.Write([UInt16]$sizes.Count)
    $offset = 6 + 16 * $sizes.Count
    for ($i = 0; $i -lt $sizes.Count; $i++) {
        $s = $sizes[$i]; $len = $pngs[$i].Length
        $b = if ($s -ge 256) { 0 } else { $s }
        $w.Write([byte]$b); $w.Write([byte]$b); $w.Write([byte]0); $w.Write([byte]0)
        $w.Write([UInt16]1); $w.Write([UInt16]32); $w.Write([UInt32]$len); $w.Write([UInt32]$offset)
        $offset += $len
    }
    foreach ($p in $pngs) { $w.Write($p) }
    $w.Flush()
    [System.IO.File]::WriteAllBytes($path, $out.ToArray())
}

Save-Png 1024 "$root\res\icon.png"
Save-Png 1024 "$root\res\mac-icon.png"
Save-Png 256 "$root\res\128x128@2x.png"
Save-Png 128 "$root\res\128x128.png"
Save-Png 64 "$root\res\64x64.png"
Save-Png 32 "$root\res\32x32.png"
Save-Ico @(256, 128, 64, 48, 32, 16) "$root\res\icon.ico"
Save-Ico @(32, 16) "$root\res\tray-icon.ico"
Save-Ico @(256, 64, 48, 32, 16) "$root\flutter\windows\runner\resources\app_icon.ico"
$logoImg.Dispose(); $square.Dispose()
"icons written"
