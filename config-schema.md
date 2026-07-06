# Config Schema

DevLocalManager 使用兩份 config 檔案，分別管理「共享專案設定」與「個人本地設定」。

---

## project-config.yaml（共享）

團隊共享的專案設定檔，定義環境、repo 啟動規則與 Profile。

```yaml
name: "專案名稱"

environments:
  - id: lab                        # 環境唯一識別碼
    label: "Lab API"               # 顯示名稱
    description: "呼叫 Lab 環境 API"  # 描述說明

repos:
  - id: frontend-main             # repo 唯一識別碼
    name: "前端主站"                # 顯示名稱
    node_version: "18"             # 選填，啟動服務前自動執行 nvm use <version>
    environments:
      lab:                         # 對應 environments 中的 id
        services:                  # 必填，該環境下的服務列表
          - id: dev                # 服務唯一識別碼（repo 內唯一）
            label: "Dev Server"    # 服務顯示名稱
            command: "npm run dev" # 啟動指令
          - id: mock-server
            label: "Mock API"
            command: "npm run mock"
        pre_commands:              # 選填，啟動前執行的指令（第一版未啟用）
          - "npm install"
        env_file:                  # 選填，env 檔案變數異動
          path: ".env.development.local"
          variables:
            KEY: "value"

profiles:
  - id: all-lab                    # profile 唯一識別碼
    label: "全部 Lab"               # 按鈕顯示文字
    description: "所有服務呼叫 Lab API"  # 描述說明
    repos:                         # 各 repo 的啟動配置
      frontend-main:
        environment: lab           # 使用哪個環境
        services: [dev]            # 選填，指定啟動哪些服務（省略 = 全部啟動）
      shared-lib:
        environment: lab
    startup_order:                 # 啟動順序（依序執行）
      - shared-lib
      - frontend-main
```

### 欄位說明

| 欄位 | 必填 | 類型 | 說明 |
|------|------|------|------|
| `name` | 是 | string | 專案名稱，用於 App 顯示與內部識別 |
| **environments[]** | 是 | array | 環境定義列表 |
| `environments[].id` | 是 | string | 環境唯一識別碼，供 repos 和 profiles 引用 |
| `environments[].label` | 是 | string | 環境顯示名稱 |
| `environments[].description` | 否 | string | 環境描述 |
| **repos[]** | 是 | array | repo 定義列表 |
| `repos[].id` | 是 | string | repo 唯一識別碼 |
| `repos[].name` | 是 | string | repo 顯示名稱 |
| `repos[].node_version` | 否 | string | 指定 Node.js 版本，啟動服務前自動執行 `nvm use <version>` |
| `repos[].environments` | 是 | map | key 為 environment id，value 為該環境下的啟動設定 |
| `repos[].environments.<env>.services` | 是 | array | 服務列表，每個服務對應一條啟動指令 |
| `repos[].environments.<env>.services[].id` | 是 | string | 服務唯一識別碼（repo 內唯一） |
| `repos[].environments.<env>.services[].label` | 是 | string | 服務顯示名稱 |
| `repos[].environments.<env>.services[].command` | 是 | string | 啟動指令 |
| `repos[].environments.<env>.pre_commands` | 否 | string[] | 啟動前執行的指令（第一版保留，未啟用） |
| `repos[].environments.<env>.env_file` | 否 | object | env 檔案變數異動設定 |
| `repos[].environments.<env>.env_file.path` | 是* | string | env 檔案相對路徑（相對於 repo 根目錄） |
| `repos[].environments.<env>.env_file.variables` | 是* | map | 要寫入的變數（key-value），只修改指定變數，不覆蓋整個檔案 |
| **profiles[]** | 是 | array | Profile（按鈕）定義列表 |
| `profiles[].id` | 是 | string | profile 唯一識別碼 |
| `profiles[].label` | 是 | string | 按鈕顯示文字 |
| `profiles[].description` | 否 | string | 描述說明 |
| `profiles[].repos` | 是 | map | key 為 repo id，value 為啟動配置（environment + 可選 services） |
| `profiles[].repos.<repo>.environment` | 是 | string | 使用的環境 id |
| `profiles[].repos.<repo>.services` | 否 | string[] | 指定啟動的服務 id 列表，省略表示啟動該環境下所有服務 |
| `profiles[].startup_order` | 是 | string[] | 啟動順序，元素為 repo id，依序啟動 |

> *標記為「是*」的欄位：當 `env_file` 存在時為必填。

### 欄位關聯

- `profiles[].repos` 的 **key** 必須對應某個 `repos[].id`
- `profiles[].repos.<repo>.environment` 必須對應某個 `environments[].id`
- `profiles[].repos.<repo>.services` 的元素必須對應該 repo 在該環境下 `services[].id`
- `profiles[].startup_order` 的元素必須對應 `profiles[].repos` 中的 key
- `repos[].environments` 的 **key** 必須對應某個 `environments[].id`

---

## local-settings.yaml（個人）

個人本地設定，不需要共享。App 啟動時自動讀取，存放於 `~/Library/Application Support/LocalDevTools/settings.yaml`。

```yaml
terminal: "iterm2"              # 選填，預設 terminal。可選值：terminal, iterm2
skip_switch_alert: false        # 選填，切換 Profile 時是否跳過確認提醒

repo_paths:                     # 各專案的 repo 本地路徑
  "專案名稱":
    repo-id: "/Users/xxx/projects/repo-name"
    another-repo: "/Users/xxx/projects/another"
```

### 欄位說明

| 欄位 | 必填 | 類型 | 說明 |
|------|------|------|------|
| `terminal` | 否 | string | 使用的 Terminal App，可選值：`terminal`（Terminal.app）、`iterm2`（iTerm2），預設 `terminal` |
| `skip_switch_alert` | 否 | boolean | 切換 Profile 時跳過確認提醒，預設 `false` |
| `repo_paths` | 否 | map | 巢狀結構：第一層 key 為專案名稱（對應 project-config 的 `name`），第二層 key 為 repo id，value 為本地絕對路徑 |

---

## 儲存結構

```
~/Library/Application Support/LocalDevTools/
├── settings.yaml              # 本地設定
└── projects/
    ├── my-project.yaml        # 匯入的 project config（副本）
    └── another-project.yaml
```

匯入時 App 會將 project-config.yaml 複製到 `projects/` 目錄下，後續讀取自己持有的副本。更新 config 時重新匯入即可覆蓋。
