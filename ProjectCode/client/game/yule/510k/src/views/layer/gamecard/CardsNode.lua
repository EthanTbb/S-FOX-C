
local module_pre = "game.yule.510k.src"
local CardSprite = appdf.req(module_pre .. ".views.layer.gamecard.CardSprite")
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local cmd = appdf.req(module_pre .. ".models.CMD_Game")
local GameLogic = appdf.req(module_pre .. ".models.GameLogic")

local CARD_X_POS = 0
--横向间隔
local CARD_X_DIS = 75
--纵向间隔
local CARD_Y_DIS = 25

local ANI_BEGIN = 0.1
--弹出动画
local CARD_SHOOT_TIME = 0.2
--弹回动画
local CARD_BACK_TIME = 0.2
--弹出距离
local CARD_SHOOT_DIS = 20
--最低叠放层级
local MIN_DRAW_ORDER = 0
--最高叠放层级
local MAX_DRAW_ORDER = 20
--过滤模式
local kHIGHEST = 1
local kLOWEST = 2
--拖动方向
local kMoveNull = 0
local kMoveToLeft = 1
local kMoveToRight = 2
-- 自己扑克尺寸
local CARD_SHOW_SCALE = 1.0
-- 非自己扑克尺寸
local CARD_HIDE_SCALE = 0.5
-- 亮牌尺寸
local CARD_LEFT_SCALE = 0.5

local function ANI_RATE( var )
	return var * ANI_BEGIN
end

local CardsNode = class("CardsNode", cc.Node)
CardsNode.CARD_X_DIS = CARD_X_DIS
CardsNode.CARD_Y_DIS = CARD_Y_DIS

function CardsNode.registerTouchEvent(node, bSwallow, FixedPriority)
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


function CardsNode:ctor(bSwallow,FixedPriority)
	--ExternalFun.registerTouchEvent(self)
	CardsNode.registerTouchEvent(self,bSwallow,FixedPriority)
	
	--扑克管理
	self.m_mapCard = {}
	self.m_vecCard = {}
	--扑克数据
	self.m_cardsData = {}
	self.m_cardsHolder = nil

	--视图id
	self.m_nViewId = cmd.INVALID_VIEWID
	--是否可点击
	self.m_bClickable = false
	--是否发牌
	self.m_bDispatching = false
	--提示出牌
	self.m_bSuggested = false

	------
	-- 扑克操控

	--开始点击位置
	self.m_beginTouchPoint = cc.p(0,0)
	--开始点击选牌
	self.m_beginSelectCard = nil
	--结束点击选牌
	self.m_endSelectCard = nil
	--是否拖动
	self.m_bDragCard = false
	--是否触摸
	self.m_bTouched = false
	--拖动方向
	self.m_dragMoveDir = kMoveNull

	--选牌管理
	self.m_mapSelectedCards = {}
	--拖动选择
	self.m_mapDragSelectCards = {}
	--选择扑克
	self.m_tSelectCards = {}

	--回调监听
	self.m_pSelectedListener = nil
	-- 扑克操控
	------
	self.m_cardsCount = 0
end

function CardsNode:createEmptyCardsNode(viewId, bSwallow, FixedPriority)
	local node = CardsNode.new(bSwallow,FixedPriority)
	if nil ~= node and node:init() then
		node.m_nViewId = viewId
		node.m_bClickable = (viewId == cmd.MY_VIEWID)
		node:addCardsHolder()

		return node
	end
	return nil;
end

function CardsNode:createCardsNode(viewId, cards, isShowCard, bSwallow, FixedPriority)
	local node = CardsNode.new(bSwallow,FixedPriority)
	if nil ~= node and node:init() then
		node.m_nViewId = viewId
		node.m_bClickable = (viewId == cmd.MY_VIEWID)
		node:addCardsHolder()
		node:updateCardsNode(cards, isShowCard, false, nil)		

		return node
	end
	return nil
end

function CardsNode:setListener( pNode )
	self.m_pSelectedListener = pNode
end

function CardsNode:onExit()
	self:removeAllCards()

	self.m_pSelectedListener = nil
end

function CardsNode:onTouchBegan(touch, event)
	
	if nil ~= self.m_pSelectedListener.m_trusteeshipBg then
		if self.m_pSelectedListener.m_trusteeshipBg:isVisible() then
        	--return false
        end
    end
    print("------ CardsNode:onTouchBegan  -------", self:isVisible(), self.m_bClickable, self.m_bDispatching)
	if false == self:isVisible() or false == self.m_bClickable or true == self.m_bDispatching then
		return false
	end
	local location = touch:getLocation()

	self.m_endSelectCard = nil
	self.m_bDragCard = false
	self.m_beginTouchPoint = self:convertToNodeSpace(location)
	self.m_beginSelectCard = self:filterCard(kHIGHEST, location)
	if nil ~= self.m_beginSelectCard 
		and nil ~= self.m_beginSelectCard.getCardData then
		--选牌效果
		self.m_beginSelectCard:showSelectEffect(true)
		self.m_mapSelectedCards[self.m_beginSelectCard:getCardData()] = self.m_beginSelectCard
	end
	self.m_bTouched = (self.m_beginSelectCard ~= nil)
	return true
end

function CardsNode:onTouchMoved(touch, event)
	if true == self.m_bTouched then
		local location = touch:getLocation()

		self.m_endSelectCard = self:filterCard(kHIGHEST, location)
		self.m_bDragCard = true
		local touchRect = self:makeTouchRect(self:convertToNodeSpace(location))

		--筛选在触摸区域内的卡牌
		local mapTouchCards = self:inTouchAreaCards(touchRect)

		--过滤有效卡牌,选择叠放最高
		if type(mapTouchCards) ~= "table" or 0 == table.nums(mapTouchCards) then
			return
		end

		if nil ~= self.m_endSelectCard 
			and nil ~= self.m_endSelectCard.getCardData then			
			--拖动选择
			if false == self.m_endSelectCard:getCardDragSelect() then
				self.m_endSelectCard:showSelectEffect(true)
				self.m_endSelectCard:setCardDragSelect(true)
				if nil ~= self.m_beginSelectCard 
					and self.m_beginSelectCard:getCardData() ~= self.m_endSelectCard:getCardData() then
					self.m_mapDragSelectCards[self.m_endSelectCard:getCardData()] = self.m_endSelectCard
				end
			end
		end

		--剔除不在触摸区域内，但已选择的卡牌
		for k,v in pairs(self.m_mapDragSelectCards) do
			local tmpCard = mapTouchCards[k]
			if nil == tmpCard then
				self.m_mapDragSelectCards[k]:setCardDragSelect(false)
				self.m_mapDragSelectCards[k]:showSelectEffect(false)
				self.m_mapDragSelectCards[k] = nil
			end
		end	
	end
end

function CardsNode:onTouchEnded(touch, event)
	if true == self.m_bTouched then
		local location = touch:getLocation()

		self.m_endSelectCard = self:filterCard(kHIGHEST, location)
		if false == self.m_bDragCard then
			if nil ~= self.m_endSelectCard 
				and nil ~= self.m_endSelectCard.getCardData then
				self.m_endSelectCard:setCardDragSelect(true)

				if nil ~= self.m_beginSelectCard
					and nil ~= self.m_beginSelectCard.getCardData
					and self.m_beginSelectCard:getCardData() ~= self.m_endSelectCard:getCardData() then
					self.m_mapSelectedCards[self.m_endSelectCard:getCardData()] = self.m_endSelectCard
				end
			end
			--选牌音效
			ExternalFun.playSoundEffect("xuanpai.wav")
		end

		--选牌效果
		if nil ~= self.m_beginSelectCard then
			self.m_beginSelectCard:showSelectEffect(false)
		end
	end
	if not self.m_pSelectedListener.m_bClickSuggest then
		local vecSelectCard = self:filterDragSelectCards(self.m_bTouched)
		self:dragCards(vecSelectCard)
	else
		self.m_pSelectedListener.m_bClickSuggest = false
	end
	
	if true == self.m_bSuggested then
		self.m_bSuggested = (0 ~= table.nums(self.m_mapSelectedCards))
	end
	self.m_beginSelectCard = nil
    self.m_endSelectCard = nil
    self.m_bDragCard = false
    self.m_bTouched = false
    --dump(self.m_mapSelectedCards, "---------------CardsNode:onTouchEnded------------", 6)
end

function CardsNode:onTouchCancelled(touch, event)
end

-- 更新
-- @param[cards] 新的扑克数据
-- @param[isShowCard] 是否显示正面
-- @param[bAnimation] 是否动画效果
-- @param[pCallBack] 更新回调
function CardsNode:updateCardsNode( cards, isShowCard, bAnimation, pCallBack)
	if type(cards) ~= "table"  then
		return
	end

	local m_cardsData = cards
	local m_cardCount = #cards
	bAnimation = bAnimation or false
	isShowCard = isShowCard or false

	if 0 == m_cardCount then
		print("count = 0")
		return
	end	
	
	self.m_bAddCards = false
	self.m_bDispatching = true

	self:removeAllCards()
	self.m_cardsData = m_cardsData
	self.m_cardsCount = m_cardCount
	self.m_bShowCard = isShowCard

	--转换为相对于自己的中间位置
	local winSize = cc.Director:getInstance():getWinSize()
	local centerPos = cc.p(winSize.width * 0.5, winSize.height * 0.5)
	centerPos = self.m_cardsHolder:convertToNodeSpace(centerPos)
	print("================ updateCardsNode  centerPos ================",self.m_nViewId,centerPos.x,centerPos.y)
	local toPos = centerPos

	local mapKey = 0
	local m_cardsHolder = self.m_cardsHolder
	---[[
	if cmd.LEFT_VIEWID == self.m_nViewId then
		--toPos = self:convertToNodeSpace(cc.p(winSize.width * 0.3, winSize.height * 0.5))
		toPos = self.m_cardsHolder:convertToNodeSpace(cc.p(winSize.width * 0.3, winSize.height * 0.5))
	elseif cmd.RIGHT_VIEWID == self.m_nViewId then
		--toPos = self:convertToNodeSpace(cc.p(winSize.width * 0.7, winSize.height * 0.5))
		toPos = self.m_cardsHolder:convertToNodeSpace(cc.p(winSize.width * 0.7, winSize.height * 0.5))
		--toPos = cc.p(0.5,500)
	elseif cmd.TOP_VIEWID == self.m_nViewId then
		--toPos = self:convertToNodeSpace(cc.p(winSize.width * 0.5, winSize.height * 0.5))
		--toPos = cc.p(0.5,500)
		toPos = self.m_cardsHolder:convertToNodeSpace(cc.p(winSize.width * 0.5, winSize.height * 0.5))
	end
	--]]
	--创建扑克
	if cmd.MY_VIEWID ~= self.m_nViewId then
		if nil ~= self.m_pSelectedListener then
			self.m_pSelectedListener:updateCardsNodeLayout(self.m_nViewId,0,false)
		end
	else
		if nil ~= self.m_pSelectedListener then
			--self.m_pSelectedListener.m_cardNum1:setVisible(true)
    		--self.m_pSelectedListener.m_cardNum1:setString(string.format("%d", 0))
    	end
	end
	
	for i = 1, m_cardCount do
		local tmpSp = CardSprite:createCard(m_cardsData[i])
		tmpSp:setPosition(centerPos)
		tmpSp:setDispatched(false)
		tmpSp:showCardBack(true)
		tmpSp:setVisible(true)
		m_cardsHolder:addChild(tmpSp)
		if 0 == m_cardsData[i] then
			mapKey = i
		else
			mapKey = m_cardsData[i]
		end
		self.m_mapCard[mapKey] = tmpSp
	end
	self:setVisible(true)
	self.m_cardsHolder:setVisible(true)
	--运行动画
	if ((cmd.RIGHT_VIEWID == self.m_nViewId) 
		or (cmd.LEFT_VIEWID == self.m_nViewId)
		or (cmd.MY_VIEWID == self.m_nViewId)
		or (cmd.TOP_VIEWID == self.m_nViewId))
		and (true == bAnimation) then

		for i = 1, m_cardCount do
			local key = (m_cardsData[i] ~= 0) and m_cardsData[i] or i
			local tmpSp = self.m_mapCard[key]
			tmpSp:setVisible(true)
			if nil ~= tmpSp then
				print("=============== updateCardsNode ==============",self.m_nViewId,i,toPos.x,toPos.y,centerPos.x,centerPos.y)
				local moveTo = cc.MoveTo:create(0.3 + i / 16, toPos)
				local backTo = cc.MoveTo:create(0.3, centerPos)
				local seq = nil
				if i == m_cardCount then
					seq = cc.Sequence:create(moveTo, backTo, cc.CallFunc:create(function()
						
						self:arrangeAllCards(bAnimation, pCallBack)
					end))
				else
					seq = cc.Sequence:create(moveTo, backTo, cc.CallFunc:create(function()
						--[[
						if cmd.MY_VIEWID ~= self.m_nViewId then
							self.m_pSelectedListener:updateCardsNodeLayout(self.m_nViewId,i,true)
						end
						--]]
					end))
				end

				tmpSp:stopAllActions()
				--if cmd.MY_VIEWID == self.m_nViewId then
					tmpSp:runAction(seq)
				--end
				
			end			
		end
	else
		self:arrangeAllCards(bAnimation, pCallBack)
	end
end

-- 更新
-- @param[cards] 新扑克数据
function CardsNode:updateCardsData( cards )
	if type(cards) ~= "table"  then
		return
	end

	local m_cardsData = cards
	self.m_cardsData = m_cardsData
	self.m_cardsCount = #m_cardsData

	local vecChildren = self.m_cardsHolder:getChildren()
	self.m_mapCard = {}

	--数量检查
	if #vecChildren ~= #cards then
		print("children count " .. #vecChildren .. " cards count " .. #cards)
		return
	end

	for k,v in pairs(vecChildren) do
		local cbCardData = m_cardsData[k]
		v:setCardValue(cbCardData)
		self.m_mapCard[cbCardData] = v
	end
end

-- 加牌
function CardsNode:addCards( addCards, handCards )
	if type(addCards) ~= "table"  then
		return
	end

	local tmpcount = #handCards
	self.m_cardsData = handCards	
	if tmpcount > cmd.MAX_COUNT then
		print("超出最大牌数")
		return
	end

	--转换为相对于自己的中间位置
	local winSize = cc.Director:getInstance():getWinSize()
	local centerPos = cc.p(winSize.width * 0.5, winSize.height * 0.5)
	centerPos = self:convertToNodeSpace(centerPos)

	for i = 1, #addCards do
		local tmpSp = CardSprite:createCard(addCards[i])
		tmpSp:setPosition(centerPos)
		tmpSp:setDispatched(false)
		tmpSp:showCardBack(true)
		self.m_cardsHolder:addChild(tmpSp)
		if 0 == self.m_cardsData[i] then
			mapKey = self.m_cardsCount + i
		else
			mapKey = addCards[i]
		end
		self.m_mapCard[mapKey] = tmpSp
	end
	self.m_cardsCount = tmpcount
	self:arrangeAllCards(true)
end

-- 出牌
-- @param[cards] 	 	出牌
-- @param[bNoSubCount]	不减少牌数
-- @return 需要移除的牌精灵
function CardsNode:outCard( cards, bNoSubCount )
	bNoSubCount = bNoSubCount or false
	if type(cards) ~= "table"  then
		return
	end

	local vecOut = {}
	local outCount = #cards
	local handCount = self.m_cardsCount
	local m_cardsHolder = self.m_cardsHolder

	local bOutOk = false
	local haveCardData = self.m_nViewId == cmd.MY_VIEWID
	if 0 ~= handCount and haveCardData then
		self.m_bDispatching = true
		for k,v in pairs(cards) do
            local removeIdx = nil
            for k1,v1 in pairs(self.m_cardsData) do            
                if v == v1 then
                    removeIdx = k1
                end
            end
            if nil ~= removeIdx then
                table.remove(self.m_cardsData, removeIdx)
            end
        end
        self.m_cardsCount = #self.m_cardsData

		for i = 1, outCount do
			local tag = cards[i]
			--print("***** 出牌:" .. yl.POKER_VALUE[tag])
			local tmpSp = m_cardsHolder:getChildByTag(tag)
			if nil ~= tmpSp then
				table.insert(vecOut, tmpSp)
			end

			self.m_mapCard[tag] = nil
		end
		bOutOk = true
		self:reSortCards()
	elseif not bNoSubCount then
		local afterCards = {}
        for i = 1, self.m_cardsCount - outCount do
            table.insert(afterCards, 0)
        end
        self.m_cardsData = afterCards
        self.m_cardsCount = #self.m_cardsData

		local vecChildren = m_cardsHolder:getChildren()
		if 0 ~= #vecChildren then
			for i = 1, outCount do
				local tag = cards[i]
				--print("##### 出牌:" .. yl.POKER_VALUE[tag])
				local tmpSp = vecChildren[i]
				if nil ~= tmpSp then
					if tmpSp:getTag() ~= tag then
						tmpSp:setCardValue(tag)
					end
					table.insert(vecOut, tmpSp)
				end

				self.m_mapCard[tag] = nil
			end
			bOutOk = true
		end			
	end

	if not bOutOk then
		for i = 1, outCount do
			local cbCardData = cards[i] or 0
			local tmpSp = CardSprite:createCard(cbCardData)
			tmpSp:setPosition(CARD_X_DIS, 0)
			tmpSp:showCardBack(true)
			m_cardsHolder:addChild(tmpSp)
			table.insert(vecOut, tmpSp)
		end
	end

	--清除选中
	for k,v in pairs(self.m_mapSelectedCards) do 
		v:showSelectEffect(false)
		v:setCardDragSelect(false)
		v:setPositionY(0)
	end
	for k,v in pairs(self.m_mapDragSelectCards) do 
		v:showSelectEffect(false)
		v:setCardDragSelect(false)
		v:setPositionY(0)
	end
	self.m_mapSelectedCards = {}
	self.m_mapDragSelectCards = {}
	self.m_tSelectCards = {}
	self.m_bSuggested = false

	--变动通知
	if nil ~= self.m_pSelectedListener and nil ~= self.m_pSelectedListener.onCountChange then
		self.m_pSelectedListener:onCountChange( self.m_cardsCount, self, true )
	end
	return vecOut
end

-- 显示扑克
function CardsNode:showCards()
	for k,v in pairs(self.m_mapCard) do
		if nil ~= v and nil ~= v.showCardBack then
			v:showCardBack(false)
		end		
	end
end

-- 结算显示
-- @param[cards] 实际扑克数据
function CardsNode:showLeftCards( cards )
	if type(cards) ~= "table"  then
		return
	end

	if cmd.MY_VIEWID == self.m_nViewId then
		return
	end
	--dump(cards, "left cards", 6)

	local vecChildren = self.m_cardsHolder:getChildren()
	local center = 0
	if cmd.RIGHT_VIEWID == self.m_nViewId then
		center = #vecChildren
	end

	if #cards <= self.m_cardsCount then
		for i = 1, self.m_cardsCount do
			local cbCardData = cards[i]
			local tmp = vecChildren[i]
			if nil ~= tmp then
				tmp:setCardValue(cbCardData)
				tmp:setScale(CARD_LEFT_SCALE)
				local pos = cc.p((i - center) * CARD_X_DIS * CARD_HIDE_SCALE, 0)
				local moveTo = cc.MoveTo:create(0.5 + i / 16, pos)
				local call = cc.CallFunc:create(function ()
					tmp:showCardBack(false)
				end)
				local spa = cc.Spawn:create(moveTo, call)
				tmp:stopAllActions()
				tmp:runAction(spa)
			end
		end
	end
	--变动通知
	if nil ~= self.m_pSelectedListener and nil ~= self.m_pSelectedListener.onCountChange then
		self.m_pSelectedListener:onCountChange( self.m_cardsCount, self )
	end
end

-- 重置
function CardsNode:reSetCards()
	self.m_beginSelectCard = nil
	self.m_endSelectCard = nil

	self:dragCards(self:filterDragSelectCards(false))
	self.m_mapSelectedCards = {}
	self.m_mapDragSelectCards = {}

	self.m_bSuggested = false
end

-- 提示弹出
-- @param[cards] 提示牌
function CardsNode:suggestShootCards( cards )
	if type(cards) ~= "table"  then
		return
	end

	if false == self.m_bTouched then
		self.m_beginSelectCard = nil
		self.m_endSelectCard = nil
	end

	--更新已选择扑克
	print("suggestShootCards m_bSuggested", self.m_bSuggested)
	if true == self.m_bSuggested then
		self:dragCards(self:filterDragSelectCards(false))
		self.m_mapSelectedCards = {}
		self.m_mapDragSelectCards = {}
	end
	
	if false == self.m_bSuggested then
		local count = #cards
		for i = 1, count do
			local cbCardData = cards[i]
			local tmp = self.m_mapCard[cbCardData]
			print(" usgg ,", tmp)
			print(" ccc", cbCardData)
			if nil ~= tmp then
				tmp:setCardDragSelect(true)
				self.m_mapSelectedCards[cbCardData] = tmp
			end
		end
		self:dragCards(self:filterDragSelectCards(false))
	end
	self.m_bSuggested = not self.m_bSuggested
end

function CardsNode:getSelectCards()
	return self.m_tSelectCards
end

function CardsNode:getHandCards(  )
	return self.m_cardsData
end

--
function CardsNode:addCardsHolder(  )
	if nil == self.m_cardsHolder then
		self.m_cardsHolder = cc.Node:create();
		self:addChild(self.m_cardsHolder);
	end
end

function CardsNode:removeAllCards()
	self.m_mapCard = {}
	self.m_vecCard = {}
	if nil ~= self.m_cardsHolder then
		self.m_cardsHolder:removeAllChildren();
	end
	self.m_cardsData = {}
end

function CardsNode:arrangeAllCards( showAnimation, pCallBack )
	local idx = 0;
	if showAnimation then
		local count = self.m_cardsCount
		local cards = self.m_cardsData

		if cmd.MY_VIEWID == self.m_nViewId then
			local center = count * 0.5
			for i = 1, count do
				local cardData = cards[i]
				local tmp = self.m_mapCard[cardData]
				if nil ~= tmp then
					tmp:setLocalZOrder(i)					
					tmp:showSelectEffect(false)
					tmp:setScale(CARD_SHOW_SCALE)

					local pos = cc.p((i - center) * CARD_X_DIS, 0)
					tmp:stopAllActions()
					if tmp:getDispatched() then
						tmp:setPosition(pos)
					else
						tmp:setDispatched(true)

						local moveTo = cc.MoveTo:create(ANI_BEGIN, pos)
						local delay = cc.DelayTime:create(ANI_BEGIN)
						local hideBack = cc.CallFunc:create(function ()
							tmp:showCardBack(false)
							ExternalFun.playSoundEffect("sendcard.wav")
						end)
						local seq = cc.Sequence:create(delay, hideBack)
						local spa = cc.Spawn:create(moveTo, cc.ScaleTo:create(ANI_BEGIN, CARD_SHOW_SCALE), cc.CallFunc:create(function()
							if i == count then
								if nil ~= pCallBack then
									tmp:runAction(pCallBack)
									pCallBack:release()
									self.m_bDispatching = false							
								else
									self.m_bDispatching = false
								end								
							end	
							if nil ~= self.m_pSelectedListener then
								self.m_pSelectedListener.m_cardNum1:setVisible(true)
    							self.m_pSelectedListener.m_cardNum1:setString(string.format("%d", i))
    						end						
						end), seq)

						tmp:runAction(cc.Sequence:create(cc.DelayTime:create(ANI_RATE(idx)) , spa))
						idx = idx + 1
					end
				end
			end
		else
			for i = 1, count do
				local cardData = cards[i]
				cardData = (cardData ~= 0) and cardData or i
				local tmp = self.m_mapCard[cardData]
				if nil ~= tmp then
					tmp:setLocalZOrder(i)					
					tmp:showSelectEffect(false)

					local pos = cc.p(0, 0)
					tmp:stopAllActions()
					if tmp:getDispatched() then
						tmp:setPosition(pos)
					else
						tmp:setDispatched(true)

						local moveTo = cc.MoveTo:create(ANI_BEGIN, pos)
						local delay = cc.DelayTime:create(ANI_BEGIN)
						local showBack = cc.CallFunc:create(function ()
							tmp:showCardBack(true)
							if i == count then
								self.m_bDispatching = false
							end

							--变动通知
							if nil ~= self.m_pSelectedListener and nil ~= self.m_pSelectedListener.onCountChange then
								self.m_pSelectedListener:onCountChange( i, self )
								if cmd.MY_VIEWID ~= self.m_nViewId then
									self.m_pSelectedListener:updateCardsNodeLayout(self.m_nViewId,i,true)
								end
							end
						end)
						local seq = cc.Sequence:create(delay, showBack)
						local spa = cc.Spawn:create(moveTo, cc.ScaleTo:create(ANI_BEGIN, CARD_HIDE_SCALE), seq)

						tmp:runAction(cc.Sequence:create(cc.DelayTime:create(ANI_RATE(idx)) , spa))
						idx = idx + 1
					end
				end
			end
		end
	else
		--整理卡牌位置
		self:reSortCards()
	end
end

function CardsNode:reSortCards()
	local count = self.m_cardsCount
	local cards = self.m_cardsData

	--布局
	if cmd.MY_VIEWID == self.m_nViewId then
		local center = count * 0.5
		for i = 1, count do
			local cardData = cards[i]
			local tmp = self.m_mapCard[cardData]
			if nil ~= tmp then
				tmp:setLocalZOrder(i)
				tmp:setDispatched(true)
				tmp:showSelectEffect(false)
				tmp:showCardBack(false)
				tmp:setScale(CARD_SHOW_SCALE)

				local pos = cc.p((i - center) * CARD_X_DIS, 0)
				tmp:stopAllActions()
				tmp:setPosition(pos)
				if (i == count) then
					self.m_bDispatching = false
				end
			end
		end
	else
		for i = 1, count do
			local cardData = cards[i]
			cardData = (cardData ~= 0) and cardData or i
			local tmp = self.m_mapCard[cardData]
			if nil ~= tmp then
				tmp:setLocalZOrder(i)
				tmp:setDispatched(true)
				tmp:showSelectEffect(false)
				tmp:showCardBack(true)
				tmp:setScale(CARD_HIDE_SCALE)

				local pos = cc.p(0, 0)
				tmp:stopAllActions()
				tmp:setPosition(pos)
				if (i == count) then
					self.m_bDispatching = false
				end
			end
		end

		--变动通知
		if nil ~= self.m_pSelectedListener and nil ~= self.m_pSelectedListener.onCountChange then
			self.m_pSelectedListener:onCountChange( self.m_cardsCount, self)
		end
	end
end

function CardsNode:dragCards( vecCard )
	if type(vecCard) ~= "table"  then
		return
	end

	for k,v in pairs(vecCard) do
		local pos = cc.p(v:getPositionX(), v:getPositionY())
		v:stopAllActions()
		print(" dragCards ", v, v:getCardShoot(), v:getCardData())
		if not v:getCardShoot() then
			local shoot = cc.MoveTo:create(CARD_SHOOT_TIME,cc.p(pos.x,CARD_SHOOT_DIS))
            v:runAction(shoot)
            v:setCardShoot(true)
            if nil ~= self.m_pSelectedListener 
            	and nil ~= self.m_pSelectedListener.onCardsStateChange 
            	and self.m_bClickable then            
                self.m_pSelectedListener:onCardsStateChange(v:getCardData(), true, self)
            end
            self.m_mapSelectedCards[v:getCardData()] = v
        else
        	local shoot = cc.MoveTo:create(CARD_SHOOT_TIME,cc.p(pos.x,0))
            v:runAction(shoot)
            v:setCardShoot(false)
            if nil ~= self.m_pSelectedListener 
            	and nil ~= self.m_pSelectedListener.onCardsStateChange 
            	and self.m_bClickable then            
                self.m_pSelectedListener:onCardsStateChange(v:getCardData(), false, self)
            end
            self.m_mapSelectedCards[v:getCardData()] = nil
		end
	end
	--print("---- self.m_nViewId ----",self.m_nViewId,self.m_bShowCard)
	local tmpShow = (cmd.MY_VIEWID == self.m_nViewId) and false or not self.m_bShowCard
	local vecChildren = self.m_cardsHolder:getChildren()
	for k,v in pairs(vecChildren) do
		v:showCardBack(tmpShow)
		v:setCardDragSelect(false)
		v:showSelectEffect(false)
	end

	self.m_tSelectCards = {}
	for k,v in pairs(self.m_mapSelectedCards) do
		if nil ~= v and nil ~= v.getCardData then
			table.insert(self.m_tSelectCards, v:getCardData())
		end		
	end
	self.m_tSelectCards = GameLogic:SortCardList(self.m_tSelectCards, #self.m_tSelectCards, 0)
	--dump(self.m_tSelectCards, "---------------dragCards m_tSelectCards------------", 6)
	--通知
	if nil ~= self.m_pSelectedListener and nil ~= self.m_pSelectedListener.onSelectedCards then
		self.m_pSelectedListener:onSelectedCards(self.m_tSelectCards, self)
	end

	self.m_mapDragSelectCards = {}
end

--触摸操控
function CardsNode:filterCard(flag, touchPoint)
	local tmpSel = {}
	for k,v in pairs(self.m_mapCard) do
		local locationInNode = v:convertToNodeSpace(touchPoint)
		local rec = cc.rect(0, 0, v:getContentSize().width, v:getContentSize().height)
		if cc.rectContainsPoint(rec, locationInNode) then
	        table.insert(tmpSel, v)
	    end
	end

	if 0 == #tmpSel then
		return nil
	end

	table.sort(tmpSel,function( a,b )
		return a:getLocalZOrder() < b:getLocalZOrder()
	end)

	if kHIGHEST == flag then
		return tmpSel[#tmpSel]
	else
		return tmpSel[1]
	end
end

function CardsNode:inTouchAreaCards( touchRect )
	local tmpMap = {}
	for k,v in pairs(self.m_mapCard) do
		if nil ~= v then
			local locationInNode = cc.p(v:getPositionX(), v:getPositionY())
			local anchor = v:getAnchorPoint()
			local tmpSize = v:getContentSize()

			local ori = cc.p(locationInNode.x - tmpSize.width * anchor.x, locationInNode.y - tmpSize.height * anchor.y)
			local rect = cc.rect(ori.x, ori.y, tmpSize.width , tmpSize.height)
			if cc.rectIntersectsRect(rect, touchRect) and nil ~= v.getCardData then
		        tmpMap[v:getCardData()] = v
		    end
		end		 
	end

	return self:filterDragSelectCards(true, tmpMap, true)
end

function CardsNode:makeTouchRect( endTouch )
	local movePoint = endTouch
	local m_beginTouchPoint = self.m_beginTouchPoint

	--判断拖动方向(左右)
	local toRight = (m_beginTouchPoint.x < movePoint.x) and true or false
	--判断拖动方向(上下)
	local toTop = (m_beginTouchPoint.y < movePoint.y) and true or false
	self.m_dragMoveDir = (toRight == true) and kMoveToRight or kMoveToLeft

	if toRight and toTop then
		return cc.rect(m_beginTouchPoint.x, m_beginTouchPoint.y, movePoint.x - m_beginTouchPoint.x, movePoint.y - m_beginTouchPoint.y)
	elseif toRight and not toTop then
		return cc.rect(m_beginTouchPoint.x, movePoint.y, movePoint.x - m_beginTouchPoint.x, m_beginTouchPoint.y - movePoint.y)
	elseif not toRight and toTop then
		return cc.rect(movePoint.x, m_beginTouchPoint.y, m_beginTouchPoint.x - movePoint.x, movePoint.y - m_beginTouchPoint.y)
	elseif not toRight and not toTop then
		return cc.rect(movePoint.x, movePoint.y, m_beginTouchPoint.x - movePoint.x, m_beginTouchPoint.y - movePoint.y)
	end
	return cc.rect(0, 0, 0, 0)
end

function CardsNode:filterDragSelectCards( bFilter, cards, bMap)
	local lowOrder = self:getLowOrder()
	local hightOrder = self:getHightOrder()
	bMap = bMap or false

	--过滤对象
	local tmpMap = {}
	if nil == cards or type(cards) ~= "table" or 0 == table.nums(cards) then
		--合并
		for k,v in pairs(self.m_mapSelectedCards) do
			if nil ~= v and nil ~= v.getCardData then
				tmpMap[v:getCardData()] = v
			end			
		end
		for k,v in pairs(self.m_mapDragSelectCards) do
			if nil ~= v and nil ~= v.getCardData then
				tmpMap[v:getCardData()] = v
			end	
		end
	else
		tmpMap = cards
	end

	local tmp = {}
	if bMap then
		if bFilter then
			for k,v in pairs(tmpMap) do
				if v:getLocalZOrder() >= lowOrder and v:getLocalZOrder() <= hightOrder then
					tmp[v:getCardData()] = v
				end			
			end
		else
			for k,v in pairs(tmpMap) do
				tmp[v:getCardData()] = v
			end
		end
	else
		if bFilter then
			for k,v in pairs(tmpMap) do
				if v:getLocalZOrder() >= lowOrder and v:getLocalZOrder() <= hightOrder then
					table.insert(tmp, v)
				end			
			end
		else
			for k,v in pairs(tmpMap) do
				table.insert(tmp, v)
			end
		end
	end	
	return tmp
end

function CardsNode:setCardsCount(cbCount)
	self.m_cardsCount = cbCount
end

function CardsNode:getCardsCount()
	local count = self.m_cardsCount
	return count
end

function CardsNode:getLowOrder()
	local beginOrder = (self.m_beginSelectCard ~= nil) and self.m_beginSelectCard:getLocalZOrder() or MIN_DRAW_ORDER
	local endOrder = nil
	if nil ~= self.m_endSelectCard then
		endOrder = self.m_endSelectCard:getLocalZOrder()
	end
	if kMoveToLeft == self.m_dragMoveDir then
		endOrder = endOrder or MIN_DRAW_ORDER
	else
		endOrder = endOrder or MAX_DRAW_ORDER
	end
	return math.min(beginOrder, endOrder)
end

function CardsNode:getHightOrder()
	local beginOrder = (self.m_beginSelectCard ~= nil) and self.m_beginSelectCard:getLocalZOrder() or MIN_DRAW_ORDER
	local endOrder = nil
	if nil ~= self.m_endSelectCard then
		endOrder = self.m_endSelectCard:getLocalZOrder()
	end
	if kMoveToLeft == self.m_dragMoveDir then
		endOrder = endOrder or MAX_DRAW_ORDER
	else
		endOrder = endOrder or MIN_DRAW_ORDER
	end
	return math.max(beginOrder, endOrder)
end
--触摸操控
function CardsNode:setCardsBlack(vecCard)
	for ke,va in pairs (vecCard) do

		local cardData = vecCard[ke]

		for k,v in pairs (self.m_mapCard) do
			local pCardSprite = self.m_mapCard[k]
			local handCardData = v:getCardData()
			print("handCardData ",handCardData)
			if cardData == handCardData then
				pCardSprite.m_bIsBlack = true
				pCardSprite:showSelectEffect(true)
				break
			end
		end	
	end
end

return CardsNode