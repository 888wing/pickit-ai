# 📸 Pickit - Lightroom Classic 安裝指南

## 系統需求

### 最低需求
- **Lightroom Classic**: 12.0 或更高版本
- **作業系統**: macOS 10.15+ 或 Windows 10+
- **Node.js**: 16.0 或更高版本
- **記憶體**: 4GB RAM (建議 8GB)
- **硬碟空間**: 500MB

## 📦 安裝步驟

### 步驟 1: 下載專案

```bash
# 從 GitHub 下載
git clone https://github.com/888wing/pickit-ai.git
cd pickit-ai

# 或者下載 ZIP 檔案
# 訪問 https://github.com/888wing/pickit-ai
# 點擊 "Code" → "Download ZIP"
# 解壓縮到您想要的位置
```

### 步驟 2: 安裝 Node.js (如果尚未安裝)

#### macOS
```bash
# 使用 Homebrew
brew install node

# 或從官網下載
# https://nodejs.org/
```

#### Windows
```powershell
# 從官網下載安裝程式
# https://nodejs.org/
# 下載 Windows Installer (.msi)
```

### 步驟 3: 設置 Node.js 服務

```bash
# 進入 node-bridge 目錄
cd LightroomAISelector/node-bridge

# 安裝依賴套件
npm install

# 下載 AI 模型
npm run install-models
```

### 步驟 4: 配置 Google Sheets API (選用 - 用於意見回饋功能)

#### 4.1 建立 Google Cloud 專案
1. 前往 [Google Cloud Console](https://console.cloud.google.com)
2. 建立新專案或選擇現有專案
3. 啟用 Google Sheets API

#### 4.2 建立服務帳戶
1. 前往 "IAM 與管理" → "服務帳戶"
2. 點擊 "建立服務帳戶"
3. 輸入名稱和描述
4. 點擊 "建立並繼續"
5. 跳過權限設定（稍後在 Google Sheets 中設定）
6. 點擊 "完成"

#### 4.3 下載憑證
1. 點擊剛建立的服務帳戶
2. 前往 "金鑰" 標籤
3. 點擊 "新增金鑰" → "建立新金鑰"
4. 選擇 "JSON" 格式
5. 下載金鑰檔案

#### 4.4 設置憑證
```bash
# 複製範例檔案
cp credentials.example.json credentials.json

# 將下載的 JSON 內容貼到 credentials.json
# 然後執行安全腳本
../../secure-credentials.sh
```

### 步驟 5: 啟動 Node.js 服務

```bash
# 在 node-bridge 目錄中
npm start

# 您應該會看到：
# 🚀 Pickit AI Server running on port 3001
# ✅ Ready for Lightroom connections
```

**重要**: 保持這個終端機視窗開啟，服務需要持續運行

### 步驟 6: 安裝 Lightroom 插件

#### 方法 A: 使用插件管理器 (推薦)

1. **開啟 Lightroom Classic**

2. **進入插件管理器**
   - Mac: `Lightroom Classic` → `外掛模組管理員...`
   - Windows: `檔案` → `外掛模組管理員...`

3. **新增插件**
   - 點擊左下角的 `新增` 按鈕
   - 瀏覽到下載的專案資料夾
   - 選擇 `LightroomAISelector` 資料夾
   - 點擊 `選擇資料夾` (Mac) 或 `選擇` (Windows)

4. **啟用插件**
   - 在插件列表中找到 "Pickit AI Photo Selector"
   - 確保勾選 "啟用" 選項
   - 點擊 `完成`

#### 方法 B: 手動複製 (進階用戶)

```bash
# macOS
cp -r LightroomAISelector ~/Library/Application\ Support/Adobe/Lightroom/Modules/

# Windows
xcopy LightroomAISelector "%APPDATA%\Adobe\Lightroom\Modules\" /E /I
```

然後重啟 Lightroom Classic

## ✅ 驗證安裝

### 1. 檢查插件狀態
- 開啟 Lightroom Classic
- 前往 `檔案` → `外掛模組管理員`
- 確認 "Pickit AI Photo Selector" 顯示為 "已啟用"

### 2. 檢查選單項目
- 在圖庫模組中
- 點擊 `圖庫` 選單
- 您應該看到新的選項：
  - `Pickit - AI 照片分析`
  - `Pickit - 批次處理`
  - `Pickit - 設定`

### 3. 測試連線
1. 選擇幾張照片
2. 右鍵點擊 → `Pickit` → `測試連線`
3. 應該顯示 "✅ 成功連接到 AI 服務"

## 🎯 使用插件

### 基本工作流程

1. **選擇照片**
   - 在圖庫模組中選擇要分析的照片
   - 可以選擇單張或多張（建議批次 50-100 張）

2. **執行 AI 分析**
   - 右鍵點擊選中的照片
   - 選擇 `Pickit` → `分析照片`
   - 或使用快捷鍵 `Cmd+Shift+P` (Mac) / `Ctrl+Shift+P` (Windows)

3. **查看結果**
   - 分析完成後，照片會自動標記評分
   - 5 星：最佳照片（美學 + 技術分數 > 0.8）
   - 4 星：優秀照片（分數 > 0.7）
   - 3 星：良好照片（分數 > 0.6）
   - 2 星：一般照片（分數 > 0.5）
   - 1 星：建議刪除（分數 < 0.5）

4. **篩選結果**
   - 使用 Lightroom 的星級篩選器
   - 快速找到最佳照片

### 進階功能

#### 批次處理
```
圖庫 → Pickit → 批次處理整個目錄
```

#### 相似照片分組
```
圖庫 → Pickit → 智能分組
```

#### 人臉品質檢測
```
圖庫 → Pickit → 人臉分析
```

## 🔧 疑難排解

### 問題 1: 插件未顯示在選單中
**解決方案**:
1. 確認插件已在插件管理器中啟用
2. 重啟 Lightroom Classic
3. 檢查插件資料夾權限

### 問題 2: "無法連接到 AI 服務"
**解決方案**:
1. 確認 Node.js 服務正在運行
   ```bash
   cd LightroomAISelector/node-bridge
   npm start
   ```
2. 檢查防火牆是否封鎖 port 3001
3. 確認 localhost:3001 可以訪問

### 問題 3: 分析速度很慢
**解決方案**:
1. 減少批次大小（建議 50 張）
2. 檢查 Node.js 服務的記憶體使用
3. 考慮使用 GPU 加速（如果可用）

### 問題 4: Google Sheets 回饋功能不工作
**解決方案**:
1. 確認憑證檔案已正確設置
2. 檢查服務帳戶是否有 Google Sheets 的編輯權限
3. 查看 Node.js 控制台的錯誤訊息

## 📝 配置選項

編輯 `LightroomAISelector/src/utils/Config.lua`:

```lua
-- 調整評分閾值
Config.qualityThreshold = 0.75  -- 預設 0.75

-- 調整批次大小
Config.batchSize = 50  -- 預設 50

-- 啟用/停用功能
Config.enableFaceDetection = true
Config.enableSimilarityGrouping = true
Config.enableAutoTagging = true
```

## 🚀 效能優化建議

1. **使用智能預覽**
   - 在 Lightroom 中建立智能預覽
   - 可大幅提升分析速度

2. **批次處理最佳實踐**
   - 每批 50-100 張照片
   - 避免同時處理 RAW 和 JPEG

3. **定期清理快取**
   ```bash
   # 清理 Node.js 快取
   cd LightroomAISelector/node-bridge
   npm run clean-cache
   ```

## 📚 其他資源

- **使用手冊**: [USER_MANUAL.md](USER_MANUAL.md)
- **常見問題**: [FAQ.md](FAQ.md)
- **問題回報**: [GitHub Issues](https://github.com/888wing/pickit-ai/issues)
- **社群討論**: [GitHub Discussions](https://github.com/888wing/pickit-ai/discussions)

## 💡 提示

- 第一次使用時，建議先用少量照片測試
- AI 模型會隨著使用學習您的偏好（透過回饋系統）
- 定期更新插件以獲得最新功能和改進

---

## 需要協助？

如果遇到任何問題，請：
1. 查看[疑難排解](#疑難排解)部分
2. 查看 [GitHub Issues](https://github.com/888wing/pickit-ai/issues)
3. 在 [Discussions](https://github.com/888wing/pickit-ai/discussions) 發問
4. 聯繫：support@pickit.ai

祝您使用愉快！🎉