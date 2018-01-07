local HandCardLayer = class("HandCardLayer", function(scene)
	local handCardLayer = display.newLayer()
	return handCardLayer
end)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC.."ExternalFun")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.runfasthn.src.models.GameLogic")

local posCard = {cc.p(256, 565), cc.p(667, 100), cc.p(1066, 485)}

function HandCardLayer:onInitData(scene)
	self._scene = scene
	self.bCardTouchEnabled = false
    --self.cbCardData = {0x0C, 0x0B, 0x0A, 0x09, 0x38, 0x28, 0x18, 0x08, 0x37, 0x27, 0x17, 0x16, 0x06, 0x15, 0x05}
    self.cbCardData = {}
    self.cbCardCount = {16, 16, 16}
	self.bCardPopup = {}
	self.bCardOut = {}
    for i = 1, 16 do
    	self.bCardPopup[i] = false
    	self.bCardOut[i] = false
    end
end

function HandCardLayer:onResetData()
	for i = 1, 16 do
		self.bCardPopup[i] = false
		self.bCardOut[i] = false
	end
end

function HandCardLayer:ctor(scene)
	self:onInitData(scene)

	local width = 143 + (16 - 1)*70
	local height = 194 + (16 - 1)*10
	self.nodeCard = {}
	for i = 1, 3 do
		self.nodeCard[i] = cc.Node:create()
			:move(posCard[i])
			:setContentSize(i == 2 and cc.size(width, 194) or cc.size(143, height))
			:setAnchorPoint(cc.p(0.5, 0.5))
			:addTo(self)
		for j = 1, 16 do
			local card = display.newSprite(self._scene.RES_PATH.."runFastCard.png")
				:setTextureRect(cc.rect(143*2, 194*4, 143, 194))
				:setTag(j)
				:setVisible(false)
				:addTo(self.nodeCard[i])

			if i == 2 then
				card:move(143/2 + (j - 1)*70, 194/2)
			else
				card:move(143/2, 194/2 + (j - 1)*10)
				if i == 1 then
					card:setLocalZOrder(16 + 1 - j)
				end
			end
		end
	end

	ExternalFun.registerTouchEvent(self, false)
end

function HandCardLayer:setHandCard(cardData, cardCount)
	if not cardData then
		print("card error!")
		return
	end

	self:onResetData()
	self.bCardTouchEnabled = true
	self.cbCardCount = cardCount
	self.cbCardData = clone(cardData)
	for i = 1, 3 do
		self:updateCard(i)
	end
	if cardCount[2] < 16 then
		for i = cardCount[2] + 1, 16 do
			self.nodeCard[2]:getChildByTag(i):setVisible(false)
		end
	end
end

function HandCardLayer:onTouchBegan(touch, event)
	if not self.bCardTouchEnabled then
		return false
	end

	return true
end

function HandCardLayer:onTouchEnded(touch, event)
	local pos = touch:getLocation()

	local nodeX, nodeY = self.nodeCard[2]:getPosition()
	local nodeSize = self.nodeCard[2]:getContentSize()
	local posTemp = cc.p(pos.x - (nodeX - nodeSize.width/2), pos.y -(nodeY - nodeSize.height/2)) 		--相对于牌的位置

	for i = 1, #self.cbCardData do
		local card = self.nodeCard[2]:getChildByTag(i)
		if card and not self.bCardOut[i] then
			local rectCard = card:getBoundingBox()
			if cc.rectContainsPoint(rectCard, posTemp) then
				local bMove = true

				for j = i + 1, #self.cbCardData do
					local card1 = self.nodeCard[2]:getChildByTag(j)
					if card1 and not self.bCardOut[j] then
						local rectCard1 = card1:getBoundingBox()
						if cc.rectContainsPoint(rectCard1, posTemp) then
							bMove = false
						end
						break
					end
				end

				--是否可以移动
				if bMove then
					local cardX, cardY = card:getPosition()
					if self.bCardPopup[i] then
						card:move(cardX, cardY - 30)
					else
						card:move(cardX, cardY + 30)
					end
					self.bCardPopup[i] = not self.bCardPopup[i]
					self:detectionPopupCard()
					break
				end
			end
		end
	end

	return true
end

--更新牌的坐标、纹理、显隐
function HandCardLayer:updateCard(viewId)
	local width = 143 + (self.cbCardCount[viewId] - 1)*70
	local height = 194 + (self.cbCardCount[viewId] - 1)*10
	self.nodeCard[viewId]:setContentSize(viewId == 2 and cc.size(width, 194) or cc.size(143, height))

	if viewId == 2 then
		local k = 0
		for i = 1, #self.cbCardData do
			local card = self.nodeCard[2]:getChildByTag(i)

			if self.bCardOut[i] then
				card:setTextureRect(cc.rect(143*2, 194*4, 143, 194))
				card:move(0, 0)
				card:setVisible(false)
			else
				local nValue = GameLogic:GetCardValue(self.cbCardData[i])
				local nColor = GameLogic:GetCardColor(self.cbCardData[i])
				card:setTextureRect(cc.rect(143*(nValue - 1), 194*nColor, 143, 194))

				local pos = cc.p(cc.p(143/2 + 70*k, 194/2))
				if self.bCardPopup[i] then
					pos.y = pos.y + 30
				end
				card:move(pos)
				card:setVisible(true)

				k = k + 1
			end
		end
	else
		for i = 1, 16 do
			local card = self.nodeCard[viewId]:getChildByTag(i)
			if i <= self.cbCardCount[viewId] then
				card:setVisible(true)
			else
				card:setVisible(false)
			end
		end
	end
end

--出牌
function HandCardLayer:getPopupCard()
	local outCardData = {}
	for i = 1, #self.cbCardData do
		if self.bCardPopup[i] and not self.bCardOut[i] then
			table.insert(outCardData, self.cbCardData[i])
		end
	end

	return outCardData
end

function HandCardLayer:cutHandCard(viewId, cardData)
	if not cardData then
		print("card error!")
		return
	end

	self.cbCardCount[viewId] = self.cbCardCount[viewId] - #cardData

	if viewId == 2 then
		for i = 1, #cardData do
			for j = 1, #self.cbCardData do
				if cardData[i] == self.cbCardData[j] then
					self.bCardOut[j] = true
					break
				end
			end
		end
	end

	self:updateCard(viewId)
end

function HandCardLayer:gameEnded()
	self.bCardTouchEnabled = false
	for i = 1, 3 do
		for j = 1, 16 do
			self.nodeCard[i]:getChildByTag(j):setVisible(false)
		end
	end
end

function HandCardLayer:popupCard(cardData)
	if not cardData then
		print("card error!")
		return
	end

	self.bCardPopup = {}		--先清零

	for i = 1, #cardData do
		local bHave = false
		for j = 1, #self.cbCardData do
			if cardData[i] == self.cbCardData[j] then
				--assert(not self.bCardOut[j], "已出的牌片")
				if self.bCardOut[j] then
				end
				self.bCardPopup[j] = true
				bHave = true

				break
			end
		end
		--assert(bHave, "Error! The prompt card does not exist!")
		if not bHave then
			print("该牌值没有")
		end
	end
	self:updateCard(2)
end

function HandCardLayer:detectionPopupCard()
	local popupCardData = self:getPopupCard()
	local bOk = self._scene._scene:detectionOutCard(popupCardData)
	self._scene:setGameBtnStatus(nil, nil, bOk)
end

function HandCardLayer:reelectCard()
	self.bCardPopup = {}
	self:updateCard(2)
	self._scene:setGameBtnStatus(nil, nil, false)
end

return HandCardLayer