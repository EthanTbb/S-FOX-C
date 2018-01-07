local GameViewLayer = class("GameViewLayer",function(scene)
		local gameViewLayer =  display.newLayer()
    return gameViewLayer
end)

require("client/src/plaza/models/yl")
local cmd = appdf.req(appdf.GAME_SRC.."yule.runfasthn.src.models.CMD_Game")
local PopupInfoHead = appdf.req("client.src.external.PopupInfoHead")
local GameChatLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.game.GameChatLayer")
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local ResultLayer = appdf.req(appdf.GAME_SRC.."yule.runfasthn.src.views.layer.ResultLayer")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.runfasthn.src.models.GameLogic")
local HandCardLayer = appdf.req(appdf.GAME_SRC.."yule.runfasthn.src.views.layer.HandCardLayer")

GameViewLayer.RES_PATH 				= "game/yule/runfasthn/res/"
GameViewLayer.BT_EXIT 				= 1
GameViewLayer.BT_EXIT 				= 2
GameViewLayer.BT_START 				= 3
GameViewLayer.BT_CHAT 				= 4
GameViewLayer.BT_TRUSTEE 			= 5
GameViewLayer.BT_OUTNONE 			= 6
GameViewLayer.BT_REELECT 			= 7
GameViewLayer.BT_PROMPT 			= 8
GameViewLayer.BT_OUTCARD 			= 9

GameViewLayer.CBX_SOUNDOFF 			= 10

GameViewLayer.SP_HEAD 				= 15

local anchorPointCard = {cc.p(0, 0.5), cc.p(0.5, 0.5), cc.p(1, 0.5)}
local anchorPointBubble = {cc.p(0, 0), cc.p(0, 0), cc.p(1, 0)}
local anchorPointHead = {cc.p(0, 1), cc.p(0, 0), cc.p(1, 0.5)}
local posOutCard = {cc.p(350, 570), cc.p(667, 266), cc.p(970, 466)}
local posClock = {cc.p(400, 567), cc.p(667, 375), cc.p(840, 455)}
local posBubble = {cc.p(96, 598), cc.p(235, 344), cc.p(1230, 520)}
local posChat = {cc.p(113, 643), cc.p(252, 385), cc.p(1210, 560)}
local posHead = {cc.p(164, 360), cc.p(270, 323), cc.p(743, 280)}
local posFirstPlayer = {cc.p(172, 564), cc.p(310, 278), cc.p(1151, 443)}
local posWarn = {cc.p(256, 565), cc.p(358, 371), cc.p(1066, 485)}
local posEndedCard = {cc.p(190, 570), cc.p(667, 266), cc.p(1125, 466)}

function GameViewLayer:onInitData()
    self.nodeOutCard = {}
	self.cardData = {0x13, 0x23, 0x04, 0x24, 0x1C, 0x3D}
	self.nRemainCard = {16, 16, 16}
	self.chatDetails = {}
    self.cbGender = {}
    self.bombNum = {0, 0, 0}
    self.spriteWarnAnimate = {}
end

function GameViewLayer:onResetData()
	for v, k in pairs(self.nodeOutCard) do
		k:removeFromParent()
	end
	self.nodeOutCard = {}

	self:setGameBtnStatus(false, false, false)

	self._handCardLayer:onResetData()
	self.nRemainCard = {16, 16, 16}
	self.spriteFirstPlayer:setVisible(false)

	for i = 1, 3 do
		local remainCard = self.nodePlayer[i]:getChildByName("Text_remainCard")
		remainCard:setString("16")
		remainCard:setVisible(false)
		self:setBombNum(i, 0)
	end
end

function GameViewLayer:preloadUI()
    print("欢迎来到我的酒馆！")
    --路劲
    cc.FileUtils:getInstance():addSearchPath(device.writablePath..GameViewLayer.RES_PATH)
	--加载资源
	local rootLayer
	rootLayer, self._csbNode = ExternalFun.loadRootCSB(GameViewLayer.RES_PATH.."game/GameScene.csb", self)
	--加载动画
	local animation = cc.Animation:create()
	animation:setDelayPerUnit(0.04)
	animation:setLoops(-1)
	for i = 1, 4 do
		local str = string.format("Animate_warn_%d.png", i)
		local spriteFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(str)
		if spriteFrame then
			animation:addSpriteFrame(spriteFrame)
		end
	end
	cc.AnimationCache:getInstance():addAnimation(animation, "WARN")
end

function GameViewLayer:onExit()
	print("GameViewLayer onExit")
    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
end

local this
function GameViewLayer:ctor(scene)
	this = self
	self._scene = scene
	self:onInitData()
	self:preloadUI()
	self._resultLayer = ResultLayer:create(self):addTo(self, 3)
	self._handCardLayer = HandCardLayer:create(self):addTo(self, 1)

	--节点事件
	local function onNodeEvent(event)
		if event == "exit" then
			self:onExit()
		end
	end
	self:registerScriptHandler(onNodeEvent)

	--按钮回调
	local btnCallback = function(ref, eventType)
		if eventType == ccui.TouchEventType.ended then
			self:onButtonClickedEvent(ref:getTag(), ref)
		end
	end

	self.btnStart = self._csbNode:getChildByName("Button_start")
	self.btnStart:setTag(GameViewLayer.BT_START)
	self.btnStart:setVisible(false)
	self.btnStart:addTouchEventListener(btnCallback)

	local btnChat = self._csbNode:getChildByName("Button_chat")
	btnChat:setTag(GameViewLayer.BT_CHAT)
	btnChat:addTouchEventListener(btnCallback)

	local btnTrustee = self._csbNode:getChildByName("Button_trustee")
	btnTrustee:setTag(GameViewLayer.BT_TRUSTEE)
	btnTrustee:addTouchEventListener(btnCallback)

	local bAble = GlobalUserItem.bSoundAble or GlobalUserItem.bVoiceAble			--声音
	if GlobalUserItem.bVoiceAble then
		AudioEngine.playMusic(GameViewLayer.RES_PATH.."sound/BACK_MUSIC.wav", true)
	end
	local checkBoxSoundOff = self._csbNode:getChildByName("CheckBox_soundOff")
	checkBoxSoundOff:setTag(GameViewLayer.CBX_SOUNDOFF)
	checkBoxSoundOff:setSelected(not bAble)
	checkBoxSoundOff:addTouchEventListener(btnCallback)

	local btnExit = self._csbNode:getChildByName("Button_exit")
	btnExit:setTag(GameViewLayer.BT_EXIT)
	btnExit:addTouchEventListener(btnCallback)

	self.btnOutNone = self._csbNode:getChildByName("Button_outNone")
	self.btnOutNone:setTag(GameViewLayer.BT_OUTNONE)
	self.btnOutNone:setVisible(false)
	self.btnOutNone:addTouchEventListener(btnCallback)

	self.btnReelect = self._csbNode:getChildByName("Button_reelect")
	self.btnReelect:setTag(GameViewLayer.BT_REELECT)
	self.btnReelect:setVisible(false)
	self.btnReelect:addTouchEventListener(btnCallback)

	self.btnPrompt = self._csbNode:getChildByName("Button_prompt")
	self.btnPrompt:setTag(GameViewLayer.BT_PROMPT)
	self.btnPrompt:setVisible(false)
	self.btnPrompt:addTouchEventListener(btnCallback)

	self.btnOutCard = self._csbNode:getChildByName("Button_outCard")
	self.btnOutCard:setTag(GameViewLayer.BT_OUTCARD)
	self.btnOutCard:setVisible(false)
	self.btnOutCard:addTouchEventListener(btnCallback)

	self.spriteClock = self._csbNode:getChildByName("Sprite_clock")
	self.clock_time = self.spriteClock:getChildByName("AtlasLabel_time")
	self.spriteFirstPlayer = self._csbNode:getChildByName("Sprite_firstPlayer"):setVisible(false)

	--玩家节点
	self.nodePlayer = {}
	for i = 1, 3 do
		local strName = string.format("FileNode_viewChair_%d", i)
		self.nodePlayer[i] = self._csbNode:getChildByName(strName)
		self.nodePlayer[i]:setVisible(false)
	end
	self.nodePlayer[2]:getChildByName("Text_remainCard"):move(-34, 81)
	self.nodePlayer[2]:getChildByName("Sprite_ready"):move(500, 75)
	self.nodePlayer[2]:getChildByName("Sprite_trustee"):move(-34, 25)
	self.nodePlayer[2]:getChildByName("Text_bomb"):move(170, 17)

	--聊天框
    self._chatLayer = GameChatLayer:create(self._scene._gameFrame)
    self._chatLayer:addTo(self, 3)
	--聊天泡泡
	self.chatBubble = {}
	for i = 1 , cmd.GAME_PLAYER do 
		self.chatBubble[i] = display.newSprite("#Image_chatBubble.png", {scale9 = true ,capInsets = cc.rect(0, 0, 194, 69)})
			:setAnchorPoint(cc.p(0, 0))
			:move(posBubble[i])
			:setVisible(false)
			:addTo(self, 2)
	end
	self.chatBubble[3]:setScaleX(-1)
end

--更新用户显示
function GameViewLayer:OnUpdateUser(viewId, userItem)
	if not viewId or viewId == yl.INVALID_CHAIR then
		print("OnUpdateUser viewId is nil")
		return
	end

	--准备
	local spriteReady = self.nodePlayer[viewId]:getChildByName("Sprite_ready")
	--头像
	local head = self.nodePlayer[viewId]:getChildByTag(GameViewLayer.SP_HEAD)
	if not userItem then
		self.nodePlayer[viewId]:setVisible(false)
		spriteReady:setVisible(false)
		if head then
			head:setVisible(false)
		end
	else
		self.nodePlayer[viewId]:setVisible(true)
		--昵称
		local strNickname = string.EllipsisByConfig(userItem.szNickName, 117, string.getConfig("fonts/round_body.ttf", 20))
		self.nodePlayer[viewId]:getChildByName("Text_nickname"):setString(strNickname)
		--金币
		self:setUserScore(viewId, userItem.lScore)
		spriteReady:setVisible(yl.US_READY == userItem.cbUserStatus)
		if not head then
			head = PopupInfoHead:createNormal(userItem, 98)
			head:setPosition(68, 77)			--初始位置
			head:enableHeadFrame(false)
			head:enableInfoPop(true, posHead[viewId], anchorPointHead[viewId])			--点击弹出的位置0
			head:setTag(GameViewLayer.SP_HEAD)
			self.nodePlayer[viewId]:addChild(head)
		else
			head:updateHead(userItem)
		end
		head:setVisible(true)
    	self.cbGender[viewId] = userItem.cbGender
    	print("性别：", self.cbGender[viewId])
	end
end

function GameViewLayer:onButtonClickedEvent(tag, ref)
	if tag == GameViewLayer.BT_CHAT then
		self._chatLayer:showGameChat(true)
	elseif tag == GameViewLayer.CBX_SOUNDOFF then
		print("Sound off")
		local effect = not (GlobalUserItem.bSoundAble or GlobalUserItem.bVoiceAble)
		GlobalUserItem.setSoundAble(effect)
		GlobalUserItem.setVoiceAble(effect)
		if effect == true then
			AudioEngine.playMusic(GameViewLayer.RES_PATH.."sound/BACK_MUSIC.wav", true)
		end
	elseif tag == GameViewLayer.BT_EXIT then
		self._scene:onQueryExitGame()
	elseif tag == GameViewLayer.BT_START then
		self:onUserReady()
	elseif tag == GameViewLayer.BT_TRUSTEE then
		print("trustee")
		self._scene:sendAutomatism()
	elseif tag == GameViewLayer.BT_OUTNONE then
		print("out none")
		self:setGameBtnStatus(false, nil, false)

		self._scene:sendPassCard()
	elseif tag == GameViewLayer.BT_REELECT then
		print("reelect")
		self._handCardLayer:reelectCard()
	elseif tag == GameViewLayer.BT_PROMPT then
		print("prompt")
		local cardData = self._scene:promptCard()
		if cardData then
			self._handCardLayer:popupCard(cardData)
			self:setGameBtnStatus(nil, nil, true)
		else
		 	self:onButtonClickedEvent(GameViewLayer.BT_OUTNONE)
		end
	elseif tag == GameViewLayer.BT_OUTCARD then
		print("out card")

		local outCardData = self._handCardLayer:getPopupCard()
		if #outCardData > 0 then
			self:setGameBtnStatus(false, nil, false)
			self._scene:sendOutCard(outCardData)
		end
	else
		print("default")
	end
end

--计时器刷新
function GameViewLayer:OnUpdataClockView(viewId, time)
	if not viewId or viewId == yl.INVALID_CHAIR or not time then
		self.clock_time:setString("")
		self.spriteClock:setVisible(false)
	else
		self.clock_time:setString(time)
		self.spriteClock:move(posClock[viewId])
		self.spriteClock:setVisible(true)
	end
end

--玩家准备开始
function GameViewLayer:onUserReady()
		self.btnStart:setVisible(false)
		self._resultLayer:setVisible(false)
		self._scene:sendStart()
end

--设置玩家金币
function GameViewLayer:setUserScore(viewId, lScore)
	local textScore = self.nodePlayer[viewId]:getChildByName("Text_score")
	textScore:setString(lScore)

	--限宽
	local limitWidth = 92
	local scoreWidth = textScore:getContentSize().width
	if scoreWidth > limitWidth then
		textScore:setScaleX(limitWidth/scoreWidth)
	elseif textScore:getScaleX() ~= 1 then
		textScore:setScaleX(1)
	end
end

--设置游戏按钮显隐
function GameViewLayer:setGameBtnStatus(bVisible, bOutNoneEnabled, bOutCardEnabled)
	if nil ~= bVisible then
		self.btnOutNone:setVisible(bVisible)
		self.btnReelect:setVisible(bVisible)
		self.btnPrompt:setVisible(bVisible)
		self.btnOutCard:setVisible(bVisible)
	end

	if nil ~= bOutNoneEnabled then
		self.btnOutNone:setEnabled(bOutNoneEnabled)
		self.btnOutNone:setBright(bOutNoneEnabled)
	end

	if nil ~= bOutCardEnabled then
		self.btnOutCard:setEnabled(bOutCardEnabled)
		self.btnOutCard:setBright(bOutCardEnabled)
	end
end

--托管标记
function GameViewLayer:setTrusteeVisible(viewId, bVisible)
	self.nodePlayer[viewId]:getChildByName("Sprite_trustee"):setVisible(bVisible)
	if viewId == 2 then
		self:showTrusteeLayer(bVisible)
	end
end

--游戏倍数
function GameViewLayer:setGameMultiple(num)
	local labAt = self._csbNode:getChildByName("AtlasLabel_multiple")
	labAt:setString(num)

	if num == 0 then
		labAt:setVisible(false)
	else
		labAt:setVisible(true)
	end
end

--炸弹数
function GameViewLayer:setBombNum(viewId, num)
	local fonts = {"炸一轮", "炸二轮", "炸三轮", "炸四轮"}
	local textBomb = self.nodePlayer[viewId]:getChildByName("Text_bomb")
	textBomb:setString(fonts[num])
	if num == 0 then
		textBomb:setVisible(false)
	else
		textBomb:setVisible(true)
	end
    self.bombNum[viewId] = num
end

function GameViewLayer:gameSendCard(cardData, cardCount)
	--玩家剩余牌数
	for i = 1, 3 do
		self.nRemainCard[i] = cardCount[i]
		local remainCard = self.nodePlayer[i]:getChildByName("Text_remainCard")
		remainCard:setString(self.nRemainCard[i])
		remainCard:setVisible(true)
	end
	self._handCardLayer:setHandCard(cardData, cardCount)
end

function GameViewLayer:setFirstPlayer(viewId)
	self.spriteFirstPlayer:move(posFirstPlayer[1])
	self.spriteFirstPlayer:move(posFirstPlayer[2])
	self.spriteFirstPlayer:move(posFirstPlayer[3])
	print(viewId)
	self.spriteFirstPlayer:move(posFirstPlayer[viewId])
	self.spriteFirstPlayer:setVisible(true)
end

--出牌
function GameViewLayer:gameOutCard(viewId, cbCardData, bOnlyShow, bEnded)
	if viewId < 1 or viewId > 3 or nil == cbCardData or #cbCardData == 0 then
		return false
	end

	if nil ~= self.nodeOutCard[viewId] then
		self.nodeOutCard[viewId]:removeFromParent()
		self.nodeOutCard[viewId] = nil
	end

	local fSpacing = 70
	local sizeOutCard = cc.size(143 + fSpacing*(#cbCardData - 1), 194)
	self.nodeOutCard[viewId] = cc.Node:create()
		:setContentSize(sizeOutCard)
		:setAnchorPoint(anchorPointCard[viewId])
		:move(bEnded and posEndedCard[viewId] or posOutCard[viewId])
		:setScale(0.5)
		:addTo(self, 1)
	for i = 1, #cbCardData do
		local nValue = GameLogic:GetCardValue(cbCardData[i])
		local nColor = GameLogic:GetCardColor(cbCardData[i])
		display.newSprite(GameViewLayer.RES_PATH.."runFastCard.png")
			:setTextureRect(cc.rect(143*(nValue - 1), 194*nColor, 143, 194))
			:move(143/2 + fSpacing*(i - 1), 194/2)
			:addTo(self.nodeOutCard[viewId])
	end

	self:manageCardType(viewId, cbCardData)

	--玩家剩余牌
	if not bOnlyShow then
		self.nRemainCard[viewId] = self.nRemainCard[viewId] - #cbCardData
		self.nodePlayer[viewId]:getChildByName("Text_remainCard"):setString(self.nRemainCard[viewId])
		-- if self.nRemainCard[viewId] <= 2 then
		-- 	self:runWarnAnimate(viewId)
		-- end

		self._handCardLayer:cutHandCard(viewId, cbCardData)
	end

end

--不出牌
function GameViewLayer:gamePassCard(viewId)
	if viewId < 1 or viewId > 3 then
		return false
	end

	if nil ~= self.nodeOutCard[viewId] then
		self.nodeOutCard[viewId]:removeFromParent()
		self.nodeOutCard[viewId] = nil
	end
	self.nodeOutCard[viewId] = cc.Label:createWithTTF("PASS", "fonts/round_body.ttf", "40")
		:move(posOutCard[viewId])
		:setAnchorPoint(anchorPointCard[viewId])
		:addTo(self, 1)
	--声音
	if self.cbGender[viewId] == 0 then
    	AudioEngine.playEffect(GameViewLayer.RES_PATH.."sound/GIRL/PASS_CARD.wav")
	else
    	AudioEngine.playEffect(GameViewLayer.RES_PATH.."sound/BOY/PASS_CARD.wav")
	end
end

--游戏结束
function GameViewLayer:gameEnded()
	self.btnStart:setVisible(true)
	for i = 1, 3 do
    	self.bombNum[i] = 0
		self:setTrusteeVisible(i, false)
		if self.spriteWarnAnimate[i] then
			self.spriteWarnAnimate[i]:removeFromParent()
			self.spriteWarnAnimate[i] = nil
		end
	end
	self._handCardLayer:gameEnded()
end

function GameViewLayer:removeOutCard(viewId)
	if nil ~= self.nodeOutCard[viewId] then
		self.nodeOutCard[viewId]:removeFromParent()
		self.nodeOutCard[viewId] = nil
	end
end

--用户聊天
function GameViewLayer:userChat(wViewChairId, chatString)
	if chatString and #chatString > 0 then
		self._chatLayer:showGameChat(false)
		--取消上次
		if self.chatDetails[wViewChairId] then
			self.chatDetails[wViewChairId]:stopAllActions()
			self.chatDetails[wViewChairId]:removeFromParent()
			self.chatDetails[wViewChairId] = nil
		end

		--创建label
		local limWidth = 24*12
		local labCountLength = cc.Label:createWithTTF(chatString,"fonts/round_body.ttf", 24)  
		if labCountLength:getContentSize().width > limWidth then
			self.chatDetails[wViewChairId] = cc.Label:createWithTTF(chatString,"fonts/round_body.ttf", 24, cc.size(limWidth, 0))
		else
			self.chatDetails[wViewChairId] = cc.Label:createWithTTF(chatString,"fonts/round_body.ttf", 24)
		end
		self.chatDetails[wViewChairId]:setColor(cc.c3b(0, 0, 0))
		self.chatDetails[wViewChairId]:move(posChat[wViewChairId])
		self.chatDetails[wViewChairId]:setAnchorPoint(anchorPointBubble[wViewChairId])
		self.chatDetails[wViewChairId]:addTo(self, 2)

	    --改变气泡大小
		self.chatBubble[wViewChairId]:setContentSize(self.chatDetails[wViewChairId]:getContentSize().width+38, self.chatDetails[wViewChairId]:getContentSize().height + 54)
			:setVisible(true)
		--动作
	    self.chatDetails[wViewChairId]:runAction(cc.Sequence:create(
	    	cc.DelayTime:create(3),
	    	cc.CallFunc:create(function(ref)
	    		self.chatDetails[wViewChairId]:removeFromParent()
				self.chatDetails[wViewChairId] = nil
				self.chatBubble[wViewChairId]:setVisible(false)
	    	end)))
    end
end

--用户表情
function GameViewLayer:userExpression(wViewChairId, wItemIndex)
	if wItemIndex and wItemIndex >= 0 then
		self._chatLayer:showGameChat(false)
		--取消上次
		if self.chatDetails[wViewChairId] then
			self.chatDetails[wViewChairId]:stopAllActions()
			self.chatDetails[wViewChairId]:removeFromParent()
			self.chatDetails[wViewChairId] = nil
		end

	    local strName = string.format("e(%d).png", wItemIndex)
	    self.chatDetails[wViewChairId] = cc.Sprite:createWithSpriteFrameName(strName)
	        :move(posChat[wViewChairId])
			:setAnchorPoint(anchorPointBubble[wViewChairId])
			:addTo(self, 2)
	    --改变气泡大小
		self.chatBubble[wViewChairId]:setContentSize(90,100)
			:setVisible(true)

	    self.chatDetails[wViewChairId]:runAction(cc.Sequence:create(
	    	cc.DelayTime:create(3),
	    	cc.CallFunc:create(function(ref)
	    		self.chatDetails[wViewChairId]:removeFromParent()
				self.chatDetails[wViewChairId] = nil
				self.chatBubble[wViewChairId]:setVisible(false)
	    	end)))
    end
end

function GameViewLayer:manageCardType(viewId, cbCardData)
	local str = nil
	if self.cbGender[viewId] == 0 then
		str = GameViewLayer.RES_PATH.."sound/GIRL/"
	else
		str = GameViewLayer.RES_PATH.."sound/BOY/"
	end

	local cbFirstValue = GameLogic:GetCardValue(cbCardData[1])
	local cbCardType = GameLogic:GetCardType(cbCardData)
	if cbCardType == cmd.CT_SINGLE then --单张
		local strPath = str..string.format("SINGLE_%d.wav", cbFirstValue)
		AudioEngine.playEffect(strPath)

	elseif cbCardType == cmd.CT_DOUBLE_LINE then --对连
		if #cbCardData == 2 then
			local strPath = str..string.format("DOUBLE_%d.wav", cbFirstValue)
			AudioEngine.playEffect(strPath)
		else
			AudioEngine.playEffect(str.."DOUBLE_LINE.wav")
		end

	elseif cbCardType == cmd.CT_THREE_LINE then --三连
		if #cbCardData == 3 then
			AudioEngine.playEffect(str.."THREE.wav")
		else
			AudioEngine.playEffect(str.."THREE_LINE.wav")
		end

	elseif cbCardType == cmd.CT_THREE_LINE_TAKE_SINGLE then --三带单
		if #cbCardData == 4 then
			AudioEngine.playEffect(str.."THREE_TAKE_ONE.wav")
		else
			AudioEngine.playEffect(str.."THREE_ONE_LINE.wav")
		end

	elseif cbCardType == cmd.CT_THREE_LINE_TAKE_DOUBLE then --三带双
		if #cbCardData == 5 then
			AudioEngine.playEffect(str.."THREE_TAKE_TWO.wav")
		else
			AudioEngine.playEffect(str.."THREE_ONE_LINE.wav")
		end

	elseif cbCardType == cmd.CT_SINGLE_LINE then -- 顺子
		AudioEngine.playEffect(str.."SINGLE_LINE.wav")

	elseif cbCardType == cmd.CT_BOMB then -- 炸弹
		AudioEngine.playEffect(str.."BOMB_CARD.wav")
		self:setBombNum(viewId, self.bombNum[viewId] + 1)
	end
end

--托管遮盖层
function GameViewLayer:showTrusteeLayer(bShow)
	if not self.trusteeLayer then
		self.trusteeLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 125))
			:setContentSize(cc.size(display.width, 364))
			:addTo(self, 3)
		display.newSprite("#Sprite_bigTrustee.png")
			:move(display.cx, 160)
			:addTo(self.trusteeLayer)

		local onTouch = function(eventType, x, y)
			if not self.trusteeLayer:isVisible() then
				return false
			end

			local rect = self.trusteeLayer:getBoundingBox()
			if cc.rectContainsPoint(rect, cc.p(x, y)) then
				return true
			else
				return false
			end
		end

		self.trusteeLayer:setTouchEnabled(true)
		self.trusteeLayer:registerScriptTouchHandler(function(eventType, x, y)
			return onTouch(eventType, x, y)
		end)
	end
	self.trusteeLayer:setVisible(bShow)
end

--警报动画
function GameViewLayer:runWarnAnimate(viewId)
	if self.spriteWarnAnimate[viewId] then
		return
	end

	local animation = cc.AnimationCache:getInstance():getAnimation("WARN")
	local animate = cc.Animate:create(animation)
	print("comming?", animation, animate)
	self.spriteWarnAnimate[viewId] = display.newSprite()
		:move(posWarn[viewId])
		:addTo(self, 2)
	self.spriteWarnAnimate[viewId]:runAction(animate)
end

return GameViewLayer