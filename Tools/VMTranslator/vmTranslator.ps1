Get-ChildItem -Path $PSScriptRoot -Filter *.vm -Recurse | ForEach-Object {
    $file = $_
    Write-Host -message ("processing: " + $file.Name)
    $content = Get-content -Path $file.FullName
    $commanddict = @{};
    $commandlist = @();

    foreach ($line in $content) {
        $line = $line -replace "//.*", ""
        $line = $line.trim()

        $words = $line.split(" ")

        $command = $commanddict

        $i = 0
        while ($true) {
            switch ($command.next) {
                "cmd" {$command = $command.$word[$i]}
                "val" {$commandlist += $command.cmd -replace "#", $words[$i+1] ; break}
                "stop" {$commandlist += $command.cmd ; break}
                Default {Write-Error -Message "no command" -ErrorAction Stop}
            }
            $i ++;
        }
    }

    $commandlist | Out-File -FilePath $file.FullName.Replace(".vm",".asm") -Encoding ascii
}