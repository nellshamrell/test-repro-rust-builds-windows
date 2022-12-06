function FirstBuild($AdditionalArgs) {
    # This environmental variable needs to reset everytime a build is run in a new directory
    $Env:RUSTFLAGS = "--remap-path-prefix=${PWD}=app -Clink-arg=/experimental:deterministic"

    Write-Output 'Build to generate Cargo.lock file'
    cargo build --release $AdditionalArgs --target=x86_64-pc-windows-msvc 

    Write-Output 'Build with locked Cargo.lock file'
    cargo build --release --locked $AdditionalArgs --target=x86_64-pc-windows-msvc 
}

function SecondBuild {
    # This environmental variable needs to reset everytime a build is run in a new directory
    $Env:RUSTFLAGS = "--remap-path-prefix=${PWD}=app -Clink-arg=/experimental:deterministic"

    Write-Output 'Build with locked Cargo.lock file'
    cargo build --release --locked --package=windows --target=x86_64-pc-windows-msvc 
}

function ExecutableTests {
    Write-Output '======================='
    Write-Output 'Executable Tests'
    Write-Output '======================='
    Write-Output 'Testing exe reproducibility using https://github.com/nellshamrell/reproducible_build_basic_exp.git'
    Set-Location first_builds
    git clone https://github.com/nellshamrell/reproducible_build_basic_exp.git
    Set-Location reproducible_build_basic_exp


 
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

    Write-Output 'Getting file hashes...'
    Write-Output 'libwindows.d (first build)'
    $DFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\libwindows.d
    Write-Output $DFirstBuild.Hash
    Write-Output ''
    Write-Output 'libwindows.rlib (first build)'
    $RlibFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\libwindows.rlib
    Write-Output $RlibFirstBuild.Hash

    Write-Output ''

    Write-Output 'Creating second build from a different directory...'
    Set-Location ../../second_builds
    git clone https://github.com/microsoft/windows-rs.git

    Write-Output 'Copying Cargo.lock from first build to make sure we use the same one'
    Copy-Item ../first_builds/windows-rs/Cargo.lock windows-rs
    Set-Location windows-rs

    SecondBuild

    Write-Output 'Getting file hashes...'

    Write-Output 'libwindows.d (second build)'
    $DSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\libwindows.d
    Write-Output $DSecondBuild.Hash
    Write-Output ''
    Write-Output 'libwindows.rlib (second build)'
    $RlibSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\libwindows.rlib
    Write-Output $RlibSecondBuild.Hash

    Write-Output ''
    Write-Output 'libwindows.d reproducible?'
    $DReproducible = $DFirstBuild.Hash -eq $DSecondBuild.Hash
    Write-Output $DReproducible

    Write-Output ''
    Write-Output 'libwindows.rlib reproducible?'
    $RLibReproducible = $RlibFirstBuild.Hash -eq $RlibSecondBuild.Hash
    Write-Output $RLibReproducible
}

# SET UP
Write-Output 'Running Windows Rust Reproducible Build Tests'
Write-Output 'Getting Rust version...'
rustc --version

mkdir first_builds
mkdir second_builds

RLibTests

# CLEAN UP
Set-Location ../..
Remove-Item -LiteralPath "first_builds" -Force -Recurse
Remove-Item -LiteralPath "second_builds" -Force -Recurse