# JetBrainsMono Nerd Font installer for Windows

This is a [WiX v5](https://wixtoolset.org/docs/intro/) based installer for the
[JetBrainsMono Nerd Font](https://www.nerdfonts.com/).

This installer is available on
[winget](https://learn.microsoft.com/windows/package-manager/winget/):

```
winget install --id DjRyan.JetBrainsMonoNerdFont
```

## Build prerequisites

- [Pandoc](https://pandoc.org/)
- [.NET SDK](https://dotnet.microsoft.com/download)

Install them with the following commands:

```powershell
winget install --id JohnMacFarlane.Pandoc
winget install --id Microsoft.DotNet.SDK.10
```

## Build

Run the `src\Build-Installer.ps1` PowerShell script to build the installer.

If successful, the MSI file will be available in the `src\bin\Release\en-US`
directory.
