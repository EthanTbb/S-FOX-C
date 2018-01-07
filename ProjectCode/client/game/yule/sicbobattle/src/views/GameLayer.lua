local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")
local GameLayer = class("GameLayer", GameModel)

local module_pre = "game.yule.sicbobattle.src";
require("cocos.init")
local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local cmd = module_pre .. ".models.CMD_Game"
local game_cmd = appdf.HEADER_SRC .. "CMD_GameServer"
local GameLogic = module_pre .. ".models.GameLogic";
local GameViewLayer = appdf.req(module_pre .. ".views.layer.GameViewLayer")
local GameDefine = appdf.req(module_pre .. ".models.GameDefine")
local QueryDialog   = require("app.views.layer.other.QueryDialog")
local g_var = ExternalFun.req_var
local GameFrame = appdf.req(module_pre .. ".models.118_GameFrame")

function GameLayer:ctor( frameEngine,scene )
    ExternalFun.registerNodeEvent(self)
    self.m_bLeaveGame = false
    self.m_bOnGame = false
    self._dataModle = GameFrame:create()
    GameLayer.super.ctor(self,frameEngine,scene)
    -- self._roomRule = self._gameFrame._dwServerRule
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

function GameLayer:getUserList(  )
    return self._gameFrame._UserList
end

function GameLayer:sendNetData( cmddata )
    return self:getFrame():sendSocketData(cmddata)
end

function GameLayer:getDataMgr( )
    return self._dataModle
end

function GameLayer:logData(msg)
    if nil ~= self._scene.logData then
        self._scene:logData(msg)
    end
end
--当前庄家
function GameLayer:GetCurrentBanker(  )
    return self._gameView.m_wCurrentBanker
end
--当前状态
function  GameLayer:GetGameStatus( )
    return self._gameView.m_cbGameStatus
end
--是否系统庄家
function GameLayer:GetIsSysBanker( )
    return self._gameView.m_bEnableSysBanker
end

--设置筹码
function GameLayer:SetCurrentJetton( lCurrentJetton,nJettonIndex )
    if lCurrentJetton < 0 then
        return
    end
    self._gameView.m_lCurrentJetton = lCurrentJetton
    self._gameView.m_nJettonIndex = nJettonIndex
end

function GameLayer:GetBankerWinMinScore( cbAreaID )
    local lAllUserBet = {}
    lAllUserBet = GameLogic:copyTab(self._gameView.m_lAllUserBet)

    local lBankerWinMinScore = 0
    local bFirst = true
    for i=1,6 do
        for j=1,6 do
            for k=1,6 do
                local cbDiceValue = {}
                cbDiceValue[1] = i
                cbDiceValue[2] = j
                cbDiceValue[3] = k
                local nWinMultiple = {}
                GameLogic:DeduceWinner(nWinMultiple,cbDiceValue)

                -- if nWinMultiple[cbAreaID] < 0 then
                --     contince
                -- end
                local lBankerWinScore = 0
                for cbAreaIndex=1,g_var(cmd).AREA_COUNT do
                    if nWinMultiple[cbAreaIndex] > 0 then
                        lBankerScore = lBankerScore - (lAllUserBet[cbAreaIndex]*nWinmultiple[cbAreaIndex])
                    else
                        lBankerScore = lBankerWinScore + (-lAllUserBet[cbAreaIndex]*nWinMultiple[cbAreaIndex])
                    end
                end
                if bFirst then
                    lBankerWinMinScore = lBankerWinScore
                else 
                    if lBankerWinScore < lBankerWinMinScore then
                        lBankerWinMinScore = lBankerWinScore
                    end
                end
            end
        end
    end
    return lBankerWinMinScore
end

function GameLayer:GetUserMaxBet( cbAreaID )
    local lNowJetton = 0
    local lCurUserMaxBet = 0
    for nAreaIndex=1,g_var(cmd).AREA_COUNT do
        lNowJetton = lNowJetton + self._gameView.m_lUserBet[nAreaIndex]
    end
    --可下金币
    lCurUserMaxBet = self:GetMeUserItem().lScore - lNowJetton
    --下注限制
    lCurUserMaxBet = math.min(lCurUserMaxBet,self._gameView.m_lMeMaxScore - lNowJetton)
    --区域限制
    lCurUserMaxBet = math.min(lCurUserMaxBet,self._gameView.m_lAreaLimitScore - self._gameView.m_lAllUserBet[cbAreaID])

    --庄家限制
    local lBankerScore = 0
    if self._gameView.m_wBankerUser ~= yl.INVALID_CHAIR then
        lBankerScore = self._gameView.m_lBankerScore
    end
    lBankerScore = lBankerScore + self:GetBankerWinMinScore(cbAreaID)

    if lBankerScore < 0 then
        if self._gameView.m_wBankerUser ~= yl.INVALID_CHAIR then
            lBankerScore = self._gameView.m_lBankerScore
        else
            lBankerScore = 0
        end
    end
    lCurUserMaxBet = math.min(lCurUserMaxBet,lBankerScore/g_var(cmd).g_cbAreaOdds[cbAreaID])

    --零值过滤
    lCurUserMaxBet = math.max(lCurUserMaxBet,0)
    return lCurUserMaxBet
end

--更新控制
function GameLayer:UpdateButtonContron()
    --智能判断
    local bEnablePlaceJetton = true
    if self:GetGameStatus() ~= g_var(cmd).GS_PLAYER_BET or self:GetCurrentBanker()==self:GetMeChairID() or (self:GetIsSysBanker() == false and self:GetCurrentBanker()==0) then
        bEnablePlaceJetton = false
    end

    if not self._gameView.m_bCanPlaceJetton then 
        bEnablePlaceJetton = false;
    end
    local nIndex = 0
    --下注按钮
    if bEnablePlaceJetton == true then
        --计算积分
        local lCurrentJetton = self._gameView.GetCurrentJetton
        local lLeaveScore = self._gameView.m_lMeMaxScore
        for nAreaIndex=1,g_var(cmd).AREA_COUNT do
            lLeaveScore = lLeaveScore - self._gameView.m_lUserBet[nAreaIndex];
        end
        --最大下注
        local lUserMaxJetton = self:GetUserMaxBet(3)
    else
        --设置光标
        self:SetCurrentJetton(0,-1)

        --禁止按钮
        for nIndex=1,g_var(cmd).JETTON_COUNT do
            
        end
    end

    --庄家按钮
    --获取信息
    local useritem = self:GetMeUserItem()
    --申请按钮
    local bEnableApply = true
    if self._gameView.m_wCurrentBanker == self:GetMeChairID() then
        bEnableApply = false
    end
    if m_bMeApplyBanker then
        bEnableApply = false
    end
    if useritem.lScore < self._gameView.m_lApplyBankerCondition then
        bEnableApply = false
    end
    --设置庄家按钮是否可以点击
    --m_GameClientView.m_btApplyBanker.EnableWindow(bEnableApply?TRUE:FALSE);

    --取消按钮
    local bEnableCancel = true

    if self.m_bMeApplyBanker == false then
        bEnableCancel = false
    end
    --取消按钮 是否可以点击 图片
-- m_GameClientView.m_btCancelBanker.EnableWindow(bEnableCancel?TRUE:FALSE);
--         m_GameClientView.m_btCancelBanker.SetButtonImage(m_wCurrentBanker==GetMeChairID()?IDB_BT_CANCEL_BANKER:IDB_BT_CANCEL_APPLY,AfxGetInstanceHandle(),false,false);

    --显示判断
    if self._gameView.m_bMeApplyBanker then
        --按钮
        -- m_GameClientView.m_btCancelBanker.ShowWindow(SW_SHOW);
        -- m_GameClientView.m_btApplyBanker.ShowWindow(SW_HIDE);
    else
        --按钮
        -- m_GameClientView.m_btCancelBanker.ShowWindow(SW_HIDE);
        -- m_GameClientView.m_btApplyBanker.ShowWindow(SW_SHOW);
    end


    return
end


---------------------------------------------------------------------------------------
------继承函数
function GameLayer:onExit()
    self:KillGameClock()
    self:dismissPopWait()
end

-- 重置游戏数据
function GameLayer:OnResetGameEngine()
    self.m_bOnGame = false
    self._gameView.m_enApplyState = self._gameView._apply_state.kCancelState
    self._dataModle:removeAllUser()
    self._dataModle:initUserList(self:getUserList())
    self._gameView:refreshApplyList()
    self._gameView:refreshUserList()
    self._gameView:refreshApplyBtnState()
    self._gameView:cleanJettonArea()
end

--强行起立、退出(用户切换到后台断网处理)
function GameLayer:standUpAndQuit()
    self:sendCancelOccupy()
    GameLayer.super.standUpAndQuit(self)
end

--退出桌子
function GameLayer:onExitTable()
    self:KillGameClock()
    local MeItem = self:GetMeUserItem()
    if MeItem and MeItem.cbUserStatus > yl.US_FREE then
        self:showPopWait()
        self:runAction(cc.Sequence:create(
            cc.DelayTime:create(2),
            cc.CallFunc:create(
                function () 
                    self:sendCancelOccupy()
                    self._gameFrame:StandUp(1)
                end
                ),
            cc.DelayTime:create(10),
            cc.CallFunc:create(
                function ()
                    --强制离开游戏(针对长时间收不到服务器消息的情况)
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
    self:getFrame():onCloseSocket()

    self._scene:onKeyBack()    
end

-- 计时器响应
function GameLayer:OnEventGameClockInfo(chair,time,clockId)
    if nil ~= self._gameView and nil ~= self._gameView.updateClock then
        --print("计时器响应 clockId",clockId)
        self._gameView:updateClock(clockId, time)
    end
end

-- 设置计时器
function GameLayer:SetGameClock(chair,id,time)
    GameLayer.super.SetGameClock(self,chair,id,time)
    if nil ~= self._gameView and nil ~= self._gameView.showTimerTip then
        self._gameView:showTimerTip(id)
    end
end

------网络发送
--玩家下注
function GameLayer:sendUserBet( cbArea, lScore )
    local cmddata = ExternalFun.create_netdata(g_var(cmd).CMD_C_PlaceBet)
    cmddata:pushbyte(cbArea)
    cmddata:pushscore(lScore)

    self:SendData(g_var(cmd).SUB_C_PLACE_JETTON, cmddata)
    print("@@@cbArea@@@",cbArea)
    print("@@@lScore@@@",lScore)
end

--超级抢庄
-- function GameLayer:sendRobBanker(  )
--     local cmddata = CCmd_Data:create(0)

--     self:SendData(g_var(cmd).SUB_C_SUPERROB_BANKER, cmddata)
-- end

--申请上庄
function GameLayer:sendApplyBanker(  )
    local cmddata = CCmd_Data:create(0)
    self:SendData(g_var(cmd).SUB_C_APPLY_BANKER, cmddata)
end

--取消申请
function GameLayer:sendCancelApply(  )
    local cmddata = CCmd_Data:create(0)
    self:SendData(g_var(cmd).SUB_C_CANCEL_BANKER, cmddata)
end

--申请坐下
function GameLayer:sendSitDown( index, wchair )
    local cmddata = ExternalFun.create_netdata(g_var(cmd).CMD_C_OccupySeat)
    cmddata:pushword(wchair)
    cmddata:pushbyte(index)

    self:SendData(g_var(cmd).SUB_C_OCCUPYSEAT, cmddata)
end

--申请取消占位
function GameLayer:sendCancelOccupy(  )
    if nil ~= self._gameView.m_nSelfSitIdx then 
        local cmddata = CCmd_Data:create(0)
        self:SendData(g_var(cmd).SUB_C_QUIT_OCCUPYSEAT, cmddata)
    end 
end

--申请取款
function GameLayer:sendTakeScore( lScore,szPassword )
    local cmddata = ExternalFun.create_netdata(g_var(game_cmd).CMD_GR_C_TakeScoreRequest)
    cmddata:setcmdinfo(g_var(game_cmd).MDM_GR_INSURE, g_var(game_cmd).SUB_GR_TAKE_SCORE_REQUEST)
    cmddata:pushbyte(g_var(game_cmd).SUB_GR_TAKE_SCORE_REQUEST)
    cmddata:pushscore(lScore)
    cmddata:pushstring(md5(szPassword),yl.LEN_PASSWORD)

    self:sendNetData(cmddata)
end

--请求银行信息
function GameLayer:sendRequestBankInfo()
    local cmddata = CCmd_Data:create(67)
    cmddata:setcmdinfo(g_var(game_cmd).MDM_GR_INSURE,g_var(game_cmd).SUB_GR_QUERY_INSURE_INFO)
    cmddata:pushbyte(g_var(game_cmd).SUB_GR_QUERY_INSURE_INFO)
    cmddata:pushstring(md5(GlobalUserItem.szPassword),yl.LEN_PASSWORD)

    self:sendNetData(cmddata)
end


------网络接收

-- 场景信息
function GameLayer:onEventGameScene(cbGameStatus,dataBuffer)
    -- print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
    -- print("ljb ----场景数据:" .. cbGameStatus);
    -- print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
    if self.m_bOnGame then
        return
    end
    self.m_bOnGame = true
    
    self._gameView.m_cbGameStatus = cbGameStatus;

	if cbGameStatus == g_var(cmd).GS_GAME_FREE	then                            --空闲状态 0
        print("空闲状态")
        self:onEventGameSceneFree(dataBuffer);
	elseif cbGameStatus == g_var(cmd).GS_GAME_START	then                        --游戏开始 100 
        print("游戏开始")
        self:onEventGameSceneJetton(dataBuffer);
    elseif  cbGameStatus == g_var(cmd).GS_PLAYER_BET then                        --下注状态 101
        self:onEventGameSceneJetton(dataBuffer);    
	elseif cbGameStatus == g_var(cmd).GS_GAME_END 	then                        --结束状态 102
        print("结束状态")
        self:onEventGameSceneEnd(dataBuffer);
	end
    self:dismissPopWait()
end

--游戏场景
function GameLayer:onEventGameSceneFree( dataBuffer )
    --self._gameView:reSetForNewGame()
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_StatusFree, dataBuffer);
    --dump(cmd_table)

    --庄家信息
    yl.m_bDynamicJoin = false

    -- local susbRob = cmd_table.wCurSuperRobBankerUser
    --当前超级抢庄用户
    -- self._gameView.m_wCurrentRobApply = subRob
    -- self.m_wCurrentRobApply = subRob

    --申请条件
    self._gameView:onGetApplyBankerCondition(cmd_table.lApplyBankerCondition, cmd_table.superbankerConfig);

    --游戏倒计时
    self:SetGameClock(self:GetMeChairID(), g_var(cmd).kGAMEFREE_COUNTDOWN, cmd_table.cbTimeLeave)

    self.m_bEnableSystemBanker = cmd_table.bEnableSysBanker
    --刷新庄家信息
    self._gameView.m_wBankerUser = cmd_table.wBankerUser
    self._gameView.m_lBankerScore = cmd_table.lBankerScore


    local ebi = GameDefine.getEmptyBankInfo()
    ebi.wBankerUser = cmd_table.wBankerUser
    ebi.lBankerScore = cmd_table.lBankerScore
    ebi.nBankerTime = cmd_table.cbBankerTime
    ebi.lBankerWinScore = cmd_table.lBankerWinScore
    self._dataModle.m_tabGameBankInfo = ebi
    self._gameView:onChangeBanker();

    --self._gameView:onChangeBanker(cmd_table.wBankerUser, cmd_table.lBankerScore, self.m_bEnableSystemBanker,cmd_table.cbBankerTime);

    -- --刷新玩家信息
    self._gameView.m_lMeMaxScore = cmd_table.lUserMaxScore
    -- --设置玩家分数

    --控制信息
    self._gameView.m_lApplyBankerCondition = cmd_table.lApplyBankerCondition
    self._gameView.m_lAreaLimitScore = cmd_table.lAreaLimitScore
    -- --设置最大下注分数

    --self:UpdateButtonContron()

    --从申请列表移除
    self._dataModle:removeApplyUser(cmd_table.wBankerUser)


    self._gameView:showGameResult(false)
end

function GameLayer:onEventGameSceneJetton( dataBuffer )
    print("Jetton")
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_StatusPlay, dataBuffer);
    dump(cmd_table)
    yl.m_bDynamicJoin = false

    --申请条件
    self._gameView:onGetApplyBankerCondition(cmd_table.lApplyBankerCondition, cmd_table.superbankerConfig);

    --游戏倒计时
    self:SetGameClock(self:GetMeChairID(), g_var(cmd).kGAMEPLAY_COUNTDOWN, cmd_table.cbTimeLeave)

    --玩家最大下注
    self._gameView.m_llMaxJetton = cmd_table.lUserMaxScore;

    --界面下注信息
    local ll = 0;
    local userJettonScore = 0;
    local allJettonScore = 0
    for i=1,g_var(cmd).AREA_COUNT do
        --界面已下注
        ll = cmd_table.lAllJettonScore[1][i];

        if self._gameView.m_wBankerUser == self:GetMeChairID() then
            --print("界面已下注")
            self._gameView:reEnterGameBet(i, ll);
        end
        allJettonScore = allJettonScore + ll
        --玩家下注
        ll = cmd_table.lUserJettonScore[1][i];

        self._gameView:reEnterUserBet(i, ll);
        userJettonScore = userJettonScore + ll
    end
    self._gameView.m_lHaveJetton = userJettonScore
    self._gameView.m_lAllJetton = allJettonScore


    -- 刷新下注信息
    self._gameView:refreshJetton()

    self.m_bEnableSystemBanker = cmd_table.bEnableSysBanker
    --刷新庄家信息
    self._gameView.m_wBankerUser = cmd_table.wBankerUser
    self._gameView.m_lBankerScore = cmd_table.lBankerScore

    --获取庄家信息
    local ebi = GameDefine.getEmptyBankInfo()
    ebi.wBankerUser = cmd_table.wBankerUser
    ebi.lBankerScore = cmd_table.lEndUserScore
    ebi.nBankerTime = cmd_table.cbBankerTime
    ebi.lBankerWinScore = cmd_table.lBankerWinScore
    self._dataModle.m_tabGameBankInfo = ebi

    self._gameView:onChangeBanker(cmd_table.wBankerUser,cmd_table.lBankerScore,cmd_table.cbBankerTime,cmd_table.lBankerWinScore);

    -- self._gameView:onChangeBanker(cmd_table.wBankerUser, cmd_table.lBankerScore, self.m_bEnableSystemBanker,cmd_table.cbBankerTime);

    --从申请列表移除
    self._dataModle:removeApplyUser(cmd_table.wBankerUser)

    --游戏开始
    self._gameView:reEnterStart(userJettonScore);

end

function GameLayer:onEventGameSceneEnd( dataBuffer )

    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_StatusPlay, dataBuffer)
    dump(cmd_table)
    --保存游戏结果
    self._dataModle.m_tabGameEndCmd = cmd_table

    --申请条件
    self._gameView:onGetApplyBankerCondition(cmd_table.lApplyBankerCondition )--, cmd_table.superbankerConfig)

    --游戏倒计时
    self:SetGameClock(self:GetMeChairID(), g_var(cmd).kGAMEOVER_COUNTDOWN, cmd_table.cbTimeLeave)
    yl.m_bDynamicJoin = true

    --玩家最大下注
    self._gameView.m_llMaxJetton = cmd_table.lUserMaxScore;
    --界面下注信息
    local ll = 0;
    local userJettonScore = 0;
    local allJettonScore = 0

    for i=1,g_var(cmd).AREA_COUNT do
        --界面已下注
        ll = cmd_table.lAllJettonScore[1][i]

        if self._gameView.m_wBankerUser == self:GetMeChairID() then
            -- print("界面已下注")
            self._gameView:reEnterGameBet(i, ll);
        end

        allJettonScore = allJettonScore + ll
        --玩家下注
        ll = cmd_table.lUserJettonScore[1][i]

        self._gameView:reEnterUserBet(i, ll)
        userJettonScore = userJettonScore + ll
    end
    self._gameView.m_lHaveJetton = userJettonScore
    self._gameView.m_lAllJetton = allJettonScore
    -- 刷新下注信息
    self._gameView:refreshJetton()


    self.m_bEnableSystemBanker = cmd_table.bEnableSysBanker
    --刷新庄家信息
    self._gameView.m_wBankerUser = cmd_table.wBankerUser
    self._gameView.m_lBankerScore = cmd_table.lBankerScore

    --获取庄家信息
    local ebi = GameDefine.getEmptyBankInfo()
    ebi.wBankerUser = cmd_table.wBankerUser
    ebi.lBankerScore = cmd_table.lEndUserScore
    ebi.nBankerTime = cmd_table.cbBankerTime+1
    ebi.lBankerWinScore = cmd_table.lBankerWinScore
    self._dataModle.m_tabGameBankInfo = ebi

    self._gameView:onChangeBanker(cmd_table.wBankerUser,cmd_table.lBankerScore,cmd_table.cbBankerTime,cmd_table.lBankerWinScore);


    --self._gameView:onChangeBanker(cmd_table.wBankerUser, cmd_table.lBankerScore, self.m_bEnableSystemBanker,cmd_table.cbBankerTime,cmd_table.lBankerWinScore);

    --从申请列表移除
    self._dataModle:removeApplyUser(cmd_table.wBankerUser)


    local winMultiple = {}
    local winArea = g_var(GameLogic):DeduceWinner(winMultiple,cmd_table.cbDiceValue[1])
    -- print("胜利区域")

    self._dataModle.m_tabBetArea = winMultiple

    
    --设置游戏结果数据
    local res = GameDefine.getEmptyGameResult()
    --res.m_llTotal = cmd_table.lEndUserScore
    --res.m_pAreaScore = cmd_table.cbDiceValue[1]
    res.cbDiceValue = cmd_table.cbDiceValue[1]
    for i=1,#res.cbDiceValue do
        res.cbDicePoints = res.cbDicePoints + res.cbDiceValue[i]
    end
    if res.cbDicePoints >= 3 and res.cbDicePoints <= 10 then
        res.cbDiceDaxiao = "小"
    elseif res.cbDicePoints >= 11 and res.cbDicePoints <= 18 then
        res.cbDiceDaxiao = "大"
    end

    --egr.m_llTotal = cmd_table.lEndUserScore
    res.lBankerScore = cmd_table.lEndBankerScore
    res.lUserScore = cmd_table.lEndUserScore
    res.lUserReturnScore = cmd_table.lEndUserReturnScore
    self._dataModle.m_tabGameResult = res

    local bJoin = false
    local nWinCount = 0
    local nLoseCount = 0

    for i = 1, g_var(cmd).AREA_COUNT do
        if cmd_table.lUserJettonScore[1][i] > 0 then
            bJoin = true
            nWinCount = nWinCount + 1
        elseif cmd_table.lAllJettonScore[1][i] < 0 then
            bJoin = true
            nLoseCount = nLoseCount + 1

        end
    end
    self._dataModle.m_bJoin = bJoin

    --成绩
    --self._dataModle.m_llTotalScore = cmd_table.lAllJettonScore

    self._gameView:onGetGameEnd(cmd_table.cbTimeLeave)
end

-- 游戏消息
function GameLayer:onEventGameMessage(sub,dataBuffer)  
    print("ljb ---onEventGameMessage sub:",sub)
    if self.m_bLeaveGame or nil == self._gameView then
        return
    end 
	if sub == g_var(cmd).SUB_S_GAME_FREE then --游戏空闲 99
        self._gameView.m_cbGameStatus = g_var(cmd).GS_GAME_FREE
		self:onSubGameFree(dataBuffer);
	elseif sub == g_var(cmd).SUB_S_GAME_START then --游戏开始 100
        self._gameView.m_cbGameStatus = g_var(cmd).GS_GAME_START
		self:onSubGameStart(dataBuffer);
    elseif sub == g_var(cmd).SUB_S_START_BET then           --101
        self._gameView.m_cbGameStatus = g_var(cmd).GS_PLAYER_BET
        self:OnUserStartBet(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_PLACE_JETTON then  --用户下注 102
        --self._gameView.m_cbGameStatus = g_var(cmd).SUB_S_PLACE_JETTON
        self:onSubPlaceJetton(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_GAME_END then --游戏结束 103
        self._gameView.m_cbGameStatus = g_var(cmd).GS_GAME_END
        self:onSubGameEnd(dataBuffer);
	elseif sub == g_var(cmd).SUB_S_APPLY_BANKER then --申请做庄 104
		self:onSubApplyBanker(dataBuffer);
	elseif sub == g_var(cmd).SUB_S_CHANGE_BANKER then --切换庄家 105
		self:onSubChangeBanker(dataBuffer);
    elseif sub == g_var(cmd).SUB_S_CHANGE_USER_SCORE then --更新积分106
        self:onSubChangeUserScore(dataBuffer);
    elseif sub == g_var(cmd).SUB_S_SEND_RECORD then     --游戏记录 107
        self:onSubSendRecord(dataBuffer);
    elseif sub == g_var(cmd).SUB_S_PLACE_JETTON_FAIL then   --下注失败 108
        self:onSubJettonFail(dataBuffer);
    elseif sub == g_var(cmd).SUB_S_CANCEL_BANKER then  --取消做庄 109
        self:onSubCancelBanker(dataBuffer);
    elseif sub == g_var(cmd).SUB_S_REVOCAT_BET then --撤销押注  111
    --  self:onSubChangeUserScore(dataBuffer);
    elseif sub == g_var(cmd).SUB_S_AMDIN_COMMAND then  --更新下注记录 --120
        --self:onSubAdminCmd(dataBuffer);
    elseif sub == g_var(cmd).SUB_S_SEND_USER_BET_INFO then --更新下注记录 121
        --self:onSubSupperRobLeave(dataBuffer);
    elseif sub == g_var(cmd).SUB_S_UPDATE_STORAGE then  --更新库存 122
        --self:onSubUpdateStorage(dataBuffer);
    elseif sub == g_var(cmd).SUB_S_AMDIN_COMMAND then --管理员命令 120
    --     self:OnSubReqResult(dataBuffer);
    elseif sub == g_var(cmd).SUB_S_CONTROL_WIN then  --123
        --self:OnSubControlWinLose(dataBuffer);
    -- elseif sub == g_var(cmd).SUB_S_OCCUPYSEAT_FAIL then
    --     self:onSubOccupySeatFail(dataBuffer);
    -- elseif sub == g_var(cmd).SUB_S_UPDATE_OCCUPYSEAT then
    --     self:onSubUpdateOccupySeat(dataBuffer);
	else
		print("unknow gamemessage sub is ==>"..sub)
	end
end

--
function GameLayer:onSocketInsureEvent( sub,dataBuffer )
    self:dismissPopWait()
    if sub == g_var(game_cmd).SUB_GR_USER_INSURE_SUCCESS then
        local cmd_table = ExternalFun.read_netdata(g_var(game_cmd).CMD_GR_S_UserInsureSuccess, dataBuffer)
        self.bank_success = cmd_table

        self._gameView:onBankSuccess()
    elseif sub == g_var(game_cmd).SUB_GR_USER_INSURE_FAILURE then
        local cmd_table = ExternalFun.read_netdata(g_var(game_cmd).CMD_GR_S_UserInsureFailure, dataBuffer)
        self.bank_fail = cmd_table

        self._gameView:onBankFailure()
    elseif sub == g_var(game_cmd).SUB_GR_USER_INSURE_INFO then --银行资料
        local cmdtable = ExternalFun.read_netdata(g_var(game_cmd).CMD_GR_S_UserInsureInfo, dataBuffer)

        self._gameView:onGetBankInfo(cmdtable)
    else
        print("unknow gamemessage sub is ==>"..sub)
    end
end

--游戏空闲
function GameLayer:onSubGameFree( dataBuffer )
    print("game free")
    yl.m_bDynamicJoin = false
    self.cmd_gamefree = ExternalFun.read_netdata(g_var(cmd).CMD_S_GameFree, dataBuffer);
    --dump(self.cmd_gamefree)
    --游戏倒计时
    self:SetGameClock(self:GetMeChairID(), g_var(cmd).kGAMEFREE_COUNTDOWN, self.cmd_gamefree.cbTimeLeave)

    self._gameView:onGameFree();
end

--游戏开始
function GameLayer:onSubGameStart( dataBuffer )
    print("game start");
    self.cmd_gamestart = ExternalFun.read_netdata(g_var(cmd).CMD_S_GameStart,dataBuffer);
    --dump(self.cmd_gamestart)
    --播放开始音效
    ExternalFun.playSoundEffect("GAME_START.wav")

    -- local ebi = GameDefine.getEmptyBankInfo()
    -- ebi.wBankerUser = cmd_gamestart.wBankerUser
    -- ebi.lBankerScore = cmd_gamestart.lBankerScore
    -- ebi.nBankerTime = cmd_table.nBankerTime
    -- ebi.lBankerWinScore = cmd_table.lBankerScore

    self._dataModle.m_tabGameBankInfo.wBankerUser = self.cmd_gamestart.wBankerUser
    self._dataModle.m_tabGameBankInfo.lBankerScore = self.cmd_gamestart.lBankerScore
    -- self._dataModle.m_tabGameBankInfo.lBankerScore = self._dataModle.m_tabGameBankInfo.lBankerScore + 1
    -- --刷新庄家信息
    self._gameView:onChangeBanker();

    -- --玩家最大下注
    self._gameView.m_llMaxJetton = self.cmd_gamestart.lUserMaxScore;

    -- --游戏倒计时
    self:SetGameClock(self:GetMeChairID(), g_var(cmd).kGAMEPLAY_COUNTDOWN, self.cmd_gamestart.cbTimeLeave)

    self._gameView:onGameStart();
end

--用户下注
function GameLayer:onSubPlaceJetton( dataBuffer )
    print("game bet");
    self.cmd_placebet = ExternalFun.read_netdata(g_var(cmd).CMD_S_PlaceJetton, dataBuffer);
    --dump(self.cmd_placebet)

    self._gameView.m_lAllJetton = self._gameView.m_lAllJetton + self.cmd_placebet.lJettonScore
    self._gameView:refreshJetton()

    if self.cmd_placebet.wChairID == self:GetMeChairID() or self._gameView.m_wBankerUser == self:GetMeChairID() or self.cmd_placebet.cbJettonArea == 0 or self.cmd_placebet.cbJettonArea == 1 then
        if self.cmd_placebet.lJettonScore == 5000000 then
            ExternalFun.playSoundEffect("ADD_GOLD_EX.wav")
        else
            ExternalFun.playSoundEffect("ADD_GOLD.wav")
        end
        print("self.cmd_placebet.lJettonScore",self.cmd_placebet.lJettonScore)
        self._gameView:onGetUserBet();
    end
end

function GameLayer:OnUserStartBet(dataBuffer)
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_StartBet,dataBuffer)
    dump(cmd_table)
end

--游戏结束
function GameLayer:onSubGameEnd( dataBuffer )
    print("@@@@@@@@@@@@@开牌@@@@@@@@@@@@@@")
    print("game end");
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_GameEnd,dataBuffer)
    dump(cmd_table)
    --保存游戏结果
    self._dataModle.m_tabGameEndCmd = cmd_table

    self._gameView.m_lBankerScore = self._gameView.m_lBankerScore + cmd_table.lBankerScore
    local ebi = GameDefine.getEmptyBankInfo()
    ebi.wBankerUser = self._gameView.m_wBankerUser
    ebi.lBankerScore = self._gameView.m_lBankerScore
    ebi.nBankerTime = cmd_table.nBankerTime
    ebi.lBankerWinScore = cmd_table.lBankerTotallScore

    self._dataModle.m_tabGameBankInfo = ebi
    --庄家信息 
    --self._gameView:onChangeBanker(self._gameView.m_wBankerUser,bankerscore,cmd_table.nBankerTime, cmd_table.lBankerTotallScore);

    --游戏倒计时
    self:SetGameClock(self:GetMeChairID(), g_var(cmd).kGAMEOVER_COUNTDOWN, cmd_table.cbTimeLeave)
    
    --游戏记录
    local rec = GameDefine.getEmptyRecord()
    --设置游戏结果
    local egr = GameDefine.getEmptyGameResult()

    egr.m_llTotal = cmd_table.lUserScore
    egr.lBankerScore = cmd_table.lBankerScore
    egr.lUserScore = cmd_table.lUserScore
    egr.lUserReturnScore = cmd_table.lUserReturnScore
    --res.m_pAreaScore = cmd_table.lPlayScore[1]
    for i=1,3 do
        egr.cbDiceValue[i] = cmd_table.cbDiceValue[1][i]
        rec.cbDiceValue[i] = cmd_table.cbDiceValue[1][i]
    end

    local bJoin = false

    local winMultiple = {}
    local winArea = g_var(GameLogic):DeduceWinner(winMultiple,cmd_table.cbDiceValue[1])
    -- print("胜利区域")

    self._dataModle.m_tabBetArea = winMultiple


    --增加游戏记录
    for i=1,#rec.cbDiceValue do
        egr.cbDicePoints = egr.cbDicePoints + egr.cbDiceValue[i]
        rec.cbDicePoints = rec.cbDicePoints + rec.cbDiceValue[i]
    end
    if rec.cbDicePoints >= 3 and rec.cbDicePoints <= 10 then
        egr.cbDiceDaxiao = "小"
        rec.cbDiceDaxiao = "小"
    elseif rec.cbDicePoints >= 11 and rec.cbDicePoints <= 18 then
        egr.cbDiceDaxiao = "大"
        rec.cbDiceDaxiao = "大"
    end
    self._dataModle:addGameRecord(rec)
    self._dataModle.m_tabGameResult = egr

    --成绩
    -- self._dataModle.m_llTotalScore = cmd_table.lPlayAllScore
    -- self._dataModle:calcuteRata(nWinCount, nLoseCount)
 
    self._gameView.m_cbGameStatus = g_var(cmd).GS_GAME_END;
    self._gameView:onGetGameEnd(cmd_table.cbTimeLeave)
end

--申请庄家
function GameLayer:onSubApplyBanker( dataBuffer )
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_ApplyBanker,dataBuffer);
    self.cmd_applybanker = cmd_table;
    self._dataModle:addApplyUser(cmd_table.wApplyUser, self.m_wCurrentRobApply == cmd_table.wApplyUser ) 

    self._gameView:onGetApplyBanker()
    print("apply banker ==>" .. cmd_table.wApplyUser)
end

--切换庄家
function GameLayer:onSubChangeBanker( dataBuffer )
    print("change banker")
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_ChangeBanker,dataBuffer);
    -- dump(cmd_table)

    self.cmd_changebanker = cmd_table;
    --从申请列表移除
    self._dataModle:removeApplyUser(cmd_table.wBankerUser)
    self._gameView.m_lBankerScore = cmd_table.lBankerScore
    local ebi = GameDefine.getEmptyBankInfo()
    ebi.wBankerUser = cmd_table.wBankerUser
    ebi.lBankerScore = cmd_table.lBankerScore
    ebi.nBankerTime = 0
    ebi.lBankerWinScore = 0
    self._dataModle.m_tabGameBankInfo = ebi

    self._gameView:onChangeBanker()

    --申请列表更新
    self._gameView:refreshApplyList()

    --刷新申请按钮状态
    self._gameView:refreshCondition()
end

--更新积分
function GameLayer:onSubChangeUserScore( dataBuffer )
    
end

--游戏记录
function GameLayer:onSubSendRecord( dataBuffer )
    local len = dataBuffer:getlen();
    local recordcount = math.floor(len / g_var(cmd).RECORD_LEN);
    if (len - recordcount * g_var(cmd).RECORD_LEN) ~= 0 then
        print("record_len_error" .. len);
        return;
    end
    self._dataModle:clearRecord()
    
    --游戏记录
    local game_record = {};
    --recordcount = recordcount > 10 and 10 or recordcount
    --读取记录列表

    print("@@@@@@@@游戏记录@@@@@@@@@@")
    for i=1,recordcount do
        if nil == dataBuffer then
            break;
        end
        local rec = GameDefine.getEmptyRecord()
        --local serverrecord = GameDefine.getEmptyServerRecord();
        rec.cbDiceValue[1] = dataBuffer:readbyte();
        rec.cbDiceValue[2] = dataBuffer:readbyte();
        rec.cbDiceValue[3] = dataBuffer:readbyte();
        --rec.cbDiceValue = serverrecord;
        for i=1,#rec.cbDiceValue do
            rec.cbDicePoints = rec.cbDicePoints + rec.cbDiceValue[i]
        end
        if rec.cbDicePoints >= 4 and rec.cbDicePoints <= 10 then
            rec.cbDiceDaxiao = "小"
        elseif rec.cbDicePoints >= 11 and rec.cbDicePoints <= 18 then
            rec.cbDiceDaxiao = "大"
        end
        self._dataModle:addGameRecord(rec)
        game_record[#game_record+1] = rec
    end

    self._gameView:updateWallBill()
end

--下注失败
function GameLayer:onSubJettonFail( dataBuffer )
    self.cmd_jettonfail = ExternalFun.read_netdata(g_var(cmd).CMD_S_PlaceJettonFail, dataBuffer)

    self._gameView:onGetUserBetFail()
end

--取消申请
function GameLayer:onSubCancelBanker( dataBuffer )
    print("cancel banker")
    self.cmd_cancelbanker = ExternalFun.read_netdata(g_var(cmd).CMD_S_CancelBanker, dataBuffer)

    -- if self.cmd_cancelbanker.wCancelUser == self.m_wCurrentRobApply then
    --     self._gameView.m_wCurrentRobApply = yl.INVALID_CHAIR
    --     self.m_wCurrentRobApply = yl.INVALID_CHAIR
    -- end
    --从申请列表移除
    self._dataModle:removeApplyUser(self.cmd_cancelbanker.wCancelUser)

    self._gameView:onGetCancelBanker()
end

--管理员命令
function GameLayer:onSubAdminCmd( dataBuffer )
    
end

--更新库存
function GameLayer:onSubUpdateStorage( dataBuffer )
    
end

--超级抢庄
-- function GameLayer:onSubSupperRobBaner( dataBuffer )
--     local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_SuperRobBanker, dataBuffer)
--     if true == cmd_table.bSucceed then
--         print("apply " .. cmd_table.wApplySuperRobUser)
--         print("cur " .. cmd_table.wCurSuperRobBankerUser)
--         local rob = cmd_table.wApplySuperRobUser
--         local cur = cmd_table.wCurSuperRobBankerUser
--         self._gameView.m_wCurrentRobApply = rob
--         self.m_wCurrentRobApply = suRob
        
--         --更新超级抢庄列表
--         self._dataModle:updateSupperRobBanker(rob, cur)
--         --界面通知
--         self._gameView:onGetSupperRobApply()

--         --申请列表更新
--         self._gameView:refreshApplyList()
--     end
-- end

--超级抢庄玩家离开
-- function GameLayer:onSubSupperRobLeave( dataBuffer )
--     local leaveUser = dataBuffer:readword()

--     self._gameView.m_wCurrentRobApply = yl.INVALID_CHAIR
--     self.m_wCurrentRobApply = yl.INVALID_CHAIR
    --从申请列表移除
    --self._dataModle:removeApplyUser(leaveUser)
    --刷新申请调整
    --self._gameView:refreshCondition()
    --
    --self._gameView:onGetSupperRobLeave(leaveUser)

    --申请列表更新
    --self._gameView:refreshApplyList()
--end

--占位
-- function GameLayer:onSubOccupySeat( dataBuffer )
--     local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_OccupySeat, dataBuffer)

--     local wchair = cmd_table.wOccupySeatChairID
--     local index = cmd_table.cbOccupySeatIndex
--     self._gameView:onGetSitDown(index, wchair, true)
-- end

-- --占位失败
-- function GameLayer:onSubOccupySeatFail( dataBuffer )
--     local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_OccupySeat_Fail, dataBuffer) 

--     local wchair = cmd_table.wAlreadyOccupySeatChairID
--     local index = cmd_table.cbAlreadyOccupySeatIndex
--     self._gameView:onGetSitDownLeave(index)
-- end

-- --更新占位
-- function GameLayer:onSubUpdateOccupySeat( dataBuffer )
--     local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_UpdateOccupySeat, dataBuffer)

--     for i = 1, g_var(cmd).MAX_OCCUPY_SEAT_COUNT do
--         if cmd_table.tabWOccupySeatChairID[1][i] == yl.INVALID_CHAIR then
--             self._gameView:onGetSitDownLeave(i - 1)
--         end
--     end
-- end

function GameLayer:onEventUserEnter( wTableID,wChairID,useritem )
    print("add user " .. useritem.wChairID .. "; nick " .. useritem.szNickName)
    --缓存用户
    self._dataModle:addUser(useritem)

    --刷新用户列表
    self._gameView:refreshUserList()
end

function GameLayer:onEventUserStatus(useritem,newstatus,oldstatus)
    print("change user " .. useritem.wChairID .. "; nick " .. useritem.szNickName)
    if newstatus.cbUserStatus == yl.US_FREE then
        print("删除")
        self._dataModle:removeUser(useritem)
    else
        --刷新用户信息
        self._dataModle:updateUser(useritem)
    end

    --刷新用户列表
    self._gameView:refreshUserList()
end

function GameLayer:onEventUserScore( item )

    self._dataModle:updateUser(item)    
    self._gameView:onGetUserScore(item)

    --刷新用户列表
    self._gameView:refreshUserList()

    self._gameView:refreshApplyList()
end

-- eg: 10000 转 1.0万
function GameLayer:formatScoreText(score)
    local scorestr = ExternalFun.formatScore(score)
    if score > -10000  and   score < 10000  then
        return scorestr
    end
    if score > 0 then
        if score < 100000000 then
            scorestr = string.format("%.2f万", score / 10000)
            return scorestr
        end
        scorestr = string.format("%.2f亿", score / 100000000)
    elseif score < 0 then
        if score < -100000000 then
            scorestr = string.format("%.2f亿", score / 100000000)
            return scorestr
        end
        scorestr = string.format("%.2f万", score / 10000)
    end
    return scorestr
end
---------------------------------------------------------------------------------------
return GameLayer