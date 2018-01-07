local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")
local GameLayer = class("GameLayer", GameModel)

local module_pre = "game.yule.510k.src"
local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local cmd = appdf.req(module_pre .. ".models.CMD_Game")
local game_cmd = appdf.CLIENT_SRC..".plaza.models.CMD_GameServer"
local GameLogic = appdf.req(module_pre .. ".models.GameLogic")
local GameViewLayer = appdf.req(module_pre .. ".views.layer.GameViewLayer")
local ResultLayer = appdf.req(module_pre .. ".views.layer.ResultLayer")


function GameLayer.registerTouchEvent(node, bSwallow, FixedPriority)
    local function onTouchBegan( touch, event )
        if nil == node.onTouchBegan then
            return false
        end
        return node:onTouchBegan(touch, event)
    end

    local function onTouchMoved(touch, event)
        if nil ~= node.onTouchMoved then
            node:onTouchMoved(touch, event)
        end
    end

    local function onTouchEnded( touch, event )
        if nil ~= node.onTouchEnded then
            node:onTouchEnded(touch, event)
        end       
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(bSwallow)
    node._listener = listener
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = node:getEventDispatcher()
    eventDispatcher:addEventListenerWithFixedPriority(listener, FixedPriority)
end



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

    self.m_lTurnScore = {}

    self.lCollectScore = {}
    -- 是否叫分状态进入
    self.m_bCallStateEnter = false

    self.m_gameScenePlay = {}

    self.m_wXuanZhanUser = 0

    self.m_wBankerUser = 0 

    self.m_wCurrentUser = 0 

    self.m_cbAskStatus = {}

    self.m_wNoDeclareCount = 0 --没宣战玩家数

    self.m_wNoAskFriendCount = 0 --没宣战玩家数

    self.m_addTimes = 1 --个人翻倍

    self.m_tab_cbFriendFlag = {} --

    self.m_tab_cbAddTimesFlag = {}

    self.m_cbFriendFlag = 0

    self.m_wFriend = {}

    self.m_bCanTrustee = false

    self.m_wLastOutCardUser = cmd.INVALID_CHAIRID

    self.m_wOutCardUser = cmd.INVALID_CHAIRID

    self.m_cbTurnCardCount = {}

    self.m_lCellScore = 1
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
    local resultCount = 0
    resultCount = result[1]
    print("## 提示牌组 " .. resultCount)
    if resultCount > 0 then
        for i = resultCount, 1, -1 do
            local tmplist = {}
            local total = result[2][i] 
            if total == nil then
                total = 0
            end
            local cards = result[3][i]
            for j = 1, total do
                local cbCardData = cards[j] or 0
                table.insert(tmplist, cbCardData)
            end
            if  total > 0 then
                table.insert(self.m_tabPromptList, tmplist)
            end
        end
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

--是否宣战
function GameLayer:sendDelareWar(cbDelare)
    local cmddata = CCmd_Data:create(1)
    cmddata:pushbyte(cbDelare)
    self:SendData(cmd.SUB_C_XUAN_ZHAN,cmddata)
end

--
function GameLayer:sendAskFriend(cbAsk)
    local cmddata = CCmd_Data:create(1)
    cmddata:pushbyte(cbAsk)
    self:SendData(cmd.SUB_C_ASK_FRIEND,cmddata)
end

function GameLayer:sendAddTimes(cbAdd)
    local cmddata = CCmd_Data:create(1)
    cmddata:pushbyte(cbAdd)
    self:SendData(cmd.SUB_C_ADD_TIMES,cmddata)
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

-- 发送叫分
function GameLayer:sendTrustees( cbTrustees )
    local cmddata = CCmd_Data:create(1)
    print("--- sendTrustees ---", cbTrustees)
    --cmddata:pushword(self:GetMeChairID())
    cmddata:pushbyte(cbTrustees)
    self:SendData(cmd.SUB_C_TRUSTEE,cmddata)
end

-- 语音播放开始
function GameLayer:onUserVoiceStart( useritem, filepath )
    local viewid = self:SwitchViewChairID(useritem.wChairID)
    self._gameView.m_tabVoiceBox[viewid]:setVisible(true)
end

-- 语音播放结束
function GameLayer:onUserVoiceEnded( useritem, filepath )
    local viewid = self:SwitchViewChairID(useritem.wChairID)
    self._gameView.m_tabVoiceBox[viewid]:setVisible(false)
end

-- 场景信息
function GameLayer:onEventGameScene(cbGameStatus,dataBuffer)
    print("场景数据:" .. cbGameStatus)
    if self.m_bOnGame then
        return
    end
    self.m_bOnGame = true
    --初始化已有玩家
    for i = 1, cmd.PLAYER_COUNT do
        local userItem = self._gameFrame:getTableUserItem(self._gameFrame:GetTableID(), i-1)
        if nil ~= userItem then
            local wViewChairId = self:SwitchViewChairID(i-1)
            self._gameView:OnUpdateUser(wViewChairId, userItem)
        end
    end
    self._gameView:initHistoryScore()
    self.m_cbGameStatus = cbGameStatus
    if cbGameStatus == cmd.GAME_GAME_FREE then                                 --空闲状态
        self:onEventGameSceneFree(dataBuffer)
    else--if cbGameStatus == cmd.GAME_SCENE_PLAY then                             --游戏状态
        self:onEventGameScenePlay(dataBuffer)
    end
    self:dismissPopWait()
    
end

function GameLayer:onEventGameMessage(sub,dataBuffer)
    if nil == self._gameView then
        return
    end
    print("onEventGameMessage",sub)
    if cmd.SUB_S_GAME_START == sub then                 --游戏开始
        self.m_cbGameStatus = cmd.GAME_XUAN_ZHAN
        self:onSubGameStart(dataBuffer)
    elseif cmd.SUB_S_XUAN_ZHAN == sub then             --用户宣战
        self.m_cbGameStatus = cmd.GAME_XUAN_ZHAN
        self:onSubDeclareWar(dataBuffer)
    elseif cmd.SUB_S_FIND_FRIEND == sub then            --用户找同盟
        self.m_cbGameStatus = cmd.GAME_FIND_FRIEND
        self:onSubFindFriend(dataBuffer)
    elseif cmd.SUB_S_ASK_FRIEND == sub then            --用户问同盟
        self.m_cbGameStatus = cmd.GAME_ASK_FRIEND
        self:onSubAskFriend(dataBuffer)
    elseif cmd.SUB_S_ADD_TIMES == sub then            --用户加倍
        self.m_cbGameStatus = cmd.GAME_ADD_TIMES
        self:onSubAddTimes(dataBuffer)
    elseif cmd.SUB_S_OUT_CARD == sub then               --用户出牌
        self.m_cbGameStatus = cmd.GAME_SCENE_PLAY
        self:onSubOutCard(dataBuffer)
    elseif cmd.SUB_S_PASS_CARD == sub then              --用户放弃
        self.m_cbGameStatus = cmd.GAME_SCENE_PLAY
        self:onSubPassCard(dataBuffer)
    elseif cmd.SUB_S_GAME_CONCLUDE == sub then          --游戏结束
        if PriRoom and GlobalUserItem.bPrivateRoom then
            self.m_cbGameStatus = cmd.GAME_SCENE_PLAY
        else
            self.m_cbGameStatus = cmd.GAME_GAME_FREE
        end
        self:onSubGameConclude(dataBuffer)
        self._gameView:hideAllAddTimesTip()
    elseif cmd.SUB_S_TRUSTEE == sub then                --用户托管
        self.m_cbGameStatus = cmd.GAME_SCENE_PLAY
        self:onSubTrustee(dataBuffer)
    elseif cmd.SUB_S_SET_BASESCORE == sub then                --设置基数
        self.m_cbGameStatus = cmd.GAME_SCENE_PLAY
        self:onSubBaseScore(dataBuffer)
    elseif cmd.SUB_S_TRUSTEE == sub then                --用户托管
        self.m_cbGameStatus = cmd.GAME_SCENE_PLAY

    end
end

-- 游戏开始
function GameLayer:onSubGameStart(dataBuffer)
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_GameStart, dataBuffer)
    dump(cmd_table, "onSubGameStart", 6)
    --[[
    cmd_table.myName = GlobalUserItem.szNickName
    cmd_table.myChairId = self._gameFrame:GetChairID()
    cmd_table.struct = "CMD_S_GameStart"
    local jsonStr = cjson.encode(cmd_table)
    LogAsset:getInstance():logData(jsonStr,true)
    --]]
    self.m_wCurrentUser = cmd_table.wCurrentUser
    self.m_wBankerUser = cmd_table.wBanker
    self.m_b2Biggest = cmd_table.b2Biggest
    GameLogic.m_b2Biggest = self.m_b2Biggest
    -- 玩家拿牌
    
        --]]
    --self._gameView.m_tabNodeCards[1]:updateCardsNode(cards, true, true)
    --self.m_tabNodeCards[1].dragCards(cards)

    self.m_bRoundOver = false
    self:reSetData()
    --游戏开始
    self._gameView:onGameStart()
    local cards = GameLogic:SortCardList(cmd_table.cbCardData[1], cmd.NORMAL_COUNT, 0)
    ---[[
    self._gameView:onGetGameCard(cmd.MY_VIEWID, cards, false, cc.CallFunc:create(function()
            if self.m_wCurrentUser == self._gameFrame:GetChairID() then
                self._gameView:presentDeclareWarBtns()
            end
            self:KillGameClock()
            self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_DECLAREWAR, cmd.COUNTDOWN_DECLAREWAR)
        end))
    --local curView = self:SwitchViewChairID(cmd_table.wCurrentUser)
    --local startView = self:SwitchViewChairID(cmd_table.wStartUser)   

    --self:KillGameClock()
    --self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_DECLAREWAR, cmd.COUNTDOWN_DECLAREWAR)

    
    -- 刷新局数
    if PriRoom and GlobalUserItem.bPrivateRoom then
        local curcount = PriRoom:getInstance().m_tabPriData.dwPlayCount
        PriRoom:getInstance().m_tabPriData.dwPlayCount = PriRoom:getInstance().m_tabPriData.dwPlayCount + 1
        if nil ~= self._gameView._priView and nil ~= self._gameView._priView.onRefreshInfo then
            self._gameView._priView:onRefreshInfo()
        end
    end
    --[[
    if self:IsValidViewID(curView) and self:IsValidViewID(startView) then
        print("&& 游戏开始 " .. curView .. " ## " .. startView)
        -- 音效
        ExternalFun.playSoundEffect( "start.wav" )
        --发牌
        local carddata = GameLogic:SortCardList(cmd_table.cbCardData[1], cmd.NORMAL_COUNT, 0)

        self._gameView:onGetGameCard(1, carddata, false, cc.CallFunc:create(function()
            --self._gameView:onGetCallScore(curView, startView, 0, -1)
            -- 设置倒计时
            self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_DECLAREWAR, cmd.COUNTDOWN_DECLAREWAR)
        end))
    else
        print("viewid invalid" .. curView .. " ## " .. startView)
    end
    --]]
end

function GameLayer:onSubDeclareWar( dataBuffer )
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_XuanZhan, dataBuffer)
    dump(cmd_table, "=========== onSubDeclareWar =========", 6)
    self:KillGameClock()
    self.m_wCurrentUser = cmd_table.wCurrentUser
    if false == cmd_table.bXuanZhan then
        self.m_wNoDeclareCount = self.m_wNoDeclareCount + 1
        if self.m_wNoDeclareCount >= 3 then
            self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_FIND_FRIEND, cmd.COUNTDOWN_FINDFRIEND)
            self._gameView:onGameDeclareWar(cmd_table.wXuanZhanUser,cmd_table.bXuanZhan)
        else
            self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_DECLAREWAR, cmd.COUNTDOWN_DECLAREWAR)
        end 
    else
        self.m_wXuanZhanUser = cmd_table.wCurrentUser
        self.m_bMingDu = true
        self.m_cbGameStatus = cmd.GAME_ADD_TIMES
        self:KillGameClock()
        self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_OUTCARD, cmd.COUNTDOWN_OUTCARD)
        if self._gameView.m_trusteeshipBg:isVisible() then

        end
        self._gameView:presentAddTimesBtns()
        self:SetFriendFlag()
        self._gameView:onGameDeclareWar(cmd_table.wXuanZhanUser,cmd_table.bXuanZhan)
        --[[
        self.m_wXuanZhanUser = cmd_table.wXuanZhanUser
        
        self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_OUTCARD, cmd.COUNTDOWN_OUTCARD)
        --]]
        
        

    end
    if cmd_table.wCurrentUser == self:GetMeChairID() and false == cmd_table.bXuanZhan  and self.m_wNoDeclareCount < 3 then
        self._gameView.m_bt_declareWar:setVisible(true)
        self._gameView.m_bt_no_declareWar:setVisible(true)
    end
end

function GameLayer:onSubFindFriend( dataBuffer )
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_FindFriend, dataBuffer)

    --LogAsset:getInstance():logData(jsonStr,true)
    --dump(cmd_table, " onSubFindFriend ", 6)
    self.m_wCurrentUser = cmd_table.wCurrentUser
    self:KillGameClock()
    self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_ASK_FRIEND, cmd.COUNTDOWN_ASKFRIEND)
    if cmd_table.wCurrentUser == self:GetMeChairID() then
        self._gameView:presentAskFriendBtns()
    else

    end

end

function GameLayer:onSubAskFriend( dataBuffer )
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_ASKFriend, dataBuffer)

    dump(cmd_table, " -------------- onSubAskFriend -------------------------", 6)
    self.m_wCurrentUser = cmd_table.wCurrentUser
    self.m_cbFriendFlag = cmd_table.cbFriendFlag
    
    if true == cmd_table.bAsk then --问了显示同盟
        self.m_wFriend = cmd_table.wFriend[1]
        self.m_wXuanZhanUser = cmd_table.wXuanZhanUser 
        self.m_bMingDu = cmd_table.bMingDu
        self:SetFriendFlag()
        self.m_cbGameStatus = cmd.GAME_ADD_TIMES
        self:KillGameClock()
        self:SetGameClock(self.m_wCurrentUser, cmd.TAG_COUNTDOWN_ADD_TIMES, cmd.COUNTDOWN_ADDTIME)
        if self.m_wCurrentUser == self:GetMeChairID() then
            if self._gameView.m_trusteeshipBg:isVisible() then

            end
            self._gameView:presentAddTimesBtns()
        else
            self.m_bWaitAddTimes = true
            self.m_bWaitAskFriend = false
        end
        self._gameView:onGameAskFriend(cmd_table)
    else
        self.m_wNoAskFriendCount = self.m_wNoAskFriendCount + 1

        if self.m_wNoAskFriendCount >= 4 then
            self._gameView:onGameAskFriend(cmd_table)
        end

        if self.m_wCurrentUser == self.m_wBankerUser then
            self:SetFriendFlag()
            self.m_cbGameStatus = cmd.GAME_SCENE_PLAY
            self:KillGameClock()
            self:SetGameClock(self.m_wCurrentUser, cmd.TAG_COUNTDOWN_OUTCARD, cmd.COUNTDOWN_OUTCARD)

            if self.m_wCurrentUser == self:GetMeChairID() then
                if self._gameView.m_trusteeshipBg:isVisible() then

                end
                local handCards = self._gameView.m_tabNodeCards[1]:getHandCards()
                self:updatePromptList({}, handCards, cmd.MY_VIEWID, cmd.MY_VIEWID)
                self._gameView:onGetOutCard(1, 1, {})
                self._gameView:onChangePassBtnState(false)
                self._gameView:presentOutCardsBtns()
            end
            if not GlobalUserItem.bPrivateRoom then
            self._gameView:setTrusteeBtnEnable(true)
            self._gameView:changeBtnState(self._gameView.m_bt_trusteeship,true)
        else
            self._gameView:setTrusteeBtnEnable(false)
            self._gameView:changeBtnState(self._gameView.m_bt_trusteeship,false)
        end  
            
        else
            self:KillGameClock()
            self:SetGameClock(self.m_wCurrentUser, cmd.TAG_COUNTDOWN_ASK_FRIEND, cmd.COUNTDOWN_ASKFRIEND)
            if self.m_wCurrentUser == self:GetMeChairID() then
                if self._gameView.m_trusteeshipBg:isVisible() then

                end
                self._gameView:presentAskFriendBtns()
                self.m_bWaitAskFriend = false
            else
                self.m_bWaitAskFriend = false
            end
        end
    end
    --self._gameView:onGameAskFriend(dataBuffer)

end

function GameLayer:onSubAddTimes( dataBuffer )
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_AddTimes, dataBuffer)
    --dump(cmd_table, " -------------- onSubAddTimes -------------------------", 6)
    local wViewChairID = self:SwitchViewChairID(cmd_table.wAddTimesUser)
    self.m_wCurrentUser = cmd_table.m_wCurrentUser
    local wAddTimesUser = cmd_table.wAddTimesUser
    self._gameView:onGameAddTimes(cmd_table)

    if cmd_table.wCurrentUser ~= cmd.INVALID_CHAIRID then
        self:KillGameClock()
        self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_OUTCARD, cmd.COUNTDOWN_OUTCARD)
        --初始化出牌界面
        if cmd_table.wCurrentUser == self:GetMeChairID() then
            if self._gameView.m_trusteeshipBg:isVisible() then

            end
            local handCards = self._gameView.m_tabNodeCards[1]:getHandCards()
            self:updatePromptList({}, handCards, cmd.MY_VIEWID, cmd.MY_VIEWID)
            self._gameView:onGetOutCard(1, 1, {})
            self._gameView:onChangePassBtnState(false)
            self._gameView:presentOutCardsBtns()


        end
        if not GlobalUserItem.bPrivateRoom then
            self._gameView:setTrusteeBtnEnable(true)
            self._gameView:changeBtnState(self._gameView.m_bt_trusteeship,true)
        else
            self._gameView:setTrusteeBtnEnable(false)
            self._gameView:changeBtnState(self._gameView.m_bt_trusteeship,false)
        end   
        self._gameView:hideAllAddTimesTip()
    end
end


function GameLayer:SetFriendFlag(dataBuffer)
    
    self._gameView:SetFriendFlag(cmd.INVALID_VIEWID,0)

    if self.m_cbFriendFlag == cmd.FRIEDN_FLAG_NORMAL then --正常
        for i = 1, cmd.PLAYER_COUNT do
            if i == self:GetMeChairID() or i == self.m_wFriend [self:GetMeChairID() + 1] then
                self._gameView:SetFriendFlag(i - 1,5)
            else
                self._gameView:SetFriendFlag(i - 1,2)
            end
        end
    elseif self.m_cbFriendFlag == cmd.FRIEDN_FLAG_DECLAREWAR then --宣战
        for i = 1, cmd.PLAYER_COUNT do
            if i - 1 == self.m_wXuanZhanUser then
                self._gameView:SetFriendFlag(i - 1,4)
            else
                if self.m_wXuanZhanUser == self:GetMeChairID() then
                    self._gameView:SetFriendFlag(i - 1,2)
                else
                    self._gameView:SetFriendFlag(i - 1,5)
                end
            end
        end
    elseif self.m_cbFriendFlag == cmd.FRIEDN_FLAG_MINGDU then
         for i = 1, cmd.PLAYER_COUNT do
            if i -1 == self.m_wXuanZhanUser then
                self._gameView:SetFriendFlag(i - 1,1)
            else
                if self.m_wXuanZhanUser == self:GetMeChairID() then
                    self._gameView:SetFriendFlag(i - 1,2)
                else
                    self._gameView:SetFriendFlag(i - 1,5)
                end
            end
         end
    else
        for i = 1, cmd.PLAYER_COUNT do
            if i -1 ~= self:GetMeChairID() then
                self._gameView:SetFriendFlag(i - 1,3)
            end
        end
    end
end
-- 用户出牌
function GameLayer:onSubOutCard(dataBuffer)
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_OutCard, dataBuffer)
    dump(cmd_table, "onSubOutCard", 6)
    local curView = self:SwitchViewChairID(cmd_table.wCurrentUser)
    local outView = self:SwitchViewChairID(cmd_table.wOutCardUser)
    self.m_wOutCardUser = cmd_table.wOutCardUser
    print("&& 出牌 " .. outView .. " current " .. curView)
    local outCard = cmd_table.cbCardData[1]
    local outCount = cmd_table.cbCardCount--#outCard
    local carddata = GameLogic:SortCardList(outCard, outCount, 0)

    carddata = self:getValidCardsData(carddata)
    -- 扑克对比
    self:compareWithLastCards(carddata, outView)
    self:KillGameClock()
    -- 构造提示
    local handCards = self._gameView.m_tabNodeCards[cmd.MY_VIEWID]:getHandCards()
    if curView ~= cmd.INVALID_CHAIRID then
        self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_OUTCARD, cmd.COUNTDOWN_OUTCARD)
        self:updatePromptList(carddata, handCards, outView, curView)
        -- 不出按钮
        self._gameView:onChangePassBtnState(true)
    end
    
    self._gameView:onGetOutCard(curView, outView, carddata)
    self.m_wLastOutCardUser = cmd_table.wOutCardUser
    -- 设置倒计时
    self._gameView:setOperateTipVisible(outView, false)
    if curView ~= cmd.INVALID_CHAIRID then
        self._gameView:setOperateTipVisible(curView, false)
    end
    --更新牌视图
    if outView ~= cmd.MY_VIEWID then
        local m_nodeCard = self._gameView.m_tabNodeCards[outView]
        local currentCount = m_nodeCard:getCardsCount()
        local lastCount = m_nodeCard:getCardsCount()
        --print("--- outView updateCardsNodeLayout before---",outView,lastCount,outCount,currentCount)
        --currentCount = currentCount - outCount
        
        --m_nodeCard:setCardsCount(currentCount)
        --print("--- outView updateCardsNodeLayout ---",outView,lastCount,currentCount)
        if lastCount <= 2 and lastCount > 0 then
            self._gameView.m_tabAlertSp[outView]:setVisible(true)
        else
            self._gameView.m_tabAlertSp[outView]:setVisible(false)
        end

        self._gameView:updateCardsNodeLayout(outView, currentCount, true)
    end
    
end

-- 用户放弃
function GameLayer:onSubPassCard(dataBuffer)
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_PassCard, dataBuffer)
    local curView = self:SwitchViewChairID(cmd_table.wCurrentUser)
    local passView = self:SwitchViewChairID(cmd_table.wPassCardUser)
    if self:IsValidViewID(curView) and self:IsValidViewID(passView) then
        print("&& pass " .. passView .. " current " ..  curView)
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
        self._gameView:onGetPassCard(cmd_table)

        self._gameView:onGetOutCard(curView, curView, {})

        -- 设置倒计时
        self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_OUTCARD, cmd.COUNTDOWN_OUTCARD)
    else
        print("viewid invalid" .. curView .. " ## " .. passView)
    end

    self._gameView:setOperateTipVisible(passView, true)
    if curView ~= cmd.INVALID_CHAIRID then
        self._gameView:setOperateTipVisible(curView, false)
    end
end

-- 游戏结束
function GameLayer:onSubGameConclude(dataBuffer)
    self.m_wNoDeclareCount = 0
    self.m_wNoAskFriendCount = 0
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_GameConclude, dataBuffer)
    dump(cmd_table, "onSubGameConclude", 6)
    self._gameView:setTrusteeBtnEnable(false)
    self._gameView:changeBtnState(self._gameView.m_bt_trusteeship,false)
    self._gameView:onGetGameConclude( cmd_table )
    self:KillGameClock()
    -- 私人房无倒计时
    if not GlobalUserItem.bPrivateRoom then
        -- 设置倒计时
        self:SetGameClock(self:GetMeChairID(), cmd.TAG_COUNTDOWN_READY, cmd.COUNTDOWN_READY)
    end

    self:reSetData()
end

function GameLayer:onSubTrustee( dataBuffer )
    
end

function GameLayer:onSubBaseScore( dataBuffer )
    
end

function GameLayer:onEventGameSceneFree( dataBuffer )
    local int64 = Integer64.new()
    print("--------------dataBuffer:getlen() ----------------" ,dataBuffer:getlen())
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_StatusFree, dataBuffer)
    dump(cmd_table, "scene free", 6)
    cmd.COUNTDOWN_READY = cmd_table.cbTimeStart
    cmd.COUNTDOWN_DECLAREWAR = cmd_table.cbTimeXuanZhan
    cmd.COUNTDOWN_FINDFRIEND = cmd_table.cbTimeFindFriend
    cmd.COUNTDOWN_ASKFRIEND = cmd_table.cbTimeAskFriend
    cmd.COUNTDOWN_ADDTIME = cmd_table.cbTimeAddTimes
    cmd.COUNTDOWN_OUTCARD = cmd_table.cbTimeOutCard
    self.m_b2Biggest = cmd_table.b2Biggest
    self.m_lCellScore = cmd_table.lCellScore
    GameLogic.m_b2Biggest = self.m_b2Biggest

    self.m_lTurnScore = cmd_table.m_lTurnScore

    self.lCollectScore = cmd_table.lCollectScore
    -- 更新底分
    --self._gameView:onGetCellScore(cmd_table.lCellScore)
    -- 空闲消息
    self._gameView:onGetGameFree()

    --self._gameView:onGetGameCard(cmd.MY_VIEWID, cards, false)
    local empTyCard = GameLogic:emptyCardList(cmd.NORMAL_COUNT)

    -- 私人房无倒计时
    self:KillGameClock()
    if not GlobalUserItem.bPrivateRoom then
        -- 设置倒计时
        self:SetGameClock(self:GetMeChairID(), cmd.TAG_COUNTDOWN_READY, cmd.COUNTDOWN_READY)
    end  
    -- 刷新局数
    if PriRoom and GlobalUserItem.bPrivateRoom then
        local curcount = PriRoom:getInstance().m_tabPriData.dwPlayCount
        print("---- PriRoom curcount -----",curcount)
        if nil ~= self._gameView._priView and nil ~= self._gameView._priView.onRefreshInfo then
            self._gameView._priView:onRefreshInfo()
        end
    end  
end


function GameLayer:onEventGameScenePlay( dataBuffer )
    local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_StatusPlay, dataBuffer)
    self.m_gameScenePlay = cmd_table
    dump(cmd_table, "scene play", 6)
    cmd.COUNTDOWN_READY = cmd_table.cbTimeStart
    cmd.COUNTDOWN_DECLAREWAR = cmd_table.cbTimeXuanZhan
    cmd.COUNTDOWN_FINDFRIEND = cmd_table.cbTimeFindFriend
    cmd.COUNTDOWN_ASKFRIEND = cmd_table.cbTimeAskFriend
    cmd.COUNTDOWN_ADDTIME = cmd_table.cbTimeAddTimes
    cmd.COUNTDOWN_OUTCARD = cmd_table.cbTimeOutCard
    self.m_wCurrentUser = self.m_gameScenePlay.wCurrentUser
    self.m_b2Biggest = cmd_table.b2Biggest
    GameLogic.m_b2Biggest = self.m_b2Biggest
    self.m_wFriend = cmd_table.wFriend[1]
    self.m_cbTurnCardCount = cmd_table.cbTurnCardCount
    self.m_wTurnWiner = cmd_table.wTurnWiner
    self.m_cbTurnCardData = cmd_table.cbTurnCardData[1]
    self.m_wXuanZhanUser = cmd_table.wXuanZhanUser
    self.m_wBankerUser = cmd_table.wBankerUser
    self.m_lCellScore = cmd_table.lCellScore
    self.m_cbFriendFlag = cmd_table.cbFriendFlag
    local myChairId = self._gameFrame:GetChairID()
    self._gameView.m_cardNum1:setString(string.format("%d", cmd_table.cbHandCardCount[1][myChairId + 1]))
    self._gameView.m_cardNum1:setVisible(true)
    self._gameView:updateRule()
    --[[
    local empTyCard = GameLogic:emptyCardList(cmd.NORMAL_COUNT)
    self._gameView:onGetGameCard(cmd.LEFT_VIEWID, empTyCard, true)
    self._gameView:onGetGameCard(cmd.RIGHT_VIEWID, empTyCard, true)
    self._gameView:onGetGameCard(cmd.TOP_VIEWID, empTyCard, true)
    --]]
    self.m_bRoundOver = false

    -- 用户手牌
    local countlist = cmd_table.cbHandCardCount[1]

    for i = 1, 4 do
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
    self.m_cbTurnCardData = self:getValidCardsData(self.m_cbTurnCardData)
    print("self.m_gameScenePlay.cbGameStatus",self.m_gameScenePlay.cbGameStatus)
    if self.m_gameScenePlay.cbGameStatus == cmd.GAME_XUAN_ZHAN then
        self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_XUAN_ZHAN, self.m_gameScenePlay.cbTimeXuanZhan)
        if self.m_wCurrentUser == myChairId  then
            self._gameView:presentDeclareWarBtns()
        end
    elseif self.m_gameScenePlay.cbGameStatus == cmd.GAME_FIND_FRIEND then
        if  self.m_wCurrentUser == myChairId then
            self._gameView:openFindRriendLayer()
        end
        self:SetGameClock(self.m_wCurrentUser, cmd.TAG_COUNTDOWN_FIND_FRIEND, cmd.COUNTDOWN_FINDFRIEND)     
    elseif self.m_gameScenePlay.cbGameStatus == cmd.GAME_ASK_FRIEND then
        self:SetGameClock(cmd_table.wCurrentUser, cmd.TAG_COUNTDOWN_ASK_FRIEND, cmd.COUNTDOWN_ASKFRIEND)
        self.m_gameScenePlay.bEnabledAskFriend = true
        if  self.m_wCurrentUser == myChairId then
            self._gameView:presentAskFriendBtns()
        end  
    elseif self.m_gameScenePlay.cbGameStatus == cmd.GAME_ADD_TIMES then
        if  cmd_table.bEnabledAddTimes then
            self:SetGameClock(myChairId, cmd.TAG_COUNTDOWN_ADD_TIMES, cmd.COUNTDOWN_ADDTIME)
            self._gameView:presentAddTimesBtns()
        end 
        self.m_wXuanZhanUser = cmd.wXuanZhanUser
        
        self:SetFriendFlag()
        for i = 1, cmd.PLAYER_COUNT do
            self._gameView:SetAddTimes(i, cmd_table.bAddTimes[1][i])
        end
    elseif self.m_gameScenePlay.cbGameStatus == cmd.GAME_SCENE_PLAY then
        self:SetFriendFlag()
        self._gameView:SetAddTimes(cmd.INVALID_CHAIRID,false)
        self._gameView:changeBtnState(self._gameView.m_bt_trusteeship,true)
        self._gameView:SetFriendFlag2(self.m_wFriend,self.m_wXuanZhanUser)
        --出牌界面
        if cmd_table.wTurnWiner ~= cmd.INVALID_CHAIRID then
            local wViewChairID = self:SwitchViewChairID(cmd_table.wTurnWiner)
            --m_GameClientView.m_UserCardControl[wViewChairID].SetCardData(m_cbTurnCardData,m_cbTurnCardCount);
        end
        if not GlobalUserItem.bPrivateRoom then
            self._gameView:setTrusteeBtnEnable(true)
            self._gameView:changeBtnState(self._gameView.m_bt_trusteeship,true)
        else
            self._gameView:setTrusteeBtnEnable(false)
            self._gameView:changeBtnState(self._gameView.m_bt_trusteeship,false)
        end
        --显示好友

        local curView = self:SwitchViewChairID(self.m_wCurrentUser)
        local outView = self:SwitchViewChairID(cmd_table.wTurnWiner)

        local handCards = self._gameView.m_tabNodeCards[cmd.MY_VIEWID]:getHandCards()
        self:updatePromptList(self.m_cbTurnCardData, handCards, outView, cmd.MY_VIEWID)        
        if  self.m_wCurrentUser == myChairId then
            local handCards = self._gameView.m_tabNodeCards[1]:getHandCards()
            --self:updatePromptList(self.m_cbTurnCardData, handCards, cmd.MY_VIEWID, cmd.MY_VIEWID)
            self._gameView:onGetOutCard(1, 1, self.m_cbTurnCardData)
            self._gameView:presentOutCardsBtns()
            self._gameView:onChangePassBtnState(self.m_cbTurnCardCount > 0)
            self._gameView.m_bt_outCard:setEnabled(false)
            self._gameView.m_bt_outCard:setOpacity(125)
            --搜索出牌
            if cmd_table.wTurnWiner == myChairId then
                local result = {}
                result = GameLogic:SearchOutCard(handCards, #handCards, {}, 0)
            else
                result = GameLogic:SearchOutCard(handCards, #handCards, self.m_cbTurnCardData, self.m_cbTurnCardCount)
            end
        end
        --个人拥有的牌
        self._gameView.m_cardNum1:setString(string.format("%d", cmd_table.cbHandCardCount[1][myChairId + 1]))
        self._gameView.m_cardNum1:setVisible(true)
        self._gameView:onGetOutCard(curView, outView, self.m_cbTurnCardData)
        --历史成绩
        print("--- 历史成绩 ---")
        for i = 1 ,cmd.PLAYER_COUNT do
            local viewId = self:SwitchViewChairID(i - 1)
            self._gameView.m_historyScore[viewId].lTurnScore = cmd_table.lTurnScore[1][i]
            self._gameView.m_historyScore[viewId].lCollectScore = cmd_table.lCollectScore[1][i]
        end
        self._gameView:updateHistoryScore()
        self:SetGameClock(self.m_wCurrentUser, cmd.TAG_COUNTDOWN_OUTCARD, cmd.COUNTDOWN_OUTCARD)
    end
    self._gameView.m_lGameScore = cmd_table.cbGameScore[1]

     for i = 1 ,cmd.PLAYER_COUNT do
        local viewId = self:SwitchViewChairID(i - 1)
        self._gameView.m_historyScore[viewId].lTurnScore = cmd_table.lTurnScore[1][i]
        self._gameView.m_historyScore[viewId].lCollectScore = cmd_table.lCollectScore[1][i]
        local head_bg = self._gameView.m_csbNode:getChildByName(string.format("head_bg_%d", viewId))
        --显示庄家
        if i - 1 == self.m_wBankerUser then
            local heart = head_bg:getChildByName("heart")
            heart:setVisible(true)
        end
        local text_curScore = head_bg:getChildByName("text_curScore")
        text_curScore:setString(string.format("当前得分:%d", self._gameView.m_lGameScore[viewId]))

        if viewId ~= cmd.MY_VIEWID then
            self._gameView:updateCardsNodeLayout(viewId, cmd_table.cbHandCardCount[1][i], true) 
        end
    end

    -- 刷新局数
    if PriRoom and GlobalUserItem.bPrivateRoom then
        local curcount = PriRoom:getInstance().m_tabPriData.dwPlayCount
        if nil ~= self._gameView._priView and nil ~= self._gameView._priView.onRefreshInfo then
            self._gameView._priView:onRefreshInfo()
        end
    end
    self._gameView.m_cardNum1:setString(string.format("%d", cmd_table.cbHandCardCount[1][myChairId + 1]))
    self._gameView.m_cardNum1:setVisible(true)
end

--去0
function GameLayer:getValidCardsData(cardsData)
    local newCardsData = {}
    for i = 1, #cardsData do
        if 0 ~= cardsData[i] then
            table.insert(newCardsData, cardsData[i])
        end
    end
    return newCardsData
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

-- 语音聊天
function GameLayer:onUserVoice( useritem, filepath)
    local viewid = self:SwitchViewChairID(useritem.wChairID)
    if self:IsValidViewID(viewid) then
        self._gameView:onUserVoice(filepath, viewid)
        return true
    end
    return false
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

function GameLayer:SwitchViewChairID(chair)
    local viewid = yl.INVALID_CHAIR
    if chair == cmd.INVALID_CHAIRID then
        return chair
    end
    local nChairCount = self._gameFrame:GetChairCount()
    local nChairID = self:GetMeChairID()
    local userIndex = 1;
    local startIndex = nChairID
    while (true)
        do
        if startIndex == chair then
            break
        end
            userIndex = userIndex + 1
            startIndex = startIndex + 1
        if startIndex >= nChairCount then
            startIndex = 0
        end
    end
    
    return userIndex
end


return GameLayer