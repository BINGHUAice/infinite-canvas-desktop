# 无限画布 · Windows 桌面版

基于 [basketikun/infinite-canvas](https://github.com/basketikun/infinite-canvas) 的社区发行版。每个桌面版本都从上游同名正式 Release 的源码构建，提供可下载安装的 Windows x64 应用。

## 下载和启动

进入 [最新桌面版本](https://github.com/BINGHUAice/infinite-canvas-desktop/releases/latest)，在 **Assets** 中选择下载文件。

- **安装版**（`*-setup.exe`）。双击安装，完成后可从开始菜单打开「无限画布」。安装到当前 Windows 用户的程序目录，无需管理员权限。
- **便携版**（`*-portable.zip`）。将 ZIP 完整解压，双击 `无限画布.exe`。移动应用时请保留整个解压目录。ZIP 根目录包含程序文件，建议解压到单独的文件夹。
- **校验文件**（`SHA256SUMS.txt`）。可用 PowerShell 的 `Get-FileHash -Algorithm SHA256 <下载文件>` 核对完整性。

两个版本都自带运行环境，无需安装 Node.js 或 pnpm。默认工作区位于 `%USERPROFILE%\.infinite-canvas\workspace`。当前发行包未签名，Windows 首次启动时可能显示发布者提示。

## 如何发布

GitHub Actions 每半小时检查一次上游正式 Release。从 `v1.0.0` 起，按版本顺序处理 fork 中缺少的桌面版本。工作流直接从作者仓库检出对应提交、应用 Windows 打包补丁，再构建 EXE 和 ZIP。发布前会在 Windows runner 上验证便携版解压启动，以及安装版的安装、启动和卸载。

默认分支只维护工作流、Windows 打包脚本、补丁和说明。上游源码在构建时检出，Release 标签指向对应的上游提交。可在 **Windows Desktop Release** 工作流中手动指定上游标签。默认只生成 Actions 附件，勾选 `publish` 后才发布到 Releases。 [发布工作流](.github/workflows/desktop-release.yml)

## 来源和许可证

原项目由 basketikun 和上游贡献者维护。应用与源码遵循上游 MIT 许可证，下游发行包随附版权和许可证。 [上游项目](https://github.com/basketikun/infinite-canvas) · [MIT 许可证](LICENSE)
