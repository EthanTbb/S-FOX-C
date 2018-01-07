local cmd = appdf.req(appdf.GAME_SRC.."yule.sparrowhz.src.models.CMD_Game")
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC.."ExternalFun")
local CardLayer = appdf.req(appdf.GAME_SRC.."yule.sparrowhz.src.views.layer.CardLayer")
local PopupInfoHead = appdf.req("client.src.external.PopupInfoHead")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.sparrowhz.src.models.GameLogic")

local ResultLayer = class("ResultLayer", function(scene)
	local resultLayer = cc.CSLoader:createNode(cmd.RES_PATH.."gameResult/GameResultLayer.csb")
	return resultLayer
end)

ResultLayer.TAG_NODE_USER_1					= 1
ResultLayer.TAG_NODE_USER_2					= 2
ResultLayer.TAG_NODE_USER_3					= 3
ResultLayer.TAG_NODE_USER_4					= 4
ResultLayer.TAG_SP_ROOMHOST					= 5
ResultLayer.TAG_SP_BANKER					= 6
ResultLayer.TAG_BT_RECODESHOW				= 8
ResultLayer.TAG_BT_CONTINUE					= 9

ResultLayer.TAG_SP_HEADCOVER				= 1
ResultLayer.TAG_TEXT_NICKNAME				= 2
ResultLayer.TAG_ASLAB_SCORE					= 3
ResultLayer.TAG_HEAD 						= 4
ResultLayer.TAG_NODE_CARD					= 5

ResultLayer.WINNER_ORDER					= 1

local posBanker = {cc.p(146, 556), cc.p(146, 451), cc.p(146, 343), cc.p(146, 237)}

function ResultLayer:onInitData()
	--body
	self.winnerIndex = nil
	self.bShield = false
end

function ResultLayer:onResetData()
	--body
	self.winnerIndex = nil
	self.bShield = false
	self.nodeAwardCard:removeAllChildren()
	self.nodeRemainCard:removeAllChildren()
	for i = 1, cmd.GAME_PLAYER do
		self.nodeUser[i]:getChildByTag(ResultLayer.TAG_NODE_CARD):removeAllChildren()
		local score = self.nodeUser[i]:getChildByTag(ResultLayer.TAG_ASLAB_SCORE)
		if score then
			score:removeFromParent()
		end
	end
end

function ResultLayer:ctor(scene)
	self._scene = scene
	self:onInitData()
	ExternalFun.registerTouchEvent(self, true)

	local btRecodeShow = self:getChildByTag(ResultLayer.TAG_BT_RECODESHOW)
	btRecodeShow:setVisible(false)
	btRecodeShow:addClickEventListener(function(ref)
		print("战绩炫耀!")
	end)

	local btContinue = self:getChildByTag(ResultLayer.TAG_BT_CONTINUE)
	btContinue:addClickEventListener(function(ref)
		self:hideLayer()
		self._scene:onButtonClickedEvent(self._scene.BT_START)
	end)

	self.nodeUser = {}
	for i = 1, cmd.GAME_PLAYER do
		self.nodeUser[i] = self:getChildByTag(ResultLayer.TAG_NODE_USER_1 + i - 1)
		self.nodeUser[i]:setLocalZOrder(1)
		self.nodeUser[i]:getChildByTag(ResultLayer.TAG_SP_HEADCOVER):setLocalZOrder(1)
		--个人麻将
		local nodeUserCard = cc.Node:create()
			:setTag(ResultLayer.TAG_NODE_CARD)
			:addTo(self.nodeUser[i])
	end
	--奖码
	self.nodeAwardCard = cc.Node:create():addTo(self)
	--剩余麻将
	self.nodeRemainCard = cc.Node:create():addTo(self)
	--庄标志
	self.spBanker = self:getChildByTag(ResultLayer.TAG_SP_BANKER):setLocalZOrder(1)
end

function ResultLayer:onTouchBegan(touch, event)
	local pos = touch:getLocation()
	--print(pos.x, pos.y)
	local rect = cc.rect(17, 25, 1330, 750)
	if not cc.rectContainsPoint(rect, pos) then
		self:hideLayer()
	end
	return self.bShield
end

function ResultLayer:showLayer(resultList, cbAwardCard, cbRemainCard, wBankerChairId, cbHuCard)
	assert(type(resultList) == "table" and type(cbAwardCard) == "table" and type(cbRemainCard) == "table")
	local width = 44
	local height = 67
	for i = 1, #resultList do
		if resultList[i].cbChHuKind >= GameLogic.WIK_CHI_HU then
			self.winnerIndex = i
			break
		end
	end
	local nBankerOrder = 1
	for i = 1, cmd.GAME_PLAYER do
		local order = self:switchToOrder(i)
		if i <= #resultList then
			self.nodeUser[order]:setVisible(true)
			--头像
			local head = self.nodeUser[order]:getChildByTag(ResultLayer.TAG_HEAD)
			if head then
				head:updateHead(resultList[i].userItem)
			else
				head = PopupInfoHead:createNormal(resultList[i].userItem, 65)
				head:setPosition(0, 2)			--初始位置
				head:enableHeadFrame(false)
				head:enableInfoPop(false)
				head:setTag(ResultLayer.TAG_HEAD)
				self.nodeUser[order]:addChild(head)
			end
			--输赢积分
			local strFile = nil
			if resultList[i].lScore >= 0 then
				strFile = cmd.RES_PATH.."gameResult/num_win.png"
			else
				strFile = cmd.RES_PATH.."gameResult/num_lose.png"
				resultList[i].lScore = -resultList[i].lScore
			end
			local strNum = "/"..resultList[i].lScore --"/"代表“+”或者“-”
			labAtscore = cc.LabelAtlas:_create(strNum, strFile, 21, 27, string.byte("/"))
				:move(1080, -15)
				:setAnchorPoint(cc.p(0, 0.5))
				:setTag(ResultLayer.TAG_ASLAB_SCORE)
				:addTo(self.nodeUser[order])
			--昵称
			local textNickname = self.nodeUser[order]:getChildByTag(ResultLayer.TAG_TEXT_NICKNAME)
			textNickname:setString(resultList[i].userItem.szNickName)
			--个人麻将
			local nodeUserCard = self.nodeUser[order]:getChildByTag(ResultLayer.TAG_NODE_CARD)
			local fX = 82
			for j = 1, #resultList[i].cbBpBgCardData do 											--碰杠牌
				--牌底
				--local rectX = CardLayer:switchToCardRectX(resultList[i].cbBpBgCardData[j])
				local card = display.newSprite(cmd.RES_PATH.."game/font_small/card_down.png")
					--:setTextureRect(cc.rect(width*rectX, 0, width, height))
					:move(fX, -7)
					:addTo(nodeUserCard)
				--字体
				local nValue = math.mod(resultList[i].cbBpBgCardData[j], 16)
				local nColor = math.floor(resultList[i].cbBpBgCardData[j]/16)
				display.newSprite("game/font_small/font_"..nColor.."_"..nValue..".png")
					:move(width/2, height/2 + 8)
					:addTo(card)

				if resultList[i].cbBpBgCardData[j] == resultList[i].cbBpBgCardData[j + 1] then
					fX = fX + width
				else
					fX = fX + 52
				end
				--末尾
				if j == #resultList[i].cbBpBgCardData then
					fX = fX + 20
				end
			end
			for j = 1, #resultList[i].cbCardData do  											 	--剩余手牌
				--牌底
				--local rectX = CardLayer:switchToCardRectX(resultList[i].cbCardData[j])
				local card = display.newSprite(cmd.RES_PATH.."game/font_small/card_down.png")
					--:setTextureRect(cc.rect(width*rectX, 0, width, height))
					:move(fX, -7)
					:addTo(nodeUserCard)
				--字体
				local nValue = math.mod(resultList[i].cbCardData[j], 16)
				local nColor = math.floor(resultList[i].cbCardData[j]/16)
				display.newSprite("game/font_small/font_"..nColor.."_"..nValue..".png")
					:move(width/2, height/2 + 8)
					:addTo(card)

				fX = fX + width
			end
			--胡的那张牌
			if resultList[i].cbChHuKind >= GameLogic.WIK_CHI_HU then
				fX = fX + 20
				--牌底
				--local rectX = CardLayer:switchToCardRectX(cbHuCard)
				local huCard = display.newSprite(cmd.RES_PATH.."game/font_small/card_down.png")
					--:setTextureRect(cc.rect(width*rectX, 0, width, height))
					:move(fX, -7)
					:addTo(nodeUserCard)
				--字体
				local nValue = math.mod(cbHuCard, 16)
				local nColor = math.floor(cbHuCard/16)
				display.newSprite("game/font_small/font_"..nColor.."_"..nValue..".png")
					:move(width/2, height/2 + 8)
					:addTo(huCard)
				--自摸或放炮标记
				display.newSprite("#sp_ziMo.png")
					:move(fX + 21, -7 + 32)
					:addTo(nodeUserCard)
			end
			--奖码
			fX = fX + 110
			for j = 1, #resultList[i].cbAwardCard do
				--local rectX = CardLayer:switchToCardRectX(resultList[i].cbAwardCard[j])
				--local x = 788 + 52*j
				local y = -7
				--牌底
				local card = display.newSprite(cmd.RES_PATH.."game/font_small/card_down.png")
					--:setTextureRect(cc.rect(width*rectX, 0, width, height))
					:move(fX, y)
					:addTo(nodeUserCard)
				--字体
				local nValue = math.mod(resultList[i].cbAwardCard[j], 16)
				local nColor = math.floor(resultList[i].cbAwardCard[j]/16)
				display.newSprite("game/font_small/font_"..nColor.."_"..nValue..".png")
					:move(width/2, height/2 + 8)
					:addTo(card)
				if nil ~= self.winnerIndex and 
					(nValue == 1 or
					nValue == 5 or
					nValue == 9 or
					resultList[i].cbAwardCard[j] == GameLogic.MAGIC_DATA) then
					display.newSprite("#sp_chooseFlag.png")
						:move(fX + 5, y - 30)
						:addTo(nodeUserCard)
				end
				fX = fX + 52
			end
			--庄家
			if wBankerChairId == resultList[i].userItem.wChairID then
				nBankerOrder = order
			end
		else
			self.nodeUser[order]:setVisible(false)
		end
	end
	--剩余麻将
	local nLimlt = 29
	for i = 1, #cbRemainCard do
		local pos = cc.p(0, 0)
		if i <= nLimlt then 	--一行
			pos = cc.p(5 + width*i, 700)
		elseif i > nLimlt*2 then 	--三行
			pos = cc.p(25 + width*(i - nLimlt*2), 610)
		else 						--两行
			pos = cc.p(15 + width*(i - nLimlt), 655)
		end
		--牌底
		--local rectX = CardLayer:switchToCardRectX(cbRemainCard[i])
		local card = display.newSprite(cmd.RES_PATH.."game/font_small/card_up.png")
			--:setTextureRect(cc.rect(width*rectX, 0, width, height))
			:move(pos)
			:addTo(self.nodeRemainCard)
		--字体
		local nValue = math.mod(cbRemainCard[i], 16)
		local nColor = math.floor(cbRemainCard[i]/16)
		display.newSprite("game/font_small/font_"..nColor.."_"..nValue..".png")
			:move(width/2, height/2 - 8)
			:addTo(card)
	end
	--庄家
	self:setBanker(nBankerOrder)

	self.bShield = true
	self:setVisible(true)
	self:setLocalZOrder(yl.MAX_INT)
end

function ResultLayer:hideLayer()
	if not self:isVisible() then
		return
	end
	self:onResetData()
	self:setVisible(false)
	self._scene.btStart:setVisible(true)
end

--1~4转换到1~4
function ResultLayer:switchToOrder(index)
	assert(index >=1 and index <= cmd.GAME_PLAYER)
	if self.winnerIndex == nil then
		return index
	end
	local nDifference = ResultLayer.WINNER_ORDER - self.winnerIndex - 1
	local order = math.mod(index + nDifference, cmd.GAME_PLAYER) + 1
	return order
end

function ResultLayer:setBanker(order)
	assert(order ~= 0)
	self.spBanker:move(posBanker[order])
	self.spBanker:setVisible(true)
end

return ResultLayer