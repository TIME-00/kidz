<#
Kidz operator tool. No secrets/passwords are accepted as command-line arguments.
Dot-sourcing defines functions only. -WhatIf makes no requests or secret prompts.
Remote operations require separate approval; this script is not run by Flutter.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet('Inspect', 'Create', 'AssignRole', 'ResetPassword')]
    [string] $Action = 'Inspect',
    [ValidateSet('jtkqbasbyrejjyoayxmh')]
    [string] $ProjectRef = 'jtkqbasbyrejjyoayxmh',
    [string] $Email,
    [Guid] $UserId = [Guid]::Empty,
    [switch] $VerifiedEmailOwnership
)

function Read-KidzPrivateValue {
    param([string] $Prompt)
    $secureValue = Read-Host -Prompt $Prompt -AsSecureString
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureValue)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
        $secureValue.Dispose()
    }
}

function Read-KidzPassword {
    $first = Read-KidzPrivateValue 'New Admin password (16+ characters)'
    $second = Read-KidzPrivateValue 'Confirm new Admin password'
    try {
        if ($first.Length -lt 16 -or $first -cne $second) {
            throw 'Passwords must match exactly and contain at least 16 characters.'
        }
        return $first
    } finally { $second = $null; $first = $null }
}

function Assert-KidzServerKey {
    param([string] $Key)
    if ($Key -match '^sb_secret_[A-Za-z0-9_-]+$') { return }
    # Accept a legacy service_role JWT, but reject anon/user JWTs. This is key
    # classification only; the Supabase server verifies its signature/privileges.
    try {
        $parts = $Key.Split('.')
        if ($parts.Count -ne 3) { throw 'Invalid key' }
        $payload = $parts[1].Replace('-', '+').Replace('_', '/')
        $payload = $payload.PadRight($payload.Length + ((4 - $payload.Length % 4) % 4), '=')
        $claims = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
        if ($claims.role -cne 'service_role') { throw 'Invalid key' }
    } catch { throw 'A server secret or legacy service_role key is required. Do not use a client key.' }
}

function Invoke-KidzAdminRequest {
    param(
        [ValidateSet('GET', 'POST', 'PUT')] [string] $Method,
        [ValidatePattern('^/auth/v1/admin/users(/[0-9a-fA-F-]{36})?$')] [string] $Path,
        [string] $Key,
        [hashtable] $Body
    )
    # Pin the destination and prohibit redirects so credentials cannot be sent
    # to a user-supplied URL. HttpWebRequest does not emit verbose header logs.
    $request = [Net.HttpWebRequest]::Create('https://jtkqbasbyrejjyoayxmh.supabase.co' + $Path)
    $request.Method = $Method
    $request.AllowAutoRedirect = $false
    $request.Timeout = 30000
    $request.Headers['apikey'] = $Key
    if (-not $Key.StartsWith('sb_secret_')) { $request.Headers['Authorization'] = 'Bearer ' + $Key }
    $response = $null
    $reader = $null
    $bytes = $null
    try {
        if ($Body) {
            $request.ContentType = 'application/json'
            $bytes = [Text.Encoding]::UTF8.GetBytes(($Body | ConvertTo-Json -Depth 20 -Compress))
            $request.ContentLength = $bytes.Length
            $stream = $request.GetRequestStream()
            try { $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
        }
        $response = $request.GetResponse()
        if ([int]$response.StatusCode -ge 300) { throw 'Request refused' }
        $reader = New-Object IO.StreamReader($response.GetResponseStream())
        return ($reader.ReadToEnd() | ConvertFrom-Json)
    } catch {
        # Do not print exception bodies, request headers, passwords, or keys.
        throw 'Supabase Admin API request failed. No automatic retry or fallback was performed.'
    } finally {
        if ($reader) { $reader.Dispose() }
        if ($response) { $response.Dispose() }
        if ($bytes) { [Array]::Clear($bytes, 0, $bytes.Length) }
        $request.Headers.Clear()
        $Key = $null
    }
}

function Get-KidzAdminTarget {
    param([Guid] $Id, [string] $ExpectedEmail, [string] $Key)
    if ($Id -eq [Guid]::Empty -or [string]::IsNullOrWhiteSpace($ExpectedEmail)) {
        throw 'Both an exact Auth UUID and its expected email are required.'
    }
    $user = Invoke-KidzAdminRequest -Method GET -Path ('/auth/v1/admin/users/' + $Id) -Key $Key
    if ($user.id -ne $Id.ToString() -or $user.email -ine $ExpectedEmail.Trim()) {
        throw 'Target UUID/email mismatch. No changes were made.'
    }
    return $user
}

function Invoke-KidzAdminOperation {
    param([string] $Operation, [string] $TargetEmail, [Guid] $TargetId,
        [string] $Key, [switch] $EmailOwnershipVerified)
    Assert-KidzServerKey $Key
    $password = $null
    $body = $null
    try {
        if ($Operation -eq 'Create') {
            if (-not $EmailOwnershipVerified -or [string]::IsNullOrWhiteSpace($TargetEmail)) {
                throw 'Create requires a dedicated email and prior verification of email ownership.'
            }
            $password = Read-KidzPassword
            $body = @{ email = $TargetEmail.Trim(); password = $password; email_confirm = $true;
                app_metadata = @{ role = 'admin' } }
            # A duplicate-email error stops here. Never fall back to updating it.
            $user = Invoke-KidzAdminRequest -Method POST -Path '/auth/v1/admin/users' -Key $Key -Body $body
        } else {
            $user = Get-KidzAdminTarget -Id $TargetId -ExpectedEmail $TargetEmail -Key $Key
            switch ($Operation) {
                'Inspect' { }
                'AssignRole' {
                    $metadata = @{}
                    if ($user.app_metadata) {
                        foreach ($property in $user.app_metadata.PSObject.Properties) {
                            $metadata[$property.Name] = $property.Value
                        }
                    }
                    if ($metadata.ContainsKey('role') -and $metadata.role -cne 'admin') {
                        throw 'An existing different role cannot be overwritten by this tool.'
                    }
                    if (-not $EmailOwnershipVerified) { throw 'Verify ownership of the dedicated Admin email before assigning its role.' }
                    $metadata.role = 'admin'
                    $body = @{ app_metadata = $metadata }
                    $user = Invoke-KidzAdminRequest -Method PUT -Path ('/auth/v1/admin/users/' + $TargetId) -Key $Key -Body $body
                }
                'ResetPassword' {
                    if ($user.app_metadata.role -cne 'admin') { throw 'Password reset is restricted to an existing Admin account.' }
                    $password = Read-KidzPassword
                    $body = @{ password = $password }
                    $user = Invoke-KidzAdminRequest -Method PUT -Path ('/auth/v1/admin/users/' + $TargetId) -Key $Key -Body $body
                }
                default { throw 'Unsupported operation.' }
            }
        }
        # Whitelist output fields. Never return raw Auth responses or credentials.
        [PSCustomObject]@{ Id = $user.id; Email = $user.email;
            IsAdmin = ($user.app_metadata.role -ceq 'admin'); Operation = $Operation }
    } finally {
        if ($body) { $body.Clear() }
        $password = $null; $Key = $null; $user = $null
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if ([string]::IsNullOrWhiteSpace($Email) -or
        ($Action -ne 'Create' -and $UserId -eq [Guid]::Empty)) {
        throw 'Supply -Email and, except for Create, -UserId. Use a dedicated Admin account.'
    }
    if ($Action -in @('Create','AssignRole') -and -not $VerifiedEmailOwnership) {
        throw 'Create/AssignRole requires -VerifiedEmailOwnership after verifying control of the dedicated email.'
    }
    if ($PSCmdlet.ShouldProcess("$ProjectRef / $Email / $UserId", $Action)) {
        $operatorKey = Read-KidzPrivateValue 'Supabase server secret (never the Flutter publishable key)'
        try {
            Invoke-KidzAdminOperation -Operation $Action -TargetEmail $Email -TargetId $UserId `
                -Key $operatorKey -EmailOwnershipVerified:$VerifiedEmailOwnership
        } finally { $operatorKey = $null }
    }
}
