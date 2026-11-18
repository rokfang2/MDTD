param(
    [string]$GodotPath,
    [switch]$PrepareOnly
)

$ErrorActionPreference = 'Stop'
# Este script fica em tools/; a raiz do projeto é a pasta acima.
$root = Split-Path -Parent $PSScriptRoot
try {
    if (-not $GodotPath) {
        # Ordem: GODOT_BIN, godot no PATH, Godot.exe na raiz, caminho memorizado, busca nas pastas comuns.
        $cacheFile = Join-Path $env:LOCALAPPDATA 'MushroomsDeserveToDie\godot_path.txt'
        $candidates = @()
        if ($env:GODOT_BIN) { $candidates += $env:GODOT_BIN }
        $inPath = Get-Command godot -ErrorAction SilentlyContinue
        if ($inPath) { $candidates += $inPath.Source }
        $candidates += (Join-Path $root 'Godot.exe')
        if (Test-Path -LiteralPath $cacheFile) { $candidates += (Get-Content -LiteralPath $cacheFile -TotalCount 1) }
        $GodotPath = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
        if (-not $GodotPath) {
            # Primeira execução: procura o Godot 4.7 onde ele costuma ficar e memoriza o caminho.
            $places = @("$env:USERPROFILE\Desktop", "$env:USERPROFILE\Documents", "$env:USERPROFILE\Downloads",
                        "$env:USERPROFILE\OneDrive", $env:ProgramFiles, ${env:ProgramFiles(x86)}, "$env:LOCALAPPDATA\Programs") |
                      Where-Object { $_ -and (Test-Path -LiteralPath $_) }
            $found = Get-ChildItem -Path $places -Recurse -Depth 6 -Filter 'Godot*.exe' -File -ErrorAction SilentlyContinue |
                     Where-Object { $_.Name -notmatch 'console' -and $_.VersionInfo.ProductName -eq 'Godot Engine' -and $_.VersionInfo.ProductVersion -like '4.7.*' } |
                     Sort-Object { $_.VersionInfo.ProductVersion } -Descending | Select-Object -First 1
            if ($found) {
                $GodotPath = $found.FullName
                New-Item -ItemType Directory -Force -Path (Split-Path $cacheFile) | Out-Null
                Set-Content -LiteralPath $cacheFile -Value $GodotPath -Encoding UTF8
            }
        }
    }
    if (-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath)) {
        throw "Godot 4.7 não encontrado na Área de Trabalho, Documentos, Downloads, OneDrive nem em Arquivos de Programas. Defina a variável de ambiente GODOT_BIN com o caminho do Godot.exe (ex.: setx GODOT_BIN `"C:\caminho\Godot.exe`")."
    }
    $logDirectory = Join-Path $root 'docs\review\launch'
    New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
    # Uma pasta .godot existente pode conter somente os sprites da versão antiga.
    # O importador incremental prepara também arquivos novos e modificados.
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        $engineLog = Join-Path $logDirectory "import_${stamp}_${attempt}.log"
        $arguments = @('--headless','--path',('"'+$root+'"'),'--editor','--import','--quit','--log-file',('"'+$engineLog+'"'))
        $process = Start-Process -FilePath $GodotPath -ArgumentList $arguments -WorkingDirectory $root -WindowStyle Hidden -Wait -PassThru
        $contents = if (Test-Path -LiteralPath $engineLog) { Get-Content -LiteralPath $engineLog -Raw } else { '' }
        if ($process.ExitCode -eq 0 -and $contents -notmatch 'SCRIPT ERROR:|ERROR:') { break }
        # A falha nativa observada ao encerrar o importador admite uma repetição;
        # erros de recurso/script não são ocultados por novas tentativas.
        if ($attempt -eq 2 -or $process.ExitCode -ne -1073741819 -or $contents -match 'SCRIPT ERROR:|ERROR:') {
            throw "Não foi possível preparar o jogo. Consulte $engineLog (código $($process.ExitCode))."
        }
    }
    if ($PrepareOnly) {
        Write-Output 'IMPORT_READY'
        exit 0
    }
    $gameLog = Join-Path $logDirectory "game_${stamp}.log"
    Start-Process -FilePath $GodotPath -ArgumentList @('--path',('"'+$root+'"'),'--log-file',('"'+$gameLog+'"')) -WorkingDirectory $root -WindowStyle Normal | Out-Null
} catch {
    if (-not $PrepareOnly) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Mushrooms Deserve to Die') | Out-Null
    }
    Write-Error $_.Exception.Message
    exit 1
}
