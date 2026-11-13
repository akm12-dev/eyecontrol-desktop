# Home-screen logos (max 300x60 displayed, generated at 2x):
#   flutter/assets/logo_dark.png   logo on transparent background (black becomes transparent, glow kept)
#   flutter/assets/logo_light.png  same logo on a dark navy rounded card, readable on the light theme
param([string]$Logo = (Resolve-Path "$PSScriptRoot\logo.png").Path)

$root = (Resolve-Path "$PSScriptRoot\..").Path
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class EcAlpha {
  // alpha = brightest channel; colour un-premultiplied so the glow blends on any dark background
  public static Bitmap BlackToAlpha(Bitmap src) {
    var dst = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
    var r = new Rectangle(0, 0, src.Width, src.Height);
    var s = src.LockBits(r, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    var d = dst.LockBits(r, ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
    int n = Math.Abs(s.Stride) * src.Height; var px = new byte[n];
    Marshal.Copy(s.Scan0, px, 0, n);
    for (int i = 0; i < n; i += 4) {
      int b = px[i], g = px[i+1], rr = px[i+2];
      int a = Math.Max(rr, Math.Max(g, b));
      if (a == 0) { px[i] = px[i+1] = px[i+2] = px[i+3] = 0; continue; }
      px[i] = (byte)Math.Min(255, b * 255 / a); px[i+1] = (byte)Math.Min(255, g * 255 / a);
      px[i+2] = (byte)Math.Min(255, rr * 255 / a); px[i+3] = (byte)a;
    }
    Marshal.Copy(px, 0, d.Scan0, n);
    src.UnlockBits(s); dst.UnlockBits(d); return dst;
  }
}
"@

$img = [System.Drawing.Image]::FromFile($Logo)
# Eye + "EyeControl" wordmark area of the 1536x1024 logo
$crop = New-Object System.Drawing.Rectangle 290, 190, 956, 640
$h = 120; $w = [int]($crop.Width * $h / $crop.Height)

function New-Canvas([int]$cw, [int]$ch) {
    $bmp = New-Object System.Drawing.Bitmap $cw, $ch, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    return @($bmp, $g)
}

# Scaled logo on black, then black -> transparent
$scaled, $g = New-Canvas $w $h
$g.Clear([System.Drawing.Color]::Black)
$g.DrawImage($img, (New-Object System.Drawing.Rectangle 0, 0, $w, $h), $crop, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$transparent = [EcAlpha]::BlackToAlpha($scaled)
$transparent.Save("$root\flutter\assets\logo_dark.png", [System.Drawing.Imaging.ImageFormat]::Png)

# Light theme: same transparent logo on a rounded navy card
$pad = 10
$card, $g = New-Canvas ($w + 2 * $pad) ($h + 2 * $pad)
$g.Clear([System.Drawing.Color]::Transparent)
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$rad = 22; $cw = $card.Width - 1; $chh = $card.Height - 1
$path.AddArc(0, 0, $rad, $rad, 180, 90); $path.AddArc($cw - $rad, 0, $rad, $rad, 270, 90)
$path.AddArc($cw - $rad, $chh - $rad, $rad, $rad, 0, 90); $path.AddArc(0, $chh - $rad, $rad, $rad, 90, 90); $path.CloseFigure()
$g.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 11, 17, 24))), $path)
$g.DrawImage($transparent, $pad, $pad, $w, $h)
$g.Dispose()
$card.Save("$root\flutter\assets\logo_light.png", [System.Drawing.Imaging.ImageFormat]::Png)
$img.Dispose()
"logos written ($w x $h)"
