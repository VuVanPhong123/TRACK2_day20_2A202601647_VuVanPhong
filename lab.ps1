<#
  Windows runner — the equivalent of `make <target>` for students without make.

  Works in Windows PowerShell 5.1 (powershell.exe) and PowerShell 7+ (pwsh).

      .\lab.ps1                 # list targets
      .\lab.ps1 probe
      .\lab.ps1 setup
      .\lab.ps1 bench
      .\lab.ps1 serve           # leave running, open a second window for the rest
      .\lab.ps1 load-50
      .\lab.ps1 verify

  Every target maps 1:1 to the make target of the same name, so GUIDE.md applies
  as written — just substitute `.\lab.ps1 x` for `make x`.
#>
param(
    [Parameter(Position = 0)] [string] $Target = "help",
    [Parameter(ValueFromRemainingArguments = $true)] [string[]] $Rest
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$VenvPy    = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
$Port      = if ($env:LAB_SERVER_PORT) { $env:LAB_SERVER_PORT } else { '8080' }
$EmbedPort = if ($env:LAB_EMBED_PORT) { $env:LAB_EMBED_PORT } else { '8081' }
$SysPy     = 'python'

function Need-Venv {
    if (-not (Test-Path $VenvPy)) {
        Write-Host "ERROR: no virtualenv found at .venv\" -ForegroundColor Red
        Write-Host "Run this first:  .\lab.ps1 setup"
        exit 1
    }
}

function Py { Need-Venv; & $VenvPy @args; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE } }

function Locust {
    Need-Venv
    & $VenvPy -m locust @args
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

function Get-BuildJobs {
    if ($env:LLAMA_BUILD_JOBS) {
        if ($env:LLAMA_BUILD_JOBS -notmatch '^[1-9][0-9]*$') {
            Write-Host "ERROR: LLAMA_BUILD_JOBS must be a positive integer." -ForegroundColor Red
            exit 1
        }
        return [int]$env:LLAMA_BUILD_JOBS
    }

    $cores = [Environment]::ProcessorCount
    $ramGb = 8
    try {
        $mem = (Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).TotalPhysicalMemory
        if ($mem) { $ramGb = [Math]::Floor($mem / 1GB) }
    }
    catch {
        try {
            $mem = (Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop).TotalPhysicalMemory
            if ($mem) { $ramGb = [Math]::Floor($mem / 1GB) }
        }
        catch {
            Write-Host "WARNING: could not detect RAM; using a conservative 8 GB build budget." -ForegroundColor Yellow
        }
    }

    $byRam = [Math]::Max(1, [Math]::Floor($ramGb / 4))
    return [int][Math]::Min($cores, $byRam)
}

switch ($Target) {
    'help' {
        Write-Host ""
        Write-Host "Day 20 lab — Windows runner" -ForegroundColor Cyan
        Write-Host "Usage:  .\lab.ps1 <target>"
        Write-Host ""
        Write-Host "Setup (00)"
        Write-Host "  probe          Probe hardware -> hardware.json"
        Write-Host "  setup          Install deps + llama.cpp runtime + selected model"
        Write-Host "  runtime        Re-fetch just the llama.cpp binaries"
        Write-Host ""
        Write-Host "Measure (01)"
        Write-Host "  bench          TTFT / TPOT / percentiles, both quantizations"
        Write-Host "  tune           Thread sweep -> your before/after speedup"
        Write-Host ""
        Write-Host "Serve (02)"
        Write-Host "  serve          Start llama-server on :$Port (leave running)"
        Write-Host "  serve-embed    Embedding server on :$EmbedPort (bonus C9)"
        Write-Host "  smoke          Prove the API + non-zero /metrics"
        Write-Host "  load-10        Load test, 10 users, 60s"
        Write-Host "  load-50        Load test, 50 users, 60s"
        Write-Host "  metrics        Sample /metrics 60s (run WHILE load-50 runs)"
        Write-Host "  load-report    Saturation reading from both load runs"
        Write-Host ""
        Write-Host "Integrate (03)"
        Write-Host "  pipeline       RAG pipeline -> llama-server"
        Write-Host ""
        Write-Host "Submission"
        Write-Host "  verify         Check submission readiness"
        Write-Host ""
        Write-Host "Bonus"
        Write-Host "  sweep-quant | sweep-ctx | sweep-batch | sweep-gpu"
        Write-Host "  compare-builds | build-llama | semantic-cache-offline | embed-demo-offline"
        Write-Host ""
        Write-Host "Housekeeping"
        Write-Host "  clean          Remove generated reports"
        Write-Host "  clean-all      Also remove venv, runtime, models, hardware.json"
        Write-Host ""
        Write-Host "You need 3 windows for the 50-user step: serve / load-50 / metrics." -ForegroundColor Yellow
        Write-Host ""
    }

    'probe'   { & $SysPy labs\00-setup\detect-hardware.py }
    'setup'   {
        if (-not (Test-Path '.venv')) { & $SysPy -m venv .venv }
        & $VenvPy -m pip install --upgrade pip wheel | Out-Null
        & $VenvPy -m pip install -r requirements.txt
        Py labs\00-setup\setup.py
    }
    'runtime' { Py labs\00-setup\fetch-runtime.py --force }

    'bench'   { Py labs\01-measure\benchmark.py }
    'tune'    { Py labs\01-measure\tune.py @Rest }

    'serve'       { Py labs\02-serve\serve.py @Rest }
    'serve-embed' { Py labs\02-serve\serve.py --embedding @Rest }
    'smoke'       { Py labs\02-serve\smoke-test.py }
    'load-10'     { Locust -f labs\02-serve\load-test.py --headless -u 10 -r 5 -t 1m --host http://localhost:$Port --csv benchmarks\locust-10 --csv-full-history }
    'load-50'     { Locust -f labs\02-serve\load-test.py --headless -u 50 -r 25 -t 1m --host http://localhost:$Port --csv benchmarks\locust-50 --csv-full-history }
    'metrics'     { Py labs\02-serve\record-metrics.py --duration 60 --label u50 }
    'load-report' { Py labs\02-serve\load-report.py }

    'pipeline' { Py labs\03-integrate\pipeline.py @Rest }

    # verify must work with system Python too: the grader has no .venv.
    'verify' { & $SysPy scripts\verify.py; exit $LASTEXITCODE }

    'sweep-quant' { Py bonus\sweeps\quant-sweep.py @Rest }
    'sweep-ctx'   { Py bonus\sweeps\ctx-len-sweep.py @Rest }
    'sweep-batch' { Py bonus\sweeps\batch-size-sweep.py @Rest }
    'sweep-gpu'   { Py bonus\sweeps\gpu-offload-sweep.py @Rest }
    'compare-builds' { Py bonus\compare-builds.py @Rest }
    'embed-demo'             { Py bonus\serving-regimes\embedding-serving.py @Rest }
    'embed-demo-offline'     { Py bonus\serving-regimes\embedding-serving.py --offline }
    'semantic-cache'         { Py bonus\serving-regimes\semantic-cache-demo.py @Rest }
    'semantic-cache-offline' { Py bonus\serving-regimes\semantic-cache-demo.py --offline --sweep }

    'build-llama' {
        Need-Venv
        foreach ($t in 'cmake', 'git') {
            if (-not (Get-Command $t -ErrorAction SilentlyContinue)) {
                Write-Host "ERROR: $t not found. Install Visual Studio Build Tools + cmake + git." -ForegroundColor Red
                exit 1
            }
        }
        $build = & $VenvPy -c "import sys;sys.path.insert(0,'lib');import labkit;print(labkit.LLAMA_CPP_BUILD)"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        if (-not (Test-Path 'bonus\llama.cpp')) {
            git clone --depth 1 --branch $build https://github.com/ggml-org/llama.cpp bonus\llama.cpp
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        }
        $flags = if ($env:LLAMA_CMAKE_FLAGS) { $env:LLAMA_CMAKE_FLAGS -split ' ' } else { @() }
        $jobs = Get-BuildJobs
        Write-Host "Building llama.cpp with $jobs parallel job(s). Override with LLAMA_BUILD_JOBS." -ForegroundColor Cyan
        cmake -B bonus\llama.cpp\build -S bonus\llama.cpp @flags -DGGML_NATIVE=ON -DCMAKE_BUILD_TYPE=Release
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        cmake --build bonus\llama.cpp\build -j $jobs --config Release
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Write-Host ""
        Write-Host "Built. Now compare it against the prebuilt binary:  .\lab.ps1 compare-builds"
    }

    'clean' {
        Remove-Item -ErrorAction SilentlyContinue benchmarks\01-*.md, benchmarks\01-*.json,
            benchmarks\02-*.md, benchmarks\02-*.json, benchmarks\02-*.csv,
            benchmarks\03-*.md, benchmarks\03-*.json,
            benchmarks\locust-*.csv, benchmarks\bonus-*.md, benchmarks\bonus-*.json,
            benchmarks\.llama-server.log
        Write-Host "Cleaned generated reports. Kept hardware.json, models\, runtime\, submission\."
    }

    'clean-all' {
        Remove-Item -ErrorAction SilentlyContinue benchmarks\01-*.md, benchmarks\01-*.json,
            benchmarks\02-*.md, benchmarks\02-*.json, benchmarks\02-*.csv,
            benchmarks\03-*.md, benchmarks\03-*.json,
            benchmarks\locust-*.csv, benchmarks\bonus-*.md, benchmarks\bonus-*.json,
            benchmarks\.llama-server.log
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .venv, runtime, models,
            bonus\llama.cpp, hardware.json
        Write-Host "Removed venv, runtime, models and hardware.json. Re-run: .\lab.ps1 setup"
    }

    default {
        Write-Host "Unknown target: $Target" -ForegroundColor Red
        Write-Host "Run  .\lab.ps1  with no arguments to list targets."
        exit 1
    }
}
