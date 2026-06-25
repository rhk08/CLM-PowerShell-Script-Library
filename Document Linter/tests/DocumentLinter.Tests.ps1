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
# import document.xml as xml object and return it

Describe "Get-DocumentXML" {

    Context "Valid .docx file" {

        It "returns an XML object" {
            $result = Get-DocumentXML -Path "test.docx"

            $result | Should -Not -BeNullOrEmpty
            $result.GetType().Name | Should -Be "XmlDocument"
        }

        It "contains document.xml content" {
            $result = Get-DocumentXML -Path "test.docx"

            $result.OuterXml | Should -Match "<w:document"
        }
    }

    Context "Invalid inputs" {

        It "throws when file does not exist" {
            { Get-DocumentXML -Path "fake.docx" } | Should -Throw
        }

        It "throws when file is not a docx" {
            { Get-DocumentXML -Path "test.txt" } | Should -Throw
        }
    }
}