--
-- Author: zhouweixiang
-- Date: 2016-11-25 16:04:02
--
local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")
local GameLayer = class("GameLayer", GameModel)

local Game_CMD = appdf.req(appdf.GAME_SRC.."yule.oxbattle.src.models.CMD_Game")
local GameServer_CMD = appdf.req(appdf.HEADER_SRC.."CMD_GameServer")
local GameViewLayer = appdf.req(appdf.GAME_SRC.."yule.oxbattle.src.views.layer.GameViewLayer")
local GameFrame = appdf.req(appdf.GAME_SRC.."yule.oxbattle.src.models.GameFrame")
local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

function GameLayer:ctor(frameEngine, scene)	
	self._dataModle = GameFrame:create()

	GameLayer.super.ctor(self, frameEngine, scene)
	GameLayer.super.OnInitGameEngine(self)
	self._roomRule = self._gameFrame._dwServerRule

	--是否收到场景消息
	self.m_bOnGame = false
end

--获取gamekind
function GameLayer:getGameKind()
    return Game_CMD.KIND_ID
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

function GameLayer:reSetData()
    
end

----继承函数
function GameLayer:onExit()
	self:dismissPopWait()
	self:KillGameClock()
	GameLayer.super.onExit(self)
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
    self._gameView:resetGameData()
end

--强行起立、退出(用户切换到后台断网处理)
function GameLayer:standUpAndQuit()
    self:sendCancelOccupy()
    GameLayer.super.standUpAndQuit(self)
end

--退出桌子
function GameLayer:onExitTable()
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
	self._gameFrame:onCloseSocket()
	self:KillGameClock()
	self._scene:onKeyBack()
end

-- 设置计时器
function GameLayer:SetGameClock(chair,id,time)
    GameLayer.super.SetGameClock(self,chair,id,time)
end

------------------------------------
------网络处理
------------------------------------

--发送加注
function GameLayer:SendPlaceJetton(jettonScore, jettonArea)
	local cmddata = ExternalFun.create_netdata(Game_CMD.CMD_C_PlaceJetton)
	cmddata:pushbyte(jettonArea)
	cmddata:pushscore(jettonScore)
	self:SendData(Game_CMD.SUB_C_PLACE_JETTON, cmddata)
end

--超级抢庄
function GameLayer:sendRobBanker()
	local cmddata = CCmd_Data:create(0)
	self:SendData(Game_CMD.SUB_C_SUPERROB_BANKER, cmddata)
end

--申请上庄
function GameLayer:sendApplyBanker()
	local cmddata = CCmd_Data.create(0)
	self:SendData(Game_CMD.SUB_C_APPLY_BANKER, cmddata)
end

--取消申请
function GameLayer:sendCancelApply(  )
    local cmddata = CCmd_Data:create(0)
    self:SendData(Game_CMD.SUB_C_CANCEL_BANKER, cmddata)
end

--申请坐下
function GameLayer:sendSitDown(index, wchair)
    local cmddata = ExternalFun.create_netdata(Game_CMD.CMD_C_OccupySeat)
    cmddata:pushword(wchair)
    cmddata:pushbyte(index)
    self:SendData(Game_CMD.SUB_C_OCCUPYSEAT, cmddata)
end

--申请取消占位
function GameLayer:sendCancelOccupy(  )
    if nil ~= self._gameView.m_nSelfSitIdx then 
        local cmddata = CCmd_Data:create(0)
        self:SendData(Game_CMD.SUB_C_QUIT_OCCUPYSEAT, cmddata)
    end 
end

--申请取款
function GameLayer:sendTakeScore(lScore, szPassword )
    local cmddata = ExternalFun.create_netdata(GameServer_CMD.CMD_GR_C_TakeScoreRequest)
    cmddata:setcmdinfo(GameServer_CMD.MDM_GR_INSURE, GameServer_CMD.SUB_GR_TAKE_SCORE_REQUEST)
    cmddata:pushbyte(GameServer_CMD.SUB_GR_TAKE_SCORE_REQUEST)
    cmddata:pushscore(lScore)
    cmddata:pushstring(md5(szPassword),yl.LEN_PASSWORD)

    self:sendNetData(cmddata)
end

--请求银行信息
function GameLayer:sendRequestBankInfo()
    local cmddata = CCmd_Data:create(67)
    cmddata:setcmdinfo(GameServer_CMD.MDM_GR_INSURE,GameServer_CMD.SUB_GR_QUERY_INSURE_INFO)
    cmddata:pushbyte(GameServer_CMD.SUB_GR_QUERY_INSURE_INFO)
    cmddata:pushstring(md5(GlobalUserItem.szPassword),yl.LEN_PASSWORD)

    self:sendNetData(cmddata)
end


-----网络接收消息------
--场景消息
function GameLayer:onEventGameScene(cbGameStatus, dataBuffer)
	print("场景数据:"..cbGameStatus)
	if self.m_bOnGame == true then
		return
	end
	self.m_bOnGame = true

	if cbGameStatus == Game_CMD.GAME_SCENE_FREE then
		self:onGameSceneFree(dataBuffer)
	elseif cbGameStatus == Game_CMD.GAME_SCENE_JETTON or cbGameStatus == Game_CMD.GAME_SCENE_END then
		self:onGameScenePlaying(dataBuffer)
	end
	self:dismissPopWait()
end

function GameLayer:onGameSceneFree(dataBuffer)
	local cmd_table = ExternalFun.read_netdata(Game_CMD.CMD_S_StatusFree, dataBuffer)

	--游戏倒计时
	self:SetGameClock(self:GetMeChairID(), 1, cmd_table.cbTimeLeave)

	--从申请列表移除
	self._dataModle:removeApplyUser(cmd_table.wBankerUser)

	self._gameView:onGameSceneFree(cmd_table)
end

function GameLayer:onGameScenePlaying(dataBuffer)
	local cmd_table = ExternalFun.read_netdata(Game_CMD.CMD_S_StatusPlay, dataBuffer)

	--从申请列表移除
	self._dataModle:removeApplyUser(cmd_table.wBankerUser)

	self._gameView:onGameScenePlaying(cmd_table)

end

--游戏消息
function GameLayer:onEventGameMessage(sub, dataBuffer)
	if sub == Game_CMD.SUB_S_GAME_FREE then
		self:onGameMessageFree(dataBuffer)
	elseif sub == Game_CMD.SUB_S_GAME_START then
		self:onGameMessageStart(dataBuffer)
	elseif sub == Game_CMD.SUB_S_GAME_END then
		self:onGameMessageEnd(dataBuffer)
	elseif sub == Game_CMD.SUB_S_PLACE_JETTON then
		self:onGameMessagePlaceJetton(dataBuffer)
	elseif sub == Game_CMD.SUB_S_APPLY_BANKER then
		self:onGameMessageApplyBanker(dataBuffer)
	elseif sub == Game_CMD.SUB_S_CHANGE_BANKER then
		self:onGameMessageChageBanker(dataBuffer)
	elseif sub == Game_CMD.SUB_S_CANCEL_BANKER then
		self:onGameMessageCancelBanker(dataBuffer)
	elseif sub == Game_CMD.SUB_S_CHANGE_USER_SCORE then
		self:onGameMessageChangeUserScore(dataBuffer)
	elseif sub == Game_CMD.SUB_S_SEND_RECORD then
		self:onGameMessageSendRecord(dataBuffer)
	elseif sub == Game_CMD.SUB_S_PLACE_JETTON_FAIL then
		self:onGameMessagePlaceJettonFail(dataBuffer)
	elseif sub == Game_CMD.SUB_S_ADVANCE_OPENCARD then
		self:onGameMessageAdvanceOpenCard(dataBuffer)
	elseif sub == Game_CMD.SUB_S_SUPERROB_BANKER then
		self:onGameMessageSuperrobBanker(dataBuffer)
	elseif sub == Game_CMD.SUB_S_CURSUPERROB_LEAVE then
		self:onGameMessageSuperrobLeave(dataBuffer)
	elseif sub == Game_CMD.SUB_S_OCCUPYSEAT then
		self:onGameMessageOccupySeat(dataBuffer)
	elseif sub == Game_CMD.SUB_S_OCCUPYSEAT_FAIL then
		self:onGameMessageOccupySeatFail(dataBuffer)
	elseif sub == Game_CMD.SUB_S_UPDATE_OCCUPYSEAT then
		self:onGameMessageUpdateOccupySeat(dataBuffer)
	end
end

--游戏空闲
function GameLayer:onGameMessageFree(dataBuffer)
	local cmd_table = ExternalFun.read_netdata(Game_CMD.CMD_S_GameFree, dataBuffer)

	self._gameView:onGameFree(cmd_table)
	--游戏倒计时
	self:SetGameClock(self:GetMeChairID(), 1, cmd_table.cbTimeLeave)
end

--游戏开始下注
function GameLayer:onGameMessageStart(dataBuffer)
	local cmd_table = ExternalFun.read_netdata(Game_CMD.CMD_S_GameStart, dataBuffer)

	--游戏倒计时
	self._gameView:onGameStart(cmd_table)

	self:SetGameClock(self:GetMeChairID(), 1, cmd_table.cbTimeLeave)
end

--游戏结束
function GameLayer:onGameMessageEnd(dataBuffer)
	local cmd_table = ExternalFun.read_netdata(Game_CMD.CMD_S_GameEnd, dataBuffer)

	self._gameView:onGameEnd(cmd_table)

	self._gameView.m_cbTimeLeave = cmd_table.cbTimeLeave
	--游戏倒计时
	self:SetGameClock(self:GetMeChairID()+1, 1, cmd_table.cbTimeLeave)
end

--用户下注
function GameLayer:onGameMessagePlaceJetton(dataBuffer)
	local cmd_table = ExternalFun.read_netdata(Game_CMD.CMD_S_PlaceJetton, dataBuffer)

	self._gameView:onPlaceJetton(cmd_table)
end

--申请上庄
function GameLayer:onGameMessageApplyBanker(dataBuffer)
	local cmd_table = ExternalFun.read_netdata(Game_CMD.CMD_S_ApplyBanker,dataBuffer)

    self._dataModle:addApplyUser(cmd_table.wApplyUser, false) 

    self._gameView:onApplyBanker(cmd_table)
end

--切换庄家
function GameLayer:onGameMessageChageBanker(dataBuffer)
	local cmd_table = ExternalFun.read_netdata(Game_CMD.CMD_S_ChangeBanker,dataBuffer)
  
    --从申请列表移除
    self._dataModle:removeApplyUser(cmd_table.wBankerUser)

    self._gameView:onChangeBanker(cmd_table)

    --申请列表更新
    self._gameView:refreshApplyList()

    --刷新申请按钮状态
    self._gameView:refreshCondition()
end

--取消上庄申请
function GameLayer:onGameMessageCancelBanker(dataBuffer)
	local cmd_table = ExternalFun.read_netdata(Game_CMD.CMD_S_CancelBanker, dataBuffer)

    if cmd_table.wCancelUser == self._gameView.m_wCurrentRobApply then
        self._gameView.m_wCurrentRobApply = yl.INVALID_CHAIR
    end
    --从申请列表移除
    self._dataModle:removeApplyUser(cmd_table.wCancelUser)

    self._gameView:onGetCancelBanker(cmd_table)
end

--更新用户分数
function GameLayer:onGameMessageChangeUserScore(dataBuffer)
	--此消息不会来，应该是被废弃了
	local cmd_table = ExternalFun.read_netdata(Game_CMD.CMD_S_ChangeUserScore, dataBuffer)
	print("更新用户分数", cmd_table.lScore, cmd_table.lCurrentBankerScore)
end

--游戏记录
function GameLayer:onGameMessageSendRecord(dataBuffer)
	local len = dataBuffer:getlen()
	local recordcount = math.floor(len/Game_CMD.RECORD_LEN)
	self._dataModle:clearRecord()

	print("游戏记录数目", recordcount)
	for i=1,recordcount do
		if nil == dataBuffer then
			break
		end
		local rec = Game_CMD.getEmptyGameRecord()
		rec.bWinTianMen = dataBuffer:readbool()
		rec.bWinDiMen = dataBuffer:readbool()
		rec.bWinXuanMen = dataBuffer:readbool()
		rec.bWinHuangMen = dataBuffer:readbool()
		self._dataModle:addGameRecord(rec)
	end

	self._gameView:refreshGameRecord()
end

--下注失败
function GameLayer:onGameMessagePlaceJettonFail(dataBuffer)
	local cmd_table = ExternalFun.read_netdata(Game_CMD.CMD_S_PlaceJettonFail, dataBuffer)

	self._gameView:onPlaceJettonFail(cmd_table)
end

--提前开牌
function GameLayer:onGameMessageAdvanceOpenCard(dataBuffer)
	self._gameView:onAdvanceOpenCard()
end

--超级抢庄
function GameLayer:onGameMessageSuperrobBanker(dataBuffer)
	local cmd_table = ExternalFun.read_netdata(Game_CMD.CMD_S_SuperRobBanker, dataBuffer)
    if true == cmd_table.bSucceed then
		local rob = cmd_table.wApplySuperRobUser
        local cur = cmd_table.wCurSuperRobBankerUser

        self._gameView.m_wCurrentRobApply = rob
        
        --更新超级抢庄列表
        self._dataModle:updateSupperRobBanker(rob, cur)
        --界面通知
        self._gameView:onGetSupperRobApply()

        --申请列表更新
        self._gameView:refreshApplyList()
    end
end

--超级抢庄玩家离开
function GameLayer:onGameMessageSuperrobLeave(dataBuffer)
	local leaveUser = dataBuffer:readword()

    self._gameView.m_wCurrentRobApply = yl.INVALID_CHAIR
    --从申请列表移除
    self._dataModle:removeApplyUser(leaveUser)
    --刷新申请调整
    self._gameView:refreshCondition()
    --
    self._gameView:onGetSupperRobLeave(leaveUser)

    --申请列表更新
    self._gameView:refreshApplyList()
end

--占位
function GameLayer:onGameMessageOccupySeat( dataBuffer )
    local cmd_table = ExternalFun.read_netdata(Game_CMD.CMD_S_OccupySeat, dataBuffer)

    local wchair = cmd_table.wOccupySeatChairID
    local index = cmd_table.cbOccupySeatIndex
    self._gameView:onGetSitDown(index, wchair, true)
end

--占位失败
function GameLayer:onGameMessageOccupySeatFail( dataBuffer )
    local cmd_table = ExternalFun.read_netdata(Game_CMD.CMD_S_OccupySeat_Fail, dataBuffer) 

    local wchair = cmd_table.wAlreadyOccupySeatChairID
    local index = cmd_table.cbAlreadyOccupySeatIndex
    self._gameView:onGetSitDownLeave(index)
end

--更新占位
function GameLayer:onGameMessageUpdateOccupySeat( dataBuffer )
    local cmd_table = ExternalFun.read_netdata(Game_CMD.CMD_S_UpdateOccupySeat, dataBuffer)

    for i = 1, Game_CMD.MAX_OCCUPY_SEAT_COUNT do
        if cmd_table.tabWOccupySeatChairID[1][i] == yl.INVALID_CHAIR then
            self._gameView:onGetSitDownLeave(i - 1)
        end
    end
end

--银行消息
function GameLayer:onSocketInsureEvent( sub,dataBuffer )
    self:dismissPopWait()
    if sub == GameServer_CMD.SUB_GR_USER_INSURE_SUCCESS then
        local cmd_table = ExternalFun.read_netdata(GameServer_CMD.CMD_GR_S_UserInsureSuccess, dataBuffer)
        self.bank_success = cmd_table

        self._gameView:onBankSuccess()
    elseif sub == GameServer_CMD.SUB_GR_USER_INSURE_FAILURE then
        local cmd_table = ExternalFun.read_netdata(GameServer_CMD.CMD_GR_S_UserInsureFailure, dataBuffer)
        self.bank_fail = cmd_table

        self._gameView:onBankFailure()
    elseif sub == GameServer_CMD.SUB_GR_USER_INSURE_INFO then --银行资料
        local cmdtable = ExternalFun.read_netdata(GameServer_CMD.CMD_GR_S_UserInsureInfo, dataBuffer)
        dump(cmdtable, "cmdtable", 6)

        self._gameView:onGetBankInfo(cmdtable)
    else
        print("unknow gamemessage sub is ==>"..sub)
    end
end

--

----------用户消息
--用户进入
function GameLayer:onEventUserEnter(wTableID, wChairID, useritem)
	--缓存用户
	self._dataModle:addUser(useritem)
	self._gameView:refreshUserList()
	self._gameView:onGetUserScore(useritem)
end

--用户状态
function GameLayer:onEventUserStatus(useritem, newstatus, oldstatus)
	if newstatus == yl.US_FREE or newstatus == yl.US_NULL then
		self._dataModle:removeUser(useritem)
	else
		self._dataModle:updateUser(useritem)
	end
	self._gameView:refreshUserList()
end

--用户分数
function GameLayer:onEventUserScore(useritem)
	self._dataModle:updateUser(useritem)

	self._gameView:onGetUserScore(useritem)

	self._gameView:refreshUserList()
end

return GameLayer