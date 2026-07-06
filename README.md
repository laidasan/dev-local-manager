# DevLocalManager

macOS 視窗型工具（Swift + SwiftUI），用於簡化多 repo 專案的 local 開發環境啟動流程。

## 解決什麼問題

多 repo 專案在 local 開發時，需要手動逐一啟動各服務、切換環境變數。這個工具讓你：

- 一鍵啟動所有依賴服務
- 支援 Lab / Mock 環境切換，也支援混合配置（A 用 Lab、B 用 Mock）
- 自動處理 env 變數異動，不需要手動改 `.env` 檔
- 一鍵停止所有服務

## 安裝

```bash
brew tap laidasan/tap
brew trust laidasan/tap
brew install --cask dev-local-manager
```

更新至最新版：

```bash
brew upgrade --cask dev-local-manager
```

解除安裝：

```bash
brew uninstall --cask dev-local-manager
```

## 使用流程

1. 撰寫專案的 `project-config.yaml`（參考下方 Config 說明）
2. 開啟 App → 匯入 config
3. 進入 Settings，設定各 repo 的本地路徑
4. 回到主畫面，點選 Profile 按鈕啟動服務
5. 結束時點「全部停止」

## Config

專案使用兩份設定檔：

| 檔案 | 用途 | 共享方式 |
|------|------|----------|
| `project-config.yaml` | 定義環境、repo 啟動規則、Profile | 團隊共享 |
| `local-settings.yaml` | Terminal 偏好、repo 本地路徑 | 個人私有，App 自動管理 |

- 完整欄位說明：[config-schema.md](config-schema.md)
- 範例檔案：[example-config.yaml](example-config.yaml)

## 開發

### 環境需求

- macOS 14+
- Xcode 15+
- Swift Package Manager（自動管理依賴）

### 依賴

- [Yams](https://github.com/jpsim/Yams) — YAML parser

### Build & Run

1. 開啟 `DevLocalManager.xcodeproj`
2. 確認 Target 為 `DevLocalManager` > `My Mac`
3. `⌘R` 執行

### 專案結構

```
DevLocalManager/
├── App/                  # App 進入點
├── Models/               # 資料模型（ProjectConfig, LocalSettings, RunningSession）
├── Services/             # 核心服務（Config 解析、Env 處理、Terminal 操作、Process 管理）
├── ViewModels/           # 畫面邏輯
├── Views/                # SwiftUI 畫面
└── Resources/            # Entitlements 等資源
```
