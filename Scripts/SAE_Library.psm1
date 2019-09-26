function Write-Log
{
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LogText,

        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [string]$Component = '',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Information','Warning','Error')]
        [string]$Type = 'Information',

        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [int]$Thread = $PID,

        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [string]$File = '',

        [Parameter(Mandatory = $false)]
        [int]$LogMaxSize = 2.5MB,

        [Parameter(Mandatory = $false)]
        [int]$LogMaxHistory = 1
    )
    
    #Requires -Version 2.0

    Begin
    {
        switch ($Type)
        {
            'Information' { $TypeNum = 1 }
            'Warning'     { $TypeNum = 2 }
            'Error'       { $TypeNum = 3 }
        }
    
        if (-not $Script:LogFilePath) {
            Write-Error -Message 'Variable $LogFilePath not defined in scope $Script:'
            exit 1
        }
        
        $Script:LogFilePath = Resolve-Path -Path $Script:LogFilePath
        if (-not (Test-Path -Path $Script:LogFilePath -PathType Leaf)) {
            New-Item -Path $Script:LogFilePath -ItemType File -ErrorAction Stop | Out-Null
        }
        
        $LogFile = Get-Item -Path $Script:LogFilePath
        if ($LogFile.Length -ge $LogMaxSize) {
            $ArchiveLogFiles = Get-ChildItem -Path $LogFile.Directory -Filter "$($LogFile.BaseName)*.log" | Where-Object {$_.Name -match "$($LogFile.BaseName)-\d{8}-\d{6}\.log"} | Sort-Object -Property BaseName
            if ($ArchiveLogFiles.Count -gt $LogMaxHistory) {
                $ArchiveLogFiles | Select-Object -Skip ($ArchiveLogFiles.Count - $LogMaxHistory) | Remove-Item
            }

            $NewFileName = "{0}-{1:yyyyMMdd-HHmmss}{2}" -f $LogFile.BaseName, $LogFile.LastWriteTime, $LogFile.Extension
            $LogFile | Rename-Item -NewName $NewFileName
            New-Item -Path $Script:LogFilePath -ItemType File -ErrorAction Stop | Out-Null
        }
    }
    
    Process
    {
        $now = Get-Date
        $Bias = ($now.ToUniversalTime() - $now).TotalMinutes
        [string]$Line = "<![LOG[{0}]LOG]!><time=`"{1:HH:mm:ss.fff}{2}`" date=`"{1:MM-dd-yyyy}`" component=`"{3}`" context=`"`" type=`"{4}`" thread=`"{5}`" file=`"{6}`">" -f $LogText, $now, $Bias, $Component, $TypeNum, $Thread, $File
        $Line | Out-File -FilePath $Script:LogFilePath -Encoding utf8 -Append -ErrorAction Stop
    }
    
    End
    {
    }
}

function Install-MSFile
{
    <#
    .SYNOPSIS
    Installs a MSI install package
    .DESCRIPTION
    Installs an installation package in MSI format
    .PARAMETER MsiPath
    Path to a MSI installation package
    .PARAMETER MsiLogPath
    Path to a log file
    #>

    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$MsiPath,

        [Parameter(Mandatory=$false)]
        [string]$MsiLogPath
    )

    $ReturnCode = 0

    if (-not (Test-Path $MsiPath)) {
        Write-Error "Could not find file `'$MsiPath`'."
        return 1
    }
    $MsiPath = Resolve-Path -Path $MsiPath
    
    if (-not $MsiLogPath) {
        $MsiLogPath = Join-Path $env:TEMP -ChildPath "$((Get-Item $MsiPath).BaseName).log"
    }

    Write-Log -LogText "Found MSI file `'$MsiPath`'."
    Write-Log -LogText "Using MSI log file `'$MsiLogPath`'."

    $Cmd = @{
        FilePath = Join-Path ([Environment]::SystemDirectory) -ChildPath 'msiexec.exe'
        ArgumentList = "/package `"$MSIPath`" /l `"$LogFile`" /quiet /norestart"
    }
    Write-Log -LogText 'Executing command line'
    Write-Log -LogText "$($Cmd.FilePath) $($Cmd.ArgumentList)"
    $Return = Start-Process @Cmd -Wait -PassThru
    if ($Return) {
        $ReturnCode = $Return.ExitCode
    }
    else {
        $ReturnCode = 2
    }

    if ($ReturnCode -eq 0) {
        Write-Log -LogText "Successfully installed file `'$MsiPath`' (Exit code $ReturnCode)."
    }
    elseif ($ReturnCode -eq 3010) {
        Write-Log -LogText "Restart required to complete the installation (Exit code $ReturnCode)."
    }
    else {
        Write-Log -LogText "Error occured while installing file `'$MsiPath`' (Exit code $ReturnCode)."
    }

    return  $ReturnCode
}
