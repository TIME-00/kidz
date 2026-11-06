# Compatible with the existing Windows PowerShell Pester 3.x; no module install.
$toolPath = Join-Path $PSScriptRoot 'admin-account.ps1'
. $toolPath

Describe 'Kidz Admin operator tool (mocked requests only)' {
    BeforeEach {
        $script:requests = @()
        $script:fixture = [PSCustomObject]@{
            id = '10000000-0000-4000-8000-000000000001'
            email = 'dedicated@example.test'
            app_metadata = [PSCustomObject]@{ role = 'admin'; provider = 'email'; retained = 'original' }
        }
        Mock Read-KidzPassword { 'synthetic-password-for-tests' }
        Mock Read-KidzPrivateValue { throw 'No private prompts permitted in this test.' }
        Mock Invoke-KidzAdminRequest {
            $script:requests += [PSCustomObject]@{
                Method = $Method; Path = $Path
                BodyJson = ($Body | ConvertTo-Json -Depth 20 -Compress)
            }
            $script:fixture
        }
    }

    It 'creates only a dedicated confirmed Admin through POST' {
        $result = Invoke-KidzAdminOperation -Operation Create -TargetEmail 'dedicated@example.test' `
            -Key 'sb_secret_synthetic' -EmailOwnershipVerified
        $script:requests.Count | Should Be 1
        $script:requests[0].Method | Should Be 'POST'
        $body = $script:requests[0].BodyJson | ConvertFrom-Json
        $body.app_metadata.role | Should Be 'admin'
        $body.email_confirm | Should Be $true
        $result.IsAdmin | Should Be $true
        $result.PSObject.Properties.Name.Count | Should Be 4
        ($result | ConvertTo-Json) | Should Not Match 'password|sb_secret|retained'
    }

    It 'refuses creation without verified email ownership before prompting for a password' {
        { Invoke-KidzAdminOperation -Operation Create -TargetEmail 'dedicated@example.test' -Key 'sb_secret_synthetic' } | Should Throw
        Assert-MockCalled -Scope It Read-KidzPassword -Times 0 -Exactly
        Assert-MockCalled -Scope It Invoke-KidzAdminRequest -Times 0 -Exactly
    }

    It 'stops on duplicate creation without updating an existing account' {
        Mock Invoke-KidzAdminRequest { throw 'Synthetic duplicate refusal' }
        { Invoke-KidzAdminOperation -Operation Create -TargetEmail 'dedicated@example.test' `
            -Key 'sb_secret_synthetic' -EmailOwnershipVerified } | Should Throw
        Assert-MockCalled -Scope It Invoke-KidzAdminRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'PUT' }
    }

    It 'explicit role assignment preserves other application metadata' {
        $script:fixture.app_metadata = [PSCustomObject]@{provider='email'; retained='original'}
        $null = Invoke-KidzAdminOperation -Operation AssignRole -TargetEmail 'dedicated@example.test' `
            -TargetId $script:fixture.id -Key 'sb_secret_synthetic' -EmailOwnershipVerified
        $script:requests.Count | Should Be 2
        $body = $script:requests[1].BodyJson | ConvertFrom-Json
        $body.app_metadata.role | Should Be 'admin'
        $body.app_metadata.provider | Should Be 'email'
        $body.app_metadata.retained | Should Be 'original'
        $body.PSObject.Properties.Name | Should Be 'app_metadata'
    }

    It 'refuses to overwrite an existing Buyer or Seller role' {
        $script:fixture.app_metadata.role = 'seller'
        { Invoke-KidzAdminOperation -Operation AssignRole -TargetEmail 'dedicated@example.test' `
            -TargetId $script:fixture.id -Key 'sb_secret_synthetic' -EmailOwnershipVerified } | Should Throw
        Assert-MockCalled -Scope It Invoke-KidzAdminRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'PUT' }
    }

    It 'role assignment requires explicit verified ownership' {
        { Invoke-KidzAdminOperation -Operation AssignRole -TargetEmail 'dedicated@example.test' `
            -TargetId $script:fixture.id -Key 'sb_secret_synthetic' } | Should Throw
        Assert-MockCalled -Scope It Invoke-KidzAdminRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'PUT' }
    }

    It 'resets the exact Admin UUID with a password-only request' {
        $null = Invoke-KidzAdminOperation -Operation ResetPassword -TargetEmail 'dedicated@example.test' `
            -TargetId $script:fixture.id -Key 'sb_secret_synthetic'
        $script:requests[1].Path | Should Be ('/auth/v1/admin/users/' + $script:fixture.id)
        $body = $script:requests[1].BodyJson | ConvertFrom-Json
        $body.PSObject.Properties.Name | Should Be 'password'
        $script:fixture.app_metadata.retained | Should Be 'original'
    }

    It 'does not reset a non-Admin password' {
        $script:fixture.app_metadata.role = 'buyer'
        { Invoke-KidzAdminOperation -Operation ResetPassword -TargetEmail 'dedicated@example.test' `
            -TargetId $script:fixture.id -Key 'sb_secret_synthetic' } | Should Throw
        Assert-MockCalled -Scope It Read-KidzPassword -Times 0 -Exactly
        Assert-MockCalled -Scope It Invoke-KidzAdminRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'PUT' }
    }

    It 'rejects a UUID and email mismatch before any mutation' {
        { Invoke-KidzAdminOperation -Operation ResetPassword -TargetEmail 'wrong@example.test' `
            -TargetId $script:fixture.id -Key 'sb_secret_synthetic' } | Should Throw
        Assert-MockCalled -Scope It Read-KidzPassword -Times 0 -Exactly
        Assert-MockCalled -Scope It Invoke-KidzAdminRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'PUT' }
    }

    It 'requires an exact target UUID for existing-account operations' {
        { Invoke-KidzAdminOperation -Operation Inspect -TargetEmail 'dedicated@example.test' `
            -TargetId ([Guid]::Empty) -Key 'sb_secret_synthetic' } | Should Throw
        Assert-MockCalled -Scope It Invoke-KidzAdminRequest -Times 0 -Exactly
    }

    It 'rejects publishable keys before any API request' {
        { Invoke-KidzAdminOperation -Operation Inspect -TargetEmail 'dedicated@example.test' `
            -TargetId $script:fixture.id -Key 'sb_publishable_synthetic' } | Should Throw
        Assert-MockCalled -Scope It Invoke-KidzAdminRequest -Times 0 -Exactly
    }

    It 'Inspect returns only safe fields without mutations' {
        $result = Invoke-KidzAdminOperation -Operation Inspect -TargetEmail 'dedicated@example.test' `
            -TargetId $script:fixture.id -Key 'sb_secret_synthetic'
        $result.Operation | Should Be 'Inspect'
        Assert-MockCalled -Scope It Invoke-KidzAdminRequest -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' }
        Assert-MockCalled -Scope It Read-KidzPassword -Times 0 -Exactly
    }

    It 'WhatIf performs no API request or credential prompt' {
        & $toolPath -Action Create -Email dedicated@example.test -VerifiedEmailOwnership -WhatIf
        Assert-MockCalled -Scope It Invoke-KidzAdminRequest -Times 0 -Exactly
        Assert-MockCalled -Scope It Read-KidzPrivateValue -Times 0 -Exactly
    }

    It 'the transport forbids delete methods and arbitrary destinations before networking' {
        { Invoke-KidzAdminRequest -Method DELETE -Path '/auth/v1/admin/users' -Key 'synthetic' } | Should Throw
        { & $toolPath -Action Inspect -Email dedicated@example.test -UserId $script:fixture.id -ProjectRef 'another-project' -WhatIf } | Should Throw
    }
}
