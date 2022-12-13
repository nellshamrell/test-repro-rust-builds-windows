# test-repro-rust-builds-windows

Basic scripts for testing reproducible Rust builds on Windows

I created these scripts when I was evaluating reproducible Rust builds on Windows.

Overall, they do work for most outputs (exe, dll, etc.) *when built in containers*, but not all. For example, pdbs are not reproducible (and that is not exclusive to Rust). Proc Macro crate dlls are also not reproducible at this time.

Feel free to use these scripts to explore reproducible Rust builds on Windows. I hope to use these as a foundation for some sort of upstream CI tests.

These scripts test for reproducibility of:
* Binary crates (using [reproducible_build_basic_exp]( https://github.com/nellshamrell/reproducible_build_basic_exp))
* RLib library crates (using [windows-rs](https://github.com/microsoft/windows-rs)) 
* Static/Cdylib library crates (using [regex](https://github.com/rust-lang/regex))
* Dylib library crates (using [rust-plugin-example](https://github.com/AndrewGaspar/rust-plugin-example/))
* ProcMacro library crates (using [proc-macro-workshop](https://github.com/dtolnay/proc-macro-workshop.git))

## Pre-reqs

* PowerShell
* Rust installed
* Git installed
* Docker installed (and configured to use Windows containers)

## Running the scripts

### Testing builds in containers

To test builds in containers, run this script:

```bash
./containerized_build_tests.ps1
```

The test output will be captured in containerized_build_test_results.txt

*Most outputs are reproducible when built in containers.*

### Testing builds in locally (outside of containers)

To test the builds on your local workstation (not using containers), run this script.

```bash
./local_build_tests.ps1
```

The test output will be captured in local_build_test_results.txt

*Most outputs are not reproducible (when the build is run from different directories) outside of containers*