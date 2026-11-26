# 无限画布桌面版

从仓库根目录运行：

```bash
pnpm install --frozen-lockfile
pnpm dev:desktop
```

桌面版通过 Electron 窗口打开 CLI 工作台，源码开发直接使用 CLI 的 Vite 热更新。默认使用与 CLI 相同的 `~/.infinite-canvas/workspace` 和端口 17371。使用其他工作区可运行 `pnpm dev:desktop --data-dir /绝对路径 --port 17372`。同一工作区只能由一个服务打开；先退出 CLI 或桌面版，再切换入口。

项目、素材、模型渠道、插件和 MCP 连接都由同一个本地服务处理。窗口关闭且允许离开后，桌面版等待服务退出并释放目录。关闭窗口时，如果画布或设置仍在保存，可以返回工作台等待，或选择放弃修改。

启动受插件影响时，退出原进程后使用 `pnpm dev:desktop --skip-plugins` 打开原工作区，本次跳过第三方插件并保留数据和启用选择。进入插件设置后逐个重新启用；相关视频任务保持暂停，确认插件可用后再继续。

运行 `pnpm build:desktop` 会先构建 CLI，再为当前系统和架构打包桌面应用到 `apps/desktop/dist/`。应用包含 CLI 的正式界面、服务及其运行依赖。首次开发启动或打包需要下载对应平台的 Electron。签名、安装程序和自动更新尚待发行阶段处理。

## Windows Desktop Release（分发 fork）

在分发 fork 中把 `desktop` 设为默认分支，并启用 GitHub Actions。GitHub 的定时任务从默认分支运行，工作流每半小时检查上游已公开的稳定 Release，并从 `v1.0.0` 开始按版本顺序处理缺失的版本。上游只有 tag 时不会发布桌面包。

可以先在 Actions 中手动运行 **Windows Desktop Release**，填写 `v1.0.0`。默认只生成 Actions 附件。启用 `publish` 后，验证通过的产物会上传到 fork 的同名 Release。这个 Release 的 tag 指向上游的原始提交，工作流会把 `desktop` 分支维护的打包补丁应用到该提交再构建。已发布的版本会跳过。

Windows x64 产物包含免安装 ZIP、每用户安装 EXE 和 `SHA256SUMS.txt`。每次发布前都会从 ZIP 解压启动，并安装、启动和卸载 EXE。包内自带 Electron，首次运行所用的工作区仍位于 Windows 用户目录。当前产物未签名。
