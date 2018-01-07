local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")
local GameLayer = class("GameLayer", GameModel)

local module_pre = "game.yule.sharkwanimal.src";
require("cocos.init")
local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local cmd = module_pre .. ".models.CMD_Game"
local game_cmd = appdf.HEADER_SRC .. "CMD_GameServer"
local GameViewLayer = appdf.req(module_pre .. ".views.layer.GameViewLayer")
local QueryDialog   = require("app.views.layer.other.QueryDialog")
local g_var = ExternalFun.req_var
local GameFrame = appdf.req(module_pre .. ".models.GameFrame")



-------------------------------------------------------------------------

function GameLayer:ctor( frameEngine,scene )
    ExternalFun.registerNodeEvent(self)
    self.m_bLeaveGame = false
    self.m_bOnGame = false
    self._dataModle = GameFrame:create()    
    GameLayer.super.ctor(self,frameEngine,scene)
    self._roomRule = self._gameFrame._dwServerRule
end

--创建场景
function GameLayer:CreateView()
    print("GameLayer:CreateView")
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

---------------------------------------------------------------------------------------
------继承函数
function GameLayer:onExit()
    self:KillGameClock()
    self:dismissPopWait()
end
-- 重置游戏数据
function GameLayer:OnResetGameEngine()
    self.m_bOnGame = false
    self:standUpAndQuit()
end

--强行起立、退出(用户切换到后台断网处理)
function GameLayer:standUpAndQuit()
    --self:sendCancelOccupy()
    GameLayer.super.standUpAndQuit(self)
end

--退出桌子
function GameLayer:onExitTable()
    self:KillGameClock()
    local MeItem = self:GetMeUserItem()
    if MeItem and MeItem.cbUserStatus > yl.US_FREE then
        self:runAction(cc.Sequence:create(
            cc.DelayTime:create(2),
            cc.CallFunc:create(
                function ()   
                    self:showPopWait()
                    --self:sendCancelOccupy()
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
function GameLayer:sendUserBet( cbArea, lScore ,bClearUp)
    local cmddata = ExternalFun.create_netdata(g_var(cmd).CMD_C_PlaceJetton)
    --local cmddata = CCmd_Data:create(53)
    cmddata:pushbyte(cbArea)
    cmddata:pushscore(lScore)
    cmddata:pushbool(bClearUp)

    cmddata:pushscore(lScore)
    cmddata:pushstring(lScore,cmd.SERVER_LEN)
    self:SendData(g_var(cmd).SUB_C_PLACE_JETTON, cmddata)
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
    print("==================》》》》》》》场景数据:" .. cbGameStatus);
    if self.m_bOnGame then
        return
    end
    self.m_bOnGame = true
    
    self._gameView.m_cbGameStatus = cbGameStatus;
    if cbGameStatus == g_var(cmd).GAME_SCENE_FREE   then                        --空闲状态
        self:onEventGameSceneFree(dataBuffer);
    elseif cbGameStatus == g_var(cmd).GAME_JETTON   then                        --下注状态
        self:onEventGameSceneJetton(dataBuffer);
    elseif cbGameStatus == g_var(cmd).GAME_END  then                            --游戏状态
        self:onEventGameSceneEnd(dataBuffer);
    end
    self:dismissPopWait()
end
--空闲状态
function GameLayer:onEventGameSceneFree( dataBuffer )
    print("==================》》》》》》》  onEventGameSceneFree");
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_StatusFree, dataBuffer);
    yl.m_bDynamicJoin = false
    self._gameView:setGameTimer(g_var(cmd).GAME_SCENE_FREE,cmd_table.cbTimeLeave)
    self._gameView.m_lUserMaxScore = cmd_table.lUserMaxScore;
    --self._gameView:setSelfScore(cmd_table.lUserMaxScore)
    self._gameView.m_wBankerUser = cmd_table.wBankerUser;
    self._gameView.m_wBankerTime = cmd_table.wBankerTime;
    self._gameView.m_lBankerWinScore = cmd_table.lBankerWinScore;
    self._gameView.m_lBankerScore = cmd_table.lBankerScore;
    self._gameView.m_bEnableSysBanker = cmd_table.bEnableSysBanker;
    self._gameView.m_lApplyBankerCondition = cmd_table.lApplyBankerCondition;
    self._gameView.m_lAreaLimitScore = cmd_table.lAreaLimitScore;
    print(" self._gameView.m_lAreaLimitScore:".. self._gameView.m_lAreaLimitScore)
    self._gameView:setChipPool(cmd_table.lPrizePool);
    self._gameView.m_CheckImage = cmd_table.CheckImage;
    self._gameView.m_nCode = cmd_table.nCode

    self._gameView.m_GamePondCopy = cmd_table.lPrizePool;

    self._gameView:onGameSceneFree();
end
--下注状态
function GameLayer:onEventGameSceneJetton( dataBuffer )
    print("==================》》》》》》》  onEventGameSceneJetton");
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_StatusPlay, dataBuffer);
    yl.m_bDynamicJoin = false
    --dump(cmd_table, "Jetton cmd_table onEventGameSceneJetton")

    local allChipFirst = true
    for i=self._gameView.ENUM_CHIPNUM.NUM_BIRE_ALL,self._gameView.ENUM_CHIPNUM.NUM_TUZI_SELF do
        if allChipFirst == true then
            self._gameView:setChipString(i, cmd_table.lAllJettonScore[1][(i - self._gameView.ENUM_CHIPNUM.NUM_BIRE_ALL) / 2 + 2])
        else 
            self._gameView:setChipString(i, cmd_table.lUserJettonScore[1][(i - self._gameView.ENUM_CHIPNUM.NUM_BIRE_ALL - 1) / 2 + 2])
        end
        allChipFirst = not allChipFirst  
    end

    
    self._gameView.m_lUserMaxScore = cmd_table.lUserMaxScore;
    --self._gameView:setSelfScore(cmd_table.lUserMaxScore)
    self._gameView.m_lApplyBankerCondition = cmd_table.lApplyBankerCondition;
    self._gameView.m_lAreaLimitScore = cmd_table.lAreaLimitScore;
    print(" self._gameView.m_lAreaLimitScore:".. self._gameView.m_lAreaLimitScore)
    self._gameView.m_cbTableCardArray = cmd_table.cbTableCardArray
    self._gameView.m_wBankerUser = cmd_table.wBankerUser;
    self._gameView.m_wBankerTime = cmd_table.wBankerTime;
    self._gameView.m_lBankerWinScore = cmd_table.lBankerWinScore;
    self._gameView.m_lBankerScore = cmd_table.lBankerScore;
    self._gameView.m_bEnableSysBanker = cmd_table.bEnableSysBanker;
    self._gameView.m_lEndBankerScore = cmd_table.lEndBankerScore;
    self._gameView.m_lEndUserScore = cmd_table.lEndUserScore;
    self._gameView.m_lEndUserReturnScore = cmd_table.lEndUserReturnScore;
    self._gameView.m_lEndRevenue = cmd_table.lEndRevenue;
    self._gameView.m_lEndBankerScore = cmd_table.lEndBankerScore;
    self._gameView.m_lEndBankerScore = cmd_table.lEndBankerScore;
    self._gameView:setChipPool(cmd_table.lPrizePool);
    self._gameView.m_nCode = cmd_table.nCode
    self._gameView:setGameTimer(g_var(cmd).GAME_JETTON,cmd_table.cbTimeLeave)
    self._gameView.m_checkImage = cmd_table.CheckImage

    self._gameView:onGameSceneJetton();  
end
--结束状态
function GameLayer:onEventGameSceneEnd( dataBuffer )
    print("==================》》》》》》》  onEventGameSceneEnd");
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_StatusPlay, dataBuffer);

    yl.m_bDynamicJoin = false
    local allChipFirst = true
    for i=self._gameView.ENUM_CHIPNUM.NUM_BIRE_ALL,self._gameView.ENUM_CHIPNUM.NUM_TUZI_SELF do
        if allChipFirst == true then
            self._gameView:setChipString(i, cmd_table.lAllJettonScore[1][(i - self._gameView.ENUM_CHIPNUM.NUM_BIRE_ALL) / 2 + 2])
        else 
            self._gameView:setChipString(i, cmd_table.lUserJettonScore[1][(i - self._gameView.ENUM_CHIPNUM.NUM_BIRE_ALL - 1) / 2 + 2])
        end
        allChipFirst = not allChipFirst  
    end

    self._gameView.m_lUserMaxScore = cmd_table.lUserMaxScore;
    --self._gameView:setSelfScore(cmd_table.lUserMaxScore)
    self._gameView.m_lApplyBankerCondition = cmd_table.lApplyBankerCondition;
    self._gameView.m_lAreaLimitScore = cmd_table.lAreaLimitScore;
    print(" self._gameView.m_lAreaLimitScore:".. self._gameView.m_lAreaLimitScore)
    self._gameView.m_cbTableCardArray = cmd_table.cbTableCardArray
    self._gameView.m_wBankerUser = cmd_table.wBankerUser;
    self._gameView.m_wBankerTime = cmd_table.wBankerTime;
    self._gameView.m_lBankerWinScore = cmd_table.lBankerWinScore;
    self._gameView.m_lBankerScore = cmd_table.lBankerScore;
    self._gameView.m_bEnableSysBanker = cmd_table.bEnableSysBanker;
    self._gameView.m_lEndBankerScore = cmd_table.lEndBankerScore;
    self._gameView.m_lEndUserScore = cmd_table.lEndUserScore;
    self._gameView.m_lEndUserReturnScore = cmd_table.lEndUserReturnScore;
    self._gameView.m_lEndRevenue = cmd_table.lEndRevenue;
    self._gameView.m_lEndBankerScore = cmd_table.lEndBankerScore;
    self._gameView.m_lEndBankerScore = cmd_table.lEndBankerScore;
    self._gameView:setChipPool(cmd_table.lPrizePool);
    print("cmd_table.lPrizePool:"..cmd_table.lPrizePool)
    self._gameView.m_nCode = cmd_table.nCode
    self._gameView:setGameTimer(g_var(cmd).GAME_END,cmd_table.cbTimeLeave)
    print("cmd_table.cbTimeLeave:"..cmd_table.cbTimeLeave)
    self._gameView.m_checkImage = cmd_table.CheckImage

    self._gameView:onGameSceneEnd();


    --dump(cmd_table, "end cmd_table onEventGameSceneEnd")
    print(" self._gameView.m_lAreaLimitScore:".. self._gameView.m_lAreaLimitScore)
    print("++++++++++++++++++++++++++"..cmd_table.cbGameStatus.."g_var(cmd).GAME_END"..g_var(cmd).GAME_END)
end
--银行信息
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
        --dump(cmdtable, "cmdtable", 6)

        self._gameView:onGetBankInfo(cmdtable)
    else
        print("unknow gamemessage sub is ==>"..sub)
    end
end
---------------------------------------------------------------
-- 游戏消息
function GameLayer:onEventGameMessage(sub,dataBuffer) 
    if self.m_bLeaveGame or nil == self._gameView then
        return
    end 

    if sub == g_var(cmd).SUB_S_GAME_FREE then 
        self._gameView.m_cbGameStatus = g_var(cmd).GAME_SCENE_FREE
        self:onSubGameFree(dataBuffer); 
    elseif sub == g_var(cmd).SUB_S_GAME_START then
        self._gameView.m_cbGameStatus = g_var(cmd).GAME_JETTON
        self:onSubGameStart(dataBuffer); 
    elseif sub == g_var(cmd).SUB_S_PLACE_JETTON then
        self._gameView.m_cbGameStatus = g_var(cmd).GAME_JETTON
        self:onSubPlaceBet(dataBuffer); 
    elseif sub == g_var(cmd).SUB_S_GAME_END then
        self._gameView.m_cbGameStatus = g_var(cmd).GAME_END
        self:onSubGameEnd(dataBuffer); 
    elseif sub == g_var(cmd).SUB_S_SEND_RECORD then
        self:onSubGameRecord(dataBuffer);  
    elseif sub == g_var(cmd).SUB_S_PLACE_JETTON_FAIL then
        self:onSubGamePlaceJettonFail(dataBuffer);  
    end
end
--游戏空闲
function GameLayer:onSubGameFree( dataBuffer )
    print("---------->game free")
    yl.m_bDynamicJoin = false
    local cmd_gamefree = ExternalFun.read_netdata(g_var(cmd).CMD_S_GameFree, dataBuffer);
    self._gameView:setGameTimer(g_var(cmd).GAME_SCENE_FREE,cmd_gamefree.cbTimeLeave);
    print("cmd_gamefree.cbTimeLeave:"..cmd_gamefree.cbTimeLeave)
    self._gameView:setChipPool(cmd_gamefree.lPrizePool);
    print("cmd_gamefree.lPrizePool:"..cmd_gamefree.lPrizePool)
    self._gameView.m_nCode = cmd_gamefree.nCode

    self._gameView.m_GamePondCopy = cmd_gamefree.lPrizePool;
    self._gameView:onGameFree();
end
--游戏开始
function GameLayer:onSubGameStart( dataBuffer )
    print("---------->game start");
    local cmd_gamestart = ExternalFun.read_netdata(g_var(cmd).CMD_S_GameStart,dataBuffer);
    self._gameView.m_wBankerUser = cmd_gamestart.wBankerUser;
    self._gameView.m_lBankerScore = cmd_gamestart.lBankerScore;
    self._gameView.m_lUserMaxScore = cmd_gamestart.lUserMaxScore;
    --self._gameView:setSelfScore(cmd_gamestart.lUserMaxScore)
    --self._gameView:setChipPool(cmd_gamestart.lGamePond);
    self._gameView:setGameTimer(g_var(cmd).GAME_JETTON,cmd_gamestart.cbTimeLeave);
    self._gameView.m_bContiueCard = cmd_gamestart.bContiueCard;
    self._gameView.m_nCode = cmd_gamestart.nCode
    print("===================================cmd_gamestart.lGamePond:"..cmd_gamestart.lGamePond) --0
    self._gameView:onGameStart();
    --dump(cmd_gamestart, "cmd_gamestart onSubGameStart")
end
--游戏下注
function GameLayer:onSubPlaceBet( dataBuffer )
    --print("---------->game Bet");
    local cmd_gamebet = ExternalFun.read_netdata(g_var(cmd).CMD_S_PlaceBet,dataBuffer);
    --dump(cmd_gamebet, "onSubPlaceBet_cmd_gamebet")
    self._gameView:onGameBet(cmd_gamebet);
end
--游戏结束
function GameLayer:onSubGameEnd( dataBuffer )
    print("---------->game end---");
    local cmd_gameend = ExternalFun.read_netdata(g_var(cmd).CMD_S_GameEnd,dataBuffer);
    dump(cmd_gameend, "cmd_gameend")
    --信息处理
    if cmd_gameend.cbMarkCard[1] == 8 and cmd_gameend.cbTableCardArray[1][1] == 0 then
        cmd_gameend.cbMarkCard[1] = 11
    elseif cmd_gameend.cbMarkCard[1] == 8 and cmd_gameend.cbTableCardArray[1][1] == 7 then
        cmd_gameend.cbMarkCard[1] = 10
    elseif cmd_gameend.cbMarkCard[1] == 8 and cmd_gameend.cbTableCardArray[1][1] == 21 then
        cmd_gameend.cbMarkCard[1] = 9
    end

    self._gameView:setGameTimer(g_var(cmd).GAME_END,cmd_gameend.cbTimeLeave);
    self._gameView.m_cbLeftCardCount = cmd_gameend.cbLeftCardCount
    self._gameView.m_bcFirstCard = cmd_gameend.bcFirstCard
    self._gameView.m_cbAddedMultiple = cmd_gameend.cbAddedMultiple
    self._gameView.m_lBankerTotallScore = cmd_gameend.lBankerTotallScore
    self._gameView.m_nBankerTime = cmd_gameend.nBankerTime
    self._gameView.m_lUserScore = cmd_gameend.lUserScore
    self._gameView.m_lUserReturnScore = cmd_gameend.lUserReturnScore
    self._gameView.m_lRevenue = cmd_gameend.lRevenue
    self._gameView.m_cbTableCardArray = cmd_gameend.cbTableCardArray
    self._gameView.m_cbMarkCard = cmd_gameend.cbMarkCard
    

    self._gameView:onGameEnd(cmd_gameend);
end
--游戏记录
function GameLayer:onSubGameRecord( dataBuffer )
    print("---------->game onSubGameRecord---");
    --dump(cmd_gameend, "=================onSubGameRecord=======================")

    local len = dataBuffer:getlen();
    local recordcount = math.floor(len / g_var(cmd).RECORD_LEN);
    if (len - recordcount * g_var(cmd).RECORD_LEN) ~= 0 then
        print("record_len_error" .. len);
        return;
    end
    
    --游戏记录
    local game_record = {};
    --读取记录列表
    for i=1,recordcount do
        if nil == dataBuffer then
            break;
        end
        local rec = dataBuffer:readbyte();
        self._gameView:insertHistroy(rec);
    end
end
--游戏下注失败
function GameLayer:onSubGamePlaceJettonFail( dataBuffer )
    print("---------->game onSubGamePlaceJettonFail---");
    --dump(cmd_gameend, "=================onSubGameRecord=======================")
    local cmd_gamejettonfail = ExternalFun.read_netdata(g_var(cmd).CMD_S_PlaceJettonFail,dataBuffer);

    self._gameView:onGameBetFail(cmd_gamejettonfail)
end

function GameLayer:onEventUserEnter( wTableID,wChairID,useritem )
    print("add user " .. useritem.wChairID .. "; nick " .. useritem.szNickName)
    --缓存用户
    self._dataModle:addUser(useritem)

    --刷新用户列表
    self._gameView:refreshUserList()
end

function GameLayer:onEventUserStatus(useritem,newstatus,oldstatus)
    --print("change user " .. useritem.wChairID .. "; nick " .. useritem.szNickName)
    if newstatus.cbUserStatus == yl.US_FREE then
        --print("删除")
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
end
---------------------------------------------------------------------------------------
return GameLayer