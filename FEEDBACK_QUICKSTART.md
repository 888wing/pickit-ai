# Pickit 意見回饋系統 - 快速開始指南

## 🎯 您的 Google Sheets 資訊

✅ **試算表已準備就緒！**
- **試算表 ID**: `1kSqxDK39h-yncxnJzliDS-cec_1BnxjilJlS88cBkjw`
- **查看試算表**: [點擊這裡開啟](https://docs.google.com/spreadsheets/d/1kSqxDK39h-yncxnJzliDS-cec_1BnxjilJlS88cBkjw)

## 📋 快速設置步驟

### 1️⃣ 設置 Google Cloud 服務帳戶

```bash
# 1. 訪問 Google Cloud Console
https://console.cloud.google.com

# 2. 創建新項目或選擇現有項目

# 3. 啟用 Google Sheets API
# 導航到: API 和服務 > 啟用 API 和服務
# 搜索: Google Sheets API
# 點擊: 啟用

# 4. 創建服務帳戶
# 導航到: API 和服務 > 憑證
# 點擊: 創建憑證 > 服務帳戶
# 名稱: pickit-feedback-service
# 角色: 編輯者

# 5. 下載密鑰
# 點擊服務帳戶 > 密鑰 > 新增密鑰 > JSON
# 下載並保存為: credentials.json
```

### 2️⃣ 共享 Google Sheets

1. 開啟您的 [Pickit Feedback Database](https://docs.google.com/spreadsheets/d/1kSqxDK39h-yncxnJzliDS-cec_1BnxjilJlS88cBkjw)
2. 點擊右上角「共享」按鈕
3. 輸入服務帳戶電子郵件（從 credentials.json 中的 `client_email` 欄位複製）
4. 選擇「編輯者」權限
5. 點擊「傳送」

### 3️⃣ 配置 Node.js 服務器

```bash
# 進入 node-bridge 目錄
cd LightroomAISelector/node-bridge

# 放置 credentials.json
# 將下載的 credentials.json 文件放到此目錄

# 安裝依賴
npm install

# 運行設置腳本（自動配置試算表）
npm run setup-feedback

# 或手動設置
node scripts/setup-feedback.js
```

### 4️⃣ 創建環境配置

創建 `node-bridge/.env` 文件：

```env
# Server Configuration
PORT=3000
NODE_ENV=production

# Google Sheets Configuration
FEEDBACK_SHEET_ID=1kSqxDK39h-yncxnJzliDS-cec_1BnxjilJlS88cBkjw

# 如果使用 credentials.json，以下可以省略
# GOOGLE_PROJECT_ID=your-project-id
# GOOGLE_CLIENT_EMAIL=your-service-account@project.iam.gserviceaccount.com
```

### 5️⃣ 啟動服務器

```bash
# 啟動 Node.js Bridge 服務器
npm start

# 服務器將在 http://localhost:3000 運行
# 您應該看到：
# 🚀 ONNX Bridge Server running on port 3000
# ✅ FeedbackService initialized successfully
```

### 6️⃣ 測試意見提交

```bash
# 使用 curl 測試
curl -X POST http://localhost:3000/feedback/submit \
  -H "Content-Type: application/json" \
  -d '{
    "feedbackType": "feature_request",
    "rating": 5,
    "title": "測試提交",
    "description": "這是一個測試意見",
    "userName": "測試用戶",
    "userEmail": "test@example.com"
  }'

# 成功響應：
# {
#   "success": true,
#   "submissionId": "FB20250120xxxx"
# }
```

## 🎨 在 Lightroom 中使用

### 開啟意見回饋對話框

1. 打開 Lightroom Classic
2. 選擇菜單：**圖庫** → **插件附加功能** → **Pickit - 意見回饋**
3. 填寫意見表單
4. 點擊「提交」

### 意見類型說明

| 類型 | 用途 | 範例 |
|------|------|------|
| **功能建議** | 新功能想法 | "希望增加批次導出功能" |
| **錯誤回報** | 發現的問題 | "選片時崩潰" |
| **性能問題** | 速度或效率 | "處理100張照片需要10分鐘" |
| **界面意見** | UI/UX 改進 | "按鈕太小難以點擊" |
| **工作流程建議** | 流程優化 | "希望能記住上次設置" |
| **一般意見** | 其他意見 | "整體使用體驗很好" |
| **讚賞鼓勵** | 正面回饋 | "節省了80%的時間！" |

## 📊 查看意見數據

### 在 Google Sheets 中查看

1. 開啟 [Pickit Feedback Database](https://docs.google.com/spreadsheets/d/1kSqxDK39h-yncxnJzliDS-cec_1BnxjilJlS88cBkjw)
2. **Feedback** 工作表：查看所有提交的意見
3. **Statistics** 工作表：查看統計數據

### 數據欄位說明

| 欄位 | 說明 |
|------|------|
| **Submission ID** | 唯一識別碼（如 FB20250120001）|
| **Timestamp** | 提交時間 |
| **Rating** | 滿意度評分（1-5）|
| **Title** | 意見標題 |
| **Description** | 詳細描述 |
| **Status** | 處理狀態（pending/reviewing/completed）|
| **Response** | 官方回覆 |

## 🔧 常見問題解決

### 問題 1: 無法連接到 Google Sheets

**錯誤訊息**: `Failed to submit feedback: Cannot access spreadsheet`

**解決方案**:
1. 確認已共享試算表給服務帳戶
2. 檢查 credentials.json 是否在正確位置
3. 確認 Google Sheets API 已啟用

### 問題 2: 提交失敗但已暫存

**訊息**: "無法連接伺服器，意見已暫存並將稍後自動提交"

**說明**: 
- 意見已保存在本地
- 當服務器恢復時會自動重試提交
- 不會丟失任何意見

### 問題 3: 服務器啟動失敗

**錯誤**: `Failed to initialize FeedbackService`

**檢查項目**:
```bash
# 1. 確認 credentials.json 存在
ls node-bridge/credentials.json

# 2. 確認依賴已安裝
npm install googleapis

# 3. 檢查環境變量
cat .env | grep FEEDBACK_SHEET_ID
```

## 📈 進階功能

### 自動化通知（可選）

在 Google Sheets 中設置 Apps Script：

1. 開啟試算表
2. 擴充功能 → Apps Script
3. 添加以下腳本：

```javascript
function onFormSubmit(e) {
  const row = e.range.getRow();
  const sheet = e.range.getSheet();
  const feedbackType = sheet.getRange(row, 6).getValue();
  const rating = sheet.getRange(row, 8).getValue();
  
  // 錯誤回報或低評分時發送郵件
  if (feedbackType === 'bug_report' || rating <= 2) {
    MailApp.sendEmail(
      'your-email@example.com',
      '[Pickit] 緊急意見回饋',
      `新的${feedbackType}，評分: ${rating}`
    );
  }
}
```

### 數據分析

使用 Google Sheets 公式分析數據：

```excel
# 平均評分
=AVERAGE(Feedback!H:H)

# 本週提交數
=COUNTIFS(Feedback!B:B, ">="&TODAY()-7)

# 按類型統計
=QUERY(Feedback!A:T, "SELECT F, COUNT(A) WHERE F != '' GROUP BY F", 1)
```

## ✅ 完成檢查清單

- [ ] Google Cloud 項目已創建
- [ ] Google Sheets API 已啟用
- [ ] 服務帳戶已創建
- [ ] credentials.json 已下載並放置
- [ ] 試算表已共享給服務帳戶
- [ ] Node.js 依賴已安裝
- [ ] 服務器成功啟動
- [ ] 測試提交成功
- [ ] Lightroom 插件可以開啟意見回饋對話框

## 🎉 恭喜！

您的 Pickit 意見回饋系統已經設置完成。現在您可以：

1. 📝 收集用戶意見和建議
2. 🐛 快速接收錯誤報告
3. 📊 分析用戶滿意度
4. 💬 回覆用戶意見
5. 📈 追蹤產品改進

## 📞 需要協助？

- 📧 Email: support@pickit.ai
- 📖 完整文檔: [GOOGLE_SHEETS_SETUP.md](./GOOGLE_SHEETS_SETUP.md)
- 💻 技術支援: [GitHub Issues](https://github.com/pickit/pickit-lightroom/issues)

---

*感謝您使用 Pickit！您的意見將幫助我們打造更好的產品。*