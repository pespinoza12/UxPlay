# Convierte las grabaciones crudas de UxPlay (C:\Users\pedro\Videos\iPhone\crudo)
# en MP4 editables en C:\Users\pedro\Videos\iPhone, uno por conexión del iPhone.
#
# UxPlay corta un tramo nuevo cada vez que la imagen cambia de tamaño (giro del
# iPhone, video que entra o sale de pantalla completa). Aquí los tramos seguidos
# se vuelven a unir en un solo archivo:
#   - lienzo Full HD 16:9 (1920x1080): lo vertical va al centro con barras, lo
#     horizontal ocupa el ancho; nada se achica
#   - 30 fps constantes (el iPhone manda cuadros variables) en H.264 por NVENC
#   - audio AAC-LC 48 kHz (los editores no leen el AAC-ELD del iPhone); los
#     huecos sin sonido se rellenan con silencio real
# Los crudos procesados se mueven a crudo\convertidos (no se borran).

$ErrorActionPreference = "Continue"   # ffmpeg escribe en stderr: en PS 5.1 con Stop eso aborta
$env:PATH = "C:\msys64\ucrt64\bin;" + $env:PATH
$crudo = "C:\Users\pedro\Videos\iPhone\crudo"
$salida = "C:\Users\pedro\Videos\iPhone"
$hechos = Join-Path $crudo "convertidos"
$tmp = Join-Path $crudo "tmp"
$log = Join-Path $salida "conversion.log"
New-Item -ItemType Directory -Force $hechos, $tmp | Out-Null

function Log($m) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m" | Out-File $log -Append -Encoding utf8 }
function Probe($f, $sel, $entry) { (& ffprobe -v error @sel -show_entries $entry -of csv=p=0 $f 2>$null | Select-Object -First 1) }

# tramos en orden de creación; uno nuevo pertenece a la misma conexión si nació
# a menos de 3 s de que se cerrara el anterior
$archivos = Get-ChildItem $crudo -Filter *.mp4 -File | Sort-Object CreationTime
if (-not $archivos) { Log "nada para convertir"; exit 0 }
$grupos = @(); $actual = @(); $fin = $null
foreach ($f in $archivos) {
    if ($actual.Count -and ($f.CreationTime - $fin).TotalSeconds -gt 3) { $grupos += ,$actual; $actual = @() }
    $actual += $f; $fin = $f.LastWriteTime
}
if ($actual.Count) { $grupos += ,$actual }

$vf = "fps=30,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,format=yuv420p"
$enc = @("-c:v", "h264_nvenc", "-preset", "p6", "-rc", "vbr", "-cq", "19", "-b:v", "0", "-c:a", "aac", "-b:a", "192k", "-ar", "48000")

foreach ($g in $grupos) {
    $nombre = "iphone-" + $g[0].CreationTime.ToString("yyyyMMdd-HHmmss") + ".mp4"
    $partes = @(); $ok = $true; $total = 0
    for ($i = 0; $i -lt $g.Count; $i++) {
        $f = $g[$i]
        $dur = [double](Probe $f.FullName @() "format=duration")
        if ($dur -lt 0.5) { continue }   # tramo vacío de un cambio de tamaño instantáneo
        $paquetes = 0   # "N/A" o vacío cuando el tramo no tiene audio
        [void][int]::TryParse([string](Probe $f.FullName @("-select_streams", "a", "-count_packets") "stream=nb_read_packets"), [ref]$paquetes)
        $parte = Join-Path $tmp ("parte-{0:D3}.mp4" -f $i)
        $durTxt = $dur.ToString([Globalization.CultureInfo]::InvariantCulture)
        if ($paquetes -gt 0) {
            $fc = "[0:v]$vf[v];[0:a]aresample=48000:async=1:first_pts=0,apad[a]"
            & ffmpeg -hide_banner -v error -y -err_detect ignore_err -i $f.FullName -filter_complex $fc -map "[v]" -map "[a]" -t $durTxt @enc $parte 2>> $log
        } else {
            # tramo sin sonido: pista de silencio para que todas las partes coincidan
            & ffmpeg -hide_banner -v error -y -err_detect ignore_err -i $f.FullName -f lavfi -i "anullsrc=r=48000:cl=stereo" -filter_complex "[0:v]$vf[v]" -map "[v]" -map 1:a -t $durTxt @enc $parte 2>> $log
        }
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $parte)) { $ok = $false; Log "$($f.Name): ERROR al convertir el tramo"; break }
        $partes += $parte; $total += $dur
    }

    if ($ok -and $partes.Count) {
        $lista = Join-Path $tmp "lista.txt"
        ($partes | ForEach-Object { "file '" + ($_ -replace '\\', '/') + "'" }) | Out-File $lista -Encoding ascii
        & ffmpeg -hide_banner -v error -y -f concat -safe 0 -i $lista -c copy -movflags +faststart (Join-Path $salida $nombre) 2>> $log
        if ($LASTEXITCODE -eq 0) {
            Log "$nombre <- $($g.Count) tramo(s), $([math]::Round($total,1)) s"
            $g | ForEach-Object { Move-Item $_.FullName $hechos -Force }
        } else { Log "${nombre}: ERROR al unir los tramos; los crudos quedan en crudo" }
    } elseif (-not $partes.Count -and $ok) {
        $g | ForEach-Object { Move-Item $_.FullName $hechos -Force }
    }
    Remove-Item (Join-Path $tmp "*") -Force -ErrorAction SilentlyContinue
}
Remove-Item $tmp -Force -ErrorAction SilentlyContinue
