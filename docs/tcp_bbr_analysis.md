# TCP BBR 擁塞控制優化：反效果、注意事項與最佳實踐

## 背景

BBR（Bottleneck Bandwidth and Round-trip propagation time）是 Google 於 2016 年提出的 TCP 擁塞控制演算法，透過主動估測網路瓶頸頻寬與 RTT 來控制發送速率，而非像傳統 CUBIC 演算法一樣依賴「丟包 = 壅塞」的假設。

---

## 1. 潛在反效果與風險

### 1.1 與 CUBIC 共存的公平性問題（主要風險）

BBR 在與 Linux 預設的 CUBIC（基於丟包的演算法）共享同一條頻寬瓶頸時，**BBR 流量會表現得明顯更具侵略性**，擠壓 CUBIC 流量的可用頻寬。

- **淺緩衝區（Shallow Buffer）環境**：BBR 可能導致 CUBIC 流量幾乎被餓死（Starvation）。
- **深緩衝區（Deep Buffer）環境**：差異較不顯著，但 BBR 仍傾向佔據更多頻寬。

> [!WARNING]
> 若您的 Debian 機器與其他使用 CUBIC 的設備共享同一條頻寬有限的出口線路（例如共用辦公室路由器），啟用 BBR 可能導致其他設備的連線品質下降。

### 1.2 重傳率 (Retransmission) 可能上升

BBR 不將偶發性丟包視為壅塞訊號，因此不會像 CUBIC 那樣在丟包時大幅降低發送速率。在**高丟包率的網路環境**中（例如無線網路、跨國 VPN），BBR 可能產生更多不必要的重傳封包。

### 1.3 CPU 開銷

BBR 內部使用高解析度定時器（High-Resolution Timer）進行封包 pacing。**若未正確搭配 `fq`（Fair Queuing）排隊規則**，CPU 使用率會明顯上升，在高流量伺服器上尤其顯著。

### 1.4 App-Limited 場景的效能波動

在應用程式本身傳輸量較小或間歇性傳輸的場景下，BBR 可能誤判瓶頸頻寬，導致效能不穩定甚至低於 CUBIC。

---

## 2. BBR 版本現況

| 版本 | Linux Kernel 支援 | 狀態 |
|------|-------------------|------|
| BBRv1 | **4.9+（主線內建）** | 所有標準發行版直接可用 |
| BBRv2 | 未合併主線 | 已廢棄，被 BBRv3 取代 |
| BBRv3 | 未合併主線 | 需自行 Patch 編譯核心 |

> [!IMPORTANT]
> Debian Trixie 搭載 Linux Kernel 6.12 LTS，其內建的 `tcp_bbr` 模組為 **BBRv1**。BBRv3 雖大幅改善了公平性問題，但目前仍未合併進主線核心，需要自行編譯方可使用。

---

## 3. 最佳實踐

### 3.1 必須搭配 `fq` 排隊規則（已實作）

BBR 的 pacing 機制依賴 `fq` 來正確調度封包。**這是 BBR 部署的硬性前提條件**。

```bash
net.core.default_qdisc = fq
```

目前 `init.sh` 已正確實作此項。

### 3.2 適用場景評估

BBR 最適合的場景：

- **伺服器對外提供服務**（Web Server、API Server、CDN Edge）：BBR 能有效降低延遲並提高吞吐量。
- **長距離 / 高 RTT 連線**：跨國或跨區域傳輸時，BBR 的優勢最為明顯。
- **獨享頻寬的環境**：VPS、Cloud VM 等擁有獨立網路介面的場景最適合。

BBR 需要謹慎評估的場景：

- **共享頻寬的區域網路**：多台設備共用同一條出口線路，且其他設備使用 CUBIC。
- **高丟包率的無線網路環境**：可能觸發大量不必要的重傳。

### 3.3 部署前應進行基準測試

在正式環境啟用前，建議使用 `iperf3` 進行基準測試，比較啟用前後的吞吐量與延遲表現：

```bash
# 伺服端
iperf3 -s

# 客戶端（測試 BBR 效果）
iperf3 -c <server-ip> -t 30
```

### 3.4 可選：啟用 ECN（Explicit Congestion Notification）

搭配 ECN 可讓支援的路由器在緩衝區即將滿載時主動通知端點，而非直接丟棄封包：

```bash
net.ipv4.tcp_ecn = 1
```

---

## 4. 對目前 `init.sh` 實作的評估

| 項目 | 現況 | 評估 |
|------|------|------|
| `fq` qdisc 設定 | 已實作 | 正確，為 BBR 硬性前提 |
| BBR 版本 | BBRv1（Kernel 6.12 內建） | 可接受，主線唯一選項 |
| 冪等性檢查 | 已實作 | 正確，不會重複套用 |
| 公平性風險 | 未特別處理 | 在獨享頻寬的 VPS/Cloud 環境下可忽略 |

### 結論

→ 目前 `init.sh` 的 BBR 實作方式是正確且合理的，適用於大多數 Debian 伺服器（VPS / Cloud VM）的使用場景。
→ 若您的機器是部署在**共享區域網路**（例如辦公室內網多台設備共用出口），可考慮移除 BBR 或保持 CUBIC 預設值。
