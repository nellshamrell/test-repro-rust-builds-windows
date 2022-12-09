function FirstBuild($AdditionalArgs) {
    Write-Output 'Build to generate Cargo.lock file'
    docker run --env RUSTFLAGS="--remap-path-prefix=\app=app -Clink-arg=/experimental:deterministic" --rm -v ${PWD}:C:\app -w /app nellshamrell/windows_rust_exp:0.0.1 cargo build --release --target=x86_64-pc-windows-msvc

    Write-Output 'Build with locked Cargo.lock file'
    docker run --env RUSTFLAGS="--remap-path-prefix=\app=app -Clink-arg=/experimental:deterministic" --rm -v ${PWD}:C:\app -w /app nellshamrell/windows_rust_exp:0.0.1 cargo build --release --locked --target=x86_64-pc-windows-msvc
}

function SecondBuild($AdditionalArgs) {
    Write-Output 'Build with locked Cargo.lock file'
    docker run --env RUSTFLAGS="--remap-path-prefix=\app=app -Clink-arg=/experimental:deterministic" --rm -v ${PWD}:C:\app -w /app nellshamrell/windows_rust_exp:0.0.1 cargo build --release --locked --target=x86_64-pc-windows-msvc
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
    "Exe Test Results`n-------------`n" | Out-File -FilePath ..\..\containerized_build_test_results.txt -Append
    "Tested using https://github.com/nellshamrell/reproducible_build_basic_exp`n"  | Out-File -FilePath ..\..\containerized_build_test_results.txt -Append
    "reproducible_build_basic_exp.d reproducible? ${DReproducible}" | Out-File -FilePath ..\..\containerized_build_test_results.txt -Append
    "reproducible_build_basic_exp.exe reproducible? ${ExeReproducible}" | Out-File -FilePath ..\..\containerized_build_test_results.txt -Append
    "reproducible_build_basic_exp.pdb reproducible? ${PdbReproducible}`n" | Out-File -FilePath ..\..\containerized_build_test_results.txt -Append

    Set-Location ../..
}

Write-Output 'Running Containerized Windows Rust Reproducible Build Tests'

# Create directories to run tests in
mkdir first_builds
mkdir second_builds

# Check if results file already exists
# If it does, delete it

If (Test-Path -Path .\containerized_build_test_results.txt) {
    Remove-Item -Path .\containerized_build_test_results.txt    
}

# Create file to write results to
New-Item -Path . -Name 'containerized_build_test_results.txt' -ItemType "file" -Value "Test Results`n`n"

# Run tests
ExecutableTests

# CLEAN UP
Remove-Item -LiteralPath "first_builds" -Force -Recurse
Remove-Item -LiteralPath "second_builds" -Force -Recurse