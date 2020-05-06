Get-ChildItem -Path $PSScriptRoot -Filter *.asm -Recurse | ForEach-Object {
    $file = $_
    Write-Host -message ("processing: " + $file.Name)
    $content = Get-content -Path $file.FullName
    $commandlist = @();
    $varMem = 16
    $SymbolList = @{
        SP = 0
        LCL = 1
        ARG = 2
        THIS = 3
        THAT = 4
        R0 = 0
        R1 = 1
        R2 = 2
        R3 = 3
        R4 = 4
        R5 = 5
        R6 = 6
        R7 = 7
        R8 = 8
        R9 = 9
        R10 = 10
        R11 = 11
        R12 = 12
        R13 = 13
        R14 = 14
        R15 = 15
        SCREEN = 16384
        KBD = 24576
    }
    $compList = @{
        "0"="0101010"
        "1"="0111111"
        "-1"="0111010"
        "D"="0001100"
        "A"="0110000"
        "!D"="0001101"
        "!A"="0110001"
        "-D"="0001111"
        "-A"="0110011"
        "D+1"="0011111"
        "A+1"="0110111"
        "D-1"="0001110"
        "A-1"="0110010"
        "D+A"="0000010"
        "D-A"="0010011"
        "A-D"="0000111"
        "D&A"="0000000"
        "D|A"="0010101"
        "M"="1110000"
        "!M"="1110001"
        "-M"="1110011"
        "M+1"="1110111"
        "M-1"="1110010"
        "D+M"="1000010"
        "D-M"="1010011"
        "M-D"="1000111"
        "D&M"="1000000"
        "D|M"="1010101"
    }
    $destList = @{
        "null"="000"
        "M"="001"
        "D"="010"
        "MD"="011"
        "A"="100"
        "AM"="101"
        "AD"="110"
        "AMD"="111"
    }
    $jumpList = @{
        "null"="000"
        "JGT"="001"
        "JEQ"="010"
        "JGE"="011"
        "JLT"="100"
        "JNE"="101"
        "JLE"="110"
        "JMP"="111"
    }

    foreach ($line in $content) {
        $line = $line -replace "//.*", ""
        $line = $line.trim()
        if ($line) {
            if ($line -match "\(.*\)") {
                $line = $line -replace "\(", ""
                $line = $line -replace "\)", ""
                $SymbolList[$line] = $commandlist.Length
            }
            else {
                $commandlist += $line
            }
        }
    }

    $binaries = @()
    foreach ($command in $commandlist) {
        $binary = ""
        if ($command[0] -eq "@") {
            $binary += "0"
            $command = $command -replace "@", ""
            if ($command -notmatch "^\d+$") {
                if ($SymbolList[$command] -notlike "") {
                    $command = $SymbolList[$command]
                }
                else{
                    $SymbolList[$command] = $varMem
                    $command = $varMem
                    $varMem ++
                }
            }
            $binary += [System.Convert]::ToString($command,2).PadLeft(15,'0')
        }
        else {
            $binary += "111"
            if ($command -match ';') {
                $a=$command.Split(';')
                $command = $a[0]
                $jump = $a[1]
            }
            else {
                $jump = "null"
            }
            if ($command -match '=') {
                $a=$command.Split('=')
                $command = $a[1]
                $dest = $a[0]
            }
            else {
                $dest = "null"
            }
            $binary += $compList[$command] + $destList[$dest] + $jumpList[$jump]
        }
        $binaries += $binary
    }
    $binaries | Out-File -FilePath $file.FullName.Replace(".asm",".hack") -Encoding ascii
}