FROM mcr.microsoft.com/windows/servercore:ltsc2022
WORKDIR /app

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

ADD https://aka.ms/vs/17/release/vs_buildtools.exe C:/vs_buildtools.exe

# Install Build Tools with the Microsoft.VisualStudio.Workload.AzureBuildTools workload, excluding workloads and components with known issues.
RUN C:\vs_buildtools.exe --quiet --wait --norestart --nocache \
    --installPath C:\BuildTools \
    --add Microsoft.Component.MSBuild \
    --add Microsoft.VisualStudio.Component.Windows10SDK.18362 \
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64	\
 || IF "%ERRORLEVEL%"=="3010" EXIT 0

RUN del C:\vs_buildtools.exe

ADD https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe C:/rustup-init.exe

RUN C:\rustup-init.exe -y --profile minimal
RUN del C:\rustup-init.exe

RUN setx /M PATH "C:\Users\ContainerAdministrator\.cargo\bin;%PATH%"