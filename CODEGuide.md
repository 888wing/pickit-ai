1. 命名規範
1.1 檔案命名規則
目錄結構
LightroomAISelector/
├── src/
│   ├── core/               # 核心功能模組
│   │   ├── AIEngine.lua    # AI推理引擎
│   │   ├── PhotoScorer.lua # 照片評分器
│   │   └── BatchProcessor.lua
│   ├── models/             # AI模型相關
│   │   ├── ModelLoader.lua
│   │   ├── ONNXBridge.lua
│   │   └── configs/
│   ├── ui/                 # 使用者介面
│   │   ├── MainDialog.lua
│   │   ├── ProgressBar.lua
│   │   └── ResultsPanel.lua
│   ├── utils/              # 工具函數
│   │   ├── ImageUtils.lua
│   │   ├── FileHelper.lua
│   │   └── Logger.lua
│   ├── api/                # API整合
│   │   ├── CloudClient.lua
│   │   ├── AuthManager.lua
│   │   └── DataSync.lua
│   └── analytics/          # 數據分析
│       ├── Tracker.lua
│       ├── Reporter.lua
│       └── Privacy.lua
檔案命名約定
lua-- ✅ 正確：PascalCase，描述性命名
PhotoScorer.lua
BatchProcessor.lua
CloudAPIClient.lua

-- ❌ 錯誤：避免縮寫和不明確命名
ps.lua
proc.lua
api.lua
1.2 變數與函數命名
變數命名規則
lua-- 全域常數：全大寫，底線分隔
local MAX_BATCH_SIZE = 100
local DEFAULT_THRESHOLD = 0.7
local API_ENDPOINT = "https://api.photoai.com"

-- 局部變數：camelCase
local photoCount = 0
local isProcessing = false
local currentBatch = {}

-- 私有變數：底線前綴
local _internalCache = {}
local _sessionId = nil

-- 配置物件：描述性名稱
local scoringConfig = {
    technicalWeight = 0.4,
    aestheticWeight = 0.6,
    enableFaceDetection = true
}
函數命名規則
lua-- 公共函數：camelCase，動詞開頭
function processPhoto(photo, options)
function calculateScore(features)
function validateInput(data)

-- 私有函數：底線前綴
function _initializeModels()
function _cleanupCache()

-- 事件處理：on + 事件名
function onPhotoSelected(photo)
function onBatchComplete(results)
function onError(error)

-- 狀態檢查：is/has/can 前綴
function isPhotoValid(photo)
function hasRequiredMetadata(metadata)
function canProcessBatch(size)

-- 取值/設值：get/set 前綴
function getConfiguration()
function setThreshold(value)
1.3 模組命名規範
lua-- 模組定義：與檔案名一致
-- 檔案：PhotoScorer.lua
local PhotoScorer = {}
PhotoScorer.VERSION = "1.0.0"

-- 命名空間組織
local AI = {}
AI.Models = {}
AI.Models.NIMA = {}
AI.Processors = {}
AI.Utils = {}

-- 避免命名衝突的策略
local LrAI = {} -- Lightroom AI 前綴
local LRAI_PhotoScorer = {} -- 專案前綴
1.4 UI元件命名
lua-- UI元件：描述性前綴 + 類型
local mainDialog = {}
local btnProcess = {} -- 按鈕
local txtThreshold = {} -- 文字輸入
local sldQuality = {} -- 滑桿
local chkAutoMode = {} -- 勾選框
local lstResults = {} -- 列表
local pnlSettings = {} -- 面板

-- UI ID命名（用於綁定）
local bindings = {
    'threshold_value',     -- 底線分隔
    'weight_technical',
    'weight_aesthetic',
    'enable_face_detection'
}

2. 程式碼組織規範
2.1 模組結構模板
lua--[[
    模組：PhotoScorer
    描述：負責照片評分的核心邏輯
    作者：[開發者名稱]
    創建日期：2024-12-20
    最後修改：2024-12-20
--]]

local LrLogger = import 'LrLogger'
local logger = LrLogger('PhotoScorer')

-- 模組定義
local PhotoScorer = {}
PhotoScorer.VERSION = "1.0.0"

-- 私有變數
local _models = {}
local _cache = {}
local _config = nil

-- 常數定義
local DEFAULT_THRESHOLD = 0.7
local MAX_CACHE_SIZE = 100

-- 初始化函數
function PhotoScorer:initialize(config)
    logger:trace("Initializing PhotoScorer")
    _config = config or {}
    self:_loadModels()
    return self
end

-- 公共方法
function PhotoScorer:scorePhoto(photo, options)
    -- 參數驗證
    assert(photo, "Photo is required")
    
    -- 快取檢查
    local cacheKey = self:_getCacheKey(photo)
    if _cache[cacheKey] then
        return _cache[cacheKey]
    end
    
    -- 主要邏輯
    local score = self:_calculateScore(photo, options)
    
    -- 更新快取
    self:_updateCache(cacheKey, score)
    
    return score
end

-- 私有方法
function PhotoScorer:_loadModels()
    -- 實現細節
end

function PhotoScorer:_calculateScore(photo, options)
    -- 實現細節
end

-- 清理函數
function PhotoScorer:cleanup()
    _cache = {}
    _models = {}
    logger:trace("PhotoScorer cleaned up")
end

return PhotoScorer
2.2 錯誤處理規範
錯誤處理模式
lua-- 錯誤代碼定義
local ErrorCodes = {
    -- 系統錯誤 (1xxx)
    SYSTEM_ERROR = 1000,
    MEMORY_ERROR = 1001,
    FILE_NOT_FOUND = 1002,
    
    -- 模型錯誤 (2xxx)
    MODEL_LOAD_FAILED = 2000,
    MODEL_INFERENCE_ERROR = 2001,
    MODEL_VERSION_MISMATCH = 2002,
    
    -- API錯誤 (3xxx)
    API_CONNECTION_FAILED = 3000,
    API_AUTH_FAILED = 3001,
    API_RATE_LIMIT = 3002,
    
    -- 用戶錯誤 (4xxx)
    INVALID_INPUT = 4000,
    INVALID_PHOTO_FORMAT = 4001,
    BATCH_SIZE_EXCEEDED = 4002
}

-- 統一錯誤處理函數
function handleError(errorCode, details, context)
    local errorInfo = {
        code = errorCode,
        message = getErrorMessage(errorCode),
        details = details,
        context = context,
        timestamp = os.time(),
        version = APP_VERSION
    }
    
    -- 記錄錯誤
    logger:error(json.encode(errorInfo))
    
    -- 用戶通知策略
    if errorCode < 2000 then
        -- 系統錯誤：顯示通用訊息
        showUserError("系統錯誤，請重試")
    elseif errorCode < 3000 then
        -- 模型錯誤：提供具體指導
        showUserError("AI模型載入失敗，請檢查安裝")
    elseif errorCode < 4000 then
        -- API錯誤：提供降級方案
        showUserError("網路連接失敗，切換到本地模式")
    else
        -- 用戶錯誤：提供明確指示
        showUserError(errorInfo.message)
    end
    
    -- 錯誤恢復
    attemptErrorRecovery(errorCode)
    
    return errorInfo
end

-- 錯誤恢復策略
function attemptErrorRecovery(errorCode)
    local recoveryStrategies = {
        [ErrorCodes.MODEL_LOAD_FAILED] = function()
            -- 嘗試重新載入模型
            return retryModelLoad()
        end,
        [ErrorCodes.API_CONNECTION_FAILED] = function()
            -- 切換到離線模式
            return switchToOfflineMode()
        end,
        [ErrorCodes.MEMORY_ERROR] = function()
            -- 清理快取並重試
            clearCache()
            return true
        end
    }
    
    local strategy = recoveryStrategies[errorCode]
    if strategy then
        return strategy()
    end
    
    return false
end
重試機制
lua-- 智能重試函數
function retryWithBackoff(func, maxAttempts, initialDelay)
    maxAttempts = maxAttempts or 3
    initialDelay = initialDelay or 1000 -- 毫秒
    
    local attempt = 0
    local delay = initialDelay
    
    while attempt < maxAttempts do
        attempt = attempt + 1
        
        -- 嘗試執行
        local success, result = pcall(func)
        
        if success then
            return result
        end
        
        -- 記錄失敗
        logger:warn(string.format(
            "Attempt %d/%d failed, retrying in %dms",
            attempt, maxAttempts, delay
        ))
        
        -- 指數退避
        if attempt < maxAttempts then
            LrTasks.sleep(delay / 1000)
            delay = delay * 2 -- 指數增長
        end
    end
    
    -- 所有嘗試失敗
    return nil, "Max retry attempts exceeded"
end

3. UI/UX 流程規範
3.1 使用者互動流程
載入狀態管理
lua-- 統一的載入狀態顯示
local UIStates = {
    IDLE = "idle",
    LOADING = "loading",
    PROCESSING = "processing",
    SUCCESS = "success",
    ERROR = "error"
}

function updateUIState(state, message, progress)
    local stateConfig = {
        [UIStates.IDLE] = {
            icon = "⭘",
            color = "gray",
            enableInput = true
        },
        [UIStates.LOADING] = {
            icon = "⟳",
            color = "blue",
            enableInput = false,
            showProgress = false
        },
        [UIStates.PROCESSING] = {
            icon = "⚙",
            color = "blue",
            enableInput = false,
            showProgress = true
        },
        [UIStates.SUCCESS] = {
            icon = "✓",
            color = "green",
            enableInput = true,
            autoHide = 3000
        },
        [UIStates.ERROR] = {
            icon = "✕",
            color = "red",
            enableInput = true,
            showRetry = true
        }
    }
    
    local config = stateConfig[state]
    
    -- 更新UI元件
    updateStatusIcon(config.icon)
    updateStatusColor(config.color)
    setInputEnabled(config.enableInput)
    
    if config.showProgress then
        showProgressBar(progress or 0)
    else
        hideProgressBar()
    end
    
    if message then
        showStatusMessage(message)
    end
    
    if config.autoHide then
        scheduleHideStatus(config.autoHide)
    end
end
進度回饋機制
lua-- 批次處理進度管理
local ProgressTracker = {}

function ProgressTracker:new(total, callback)
    local tracker = {
        total = total,
        current = 0,
        startTime = os.time(),
        callback = callback or function() end,
        milestones = {0.25, 0.5, 0.75, 1.0}
    }
    
    setmetatable(tracker, {__index = self})
    return tracker
end

function ProgressTracker:update(increment)
    self.current = self.current + (increment or 1)
    local progress = self.current / self.total
    
    -- 計算剩餘時間
    local elapsed = os.time() - self.startTime
    local estimatedTotal = elapsed / progress
    local remaining = estimatedTotal - elapsed
    
    -- 更新UI
    self.callback({
        current = self.current,
        total = self.total,
        percentage = progress * 100,
        timeRemaining = remaining,
        message = self:getProgressMessage(progress)
    })
    
    -- 里程碑通知
    self:checkMilestones(progress)
end

function ProgressTracker:getProgressMessage(progress)
    if progress < 0.1 then
        return "準備中..."
    elseif progress < 0.5 then
        return "處理中..."
    elseif progress < 0.9 then
        return "即將完成..."
    else
        return "完成處理"
    end
end
3.2 錯誤提示規範
lua-- 用戶友好的錯誤訊息
local ErrorMessages = {
    -- 技術錯誤轉換為用戶語言
    [ErrorCodes.MODEL_LOAD_FAILED] = {
        title = "AI模型載入失敗",
        message = "無法載入照片分析模型，請確認插件安裝完整。",
        actions = {
            {label = "重新安裝", action = "reinstall"},
            {label = "聯繫支援", action = "support"},
            {label = "稍後重試", action = "retry"}
        }
    },
    
    [ErrorCodes.API_RATE_LIMIT] = {
        title = "處理限制",
        message = "您已達到今日處理上限，請升級方案或明天再試。",
        actions = {
            {label = "升級方案", action = "upgrade"},
            {label = "查看用量", action = "usage"},
            {label = "使用本地模式", action = "offline"}
        }
    }
}

-- 錯誤顯示函數
function showErrorDialog(errorCode, customMessage)
    local errorConfig = ErrorMessages[errorCode] or {
        title = "未知錯誤",
        message = customMessage or "發生未預期的錯誤",
        actions = {{label = "確定", action = "close"}}
    }
    
    local dialog = LrDialogs.presentModalDialog({
        title = errorConfig.title,
        message = errorConfig.message,
        buttons = errorConfig.actions,
        cancelButton = "取消"
    })
    
    -- 記錄用戶選擇
    trackUserAction("error_dialog", {
        error_code = errorCode,
        user_action = dialog.button
    })
    
    return dialog.button
end
3.3 響應式設計原則
lua-- 自適應UI配置
local UIConfig = {
    -- 根據螢幕大小調整
    layouts = {
        compact = { -- < 1440px
            batchSize = 20,
            thumbnailSize = 100,
            columns = 4
        },
        standard = { -- 1440-1920px
            batchSize = 50,
            thumbnailSize = 150,
            columns = 6
        },
        large = { -- > 1920px
            batchSize = 100,
            thumbnailSize = 200,
            columns = 8
        }
    },
    
    -- 性能模式配置
    performanceModes = {
        battery = {
            batchSize = 10,
            aiModel = "tiny",
            refreshRate = 1000
        },
        balanced = {
            batchSize = 30,
            aiModel = "standard",
            refreshRate = 500
        },
        performance = {
            batchSize = 50,
            aiModel = "full",
            refreshRate = 100
        }
    }
}

-- 動態UI調整
function adaptUIToContext()
    local screenWidth = getScreenWidth()
    local powerMode = getPowerMode()
    
    -- 選擇適當的布局
    local layout = UIConfig.layouts.standard
    if screenWidth < 1440 then
        layout = UIConfig.layouts.compact
    elseif screenWidth > 1920 then
        layout = UIConfig.layouts.large
    end
    
    -- 應用性能模式
    local perfMode = UIConfig.performanceModes[powerMode]
    
    -- 合併配置
    return {
        batchSize = math.min(layout.batchSize, perfMode.batchSize),
        thumbnailSize = layout.thumbnailSize,
        columns = layout.columns,
        aiModel = perfMode.aiModel,
        refreshRate = perfMode.refreshRate
    }
end

4. 測試規範
4.1 單元測試命名
lua-- 測試檔案命名：原檔名 + _test
PhotoScorer_test.lua
BatchProcessor_test.lua

-- 測試函數命名：test_ + 功能描述
function test_scorePhoto_withValidInput_returnsScore()
function test_scorePhoto_withNullInput_throwsError()
function test_batchProcess_withLargeDataset_completesWithinTimeout()
4.2 整合測試結構
lua-- 測試套件組織
local TestSuite = {
    name = "PhotoScorer Integration Tests",
    
    setup = function()
        -- 測試環境準備
    end,
    
    teardown = function()
        -- 清理測試資源
    end,
    
    tests = {
        {
            name = "Full workflow test",
            run = function()
                -- 測試實現
            end
        }
    }
}

5. 文檔規範
5.1 程式碼註解規範
lua--[[
    函數：processPhoto
    描述：處理單張照片並返回評分結果
    
    參數：
        photo (LrPhoto): Lightroom照片物件
        options (table): 處理選項
            - threshold (number): 評分閾值 (0-1)
            - enableFaceDetection (boolean): 是否啟用人臉檢測
            
    返回值：
        table: 包含評分結果的表格
            - score (number): 綜合評分 (0-100)
            - technical (number): 技術評分
            - aesthetic (number): 美學評分
            
    異常：
        - InvalidPhotoError: 照片格式不支援
        - ProcessingError: 處理過程發生錯誤
        
    範例：
        local result = processPhoto(photo, {
            threshold = 0.7,
            enableFaceDetection = true
        })
--]]
5.2 API文檔模板
lua-- API端點文檔
--[[
    端點：/api/v1/analyze
    方法：POST
    描述：分析照片並返回評分
    
    請求頭：
        Content-Type: multipart/form-data
        Authorization: Bearer {token}
        
    請求參數：
        files: 照片檔案陣列 (最多50個)
        features: 需要的分析特徵 (可選)
        
    回應格式：
        {
            status: "success",
            results: [
                {
                    filename: "IMG_001.jpg",
                    scores: {...}
                }
            ]
        }
        
    錯誤代碼：
        400: 無效的請求參數
        401: 認證失敗
        429: 超過速率限制
--]]

6. 版本控制規範
6.1 分支命名
bash# 功能分支
feature/add-face-detection
feature/improve-scoring-algorithm

# 修復分支
fix/memory-leak-in-batch-processing
fix/ui-crash-on-large-selection

# 發布分支
release/v1.0.0
release/v1.1.0-beta

# 熱修復
hotfix/critical-auth-issue
6.2 提交訊息格式
bash# 格式：<類型>(<範圍>): <簡短描述>

feat(scoring): 新增人臉品質檢測功能
fix(ui): 修復批次處理進度條不更新問題
docs(api): 更新API文檔說明
refactor(core): 重構評分算法以提升性能
test(integration): 新增端到端測試案例
style(formatting): 統一程式碼格式
chore(deps): 更新依賴套件版本

7. 性能優化指南
7.1 快取策略
lua-- LRU快取實現
local LRUCache = {}

function LRUCache:new(maxSize)
    return {
        maxSize = maxSize or 100,
        cache = {},
        order = {},
        
        get = function(self, key)
            local value = self.cache[key]
            if value then
                self:_updateOrder(key)
            end
            return value
        end,
        
        set = function(self, key, value)
            if #self.order >= self.maxSize then
                self:_evictLRU()
            end
            self.cache[key] = value
            self:_updateOrder(key)
        end
    }
end
7.2 記憶體管理
lua-- 記憶體監控
local MemoryMonitor = {
    threshold = 500 * 1024 * 1024, -- 500MB
    
    check = function()
        local usage = collectgarbage("count") * 1024
        if usage > MemoryMonitor.threshold then
            logger:warn("High memory usage: " .. usage)
            MemoryMonitor.cleanup()
        end
    end,
    
    cleanup = function()
        -- 清理快取
        clearCache()
        -- 強制垃圾回收
        collectgarbage("collect")
        -- 壓縮記憶體
        collectgarbage("step", 10)
    end
}

8. 安全規範
8.1 敏感資料處理
lua-- API金鑰管理
local SecureStorage = {
    -- 永遠不要硬編碼
    -- ❌ 錯誤
    API_KEY = "sk_live_abcd1234",
    
    -- ✅ 正確
    getAPIKey = function()
        return LrPrefs.getPreference("api_key_encrypted")
    end,
    
    setAPIKey = function(key)
        local encrypted = encrypt(key)
        LrPrefs.setPreference("api_key_encrypted", encrypted)
    end
}
8.2 輸入驗證
lua-- 統一的輸入驗證
local Validator = {
    photo = function(photo)
        assert(photo, "Photo is required")
        assert(photo.catalog, "Photo must be in catalog")
        assert(photo:getRawMetadata("fileFormat"), "Invalid photo format")
    end,
    
    options = function(options)
        local schema = {
            threshold = {type = "number", min = 0, max = 1},
            batchSize = {type = "number", min = 1, max = 1000},
            enableCloud = {type = "boolean"}
        }
        
        for key, rules in pairs(schema) do
            if options[key] then
                validateField(options[key], rules)
            end
        end
    end
}
這份編碼規範確保團隊在開發過程中保持一致性，減少錯誤，提高程式碼品質和可維護性。
</artifact>
<artifact id="work-checklist" type="text/markdown" title="工作清單 - 從MVP到進階版完整任務列表">
# 工作清單 - Lightroom AI 智能選片插件
## 從MVP到進階API版本完整任務列表
專案資訊

起始日期: 2025-01-01
MVP目標日期: 2025-03-01
進階版目標日期: 2025-05-01
團隊規模: 2-3人