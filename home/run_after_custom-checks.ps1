[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Environment]::SetEnvironmentVariable("XDG_CONFIG_HOME", "$env:USERPROFILE\.config", "User")
[Environment]::SetEnvironmentVariable("GIT_SSH", "C:\WINDOWS\System32\OpenSSH\ssh.exe", "User")



function Add-ToPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateSet("User", "Machine")]
        [string]$Scope
    )

    $currentPaths = [System.Environment]::GetEnvironmentVariable("Path", $Scope) -split ";" | Where-Object { $_ -ne "" }
    $normalized = $Path.TrimEnd("\")
    $exists = $currentPaths | ForEach-Object { $_.TrimEnd("\") } | Where-Object { $_ -ieq $normalized }

    if (-not $exists) {
        $newPath = ($currentPaths + $Path) -join ";"
        [System.Environment]::SetEnvironmentVariable("Path", $newPath, $Scope)

        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + `
                    [System.Environment]::GetEnvironmentVariable("Path", "Machine")

    }
}

Add-ToPath "$env:USERPROFILE\.local\bin" "User"
