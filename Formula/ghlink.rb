# Homebrew Formula: ghlink
# 用法: brew tap liwmj/ghlink && brew install ghlink
# tap 仓库: https://github.com/liwmj/homebrew-ghlink
# 参考: v0.2 安装包技术方案草案（brew 线：libexec + bin 入口 + launchd 模板）
#
# 修复记录（赛博接口复核 2026-08-14）：
# P1: 相对导入入口 —— 安装保持包结构 libexec/ghlink/，bin wrapper 用绝对导入
# P2: service 块移除 —— 用户级 launchd 写 /etc/hosts 会失败，官方值守统一走 ghlink enable

class Ghlink < Formula
  desc "GitHub 链路自愈工具：主动监控连通性，异常时自动换 IP 写 hosts，自检回滚 + 多渠道告警"
  homepage "https://github.com/liwmj/ghlink"
  url "https://github.com/liwmj/ghlink/archive/refs/tags/v0.2.7.tar.gz"
  sha256 "e5944acec2fca07d984cf61da98b8f406113442e90a532b2d97815b25d4319cf"
  license "MIT"
  head "https://github.com/liwmj/ghlink.git", branch: "master"

  depends_on "python@3.12"

  def install
    # 保持包结构安装到 libexec/ghlink/（解决 main.py 相对导入）
    (libexec/"ghlink").install Dir["src/ghlink/*.py"]
    libexec.install "config.example.json"

    # 托盘依赖（pystray + Pillow）仅注入安装包：pip 装到 libexec/vendor，核心源码保持零依赖
    py = Formula["python@3.12"].opt_bin/"python3.12"
    system py, "-m", "pip", "install", "--target", libexec/"vendor", "--quiet", "pystray", "Pillow"

    # bin 入口：绝对导入 wrapper（仿 ghlink_entry.py）+ PYTHONPATH 注入 libexec + vendor
    (bin/"ghlink").write <<~EOS
      #!/bin/bash
      export PYTHONPATH="#{libexec}:#{libexec}/vendor"
      exec "#{Formula["python@3.12"].opt_bin/"python3.12"}" -c \\
        "import sys; sys.path.insert(0, '#{libexec}/ghlink'); from ghlink.main import main; sys.exit(main())" "$@"
    EOS
    chmod 0755, bin/"ghlink"
  end

  test do
    assert_match "ghlink", shell_output("#{bin}/ghlink --version 2>&1")
  end
end
