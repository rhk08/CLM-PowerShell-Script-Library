# Import XML to Custom Data Structure
function Convert-WordXmlToHT {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [xml] $Xml
    )

    $idRef = [ref] 1
    return @{
        Root = Convert-WordXmlNodeToHT -Node $Xml.DocumentElement -IdRef $idRef
    }
}
function Convert-WordXmlNodeToHT {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Node, 
        [Parameter()]
        $Parent = $null
    )

    $base = $Node.PSBase
    $id = $IdRef.Value
    $IdRef.Value++

    # Handle Node Types
    # Nodetype: 'Element' is more complex and has children hence we passthrough

    # NodeTypes: Text, Whitespace, SignificantWhitespace are more primitive
    # Thus we return early for these types.

    switch ($base.NodeType) {
        'Text', 'Whitespace', 'SignificantWhitespace' {
            # Specific case for Text nodes (NEED TO CONFIRM)
            if ($base.NodeType -eq 'Text' -and $null -eq $base.Value) {
                return $null
            }

            return @{
                Id     = $id
                Type   = 'T'
                Text   = $base.Value
                Parent = $Parent
            }
        }

        'Element' { 
            #Passthrough without throwing an error
        }
        default {
            throw "Unsupported node type encountered: '$($base.NodeType)'. NodeName='$($base.Name)'."
        }
    }

    # Attributes hashtable mapped as (name -> value) via PSBase
    $attr = @{}
    if ($base.Attributes -and $base.Attributes.Count -gt 0) {
        foreach ($a in $base.Attributes) {
            $ab = $a.PSBase
            $attr[$ab.Name] = $ab.Value
        }
    }

    # Create this Element HT node first so we can pass it as a Parent to Children
    $this = @{
        Id     = $id
        Type   = 'E'
        Name   = $base.Name   # QName e.g. w:bookmarkStart
        Attr   = $attr
        Kids   = @()
        Parent = $Parent
    }

    # Handle Children ensure order is preserved
    if ($base.ChildNodes -and $base.ChildNodes.Count -gt 0) {
        foreach ($ch in $base.ChildNodes) {
            $childHT = Convert-WordXmlNodeToHT -Node $ch -Parent $this -IdRef $idRef
            if ($null -ne $childHT) { $this.Kids += $childHT }
        }
    }

    return $this
}


# Helper Functions
function Escape-WordXmlText {
    param([AllowNull()][string]$s)
    if ($null -eq $s) { return '' }

    $s = $s -replace '&', '&amp;'
    $s = $s -replace '<', '&lt;'
    $s = $s -replace '>', '&gt;' # likely not necessary
    $s = $s -replace '"', '&quot;' # likely not necessary
    $s = $s -replace "'", '&apos;' # likely not necessary
    return $s
}
function Escape-WordXmlAttr { # Possibly Useless
    param([AllowNull()][string]$s)
    if ($null -eq $s) { return '' }
    $s = Escape-WordXmlText $s
    return $s
}
# Validation Functions
function Assert-ValidXmlName {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Context = 'XML name',
        [string]$NodeId  = ''
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        throw "$Context is missing or empty. Node Id=$NodeId"
    }
    if ($Name -like '*&*') {
        throw "$Context contains '&': '$Name' Node Id=$NodeId"
    }

    if ($Name -notmatch '^[A-Za-z_][A-Za-z0-9_.:-]*$') {
        throw "$Context is not a valid XML name: '$Name' Node Id=$NodeId"
    }
}


# Export Data Structure to XML String
function Convert-WordHTToXmlString {
    param(
        [Parameter(Mandatory)]
        $Tree,

        [switch] $SortAttributes
    )

    $out = ''
    $out += Convert-WordHTNodeToXmlString -Node $Tree.Root -SortAttributes:$SortAttributes
    return $out
}
function Convert-WordHTNodeToXmlString {
    param(
        [Parameter(Mandatory)]
        [hashtable] $Node,
        [switch] $SortAttributes
    )

    # Handle Text Node
    if ($Node.Type -eq 'T') {
        return (Escape-WordXmlText $Node.Text)
    }

    # Validate Element Node's Name
    $name = $Node.Name
    Assert-ValidXmlName -Name $name -Context 'Element name' -NodeId $Node.Id

    # Handle Attributes
    $attrs = ''
    if ($Node.ContainsKey('Attr') -and $Node.Attr -and $Node.Attr.Count -gt 0) {
        $keys = @($Node.Attr.Keys)
        if ($SortAttributes) { $keys = $keys | Sort-Object }

        foreach ($k in $keys) {
            Assert-ValidXmlName -Name $k -Context 'Attribute name' -NodeId $Node.Id
            $v = Escape-WordXmlAttr $Node.Attr[$k]
            $attrs += " $k=`"$v`""
        }
    }

    # Handle Children
    if ($Node.ContainsKey('Kids') -and $Node.Kids -and $Node.Kids.Count -gt 0) {
        $inner = ''
        foreach ($kid in $Node.Kids) {
            if ($kid -is [hashtable] -and $kid.ContainsKey('Type')) {
                $inner += Convert-WordHTNodeToXmlString -Node $kid -SortAttributes:$SortAttributes
            }
        }
        return "<$name$attrs>$inner</$name>"
    }

    # Handle Self Closing Nodes
    return "<$name$attrs />"
}



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
function Lint-DocumentXML {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [Alias('P')]
        [ValidateNotNullOrEmpty()]
        [string]$DocumentXMLPath,

        [switch]$Fix
    )

    # Covert XML to HashTable Tree
    

}


