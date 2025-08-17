# Pickit - Google Sheets 意見回饋系統設置指南

## 快速設置步驟

### 步驟 1: Google Sheets 設置

**您的試算表已創建完成！**
- 試算表名稱: Pickit Feedback Database
- 試算表 ID: `1kSqxDK39h-yncxnJzliDS-cec_1BnxjilJlS88cBkjw`
- 試算表連結: [開啟 Pickit Feedback Database](https://docs.google.com/spreadsheets/d/1kSqxDK39h-yncxnJzliDS-cec_1BnxjilJlS88cBkjw)

### 步驟 2: 設置試算表結構

在第一個工作表（命名為 "Feedback"）中，添加以下標題行：

| A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Submission ID | Timestamp | Plugin Version | Lightroom Version | OS Info | Feedback Type | Category | Rating | Title | Description | User Name | User Email | Contact Permission | Screenshot URL | Device Info | Usage Frequency | Professional Level | Status | Team Notes | Response |

### 步驟 3: 啟用 Google Sheets API

1. 訪問 [Google Cloud Console](https://console.cloud.google.com)
2. 創建新項目或選擇現有項目
3. 啟用 Google Sheets API：
   - 導航到 "API 和服務" > "啟用 API 和服務"
   - 搜索 "Google Sheets API"
   - 點擊 "啟用"

### 步驟 4: 創建服務帳戶

1. 在 Google Cloud Console 中：
   - 導航到 "API 和服務" > "憑證"
   - 點擊 "創建憑證" > "服務帳戶"
   
2. 填寫服務帳戶詳情：
   - 名稱: `pickit-feedback-service`
   - ID: `pickit-feedback-service`
   - 描述: Pickit feedback submission service

3. 授予角色：
   - 選擇 "編輯者" 角色

4. 創建密鑰：
   - 點擊服務帳戶
   - 選擇 "密鑰" 標籤
   - 點擊 "新增密鑰" > "創建新密鑰"
   - 選擇 JSON 格式
   - 下載密鑰文件

### 步驟 5: 共享試算表

1. 打開您的 Google Sheets
2. 點擊右上角的 "共享"
3. 輸入服務帳戶的電子郵件地址：
   `pickit-feedback-service@your-project-id.iam.gserviceaccount.com`
4. 授予 "編輯者" 權限

### 步驟 6: 配置 Node.js 服務器

1. 將下載的 JSON 密鑰文件重命名為 `credentials.json`
2. 放置到 `node-bridge/` 目錄
3. 創建 `.env` 文件：

```env
# Google Sheets Configuration
FEEDBACK_SHEET_ID=1kSqxDK39h-yncxnJzliDS-cec_1BnxjilJlS88cBkjw
GOOGLE_PROJECT_ID=your-project-id
GOOGLE_CLIENT_EMAIL=pickit-feedback-service@your-project-id.iam.gserviceaccount.com

# Optional: If not using credentials.json file
GOOGLE_PRIVATE_KEY_ID=your_private_key_id
GOOGLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CERT_URL=https://www.googleapis.com/robot/v1/metadata/x509/your-service-account-email
```

### 步驟 7: 安裝依賴

```bash
cd LightroomAISelector/node-bridge
npm install googleapis
```

### 步驟 8: 測試連接

```bash
# 啟動服務器
npm start

# 測試提交
curl -X POST http://localhost:3000/feedback/submit \
  -H "Content-Type: application/json" \
  -d '{
    "feedbackType": "general_feedback",
    "rating": 5,
    "title": "測試提交",
    "description": "這是一個測試提交"
  }'
```

## Google Apps Script 自動化（選用）

### 創建自動化腳本

1. 在 Google Sheets 中，選擇 "擴充功能" > "Apps Script"
2. 添加以下腳本：

```javascript
// 當有新提交時自動執行
function onFormSubmit(e) {
  const row = e.range.getRow();
  const sheet = e.range.getSheet();
  
  // 獲取提交數據
  const feedbackType = sheet.getRange(row, 6).getValue();
  const rating = sheet.getRange(row, 8).getValue();
  const title = sheet.getRange(row, 9).getValue();
  
  // 如果是錯誤回報或低評分，發送通知
  if (feedbackType === 'bug_report' || rating <= 2) {
    sendUrgentNotification(row);
  }
  
  // 自動設置狀態
  sheet.getRange(row, 18).setValue('pending');
  
  // 記錄到統計表
  updateStatistics();
}

// 發送緊急通知
function sendUrgentNotification(row) {
  const sheet = SpreadsheetApp.getActiveSheet();
  const title = sheet.getRange(row, 9).getValue();
  const description = sheet.getRange(row, 10).getValue();
  const type = sheet.getRange(row, 6).getValue();
  
  const subject = `[Pickit緊急] ${type}: ${title}`;
  const body = `
    新的緊急意見回饋：
    
    類型: ${type}
    標題: ${title}
    描述: ${description}
    
    請立即查看: ${SpreadsheetApp.getActiveSpreadsheet().getUrl()}
  `;
  
  // 發送郵件（替換為您的郵箱）
  MailApp.sendEmail('dev@pickit.ai', subject, body);
}

// 更新統計數據
function updateStatistics() {
  const feedbackSheet = SpreadsheetApp.getSheetByName('Feedback');
  const statsSheet = SpreadsheetApp.getSheetByName('Statistics') || 
                    SpreadsheetApp.insertSheet('Statistics');
  
  const data = feedbackSheet.getDataRange().getValues();
  const stats = {
    total: data.length - 1,
    byType: {},
    byRating: {},
    averageRating: 0
  };
  
  // 計算統計
  let totalRating = 0;
  let ratingCount = 0;
  
  for (let i = 1; i < data.length; i++) {
    const type = data[i][5];
    const rating = data[i][7];
    
    // 按類型統計
    stats.byType[type] = (stats.byType[type] || 0) + 1;
    
    // 按評分統計
    if (rating) {
      stats.byRating[rating] = (stats.byRating[rating] || 0) + 1;
      totalRating += rating;
      ratingCount++;
    }
  }
  
  // 計算平均評分
  if (ratingCount > 0) {
    stats.averageRating = totalRating / ratingCount;
  }
  
  // 更新統計表
  statsSheet.clear();
  statsSheet.getRange(1, 1).setValue('統計更新時間');
  statsSheet.getRange(1, 2).setValue(new Date());
  statsSheet.getRange(2, 1).setValue('總提交數');
  statsSheet.getRange(2, 2).setValue(stats.total);
  statsSheet.getRange(3, 1).setValue('平均評分');
  statsSheet.getRange(3, 2).setValue(stats.averageRating.toFixed(2));
}

// 設置觸發器
function setupTriggers() {
  ScriptApp.newTrigger('onFormSubmit')
    .forSpreadsheet(SpreadsheetApp.getActive())
    .onFormSubmit()
    .create();
}
```

3. 運行 `setupTriggers()` 函數以設置自動觸發器

## 創建數據可視化儀表板

### 在 Google Sheets 中創建圖表

1. 創建新工作表 "Dashboard"
2. 使用以下公式創建統計：

```excel
# 總提交數
=COUNTA(Feedback!A:A)-1

# 平均評分
=AVERAGE(Feedback!H:H)

# 按類型分組
=QUERY(Feedback!A:T, "SELECT F, COUNT(A) WHERE F != '' GROUP BY F", 1)

# 按評分分組
=QUERY(Feedback!A:T, "SELECT H, COUNT(A) WHERE H > 0 GROUP BY H", 1)

# 最近提交
=QUERY(Feedback!A:T, "SELECT B, I, J ORDER BY B DESC LIMIT 10", 1)
```

3. 基於這些數據創建圖表：
   - 餅圖：意見類型分布
   - 柱狀圖：評分分布
   - 折線圖：每日提交趨勢

## 安全最佳實踐

1. **永不提交敏感信息**：
   - 不要將 `credentials.json` 提交到版本控制
   - 使用 `.gitignore` 排除敏感文件

2. **限制權限**：
   - 服務帳戶只需要試算表的編輯權限
   - 定期審查和撤銷不必要的權限

3. **數據保護**：
   - 定期備份 Google Sheets
   - 實施數據保留政策
   - 遵守 GDPR 和其他數據保護法規

4. **監控和審計**：
   - 監控 API 使用量
   - 定期審查提交日誌
   - 設置異常活動警報

## 故障排除

### 常見問題

**問題：無法連接到 Google Sheets**
- 檢查服務帳戶是否有試算表的編輯權限
- 確認 API 已啟用
- 驗證憑證文件路徑正確

**問題：提交失敗**
- 檢查網絡連接
- 驗證試算表 ID 正確
- 查看服務器日誌

**問題：數據未顯示**
- 確認工作表名稱為 "Feedback"
- 檢查欄位順序是否正確
- 刷新試算表

## 維護建議

1. **定期備份**：每週導出 CSV 備份
2. **清理舊數據**：每季度歸檔舊的意見
3. **更新統計**：每月生成分析報告
4. **回覆用戶**：48小時內回覆錯誤報告

## 支援

如需協助，請聯繫：
- 📧 Email: support@pickit.ai
- 📖 文檔: https://pickit.ai/docs/feedback
- 💬 Discord: https://discord.gg/pickit

---

*此設置指南確保 Pickit 意見回饋系統能夠可靠、安全地運行。*