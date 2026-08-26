cask "ghlink" do
  version "0.5.9"
  sha256 "a8ee9abcdcc766f8f3d988c5b28aeba707cde80bf6c15fa808b1e5b8e8c6cab9"

  url "https://github.com/liwmj/ghlink/releases/download/v#{version}/ghlink-#{version}.dmg",
      verified: "github.com/liwmj/ghlink/"
  name "ghlink"
  desc "GitHub 链路自愈工具：主动监控连通性，异常时自动换 IP 写 hosts，自检回滚 + 多渠道告警"
  homepage "https://github.com/liwmj/ghlink"

  depends_on :macos

  app "ghlink.app"

  # v0.5.8（顾笙 00:03 实测定案：brew 移动 app 后双击报 -1712——LaunchServices
  # 数据库残留旧 bundle 记录，brew 装完不刷新 LS 缓存 → 双击启动失败）。
  # postflight 强制刷新 LS 注册，确保双击走新 bundle。
  postflight do
    lsreg = "/System/Library/Frameworks/CoreServices.framework/Frameworks/" \
            "LaunchServices.framework/Support/lsregister"
    system_command lsreg,
                   args: ["-f", "#{appdir}/ghlink.app"],
                   sudo: false
  end

  # v0.5.10（拂晓 02:15 实测：checksum 失败→软链没建→卸载脚本炸；ARM 机是
  # /opt/homebrew/bin 不是 /usr/local/bin）。卸载脚本做存在性判断幂等容错 +
  # 双架构路径自适应（Intel=/usr/local/bin，ARM=/opt/homebrew/bin）；
  # ghlink uninstall 内部自提权（sudo 失败回退 osascript 弹窗），sudo: false。
  uninstall script: {
    executable: "/bin/bash",
    args:       ["-c",
                 "if [ -x /opt/homebrew/bin/ghlink ]; then /opt/homebrew/bin/ghlink uninstall; " \
                 "elif [ -x /usr/local/bin/ghlink ]; then /usr/local/bin/ghlink uninstall; fi"],
    sudo:       false,
  }

  zap trash: [
    "/opt/homebrew/etc/ghlink",
    "/usr/local/etc/ghlink",
    "/var/lib/ghlink",
    "~/.ghlink",
    "~/Library/Application Support/ghlink",
    "~/Library/LaunchAgents/com.ghlink.tray.plist",
  ]
end
