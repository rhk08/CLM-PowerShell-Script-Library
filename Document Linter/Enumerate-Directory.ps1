function Enumerate-Directory {
    <#
    Returns an array containing the full paths of enumerated files.
    Supports optional recursion, extension filtering, and a maximum
    file limit to prevent runaway enumeration.

    .ARGUMENTS
        -r  Recursively enumerate all directories. Default: False
        -f  ".docx" Filter for specific extensions. Default: None
        -l  Set max limit on files. Default: 1000 files.

        -Verbose  <see output below>

            ==== Enumerate-Directory Configuration ====
            Directory       : C:\temp
            Recurse         : True
            FilterExtension : .docx .pdf .txt
            Limit           : 1000
            ===========================================
            Files Found     : 365
            Elapsed Time    : 00:00:03.1235354
            ===========================================

    .USAGE
        Non-recursive, first 1000 files
            Enumerate-Directory -D "C:\Temp"

        Recursive, only .docx, first 200 results, warnings at 100 and 200
            Enumerate-Directory -D "C:\Temp" -r -f ".docx" -l 200
        Multiple extensions
            Enumerate-Directory "C:\Temp" -r -f "docx","pdf" -l 500
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [Alias('D')]
        [ValidateNotNullOrEmpty()]
        [string]$DirectoryToEnumerate,

        [Alias('r')]
        [switch]$Recurse,

        [Alias('f')]
        [string[]]$FilterExtension,

        [Alias('l')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Limit = 1000


    )

    
    if ($VerbosePreference) {
        Write-Host "==== Enumerate-Directory Configuration ====" -ForegroundColor Green
        Write-Host ("Directory       : {0}" -f $DirectoryToEnumerate) -ForegroundColor Green
        Write-Host ("Recurse         : {0}" -f [bool]$Recurse)        -ForegroundColor Green
        Write-Host ("FilterExtension : {0}" -f ($(if ($FilterExtension) { $FilterExtension -join ', ' } else { '<none>' }))) -ForegroundColor Green
        Write-Host ("Limit           : {0}" -f $Limit)                -ForegroundColor Green
        Write-Host "===========================================" -ForegroundColor Green
    }
    
    $startTime = $null
    if ($VerbosePreference) {
        $startTime = Get-Date
    }


    # Validate Directory
    $resolved = $null
    try {
        $resolved = Resolve-Path -LiteralPath $DirectoryToEnumerate -ErrorAction Stop
    }
    catch {
        throw "Directory not found: '$DirectoryToEnumerate'"
    }

    if (-not (Test-Path -LiteralPath $resolved.Path -PathType Container)) {
        throw "Path is not a directory: '$($resolved.Path)'"
    }

    # Store Extensions into set for fast lookup
    $extSet = $null
    if ($FilterExtension -and $FilterExtension.Count -gt 0) {
        $extSet = @{}
        foreach ($e in $FilterExtension) {
            if ($null -eq $e) { continue }
            $x = $e.Trim()
            if ($x -eq '') { continue }
            if ($x[0] -ne '.') { $x = ".$x" }
            $x = $x.ToLowerInvariant()
            if (-not $extSet.ContainsKey($x)) { $extSet[$x] = $true }
        }
    }

    # Build Get-ChildItem params (streaming; avoids loading 1M objects into memory)
    $gciParams = @{
        LiteralPath = $resolved.Path
        ErrorAction = 'SilentlyContinue'
        Force       = $true
    }
    if ($Recurse) { $gciParams.Recurse = $true }

    # STREAMING enumeration with early stop
    $results =
        Get-ChildItem @gciParams |
        Where-Object { -not $_.PSIsContainer } |
        Where-Object {
            if (-not $extSet) { $true }
            else { $extSet.ContainsKey($_.Extension.ToLowerInvariant()) }
        } |
        Select-Object -First $Limit -ExpandProperty FullName
    
    $results = @($results)

    if ($VerbosePreference) {
        $elapsed = (Get-Date) - $startTime
        $found = $results.Count

        if ($found -ge $Limit) {
            Write-Host ("Files Found     : {0} (LIMIT REACHED)" -f $found) -ForegroundColor Green
        }
        else {
            Write-Host ("Files Found     : {0}" -f $found) -ForegroundColor Green
        }

        Write-Host ("Elapsed Time    : {0}" -f $elapsed) -ForegroundColor Green
        Write-Host "===========================================" -ForegroundColor Green
    }

    return $results
}

$list = Enumerate-Directory -D "C:\Users\rkhor" -r -f "docx","pdf"
