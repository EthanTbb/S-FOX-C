local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")

local GameLayer = class("GameLayer", GameModel)

local cmd = appdf.req(appdf.GAME_SRC.."yule.oxsixex.src.models.CMD_Game")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.oxsixex.src.models.GameLogic")
local GameViewLayer = appdf.req(appdf.GAME_SRC.."yule.oxsixex.src.views.layer.GameViewLayer")
local QueryDialog   = require("app.views.layer.other.QueryDialog")

-- 初始化界面
function GameLayer:ctor(frameEngine,scene)
    print("GameLayer........enter~~")
    cc.FileUtils:getInstance():addSearchPath( device.writablePath .. "game/yule/oxsixex/res/")
	local this = self
    self._msgModel = require(appdf.GAME_SRC .. "yule.oxsixex.src.netMsgBean.NNGameNetModel"):create()

	self._gameFrame = frameEngine
    self._scene = scene

    self._gameView = GameViewLayer:create(this)
        :addTo(self)
	
    self:onInitData()
    self:enableNodeEvents()
    self:addBackKey()
end

function GameLayer:onExit()
    self.m_tStatusFree_ = nil
    self.m_tStatusPlay_ = nil
    self.m_tHandCardData_ = nil
    self.m_tPlayStatues_ = nil
    self.m_tOx_ = nil
    self.m_nBankerUser_ = nil

    self.m_eGameStatues_ = nil

     if self._ClockFun then
        --注销时钟
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self._ClockFun) 
        self._ClockFun = nil
    end
end

function GameLayer:addBackKey()
    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(function(keyCode, event)
            if keyCode == cc.KeyCode.KEY_BACK then
                event:stopPropagation()
                self:onBtnSendMessage(GameViewLayer.UiTag.eBtnBack)
            end
            end, cc.Handler.EVENT_KEYBOARD_RELEASED )
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self)
end

-- 初始化游戏数据
function GameLayer:onInitData()
    self.m_tStatusFree_ = {}
    self.m_tStatusPlay_ = {}
    self.m_tHandCardData_ = {}
    self.m_tPlayStatues_ = {}
    self.m_tOx_ = {0,0,0,0,0,0}
    self.m_nBankerUser_ = 0

    self.m_eGameStatues_ = cmd.GameStatues.FREE_STATUES

    --计时器
    self._ClockFun = nil
    self._ClockID = yl.INVALID_ITEM
    self._ClockTime = 0
    self._ClockChair = yl.INVALID_CHAIR
    self._ClockViewChair = yl.INVALID_CHAIR
end

-- 重置游戏数据
function GameLayer:onResetData()
    -- body
    self.m_tStatusFree_ = {}
    self.m_tStatusPlay_ = {}
    self.m_tHandCardData_ = {}
    self.m_tPlayStatues_ = {}
    self.m_tOx_ = {0,0,0,0,0,0}
    self.m_nBankerUser_ = 0

    self.m_eGameStatues_ = cmd.GameStatues.FREE_STATUES
end

function GameLayer:getHandCardData()
    return self.m_tHandCardData_
end

function GameLayer:getPlayStatues()
    return self.m_tPlayStatues_
end

function GameLayer:getBankUser()
    return self.m_nBankerUser_
end

function GameLayer:getOx()
    return self.m_tOx_
end

function GameLayer:getGameStatues()
    return self.m_eGameStatues_
end

-- 时钟处理
function GameLayer:OnEventGameClockInfo(chair,time,clockid)
--    if time < 5 then
--        AudioEngine.playEffect(cmd.RES_PATH.."sound_res/GAME_WARN.wav")
--    end
    if clockid == cmd.IDI_START_GAME then
        if time == 0 then   
            print("clockid==IDI_START_GAME")
            self._gameFrame:setEnterAntiCheatRoom(false)--退出防作弊
            self:onExitTable()
            return true
        end
    elseif clockid == cmd.IDI_TIME_OPEN_CARD then
        if time == 0 then
            self._gameView:OnOpenCard()
            return true
        elseif time <= 5 then
            AudioEngine.playEffect(GameViewLayer.RES_PATH.."sound/GAME_WARN.wav")
        end
    end
end

---------------------------------------------------------发送消息-----------------------------------------------------------
--发送摊牌消息
function GameLayer:sendOpenCard(sendData)
    if sendData == nil then
        return 
    end
    local dataBuffer = CCmd_Data:create(6)
	dataBuffer:setcmdinfo(yl.MDM_GF_GAME,cmd.SUB_C_OPEN_CARD)
    dataBuffer:pushbyte(sendData.bOX)
    for i,v in pairs(sendData.cbOxCardData) do
        dataBuffer:pushbyte(v)
    end
	
	return self._gameFrame:sendSocketData(dataBuffer)
end

function GameLayer:onBtnSendMessage(msgId,tData)
    if msgId == GameViewLayer.UiTag.eBtnBack then
        if self.m_eGameStatues_ == cmd.GameStatues.START_STATUES or self.m_eGameStatues_ == cmd.GameStatues.OPENCARD_STATUES then
            self:onQueryExitGame(1)
        else
            self:onQueryExitGame()
        end  
    elseif msgId == GameViewLayer.UiTag.eBtnStart then
        self._gameFrame:SendUserReady()   
    elseif msgId == GameViewLayer.UiTag.eBtnLiangPai then
        self:sendOpenCard(tData)
    elseif msgId == GameViewLayer.UiTag.eBtnChangeDesk then
        self._gameFrame:QueryChangeDesk() 
    end
end
---------------------------------------------------------接收消息-----------------------------------------------------------
-- 场景信息
function GameLayer:onEventGameScene(cbGameStatus,dataBuffer)
    --辅助读取int64
	if cbGameStatus == cmd.GS_TK_FREE	then				    --空闲状态
        self:onSubFreeStatues(dataBuffer)
	elseif cbGameStatus == cmd.GS_TK_PLAYING	then			--游戏状态
        self:onSubPlayingStatues(dataBuffer)
	end
    self:dismissPopWait()
end

function GameLayer:onSubFreeStatues(dataBuffer)
    local tData = self._msgModel:readSubFreeStatues(dataBuffer)
    self.m_tStatusFree_ = tData
    self.m_eGameStatues_ = cmd.GameStatues.FREE_STATUES

    --ui
    self._gameView:showFreeStatues()
end

function GameLayer:onSubPlayingStatues(dataBuffer)
    local tData = self._msgModel:readSubPlayingStatues(dataBuffer)

    self.m_tStatusPlay_ = tData
    self.m_tHandCardData_ = tData.cbHandCardData
    self.m_nBankerUser_ = tData.wBankerUser
    self.m_tPlayStatues_ = tData.cbPlayStatus
    self.m_tOx_ = tData.bOxCard
    self.m_eGameStatues_ = cmd.GameStatues.START_STATUES

    --ui
    self._gameView:showPlayStatues(tData)
end

function GameLayer:onEventUserStatus(useritem,newstatus,oldstatus)
    if self._gameView then 
        if useritem.dwUserID ~= GlobalUserItem.dwUserID then
            if newstatus.cbUserStatus == yl.US_FREE and oldstatus.cbUserStatus > yl.US_FREE and self._gameFrame:GetTableID() == oldstatus.wTableID then
                 print("同一桌子的人离开")
                 self._gameView:updateUserInfo(oldstatus.wChairID)
            elseif newstatus.cbUserStatus >= yl.US_SIT and self._gameFrame:GetTableID() == useritem.wTableID then
                print("同一桌子的人进入")
                self._gameView:updateUserInfo(useritem.wChairID)
            end
        else 
            if newstatus.cbUserStatus == yl.US_READY then
                self.m_eGameStatues_ = cmd.GameStatues.READY_STATUES
                 --ui
                self._gameView:showReady()      
            end
        end
    end
end

-- 游戏消息
function GameLayer:onEventGameMessage(sub,dataBuffer)
	if sub == cmd.SUB_S_GAME_START then 
		self:onSubGameStart(dataBuffer)
	elseif sub == cmd.SUB_S_OPEN_CARD then 
		self:OnSubOpenCard(dataBuffer)
	elseif sub == cmd.SUB_S_PLAYER_EXIT then 
		self:OnSubPlayerExit(dataBuffer)
	elseif sub == cmd.SUB_S_GAME_END then 
		self:OnSubGameEnd(dataBuffer)
	elseif sub == cmd.SUB_S_ADMIN_STORAGE_INFO then 
		self:onSubAdminStorageInfo(dataBuffer)
	elseif sub == cmd.SUB_S_REQUEST_QUERY_RESULT then 
		self:OnSubRequestQueryResult(dataBuffer)
	elseif sub == cmd.SUB_S_USER_CONTROL then 
		self:onSubUserControl(dataBuffer)
    elseif sub == cmd.SUB_S_USER_CONTROL_COMPLETE then 
		self:onSubUserControlComplete(dataBuffer)
    elseif sub == cmd.SUB_S_OPERATION_RECORD then 
		self:onSubOperationRecord(dataBuffer)
    elseif sub == cmd.SUB_S_REQUEST_UDPATE_ROOMINFO_RESULT then 
		self:onSubUpdateRoomInfo(dataBuffer)
	else
		print("unknow gamemessage sub is"..sub)
	end
end

--游戏开始
function GameLayer:onSubGameStart(dataBuffer)
    local tData = self._msgModel:readSubGameStart(dataBuffer)
    self.m_tHandCardData_ = tData.cbCardData
    self.m_nBankerUser_ = tData.wBankerUser
    self.m_tPlayStatues_ = tData.cbPlayStatus

    self.m_eGameStatues_ = cmd.GameStatues.START_STATUES
    --ui
    self._gameView:showGameStart()
end

--用户摊牌
function GameLayer:OnSubOpenCard(dataBuffer)
    -- body
    local tData = self._msgModel:readSubOpenCard(dataBuffer)

    self.m_tOx_[tData.wPlayerID+1] = tData.bOpen
    if self._gameFrame:GetChairID() == tData.wPlayerID then
         self.m_eGameStatues_ = cmd.GameStatues.OPENCARD_STATUES
    end

    --ui
    self._gameView:showOpenCard(tData)
end

--用户强退
function GameLayer:OnSubPlayerExit(dataBuffer)
    local wPlayerID = self._msgModel:readSubPlayerExit(dataBuffer)
    self.m_tPlayStatues_[wPlayerID+1] = 0

    --ui
    self._gameView:dealGameExit(wPlayerID)
    pring("用户强退")
end

--游戏结束
function GameLayer:OnSubGameEnd(dataBuffer)
    -- body
    local tData = self._msgModel:readSubGameEnd(dataBuffer)
    self.m_eGameStatues_ = cmd.GameStatues.END_STATUES
     --ui
    self._gameView:showGameEnd(tData)
end

--特殊客户端信息
function GameLayer:onSubAdminStorageInfo(dataBuffer)
    local tData = self._msgModel:readSubAdminStorageInfo(dataBuffer)
end

--查询用户结果
function GameLayer:OnSubRequestQueryResult(dataBuffer)
    -- body
    local tData = self._msgModel:readSubRequestQueryResult(dataBuffer)
end

--用户控制
function GameLayer:onSubUserControl(dataBuffer)
    local tData = self._msgModel:readSubUserControl(dataBuffer)
end

--用户控制结果
function GameLayer:onSubUserControlComplete(dataBuffer)
    local tData = self._msgModel:readSubUserControlComplete(dataBuffer)
end

--操作记录
function GameLayer:onSubOperationRecord(dataBuffer)
    local tData = self._msgModel:readSubOperationRecord(dataBuffer)
end

function GameLayer:onSubUpdateRoomInfo(dataBuffer)
   local tData = self._msgModel:readSubUpdateRoomInfo(dataBuffer)
end

function GameLayer:onUserChat(chatData)
    --ui
    self._gameView:showChat(chatData)
end

function GameLayer:onUserExpression(chatPresData)
    --ui
    self._gameView:showChat(chatPresData)
end
----------------------------------------------------------------逻辑-------------------------------------------------------------------
--取整
function GameLayer:getIntPart(x)
    if x <= 0 then
       return math.ceil(x);
    end

    if math.ceil(x) == x then
       x = math.ceil(x);
    else
       x = math.ceil(x) - 1;
    end
    return x;
end
--转换钱
function GameLayer:convertMoneyToString(money,nWan)
    local iWan = nWan or 10000
    if type(money) == "string" then
        money = tonumber(money)
    end
	if money < iWan then
		return tostring(money)
	elseif money >= iWan and money < 100000000 then
        local dstStr = ""
		local sWan = "万"
		local oneNum = money / 10000;
        oneNum = self:getIntPart(oneNum)
		local twoNum = (money - oneNum * 10000) / 100
        twoNum = self:getIntPart(twoNum)
		if twoNum == 0 then
			dstStr = tostring(oneNum)
			dstStr = dstStr .. sWan
		else
			if twoNum > 10 then
                local a1 = twoNum/10
				local a2 = self:getIntPart(a1)
				if a2 == a1 then
					dstStr = string.format("%d.%d", oneNum, a2)
				else
					dstStr = string.format("%d.%d", oneNum, twoNum)
				end	
                dstStr = dstStr .. sWan
			elseif twoNum < 10 then
				dstStr = string.format("%d.0%d", oneNum, twoNum)
				dstStr = dstStr .. sWan
			else
				dstStr = string.format("%d.%d", oneNum, twoNum/10)
				dstStr = dstStr .. sWan
			end
		end

        return dstStr
	else
        local dstStr = ""
		local sYi = "亿"
		local oneNum = money / 100000000
        oneNum = self:getIntPart(oneNum)
		local twoNum = (money - oneNum * 100000000) / 1000000
        twoNum = self:getIntPart(twoNum)
		if twoNum == 0 then
			dstStr = tostring(oneNum)
			dstStr = dstStr .. sYi
		else
            if twoNum > 10 then
                local a1 = twoNum/10
				local a2 = self:getIntPart(a1)
				if a2 == a1 then
					dstStr = string.format("%d.%d", oneNum, a2)
				else
					dstStr = string.format("%d.%d", oneNum, twoNum)
				end	
                dstStr = dstStr .. sYi
			elseif twoNum < 10 then
				dstStr = string.format("%d.0%d", oneNum, twoNum)
				dstStr = dstStr .. sYi
			else
				dstStr = string.format("%d.%d", oneNum, twoNum/10)
				dstStr = dstStr .. sYi
			end
		end
        return dstStr
	end
end

return GameLayer