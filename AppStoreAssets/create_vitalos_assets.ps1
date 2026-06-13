Add-Type -AssemblyName System.Drawing

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScreenshotDir = Join-Path $Root "Screenshots-iPhone-6.5"
$iPadDir = Join-Path $Root "Screenshots-iPad-13"
$ReviewDir = Join-Path $Root "SubscriptionReview"
$PromoDir = Join-Path $Root "PromotionalImages"
$ReferenceDir = Join-Path $Root "References"
$DirectionImagePath = Join-Path $ReferenceDir "premium-app-store-direction.png"
$Pound = [string][char]0x00A3

New-Item -ItemType Directory -Force $ScreenshotDir, $iPadDir, $ReviewDir, $PromoDir, $ReferenceDir | Out-Null

function New-Bitmap($width, $height) {
    $bmp = New-Object System.Drawing.Bitmap $width, $height
    $bmp.SetResolution(144, 144)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    return @{ Bitmap = $bmp; Graphics = $g }
}

function New-Color($rgb, $alpha = 255) {
    return [System.Drawing.Color]::FromArgb($alpha, $rgb[0], $rgb[1], $rgb[2])
}

function New-Brush($rgb, $alpha = 255) {
    return New-Object System.Drawing.SolidBrush((New-Color $rgb $alpha))
}

function New-Pen($rgb, $alpha = 255, $width = 1, $round = $false) {
    $pen = New-Object System.Drawing.Pen((New-Color $rgb $alpha), $width)
    if ($round) {
        $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    }
    return $pen
}

function New-Font($size, $style = "Regular") {
    return New-Object System.Drawing.Font("Segoe UI", $size, [System.Drawing.FontStyle]::$style, [System.Drawing.GraphicsUnit]::Pixel)
}

function New-RoundedPath($rect, $radius) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $radius * 2
    $path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
    $path.AddArc($rect.Right - $d, $rect.Y, $d, $d, 270, 90)
    $path.AddArc($rect.Right - $d, $rect.Bottom - $d, $d, $d, 0, 90)
    $path.AddArc($rect.X, $rect.Bottom - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function Draw-RoundedRect($g, $rect, $radius, $brush, $pen = $null) {
    $path = New-RoundedPath $rect $radius
    if ($brush) { $g.FillPath($brush, $path) }
    if ($pen) { $g.DrawPath($pen, $path) }
    $path.Dispose()
}

function Draw-Shadow($g, $rect, $radius, $alpha = 26) {
    for ($i = 8; $i -ge 1; $i--) {
        $brush = New-Brush @(0, 0, 0) ([int]($alpha / $i))
        $r = [System.Drawing.Rectangle]::new($rect.X + $i, $rect.Y + ($i * 2), $rect.Width, $rect.Height)
        Draw-RoundedRect $g $r ($radius + $i) $brush $null
        $brush.Dispose()
    }
}

function Draw-TextBox($g, $text, $font, $brush, $x, $y, $w, $h, $align = "Near", $lineAlign = "Near") {
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::$align
    $format.LineAlignment = [System.Drawing.StringAlignment]::$lineAlign
    $format.Trimming = [System.Drawing.StringTrimming]::Word
    $format.FormatFlags = 0
    $rect = New-Object System.Drawing.RectangleF($x, $y, $w, $h)
    $g.DrawString(([string]$text), $font, $brush, $rect, $format)
    $format.Dispose()
}

function Draw-RoundedImageCrop($g, $img, $panelIndex, $destRect, $radius, $pen = $null) {
    if (-not $img) {
        $fallback = New-Brush @(245, 248, 252)
        Draw-RoundedRect $g $destRect $radius $fallback $pen
        $fallback.Dispose()
        return
    }

    $panelW = [Math]::Floor($img.Width / 5)
    $sourceX = [int]($panelIndex * $panelW + 10)
    $sourceW = [int]($panelW - 20)
    $sourceY = 24
    $sourceH = $img.Height - 48
    $sourceRatio = $sourceW / $sourceH
    $destRatio = $destRect.Width / $destRect.Height

    if ($sourceRatio -gt $destRatio) {
        $newW = [int]($sourceH * $destRatio)
        $sourceX += [int](($sourceW - $newW) / 2)
        $sourceW = $newW
    } else {
        $newH = [int]($sourceW / $destRatio)
        $sourceY += [int](($sourceH - $newH) / 2)
        $sourceH = $newH
    }

    $path = New-RoundedPath $destRect $radius
    $state = $g.Save()
    $g.SetClip($path)
    $g.DrawImage($img, $destRect, $sourceX, $sourceY, $sourceW, $sourceH, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Restore($state)
    if ($pen) { $g.DrawPath($pen, $path) }
    $path.Dispose()
}

function Draw-GradientOverlay($g, $rect, $topColor, $bottomColor, $radius) {
    $path = New-RoundedPath $rect $radius
    $state = $g.Save()
    $g.SetClip($path)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $topColor, $bottomColor, 90)
    $g.FillRectangle($brush, $rect)
    $brush.Dispose()
    $g.Restore($state)
    $path.Dispose()
}

function Draw-Background($g, $w, $h, $theme) {
    $rect = [System.Drawing.Rectangle]::new(0, 0, $w, $h)
    $bg1 = New-Color $theme.BgTop
    $bg2 = New-Color $theme.BgBottom
    $lg = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $bg1, $bg2, 90)
    $g.FillRectangle($lg, $rect)
    $lg.Dispose()

    $accent = New-Brush $theme.Accent 28
    $accent2 = New-Brush $theme.Accent2 24
    $g.FillEllipse($accent, -220, 360, 620, 620)
    $g.FillEllipse($accent2, ($w - 420), 130, 540, 540)
    if ($theme.Dark) {
        $goldGlow = New-Brush $theme.Accent 18
        $g.FillEllipse($goldGlow, 180, ($h - 360), 840, 280)
        $goldGlow.Dispose()
    } else {
        $white = New-Brush @(255,255,255) 80
        $g.FillEllipse($white, 160, ($h - 440), 920, 420)
        $white.Dispose()
    }
    $accent.Dispose(); $accent2.Dispose()
}

function Draw-BrandHeader($g, $theme, $headline, $subhead) {
    $text = New-Brush $theme.Text
    $muted = New-Brush $theme.Muted
    $accent = New-Brush $theme.Accent
    Draw-TextBox $g "VITALOS AI" (New-Font 30 "Bold") $accent 76 72 500 48
    Draw-TextBox $g $headline (New-Font 82 "Bold") $text 76 130 1090 205
    Draw-TextBox $g $subhead (New-Font 32) $muted 78 348 1030 116
    $text.Dispose(); $muted.Dispose(); $accent.Dispose()
}

function Draw-SafetyFooter($g, $theme, $caption) {
    $muted = New-Brush $theme.Muted 230
    $accent = New-Brush $theme.Accent
    Draw-TextBox $g $caption (New-Font 24) $muted 92 2386 1058 46 "Center"
    Draw-TextBox $g "Wellness guidance only. Not medical advice." (New-Font 22 "Bold") $accent 92 2494 1058 42 "Center"
    $muted.Dispose(); $accent.Dispose()
}

function Draw-MediaStage($g, $img, $theme, $panelIndex) {
    $rect = [System.Drawing.Rectangle]::new(70, 535, 1102, 965)
    Draw-Shadow $g $rect 52 34
    $stroke = New-Pen $theme.Stroke 130 3
    Draw-RoundedImageCrop $g $img $panelIndex $rect 52 $stroke
    $overlayTop = [System.Drawing.Color]::FromArgb(18, 255, 255, 255)
    $overlayBottom = [System.Drawing.Color]::FromArgb(100, $theme.BgBottom[0], $theme.BgBottom[1], $theme.BgBottom[2])
    Draw-GradientOverlay $g $rect $overlayTop $overlayBottom 52
    $stroke.Dispose()
}

function Draw-Ring($g, $cx, $cy, $size, $value, $theme) {
    $muted = New-Pen @(24, 32, 46) 32 18 $true
    $accent = New-Pen $theme.Accent 255 18 $true
    $accent2 = New-Pen $theme.Accent2 255 18 $true
    $rect = [System.Drawing.Rectangle]::new($cx - $size / 2, $cy - $size / 2, $size, $size)
    $g.DrawArc($muted, $rect, -90, 360)
    $g.DrawArc($accent, $rect, -90, [int](280 * $value / 100))
    $g.DrawArc($accent2, $rect, 210, [int](120 * $value / 100))
    $white = New-Brush @(255,255,255)
    $soft = New-Brush @(177,187,203)
    Draw-TextBox $g $value (New-Font 48 "Bold") $white ($cx - 70) ($cy - 46) 140 58 "Center"
    Draw-TextBox $g "Vital Score" (New-Font 16 "Bold") $soft ($cx - 80) ($cy + 12) 160 28 "Center"
    $muted.Dispose(); $accent.Dispose(); $accent2.Dispose(); $white.Dispose(); $soft.Dispose()
}

function Draw-PhoneShell($g, $x, $y, $w, $h, $theme) {
    $outer = [System.Drawing.Rectangle]::new($x, $y, $w, $h)
    Draw-Shadow $g $outer 62 40
    $black = New-Brush @(4, 6, 12)
    $edge = New-Pen @(255,255,255) 62 3
    Draw-RoundedRect $g $outer 62 $black $edge
    $screen = [System.Drawing.Rectangle]::new($x + 24, $y + 24, $w - 48, $h - 48)
    $screenBrush = New-Brush @(9, 14, 26)
    Draw-RoundedRect $g $screen 46 $screenBrush $null
    Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($x + [int](($w - 132) / 2), $y + 24, 132, 26)) 13 (New-Brush @(0,0,0)) $null
    $black.Dispose(); $edge.Dispose(); $screenBrush.Dispose()
}

function Draw-PhoneTop($g, $x, $y, $w, $title, $theme) {
    $white = New-Brush @(255,255,255)
    $soft = New-Brush @(174,185,202)
    $accent = New-Brush $theme.Accent
    Draw-TextBox $g "VitalOS AI" (New-Font 20 "Bold") $soft ($x + 48) ($y + 70) ($w - 96) 34
    Draw-TextBox $g $title (New-Font 34 "Bold") $white ($x + 48) ($y + 106) ($w - 96) 48
    Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($x + $w - 92, $y + 82, 42, 42)) 21 $accent $null
    $white.Dispose(); $soft.Dispose(); $accent.Dispose()
}

function Draw-ListCard($g, $x, $y, $w, $title, $body, $theme) {
    $card = New-Brush @(255,255,255) 18
    $white = New-Brush @(255,255,255)
    $soft = New-Brush @(174,185,202)
    Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($x, $y, $w, 92)) 24 $card $null
    Draw-TextBox $g $title (New-Font 18 "Bold") $white ($x + 22) ($y + 16) ($w - 44) 28
    Draw-TextBox $g $body (New-Font 14) $soft ($x + 22) ($y + 45) ($w - 44) 36
    $card.Dispose(); $white.Dispose(); $soft.Dispose()
}

function Draw-MiniLineChart($g, $x, $y, $w, $h, $theme) {
    $axis = New-Pen @(255,255,255) 35 2 $true
    $line = New-Pen $theme.Accent 255 6 $true
    $grid = New-Pen @(255,255,255) 18 1 $true
    for ($i = 1; $i -le 3; $i++) {
        $gy = $y + [int]($h * $i / 4)
        $g.DrawLine($grid, $x, $gy, $x + $w, $gy)
    }
    $points = @(
        [System.Drawing.Point]::new([int]$x, [int]($y + ($h * .70))),
        [System.Drawing.Point]::new([int]($x + ($w * .18)), [int]($y + ($h * .42))),
        [System.Drawing.Point]::new([int]($x + ($w * .36)), [int]($y + ($h * .56))),
        [System.Drawing.Point]::new([int]($x + ($w * .57)), [int]($y + ($h * .30))),
        [System.Drawing.Point]::new([int]($x + ($w * .78)), [int]($y + ($h * .38))),
        [System.Drawing.Point]::new([int]($x + $w), [int]($y + ($h * .22)))
    )
    for ($i = 0; $i -lt $points.Count - 1; $i++) {
        $g.DrawLine($line, $points[$i], $points[$i+1])
    }
    $axis.Dispose(); $line.Dispose(); $grid.Dispose()
}

function Draw-Waveform($g, $x, $y, $w, $h, $theme) {
    $line = New-Pen $theme.Accent2 255 8 $true
    for ($i = 0; $i -lt 12; $i++) {
        $bar = 28 + (($i * 37) % 112)
        $px = $x + [int]($i * ($w / 12))
        $g.DrawLine($line, $px, $y + $h / 2 - $bar / 2, $px, $y + $h / 2 + $bar / 2)
    }
    $line.Dispose()
}

function Draw-PhoneContent($g, $x, $y, $w, $h, $variant, $theme) {
    Draw-PhoneShell $g $x $y $w $h $theme
    switch ($variant) {
        "dashboard" {
            Draw-PhoneTop $g $x $y $w "Today" $theme
            Draw-Ring $g ($x + $w / 2) ($y + 330) 210 82 $theme
            Draw-ListCard $g ($x + 58) ($y + 500) ($w - 116) "Recovery" "Light strength and longer cooldown." $theme
            Draw-ListCard $g ($x + 58) ($y + 612) ($w - 116) "Sleep" "Wind down 38 minutes earlier." $theme
            Draw-ListCard $g ($x + 58) ($y + 724) ($w - 116) "Energy" "Best focus window: 10:30 AM." $theme
            Draw-MiniLineChart $g ($x + 70) ($y + 864) ($w - 140) 132 $theme
        }
        "protocol" {
            Draw-PhoneTop $g $x $y $w "Protocol" $theme
            $accent = New-Brush $theme.Accent
            $soft = New-Brush @(174,185,202)
            Draw-TextBox $g "Adaptive day plan" (New-Font 22 "Bold") (New-Brush @(255,255,255)) ($x + 58) ($y + 194) ($w - 116) 40
            $items = @(
                @("Morning", "Hydrate, 12 min mobility, daylight."),
                @("Midday", "Focus block, protein, easy walk."),
                @("Evening", "Blue-light cutoff and sleep prep.")
            )
            $cy = $y + 270
            foreach ($item in $items) {
                Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($x + 58, $cy, $w - 116, 118)) 28 (New-Brush @(255,255,255) 19) $null
                Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($x + 84, $cy + 30, 38, 38)) 19 $accent $null
                Draw-TextBox $g $item[0] (New-Font 20 "Bold") (New-Brush @(255,255,255)) ($x + 142) ($cy + 24) ($w - 210) 30
                Draw-TextBox $g $item[1] (New-Font 15) $soft ($x + 142) ($cy + 58) ($w - 210) 42
                $cy += 144
            }
            Draw-MiniLineChart $g ($x + 70) ($y + 760) ($w - 140) 170 $theme
            $accent.Dispose(); $soft.Dispose()
        }
        "voice" {
            Draw-PhoneTop $g $x $y $w "Voice Coach" $theme
            Draw-Waveform $g ($x + 78) ($y + 215) ($w - 156) 210 $theme
            Draw-ListCard $g ($x + 58) ($y + 490) ($w - 116) "You said" "I slept badly and feel drained." $theme
            Draw-ListCard $g ($x + 58) ($y + 612) ($w - 116) "AI response" "Make today a lighter recovery day." $theme
            Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($x + 118, $y + 786, $w - 236, 78)) 39 (New-Brush $theme.Accent) $null
            Draw-TextBox $g "Hold to talk" (New-Font 21 "Bold") (New-Brush @(255,255,255)) ($x + 118) ($y + 807) ($w - 236) 34 "Center"
        }
        "analytics" {
            Draw-PhoneTop $g $x $y $w "Insights" $theme
            Draw-MiniLineChart $g ($x + 64) ($y + 218) ($w - 128) 260 $theme
            Draw-Ring $g ($x + 155) ($y + 615) 132 79 $theme
            Draw-ListCard $g ($x + 250) ($y + 548) ($w - 308) "Sleep timing" "Highest leverage signal this week." $theme
            Draw-ListCard $g ($x + 58) ($y + 734) ($w - 116) "Projection" "Consistent wind-down may lift score." $theme
            Draw-ListCard $g ($x + 58) ($y + 846) ($w - 116) "Share" "Create a milestone card." $theme
        }
        default {
            Draw-PhoneTop $g $x $y $w "Premium" $theme
            $gold = New-Brush $theme.Accent
            Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($x + 78, $y + 192, $w - 156, 92)) 28 $gold $null
            Draw-TextBox $g "Vital Premium" (New-Font 26 "Bold") (New-Brush @(10,10,12)) ($x + 78) ($y + 214) ($w - 156) 38 "Center"
            Draw-ListCard $g ($x + 58) ($y + 342) ($w - 116) "Adaptive protocols" "Plans update around your signals." $theme
            Draw-ListCard $g ($x + 58) ($y + 456) ($w - 116) "Voice coaching" "Supportive wellness reflection." $theme
            Draw-ListCard $g ($x + 58) ($y + 570) ($w - 116) "Advanced analytics" "Patterns, projections and trends." $theme
            Draw-ListCard $g ($x + 58) ($y + 684) ($w - 116) "Elite models" "Deeper personalization." $theme
            Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($x + 86, $y + 860, $w - 172, 74)) 28 (New-Brush @(255,255,255) 22) $null
            Draw-TextBox $g "Educational wellness insights only" (New-Font 15 "Bold") (New-Brush @(190,198,210)) ($x + 94) ($y + 884) ($w - 188) 28 "Center"
            $gold.Dispose()
        }
    }
}

function Draw-iPadShell($g, $x, $y, $w, $h, $theme) {
    $outer = [System.Drawing.Rectangle]::new($x, $y, $w, $h)
    Draw-Shadow $g $outer 58 36
    Draw-RoundedRect $g $outer 58 (New-Brush @(4, 6, 12)) (New-Pen @(255,255,255) 58 3)
    $screen = [System.Drawing.Rectangle]::new($x + 28, $y + 28, $w - 56, $h - 56)
    Draw-RoundedRect $g $screen 38 (New-Brush @(9, 14, 26)) $null
    Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($x + [int]($w / 2) - 36, $y + 16, 72, 10)) 5 (New-Brush @(255,255,255) 32) $null
}

function Draw-iPadNav($g, $x, $y, $w, $h, $theme, $selected) {
    Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($x, $y, $w, $h)) 28 (New-Brush @(255,255,255) 12) $null
    Draw-TextBox $g "VitalOS AI" (New-Font 28 "Bold") (New-Brush @(255,255,255)) ($x + 34) ($y + 38) ($w - 68) 40
    Draw-TextBox $g "Adaptive wellness" (New-Font 16 "Bold") (New-Brush @(160,172,190)) ($x + 34) ($y + 82) ($w - 68) 28

    $items = @("Today", "Protocol", "Coach", "Insights", "Premium")
    $cy = $y + 160
    foreach ($item in $items) {
        $isSelected = $item -eq $selected
        $rowBrush = if ($isSelected) { New-Brush $theme.Accent 230 } else { New-Brush @(255,255,255) 0 }
        $textBrush = if ($isSelected) { New-Brush @(255,255,255) } else { New-Brush @(176,187,203) }
        $dotBrush = if ($isSelected) { New-Brush @(255,255,255) 230 } else { New-Brush $theme.Accent 180 }
        Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($x + 24, $cy, $w - 48, 64)) 22 $rowBrush $null
        Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($x + 48, $cy + 21, 22, 22)) 11 $dotBrush $null
        Draw-TextBox $g $item (New-Font 20 "Bold") $textBrush ($x + 86) ($cy + 18) ($w - 118) 30
        $rowBrush.Dispose(); $textBrush.Dispose(); $dotBrush.Dispose()
        $cy += 80
    }

    Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($x + 28, $y + $h - 150, $w - 56, 104)) 26 (New-Brush @(255,255,255) 16) $null
    Draw-TextBox $g "Educational insights" (New-Font 18 "Bold") (New-Brush @(255,255,255)) ($x + 52) ($y + $h - 128) ($w - 104) 28
    Draw-TextBox $g "Not medical advice." (New-Font 15) (New-Brush @(166,178,194)) ($x + 52) ($y + $h - 92) ($w - 104) 28
}

function Draw-iPadMetric($g, $x, $y, $w, $h, $label, $value, $body, $theme) {
    Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($x, $y, $w, $h)) 30 (New-Brush @(255,255,255) 16) $null
    Draw-TextBox $g $label (New-Font 18 "Bold") (New-Brush @(174,185,202)) ($x + 28) ($y + 24) ($w - 56) 30
    Draw-TextBox $g $value (New-Font 48 "Bold") (New-Brush @(255,255,255)) ($x + 28) ($y + 58) ($w - 56) 64
    Draw-TextBox $g $body (New-Font 17) (New-Brush @(166,178,194)) ($x + 28) ($y + 126) ($w - 56) 44
}

function Draw-iPadScheduleRow($g, $x, $y, $w, $time, $title, $detail, $theme) {
    Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($x, $y, $w, 92)) 24 (New-Brush @(255,255,255) 14) $null
    Draw-TextBox $g $time (New-Font 18 "Bold") (New-Brush $theme.Accent) ($x + 24) ($y + 22) 120 30
    Draw-TextBox $g $title (New-Font 21 "Bold") (New-Brush @(255,255,255)) ($x + 160) ($y + 18) ($w - 190) 32
    Draw-TextBox $g $detail (New-Font 16) (New-Brush @(166,178,194)) ($x + 160) ($y + 50) ($w - 190) 28
}

function Draw-iPadContent($g, $x, $y, $w, $h, $variant, $theme) {
    Draw-iPadShell $g $x $y $w $h $theme
    $sx = $x + 54
    $sy = $y + 54
    $sw = $w - 108
    $sh = $h - 108
    $navW = 330
    $mainX = $sx + $navW + 34
    $mainW = $sw - $navW - 34
    $selected = switch ($variant) {
        "protocol" { "Protocol" }
        "voice" { "Coach" }
        "analytics" { "Insights" }
        "paywall" { "Premium" }
        default { "Today" }
    }
    Draw-iPadNav $g $sx $sy $navW $sh $theme $selected

    switch ($variant) {
        "protocol" {
            Draw-TextBox $g "Daily Protocol" (New-Font 48 "Bold") (New-Brush @(255,255,255)) $mainX ($sy + 18) $mainW 68
            Draw-TextBox $g "A plan that adapts as your signals change." (New-Font 22) (New-Brush @(166,178,194)) $mainX ($sy + 86) $mainW 40
            Draw-iPadScheduleRow $g $mainX ($sy + 170) $mainW "07:30" "Morning calibration" "Hydration, daylight, mobility and readiness check." $theme
            Draw-iPadScheduleRow $g $mainX ($sy + 286) $mainW "12:15" "Focus support" "Work block, protein target and low-friction movement." $theme
            Draw-iPadScheduleRow $g $mainX ($sy + 402) $mainW "20:45" "Wind-down protocol" "Lower stimulation and protect tonight's sleep window." $theme
            Draw-MiniLineChart $g $mainX ($sy + 570) $mainW 230 $theme
            Draw-iPadMetric $g $mainX ($sy + 860) ([int](($mainW - 28) / 2)) 190 "Adaptation" "3 shifts" "Updated from today's check-in." $theme
            Draw-iPadMetric $g ($mainX + [int](($mainW + 28) / 2)) ($sy + 860) ([int](($mainW - 28) / 2)) 190 "Recovery load" "Light" "A gentler training day." $theme
        }
        "voice" {
            Draw-TextBox $g "Voice Coach" (New-Font 48 "Bold") (New-Brush @(255,255,255)) $mainX ($sy + 18) $mainW 68
            Draw-Waveform $g ($mainX + 40) ($sy + 150) ($mainW - 80) 260 $theme
            Draw-iPadScheduleRow $g $mainX ($sy + 470) $mainW "You" "I slept badly and feel drained." "Captured from voice input." $theme
            Draw-iPadScheduleRow $g $mainX ($sy + 590) $mainW "AI" "Make today a lighter recovery day." "Supportive educational wellness suggestion." $theme
            Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($mainX + 180, $sy + 770, $mainW - 360, 92)) 42 (New-Brush $theme.Accent) $null
            Draw-TextBox $g "Hold to talk" (New-Font 28 "Bold") (New-Brush @(255,255,255)) ($mainX + 180) ($sy + 796) ($mainW - 360) 40 "Center"
        }
        "analytics" {
            Draw-TextBox $g "Insights" (New-Font 48 "Bold") (New-Brush @(255,255,255)) $mainX ($sy + 18) $mainW 68
            Draw-TextBox $g "Patterns across sleep, recovery, stress and habits." (New-Font 22) (New-Brush @(166,178,194)) $mainX ($sy + 86) $mainW 40
            Draw-MiniLineChart $g $mainX ($sy + 160) $mainW 320 $theme
            Draw-iPadMetric $g $mainX ($sy + 545) ([int](($mainW - 56) / 3)) 210 "Vital Score" "79" "Stable weekly trend." $theme
            Draw-iPadMetric $g ($mainX + [int](($mainW - 56) / 3) + 28) ($sy + 545) ([int](($mainW - 56) / 3)) 210 "Sleep timing" "+18%" "Highest leverage signal." $theme
            Draw-iPadMetric $g ($mainX + 2 * ([int](($mainW - 56) / 3) + 28)) ($sy + 545) ([int](($mainW - 56) / 3)) 210 "Consistency" "6/7" "Habit streak this week." $theme
            Draw-iPadScheduleRow $g $mainX ($sy + 820) $mainW "Projection" "Earlier wind-down may lift readiness." "Estimates are educational, not clinical." $theme
        }
        "paywall" {
            Draw-TextBox $g "Premium" (New-Font 48 "Bold") (New-Brush @(255,255,255)) $mainX ($sy + 18) $mainW 68
            Draw-RoundedRect $g ([System.Drawing.Rectangle]::new($mainX, $sy + 118, $mainW, 118)) 36 (New-Brush $theme.Accent) $null
            Draw-TextBox $g "Vital Premium" (New-Font 38 "Bold") (New-Brush @(10,10,12)) $mainX ($sy + 152) $mainW 52 "Center"
            Draw-iPadMetric $g $mainX ($sy + 300) ([int](($mainW - 28) / 2)) 190 "Protocols" "Adaptive" "Daily plans from check-ins." $theme
            Draw-iPadMetric $g ($mainX + [int](($mainW + 28) / 2)) ($sy + 300) ([int](($mainW - 28) / 2)) 190 "Coaching" "Voice" "Reflective AI support." $theme
            Draw-iPadMetric $g $mainX ($sy + 522) ([int](($mainW - 28) / 2)) 190 "Analytics" "Deep" "Trends and projections." $theme
            Draw-iPadMetric $g ($mainX + [int](($mainW + 28) / 2)) ($sy + 522) ([int](($mainW - 28) / 2)) 190 "Elite" "Models" "Higher personalization." $theme
            Draw-TextBox $g "Educational wellness insights only" (New-Font 20 "Bold") (New-Brush @(174,185,202)) $mainX ($sy + 810) $mainW 38 "Center"
        }
        default {
            Draw-TextBox $g "Today" (New-Font 48 "Bold") (New-Brush @(255,255,255)) $mainX ($sy + 18) $mainW 68
            Draw-TextBox $g "Recovery, sleep, stress and energy in one view." (New-Font 22) (New-Brush @(166,178,194)) $mainX ($sy + 86) $mainW 40
            Draw-Ring $g ($mainX + 190) ($sy + 280) 270 82 $theme
            Draw-iPadMetric $g ($mainX + 410) ($sy + 160) ([int]($mainW - 410)) 170 "Recovery" "Light day" "Strength downshift and longer cooldown." $theme
            Draw-iPadMetric $g ($mainX + 410) ($sy + 358) ([int]($mainW - 410)) 170 "Sleep" "38 min" "Earlier wind-down recommended." $theme
            Draw-MiniLineChart $g $mainX ($sy + 620) $mainW 270 $theme
            Draw-iPadScheduleRow $g $mainX ($sy + 950) $mainW "10:30" "Best focus window" "Schedule deep work before energy drops." $theme
        }
    }
}

function Draw-FeatureBadges($g, $theme, $badges) {
    $x = 84
    $y = 1570
    foreach ($badge in $badges) {
        $w = $badge[1]
        $rect = [System.Drawing.Rectangle]::new($x, $y, $w, 66)
        Draw-RoundedRect $g $rect 28 (New-Brush @(255,255,255) 215) (New-Pen $theme.Stroke 80 2)
        Draw-TextBox $g $badge[0] (New-Font 19 "Bold") (New-Brush $theme.Text) ($x + 18) ($y + 18) ($w - 36) 28 "Center"
        $x += $w + 18
    }
}

function Draw-MarketingScreenshot($fileName, $theme, $headline, $subhead, $phoneVariant, $caption, $panelIndex, $badges) {
    $w = 1242; $h = 2688
    $ctx = New-Bitmap $w $h
    $bmp = $ctx.Bitmap; $g = $ctx.Graphics
    $img = $null
    if (Test-Path $DirectionImagePath) { $img = [System.Drawing.Image]::FromFile($DirectionImagePath) }

    Draw-Background $g $w $h $theme
    Draw-BrandHeader $g $theme $headline $subhead
    Draw-MediaStage $g $img $theme $panelIndex
    Draw-PhoneContent $g 326 1018 590 1280 $phoneVariant $theme
    Draw-SafetyFooter $g $theme $caption

    $path = Join-Path $ScreenshotDir $fileName
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    if ($img) { $img.Dispose() }
    $g.Dispose(); $bmp.Dispose()
}

function Draw-iPadMarketingScreenshot($fileName, $theme, $headline, $subhead, $variant, $caption, $panelIndex) {
    $w = 2064; $h = 2752
    $ctx = New-Bitmap $w $h
    $bmp = $ctx.Bitmap; $g = $ctx.Graphics
    $img = $null
    if (Test-Path $DirectionImagePath) { $img = [System.Drawing.Image]::FromFile($DirectionImagePath) }

    Draw-Background $g $w $h $theme
    Draw-TextBox $g "VITALOS AI" (New-Font 38 "Bold") (New-Brush $theme.Accent) 128 94 620 56
    Draw-TextBox $g $headline (New-Font 104 "Bold") (New-Brush $theme.Text) 128 168 1810 132
    Draw-TextBox $g $subhead (New-Font 38) (New-Brush $theme.Muted) 132 330 1700 98

    $stage = [System.Drawing.Rectangle]::new(126, 498, 1812, 870)
    Draw-Shadow $g $stage 64 30
    Draw-RoundedImageCrop $g $img $panelIndex $stage 64 (New-Pen $theme.Stroke 120 3)
    Draw-GradientOverlay $g $stage ([System.Drawing.Color]::FromArgb(8, 255,255,255)) ([System.Drawing.Color]::FromArgb(94, $theme.BgBottom[0], $theme.BgBottom[1], $theme.BgBottom[2])) 64

    Draw-iPadContent $g 260 812 1544 1470 $variant $theme

    Draw-TextBox $g $caption (New-Font 30) (New-Brush $theme.Muted 230) 180 2390 1704 52 "Center"
    Draw-TextBox $g "Wellness guidance only. Not medical advice." (New-Font 28 "Bold") (New-Brush $theme.Accent) 180 2504 1704 48 "Center"

    $path = Join-Path $iPadDir $fileName
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    if ($img) { $img.Dispose() }
    $g.Dispose(); $bmp.Dispose()
}

function Draw-ReviewScreenshot($fileName, $theme, $plan, $price, $features) {
    $w = 1242; $h = 2688
    $ctx = New-Bitmap $w $h
    $bmp = $ctx.Bitmap; $g = $ctx.Graphics
    $img = $null
    if (Test-Path $DirectionImagePath) { $img = [System.Drawing.Image]::FromFile($DirectionImagePath) }

    Draw-Background $g $w $h $theme
    Draw-BrandHeader $g $theme $plan $price
    Draw-TextBox $g "Subscription review screenshot showing the in-app paywall state and unlocked digital wellness features." (New-Font 28) (New-Brush $theme.Muted) 78 430 1070 86
    Draw-MediaStage $g $img $theme 4
    Draw-PhoneContent $g 326 980 590 1280 "paywall" $theme

    $note = [System.Drawing.Rectangle]::new(78, 2240, 1086, 280)
    Draw-Shadow $g $note 36 20
    Draw-RoundedRect $g $note 36 (New-Brush @(255,255,255) 225) (New-Pen $theme.Stroke 70 2)
    Draw-TextBox $g "Reviewer note" (New-Font 30 "Bold") (New-Brush @(9, 14, 24)) 116 2278 980 44
    Draw-TextBox $g "This purchase unlocks digital wellness features in the app: protocols, AI coaching, analytics, projections, and personalization. It does not unlock medical advice, diagnosis, treatment, or emergency support." (New-Font 25) (New-Brush @(66, 74, 88)) 116 2335 990 112
    Draw-TextBox $g "Configured product IDs are documented with StoreKit scaffolding and App Store Connect." (New-Font 21 "Bold") (New-Brush $theme.Accent) 116 2478 990 38

    $path = Join-Path $ReviewDir $fileName
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    if ($img) { $img.Dispose() }
    $g.Dispose(); $bmp.Dispose()
}

function Draw-PromoImage($fileName, $theme, $plan, $price, $features, $panelIndex) {
    $w = 1024; $h = 1024
    $ctx = New-Bitmap $w $h
    $bmp = $ctx.Bitmap; $g = $ctx.Graphics

    Draw-Background $g $w $h $theme
    $card = [System.Drawing.Rectangle]::new(70, 70, 884, 884)
    $panel = if ($theme.Dark) { New-Brush @(22, 24, 30) 242 } else { New-Brush @(255,255,255) 238 }
    $text = New-Brush $theme.Text
    $muted = New-Brush $theme.Muted
    $accent = New-Brush $theme.Accent
    $accent2 = New-Brush $theme.Accent2
    $white = New-Brush @(255,255,255)
    $stroke = New-Pen $theme.Stroke 160 4

    Draw-Shadow $g $card 48 34
    Draw-RoundedRect $g $card 48 $panel $stroke
    Draw-TextBox $g "VITALOS AI" (New-Font 31 "Bold") $accent 118 122 740 48
    Draw-TextBox $g $plan (New-Font 78 "Bold") $text 118 198 790 104
    Draw-TextBox $g $price (New-Font 58 "Bold") $accent2 118 334 790 78

    $chipY = 480
    foreach ($feature in $features) {
        $chipRect = [System.Drawing.Rectangle]::new(118, $chipY, 790, 78)
        Draw-RoundedRect $g $chipRect 30 (New-Brush $theme.Accent 30) (New-Pen $theme.Accent 155 3)
        Draw-TextBox $g $feature (New-Font 30 "Bold") $text 152 ($chipY + 20) 722 40
        $chipY += 104
    }

    Draw-RoundedRect $g ([System.Drawing.Rectangle]::new(118, 800, 790, 92)) 36 $accent $null
    Draw-TextBox $g "Unlock in VitalOS AI" (New-Font 34 "Bold") $white 148 827 730 46 "Center"

    $path = Join-Path $PromoDir $fileName
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $panel.Dispose(); $text.Dispose(); $muted.Dispose(); $accent.Dispose(); $accent2.Dispose(); $white.Dispose(); $stroke.Dispose()
    $g.Dispose(); $bmp.Dispose()
}

$Dashboard = @{
    BgTop=@(248,252,250); BgBottom=@(223,247,239); Text=@(8,18,32); Muted=@(79,92,108); Accent=@(0,188,136); Accent2=@(19,132,255); Stroke=@(188,221,211)
}
$Protocol = @{
    BgTop=@(250,252,255); BgBottom=@(226,239,255); Text=@(8,18,32); Muted=@(77,91,110); Accent=@(20,116,255); Accent2=@(0,200,150); Stroke=@(191,211,242)
}
$Voice = @{
    BgTop=@(255,250,248); BgBottom=@(255,226,218); Text=@(25,22,27); Muted=@(103,81,89); Accent=@(245,104,96); Accent2=@(20,116,255); Stroke=@(238,196,187)
}
$Analytics = @{
    BgTop=@(248,253,252); BgBottom=@(223,246,238); Text=@(7,22,27); Muted=@(73,94,99); Accent=@(0,178,126); Accent2=@(108,103,255); Stroke=@(187,222,212)
}
$Premium = @{
    BgTop=@(19,18,17); BgBottom=@(5,6,8); Text=@(255,255,255); Muted=@(213,206,191); Accent=@(220,161,65); Accent2=@(255,211,117); Stroke=@(135,101,45)
    Dark=$true
}

Draw-MarketingScreenshot "01-dashboard.png" $Dashboard "Your daily health OS" "Recovery, sleep, stress and energy in one premium adaptive dashboard." "dashboard" "Built for smarter daily wellness decisions." 0 @(
    @("Readiness", 170), @("Sleep", 126), @("Recovery", 162)
)

Draw-MarketingScreenshot "02-protocol.png" $Protocol "A plan that adapts" "VitalOS turns check-ins and wellness signals into a daily protocol." "protocol" "Your body changes every day. Your plan should too." 1 @(
    @("Morning", 150), @("Focus", 124), @("Wind-down", 174)
)

Draw-MarketingScreenshot "03-voice-coach.png" $Voice "Talk to your AI coach" "Use voice input for supportive reflections and educational wellness suggestions." "voice" "Humanized coaching without medical claims." 2 @(
    @("Voice", 124), @("Reflection", 174), @("Gentle day", 176)
)

Draw-MarketingScreenshot "04-analytics.png" $Analytics "See patterns clearly" "Premium analytics for Vital Score, sleep, recovery, stress and habits." "analytics" "Data visualizations designed for clarity." 3 @(
    @("Trends", 130), @("Projection", 168), @("Share", 126)
)

Draw-MarketingScreenshot "05-paywall.png" $Premium "Unlock Premium AI" "Premium and Elite add protocols, voice coaching, projections and deep analytics." "paywall" "Premium wellness technology, built responsibly." 4 @(
    @("Premium", 154), @("Elite", 106), @("Advanced", 164)
)

Draw-iPadMarketingScreenshot "01-dashboard-ipad.png" $Dashboard "Your daily health OS" "Recovery, sleep, stress and energy in one premium iPad dashboard." "dashboard" "Built for smarter daily wellness decisions on iPad." 0
Draw-iPadMarketingScreenshot "02-protocol-ipad.png" $Protocol "A plan that adapts" "Plan your day from check-ins, wellness signals and recovery context." "protocol" "Your body changes every day. Your plan should too." 1
Draw-iPadMarketingScreenshot "03-voice-coach-ipad.png" $Voice "Talk to your AI coach" "A larger coaching surface for reflection, transcripts and gentle guidance." "voice" "Humanized coaching without medical claims." 2
Draw-iPadMarketingScreenshot "04-analytics-ipad.png" $Analytics "See patterns clearly" "Explore Vital Score, sleep, recovery and habit trends on a wider canvas." "analytics" "Data visualizations designed for clarity on iPad." 3
Draw-iPadMarketingScreenshot "05-paywall-ipad.png" $Premium "Unlock Premium AI" "Premium and Elite features presented in a focused iPad paywall." "paywall" "Premium wellness technology, built responsibly." 4

Draw-ReviewScreenshot "vital-premium-monthly-review.png" $Premium "Vital Premium Monthly" ($Pound + "12.99 / month") @("adaptive protocols", "AI coach", "voice coaching", "advanced analytics")
Draw-ReviewScreenshot "vital-premium-yearly-review.png" $Premium "Vital Premium Yearly" ($Pound + "99.99 / year") @("annual premium access", "adaptive protocols", "AI coach", "advanced analytics")
Draw-ReviewScreenshot "vital-elite-monthly-review.png" $Premium "Vital Elite Monthly" ($Pound + "24.99 / month") @("premium AI models", "deep analytics", "advanced personalization", "premium themes")

Draw-PromoImage "vital-premium-monthly-promo.png" $Dashboard "Vital Premium" ($Pound + "12.99 / month") @("Adaptive daily protocols", "AI wellness coaching", "Voice guidance and analytics") 0
Draw-PromoImage "vital-premium-yearly-promo.png" $Protocol "Premium Yearly" ($Pound + "99.99 / year") @("Annual premium access", "Protocols and coaching", "Analytics all year") 1
Draw-PromoImage "vital-elite-monthly-promo.png" $Premium "Vital Elite" ($Pound + "24.99 / month") @("Advanced personalization", "Deeper premium insights", "Elevated app themes") 4

Write-Host "Created premium VitalOS AI App Store assets in $Root"
