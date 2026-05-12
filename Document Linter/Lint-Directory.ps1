function Lint-Document {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [Alias('P')]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [switch]$Fix
    )

    

}
