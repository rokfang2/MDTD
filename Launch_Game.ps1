param(
    [string]$GodotPath,
    [switch]$PrepareOnly
)

$ErrorActionPreference = 'Stop'
try {
    if (-not $GodotPath) {
        $GodotPath = Join-Path $env:USERPROFILE 'Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe'
        $localEngine = Join-Path $PSScriptRoot 'Godot.exe'
        if (Test-Path -LiteralPath $localEngine) { $GodotPath = $localEngine }
    }
    if (-not (Test-Path -LiteralPath $GodotPath)) {
        throw 'Godot não encontrado. Importe project.godot no Godot 4 ou coloque Godot.exe nesta pasta.'
    }
    $logDirectory = Join-Path $PSScriptRoot 'review\launch'
    New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
    # Uma pasta .godot existente pode conter somente os sprites da versão antiga.
    # O importador incremental prepara também arquivos novos e modificados.
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        $engineLog = Join-Path $logDirectory "import_${stamp}_${attempt}.log"
        $arguments = @('--headless','--path',('"'+$PSScriptRoot+'"'),'--editor','--import','--quit','--log-file',('"'+$engineLog+'"'))
        $process = Start-Process -FilePath $GodotPath -ArgumentList $arguments -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -Wait -PassThru
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
    Start-Process -FilePath $GodotPath -ArgumentList @('--path',('"'+$PSScriptRoot+'"'),'--log-file',('"'+$gameLog+'"')) -WorkingDirectory $PSScriptRoot -WindowStyle Normal | Out-Null
} catch {
    if (-not $PrepareOnly) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Mushrooms Deserve to Die') | Out-Null
    }
    Write-Error $_.Exception.Message
    exit 1
}
