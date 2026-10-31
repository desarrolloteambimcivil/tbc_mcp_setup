# TBC-MCP Setup

One Windows installer for the TBC-MCP suite by TeamBIMCivil:

| Product | Connects AI assistants to | Repository |
|---|---|---|
| **tbc-revit-mcp** | Autodesk Revit 2022–2027 | [tbc_mcp_revit](https://github.com/desarrolloteambimcivil/tbc_mcp_revit) |
| **tbc-acad-mcp** | Autodesk AutoCAD and Civil 3D 2022–2027 | [tbc_mcp_autocad](https://github.com/desarrolloteambimcivil/tbc_mcp_autocad) |

With both installed, the assistant can read a DWG drawing with `dwg_*` tools and model it in Revit with `revit_*` tools in the same conversation.

## Install

1. Download `TbcMcp_Setup_<version>.exe` from [Releases](https://github.com/desarrolloteambimcivil/tbc_mcp_setup/releases/latest).
2. Close Revit, AutoCAD and your AI assistants (Claude Code, Claude Desktop, Cursor…).
3. Run the installer.
   - It ticks the products whose program it finds on this computer. A product whose program is missing cannot be ticked.
   - It ticks the AI assistants it finds. The `tbc-revit-mcp` and `tbc-acad-mcp` entries are added to their configuration, with a backup first.

The installer works per user and needs no administrator rights. Each product keeps its own folders, settings and update check, so `revit_health` and `dwg_health` report their own versions.

If the standalone tbc-revit-mcp installer is already on the computer, the suite removes it first and installs the same files again. Your settings, logs and history are kept. One uninstaller, **TBC-MCP** in Settings → Apps, removes both products and keeps personal data.

## How it is built

The suite never rebuilds a product. It packages the setup ZIPs each product publishes in its own release, after checking them against their `.sha256` files:

```powershell
# 1. Download the latest releases (or pass -RevitTag v1.3.3 -AcadTag v2.2.0)
powershell -ExecutionPolicy Bypass -File scripts\fetch-releases.ps1
# 2. Build installer\output\TbcMcp_Setup_<VERSION>.exe (needs Inno Setup 6)
powershell -ExecutionPolicy Bypass -File installer\build.ps1
```

The CI workflow does both steps when it is started by hand (Actions → build → Run workflow) after a product release.

`installer\build.ps1 -SkillsDir <folder>` adds an optional component with Claude Code skills. Each subfolder that has a `SKILL.md` is copied to `%USERPROFILE%\.claude\skills\`. A skill with the same name that the user wrote is moved to `.claude\skills-backup\` and put back on uninstall. Public builds ship no skills.

`tests\skills.Tests.ps1` checks the skills install and uninstall in a temporary folder.

## License

Apache-2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE): both products are modified versions of [rvt-mcp](https://github.com/bimwright/rvt-mcp) and [dwg-mcp](https://github.com/bimwright/dwg-mcp) by Bimwright.
