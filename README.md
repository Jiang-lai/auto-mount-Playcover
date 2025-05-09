# auto-mount-Playcover

> 使用 Hammerspoon 自动管理并挂载移动到外部硬盘的 PlayCover 游戏目录，解决 macOS 启动和设备插入后默认挂载路径不正确的问题。

---

## 功能特性

* **自动检测**：Hammerspoon 启动后或插入指定设备时自动执行挂载检查。
* **智能重挂载**：若目标卷已挂载但路径不正确，先卸载再挂载至用户配置的正确目录。
* **支持隐藏**：可配置 `nobrowse` 选项，避免卷出现在 Finder 侧边栏。
* **无感操作**：可通过 sudoers 设置，实现无密码、静默执行挂载与卸载。

---

## 前提条件

1. 已安装并配置 [Hammerspoon](https://www.hammerspoon.org/)。
2. PlayCover 游戏已移至外置硬盘，参考讨论： [https://github.com/PlayCover/PlayCover/discussions/1712](https://github.com/PlayCover/PlayCover/discussions/1712)
3. 外置卷格式为 APFS。
4. 已知目标卷的 **Partition UUID** 及期望挂载路径。

---

## 安装与配置

1. 克隆或下载本仓库：

   ```bash
   git clone https://github.com/Jiang-lai/auto-mount-Playcover.git
   ```
2. 将 `init.lua` 中的脚本内容追加到你本地的 `~/.hammerspoon/init.lua`：

   ```lua
   -- 在 init.lua 合适位置粘贴脚本
   ```
3. 打开脚本中的示例映射表，将其中的卷 UUID 与挂载路径替换为你的实际值：

   ```lua
   local volumeMappings = {
     { uuid = "<你的分区 UUID>", mountPoint = "/用户/你的路径" },
     -- …
   }
   ```
4. （可选）启用 USB 插入时重新挂载逻辑：

   ```lua
   -- 取消注释以下行：
   -- hs.usb.watcher.new(...):start()
   ```
5. 配置 **sudoers**，允许无密码执行挂载命令：

   ```bash
   sudo visudo -f /etc/sudoers.d/hammerspoon
   ```

   在打开的文件中添加：

   ```text
   <你的用户名> ALL=(root) NOPASSWD: /sbin/mount_apfs
   <你的用户名> ALL=(root) NOPASSWD: /usr/sbin/diskutil
   ```
6. 保存并退出，确保没有语法错误。

---

## 使用

1. 保存并重载 Hammerspoon 配置：

   ```lua
   -- 在 Hammerspoon 控制台执行：
   hs.reload()
   ```
2. 观察弹出通知或 Hammerspoon 控制台日志，确认以下操作：

   * 目标设备插入后检测到指定分区 UUID。
   * 如果未挂载或挂载路径不正确，自动卸载并重新挂载。
   * 脚本运行完成后，会弹出提示 `挂载监听器已启动`。

---

## 常见问题

* **为什么我的卷 UUID 在列表里找不到？**

  * 请执行 `diskutil list -plist` 并确认 `PartitionUUID`。
* **脚本找不到 **\`\`**？**

  * 请确认 `which mount_apfs` 输出 `/usr/bin/mount_apfs`。
* **挂载后仍在 Finder 侧边栏可见？**

  * 如果启用了 `nobrowse`，请重启 Finder 或取消该选项。

---

