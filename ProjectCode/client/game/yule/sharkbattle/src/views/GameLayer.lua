local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")
local GameLayer = class("GameLayer", GameModel)

local module_pre = "game.yule.sharkbattle.src";
require("cocos.init")
local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local cmd = module_pre .. ".models.CMD_Game"
local game_cmd = appdf.HEADER_SRC .. "CMD_GameServer"
local GameViewLayer = appdf.req(module_pre .. ".views.layer.GameViewLayer")
local QueryDialog   = require("app.views.layer.other.QueryDialog")
local g_var = ExternalFun.req_var

function GameLayer:ctor( frameEngine,scene )
    ExternalFun.registerNodeEvent(self)
    self.m_bLeaveGame = false
    self.m_bOnGame = false
    GameLayer.super.ctor(self,frameEngine,scene)
    self._roomRule = self._gameFrame._dwServerRule
end

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
end

function GameLayer:logData(msg)
    if nil ~= self._scene.logData then
        self._scene:logData(msg)
    end
end
function GameLayer:onExit()
    self:KillGameClock()
    self:dismissPopWait()
end

function GameLayer:OnResetGameEngine()
    self.m_bOnGame = false
    self:standUpAndQuit()
end
function GameLayer:standUpAndQuit()
    GameLayer.super.standUpAndQuit(self)
end
function GameLayer:onExitTable()
    self:KillGameClock()
    local MeItem = self:GetMeUserItem()
    if MeItem and MeItem.cbUserStatus > yl.US_FREE then
        self:runAction(cc.Sequence:create(
            cc.DelayTime:create(2),
            cc.CallFunc:create(
                function ()   
                    self:showPopWait()
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

function GameLayer:onExitRoom()
    self:getFrame():onCloseSocket()

    self._scene:onKeyBack()    
end

function GameLayer:OnEventGameClockInfo(chair,time,clockId)
    if nil ~= self._gameView and nil ~= self._gameView.updateClock then
        self._gameView:updateClock(clockId, time)
    end
end

function GameLayer:SetGameClock(chair,id,time)
    GameLayer.super.SetGameClock(self,chair,id,time)
    if nil ~= self._gameView and nil ~= self._gameView.showTimerTip then
        self._gameView:showTimerTip(id)
    end
end
function GameLayer:sendBetClear( )
   local cmddata = ExternalFun.create_netdata(g_var(cmd).CMD_C_BetClear)
   self:SendData(g_var(cmd).SUB_C_BET_CLEAR, cmddata)
end
function GameLayer:sendUserBet( cbArea, lScore )
    local cmddata = ExternalFun.create_netdata(g_var(cmd).CMD_C_PlayBet)
    cmddata:pushint(cbArea)
    cmddata:pushscore(lScore)
    cmddata:pushstring("",cmd.SERVER_LEN)
    for i = 1,32 do
       cmddata:pushbyte(0)
    end
         self._gameView.m_AllJettonDown[cbArea + 1] = self._gameView.m_AllJettonDown[cbArea + 1] + lScore ;
         self._gameView.m_PlayJettonDown[cbArea + 1] =   self._gameView.m_PlayJettonDown[cbArea +1] + lScore ;
    self:SendData(g_var(cmd).SUB_C_PLAY_BET, cmddata)
end

function GameLayer:sendTakeScore( lScore,szPassword )
    local cmddata = ExternalFun.create_netdata(g_var(game_cmd).CMD_GR_C_TakeScoreRequest)
    cmddata:setcmdinfo(g_var(game_cmd).MDM_GR_INSURE, g_var(game_cmd).SUB_GR_TAKE_SCORE_REQUEST)
    cmddata:pushbyte(g_var(game_cmd).SUB_GR_TAKE_SCORE_REQUEST)
    cmddata:pushscore(lScore)
    cmddata:pushstring(md5(szPassword),yl.LEN_PASSWORD)

    self:sendNetData(cmddata)
end

function GameLayer:sendRequestBankInfo()
    local cmddata = CCmd_Data:create(67)
    cmddata:setcmdinfo(g_var(game_cmd).MDM_GR_INSURE,g_var(game_cmd).SUB_GR_QUERY_INSURE_INFO)
    cmddata:pushbyte(g_var(game_cmd).SUB_GR_QUERY_INSURE_INFO)
    cmddata:pushstring(md5(GlobalUserItem.szPassword),yl.LEN_PASSWORD)

    self:sendNetData(cmddata)
end
function GameLayer:onEventGameScene(cbGameStatus,dataBuffer)
    print("场景数据:" .. cbGameStatus);
    if self.m_bOnGame then
        return
    end
    self.m_bOnGame = true
    
    self._gameView.m_cbGameStatus = cbGameStatus;
	if cbGameStatus == g_var(cmd).GAME_SCENE_FREE	then                         
        self:onEventGameSceneFree(dataBuffer);
	elseif cbGameStatus == g_var(cmd).GAME_SCENE_BET	then                        
        self:onEventGameSceneJetton(dataBuffer);
	elseif cbGameStatus == g_var(cmd).GAME_SCENE_END	then                      
        self:onEventGameSceneEnd(dataBuffer);
	end
    self:dismissPopWait()
end

function GameLayer:onEventGameSceneFree( dataBuffer )
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_StatusFree, dataBuffer);
    self:SetGameClock(self:GetMeChairID(), g_var(cmd).kGAMEFREE_COUNTDOWN, cmd_table.cbTimeLeave)

    self._gameView:onGameFree();
end

function GameLayer:onEventGameSceneJetton( dataBuffer )
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_StatusPlay, dataBuffer);
    self:SetGameClock(self:GetMeChairID(), g_var(cmd).kGAMEPLAY_COUNTDOWN, cmd_table.cbTimeLeave)
     for i = 1 ,12 do
         if i ~= 10 then
             str = string.format("x%d",cmd_table.nAnimalMultiple[1][i] )
             else
             str = string.format("x??" )
         end
         self._gameView.m_multiple_Node[i]:setString(str)
         self._gameView.m_AnimalMultiple[i] = cmd_table.nAnimalMultiple[1][i]
    end
    for i = 1 ,12 do
        self._gameView.m_AllJettonDown[i] = cmd_table.lAllBet[1][i];
        self._gameView.m_PlayJettonDown[i] =  cmd_table.lPlayBet[1][i];
    end
    self._gameView:onGetUserBet();   
    self._gameView:onGameStart();
end

function GameLayer:onEventGameSceneEnd( dataBuffer )
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_StatusEnd, dataBuffer)
    self:SetGameClock(self:GetMeChairID(), g_var(cmd).kGAMEOVER_COUNTDOWN, cmd_table.cbTimeLeave)
    
    for i = 1 ,12 do
         if i ~= 10 then
             str = string.format("x%d",cmd_table.nAnimalMultiple[1][i] )
             else
             str = string.format("x??" )
         end
         self._gameView.m_multiple_Node[i]:setString(str)
         self._gameView.m_AnimalMultiple[i] = cmd_table.nAnimalMultiple[1][i]
    end
    for i = 1 ,12 do
        self._gameView.m_AllJettonDown[i] = cmd_table.lAllBet[1][i];
        self._gameView.m_PlayJettonDown[i] =  cmd_table.lPlayBet[1][i];
    end
    self._gameView:GameOverVariable()
    self._gameView:onGetUserBet();
    self._gameView:onGetGameEnd()
end

function GameLayer:onEventGameMessage(sub,dataBuffer)  
    if self.m_bLeaveGame or nil == self._gameView then
        return
    end 
	if sub == g_var(cmd).SUB_S_GAME_FREE then 
        self._gameView.m_cbGameStatus = g_var(cmd).GAME_SCENE_FREE

		self:onSubGameFree(dataBuffer);
	elseif sub == g_var(cmd).SUB_S_GAME_START then 
        self._gameView.m_cbGameStatus = g_var(cmd).GAME_START

		self:onSubGameStart(dataBuffer);
	elseif sub == g_var(cmd).SUB_S_GAME_END then 
        self._gameView.m_cbGameStatus = g_var(cmd).GAME_PLAY

		self:onSubGameEnd(dataBuffer)
	elseif sub == g_var(cmd).SUB_S_PLAY_BET then 
        self._gameView.m_cbGameStatus = g_var(cmd).GAME_PLAY

		self:onSubPlaceJetton(dataBuffer);

    elseif sub == g_var(cmd).SUB_S_PLAY_BET_FAIL then
        self:onSubJettonFail(dataBuffer);
    elseif sub == g_var(cmd).SUB_S_BET_CLEAR then
        self:onSubBetClear(dataBuffer);
	else
		print("unknow gamemessage sub is ==>"..sub)
	end
end

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
    elseif sub == g_var(game_cmd).SUB_GR_USER_INSURE_INFO then 
        local cmdtable = ExternalFun.read_netdata(g_var(game_cmd).CMD_GR_S_UserInsureInfo, dataBuffer)
        dump(cmdtable, "cmdtable", 6)

        self._gameView:onGetBankInfo(cmdtable)
    else
        print("unknow gamemessage sub is ==>"..sub)
    end
end
function GameLayer:onSubGameFree( dataBuffer )
    print("game free")
    yl.m_bDynamicJoin = false

    self.cmd_gamefree = ExternalFun.read_netdata(g_var(cmd).CMD_S_GameFree, dataBuffer);
    self:SetGameClock(self:GetMeChairID(), g_var(cmd).kGAMEFREE_COUNTDOWN, self.cmd_gamefree.cbTimeLeave)

    self._gameView:onGameFree();
end
function GameLayer:onSubGameStart( dataBuffer )
    print("game start");
    self.cmd_gamestart = ExternalFun.read_netdata(g_var(cmd).CMD_S_GameStart,dataBuffer);
    ExternalFun.playSoundEffect("GAME_START.wav")

    self:SetGameClock(self:GetMeChairID(), g_var(cmd).kGAMEPLAY_COUNTDOWN, self.cmd_gamestart.cbTimeLeave)

    for i = 1 ,12 do
         if i ~= 10 then
             str = string.format("x%d",self.cmd_gamestart.nAnimalMultiple[1][i] )
             else
             str = string.format("x??" )
         end
         
         self._gameView.m_AnimalMultiple[i] = self.cmd_gamestart.nAnimalMultiple[1][i]
         self._gameView.m_multiple_Node[i]:setString(str)
    end

    self._gameView:onGameStart();
end
function GameLayer:onSubPlaceJetton( dataBuffer )

    self.cmd_placebet = ExternalFun.read_netdata(g_var(cmd).CMD_S_PlayBet, dataBuffer);



    if self.cmd_placebet.wChairID ~= self:GetMeChairID() then
       self._gameView.m_AllJettonDown[self.cmd_placebet.nAnimalIndex + 1] = self._gameView.m_AllJettonDown[self.cmd_placebet.nAnimalIndex + 1] + self.cmd_placebet.lBetChip;  
    end
    self._gameView:onGetUserBet();
end

function GameLayer:onSubGameEnd( dataBuffer )
    print("game end");
    local cmd_table = ExternalFun.read_netdata(g_var(cmd).CMD_S_GameEnd,dataBuffer)
    self:SetGameClock(self:GetMeChairID(), g_var(cmd).kGAMEOVER_COUNTDOWN, cmd_table.cbTimeLeave)
    self._gameView:GameOverVariable()
    self._gameView.m_PresentWin = cmd_table.lUserWinScore ;
    local str = string.format("%d",cmd_table.lPlayShowPrizes)
    self._gameView.m_BetrothalGift:setText(str)
    self._gameView.m_SharkJ = cmd_table.nPrizesMultiple ;
    self._gameView.m_TurnTwoTime = cmd_table.bTurnTwoTime;
    if  self._gameView.m_TurnTwoTime  == true then
        self._gameView.m_OverTurnTableTarget[1] =  ( cmd_table.nTurnTableTarget[1][1]+ 24)%28 --
        self._gameView.m_OverTurnTableTarget[2] =  (cmd_table.nTurnTableTarget[1][2] + 24)%28 
        else
        self._gameView.m_OverTurnTableTarget[1] =  0
        self._gameView.m_OverTurnTableTarget[2] =  (cmd_table.nTurnTableTarget[1][1] + 24)%28 
    end

    self._gameView.m_OverTurnTableAnimal[1] =  self._gameView.m_AnimalSpecies[(self._gameView.m_OverTurnTableTarget[1]) + 1] ;
    self._gameView.m_OverTurnTableAnimal[2] =  self._gameView.m_AnimalSpecies[(self._gameView.m_OverTurnTableTarget[2]) + 1] ;
       --

    if self._gameView.m_TurnTwoTime == true then
        self._gameView.m_TurnTarget = 1 ;
        self._gameView.m_OverFrequency[1] = (self._gameView.m_OverTurnTableTarget[1]) + 1+ 84;
        self._gameView.m_OverFrequency[2] = (self._gameView.m_OverTurnTableTarget[2]) + 1;
        self._gameView.m_OverCondition = 1 ;
        else
        self._gameView.m_TurnTarget = 2;
        self._gameView.m_OverFrequency[1] = 0;
        self._gameView.m_OverFrequency[2] = (self._gameView.m_OverTurnTableTarget[2]) + 1 + 84;
        self._gameView.m_OverCondition = 3 ;
    end

    self._gameView:onGetGameEnd()
end
function GameLayer:onSubJettonFail( dataBuffer )
    self.cmd_jettonfail = ExternalFun.read_netdata(g_var(cmd).CMD_S_PlayBetFail, dataBuffer)

    if self.cmd_placebet.wChairID == GlobalUserItem.dwUserID then
    self._gameView.m_AllJettonDown[self.cmd_placebet.nAnimalIndex + 1] = self._gameView.m_AllJettonDown[self.cmd_placebet.nAnimalIndex + 1] - self.cmd_placebet.lBetChip;
    self._gameView.m_PlayJettonDown[self.cmd_placebet.nAnimalIndex + 1] = self._gameView.m_PlayJettonDown[self.cmd_placebet.nAnimalIndex + 1] - self.cmd_placebet.lBetChip;   
    end
    self._gameView:onGetUserBet();
end
function GameLayer:onSubBetClear( dataBuffer )
    self.cmd_BetClear = ExternalFun.read_netdata(g_var(cmd).CMD_S_BetClear, dataBuffer)

    for i = 1 ,12 do
         if self.cmd_BetClear.wChairID  ~= self:GetMeChairID() then
         self._gameView.m_AllJettonDown[i] = self._gameView.m_AllJettonDown[i] - self.cmd_BetClear.lPlayBet[1][i] ;
         self._gameView.m_PlayJettonDown[i] =   self._gameView.m_PlayJettonDown[i] - self.cmd_BetClear.lPlayBet[1][i] ;
         end
    end
    
    self._gameView:onGetUserBet();
end
---------------------------------------------------------------------------------------
return GameLayer