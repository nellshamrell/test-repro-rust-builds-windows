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

    Write-Output 'reproducible_build_basic_exp.exe (first build)'
    Write-Output $ExeFirstBuild.Hash
    Write-Output 'reproducible_build_basic_exp.exe (first build)'
    Write-Output $ExeSecondBuild.Hash
    $ExeReproducible = $ExeFirstBuild.Hash -eq $ExeSecondBuild.Hash

    Write-Output 'reproducible_build_basic_exp.pdb (first build)'
    Write-Output $PdbFirstBuild.Hash
    Write-Output 'reproducible_build_basic_exp.pdb (second build)'
    Write-Output $PdbSecondBuild.Hash
    $PdbReproducible = $PdbFirstBuild.Hash -eq $PdbSecondBuild.Hash

    Write-Output '======================='
    Write-Output 'Executable Test Results'
    Write-Output '======================='

    Write-Output 'reproducible_build_basic_exp.d reproducible?'
    Write-Output $DReproducible

    Write-Output 'reproducible_build_basic_exp.exe reproducible?'
    Write-Output $ExeReproducible

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

    Write-Output 'libwindows.rlib (first build)'
    Write-Output $RlibFirstBuild.Hash
    Write-Output 'libwindows.rlib (second build)'
    Write-Output $RlibSecondBuild.Hash
    $RLibReproducible = $RlibFirstBuild.Hash -eq $RlibSecondBuild.Hash

    Write-Output '======================='
    Write-Output 'RLib Test Results'
    Write-Output '======================='

    Write-Output 'libwindows.d reproducible?'
    Write-Output $DReproducible

    Write-Output 'libwindows.rlib reproducible?'
    Write-Output $RLibReproducible

    # Write results to file
    "RLib Test Results`n-------------`n" | Out-File -FilePath ..\..\test_results.txt -Append
    "Tested using https://github.com/microsoft/windows-rs/tree/master/crates/libs/windows`n"  | Out-File -FilePath ..\..\test_results.txt -Append
    "libwindows.d reproducible? ${DReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "libwindows.rlib reproducible? ${RLibReproducible}`n" | Out-File -FilePath ..\..\test_results.txt -Append

    Set-Location ../..
}

function StaticCdyLibTests {
    Write-Output '======================='
    Write-Output 'StaticLib/CdyLib Tests'
    Write-Output '======================='
    Write-Output 'Testing staticlib/cdylib reproducibility using https://github.com/rust-lang/regex/tree/b92ffd5471018419ec48dbdef32757424439f065/regex-capi'
    Write-Output 'Creating first build...'

    Set-Location first_builds
    git clone https://github.com/rust-lang/regex.git
    Set-Location regex

    FirstBuild -AdditionalArgs "--package=rure"

    $DFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\rure.d
    $DllFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\rure.dll
    $DllExpFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\rure.dll.exp
    $DllLibFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\rure.dll.lib
    $LibFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\rure.lib
    $PdbFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\rure.pdb

    Set-Location ../../second_builds

    Write-Output 'Creating second build from a different directory...'
    git clone https://github.com/rust-lang/regex.git
    Write-Output 'Copying Cargo.lock from first build to make sure we use the same one'
    Copy-Item ../first_builds/regex/Cargo.lock regex
    Set-Location regex
 
    SecondBuild -AdditionalArgs "--package=rure"

    Write-Output 'Getting file hashes...'

    $DSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\rure.d
    $DllSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\rure.dll
    $DllExpSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\rure.dll.exp
    $DllLibSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\rure.dll.lib
    $LibSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\rure.lib
    $PdbSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\rure.pdb

    Write-Output 'rure.d (first build)'
    Write-Output $DFirstBuild.Hash
    Write-Output 'rure.d (second build)'
    Write-Output $DSecondBuild.Hash
    $DReproducible = $DFirstBuild.Hash -eq $DSecondBuild.Hash

    Write-Output 'rure.dll (first build)'
    Write-Output $DllFirstBuild.Hash
    Write-Output 'rure.dll (second build)'
    Write-Output $DllSecondBuild.Hash
    $DllReproducible = $DllFirstBuild.Hash -eq $DllSecondBuild.Hash

    Write-Output 'rure.dll.exp (first build)'
    Write-Output $DllExpFirstBuild.Hash
    Write-Output 'rure.dll.exp (second build)'
    Write-Output $DllExpSecondBuild.Hash
    $DllExpReproducible = $DllExpFirstBuild.Hash -eq $DllExpSecondBuild.Hash

    Write-Output 'rure.dll.lib (first build)'
    Write-Output $DllLibFirstBuild.Hash
    Write-Output 'rure.dll.lib (second build)'
    Write-Output $DllLibSecondBuild.Hash
    $DllLibReproducible = $DllLibFirstBuild.Hash -eq $DllLibSecondBuild.Hash

    Write-Output 'rure.lib (first build)'
    Write-Output $LibFirstBuild.Hash
    Write-Output 'rure.lib (second build)'
    Write-Output $LibSecondBuild.Hash
    $LibReproducible = $LibFirstBuild.Hash -eq $LibSecondBuild

    Write-Output 'rure.pdb (first build)'
    Write-Output $PdbFirstBuild.Hash
    Write-Output 'rure.pdb (second build)'
    Write-Output $PdbSecondBuild.Hash
    $PdbReproducible = $PdbFirstBuild.Hash -eq $PdbSecondBuild.Hash

    # Write results to file
    "StaticLib/Cdy LibTest Results`n-------------`n" | Out-File -FilePath ..\..\test_results.txt -Append
    "Tested using https://github.com/rust-lang/regex/tree/b92ffd5471018419ec48dbdef32757424439f065/regex-capi"  | Out-File -FilePath ..\..\test_results.txt -Append
    "rure.d reproducible? ${DReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "rure.dll reproducible? ${DllReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "rure.dll.exp reproducible? ${DllExpReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "rure.dll.lib reproducible? ${DllLibReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "rure.lib reproducible? ${LibReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "rure.pdb reproducible? ${PdbReproducible}`n" | Out-File -FilePath ..\..\test_results.txt -Append

    Set-Location ../..
}

function DyLibTests {
    Write-Output '======================='
    Write-Output 'DyLib Tests'
    Write-Output '======================='
    Write-Output 'Testing dylib reproducibility using https://github.com/AndrewGaspar/rust-plugin-example/tree/master/plugin_a'
    Write-Output 'Creating first build...'

    Set-Location first_builds
    git clone https://github.com/AndrewGaspar/rust-plugin-example.git
    Set-Location rust-plugin-example

    FirstBuild -AdditionalArgs "--package=plugin_a"

    $DFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\plugin_a.d
    $DllFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\plugin_a.dll
    $DllExpFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\plugin_a.dll.exp
    $DllLibFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\plugin_a.dll.lib
    $PdbFirstBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\plugin_a.pdb

    Set-Location ../../second_builds

    Write-Output 'Creating second build from a different directory...'
    git clone https://github.com/AndrewGaspar/rust-plugin-example.git
    Write-Output 'Copying Cargo.lock from first build to make sure we use the same one'
    Copy-Item ../first_builds/rust-plugin-example/Cargo.lock rust-plugin-example
    Set-Location rust-plugin-example

    SecondBuild -AdditionalArgs "--package=plugin_a"

    Write-Output 'Getting file hashes...'

    $DSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\plugin_a.d
    $DllSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\plugin_a.dll
    $DllExpSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\plugin_a.dll.exp
    $DllLibSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\plugin_a.dll.lib
    $PdbSecondBuild = Get-FileHash .\target\x86_64-pc-windows-msvc\release\plugin_a.pdb

    Write-Output 'plugin_a.d (first build)'
    Write-Output $DFirstBuild.Hash
    Write-Output 'plugin_a.d (second build)'
    Write-Output $DSecondBuild.Hash
    $DReproducible = $DFirstBuild.Hash -eq $DSecondBuild.Hash

    Write-Output 'plugin_a.dll (first build)'
    Write-Output $DllFirstBuild.Hash
    Write-Output 'plugin_a.dll (second build)'
    Write-Output $DllSecondBuild.Hash
    $DllReproducible = $DllFirstBuild.Hash -eq $DllSecondBuild.Hash

    Write-Output 'plugin_a.dll.exp (first build)'
    Write-Output $DllExpFirstBuild.Hash
    Write-Output 'plugin_a.dll.exp (second build)'
    Write-Output $DllExpSecondBuild.Hash
    $DllExpReproducible = $DllExpFirstBuild.Hash -eq $DllExpSecondBuild.Hash

    Write-Output 'plugin_a.dll.lib (first build)'
    Write-Output $DllLibFirstBuild.Hash
    Write-Output 'plugin_.dll.lib (second build)'
    Write-Output $DllLibSecondBuild.Hash
    $DllLibReproducible = $DllLibFirstBuild.Hash -eq $DllLibSecondBuild.Hash

    Write-Output 'plugin_a.pdb (first build)'
    Write-Output $PdbFirstBuild.Hash
    Write-Output 'plugin_a.pdb (second build)'
    Write-Output $PdbSecondBuild.Hash
    $PdbReproducible = $PdbFirstBuild.Hash -eq $PdbSecondBuild.Hash

    # Write results to file
    "DyLib Test Results`n-------------`n" | Out-File -FilePath ..\..\test_results.txt -Append
    "Tested using https://github.com/AndrewGaspar/rust-plugin-example/tree/master/plugin_a"  | Out-File -FilePath ..\..\test_results.txt -Append
    "plugin_a.d reproducible? ${DReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "plugin_a.dll reproducible? ${DllReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "plugin_a.dll.exp reproducible? ${DllExpReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "plugin_a.dll.lib reproducible? ${DllLibReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "plugin_a.pdb reproducible? ${PdbReproducible}`n" | Out-File -FilePath ..\..\test_results.txt -Append

    Set-Location ../..
}

function ProcMacroTests {
    Write-Output '======================='
    Write-Output 'Proc-Macro Tests'
    Write-Output '======================='
    Write-Output 'Testing proc-macro reproducibility using https://github.com/dtolnay/proc-macro-workshop/tree/master/seq'
    Write-Output 'Creating first build...'

    Set-Location first_builds
    git clone https://github.com/dtolnay/proc-macro-workshop.git
    Set-Location proc-macro-workshop

    FirstBuild -AdditionalArgs "--package=seq"

    $DFirstBuild = Get-FileHash .\target\release\seq.d
    $DllFirstBuild = Get-FileHash .\target\release\seq.dll
    $DllExpFirstBuild = Get-FileHash .\target\release\seq.dll.exp
    $DllLibFirstBuild = Get-FileHash .\target\release\seq.dll.lib
    $PdbFirstBuild = Get-FileHash .\target\release\seq.pdb

    Set-Location ../../second_builds

    Write-Output 'Creating second build from a different directory...'
    git clone https://github.com/dtolnay/proc-macro-workshop.git
    Write-Output 'Copying Cargo.lock from first build to make sure we use the same one'
    Copy-Item ../first_builds/proc-macro-workshop/Cargo.lock proc-macro-workshop
    Set-Location proc-macro-workshop
 
    SecondBuild -AdditionalArgs "--package=seq"

    Write-Output 'Getting file hashes...'

    $DSecondBuild = Get-FileHash .\target\release\seq.d
    $DllSecondBuild = Get-FileHash .\target\release\seq.dll
    $DllExpSecondBuild = Get-FileHash .\target\release\seq.dll.exp
    $DllLibSecondBuild = Get-FileHash .\target\release\seq.dll.lib
    $PdbSecondBuild = Get-FileHash .\target\release\seq.pdb

    Write-Output 'seq.d (first build)'
    Write-Output $DFirstBuild.Hash
    Write-Output 'seq.d (second build)'
    Write-Output $DSecondBuild.Hash
    $DReproducible = $DFirstBuild.Hash -eq $DSecondBuild.Hash

    Write-Output 'seq.dll (first build)'
    Write-Output $DllFirstBuild.Hash
    Write-Output 'seq.dll (second build)'
    Write-Output $DllSecondBuild.Hash
    $DllReproducible = $DllFirstBuild.Hash -eq $DllSecondBuild.Hash

    Write-Output 'seq.dll.exp (first build)'
    Write-Output $DllExpFirstBuild.Hash
    Write-Output 'seq.dll.exp (second build)'
    Write-Output $DllExpSecondBuild.Hash
    $DllExpReproducible = $DllExpFirstBuild.Hash -eq $DllExpSecondBuild.Hash

    Write-Output 'seq_a.dll.lib (first build)'
    Write-Output $DllLibFirstBuild.Hash
    Write-Output 'seq.dll.lib (second build)'
    Write-Output $DllLibSecondBuild.Hash
    $DllLibReproducible = $DllLibFirstBuild.Hash -eq $DllLibSecondBuild.Hash

    Write-Output 'seq.pdb (first build)'
    Write-Output $PdbFirstBuild.Hash
    Write-Output 'seq.pdb (second build)'
    Write-Output $PdbSecondBuild.Hash
    $PdbReproducible = $PdbFirstBuild.Hash -eq $PdbSecondBuild.Hash

    # Write results to file
    "Proc-Macro Test Results`n-------------`n" | Out-File -FilePath ..\..\test_results.txt -Append
    "Tested using https://github.com/dtolnay/proc-macro-workshop/tree/master/seq"  | Out-File -FilePath ..\..\test_results.txt -Append
    "seq.d reproducible? ${DReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "seq.dll reproducible? ${DllReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "seq.dll.exp reproducible? ${DllExpReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "seq.dll.lib reproducible? ${DllLibReproducible}" | Out-File -FilePath ..\..\test_results.txt -Append
    "seq.pdb reproducible? ${PdbReproducible}`n" | Out-File -FilePath ..\..\test_results.txt -Append

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
StaticCdyLibTests
DyLibTests
ProcMacroTests

# CLEAN UP
Remove-Item -LiteralPath "first_builds" -Force -Recurse
Remove-Item -LiteralPath "second_builds" -Force -Recurse