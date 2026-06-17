#!/bin/sh

echo "[*] Stopping malicious processes..."

# 1. 杀掉挖矿 / 后门进程
pkill -f xmrig 2>/dev/null
pkill -f syslog-monitor 2>/dev/null
pkill -f "/tmp/.nz" 2>/dev/null
pkill -f "/tmp/.x" 2>/dev/null

echo "[*] Removing systemd miner service..."

# 2. 删除 systemd 持久化服务
systemctl stop syslog-monitor 2>/dev/null
systemctl disable syslog-monitor 2>/dev/null
rm -f /etc/systemd/system/syslog-monitor.service
rm -f /etc/systemd/system/multi-user.target.wants/syslog-monitor.service
systemctl daemon-reload 2>/dev/null
systemctl reset-failed 2>/dev/null

echo "[*] Cleaning cron persistence..."

# 3. 清理 cron（关键持久化点）
crontab -l 2>/dev/null | grep -v "nz-implant" | grep -v "curl.*implant" | crontab - 2>/dev/null

# root cron file
if [ -f /var/spool/cron/root ]; then
  grep -v "nz-implant" /var/spool/cron/root > /tmp/cron_clean
  cat /tmp/cron_clean > /var/spool/cron/root
fi

# /etc/crontab
if [ -f /etc/crontab ]; then
  sed -i '/nz-implant/d' /etc/crontab
  sed -i '/152.42.182.35/d' /etc/crontab
  sed -i '/implant.sh/d' /etc/crontab
fi

echo "[*] Removing malicious files..."

# 4. 删除落地文件
rm -rf /tmp/.nz
rm -rf /tmp/.x
rm -f /usr/local/bin/syslog-monitor

echo "[*] Killing residual connections..."

# 5. 杀残留 curl / sh 下载链
pkill -f "152.42.182.35" 2>/dev/null
pkill -f "payloads" 2>/dev/null

echo "[*] Cleaning possible xmrig binaries..."

# 6. 常见挖矿路径扫描清理
find /usr /usr/local /tmp /var/tmp -type f -name "xmrig" -exec rm -f {} \; 2>/dev/null
find / -type f -name "*syslog-monitor*" -exec rm -f {} \; 2>/dev/null 2>/dev/null

echo "[*] Done. Please reboot system."
