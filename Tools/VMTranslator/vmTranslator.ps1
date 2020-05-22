Get-ChildItem -Path $PSScriptRoot -Filter *.vm -Recurse | ForEach-Object {
    $file = $_
    Write-Host -message ("processing: " + $file.Name)
    $content = Get-content -Path $file.FullName
    $commanddict = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath commandDict.json) | ConvertFrom-Json
    $commandlist = @()

    foreach ($line in $content) {
        $line = $line -replace "//.*", ""
        $line = $line.trim()
        if ($line -like "") {
            continue
        }

        $words = $line.split(" ")

        $command = $commanddict

        $i = 0
        $stop = $true
        while ($stop) {
            switch ($command.next) {
                "cmd" {$command = $command.($words[$i])}
                "val" {$commandlist += $command.cmd -replace "#", $words[$i] ; $stop = $false}
                "stop" {$commandlist += $command.cmd ; $stop = $false}
                "jmp" {$commandlist += $command.cmd -replace "#", ("END" + $commandlist.Length) ; $stop = $false}
                "temp" {$commandlist += $command.cmd -replace "#", ([int]($words[$i])+5) ; $stop = $false}
                "point" {$commandlist += $command.cmd -replace "#", ([int]($words[$i])+3) ; $stop = $false}
                Default {Write-Error -Message "no command" -ErrorAction Stop}
            }
            $i ++;
        }
    }

    $commandlist | Out-File -FilePath $file.FullName.Replace(".vm",".asm") -Encoding ascii
}