local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")
local GameLayer = class("GameLayer", GameModel)

local module_pre = "game.qipai.land.src"
local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local cmd = appdf.req(module_pre .. ".models.CMD_Game")
local GameLogic = appdf.req(module_pre .. ".models.GameLogic")
local GameViewLayer = appdf.req(module_pre .. ".views.layer.GameViewLayer")
local GameResultLayer = appdf.req(module_pre .. ".views.layer.GameResultLayer")

function GameLayer:ctor( frameEngine,scene )        
    GameLayer.super.ctor(self, frameEngine, scene)
    self:OnInitGameEngine()
    self._roomRule = self._gameFrame._dwServerRule
    self.m_bLeaveGame = false    

    -- 一轮结束
    self.m_bRoundOver = false
    -- 自己是否是地主
    self.m_bIsMyBanker = false
    -- 地主座椅
    self.m_cbBankerChair = 0
    -- 提示牌数组
    self.m_tabPromptList = {}
    -- 当前出牌
    self.m_tabCurrentCards = {}
    -- 提示牌
    self.m_tabPromptCards = {}
    -- 比牌结果
    self.m_bLastCompareRes = false
    -- 上轮出牌视图
    self.m_nLastOutViewId = cmd.INVALID_VIEWID
    -- 上轮出牌
    self.m_tabLastCards = {}

    -- 是否叫分状态进入
    self.m_bCallStateEnter = false
end

--获取gamekind
function GameLayer:getGameKind()
    return cmd.KIND_ID
end

--创建场景
function GameLayer:CreateView()
    return GameViewLayer:create(self)
        :addTo(self)
end

function GameLayer:getParentNode( )
    return self._scene
end

function GameLayer:getFrame( )
    return self._gameFrame
end

function GameLayer:logData(msg)
    if nil ~= self._scene.logData then
        self._scene:logData(msg)
    end
end

function GameLayer:reSetData()
    self.m_bIsMyBanker = false
    self.m_tabPromptList = {}
    self.m_tabCurrentCards = {}
    self.m_tabPromptCards = {}
    self.m_bLastCompareRes = false
    self.m_nLastOutViewId = cmd.INVALID_VIEWID
    self.m_tabLastCards = {}    
end

---------------------------------------------------------------------------------------
------继承函数
function GameLayer:onEnterTransitionFinish()
    GameLayer.super.onEnterTransitionFinish(self)
end

function GameLayer:onExit()
    self:KillGameClock()
    self:dismissPopWait()
    GameLayer.super.onExit(self)
end

--退出桌子
function GameLayer:onExitTable()
    self:KillGameClock()
    local MeItem = self:GetMeUserItem()
    if MeItem and MeItem.cbUserStatus > yl.US_FREE then
        self:showPopWait()
        self:runAction(cc.Sequence:create(
            cc.CallFunc:create(
                function () 
                    self._gameFrame:StandUp(1)
                end
                ),
            cc.DelayTime:create(10),
            cc.CallFunc:create(
                function ()
                    print("delay leave")
                    self:onExitRoom()
                end
                )
            )
        )
        return
    end

   self:onExitRoom()
end

--离开房间
function GameLayer:onExitRoom()
    self._scene:onKeyBack()
end

-- 计时器响应
function GameLayer:OnEventGameClockInfo(chair,time,clockId)
    if nil ~= self._gameView and nil ~= self._gameView.updateClock then
        self._gameView:updateClock(clockId, time)
    end
end

-- 设置计时器
function GameLayer:SetGameClock(chair,id,time)
    GameLayer.super.SetGameClock(self,chair,id,time)
end

function GameLayer:onGetSitUserNum()
    return table.nums(self._gameView.m_tabUserHead)
end

function GameLayer:getUserInfoByChairID( chairid )
    local viewId = self:SwitchViewChairID(chairid)
    return self._gameView.m_tabUserItem[viewId]
end

function GameLayer:OnResetGameEngine()
    self:reSetData() 
    GameLayer.super.OnResetGameEngine(self)
end

-- 刷新提示列表
-- @param[cards]        出牌数据
-- @param[handCards]    手牌数据
-- @param[outViewId]    出牌视图id
-- @param[curViewId]    当前视图id
function GameLayer:updatePromptList(cards, handCards, outViewId, curViewId)
    self.m_tabCurrentCards = cards
    self.m_tabPromptList = {}

    local result = {}
    if outViewId == curViewId then
        self.m_tabCurrentCards = {}
        result = GameLogic:SearchOutCard(handCards, #handCards, {}, 0)
    else
        result = GameLogic:SearchOutCard(handCards, #handCards, cards, #cards)
    end

    --dump(result, "出牌提示", 6)    
    local resultCount = result[1]
    print("## 提示牌组 " .. resultCount)
    for i = resultCount, 1, -1 do
        local tmplist = {}
        local total = result[2][i]
        local cards = result[3][i]
        for j = 1, total do
            local cbCardData = cards[j] or 0
            table.insert(tmplist, cbCardData)
        end
        table.insert(self.m_tabPromptList, tmplist)
    end
    self.m_tabPromptCards = self.m_tabPromptList[#self.m_tabPromptList] or {}
    self._gameView.m_promptIdx = 0
end

-- 扑克对比
-- @param[cards]        当前出牌
-- @param[outView]      出牌视图id
function GameLayer:compareWithLastCards( cards, outView)
    local bRes = false
    self.m_bLastCompareRes = false
    local outCount = #cards
    if outCount > 0 then
        if outView ~= self.m_nLastOutViewId then
            --返回true，表示cards数据大于m_tagLastCards数据
            self.m_bLastCompareRes = GameLogic:CompareCard(self.m_tabLastCards, #self.m_tabLastCards, cards, outCount)
            self.m_nLastOutViewId = outView
        end
        self.m_tabLastCards = cards
    end
    return bRes
end

------------------------------------------------------------------------------------------------------------
--网络处理
------------------------------------------------------------------------------------------------------------

-- 发送准备
function GameLayer:sendReady()
    self:KillGameClock()
    self._gameFrame:SendUserReady()
end

-- 发送叫分
function GameLayer:sendCallScore( score )
    self:KillGameClock()
    local cmddata = CCmd_Data:create(1)
    cmddata:pushbyte(score)
    self:SendData(cmd.SUB_C_CALL_SCORE,cmddata)
end

-- 发送出牌
function GameLayer:sendOutCard(cards, bPass)
    self:KillGameClock()
    if bPass then
        local cmddata = CCmd_Data:create()
        self:SendData(cmd.SUB_C_PASS_CARD,cmddata)
    else
        local cardcount = #cards
        local cmddata = CCmd_Data:create(1 + cardcount)
        cmddata:pushbyte(cardcount)
        for i = 1, cardcount do
            cmddata:pushbyte(cards[i])
        end
        self:SendData(cmd.SUB_C_OUT_CARD,cmddata)
    end
end

-- 场景信息
function GameLayer:onEventGameScene(cbGameStatus,dataBuffer)
    print("场景数据:" .. cbGameStatus)
    if self.m_bOnGame then
        return
    end
    self.m_cbGameStatus = cbGameStatus
    self.m_bOnGame = true
    --初始化已有玩家
    for i = 1, cmd.PLAYER_COUNT do
        local userItem = self._gameFrame:getTableUserItem(self._gameFrame:GetTableID(), i-1)
        if nil ~= userItem then
            local wViewChairId = self:SwitchViewChairID(i-1)
            self._gameView:OnUpdateUser(wViewChairId, userItem)
            if PriRoom then
                PriRoom:getInstance():onEventUserState(wViewChairId, userItem, false)
            end
        end
    end
    
    if cbGameStatus == cmd.GAME_SCENE_FREE then                                 --空闲状态
        self:onEventGameSceneFree(dataBuffer)
    elseif cbGameStatus == cmd.GAME_SCENE_CALL then                             --叫分状态
        self.m_bCallStateEnter = true
        self:onEventGameSceneCall(dataBuffer)        
    elseif cbGameStatus == cmd.GAME_SCENE_PLAY then                             --游戏状态
        self:onEventGameScenePlay(dataBuffer)
    end
    self:dismissPopWait()
end

function GameLayer:onEventGameSceneFree( dataBuffer )
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_StatusFree, dataBuffer)
    dump(cmd_table, "scene free", 6)
    cmd.COUNTDOWN_READY = cmd_table.cbTimeStartGame
    cmd.COUNTDOWN_CALLSCORE = cmd_table.cbTimeCallScore
    cmd.COUNTDOWN_OUTCARD = cmd_table.cbTimeOutCard
    cmd.COUNTDOWN_HANDOUTTIME = cmd_table.cbTimeHeadOutCard
    -- 更新底分
    self._gameView:onGetCellScore(cmd_table.lCellScore)

    -- 空闲消息
    self._gameView:onGetGameFree()

    self:KillGameClock()
    -- 私人房无倒计时
    if not GlobalUserItem.bPrivateRoom then
        -- 设置倒计时
        self:SetGameClock(self:GetMeChairID(), cmd.TAG_COUNTDOWN_READY, cmd.COUNTDOWN_READY)
    end    
end

function GameLayer:onEventGameSceneCall( dataBuffer )
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_StatusCall, dataBuffer)
    dump(cmd_table, "scene call", 6)
    cmd.COUNTDOWN_READY = cmd_table.cbTimeStartGame
    cmd.COUNTDOWN_CALLSCORE = cmd_table.cbTimeCallScore
    cmd.COUNTDOWN_OUTCARD = cmd_table.cbTimeOutCard
    cmd.COUNTDOWN_HANDOUTTIME = cmd_table.cbTimeHeadOutCard

    self.m_bRoundOver = false
    -- 更新底分
    self._gameView:onGetCellScore(cmd_table.lCellScore)
 
    -- 叫分信息
    local scoreinfo = cmd_table.cbScoreInfo[1]
    local tmpScore = 0
    local lastScore = 0
    local lastViewId = self:SwitchViewChairID(cmd_table.wCurrentUser)
    for i = 1, 3 do
        local chair = i - 1
        local score = scoreinfo[i]
        -- 扑克
        local viewId = self:SwitchViewChairID(chair)
        if chair ~= cmd_table.wCurrentUser and 0 ~= score then
            self._gameView:onGetCallScore(-1, viewId, 0, score, true)
        end

        if 0 ~= score then
            tmpScore = ((score == 255) and 0 or score)
        end

        if tmpScore > lastScore then
            lastScore = tmpScore
            lastViewId = viewId
        end
    end
    -- 叫分状态
    local currentScore = cmd_table.cbBankerScore
    local curViewId = self:SwitchViewChairID(cmd_table.wCurrentUser)

    -- 玩家拿牌
    local cards = GameLogic:SortCardList(cmd_table.cbHandCardData[1], cmd.NORMAL_COUNT, 0)
    self._gameView:onGetGameCard(cmd.MY_VIEWID, cards, true)
    -- 其余玩家
    local empTyCard = GameLogic:emptyCardList(cmd.NORMAL_COUNT)
    self._gameView:onGetGameCard(cmd.LEFT_VIEWID, empTyCard, true)
    empTyCard = GameLogic:emptyCardList(cmd.NORMAL_COUNT)
    self._gameView:onGetGameCard(cmd.RIGHT_VIEWID, empTyCard, true)

    self._gameView:onGetCallScore(curViewId, lastViewId, currentScore, lastScore, false)
    -- 设置倒计时
    self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_CALLSCORE, cmd.COUNTDOWN_CALLSCORE)

    -- 刷新局数
    if PriRoom and GlobalUserItem.bPrivateRoom then
        local curcount = PriRoom:getInstance().m_tabPriData.dwPlayCount
        PriRoom:getInstance().m_tabPriData.dwPlayCount = curcount - 1
        if nil ~= self._gameView._priView and nil ~= self._gameView._priView.onRefreshInfo then
            self._gameView._priView:onRefreshInfo()
        end
    end
end

function GameLayer:onEventGameScenePlay( dataBuffer )
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_StatusPlay, dataBuffer)
    dump(cmd_table, "scene play", 6)
    cmd.COUNTDOWN_READY = cmd_table.cbTimeStartGame
    cmd.COUNTDOWN_CALLSCORE = cmd_table.cbTimeCallScore
    cmd.COUNTDOWN_OUTCARD = cmd_table.cbTimeOutCard
    cmd.COUNTDOWN_HANDOUTTIME = cmd_table.cbTimeHeadOutCard

    self.m_bRoundOver = false
    -- 更新底分
    self._gameView:onGetCellScore(cmd_table.lCellScore)

    -- 用户手牌
    local countlist = cmd_table.cbHandCardCount[1]
    for i = 1, 3 do
        local chair = i - 1
        local cards = {}
        local count = countlist[i]
        local viewId = self:SwitchViewChairID(chair)
        if cmd.MY_VIEWID == viewId then
            local tmp = cmd_table.cbHandCardData[1]
            for j = 1, count do
                table.insert(cards, tmp[j])
            end
            cards = GameLogic:SortCardList(cards, count, 0)
        else
            cards = GameLogic:emptyCardList(count)
        end
        self._gameView:onGetGameCard(viewId, cards, true)
    end

    -- 庄家信息    
    local bankerView = self:SwitchViewChairID(cmd_table.wBankerUser)
    local bankerCards = GameLogic:SortCardList(cmd_table.cbBankerCard[1], 3, 0)
    local bankerscore = cmd_table.cbBankerScore
    if self:IsValidViewID(bankerView) then
        self._gameView:onGetBankerInfo(bankerView, bankerscore, bankerCards, true)
    end
    self.m_cbBankerChair = cmd_table.wBankerUser
    -- 自己是否庄家
    self.m_bIsMyBanker = (bankerView == cmd.MY_VIEWID)
    
    -- 出牌信息
    local cbOutTime = cmd_table.cbTimeOutCard
    local lastOutView = self:SwitchViewChairID(cmd_table.wTurnWiner)
    local outCards = {}
    local serverOut = cmd_table.cbTurnCardData[1]
    for i = 1, cmd_table.cbTurnCardCount do
        table.insert(outCards, serverOut[i])
    end
    outCards = GameLogic:SortCardList(outCards, cmd_table.cbTurnCardCount, 0)
    local currentView = self:SwitchViewChairID(cmd_table.wCurrentUser)
    if self:IsValidViewID(lastOutView) and self:IsValidViewID(currentView) then
        self.m_nLastOutViewId = lastOutView
        self:compareWithLastCards(outCards, lastOutView)

        if currentView == cmd.MY_VIEWID then
            -- 构造提示
            local handCards = self._gameView.m_tabNodeCards[cmd.MY_VIEWID]:getHandCards()
            self:updatePromptList(outCards, handCards, currentView, lastOutView)
        end

        -- 不出按钮
        if #self.m_tabPromptList > 0 then
            self._gameView:onChangePassBtnState(not (currentView == lastOutView--[[#self.m_tabPromptList > 0]]))
        else
            self._gameView:onChangePassBtnState( true )
        end        

        self._gameView:onGetOutCard(currentView, lastOutView, outCards, true)

        -- 设置倒计时
        self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_OUTCARD, cmd.COUNTDOWN_OUTCARD)
    end
end

function GameLayer:onEventGameMessage(sub,dataBuffer)
    if nil == self._gameView then
        return
    end

    if cmd.SUB_S_GAME_START == sub then                 --游戏开始
        self.m_cbGameStatus = cmd.GAME_SCENE_CALL
        self:onSubGameStart(dataBuffer)
    elseif cmd.SUB_S_CALL_SCORE == sub then             --用户叫分
        self.m_cbGameStatus = cmd.GAME_SCENE_CALL
        self:onSubCallScore(dataBuffer)
    elseif cmd.SUB_S_BANKER_INFO == sub then            --庄家信息
        self.m_cbGameStatus = cmd.GAME_SCENE_PLAY
        self:onSubBankerInfo(dataBuffer)
    elseif cmd.SUB_S_OUT_CARD == sub then               --用户出牌
        self.m_cbGameStatus = cmd.GAME_SCENE_PLAY
        self:onSubOutCard(dataBuffer)
    elseif cmd.SUB_S_PASS_CARD == sub then              --用户放弃
        self.m_cbGameStatus = cmd.GAME_SCENE_PLAY
        self:onSubPassCard(dataBuffer)
    elseif cmd.SUB_S_GAME_CONCLUDE == sub then          --游戏结束
        self.m_cbGameStatus = cmd.GAME_SCENE_END
        self:onSubGameConclude(dataBuffer)
    end
end

-- 文本聊天
function GameLayer:onUserChat(chatdata, chairid)
    local viewid = self:SwitchViewChairID(chairid)    
    if self:IsValidViewID(viewid) then
        self._gameView:onUserChat(chatdata, viewid)
    end
end

-- 表情聊天
function GameLayer:onUserExpression(chatdata, chairid)
    local viewid = self:SwitchViewChairID(chairid)
    if self:IsValidViewID(viewid) then
        self._gameView:onUserExpression(chatdata, viewid)
    end
end

-- 语音播放开始
function GameLayer:onUserVoiceStart( useritem, filepath )
    local viewid = self:SwitchViewChairID(useritem.wChairID)
    local roleItem = self._gameView.m_tabUserHead[viewid]
    if nil ~= roleItem then
        roleItem:onUserVoiceStart()
    end
end

-- 语音播放结束
function GameLayer:onUserVoiceEnded( useritem, filepath )
    local viewid = self:SwitchViewChairID(useritem.wChairID)
    local roleItem = self._gameView.m_tabUserHead[viewid]
    if nil ~= roleItem then
        roleItem:onUserVoiceEnded()
    end
end

-- 游戏开始
function GameLayer:onSubGameStart(dataBuffer)
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_GameStart, dataBuffer)
    --dump(cmd_table, "onSubGameStart", 6)

    self.m_bRoundOver = false
    self:reSetData()
    --游戏开始
    self._gameView:onGameStart()
    local curView = self:SwitchViewChairID(cmd_table.wCurrentUser)
    local startView = self:SwitchViewChairID(cmd_table.wStartUser)   

    self:KillGameClock()
    if self:IsValidViewID(curView) and self:IsValidViewID(startView) then
        print("&& 游戏开始 " .. curView .. " ## " .. startView)
        -- 音效
        ExternalFun.playSoundEffect( "start.wav" )
        --发牌
        local carddata = GameLogic:SortCardList(cmd_table.cbCardData[1], cmd.NORMAL_COUNT, 0)
        self._gameView:onGetGameCard(cmd.MY_VIEWID, carddata, false, cc.CallFunc:create(function()
            self._gameView:onGetCallScore(curView, startView, 0, -1)
            -- 设置倒计时
            self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_CALLSCORE, cmd.COUNTDOWN_CALLSCORE)
        end))
    else
        print("viewid invalid" .. curView .. " ## " .. startView)
    end
end

-- 用户叫分
function GameLayer:onSubCallScore(dataBuffer)
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_CallScore, dataBuffer)
    --dump(cmd_table, "CMD_S_CallScore", 3)

    local curView = self:SwitchViewChairID(cmd_table.wCurrentUser)
    local lastView = self:SwitchViewChairID(cmd_table.wCallScoreUser)    
    if self:IsValidViewID(curView) and self:IsValidViewID(lastView) then
        print("&& 游戏叫分 " .. curView .. " ## " .. lastView)
        self._gameView:onGetCallScore(curView, lastView, cmd_table.cbCurrentScore, cmd_table.cbUserCallScore)

        -- 设置倒计时
        self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_CALLSCORE, cmd.COUNTDOWN_CALLSCORE)
    else
        print("viewid invalid" .. curView .. " ## " .. lastView)
    end    
end

-- 庄家信息
function GameLayer:onSubBankerInfo(dataBuffer)
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_BankerInfo, dataBuffer)
    --dump(cmd_table, "onSubBankerInfo", 6)
    local bankerView = self:SwitchViewChairID(cmd_table.wBankerUser)
    local curView = self:SwitchViewChairID(cmd_table.wCurrentUser)

    -- 自己是否庄家
    self.m_bIsMyBanker = (bankerView == cmd.MY_VIEWID)

    -- 庄家信息
    if self:IsValidViewID(bankerView) and self:IsValidViewID(curView) then
        print("&& 庄家信息 " .. bankerView .. " ## " .. curView)
        -- 音效
        ExternalFun.playSoundEffect( "bankerinfo.wav" )

        self.m_cbBankerViewId = cmd_table.wBankerUser
        local bankercard = GameLogic:SortCardList(cmd_table.cbBankerCard[1], 3, 0)
        self._gameView:onGetBankerInfo(bankerView, cmd_table.cbBankerScore, bankercard, false)

        self.m_nLastOutViewId = bankerView
        -- 构造提示
        local handCards = self._gameView.m_tabNodeCards[bankerView]:getHandCards()
        if bankerView == cmd.MY_VIEWID then
            self:updatePromptList({}, handCards, cmd.MY_VIEWID, cmd.MY_VIEWID)

            -- 不出按钮
            self._gameView:onChangePassBtnState(false)

            -- 开始出牌
            self._gameView:onGetOutCard(curView, curView, {})
        end
        -- 设置倒计时
        self:SetGameClock(cmd_table.wBankerUser, cmd.TAG_COUNTDOWN_OUTCARD, cmd.COUNTDOWN_HANDOUTTIME)
    else
        print("viewid invalid" .. bankerView .. " ## " .. curView)
    end

    -- 刷新局数
    if PriRoom and not self.m_bCallStateEnter and GlobalUserItem.bPrivateRoom then
        local curcount = PriRoom:getInstance().m_tabPriData.dwPlayCount
        PriRoom:getInstance().m_tabPriData.dwPlayCount = curcount + 1
        if nil ~= self._gameView._priView and nil ~= self._gameView._priView.onRefreshInfo then
            self._gameView._priView:onRefreshInfo()
        end
    end
    self.m_bCallStateEnter = false
end

-- 用户出牌
function GameLayer:onSubOutCard(dataBuffer)
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_OutCard, dataBuffer)
    --dump(cmd_table, "onSubOutCard", 6)

    local curView = self:SwitchViewChairID(cmd_table.wCurrentUser)
    local outView = self:SwitchViewChairID(cmd_table.wOutCardUser)

    print("&& 出牌 " .. outView .. " ## " .. curView)
    local outCard = cmd_table.cbCardData[1]
    local outCount = #outCard
    local carddata = GameLogic:SortCardList(outCard, outCount, 0)
    -- 扑克对比
    self:compareWithLastCards(carddata, outView)

    -- 构造提示
    local handCards = self._gameView.m_tabNodeCards[cmd.MY_VIEWID]:getHandCards()
    self:updatePromptList(carddata, handCards, outView, curView)

    -- 不出按钮
    self._gameView:onChangePassBtnState(true)

    self._gameView:onGetOutCard(curView, outView, carddata)

    -- 设置倒计时
    self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_OUTCARD, cmd.COUNTDOWN_OUTCARD)
end

-- 用户放弃
function GameLayer:onSubPassCard(dataBuffer)
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_PassCard, dataBuffer)
    --dump(cmd_table, "onSubPassCard", 6)

    local curView = self:SwitchViewChairID(cmd_table.wCurrentUser)
    local passView = self:SwitchViewChairID(cmd_table.wPassCardUser)
    if self:IsValidViewID(curView) and self:IsValidViewID(passView) then
        print("&& pass " .. curView .. " ## " .. passView)
        if 1 == cmd_table.cbTurnOver then
            print("一轮结束")
            self:compareWithLastCards({}, curView)
            -- 构造提示
            local handCards = self._gameView.m_tabNodeCards[cmd.MY_VIEWID]:getHandCards()
            self:updatePromptList({}, handCards, curView, curView)

            -- 不出按钮
            self._gameView:onChangePassBtnState(false)
        end
        -- 不出牌
        self._gameView:onGetPassCard(passView)

        self._gameView:onGetOutCard(curView, curView, {})

        -- 设置倒计时
        self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_OUTCARD, cmd.COUNTDOWN_OUTCARD)
    else
        print("viewid invalid" .. curView .. " ## " .. passView)
    end
end

-- 游戏结束
function GameLayer:onSubGameConclude(dataBuffer)
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_GameConclude, dataBuffer)
    --dump(cmd_table, "onSubGameConclude", 6)
    -- 音效
    ExternalFun.playSoundEffect( "gameconclude.wav" )

    self.m_bRoundOver = true
    local str = ""
    local rs = GameResultLayer.getTagGameResult()

    local scorelist = cmd_table.lGameScore[1]
    local countlist = cmd_table.cbCardCount[1]
    local cardlist = cmd_table.cbHandCardData[1]
    local haveCount = 0
    for i = 1, 3 do
        local chair = i - 1
        local viewId = self:SwitchViewChairID(chair)

        -- 结算
        local score = scorelist[i]
        if score > 0 then
            str = "+" .. score
        else
            str = "" .. score
        end
        local settle = GameResultLayer.getTagSettle()
        settle.m_userName = self._gameView:getUserNick(viewId)
        settle.m_settleCoin = str
        if cmd.MY_VIEWID == viewId then
            rs.enResult = self:getWinDir(score)
        end
        rs.settles[i] = settle

        -- 手牌
        local count = countlist[i]
        local cards = {}
        for j = 1, count do 
            table.insert(cards, cardlist[j + haveCount])
        end
        haveCount = haveCount + count
        if count > 0 then
            self._gameView.m_tabNodeCards[viewId]:showLeftCards(cards)
        end
    end
    -- 标志
    for i = 1, 3 do
        local chair = i - 1
        -- 春天
        if 1 == cmd_table.bChunTian then
            if chair == self.m_cbBankerViewId then
                rs.settles[i].m_cbFlag = cmd.kFlagChunTian
            end
        end

        -- 反春天
        if 1 == cmd_table.bFanChunTian then
            if chair ~= self.m_cbBankerViewId then
                rs.settles[i].m_cbFlag = cmd.kFlagFanChunTian
            end
        end
    end

    self._gameView:onGetGameConclude( rs )

    self:KillGameClock()
    -- 私人房无倒计时
    if not GlobalUserItem.bPrivateRoom then
        -- 设置倒计时
        self:SetGameClock(self:GetMeChairID(), cmd.TAG_COUNTDOWN_READY, cmd.COUNTDOWN_READY)
    end

    self:reSetData()
end
------------------------------------------------------------------------------------------------------------
--网络处理
------------------------------------------------------------------------------------------------------------

function GameLayer:getWinDir( score )
    print("## is my Banker")
    print(self.m_bIsMyBanker)
    print("## is my Banker")
    if true == self.m_bIsMyBanker then
        if score > 0 then
            return cmd.kLanderWin
        elseif score < 0 then
            return cmd.kLanderLose
        end
    else
        if score > 0 then
            return cmd.kFarmerWin
        elseif score < 0 then
            return cmd.kFarmerLose
        end
    end
    return cmd.kDefault
end
return GameLayer