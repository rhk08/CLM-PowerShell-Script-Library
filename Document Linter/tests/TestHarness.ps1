# ============================
# Document Linter Test Harness
# Pester v3 compatible
# ============================



[CmdletBinding()]
param()


# Resolve test paths
$script:TestRoot    = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ProjectRoot = Resolve-Path (Join-Path $script:TestRoot "..")

$script:InputRoot    = Join-Path $script:TestRoot "input"
$script:DocxInput    = Join-Path $script:InputRoot "docx"
$script:XmlInput     = Join-Path $script:InputRoot "xml"
$script:InvalidInput = Join-Path $script:InputRoot "invalid"
$script:ExpectedRoot = Join-Path $script:TestRoot "expected"
$script:TempRoot     = Join-Path $script:TestRoot "temp"


function Initialize-TestFolders {

    Write-Verbose "Initialising test folders..."

    $folders = @(
        $script:InputRoot,
        $script:DocxInput,
        $script:XmlInput,
        $script:InvalidInput,
        $script:ExpectedRoot,
        $script:TempRoot
    )

    foreach ($folder in $folders) {
        if (-not (Test-Path $folder)) {
            Write-Verbose "Creating folder: $folder"
            New-Item -ItemType Directory -Path $folder | Out-Null
        }
        else {
            Write-Verbose "Folder exists: $folder"
        }
    }
}


function Clear-TestTemp {

    Write-Verbose "Clearing temp folder..."

    if (Test-Path $script:TempRoot) {
        $files = Get-ChildItem -Path $script:TempRoot -Force

        Write-Verbose ("Found {0} items in temp" -f $files.Count)

        $files | Remove-Item -Recurse -Force

        Write-Verbose "Temp folder cleared"
    }
    else {
        Write-Verbose "Temp folder does not exist"
    }
}



function Get-TestDocxPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )

    $path = Join-Path $script:InputRoot $FileName
    Write-Verbose "Resolved Input path: $path"

    return $path
}

function Get-TestDocxPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )

    $path = Join-Path $script:DocxInput $FileName
    Write-Verbose "Resolved DOCX path: $path"

    return $path
}


function Get-TestXmlPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )
    $path = Join-Path $script:XmlInput $FileName
    Write-Verbose "Resolved Xml path: $path"

    return $path
}

function Get-TestExpectedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )

    $path = Join-Path $script:ExpectedRoot $FileName
    Write-Verbose "Resolved Expected path: $path"

    return $path
}

function Get-TestTempPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )
    $path = Join-Path $script:TempRoot $FileName
    Write-Verbose "Resolved Temp path: $path"
}




# Initialise test environment
Write-Verbose "TestRoot: $script:TestRoot"
Write-Verbose "ProjectRoot: $script:ProjectRoot"
Write-Verbose "InputRoot: $script:InputRoot"

Initialize-TestFolders
Clear-TestTemp