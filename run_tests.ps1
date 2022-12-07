function FirstBuild($AdditionalArgs) {
    # This environmental variable needs to reset everytime a build is run in a new directory
    $Env:RUSTFLAGS = "--remap-path-prefix=${PWD}=app -Clink-arg=/experimental:deterministic"

    Write-Output 'Build to generate Cargo.lock file'
    cargo build --release $AdditionalArgs --target=x86_64-pc-windows-msvc 

    Write-Output 'Build with locked Cargo.lock file'
    cargo build --release --locked $AdditionalArgs --target=x86_64-pc-windows-msvc 
}

function SecondBuild($AdditionalArgs){
    # This environmental variable needs to reset everytime a build is run in a new directory
    $Env:RUSTFLAGS = "--remap-path-prefix=${PWD}=app -Clink-arg=/experimental:deterministic"

    Write-Output 'Build with locked Cargo.lock file'
    cargo build --release --locked $AdditionalArgs --target=x86_64-pc-windows-msvc 
}

function ExecutableTests {
    Write-Output '======================='
    Write-Output 'Executable Tests'
    Write-Output '======================='
    Write-Output 'Testing exe reproducibility using https://github.com/nellshamrell/reproducible_build_basic_exp.git'
    Write-Output 'Creating first build...'

    Set-Location first_builds
    git clone https://github.com/nellshamrell/reproducible_build_basic_exp.git
    Set-Location reproducible_build_basic_exp

    FirstBuild

    $DFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\reproducible_build_basic_exp.d
    $ExeFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\reproducible_build_basic_exp.exe
    $PdbFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\reproducible_build_basic_exp.pdb
 
    Write-Output 'Creating second build from a different directory...'
    Set-Location ../../second_builds
    git clone https://github.com/nellshamrell/reproducible_build_basic_exp.git

    Write-Output 'Copying Cargo.lock from first build to make sure we use the same one'
    Copy-Item ../first_builds/reproducible_build_basic_exp/Cargo.lock reproducible_build_basic_exp
    Set-Location reproducible_build_basic_exp

    SecondBuild

    $DSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\reproducible_build_basic_exp.d
    $ExeSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\reproducible_build_basic_exp.exe
    $PdbSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\reproducible_build_basic_exp.pdb

    Write-Output 'Getting file hashes...'

    Write-Output 'reproducible_build_basic_exp.d (first build)'
    Write-Output $DFirstBuild.Hash
    Write-Output 'reproducible_build_basic_exp.d (second build)'
    Write-Output $DSecondBuild.Hash
    $DReproducible = $DFirstBuild.Hash -eq $DSecondBuild.Hash

    Write-Output ''

    Write-Output 'reproducible_build_basic_exp.exe (first build)'
    Write-Output $ExeFirstBuild.Hash
    Write-Output 'reproducible_build_basic_exp.exe (first build)'
    Write-Output $ExeSecondBuild.Hash
    $ExeReproducible = $ExeFirstBuild.Hash -eq $ExeSecondBuild.Hash

    Write-Output ''

    Write-Output 'reproducible_build_basic_exp.pdb (first build)'
    Write-Output $PdbFirstBuild.Hash
    Write-Output 'reproducible_build_basic_exp.pdb (second build)'
    Write-Output $PdbSecondBuild.Hash
    $PdbReproducible = $PdbFirstBuild.Hash -eq $PdbSecondBuild.Hash

    Write-Output ''

    Write-Output '======================='
    Write-Output 'Executable Test Results'
    Write-Output '======================='

    Write-Output 'reproducible_build_basic_exp.d reproducible?'
    Write-Output $DReproducible
    Write-Output ''

    Write-Output 'reproducible_build_basic_exp.exe reproducible?'
    Write-Output $ExeReproducible
    Write-Output ''

    Write-Output 'reproducible_build_basic_exp.pdb reproducible?'
    Write-Output $PdbReproducible

    # Write results to file
    "Exe Test Results`n-------------`n" | Out-File -FilePath ..\..\test_results.txt -Append
    "Tested using https://github.com/nellshamrell/reproducible_build_basic_exp`n"  | Out-File -FilePath ..\..\test_results.txt -Append
    "reproducible_build_basic_exp.d reproducible? ${DReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "reproducible_build_basic_exp.exe reproducible? ${ExeReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "reproducible_build_basic_exp.pdb reproducible? ${PdbReproducible}`n" | Out-File -FilePath ..\..\test_results.txt -Append

    Set-Location ../..
}

function RLibTests { 
    Write-Output '======================='
    Write-Output 'RLib Tests'
    Write-Output '======================='
    Write-Output 'Testing rlib reproducibility using https://github.com/microsoft/windows-rs/tree/master/crates/libs/windows'
    Write-Output 'Using tag 0.37.0'
    Write-Output 'Creating first build...'

    Set-Location first_builds
    git clone https://github.com/microsoft/windows-rs.git
    Set-Location windows-rs

    FirstBuild -AdditionalArgs "--package=windows"

    $DFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\libwindows.d
    $RlibFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\libwindows.rlib

    Write-Output ''

    Write-Output 'Creating second build from a different directory...'
    Set-Location ../../second_builds
    git clone https://github.com/microsoft/windows-rs.git

    Write-Output 'Copying Cargo.lock from first build to make sure we use the same one'
    Copy-Item ../first_builds/windows-rs/Cargo.lock windows-rs
    Set-Location windows-rs

    SecondBuild -AdditionalArgs "--package=windows"

    Write-Output 'Getting file hashes...'

    $DSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\libwindows.d
    $RlibSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\libwindows.rlib

    Write-Output 'libwindows.d (first build)'
    Write-Output $DFirstBuild.Hash
    Write-Output 'libwindows.d (second build)'
    Write-Output $DSecondBuild.Hash
    $DReproducible = $DFirstBuild.Hash -eq $DSecondBuild.Hash

    Write-Output ''

    Write-Output 'libwindows.rlib (first build)'
    Write-Output $RlibFirstBuild.Hash
    Write-Output 'libwindows.rlib (second build)'
    Write-Output $RlibSecondBuild.Hash
    $RLibReproducible = $RlibFirstBuild.Hash -eq $RlibSecondBuild.Hash


    Write-Output '======================='
    Write-Output 'RLib Test Results'
    Write-Output '======================='

    Write-Output ''
    Write-Output 'libwindows.d reproducible?'
    Write-Output $DReproducible

    Write-Output ''
    Write-Output 'libwindows.rlib reproducible?'
    Write-Output $RLibReproducible

    # Write results to file
    "RLib Test Results`n-------------`n" | Out-File -FilePath ..\..\test_results.txt -Append
    "Tested using https://github.com/microsoft/windows-rs/tree/master/crates/libs/windows`n"  | Out-File -FilePath ..\..\test_results.txt -Append
    "libwindows.d reproducible? ${DReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "libwindows.rlib reproducible? ${RLibReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append

    Set-Location ../..
}

# SET UP
Write-Output 'Running Windows Rust Reproducible Build Tests'
Write-Output 'Getting Rust version...'
rustc --version

# Create directories to run tests in
mkdir first_builds
mkdir second_builds

# Check if results file already exists
# If it does, delete it

If (Test-Path -Path .\test_results.txt) {
    Remove-Item -Path .\test_results.txt    
}

# Create file to write results to
New-Item -Path . -Name 'test_results.txt' -ItemType "file" -Value "Test Results`n`n"

# Run tests
ExecutableTests

RLibTests

# CLEAN UP
Remove-Item -LiteralPath "first_builds" -Force -Recurse
Remove-Item -LiteralPath "second_builds" -Force -Recurse