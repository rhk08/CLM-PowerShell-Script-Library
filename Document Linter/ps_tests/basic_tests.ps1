



Describe "Mock test" {
    It "captures Write-Host" {
        Mock Write-Host {}
        Test-Import-Get-Document-XMLPath
        Assert-MockCalled Write-Host -Times 1 -ParameterFilter {
            $Object -eq "[] Sourced Successfully!"
        }
    }
}

Describe "Get-Document-XMLPath.ps1" {

    BeforeAll {

        . "C:\Users\rkhor\OneDrive - KPMG\Desktop\Scripts\CLM-PowerShell-Script-Library\Document Linter\Get-Document-XMLPath.ps1"
    }


    

    Context "Valid input" {

        It "does expected behaviour" {
            $result = FunctionName -Param "value"

            $result | Should Be "ExpectedResult"
        }
    }

    Context "Invalid input" {

        It "throws an error" {
            { FunctionName -Param $null } | Should Throw
        }
    }
}


