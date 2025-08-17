# Pickit 意見回饋系統設計文檔

## 系統架構概覽

### 目標
建立一個簡單、高效的用戶意見收集系統，使用 Google Sheets 作為資料庫，讓用戶能夠直接在插件內提交意見，協助 Pickit 持續改進。

### 核心功能
1. **插件內意見提交** - 用戶無需離開 Lightroom 即可提交意見
2. **自動分類** - 根據意見類型自動分類（功能建議、錯誤回報、使用體驗）
3. **匿名/實名選擇** - 用戶可選擇是否提供聯絡資訊
4. **即時同步** - 意見直接寫入 Google Sheets
5. **回饋追蹤** - 開發團隊可在 Google Sheets 中管理和回應

## Google Sheets 資料庫設計

### 表格結構

| 欄位名稱 | 資料類型 | 說明 | 範例 |
|---------|---------|------|------|
| submission_id | TEXT | 唯一識別碼 | FB20250120001 |
| timestamp | DATETIME | 提交時間 | 2025-01-20 14:30:00 |
| plugin_version | TEXT | 插件版本 | 1.0.0 |
| lightroom_version | TEXT | Lightroom 版本 | 12.0 |
| os_info | TEXT | 操作系統 | macOS 14.0 |
| feedback_type | TEXT | 意見類型 | feature_request |
| category | TEXT | 細分類別 | ui_improvement |
| rating | NUMBER | 滿意度評分(1-5) | 4 |
| title | TEXT | 意見標題 | 建議增加批次導出功能 |
| description | TEXT | 詳細描述 | 希望能夠... |
| user_name | TEXT | 用戶名稱（選填） | 張三 |
| user_email | TEXT | 電子郵件（選填） | user@example.com |
| contact_permission | BOOLEAN | 允許聯絡 | TRUE |
| screenshot_url | TEXT | 截圖連結（選填） | https://... |
| device_info | TEXT | 設備資訊 | MacBook Pro M1 |
| usage_frequency | TEXT | 使用頻率 | daily |
| professional_level | TEXT | 專業程度 | professional |
| status | TEXT | 處理狀態 | pending |
| team_notes | TEXT | 團隊備註 | 已納入 v1.1 計劃 |
| response | TEXT | 官方回覆 | 感謝您的建議... |

### 意見類型分類

```lua
FEEDBACK_TYPES = {
    feature_request = "功能建議",
    bug_report = "錯誤回報", 
    performance_issue = "性能問題",
    ui_feedback = "界面意見",
    workflow_suggestion = "工作流程建議",
    general_feedback = "一般意見",
    praise = "讚賞鼓勵"
}
```

## 技術實現方案

### 1. Google Sheets API 整合

使用 Google Sheets API v4 實現數據讀寫：

```javascript
// Node.js Bridge Server 端
const { google } = require('googleapis');

class FeedbackService {
    constructor() {
        this.auth = new google.auth.GoogleAuth({
            keyFile: 'credentials.json',
            scopes: ['https://www.googleapis.com/auth/spreadsheets']
        });
        
        this.sheets = google.sheets({ version: 'v4', auth: this.auth });
        this.spreadsheetId = process.env.FEEDBACK_SHEET_ID;
    }
    
    async submitFeedback(feedbackData) {
        const values = [
            [
                generateId(),
                new Date().toISOString(),
                feedbackData.pluginVersion,
                feedbackData.lightroomVersion,
                feedbackData.osInfo,
                feedbackData.feedbackType,
                feedbackData.category,
                feedbackData.rating,
                feedbackData.title,
                feedbackData.description,
                feedbackData.userName || '',
                feedbackData.userEmail || '',
                feedbackData.contactPermission || false,
                feedbackData.screenshotUrl || '',
                feedbackData.deviceInfo,
                feedbackData.usageFrequency,
                feedbackData.professionalLevel,
                'pending',
                '',
                ''
            ]
        ];
        
        const response = await this.sheets.spreadsheets.values.append({
            spreadsheetId: this.spreadsheetId,
            range: 'Feedback!A:T',
            valueInputOption: 'USER_ENTERED',
            insertDataOption: 'INSERT_ROWS',
            resource: { values }
        });
        
        return response.data;
    }
}
```

### 2. Lua 插件端實現

```lua
-- src/feedback/FeedbackManager.lua
local FeedbackManager = {}

function FeedbackManager:initialize()
    self.nodebridge = require('src/models/NodeBridge')
    self.logger = require('src/utils/Logger'):new("FeedbackManager")
    return self
end

function FeedbackManager:submitFeedback(feedbackData)
    -- 添加系統資訊
    feedbackData.pluginVersion = "1.0.0"
    feedbackData.lightroomVersion = LrApplication.versionString()
    feedbackData.osInfo = LrSystemInfo.osVersion()
    feedbackData.deviceInfo = LrSystemInfo.computerName()
    
    -- 發送到 Node.js Bridge
    local success, result = self.nodebridge:post('/feedback/submit', feedbackData)
    
    if success then
        self.logger:info("Feedback submitted successfully")
        return true, result.submissionId
    else
        self.logger:error("Failed to submit feedback: " .. tostring(result))
        return false, result
    end
end

return FeedbackManager
```

### 3. UI 界面設計

```lua
-- src/ui/FeedbackDialog.lua
local FeedbackDialog = {}

function FeedbackDialog.show()
    local LrDialogs = import 'LrDialogs'
    local LrView = import 'LrView'
    local LrBinding = import 'LrBinding'
    
    local f = LrView.osFactory()
    local properties = LrBinding.makePropertyTable(context)
    
    -- 預設值
    properties.feedbackType = "general_feedback"
    properties.rating = 3
    properties.allowContact = false
    
    local contents = f:column {
        spacing = f:control_spacing(),
        
        -- 標題
        f:static_text {
            title = "Pickit 意見回饋",
            font = "<system/bold>",
            size = "regular"
        },
        
        -- 意見類型
        f:row {
            f:static_text { title = "意見類型:", width = 100 },
            f:popup_menu {
                bind_to_object = properties,
                value = LrView.bind("feedbackType"),
                items = {
                    { title = "功能建議", value = "feature_request" },
                    { title = "錯誤回報", value = "bug_report" },
                    { title = "性能問題", value = "performance_issue" },
                    { title = "界面意見", value = "ui_feedback" },
                    { title = "工作流程建議", value = "workflow_suggestion" },
                    { title = "一般意見", value = "general_feedback" },
                    { title = "讚賞鼓勵", value = "praise" }
                }
            }
        },
        
        -- 滿意度評分
        f:row {
            f:static_text { title = "整體滿意度:", width = 100 },
            f:slider {
                bind_to_object = properties,
                value = LrView.bind("rating"),
                min = 1,
                max = 5,
                integral = true,
                width = 200
            },
            f:static_text {
                bind_to_object = properties,
                title = LrView.bind("rating")
            }
        },
        
        -- 標題
        f:row {
            f:static_text { title = "標題:", width = 100 },
            f:edit_field {
                bind_to_object = properties,
                value = LrView.bind("title"),
                width = 300,
                immediate = true
            }
        },
        
        -- 詳細描述
        f:row {
            f:static_text { 
                title = "詳細描述:", 
                width = 100,
                alignment = "left"
            },
            f:scrolled_view {
                width = 300,
                height = 150,
                f:edit_field {
                    bind_to_object = properties,
                    value = LrView.bind("description"),
                    width = 290,
                    height = 140
                }
            }
        },
        
        -- 使用頻率
        f:row {
            f:static_text { title = "使用頻率:", width = 100 },
            f:popup_menu {
                bind_to_object = properties,
                value = LrView.bind("usageFrequency"),
                items = {
                    { title = "每天", value = "daily" },
                    { title = "每週數次", value = "weekly" },
                    { title = "每月數次", value = "monthly" },
                    { title = "偶爾", value = "occasionally" }
                }
            }
        },
        
        -- 專業程度
        f:row {
            f:static_text { title = "您是:", width = 100 },
            f:popup_menu {
                bind_to_object = properties,
                value = LrView.bind("professionalLevel"),
                items = {
                    { title = "專業攝影師", value = "professional" },
                    { title = "半專業攝影師", value = "semi_professional" },
                    { title = "攝影愛好者", value = "enthusiast" },
                    { title = "初學者", value = "beginner" }
                }
            }
        },
        
        -- 聯絡資訊（選填）
        f:separator { fill_horizontal = 1 },
        
        f:checkbox {
            bind_to_object = properties,
            value = LrView.bind("allowContact"),
            title = "願意接收回覆（選填）"
        },
        
        f:row {
            f:static_text { 
                title = "姓名:", 
                width = 100,
                enabled = LrView.bind("allowContact")
            },
            f:edit_field {
                bind_to_object = properties,
                value = LrView.bind("userName"),
                width = 200,
                enabled = LrView.bind("allowContact")
            }
        },
        
        f:row {
            f:static_text { 
                title = "Email:", 
                width = 100,
                enabled = LrView.bind("allowContact")
            },
            f:edit_field {
                bind_to_object = properties,
                value = LrView.bind("userEmail"),
                width = 200,
                enabled = LrView.bind("allowContact"),
                placeholder = "your@email.com"
            }
        },
        
        -- 隱私聲明
        f:static_text {
            title = "您的意見對我們非常重要。所有資料將被安全儲存並僅用於改進 Pickit。",
            font = "<system/small>",
            text_color = LrColor(0.5, 0.5, 0.5)
        }
    }
    
    local result = LrDialogs.presentModalDialog {
        title = "Pickit 意見回饋",
        contents = contents,
        actionVerb = "提交"
    }
    
    if result == "ok" then
        -- 提交意見
        local feedbackManager = require('src/feedback/FeedbackManager'):initialize()
        local success, submissionId = feedbackManager:submitFeedback(properties)
        
        if success then
            LrDialogs.message(
                "感謝您的意見！",
                "您的意見已成功提交。\n提交編號: " .. submissionId .. 
                "\n\n我們會仔細閱讀每一條意見，並持續改進 Pickit。",
                "info"
            )
        else
            LrDialogs.message(
                "提交失敗",
                "抱歉，意見提交失敗。請稍後再試或直接聯絡 support@pickit.ai",
                "error"
            )
        end
    end
end

return FeedbackDialog
```

## 數據分析與管理

### Google Sheets 儀表板

在 Google Sheets 中建立以下工作表：

1. **Feedback** - 原始數據存儲
2. **Dashboard** - 數據可視化儀表板
3. **Statistics** - 統計分析
4. **Responses** - 官方回覆模板

### 自動化功能

使用 Google Apps Script 實現：

```javascript
// Google Apps Script
function onFeedbackSubmit(e) {
    // 自動發送通知郵件給開發團隊
    if (e.values[5] === 'bug_report') {
        sendBugAlert(e.values);
    }
    
    // 自動分類和標記優先級
    categorizeAndPrioritize(e.values);
    
    // 更新統計數據
    updateStatistics();
}

function sendBugAlert(feedbackData) {
    MailApp.sendEmail({
        to: 'dev@pickit.ai',
        subject: '[Pickit] 新的錯誤回報',
        body: formatBugReport(feedbackData)
    });
}
```

## 實施計劃

### 第一階段：基礎功能（1週）
1. ✅ 建立 Google Sheets 資料庫
2. ✅ 實現 Node.js API 端點
3. ✅ 開發 Lua 提交模組
4. ✅ 創建基本 UI 界面

### 第二階段：進階功能（1週）
1. ⬜ 添加截圖上傳功能
2. ⬜ 實現離線緩存機制
3. ⬜ 開發回饋查看功能
4. ⬜ 添加使用統計收集

### 第三階段：分析優化（持續）
1. ⬜ 建立數據分析儀表板
2. ⬜ 設置自動化回應系統
3. ⬜ 實現意見趨勢分析
4. ⬜ 開發用戶滿意度報告

## 安全與隱私

### 數據保護措施
1. **加密傳輸** - HTTPS 協議
2. **訪問控制** - Google Sheets 權限管理
3. **數據最小化** - 僅收集必要資訊
4. **匿名選項** - 用戶可選擇匿名提交
5. **GDPR 合規** - 遵守數據保護法規

### API 密鑰管理
```javascript
// .env 文件
GOOGLE_SHEETS_API_KEY=your_api_key_here
FEEDBACK_SHEET_ID=your_sheet_id_here
SERVICE_ACCOUNT_EMAIL=your_service_account@project.iam.gserviceaccount.com
```

## 成功指標

### KPI 設定
- **提交率**: 月活躍用戶的 15% 提交意見
- **響應時間**: 48 小時內回覆所有錯誤回報
- **滿意度**: 平均評分 ≥ 4.0
- **實施率**: 30% 的功能建議在 3 個月內實現

### 監控指標
- 每日/週/月意見數量
- 各類型意見分布
- 用戶滿意度趨勢
- 回覆率和響應時間
- 功能實施追蹤

## 用戶價值

### 對用戶的好處
1. **直接影響產品發展** - 意見直接影響功能開發
2. **快速問題解決** - 錯誤能夠快速修復
3. **持續改進** - 產品不斷優化
4. **社群參與感** - 成為 Pickit 發展的一部分

### 對開發團隊的好處
1. **真實用戶洞察** - 了解實際使用需求
2. **優先級指導** - 基於數據決定開發優先級
3. **品質提升** - 快速發現和修復問題
4. **用戶關係** - 建立良好的用戶關係

---

*此意見回饋系統將成為 Pickit 持續改進的核心驅動力，確保產品始終符合專業攝影師的實際需求。*