# Homebrew Formula: ghlink
# 用法: brew install ghlink（本 formula 由 brew tap liwmj/ghlink 提供）
# 参考: v0.2 安装包技术方案草案（brew 线：libexec + bin 入口 + launchd 模板）
#
# 修复记录（赛博接口复核 2026-08-14）：
# P1: 相对导入入口 —— 安装保持包结构 libexec/ghlink/，bin wrapper 用绝对导入
# P2: service 块移除 —— 用户级 launchd 写 /etc/hosts 会失败，官方值守统一走 ghlink enable
# v0.4.6（顾笙 2026-08-23）：bump v0.2.18 → v0.4.6（李工发现 brew 停在 8 版本前）；
#   配置不预写 etc/（改由 enable 时 _ensure_config 从 libexec 模板自动生成），
#   brew uninstall 卸载后 etc/ghlink 无 brew 残留，无需手动删除

class Ghlink < Formula
  desc "GitHub 链路自愈工具：主动监控连通性，异常时自动换 IP 写 hosts，自检回滚 + 多渠道告警"
  homepage "https://github.com/liwmj/ghlink"
  url "https://github.com/liwmj/ghlink/archive/refs/tags/v0.4.6.tar.gz"
  sha256 "a0bf07fb3582dec37bb74b0dd9beb608c7ba0b0e43bc6c7640a3f9e14ab27968"
  license "MIT"
  head "https://github.com/liwmj/ghlink.git", branch: "master"

  depends_on "python@3.12"

  def install
    # 保持包结构安装到 libexec/ghlink/（解决 main.py 相对导入）
    (libexec/"ghlink").install Dir["src/ghlink/*.py"]
    libexec.install "config.example.json"

    # v0.2.17（李工 21:47 定）：托盘图标必须用 LOGO——补装 assets 图标
    # 到 libexec/assets/（_icon_path 已加 brew 路径候选），避免纯色回退
    (libexec/"assets").install Dir["assets/*"]

    # 托盘依赖（pystray + Pillow）仅注入安装包：pip 装到 libexec/vendor，核心源码保持零依赖
    py = formula_opt_bin("python@3.12")/"python3.12"
    system py, "-m", "pip", "install", "--target", libexec/"vendor", "--no-input",
           "--index-url", "https://pypi.tuna.tsinghua.edu.cn/simple", "pystray", "Pillow"

    # bin 入口：绝对导入 wrapper（仿 ghlink_entry.py）+ PYTHONPATH 注入 libexec + vendor
    (bin/"ghlink").write <<~EOS
      #!/bin/bash
      export PYTHONPATH="#{libexec}:#{libexec}/vendor"
      exec "#{py}" -m ghlink.main "$@"
    EOS
    chmod 0755, bin/"ghlink"
    # 不预写 etc/ghlink/config.json：enable 时 _ensure_config 自动从 libexec 模板生成，
    # 卸载后无配置残留（李工 2026-08-23 要求卸载即清）
  end

  def caveats
    <<~EOS
      ghlink 已安装。使用步骤：
        1. 启用值守: sudo ghlink enable   （自动生成配置 + 注册系统 LaunchDaemon，需 root 写 hosts）
        2. 查看状态: ghlink status
        3. 停用值守: sudo ghlink disable
      默认不自启（opt-in），enable 后才注册定时任务。
      配置由 enable 时自动生成（#{etc}/ghlink/config.json），卸载 brew 包后无残留。
      注意：值守需 root 权限（写 /etc/hosts），请用 sudo ghlink enable。
    EOS
  end

  test do
    assert_match "ghlink", shell_output("#{bin}/ghlink --version")
  end
end
