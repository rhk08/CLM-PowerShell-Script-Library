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

. "$ProjectRoot\Get-Document-XML.ps1"


Describe "Test-Import-Get-Document-XML" {

    Context "Smoke test" {
        It "runs without throwing" {
            Mock Write-Host {}
            { Test-Import-Get-Document-XML } | Should Not Throw
        }
    }

    Context "Write-Host output" {
        It "writes to host once" {
            Mock Write-Host {}
            Test-Import-Get-Document-XML

            Assert-MockCalled Write-Host -Times 1
        }

        It "writes success response" {
            Mock Write-Host {}
            Test-Import-Get-Document-XML

            Assert-MockCalled Write-Host -Times 1 -ParameterFilter {
                $Object -eq "[Get-Document-XML.ps1] Sourced Successfully!"
            }
        }
    }
}



# Given .docx path
# Unzip to a temp location provided by user (not its responsibility to clean up)
# locate document.xml
# import object and return it

Describe "Get-Document-XML" {

    Context "Positive Tests" {
        
        It "extracts .docx into Temp" {

            Mock Write-Host {}
        }

        It "write to host 'documentXML found'" {
            Mock Write-Host {}
        }


        It "returns XML Object" {
            Mock Write-Host {}
        }


    }

    Context "Negative Tests" {



    }
}