param(
  [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\media\osd\nara')
)

Add-Type -AssemblyName System.Drawing

$size = 64
$stroke = 2.8
$white = [System.Drawing.Color]::White
$lineCap = [System.Drawing.Drawing2D.LineCap]::Round
$lineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

function New-IconCanvas {
  $bitmap = [System.Drawing.Bitmap]::new($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.Clear([System.Drawing.Color]::Transparent)
  $pen = [System.Drawing.Pen]::new($white, $stroke)
  $pen.StartCap = $lineCap
  $pen.EndCap = $lineCap
  $pen.LineJoin = $lineJoin
  return @{ Bitmap = $bitmap; Graphics = $graphics; Pen = $pen }
}

function Save-Icon([string]$Name, [scriptblock]$Draw) {
  $canvas = New-IconCanvas
  try {
    & $Draw $canvas.Graphics $canvas.Pen
    $path = Join-Path $OutputDirectory "$Name.png"
    $canvas.Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  }
  finally {
    $canvas.Pen.Dispose()
    $canvas.Graphics.Dispose()
    $canvas.Bitmap.Dispose()
  }
}

function Draw-Polyline($g, $pen, [float[]]$points) {
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  try {
    $path.AddLines([System.Drawing.PointF[]]@(
      for ($index = 0; $index -lt $points.Count; $index += 2) {
        [System.Drawing.PointF]::new($points[$index], $points[$index + 1])
      }
    ))
    $g.DrawPath($pen, $path)
  }
  finally {
    $path.Dispose()
  }
}

function Draw-RoundedRectangle($g, $pen, [float]$x, [float]$y, [float]$width, [float]$height, [float]$radius) {
  $diameter = $radius * 2
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  try {
    $path.AddArc($x, $y, $diameter, $diameter, 180, 90)
    $path.AddArc($x + $width - $diameter, $y, $diameter, $diameter, 270, 90)
    $path.AddArc($x + $width - $diameter, $y + $height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($x, $y + $height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    $g.DrawPath($pen, $path)
  }
  finally {
    $path.Dispose()
  }
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

# The seek nib is rendered as the right cap of a progress control. Its transparent background
# matches the 1920-wide skin geometry: 1676px bar plus a 32px nib half-width on each side.
$progressTrack = [System.Drawing.Bitmap]::new(1740, 64, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
try {
  $progressTrackGraphics = [System.Drawing.Graphics]::FromImage($progressTrack)
  try { $progressTrackGraphics.Clear($white) } finally { $progressTrackGraphics.Dispose() }
  $progressTrack.Save((Join-Path $OutputDirectory 'progress-nib-track.png'), [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
  $progressTrack.Dispose()
}

Save-Icon 'audio' {
  param($g, $p)
  foreach ($bar in @(@(15, 27, 15, 37), @(23, 20, 23, 44), @(32, 13, 32, 51), @(41, 20, 41, 44), @(49, 27, 49, 37))) {
    $g.DrawLine($p, $bar[0], $bar[1], $bar[2], $bar[3])
  }
}

Save-Icon 'subtitles' {
  param($g, $p)
  Draw-Polyline $g $p ([float[]]@(14, 46, 25, 18, 36, 46))
  $g.DrawLine($p, 19, 34, 31, 34)
  $g.DrawLine($p, 40, 28, 51, 28)
  $g.DrawLine($p, 40, 40, 48, 40)
}

Save-Icon 'process-info' {
  param($g, $p)
  $g.DrawLine($p, 18, 44, 18, 32)
  $g.DrawLine($p, 32, 42, 32, 23)
  $g.DrawLine($p, 46, 44, 46, 14)
}

Save-Icon 'video' {
  param($g, $p)
  Draw-RoundedRectangle $g $p 13 13 38 38 5
  Draw-Polyline $g $p ([float[]]@(27, 23, 41, 32, 27, 41, 27, 23))
}

Save-Icon 'processing' {
  param($g, $p)
  foreach ($entry in @(@(14, 20, 50, 20, 26), @(14, 32, 50, 32, 40), @(14, 44, 50, 44, 31))) {
    $g.DrawLine($p, $entry[0], $entry[1], $entry[2], $entry[3])
    $g.DrawEllipse($p, $entry[4] - 4, $entry[1] - 4, 8, 8)
  }
}

Save-Icon 'system' {
  param($g, $p)
  Draw-RoundedRectangle $g $p 17 17 30 30 3
  Draw-RoundedRectangle $g $p 24 24 16 16 2
  foreach ($offset in @(22, 32, 42)) {
    $g.DrawLine($p, $offset, 11, $offset, 17)
    $g.DrawLine($p, $offset, 47, $offset, 53)
    $g.DrawLine($p, 11, $offset, 17, $offset)
    $g.DrawLine($p, 47, $offset, 53, $offset)
  }
}

Save-Icon 'metadata' {
  param($g, $p)
  Draw-Polyline $g $p ([float[]]@(13, 22, 32, 13, 51, 22, 32, 31, 13, 22))
  Draw-Polyline $g $p ([float[]]@(13, 32, 32, 41, 51, 32))
  Draw-Polyline $g $p ([float[]]@(13, 42, 32, 51, 51, 42))
}

Save-Icon 'dolby-vision' {
  param($g, $p)
  Draw-Polyline $g $p ([float[]]@(14, 18, 32, 32, 14, 46, 14, 18))
  Draw-Polyline $g $p ([float[]]@(50, 18, 32, 32, 50, 46, 50, 18))
}

Save-Icon 'status-ok' {
  param($g, $p)
  $g.DrawEllipse($p, 10, 10, 44, 44)
  Draw-Polyline $g $p ([float[]]@(19, 33, 28, 42, 45, 22))
}

Save-Icon 'status-no' {
  param($g, $p)
  $g.DrawEllipse($p, 10, 10, 44, 44)
  $g.DrawLine($p, 21, 21, 43, 43)
  $g.DrawLine($p, 43, 21, 21, 43)
}

Save-Icon 'previous' {
  param($g, $p)
  $g.DrawLine($p, 18, 18, 18, 46)
  Draw-Polyline $g $p ([float[]]@(45, 17, 25, 32, 45, 47))
}

Save-Icon 'rewind' {
  param($g, $p)
  Draw-Polyline $g $p ([float[]]@(31, 17, 13, 32, 31, 47))
  Draw-Polyline $g $p ([float[]]@(51, 17, 33, 32, 51, 47))
}

Save-Icon 'play' {
  param($g, $p)
  Draw-Polyline $g $p ([float[]]@(23, 15, 47, 32, 23, 49, 23, 15))
}

Save-Icon 'pause' {
  param($g, $p)
  Draw-RoundedRectangle $g $p 19 15 8 34 2
  Draw-RoundedRectangle $g $p 37 15 8 34 2
}

Save-Icon 'stop' {
  param($g, $p)
  Draw-RoundedRectangle $g $p 18 18 28 28 3
}

Save-Icon 'forward' {
  param($g, $p)
  Draw-Polyline $g $p ([float[]]@(13, 17, 31, 32, 13, 47))
  Draw-Polyline $g $p ([float[]]@(33, 17, 51, 32, 33, 47))
}

Save-Icon 'next' {
  param($g, $p)
  Draw-Polyline $g $p ([float[]]@(19, 17, 39, 32, 19, 47))
  $g.DrawLine($p, 46, 18, 46, 46)
}

Save-Icon 'disc-menu' {
  param($g, $p)
  $g.DrawEllipse($p, 11, 11, 42, 42)
  $g.DrawEllipse($p, 27, 27, 10, 10)
  $g.DrawLine($p, 18, 20, 28, 20)
  $g.DrawLine($p, 18, 26, 24, 26)
}

Save-Icon 'channels' {
  param($g, $p)
  foreach ($y in @(17, 32, 47)) {
    $g.DrawEllipse($p, 14, $y - 2, 4, 4)
    $g.DrawLine($p, 25, $y, 50, $y)
  }
}

Save-Icon 'guide' {
  param($g, $p)
  Draw-RoundedRectangle $g $p 13 13 38 38 4
  $g.DrawLine($p, 13, 24, 51, 24)
  $g.DrawLine($p, 26, 24, 26, 51)
  $g.DrawLine($p, 39, 24, 39, 51)
  $g.DrawLine($p, 13, 37, 51, 37)
}

Save-Icon 'playlist' {
  param($g, $p)
  foreach ($y in @(20, 32, 44)) {
    $g.DrawEllipse($p, 17, $y - 1.5, 3, 3)
    $g.DrawLine($p, 27, $y, 47, $y)
  }
}

Save-Icon 'bookmark' {
  param($g, $p)
  Draw-Polyline $g $p ([float[]]@(20, 13, 44, 13, 44, 51, 32, 43, 20, 51, 20, 13))
}

Save-Icon 'teletext' {
  param($g, $p)
  Draw-RoundedRectangle $g $p 13 13 38 38 4
  $g.DrawLine($p, 20, 23, 44, 23)
  $g.DrawLine($p, 20, 32, 29, 32)
  $g.DrawLine($p, 35, 32, 44, 32)
  $g.DrawLine($p, 20, 41, 29, 41)
  $g.DrawLine($p, 35, 41, 44, 41)
}

Save-Icon 'stereoscopic' {
  param($g, $p)
  Draw-Polyline $g $p ([float[]]@(32, 11, 49, 21, 49, 43, 32, 53, 15, 43, 15, 21, 32, 11))
  $g.DrawLine($p, 15, 21, 32, 31)
  $g.DrawLine($p, 49, 21, 32, 31)
  $g.DrawLine($p, 32, 31, 32, 53)
}

Save-Icon 'settings' {
  param($g, $p)
  foreach ($entry in @(@(13, 19, 51, 19, 25), @(13, 32, 51, 32, 41), @(13, 45, 51, 45, 30))) {
    $g.DrawLine($p, $entry[0], $entry[1], $entry[2], $entry[3])
    $g.DrawEllipse($p, $entry[4] - 4, $entry[1] - 4, 8, 8)
  }
}

Save-Icon 'record' {
  param($g, $p)
  $g.DrawEllipse($p, 17, 17, 30, 30)
  $brush = [System.Drawing.SolidBrush]::new($white)
  try { $g.FillEllipse($brush, 25, 25, 14, 14) } finally { $brush.Dispose() }
}

Save-Icon 'progress-nib' {
  param($g, $p)
  $brush = [System.Drawing.SolidBrush]::new($white)
  try { $g.FillEllipse($brush, 24, 24, 16, 16) } finally { $brush.Dispose() }
}
