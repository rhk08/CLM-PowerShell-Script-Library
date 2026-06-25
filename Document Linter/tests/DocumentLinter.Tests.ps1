# ============================
# Document Linter Tests
# Pester v3 compatible
# ============================
$VerbosePreference = "Continue"
. "$PSScriptRoot\TestHarness.ps1"
Write-Host("")

Describe "Document Linter - Harness" {

    It "loads the test harness" {
        $script:TestRoot | Should Not BeNullOrEmpty
        $script:ProjectRoot | Should Not BeNullOrEmpty
    }

    It "creates required test folders" {
        Test-Path $script:InputRoot    | Should Be $true
        Test-Path $script:DocxInput    | Should Be $true
        Test-Path $script:XmlInput     | Should Be $true
        Test-Path $script:ExpectedRoot | Should Be $true
        Test-Path $script:TempRoot     | Should Be $true
    }
}

. "$ProjectRoot\Get-Document-XMLPath.ps1"


Describe "Test-Import-Get-Document-XMLPath" {

    Context "Smoke test" {
        It "runs without throwing" {
            Mock Write-Host {}
            { Test-Import-Get-Document-XMLPath } | Should Not Throw
        }
    }

    Context "Write-Host output" {

        It "writes to host once" {
            Mock Write-Host {}
            Test-Import-Get-Document-XMLPath

            Assert-MockCalled Write-Host -Times 1
        }
    }



    
}