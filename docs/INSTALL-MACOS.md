# 小黄包一二 · Mac 安装说明

适用于已安装 Codex 桌面端、且设置中能看到「Mini 与虚拟宠物」或「Pets」的 Mac。本包复用 v1.0.0 的完整动画，包含9类动作和16个注视方向。

## 安装

1. 解压 Mac 安装包，打开解压后的普通文件夹。
2. 双击 **`install.command`**，等待终端显示「小黄包一二安装完成」。
3. 回到 Codex：**设置 → Mini 与虚拟宠物（或 Pets）→ 小刷新图标 ↻ → 小黄包一二**。

脚本使用 macOS 自带的 Bash 和系统工具。无需管理员权限、Python、Node.js、Homebrew 或联网。不要运行 Windows 的 `install.cmd`。

## 双击打不开时

打开「终端」，输入 `/bin/bash `（末尾保留一个空格），把解压后的 **`install.command`** 拖入终端，再按回车。文件路径会自动填入，中文和空格路径也可以使用。

若终端方式仍不能运行，也可以按下面的手动复制方式安装。

## 手动复制也可以

1. Finder 中按 **Command + Shift + G**，输入 `~/.codex`；若文件夹不存在，先在个人文件夹中创建 `.codex`。
2. 在 `.codex` 下创建 `pets` 文件夹。
3. 把安装包中的 `pet` 文件夹复制进去，重命名为 `yier-yellow-bag`，保持以下结构：

```text
~/.codex/pets/yier-yellow-bag/
  pet.json
  spritesheet.webp
```

4. 回到 Codex 设置，刷新后选中「小黄包一二」。

若设置了自定义 `CODEX_HOME`，请使用该目录下的 `pets`。终端中设置的环境变量也需要与桌面客户端实际使用的目录一致；不确定时使用默认目录。

## 已安装与卸载

相同文件重复安装会提示「已经安装」。同名目录中若有不同文件，脚本会停止并保留内容；需要更新时，先将旧文件夹移出 `pets` 备份。

卸载前在 Codex 中选择其他宠物或「无」，然后只移走或删除 `pets/yier-yellow-bag`，返回设置刷新。

## 验证范围

Mac 安装脚本和 ZIP 保留 `.command` 的执行权限，并使用 LF 换行。自动化测试验证安装、重复运行、路径选择、已有文件保护及缺失素材等行为。客户端中的显示与动画仍需 Mac 用户实机确认。

代码与素材许可分别见包内 `LICENSE`、`ASSET-NOTICE.md` 与 `CREDITS.md`。
