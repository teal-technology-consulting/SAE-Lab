function New-LogLine
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
        [ValidateNotNull()]
        [int]$MaxLogFileSize = 2.5MB
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
    
        if (-not $Script:LogFilePath)
        {
            Write-Error -Message 'Variable $LogFilePath not defined in scope $Script:'
        }
        $Script:LogFilePath = Resolve-Path -Path $Script:LogFilePath
        if (-not (Test-Path -Path $Script:LogFilePath -PathType Leaf))
        {
            New-Item -Path $Script:LogFilePath -ItemType File -ErrorAction Stop | Out-Null
        }
        $LogFile = Get-Item -Path $Script:LogFilePath
        if ($LogFile.Length -ge $MaxLogFileSize)
        {
            $ArchiveLogFiles = Get-ChildItem -Path $LogFile.Directory -Filter "$($LogFile.BaseName)*.log" | Where-Object {$_.Name -match "$($LogFile.BaseName)-\d{8}-\d{6}\.log"} | Sort-Object -Property BaseName
            if ($ArchiveLogFiles.Count -gt 1)
            {
                $ArchiveLogFiles | Select-Object -Skip ($ArchiveLogFiles.Count - 1) | Remove-Item -WhatIf
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

