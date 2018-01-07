local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")

local GameLayer = class("GameLayer", GameModel)

local cmd = appdf.req(appdf.GAME_SRC.."yule.runfasthn.src.models.CMD_Game")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.runfasthn.src.models.GameLogic")
local GameViewLayer = appdf.req(appdf.GAME_SRC.."yule.runfasthn.src.views.layer.GameViewLayer")
local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

function GameLayer:ctor(frameEngine, scene)
    GameLayer.super.ctor(self, frameEngine, scene)
end

function GameLayer:CreateView()
    return GameViewLayer:create(self):addTo(self)
end

function GameLayer:OnInitGameEngine()
    GameLayer.super.OnInitGameEngine(self)
    self.wBankerUser = yl.INVALID_CHAIR
    self.bTrustee = {}
    self.bNewTurn = false
    --self.cbCardData = {0x0C, 0x0B, 0x0A, 0x09, 0x38, 0x28, 0x18, 0x08, 0x37, 0x27, 0x17, 0x16, 0x06, 0x15, 0x05}
    self.cbCardData = {}
    self.cbTurnCardData = {}
	self.bBtnOutNoneEnabled = nil
	self.wTimeOutCount = 0
end

function GameLayer:OnResetGameEngine()
    GameLayer.super.OnResetGameEngine(self)
end

-- 计时器响应
function GameLayer:OnEventGameClockInfo(chair,time,clockId)
    -- body
    if clockId == cmd.IDI_OUT_CARD then --出牌时间
    	if (time == 0 or self.bTrustee[2] and time < cmd.TIME_OUT_CARD) and chair == self:GetMeChairID() then
    		if self.bTrustee[2] == false then
    			--超时加1
    			self.wTimeOutCount = self.wTimeOutCount + 1
    			print("self.wTimeOutCount:", self.wTimeOutCount)
    			if self.wTimeOutCount >= 3 then
    				self.wTimeOutCount = 0
    				self._gameView:onButtonClickedEvent(GameViewLayer.BT_TRUSTEE)
    			end
    		end

    		--自动出牌
			self._gameView:onButtonClickedEvent(self._gameView.BT_PROMPT)
			self._gameView:onButtonClickedEvent(self._gameView.BT_OUTCARD)
    	end
	elseif clockId == cmd.IDI_START_GAME then --开始时间
		if time == 0 then
			self._gameFrame:setEnterAntiCheatRoom(false)--退出防作弊
			self:onExitTable()
		end
	end

    if time <= 3 then
    	AudioEngine.playEffect(GameViewLayer.RES_PATH.."sound/GAME_WARN.WAV")
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

-- 场景消息
function GameLayer:onEventGameScene(cbGameStatus, dataBuffer)
	local wTableId = self:GetMeTableID()
	for i = 1, 3 do
		local userItem = self._gameFrame:getTableUserItem(wTableId, i - 1)
		if userItem then
			local wViewChairId = self:SwitchViewChairID(userItem.wChairID)
			self._gameView:OnUpdateUser(wViewChairId, userItem)
		end
	end

	if cbGameStatus == cmd.GAME_SCENE_FREE then
		print("空闲状态")
		local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_StatusFree,dataBuffer)

		for i = 1, 3 do
			local viewId = self:SwitchViewChairID(i - 1)
			self.bTrustee[viewId] = cmd_table.bAutoStatus[1][i]
			--self._gameView:setTrusteeVisible(viewId, self.bTrustee[viewId])
		end

		self._gameView:setGameMultiple(cmd_table.lBaseScore)
		self._gameView.btnStart:setVisible(not GlobalUserItem.isAntiCheat())
		self:SetGameClock(self:GetMeChairID(), cmd.IDI_START_GAME, cmd.TIME_START_GAME)
	elseif cbGameStatus == cmd.GAME_SCENE_PLAY then
		print("游戏状态")
		local int64 = Integer64.new()
		local lBaseScore = dataBuffer:readscore(int64):getvalue()
		local wBankerUser = dataBuffer:readword()
		local wLastOutUser = dataBuffer:readword()
		local wCurrentUser = dataBuffer:readword()
		local bCardData = {}
		for i = 1, 16 do
			bCardData[i] = dataBuffer:readbyte()
		end
		local bCardCount = {}
		for i = 1, 3 do
			bCardCount[i] = dataBuffer:readbyte()
		end
		local bBombCount = {}
		for i = 1, 3 do
			bBombCount[i] = dataBuffer:readbyte()
		end
		local bTurnCardCount = dataBuffer:readbyte()
		local bTurnCardData = {}
		for i = 1, 16 do
			bTurnCardData[i] = dataBuffer:readbyte()
		end

		-- local sa = dataBuffer:readbyte()
		-- local me = dataBuffer:readbyte()
		-- local gui = dataBuffer:readbyte()

		local lAllTurnScore = {}
		for i = 1, 3 do
			lAllTurnScore[i] = dataBuffer:readscore(int64):getvalue()
		end
		local lLastTurnScore = {}
		for i = 1, 3 do
			lLastTurnScore[i] = dataBuffer:readscore(int64):getvalue()
		end
		local bAutoStatus = {}
		for i = 1, 3 do
			bAutoStatus[i] = dataBuffer:readbool()
		end
		local wRoomType = dataBuffer:readword()

		-- local sa = dataBuffer:readbyte()
		-- local me = dataBuffer:readbyte()
		-- local gui = dataBuffer:readbyte()

		local lTurnScore = {}
		for i = 1, 3 do
			lTurnScore[i] = dataBuffer:readscore(int64):getvalue()
		end
		local lCollectScore = {}
		for i = 1, 3 do
			lCollectScore[i] = dataBuffer:readscore(int64):getvalue()
		end

		print("lBaseScore, wBankerUser, wLastOutUser, wCurrentUser, bTurnCardCount, wRoomType:\n",
			lBaseScore, wBankerUser, wLastOutUser, wCurrentUser, bTurnCardCount, wRoomType)
		print("bCardData:", table.concat(bCardData, ","))
		print("bCardCount:", table.concat(bCardCount, ","))
		print("bBombCount:", table.concat(bBombCount, ","))
		print("self.cbTurnCardData:", table.concat(self.cbTurnCardData, ","))
		print("lAllTurnScore:", table.concat(lAllTurnScore, ","))
		print("lLastTurnScore:", table.concat(lLastTurnScore, ","))
		print("bAutoStatus:", bAutoStatus[1], bAutoStatus[2], bAutoStatus[3])
		print("lTurnScore:", table.concat(lTurnScore, ","))
		print("lCollectScore:", table.concat(lCollectScore, ","))


		self._gameView:setGameMultiple(lBaseScore)

		local myChairId = self:GetMeChairID()
		self.cbCardData = {}
		for i = 1, bCardCount[myChairId + 1] do
			self.cbCardData[i] = bCardData[i]
		end
		local viewCardCount = {}
		for i = 1, 3 do
			local viewId = self:SwitchViewChairID(i - 1)
			viewCardCount[viewId] = bCardCount[i]
			-- if viewCardCount[viewId] <= 2 then
			-- 	self._gameView:runWarnAnimate(viewId)
			-- end
			--托管
			self.bTrustee[viewId] = bAutoStatus[i]
			self._gameView:setTrusteeVisible(viewId, self.bTrustee[viewId])
			--炸弹
			self._gameView:setBombNum(viewId, bBombCount[i])
			--self._gameView.nodePlayer[viewId]:getChildByName("Sprite_trustee"):setVisible(self.bTrustee[viewId])
		end

		GameLogic:SortCardList(self.cbCardData)
		self._gameView:gameSendCard(self.cbCardData, viewCardCount)

		self.cbTurnCardData = {}
		for i = 1, bTurnCardCount do
			self.cbTurnCardData[i] = bTurnCardData[i]
		end

		self._gameView:gameOutCard(self:SwitchViewChairID(wLastOutUser), self.cbTurnCardData, true)

		local time = cmd.TIME_OUT_CARD
		self._gameView:setFirstPlayer(self:SwitchViewChairID(wCurrentUser))
		if wCurrentUser == myChairId then
			--游戏按钮
			self:updateGameBtn()
			if self.bBtnOutNoneEnabled then
				time = cmd.TIME_OUT_CARD_FAST
			end
		end
		self:SetGameClock(wCurrentUser, cmd.IDI_OUT_CARD, time)

		--local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_StatusPlay,dataBuffer)
		--dump(cmd_table)
	else
		print("\ndefault\n")
		return false
	end

	self:dismissPopWait()

	return true
end

-- 游戏消息
function GameLayer:onEventGameMessage(sub, dataBuffer)
    -- body
	if sub == cmd.SUB_S_GAME_START then			--游戏开始
		return self:onSubGameStart(dataBuffer)
	elseif sub == cmd.SUB_S_OUT_CARD then		--用户出牌
		return self:onSubOutCard(dataBuffer)
	elseif sub == cmd.SUB_S_PASS_CARD then		--放弃出牌
		return self:onSubPassCard(dataBuffer)
	elseif sub == cmd.SUB_S_GAME_END then		--游戏结束
		return self:onSubGameEnd(dataBuffer)
   	elseif sub == cmd.SUB_S_AUTOMATISM then		--托管
		return self:onSubUserAutomatism(dataBuffer)
	else
		print("\ndefault\n")
		--return false
	end

	return true
end

--游戏开始
function GameLayer:onSubGameStart(dataBuffer)
	print("onSubGameStart", "tqr")
	local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_GameStart, dataBuffer)

	local wBankerUser = cmd_table.wBankerUser
	local viewBankerUser = self:SwitchViewChairID(wBankerUser)
	local cbCardCount = {16, 16, 16}
	if cmd_table.wCurrentUser == yl.INVALID_CHAIR then --有数值为3的炸弹
		cbCardCount[viewBankerUser] = 12
	end
	for i = 1, cbCardCount[2] do
		self.cbCardData[i] = cmd_table.cbCardData[1][i]
	end

	GameLogic:SortCardList(self.cbCardData)
	self._gameView:gameSendCard(self.cbCardData, cbCardCount)

	self._gameView:setFirstPlayer(viewBankerUser)
	if wBankerUser == self:GetMeChairID() then
		self._gameView:setGameBtnStatus(true, false, false)
	end
	self:SetGameClock(wBankerUser, cmd.IDI_OUT_CARD, cmd.TIME_OUT_CARD)

    AudioEngine.playEffect(GameViewLayer.RES_PATH.."sound/GAME_START.WAV")
end

--用户出牌
function GameLayer:onSubOutCard(dataBuffer)
	print("onSubOutCard", "tqr")
	local bCardCount = dataBuffer:readbyte()
	--local bSaMeGui = dataBuffer:readbyte()
	local wCurrentUser = dataBuffer:readword()
	local wOutCardUser = dataBuffer:readword()

	local outCardData = {}
	for i = 1, bCardCount do
		outCardData[i] = dataBuffer:readbyte()
	end
	--保存
	self.cbTurnCardData = outCardData

	local viewId = self:SwitchViewChairID(wOutCardUser)
	self._gameView:gameOutCard(viewId, outCardData)
	print("cmd_table.wCurrentUser, self:GetMeChairID()", wCurrentUser, self:GetMeChairID())
	-- print("wCurrentUser, wOutCardUser", wCurrentUser, wOutCardUser)
	print("outCardData", table.concat(outCardData, ","))

	local time = cmd.TIME_OUT_CARD
	if wCurrentUser == self:GetMeChairID() then
		--游戏按钮
		self:updateGameBtn()
		if self.bBtnOutNoneEnabled then
			time = cmd.TIME_OUT_CARD_FAST
		end
	end

	GameLogic:RemoveCard(outCardData, self.cbCardData)

	self._gameView:removeOutCard(self:SwitchViewChairID(wCurrentUser))
    AudioEngine.playEffect(GameViewLayer.RES_PATH.."sound/OUT_CARD.wav")

	self:SetGameClock(wCurrentUser, cmd.IDI_OUT_CARD, time)
end

--放弃出牌
function GameLayer:onSubPassCard(dataBuffer)
	print("onSubPassCard", "tqr")
	self.bNewTurn = dataBuffer:readbyte()
	--local bSaMeGui = dataBuffer:readbyte()
	local wPassUser = dataBuffer:readword()
	local wCurrentUser = dataBuffer:readword()

	print("self.bNewTurn, bSaMeGui, wPassUser, wCurrentUser/n", self.bNewTurn, bSaMeGui, wPassUser, wCurrentUser)

	self._gameView:gamePassCard(self:SwitchViewChairID(wPassUser))

	if self.bNewTurn == 1 then
		self.cbTurnCardData = {}
	end

	local time = cmd.TIME_OUT_CARD
	if wCurrentUser == self:GetMeChairID() then
		--游戏按钮
		self:updateGameBtn()
		if self.bBtnOutNoneEnabled then
			time = cmd.TIME_OUT_CARD_FAST
		end
	end

	self._gameView:removeOutCard(self:SwitchViewChairID(wCurrentUser))

	self:SetGameClock(wCurrentUser, cmd.IDI_OUT_CARD, time)
end

--游戏结束
function GameLayer:onSubGameEnd(dataBuffer)
	print("onSubGameEnd", "tqr")
	local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_GameEnd, dataBuffer)

	--剩余牌显示
	local cardData = {}			--分发
	local index = 1
	for i = 1, 3 do
		cardData[i] = {}
		for j = 1, cmd_table.bCardCount[1][i] do
			cardData[i][j] = cmd_table.bCardData[1][index]
			index = index + 1
		end
	end
	local viewCardData = {}		--转换
	local viewCardCount = {}
	for i = 1, 3 do
		local viewId = self:SwitchViewChairID(i - 1)
		viewCardData[viewId] = cardData[i]
		viewCardCount[viewId] = cmd_table.bCardCount[1][i]
		self._gameView:gameOutCard(viewId, viewCardData[viewId], true, true)
	end

	--结算框
	local result = {}
	local myTableId = self:GetMeTableID()
	local myChairId = self:GetMeChairID()
	local bMeWin = false
	for i = 1, 3 do
		result[i] = {}
		result[i].lScore = cmd_table.lGameScore[1][i]
		if i - 1 == myChairId and result[i].lScore > 0 then
			bMeWin = true
		end
		result[i].userItem = self._gameFrame:getTableUserItem(myTableId, i - 1)
	end
	self._gameView._resultLayer:setResult(result, bMeWin)

	self.bNewTurn = true
	self.wTimeOutCount = 0
	self.bTrustee = {}
    self.cbCardData = {}
    self.cbTurnCardData = {}
	self._gameView:gameEnded()

	AudioEngine.playEffect(GameViewLayer.RES_PATH.."sound/GAME_END.WAV")
	if bMeWin then
		AudioEngine.playEffect(GameViewLayer.RES_PATH.."sound/GAME_WIN.wav")
	else
		AudioEngine.playEffect(GameViewLayer.RES_PATH.."sound/GAME_LOST.wav")
	end

	self:SetGameClock(self:GetMeChairID(), cmd.IDI_START_GAME, cmd.TIME_START_GAME)
end

--托管
function GameLayer:onSubUserAutomatism(dataBuffer)
	print("onSubUserAutomatism", "tqr")
	local cmd_table = ExternalFun.read_netdata(cmd.CMD_S_UserAutomatism, dataBuffer)
	local viewId = self:SwitchViewChairID(cmd_table.wChairID)
	self.bTrustee[viewId] = cmd_table.bTrusee
	self._gameView:setTrusteeVisible(viewId, self.bTrustee[viewId])
	--self._gameView.nodePlayer[viewId]:getChildByName("Sprite_trustee"):setVisible(cmd_table.bTrusee)
end

--提示出牌
function GameLayer:promptCard()
	local resultOutCard = GameLogic:SearchOutCard(self.cbCardData, self.cbTurnCardData)
	print(table.concat(resultOutCard.cbResultCard, ","))

	if resultOutCard.cbCardCount == 0 then
		return nil
	else
		return resultOutCard.cbResultCard
	end
end

function GameLayer:updateGameBtn()
	--游戏按钮
	local resultOutCard = GameLogic:SearchOutCard(self.cbCardData, self.cbTurnCardData)		--不出按钮可否点击
	if resultOutCard.cbCardCount == 0 then
		self.bBtnOutNoneEnabled = true
	else
		self.bBtnOutNoneEnabled = false
	end

	local bBtnOutCardEnabled = nil		--出牌按钮可否点击
	local popupCardData = self._gameView._handCardLayer:getPopupCard()
	if self:detectionOutCard(popupCardData) then
		bBtnOutCardEnabled = true
	else
		bBtnOutCardEnabled = false
	end

	self._gameView:setGameBtnStatus(true, self.bBtnOutNoneEnabled, bBtnOutCardEnabled)
end

function GameLayer:detectionOutCard(popupCardData)
	local bOk = GameLogic:CompareCard(popupCardData, self.cbTurnCardData)

	--首出黑桃三
	local bHaveBlackThree = false
	for i = #self.cbCardData, 1, -1 do
		if self.cbCardData[i] == 0x33 then
			bHaveBlackThree = true
			break
		end
	end
	if bHaveBlackThree then
		local bOutBlackThree = false
		for i = 1, #popupCardData do
			if popupCardData[i] == 0x33 then
				bOutBlackThree = true
				break
			end
		end
		if not bOutBlackThree then
			bOk = false
		end
	end

	return bOk
end

--****************************    发送消息      ********************************--
--发送开始消息
function GameLayer:sendStart()
	self:KillGameClock()
    self._gameView:onResetData()
	return self._gameFrame:SendUserReady()
end

--发送出牌消息
function GameLayer:sendOutCard(cbCardData)
	local cbCardCount = #cbCardData
	local wDataSize = 1 + cbCardCount
	local cmd_data = CCmd_Data:create(wDataSize)
	cmd_data:pushbyte(cbCardCount)
	for i = 1, cbCardCount do
		cmd_data:pushbyte(cbCardData[i])
	end

	return self:SendData(cmd.SUB_C_OUT_CART, cmd_data)
end

--发送过牌消息
function GameLayer:sendPassCard()
	local cmd_data = CCmd_Data:create(0)
	return self:SendData(cmd.SUB_C_PASS_CARD, cmd_data)
end

--发送托管消息
function GameLayer:sendAutomatism()
	local cmd_data = ExternalFun.create_netdata(cmd.CMD_C_Automatism)
	cmd_data:pushbool(not self.bTrustee[2])
	return self:SendData(cmd.SUB_C_AUTOMATISM, cmd_data)
end

return GameLayer