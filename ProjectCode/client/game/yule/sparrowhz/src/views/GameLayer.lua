local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")

local GameLayer = class("GameLayer", GameModel)

local cmd = appdf.req(appdf.GAME_SRC.."yule.sparrowhz.src.models.CMD_Game")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.sparrowhz.src.models.GameLogic")
local GameViewLayer = appdf.req(appdf.GAME_SRC.."yule.sparrowhz.src.views.layer.GameViewLayer")
local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

function GameLayer:ctor(frameEngine, scene)
    GameLayer.super.ctor(self, frameEngine, scene)
end

function GameLayer:CreateView()
    return GameViewLayer:create(self):addTo(self)
end

function GameLayer:OnInitGameEngine()
	self.lCellScore = 0
	self.cbTimeOutCard = 0
	self.cbTimeOperateCard = 0
	self.cbTimeStartGame = 0
	self.wCurrentUser = yl.INVALID_CHAIR
	self.wBankerUser = yl.INVALID_CHAIR
	self.cbPlayStatus = {0, 0, 0, 0}
	self.cbGender = {0, 0, 0, 0}
	self.bTrustee = false
	self.nGameSceneLimit = 0
	self.cbAppearCardData = {} 		--已出现的牌
	self.bMoPaiStatus = false
	self.cbListenPromptOutCard = {}
	self.cbListenCardList = {}
	self.cbActionMask = nil
	self.bSendCardFinsh = false
	self.cbPlayerCount = 4
	self.lDetailScore = {}
	self.m_userRecord = {}
	self.cbMaCount = 0
	--房卡需要
	self.wRoomHostViewId = 0
	print("Hello Hello!")
end

function GameLayer:OnResetGameEngine()
    GameLayer.super.OnResetGameEngine(self)
    self._gameView:onResetData()
	self.nGameSceneLimit = 0
	self.bTrustee = false
	self.cbAppearCardData = {} 		--已出现的牌
	self.bMoPaiStatus = false
	self.cbActionMask = nil
end

--获取gamekind
function GameLayer:getGameKind()
    return cmd.KIND_ID
end

function GameLayer:onExitRoom()
    self._gameFrame:onCloseSocket()
    self:stopAllActions()
    self:KillGameClock()
    self:dismissPopWait()
    --self._scene:onChangeShowMode(yl.SCENE_ROOMLIST)
    self._scene:onKeyBack()
end

-- 椅子号转视图位置,注意椅子号从0~nChairCount-1,返回的视图位置从1~nChairCount
function GameLayer:SwitchViewChairID(chair)
    local viewid = yl.INVALID_CHAIR
    local nChairCount = self._gameFrame:GetChairCount()
    nChairCount = cmd.GAME_PLAYER
    local nChairID = self:GetMeChairID()
    if chair ~= yl.INVALID_CHAIR and chair < nChairCount then
        viewid = math.mod(chair + math.floor(nChairCount * 3/2) - nChairID, nChairCount) + 1
    end
    return viewid
end

function GameLayer:getRoomHostViewId()
	return self.wRoomHostViewId
end

function GameLayer:getUserInfoByChairID(chairId)
	local viewId = self:SwitchViewChairID(chairId)
	return self._gameView.m_sparrowUserItem[viewId]
end

function GameLayer:getMaCount()
	print("返回码数", self.cbMaCount)
	return self.cbMaCount
end

function GameLayer:onGetSitUserNum()
	local num = 0
	for i = 1, cmd.GAME_PLAYER do
		if nil ~= self._gameView.m_sparrowUserItem[i] then
			num = num + 1
		end
	end

    return num
end

function GameLayer:onEnterTransitionFinish()
    self._scene:createVoiceBtn(cc.p(1250, 300))
    GameLayer.super.onEnterTransitionFinish(self)
end

-- 计时器响应
function GameLayer:OnEventGameClockInfo(chair,time,clockId)
    -- body
    if GlobalUserItem.bPrivateRoom then
    	return
    end
    local meChairId = self:GetMeChairID()
    if clockId == cmd.IDI_START_GAME then
    	--托管
    	if self.bTrustee and self._gameView.btStart:isVisible() then
   --  		print("进去")
   --  		self._gameView:onButtonClickedEvent(GameViewLayer.BT_START)
   --  		--托管在上个函数被复原了，在下面重开
			-- self.bTrustee = true
			-- self._gameView.nodePlayer[cmd.MY_VIEWID]:getChildByTag(GameViewLayer.SP_TRUSTEE):setVisible(true)
			-- self._gameView.spTrusteeCover:setVisible(true)
    	end
    	--超时
		if time <= 0 then
			self._gameFrame:setEnterAntiCheatRoom(false)--退出防作弊，如果有的话
			--self:onExitTable()
		elseif time <= 5 then
    		self:PlaySound(cmd.RES_PATH.."sound/GAME_WARN.wav")
		end
    elseif clockId == cmd.IDI_OUT_CARD then
    	if chair == meChairId then
    		--托管
    		if self.bTrustee then
				--self._gameView._cardLayer:outCardAuto()
    		end
    		--超时
    		if time <= 0 then
				self._gameView._cardLayer:outCardAuto()
    		elseif time <= 5 then
    			self:PlaySound(cmd.RES_PATH.."sound/GAME_WARN.wav")
    		end
    	end
    elseif clockId == cmd.IDI_OPERATE_CARD then
    	if chair == meChairId then
    		--托管
    		if self.bTrustee then
    -- 			if self._gameView._cardLayer:isUserMustWin() then
				-- 	self._gameView:onButtonClickedEvent(GameViewLayer.BT_WIN)
    -- 			end
				-- self._gameView:onButtonClickedEvent(GameViewLayer.BT_PASS)
				-- self._gameView._cardLayer:outCardAuto()
    		end
    		--超时
    		if time <= 0 then
    			if self._gameView._cardLayer:isUserMustWin() then
					self._gameView:onButtonClickedEvent(GameViewLayer.BT_WIN)
    			end
				self._gameView:onButtonClickedEvent(GameViewLayer.BT_PASS)
				self._gameView._cardLayer:outCardAuto()
    		elseif time <= 5 then
    			self:PlaySound(cmd.RES_PATH.."sound/GAME_WARN.wav")
    		end
    	end
    end
end

--用户聊天
function GameLayer:onUserChat(chat, wChairId)
    self._gameView:userChat(self:SwitchViewChairID(wChairId), chat.szChatString)
end

--用户表情
function GameLayer:onUserExpression(expression, wChairId)
    self._gameView:userExpression(self:SwitchViewChairID(wChairId), expression.wItemIndex)
end

-- 语音播放开始
function GameLayer:onUserVoiceStart( useritem, filepath )
    self._gameView:onUserVoiceStart(self:SwitchViewChairID(useritem.wChairID))
end

-- 语音播放结束
function GameLayer:onUserVoiceEnded( useritem, filepath )
    self._gameView:onUserVoiceEnded(self:SwitchViewChairID(useritem.wChairID))
end

-- 场景消息
function GameLayer:onEventGameScene(cbGameStatus, dataBuffer)
	self.m_cbGameStatus = cbGameStatus
	self.nGameSceneLimit = self.nGameSceneLimit + 1
	if self.nGameSceneLimit > 1 then
		--限制只进入场景消息一次
		return true
	end
	local wTableId = self:GetMeTableID()
	local wMyChairId = self:GetMeChairID()
	self._gameView:setRoomInfo(wTableId, wMyChairId)
	--初始化用户信息
	for i = 1, cmd.GAME_PLAYER do
		local wViewChairId = self:SwitchViewChairID(i - 1)
		local userItem = self._gameFrame:getTableUserItem(wTableId, i - 1)
		self._gameView:OnUpdateUser(wViewChairId, userItem)
		if userItem then
			self.cbGender[wViewChairId] = userItem.cbGender
			if PriRoom and GlobalUserItem.bPrivateRoom then
				if userItem.dwUserID == PriRoom:getInstance().m_tabPriData.dwTableOwnerUserID then
					self.wRoomHostViewId = wViewChairId
				end
			end
		end
	end

	if cbGameStatus == cmd.GAME_SCENE_FREE then
		print("空闲状态")
		local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_StatusFree, dataBuffer)
		--dump(cmd_data, "空闲状态")

		self.lCellScore = cmd_data.lCellScore
		self.cbTimeOutCard = cmd_data.cbTimeOutCard
		self.cbTimeOperateCard = cmd_data.cbTimeOperateCard
		self.cbTimeStartGame = cmd_data.cbTimeStartGame
		self.cbPlayerCount = cmd_data.cbPlayerCount or 4
		self.cbMaCount = cmd_data.cbMaCount
		print("设置码数", self.cbMaCount)
		
		self._gameView.btStart:setVisible(true)

		-- if GlobalUserItem.bPrivateRoom then
		-- 	--self._gameView.spClock:setVisible(false)
		-- 	self._gameView.asLabTime:setString("0")
		-- else
			self:SetGameClock(wMyChairId, cmd.IDI_START_GAME, self.cbTimeStartGame)
		--end

	elseif cbGameStatus == cmd.GAME_SCENE_PLAY then
		print("游戏状态")
		local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_StatusPlay, dataBuffer)
		--dump(cmd_data.cbHuCardData, "cbHuCardData")
		--dump(cmd_data.cbOutCardDataEx, "cbOutCardDataEx")

		self.lCellScore = cmd_data.lCellScore
		self.cbTimeOutCard = cmd_data.cbTimeOutCard
		self.cbTimeOperateCard = cmd_data.cbTimeOperateCard
		self.cbTimeStartGame = cmd_data.cbTimeStartGame
		self.wCurrentUser = cmd_data.wCurrentUser
		self.wBankerUser = cmd_data.wBankerUser
		self.cbPlayerCount = cmd_data.cbPlayerCount or 4
		self.cbMaCount = cmd_data.cbMaCount

		--庄家
		self._gameView:setBanker(self:SwitchViewChairID(self.wBankerUser))
		--设置手牌
		local viewCardCount = {}
		for i = 1, cmd.GAME_PLAYER do
			local viewId = self:SwitchViewChairID(i - 1)
			viewCardCount[viewId] = cmd_data.cbCardCount[1][i]
			if viewCardCount[viewId] > 0 then
				self.cbPlayStatus[viewId] = 1
			end
		end
		local cbHandCardData = {}
		for i = 1, cmd.MAX_COUNT do
			local data = cmd_data.cbCardData[1][i]
			if data > 0 then 				--去掉末尾的0
				cbHandCardData[i] = data
			else
				break
			end
		end
		GameLogic.SortCardList(cbHandCardData) 		--排序
		local cbSendCard = cmd_data.cbSendCardData
		if cbSendCard > 0 and self.wCurrentUser == wMyChairId then
			for i = 1, #cbHandCardData do
				if cbHandCardData[i] == cbSendCard then
					table.remove(cbHandCardData, i)				--把刚抓的牌放在最后
					break
				end
			end
			table.insert(cbHandCardData, cbSendCard)
		end
		for i = 1, cmd.GAME_PLAYER do
			self._gameView._cardLayer:setHandCard(i, viewCardCount[i], cbHandCardData)
		end
		self.bSendCardFinsh = true
		--记录已出现牌
		self:insertAppearCard(cbHandCardData)
		--组合牌
		for i = 1, cmd.GAME_PLAYER do
			local wViewChairId = self:SwitchViewChairID(i - 1)
			for j = 1, cmd_data.cbWeaveItemCount[1][i] do
				local cbOperateData = {}
				for v = 1, 4 do
					local data = cmd_data.WeaveItemArray[i][j].cbCardData[1][v]
					if data > 0 then
						table.insert(cbOperateData, data)
					end
				end
				local nShowStatus = GameLogic.SHOW_NULL
				local cbParam = cmd_data.WeaveItemArray[i][j].cbParam
				if cbParam == GameLogic.WIK_GANERAL then
					if cbOperateData[1] == cbOperateData[2] then 	--碰
						nShowStatus = GameLogic.SHOW_PENG
					else 											--吃
						nShowStatus = GameLogic.SHOW_CHI
					end
				elseif cbParam == GameLogic.WIK_MING_GANG then
					nShowStatus = GameLogic.SHOW_MING_GANG
				elseif cbParam == GameLogic.WIK_FANG_GANG then
					nShowStatus = GameLogic.SHOW_FANG_GANG
				elseif cbParam == GameLogic.WIK_AN_GANG then
					nShowStatus = GameLogic.SHOW_AN_GANG
				end
				--dump(cmd_data.WeaveItemArray[i][j], "weaveItem")
				self._gameView._cardLayer:bumpOrBridgeCard(wViewChairId, cbOperateData, nShowStatus)
				--记录已出现牌
				self:insertAppearCard(cbOperateData)
			end
		end
		--设置牌堆
		local wViewHeapHead = self:SwitchViewChairID(cmd_data.wHeapHead)
		local wViewHeapTail = self:SwitchViewChairID(cmd_data.wHeapTail)
		for i = 1, cmd.GAME_PLAYER do
			local viewId = self:SwitchViewChairID(i - 1)
			for j = 1, cmd_data.cbDiscardCount[1][i] do
				--已出的牌
				self._gameView._cardLayer:discard(viewId, cmd_data.cbDiscardCard[i][j])
				--记录已出现牌
				local cbAppearCard = {cmd_data.cbDiscardCard[i][j]}
				self:insertAppearCard(cbAppearCard)
			end
			--牌堆
			self._gameView._cardLayer:setTableCardByHeapInfo(viewId, cmd_data.cbHeapCardInfo[i], wViewHeapHead, wViewHeapTail)
			--托管
			self._gameView:setUserTrustee(viewId, cmd_data.bTrustee[1][i])
			if viewId == cmd.MY_VIEWID then
				self.bTrustee = cmd_data.bTrustee[1][i]
			end
		end
		--刚出的牌
		if cmd_data.cbOutCardData and cmd_data.cbOutCardData > 0 then
			local wOutUserViewId = self:SwitchViewChairID(cmd_data.wOutCardUser)
			self._gameView:showCardPlate(wOutUserViewId, cmd_data.cbOutCardData)
		end
		--计时器
		self:SetGameClock(self.wCurrentUser, cmd.IDI_OUT_CARD, self.cbTimeOutCard)

		--提示听牌数据
		self.cbListenPromptOutCard = {}
		self.cbListenCardList = {}
		for i = 1, cmd_data.cbOutCardCount do
			self.cbListenPromptOutCard[i] = cmd_data.cbOutCardDataEx[1][i]
			self.cbListenCardList[i] = {}
			for j = 1, cmd_data.cbHuCardCount[1][i] do
				self.cbListenCardList[i][j] = cmd_data.cbHuCardData[i][j]
			end
		end
		local cbPromptHuCard = self:getListenPromptHuCard(cmd_data.cbOutCardData)
		self._gameView:setListeningCard(cbPromptHuCard)
		--提示操作
		self._gameView:recognizecbActionMask(cmd_data.cbActionMask, cmd_data.cbActionCard)
		if self.wCurrentUser == wMyChairId then
			self._gameView._cardLayer:promptListenOutCard(self.cbListenPromptOutCard)
		end
	else
		print("\ndefault\n")
		return false
	end

    -- 刷新房卡
    if PriRoom and GlobalUserItem.bPrivateRoom then
        if nil ~= self._gameView._priView and nil ~= self._gameView._priView.onRefreshInfo then
            self._gameView._priView:onRefreshInfo()
        end
    end

	self:dismissPopWait()

	return true
end

-- 游戏消息
function GameLayer:onEventGameMessage(sub, dataBuffer)
    -- body
	if sub == cmd.SUB_S_GAME_START then 					--游戏开始
		return self:onSubGameStart(dataBuffer)
	elseif sub == cmd.SUB_S_OUT_CARD then 					--用户出牌
		return self:onSubOutCard(dataBuffer)
	elseif sub == cmd.SUB_S_SEND_CARD then 					--发送扑克
		return self:onSubSendCard(dataBuffer)
	elseif sub == cmd.SUB_S_OPERATE_NOTIFY then 			--操作提示
		return self:onSubOperateNotify(dataBuffer)
	elseif sub == cmd.SUB_S_HU_CARD then 					--听牌提示
		return self:onSubListenNotify(dataBuffer)
	elseif sub == cmd.SUB_S_OPERATE_RESULT then 			--操作命令
		return self:onSubOperateResult(dataBuffer)
	elseif sub == cmd.SUB_S_LISTEN_CARD then 				--用户听牌
		return self:onSubListenCard(dataBuffer)
	elseif sub == cmd.SUB_S_TRUSTEE then 					--用户托管
		return self:onSubTrustee(dataBuffer)
	elseif sub == cmd.SUB_S_GAME_CONCLUDE then 				--游戏结束
		return self:onSubGameConclude(dataBuffer)
	elseif sub == cmd.SUB_S_RECORD then 					--游戏记录
		return self:onSubGameRecord(dataBuffer)
	elseif sub == cmd.SUB_S_SET_BASESCORE then 				--设置基数
		self.lCellScore = dataBuffer:readint()
		return true
	else
		assert(false, "default")
	end

	return false
end

--游戏开始
function GameLayer:onSubGameStart(dataBuffer)
	print("游戏开始")
    self.m_cbGameStatus = cmd.GAME_SCENE_PLAY
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_GameStart, dataBuffer)
	--dump(cmd_data, "CMD_S_GameStart")
	for i = 1, cmd.GAME_PLAYER do
		local viewId = self:SwitchViewChairID(i - 1)
		local head = cmd_data.cbHeapCardInfo[i][1]
		local tail = cmd_data.cbHeapCardInfo[i][2]
	end

	self.wBankerUser = cmd_data.wBankerUser
	local wViewBankerUser = self:SwitchViewChairID(self.wBankerUser)
	self._gameView:setBanker(wViewBankerUser)
	local cbCardCount = {0, 0, 0, 0}
	for i = 1, cmd.GAME_PLAYER do
		local userItem = self._gameFrame:getTableUserItem(self:GetMeTableID(), i - 1)
		local wViewChairId = self:SwitchViewChairID(i - 1)
		self._gameView:OnUpdateUser(wViewChairId, userItem)
		if userItem then
			self.cbPlayStatus[wViewChairId] = 1
			cbCardCount[wViewChairId] = 13
			if wViewChairId == wViewBankerUser then
				cbCardCount[wViewChairId] = cbCardCount[wViewChairId] + 1
			end
		end
	end

	if self.wBankerUser ~= self:GetMeChairID() then
		cmd_data.cbCardData[1][cmd.MAX_COUNT] = nil
	end
	
	--筛子
	local cbSiceCount1 = math.mod(cmd_data.wSiceCount, 256)
	local cbSiceCount2 = math.floor(cmd_data.wSiceCount/256)
	--起始位置
	local wStartChairId = math.mod(self.wBankerUser + cbSiceCount1 + cbSiceCount2 - 1, cmd.GAME_PLAYER)
	local wStartViewId = self:SwitchViewChairID(wStartChairId)
	--起始位置数的起始牌
	local nStartCard = math.min(cbSiceCount1, cbSiceCount2)*2 + 1
	--开始发牌
	self._gameView:gameStart(wStartViewId, nStartCard, cmd_data.cbCardData[1], cbCardCount, cbSiceCount1, cbSiceCount2)

	--记录已出现的牌
	self:insertAppearCard(cmd_data.cbCardData[1])

	self.wCurrentUser = cmd_data.wBankerUser
	self.cbActionMask = cmd_data.cbUserAction
	self.bMoPaiStatus = true
	self.bSendCardFinsh = false
	self:PlaySound(cmd.RES_PATH.."sound/GAME_START.wav")
	-- 刷新房卡
    if PriRoom and GlobalUserItem.bPrivateRoom then
        if nil ~= self._gameView._priView and nil ~= self._gameView._priView.onRefreshInfo then
        	PriRoom:getInstance().m_tabPriData.dwPlayCount = PriRoom:getInstance().m_tabPriData.dwPlayCount + 1
            self._gameView._priView:onRefreshInfo()
        end
    end

    --计时器
	self:SetGameClock(self.wCurrentUser, cmd.IDI_OUT_CARD, self.cbTimeOutCard)
	return true
end

--用户出牌
function GameLayer:onSubOutCard(dataBuffer)
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_OutCard, dataBuffer)
	--dump(cmd_data, "CMD_S_OutCard")
	print("用户出牌", cmd_data.cbOutCardData)

	local wViewId = self:SwitchViewChairID(cmd_data.wOutCardUser)
	self._gameView:gameOutCard(wViewId, cmd_data.cbOutCardData)

	--记录已出现的牌
	if wViewId ~= cmd.MY_VIEWID then
		local cbAppearCard = {cmd_data.cbOutCardData}
		self:insertAppearCard(cbAppearCard)
	end

	self.bMoPaiStatus = false
	self:KillGameClock()
	self._gameView:HideGameBtn()
	self:PlaySound(cmd.RES_PATH.."sound/OUT_CARD.wav")
	self:playCardDataSound(wViewId, cmd_data.cbOutCardData)
	--轮到下一个
	self.wCurrentUser = cmd_data.wOutCardUser
	local wTurnUser = self.wCurrentUser + 1
	local wViewTurnUser = self:SwitchViewChairID(wTurnUser)
	while self.cbPlayStatus[wViewTurnUser] ~= 1 do
		wTurnUser = wTurnUser + 1
		if wTurnUser > 3 then
			wTurnUser = 0
		end
		wViewTurnUser = self:SwitchViewChairID(wTurnUser)
	end
	--设置听牌
	self._gameView._cardLayer:promptListenOutCard(nil)
	if wViewId == cmd.MY_VIEWID then
		local cbPromptHuCard = self:getListenPromptHuCard(cmd_data.cbOutCardData)
		self._gameView:setListeningCard(cbPromptHuCard)
		--听牌数据置空
		self.cbListenPromptOutCard = {}
		self.cbListenCardList = {}
	end
	--设置时间
	self:SetGameClock(wTurnUser, cmd.IDI_OUT_CARD, self.cbTimeOutCard)
	return true
end

--发送扑克(抓牌)
function GameLayer:onSubSendCard(dataBuffer)
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_SendCard, dataBuffer)
	--dump(cmd_data, "CMD_S_SendCard")
	print("发送扑克", cmd_data.cbCardData)

	self.wCurrentUser = cmd_data.wCurrentUser
	local wCurrentViewId = self:SwitchViewChairID(self.wCurrentUser)
	self._gameView:gameSendCard(wCurrentViewId, cmd_data.cbCardData, cmd_data.bTail)

	self:SetGameClock(self.wCurrentUser, cmd.IDI_OUT_CARD, self.cbTimeOutCard)

	self._gameView:HideGameBtn()
	if self.wCurrentUser == self:GetMeChairID()  then
		self._gameView:recognizecbActionMask(cmd_data.cbActionMask, cmd_data.cbCardData)
		--自动胡牌
		if cmd_data.cbActionMask >= GameLogic.WIK_CHI_HU and self.bTrustee then
			self._gameView:onButtonClickedEvent(GameViewLayer.BT_WIN)
		end
	end

	--记录已出现的牌
	if wCurrentViewId == cmd.MY_VIEWID then
		local cbAppearCard = {cmd_data.cbCardData}
		self:insertAppearCard(cbAppearCard)
	end

	self.bMoPaiStatus = true
	self:PlaySound(cmd.RES_PATH.."sound/SEND_CARD.wav")
	if cmd_data.bTail then
		self:playCardOperateSound(wOperateViewId, true, nil)
	end
	return true
end

--操作提示
function GameLayer:onSubOperateNotify(dataBuffer)
	print("操作提示")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_OperateNotify, dataBuffer)
	--dump(cmd_data, "CMD_S_OperateNotify")

	if self.bSendCardFinsh then 	--发牌完成
		self._gameView:recognizecbActionMask(cmd_data.cbActionMask, cmd_data.cbActionCard)
	else
		self.cbActionMask = cmd_data.cbActionMask
		self.cbActionCard = cmd_data.cbActionCard
	end
	return true
end

--听牌提示
function GameLayer:onSubListenNotify(dataBuffer)
	print("听牌提示")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_Hu_Data, dataBuffer)
	--dump(cmd_data, "CMD_S_Hu_Data")

	self.cbListenPromptOutCard = {}
	self.cbListenCardList = {}
	for i = 1, cmd_data.cbOutCardCount do
		self.cbListenPromptOutCard[i] = cmd_data.cbOutCardData[1][i]
		self.cbListenCardList[i] = {}
		for j = 1, cmd_data.cbHuCardCount[1][i] do
			self.cbListenCardList[i][j] = cmd_data.cbHuCardData[i][j]
		end
		print("self.cbListenCardList"..i, table.concat(self.cbListenCardList[i], ","))
	end
	print("self.cbListenPromptOutCard", table.concat(self.cbListenPromptOutCard, ","))

	return true
end

--操作结果
function GameLayer:onSubOperateResult(dataBuffer)
	print("操作结果")

	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_OperateResult, dataBuffer)
	--dump(cmd_data, "CMD_S_OperateResult")
	if cmd_data.cbOperateCode == GameLogic.WIK_NULL then
		assert(false, "没有操作也会进来？")
		return true
	end

	local wOperateViewId = self:SwitchViewChairID(cmd_data.wOperateUser)
	if cmd_data.cbOperateCode < GameLogic.WIK_LISTEN then 		--并非听牌
		local nShowStatus = GameLogic.SHOW_NULL
		local data1 = cmd_data.cbOperateCard[1][1]
		local data2 = cmd_data.cbOperateCard[1][2]
		local data3 = cmd_data.cbOperateCard[1][3]
		local cbOperateData = {}
		local cbRemoveData = {}
		if cmd_data.cbOperateCode == GameLogic.WIK_GANG then
			cbOperateData = {data1, data1, data1, data1}
			cbRemoveData = {data1, data1, data1}
			--检查杠的类型
			local cbCardCount = self._gameView._cardLayer.cbCardCount[wOperateViewId]
			if math.mod(cbCardCount - 2, 3) == 0 then
				if self._gameView._cardLayer:checkBumpOrBridgeCard(wOperateViewId, data1) then
					nShowStatus = GameLogic.SHOW_MING_GANG
				else
					nShowStatus = GameLogic.SHOW_AN_GANG
				end
			else
				nShowStatus = GameLogic.SHOW_FANG_GANG
			end
		elseif cmd_data.cbOperateCode == GameLogic.WIK_PENG then
			cbOperateData = {data1, data1, data1}
			cbRemoveData = {data1, data1}
			nShowStatus = GameLogic.SHOW_PENG
		elseif cmd_data.cbOperateCode == GameLogic.WIK_RIGHT then
			cbOperateData = cmd_data.cbOperateCard[1]
			cbRemoveData = {data1, data2}
			nShowStatus = GameLogic.SHOW_CHI
		elseif cmd_data.cbOperateCode == GameLogic.WIK_CENTER then
			cbOperateData = cmd_data.cbOperateCard[1]
			cbRemoveData = {data1, data3}
			nShowStatus = GameLogic.SHOW_CHI
		elseif cmd_data.cbOperateCode == GameLogic.WIK_LEFT then
			cbOperateData = cmd_data.cbOperateCard[1]
			cbRemoveData = {data2, data3}
			nShowStatus = GameLogic.SHOW_CHI
		end
		local bAnGang = nShowStatus == GameLogic.SHOW_AN_GANG
		self._gameView._cardLayer:bumpOrBridgeCard(wOperateViewId, cbOperateData, nShowStatus)
		local bRemoveSuccess = false
		if nShowStatus == GameLogic.SHOW_AN_GANG then
			self._gameView._cardLayer:removeHandCard(wOperateViewId, cbOperateData, false)
		elseif nShowStatus == GameLogic.SHOW_MING_GANG then
			self._gameView._cardLayer:removeHandCard(wOperateViewId, {data1}, false)
		else
			self._gameView._cardLayer:removeHandCard(wOperateViewId, cbRemoveData, false)
			--self._gameView._cardLayer:recycleDiscard(self:SwitchViewChairID(cmd_data.wProvideUser))
			print("提供者不正常？", cmd_data.wProvideUser, self:GetMeChairID())
		end
		self:PlaySound(cmd.RES_PATH.."sound/PACK_CARD.wav")
		self:playCardOperateSound(wOperateViewId, false, cmd_data.cbOperateCode)

		--记录已出现的牌
		if wOperateViewId ~= cmd.MY_VIEWID then
			if nShowStatus == GameLogic.SHOW_AN_GANG then
				self:insertAppearCard(cbOperateData)
			elseif nShowStatus == GameLogic.SHOW_MING_GANG then
				self:insertAppearCard({data1})
			else
				self:insertAppearCard(cbRemoveData)
			end
		end
		--提示听牌
		if wOperateViewId == cmd.MY_VIEWID and cmd_data.cbOperateCode == GameLogic.WIK_PENG then
			self._gameView._cardLayer:promptListenOutCard(self.cbListenPromptOutCard)
		end
	end
	self._gameView:showOperateFlag(wOperateViewId, cmd_data.cbOperateCode)

	local cbTime = self.cbTimeOutCard - self.cbTimeOperateCard
	self:SetGameClock(cmd_data.wOperateUser, cmd.IDI_OUT_CARD, cbTime > 0 and cbTime or self.cbTimeOutCard)

	return true
end

--用户听牌
function GameLayer:onSubListenCard(dataBuffer)
	--print("用户听牌")
	--local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_ListenCard, dataBuffer)
	--dump(cmd_data, "CMD_S_ListenCard")
	return true
end

--用户托管
function GameLayer:onSubTrustee(dataBuffer)
	print("用户托管")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_Trustee, dataBuffer)
	--dump(cmd_data, "trustee")

	local wViewChairId = self:SwitchViewChairID(cmd_data.wChairID)
	self._gameView:setUserTrustee(wViewChairId, cmd_data.bTrustee)
	if cmd_data.wChairID == self:GetMeChairID() then
		self.bTrustee = cmd_data.bTrustee
	end

	if cmd_data.bTrustee then
		self:PlaySound(cmd.RES_PATH.."sound/GAME_TRUSTEE.wav")
	else
		self:PlaySound(cmd.RES_PATH.."sound/UNTRUSTEE.wav")
	end

	return true
end

--游戏结束
function GameLayer:onSubGameConclude(dataBuffer)
	print("游戏结束")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_GameConclude, dataBuffer)
	--dump(cmd_data, "CMD_S_GameConclude")

	local bMeWin = nil  	--nil：没人赢，false：有人赢但我没赢，true：我赢
	--剩余牌
	local cbTotalCardData = clone(GameLogic.TotalCardData)
	local cbRemainCard = GameLogic.RemoveCard(cbTotalCardData, self.cbAppearCardData)
	--提示胡牌标记
	for i = 1, cmd.GAME_PLAYER do
		local wViewChairId = self:SwitchViewChairID(i - 1)
		if cmd_data.cbChiHuKind[1][i] >= GameLogic.WIK_CHI_HU then
			bMeWin = false
			self:playCardOperateSound(wOperateViewId, false, GameLogic.WIK_CHI_HU)
			self._gameView:showOperateFlag(wViewChairId, GameLogic.WIK_CHI_HU)
			if wViewChairId == cmd.MY_VIEWID then
				bMeWin = true
			end
		end
	end
	--显示结算图层
	local resultList = {}
	local cbBpBgData = self._gameView._cardLayer:getBpBgCardData()
	for i = 1, cmd.GAME_PLAYER do
		local wViewChairId = self:SwitchViewChairID(i - 1)
		local lScore = cmd_data.lGameScore[1][i]
		local user = self._gameFrame:getTableUserItem(self:GetMeTableID(), i - 1)
		if user then
			local result = {}
			result.userItem = user
			result.lScore = lScore
			result.cbChHuKind = cmd_data.cbChiHuKind[1][i]
			result.cbCardData = {}
			--手牌
			for j = 1, cmd_data.cbCardCount[1][i] do
				result.cbCardData[j] = cmd_data.cbHandCardData[i][j]
			end
			--碰杠牌
			result.cbBpBgCardData = cbBpBgData[wViewChairId]
			--奖码
			result.cbAwardCard = {}
			for j = 1, cmd_data.cbMaCount[1][i] do
				result.cbAwardCard[j] = cmd_data.cbMaData[1][j]
			end
			--插入
			table.insert(resultList, result)
			--剩余牌里删掉对手的牌
			if wViewChairId ~= cmd.MY_VIEWID then
				cbRemainCard = GameLogic.RemoveCard(cbRemainCard, result.cbCardData)
			end
		end
	end
	--全部奖码
	local meIndex = self:GetMeChairID() + 1
	local cbAwardCardTotal = {}
	for i = 1, 7 do
		local value = cmd_data.cbMaData[1][i]
		if value and value > 0 then
			table.insert(cbAwardCardTotal, value)
		end
	end
	--删掉奖码
	cbRemainCard = GameLogic.RemoveCard(cbRemainCard, cbAwardCardTotal)
	if bMeWin == false then 			--有人赢但赢的人不是我
		cbRemainCard = GameLogic.RemoveCard(cbRemainCard, {cmd_data.cbProvideCard})
	end
	--打散剩余牌
	cbRemainCard = GameLogic.RandCardList(cbRemainCard)
	--在首位插入奖码（将奖码伪装成剩余牌）
	for i = 1, #cbAwardCardTotal do
		table.insert(cbRemainCard, i, cbAwardCardTotal[i])
	end
	print("通过已显示牌统计，剩余多少张？", #cbRemainCard)
	--显示结算框
	self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function(ref)
		self._gameView._resultLayer:showLayer(resultList, cbAwardCardTotal, cbRemainCard, self.wBankerUser, cmd_data.cbProvideCard)
	end)))
	--播放音效
	if bMeWin then
		self:PlaySound(cmd.RES_PATH.."sound/ZIMO_WIN.wav")
	else
		self:PlaySound(cmd.RES_PATH.."sound/ZIMO_LOSE.wav")
	end

	self.cbPlayStatus = {0, 0, 0, 0}
    self.bTrustee = false
    self.bSendCardFinsh = false
	self._gameView:gameConclude()

	-- if GlobalUserItem.bPrivateRoom then
	-- 	--self._gameView.spClock:setVisible(false)
	-- 	self._gameView.asLabTime:setString("0")
	-- else
		self:SetGameClock(self:GetMeChairID(), cmd.IDI_START_GAME, self.cbTimeStartGame)
	--end

	return true
end

--游戏记录（房卡）
function GameLayer:onSubGameRecord(dataBuffer)
	print("游戏记录")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_Record, dataBuffer)
	--dump(cmd_data, "CMD_S_Record")

	self.m_userRecord = {}
	local nInningsCount = cmd_data.nCount
	for i = 1, self.cbPlayerCount do
		self.m_userRecord[i] = {}
		self.m_userRecord[i].cbHuCount = cmd_data.cbHuCount[1][i]
		self.m_userRecord[i].cbMingGang = cmd_data.cbMingGang[1][i]
		self.m_userRecord[i].cbAnGang = cmd_data.cbAnGang[1][i]
		self.m_userRecord[i].cbMaCount = cmd_data.cbMaCount[1][i]
		self.m_userRecord[i].lDetailScore = {}
		for j = 1, nInningsCount do
			self.m_userRecord[i].lDetailScore[j] = cmd_data.lDetailScore[i][j]
		end
	end
	--dump(self.m_userRecord, "m_userRecord", 5)
end

--*****************************    普通函数     *********************************--
--发牌完成
function GameLayer:sendCardFinish()
	--self:SetGameClock(self.wCurrentUser, cmd.IDI_OUT_CARD, self.cbTimeOutCard)
	
	--提示操作
	if self.cbActionMask then
		self._gameView:recognizecbActionMask(self.cbActionMask, self.cbActionCard)
	end

	--提示听牌
	if self.wBankerUser == self:GetMeChairID() then
		self._gameView._cardLayer:promptListenOutCard(self.cbListenPromptOutCard)
	end

	self.bSendCardFinsh = true
end

--解析筛子
function GameLayer:analyseSice(wSiceCount)
	local cbSiceCount1 = math.mod(wSiceCount, 256)
	local cbSiceCount2 = math.floor(wSiceCount/256)
	return cbSiceCount1, cbSiceCount2
end

--设置操作时间
function GameLayer:SetGameOperateClock()
	self:SetGameClock(self:GetMeChairID(), cmd.IDI_OPERATE_CARD, self.cbTimeOperateCard)
end

--播放麻将数据音效（哪张）
function GameLayer:playCardDataSound(viewId, cbCardData)
	local strGender = ""
	if self.cbGender[viewId] == 1 then
		strGender = "BOY"
	else
		strGender = "GIRL"
	end
	local color = {"W_", "S_", "T_", "F_"}
	local nCardColor = math.floor(cbCardData/16) + 1
	local nValue = math.mod(cbCardData, 16)
	if cbCardData == GameLogic.MAGIC_DATA then
		nValue = 5
	end
	local strFile = cmd.RES_PATH.."sound/"..strGender.."/"..color[nCardColor]..nValue..".wav"
	self:PlaySound(strFile)
end
--播放麻将操作音效
function GameLayer:playCardOperateSound(viewId, bTail, operateCode)
	assert(operateCode ~= GameLogic.WIK_NULL)

	local strGender = ""
	if self.cbGender[viewId] == 1 then
		strGender = "BOY"
	else
		strGender = "GIRL"
	end
	local strName = ""
	if bTail then
		strName = "REPLACE.wav"
	else
		if operateCode >= GameLogic.WIK_CHI_HU then
			strName = "CHI_HU.wav"
		elseif operateCode == GameLogic.WIK_LISTEN then
			strName = "TING.wav"
		elseif operateCode == GameLogic.WIK_GANG then
			strName = "GANG.wav"
		elseif operateCode == GameLogic.WIK_PENG then
			strName = "PENG.wav"
		elseif operateCode <= GameLogic.WIK_RIGHT then
			strName = "CHI.wav"
		end
	end
	local strFile = cmd.RES_PATH.."sound/"..strGender.."/"..strName
	self:PlaySound(strFile)
end
--播放随机聊天音效
function GameLayer:playRandomSound(viewId)
	local strGender = ""
	if self.cbGender[viewId] == 1 then
		strGender = "BOY"
	else
		strGender = "GIRL"
	end
	local nRand = math.random(25) - 1
	if nRand <= 6 then
		local num = 6603000 + nRand
		local strName = num..".wav"
		local strFile = cmd.RES_PATH.."sound/PhraseVoice/"..strGender.."/"..strName
		self:PlaySound(strFile)
	end
end

--插入到已出现牌中
function GameLayer:insertAppearCard(cbCardData)
	assert(type(cbCardData) == "table")
	for i = 1, #cbCardData do
		table.insert(self.cbAppearCardData, cbCardData[i])
		--self._gameView:reduceListenCardNum(cbCardData[i])
	end
	table.sort(self.cbAppearCardData)
	local str = ""
	for i = 1, #self.cbAppearCardData do
		str = str..string.format("%x,", self.cbAppearCardData[i])
	end
	--print("已出现的牌:", str)
end

function GameLayer:getDetailScore()
	return self.m_userRecord
end

function GameLayer:getListenPromptOutCard()
	return self.cbListenPromptOutCard
end

function GameLayer:getListenPromptHuCard(cbOutCard)
	if not cbOutCard then
		return nil
	end

	for i = 1, #self.cbListenPromptOutCard do
		if self.cbListenPromptOutCard[i] == cbOutCard then
			assert(#self.cbListenCardList > 0 and self.cbListenCardList[i] and #self.cbListenCardList[i] > 0)
			return self.cbListenCardList[i]
		end
	end

	return nil
end

-- 刷新房卡数据
function GameLayer:updatePriRoom()
    if PriRoom and GlobalUserItem.bPrivateRoom then
        if nil ~= self._gameView._priView and nil ~= self._gameView._priView.onRefreshInfo then
            self._gameView._priView:onRefreshInfo()
        end
    end
end

--*****************************    发送消息     *********************************--
--开始游戏
function GameLayer:sendGameStart()
	self:SendUserReady()
	self:OnResetGameEngine()
end
--出牌
function GameLayer:sendOutCard(card)
	-- body
	if card == GameLogic.MAGIC_DATA then
		return false
	end

	self._gameView:HideGameBtn()
	print("发送出牌", card)

	local cmd_data = ExternalFun.create_netdata(cmd.CMD_C_OutCard)
	cmd_data:pushbyte(card)
	return self:SendData(cmd.SUB_C_OUT_CARD, cmd_data)
end
--操作扑克
function GameLayer:sendOperateCard(cbOperateCode, cbOperateCard)
	print("发送操作提示：", cbOperateCode, table.concat(cbOperateCard, ","))
	assert(type(cbOperateCard) == "table")

	--听牌数据置空
	self.cbListenPromptOutCard = {}
	self.cbListenCardList = {}
	self._gameView:setListeningCard(nil)
	self._gameView._cardLayer:promptListenOutCard(nil)

	--发送操作
	--local cmd_data = ExternalFun.create_netdata(cmd.CMD_C_OperateCard)
    local cmd_data = CCmd_Data:create(4)
	cmd_data:pushbyte(cbOperateCode)
	for i = 1, 3 do
		cmd_data:pushbyte(cbOperateCard[i])
	end
	--dump(cmd_data, "operate")
	self:SendData(cmd.SUB_C_OPERATE_CARD, cmd_data)
end
--用户听牌
function GameLayer:sendUserListenCard(bListen)
	local cmd_data = CCmd_Data:create(1)
	cmd_data:pushbool(bListen)
	self:SendData(cmd.SUB_C_LISTEN_CARD, cmd_data)
end
--用户托管
function GameLayer:sendUserTrustee()
	if not self.bSendCardFinsh then
		return
	end
	
	local cmd_data = CCmd_Data:create(1)
	cmd_data:pushbool(not self.bTrustee)
	self:SendData(cmd.SUB_C_TRUSTEE, cmd_data)
end
--用户补牌
-- function GameLayer:sendUserReplaceCard(card)
-- 	local cmd_data = ExternalFun.create_netdate(cmd.CMD_C_ReplaceCard)
-- 	cmd_data:pushbyte(card)
-- 	self:SendData(cmd.SUB_C_REPLACE_CARD, cmd_data)
-- end
--发送扑克
function GameLayer:sendControlCard(cbControlGameCount, cbCardCount, wBankerUser, cbCardData)
	local cmd_data = ExternalFun.create_netdata(cmd.CMD_C_SendCard)
	cmd_data:pushbyte(cbControlGameCount)
	cmd_data:pushbyte(cbCardCount)
	cmd_data:pushword(wBankerUser)
	for i = 1, #cbCardData do
		cmd_data:pushbyte(cbCardData[i])
	end
	self:SendData(cmd.SUB_C_SEND_CARD, cmd_data)
end

return GameLayer