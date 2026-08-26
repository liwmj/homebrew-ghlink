cask "ghlink" do
  version "0.5.11"
  sha256 "b86ec4db7de32485da33b38138db4f100a7be285938f0358067815a16132bdf0"

  url "https://github.com/liwmj/ghlink/releases/download/v#{version}/ghlink-#{version}.dmg",
      verified: "github.com/liwmj/ghlink/"
  name "ghlink"
  desc "GitHub 链路自愈工具：主动监控连通性，异常时自动换 IP 写 hosts，自检回滚 + 多渠道告警"
  homepage "https://github.com/liwmj/ghlink"

  depends_on :macos

  app "ghlink.app"

  # v0.5.8（顾笙 00:03 实测定案）：brew 移动 app 后双击报 -1712——LaunchServices
  # 数据库残留旧 bundle 记录，brew 装完不刷新 LS 缓存 → 双击启动失败。
  # postflight 强制刷新 LS 注册，确保双击走新 bundle。
  postflight do
    lsreg = "/System/Library/Frameworks/CoreServices.framework/Frameworks/" \
            "LaunchServices.framework/Support/lsregister"
    system_command lsreg,
                   args: ["-f", "#{appdir}/ghlink.app"],
                   sudo: false
  end

  # v0.5.11（赛博 02:50 根因 + 李工 02:48 实测）：CI 发版 sync 曾用写死路径模板覆盖
  # 容错修复 → brew 卸载报 "uninstall script /usr/local/bin/ghlink does not exist"
  # （软链靠 app 首启才建，brew install 后未首启即缺失）。uninstall script 改
  # /bin/bash -c 容错版：双架构路径自适应（ARM=/opt/homebrew，Intel=/usr/local）+
  # 存在性判断，软链缺失时静默跳过不炸；ghlink uninstall 内部自提权（sudo: false）。
  # 合并定案（李工 02:48 质疑 + 赛博 03:23 核实）：/bin/bash -c 双架构容错 +
  # sudo: true——brew 用 sudo 跑 ghlink uninstall（密码在终端正常输入），root 执行
  # 后 _uninstall_self_elevate 检测 root 直返 None 不再嵌套 sudo；软链缺失静默跳过。
  uninstall script: {
    executable: "/bin/bash",
    args:       ["-c",
                 "if [ -x /opt/homebrew/bin/ghlink ]; then /opt/homebrew/bin/ghlink uninstall; " \
                 "elif [ -x /usr/local/bin/ghlink ]; then /usr/local/bin/ghlink uninstall; fi"],
    sudo:       true,
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
