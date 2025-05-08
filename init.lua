-- Hammerspoon 脚本：Hammerspoon启动或连接设备后自动挂载 APFS 卷

-- 定义需要挂载的卷信息：包含卷 UUID、期望挂载路径
local volumeMappings = {
    -- 卷 UUID  -> 挂载路径
    -- 请自行修改为您实际的卷UUID以及期望挂载路径
    -- 崩坏:星穹铁道
    { uuid = "D8A6ED7A-4666-42BF-855A-BC8D298A0317", mountPoint = "/Users/username/Library/Containers/com.miHoYo.hkrpg" },
    -- 崩坏3 (从App Store安装，路径为系统自动生成，请自行修改)
    { uuid = "956CBF59-E2C7-41F7-8688-500ABA61B74B", mountPoint = "/Users/username/Library/Containers/DAD8543B-922E-42E2-AFCE-C2CF8D229947" },
    -- 绝区零
    { uuid = "40CC7285-6035-4BCF-84DB-8D257A08BC0E", mountPoint = "/Users/username/Library/Containers/com.miHoYo.Nap" }
}

-- 执行挂载逻辑：检查设备和挂载卷
local function checkAndMountVolumes()

    -- 获取当前已挂载的卷信息（包括隐藏卷）
    local mounted = hs.fs.volume.allVolumes(true)

    -- 遍历每个目标卷，执行挂载逻辑
    for _, vol in ipairs(volumeMappings) do
        local foundPath = nil
        for path, info in pairs(mounted) do
            -- 根据卷的 UUID 匹配已挂载卷
            if info["NSURLVolumeUUIDStringKey"] == vol.uuid then
                foundPath = path
                break
            end
        end

        if foundPath then
            -- 如果卷已挂载但路径不正确，则先卸载再重新挂载
            if foundPath ~= vol.mountPoint then
                hs.alert.show(string.format("卷 %s 挂载路径不匹配，重新挂载", vol.uuid))
                hs.execute(string.format("sudo diskutil unmount '%s'", foundPath))
                foundPath = nil  -- 标记为未挂载，以便后续挂载
            else
                -- 已经挂载在正确路径，跳过
                hs.alert.show(string.format("卷 %s 已挂载在正确路径", vol.uuid))
            end
        end

        if not foundPath then
            -- 卷未挂载：进行挂载
            -- 需要获取卷的设备节点 (/dev/diskXsY)
            -- 使用 diskutil info 获取 Volume 对应的 Device Node
            local infoOut, infoOk = hs.execute(
                string.format("diskutil info -plist %s", vol.uuid), true)
            local devNode = nil
            if infoOk and infoOut then
                local infoPlist = hs.plist.readString(infoOut)
                if infoPlist then
                    devNode = infoPlist["DeviceIdentifier"]
                end
            end
            if not devNode then
                -- 有时 diskutil info 可直接使用卷 UUID 或名称查询
                -- 如果以上失败，可尝试用名称查询
                -- local infoOk2, infoOut2 = hs.execute(string.format("diskutil info -plist %s", vol.name), true)
                -- ...
                hs.alert.show("无法获取卷 " .. vol.uuid .. " 的设备节点")
            else
                -- 拼接完整设备节点路径
                local deviceNode = "/dev/" .. devNode
                -- 执行挂载命令（读写，可选 nobrowse 隐藏）
                local cmd = string.format(
                    "sudo mount_apfs -o rw,nobrowse '%s' '%s'",
                    deviceNode, vol.mountPoint)
                hs.execute(cmd)
                hs.alert.show(string.format("已挂载卷 %s 到 %s", vol.uuid, vol.mountPoint))
            end
        end
    end
end

-- 初始运行：Hammerspoon 启动时立即执行一次检查挂载
checkAndMountVolumes()

-- 设备插入监听：USB 插入时重新执行挂载逻辑（若需要可启用）
-- hs.usb.watcher.new(function(data)
--     if data["eventType"] == "added" then
--         -- 当任何 USB 设备插入时，尝试挂载
--         hs.timer.doAfter(1, checkAndMountVolumes)
--     end
-- end):start()

-- 可选：卷挂载监听器，检测新卷挂载后触发（若需要可启用）
-- hs.fs.volume.new(function(eventType, info)
--     if eventType == hs.fs.volume.didMount then
--         checkAndMountVolumes()
--     end
-- end):start()

-- 提示完成
hs.alert.show("挂载监听器已启动")
