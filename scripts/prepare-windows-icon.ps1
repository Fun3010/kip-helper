# Run with Windows PowerShell 5.1 -STA. Render the existing Android vector;
# this script does not introduce separate Windows artwork or coefficients.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationCore, WindowsBase
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$vectorPath = Join-Path $projectRoot 'android/app/src/main/res/mipmap-anydpi/ic_kip.xml'
[xml]$vector = Get-Content -LiteralPath $vectorPath -Raw
$androidNamespace = 'http://schemas.android.com/apk/res/android'
$images = foreach ($size in @(16, 24, 32, 48, 64, 128, 256)) {
    $visual = New-Object System.Windows.Media.DrawingVisual
    $drawing = $visual.RenderOpen()
    $drawing.PushTransform((New-Object System.Windows.Media.ScaleTransform ($size / 108.0), ($size / 108.0)))
    foreach ($path in $vector.vector.path) {
        $geometry = [System.Windows.Media.Geometry]::Parse($path.GetAttribute('pathData', $androidNamespace))
        $fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString($path.GetAttribute('fillColor', $androidNamespace))
        $pen = $null
        if ($path.HasAttribute('strokeColor', $androidNamespace)) {
            $brush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($path.GetAttribute('strokeColor', $androidNamespace))
            $pen = [System.Windows.Media.Pen]::new($brush, [double]$path.GetAttribute('strokeWidth', $androidNamespace))
            $pen.StartLineCap = $pen.EndLineCap = [System.Windows.Media.PenLineCap]::Round
        }
        $drawing.DrawGeometry($fill, $pen, $geometry)
    }
    $drawing.Close()
    $bitmap = [System.Windows.Media.Imaging.RenderTargetBitmap]::new($size, $size, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
    $bitmap.Render($visual)
    $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
    $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
    $stream = [System.IO.MemoryStream]::new()
    $encoder.Save($stream)
    [pscustomobject]@{ Size = $size; Bytes = $stream.ToArray() }
    $stream.Dispose()
}
$target = Join-Path $projectRoot 'windows/runner/resources/app_icon.ico'
$writer = [System.IO.BinaryWriter]::new([System.IO.File]::Create($target))
try {
    $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$images.Count)
    $offset = 6 + 16 * $images.Count
    foreach ($image in $images) {
        $dimension = [byte]($image.Size % 256)
        $writer.Write($dimension); $writer.Write($dimension)
        $writer.Write([byte]0); $writer.Write([byte]0)
        $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$image.Bytes.Length); $writer.Write([uint32]$offset)
        $offset += $image.Bytes.Length
    }
    foreach ($image in $images) { $writer.Write([byte[]]$image.Bytes) }
} finally { $writer.Dispose() }
$previewDirectory = Join-Path $projectRoot 'build/qa'
[System.IO.Directory]::CreateDirectory($previewDirectory) | Out-Null
[System.IO.File]::WriteAllBytes((Join-Path $previewDirectory 'windows-icon.png'), [byte[]]$images[-1].Bytes)
Write-Output 'Windows icon generated from the existing Android vector (7 sizes).'
