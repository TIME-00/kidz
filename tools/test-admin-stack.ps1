<# Creates and removes ONLY a fresh isolated local test stack inside this repo.
   Captures CLI startup/status output in memory; never logs its local secret keys.
   No linked project, hosted URL, database reset, global setting or --all stop.
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
function Invoke-PrivateSupabase {
    param([string[]] $CliArguments)
    $previousPreference = $ErrorActionPreference
    try {
        # Windows PowerShell treats native stderr as ErrorRecords. CLI progress
        # on stderr must not abort a start, nor reveal the final key summary.
        $ErrorActionPreference = 'Continue'
        $discarded = & supabase @CliArguments 2>&1
        $exitCode = $LASTEXITCODE
        $discarded = $null
        return $exitCode
    } finally { $ErrorActionPreference = $previousPreference }
}
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$projectId = 'kidz_admin_verify_' + [Guid]::NewGuid().ToString('N').Substring(0,8)
$testRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot ('.dart_tool/' + $projectId)))
if (-not $testRoot.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
    throw 'Test path must stay inside the Kidz project.'
}
$pointer = Join-Path $projectRoot '.dart_tool/kidz_admin_stack_location.txt'
if (Test-Path -LiteralPath $pointer) {
    $previous = (Get-Content -LiteralPath $pointer -Raw).Trim()
    $previousId = Split-Path -Path $previous -Leaf
    if ($previousId -match '^kidz_admin_verify_[0-9a-f]{8}$') {
        $running = & docker ps --filter ('name=' + $previousId) --format '{{.Names}}'
        if ($running) { throw 'An isolated Admin verification stack is already running. Finish its scoped cleanup first.' }
    }
}
$started = $false
$passed = $false
try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    if ((Invoke-PrivateSupabase @('init','--workdir',$testRoot)) -ne 0) {
        throw 'Unable to initialize isolated test configuration.'
    }
    $configPath = Join-Path $testRoot 'supabase/config.toml'
    $config = Get-Content -LiteralPath $configPath -Raw
    $config = [regex]::Replace($config,'(?m)^project_id\s*=.*$',('project_id = "' + $projectId + '"'))
    $config = [regex]::Replace($config,'\b543([0-9]{2})\b','553$1')
    foreach ($section in @('studio','inbucket','analytics','edge_runtime','realtime')) {
        $pattern = '(\[' + [regex]::Escape($section) + '\]\s*\r?\n(?:#[^\n]*\n)*enabled\s*=\s*)true'
        $config = [regex]::Replace($config,$pattern,'${1}false')
    }
    [IO.File]::WriteAllText($configPath,$config)
    # Pin the tested local service versions. Do not change source-project cache
    # or global Docker configuration, and never copy a hosted project-ref file.
    $cachePath = Join-Path $testRoot 'supabase/.temp'
    if (-not (Test-Path -LiteralPath $cachePath)) { New-Item -ItemType Directory -Path $cachePath | Out-Null }
    $versions = @{'postgres-version'='17.6.1.121'; 'gotrue-version'='v2.192.0'; 'rest-version'='v14.7'; 'storage-version'='v1.61.10'}
    foreach ($entry in $versions.GetEnumerator()) {
        [IO.File]::WriteAllText((Join-Path $cachePath $entry.Key),$entry.Value)
    }
    foreach ($folder in @('migrations','tests')) {
        $destination = Join-Path $testRoot ('supabase/' + $folder)
        if (-not (Test-Path -LiteralPath $destination)) { New-Item -ItemType Directory -Path $destination | Out-Null }
        Get-ChildItem -LiteralPath (Join-Path $projectRoot ('supabase/' + $folder)) -Filter '*.sql' |
            ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $destination $_.Name) }
    }
    [IO.File]::WriteAllText($pointer,$testRoot)
    Write-Output ('Starting synthetic local stack ' + $projectId + ' on API/DB ports 55321/55322.')
    $started = $true
    if ((Invoke-PrivateSupabase @('start','--workdir',$testRoot,'--exclude','realtime,imgproxy,mailpit,postgres-meta,studio,edge-runtime,logflare,vector,supavisor')) -ne 0) {
        throw 'Isolated Supabase startup failed. No private startup output was logged.'
    }
    Write-Output 'Local stack ready. Startup keys were not logged.'
    & supabase test db --local --workdir $testRoot
    if ($LASTEXITCODE -ne 0) { throw 'Isolated full-stack pgTAP tests failed.' }
    & node (Join-Path $projectRoot 'tools/admin-db/fullstack.mjs')
    if ($LASTEXITCODE -ne 0) { throw 'Isolated full-stack Auth/REST/Storage checks failed.' }
    $passed = $true
} catch {
    Write-Output ('FAIL: ' + ($_.Exception.Message -replace 'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+','[REDACTED JWT]' -replace 'sb_(secret|publishable)_[A-Za-z0-9_-]+','[REDACTED KEY]'))
    $passed = $false
} finally {
    $privateOutput = $null
    if ($started -and $projectId -match '^kidz_admin_verify_[0-9a-f]{8}$') {
        # This exact project was just created above. Never stop any other stack.
        $cleanupExit = Invoke-PrivateSupabase @('stop','--project-id',$projectId,'--workdir',$testRoot,'--no-backup')
        if ($cleanupExit -ne 0) { Write-Warning 'Scoped cleanup could not finish; inspect only the named test project.' }
        Write-Output ('Scoped local test cleanup requested for ' + $projectId + '.')
    }
}
if (-not $passed) { exit 1 }
exit 0
