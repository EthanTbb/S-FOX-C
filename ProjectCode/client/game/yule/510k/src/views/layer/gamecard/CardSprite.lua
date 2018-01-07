--
-- Author: zhong
-- Date: 2016-06-27 11:36:40
--
local CardSprite = class("CardSprite", cc.Sprite);

--纹理宽高
local CARD_WIDTH = 158
local CARD_HEIGHT = 208
local BACK_Z_ORDER = 2

------
--set/get
function CardSprite:setDispatched( var )
	self.m_bDispatched = var;
end

function CardSprite:getDispatched(  )
	if nil ~= self.m_bDispatched then
		return self.m_bDispatched;
	end
	return false;
end

function CardSprite:getCardData()
	return self.m_cardData
end

--拖动选择
function CardSprite:setCardDragSelect( var )
	self.m_bDragSelect = var
end

function CardSprite:getCardDragSelect()
	return self.m_bDragSelect
end

--弹出
function CardSprite:setCardShoot( var )
	self.m_bShoot = var
end

function CardSprite:getCardShoot()
	return self.m_bShoot
end
------

function CardSprite:ctor()
	self.m_cardData = 0
	self.m_cardValue = 0
	self.m_cardColor = 0
	self.m_bDispatched = false
	self.m_bDragSelect = false
	self.m_bShoot = false
	self.m_nCardWidth = 0
	self.m_nCardHeight = 0
	self.m_bIsBlack = false -- 是否一直暗
end

--创建卡牌
function CardSprite:createCard( cbCardData, tagParam )
	local sp = CardSprite.new();
	tagParam = tagParam or {}
	sp.m_nCardWidth = tagParam._width or CARD_WIDTH
	sp.m_nCardHeight = tagParam._height or CARD_HEIGHT
	sp.m_strCardFile = tagParam._file or "card_res/card.png"

	local tex = cc.Director:getInstance():getTextureCache():getTextureForKey(sp.m_strCardFile);
	if nil ~= sp and nil ~= tex and sp:initWithTexture(tex, tex:getContentSize()) then
		sp.m_cardData = cbCardData;
		sp.m_cardValue = yl.POKER_VALUE[cbCardData] --math.mod(cbCardData, 16)--bit:_and(cbCardData, 0x0F)
		sp.m_cardColor = yl.CARD_COLOR[cbCardData] --math.floor(cbCardData / 16)--bit:_rshift(bit:_and(cbCardData, 0xF0), 4)

		sp:updateSprite();
		--扑克背面
		sp:createBack();

		return sp;
	end
	return nil;
end

--设置卡牌数值
function CardSprite:setCardValue( cbCardData )
	self.m_cardData = cbCardData;
	self.m_cardValue = yl.POKER_VALUE[cbCardData]  --math.mod(cbCardData, 16) --bit:_and(cbCardData, 0x0F)
	self.m_cardColor = yl.CARD_COLOR[cbCardData]  --math.floor(cbCardData / 16) --bit:_rshift(bit:_and(cbCardData, 0xF0), 4)

	self:updateSprite();
end

--更新纹理资源
function CardSprite:updateSprite(  )
	local m_cardData = self.m_cardData
	local m_cardValue = self.m_cardValue
	local m_cardColor = self.m_cardColor
	local c_width = self.m_nCardWidth
	local c_height = self.m_nCardHeight

	self:setTag(m_cardData);

	local rect = cc.rect((m_cardValue - 1) * c_width, m_cardColor * c_height, c_width, c_height);
	if 0 ~= m_cardData then
		rect = cc.rect((m_cardValue - 1) * c_width, m_cardColor * c_height, c_width, c_height);
		if 0x4F == m_cardData then
			rect = cc.rect(0, 4 * c_height, c_width, c_height);
		elseif 0x4E == m_cardData then
			rect = cc.rect(c_width, 4 * c_height, c_width, c_height);
		end
	else
		--使用背面纹理区域
		rect = cc.rect(0, 4 * c_height, c_width, c_height);
	end
	self:setTextureRect(rect);
end

--显示扑克背面
function CardSprite:showCardBack( var )
	if nil ~= self.m_spBack then
		self.m_spBack:setVisible(var);
	end	
end

--扑克选择效果
function CardSprite:showSelectEffect(bSelect)
	local c_width = self.m_nCardWidth
	local c_height = self.m_nCardHeight
	if true == self.m_bIsBlack then
		bSelect = true
	end
	if nil == self.m_pMask then
		self.m_pMask = cc.Sprite:create("card_res/card.png")
		if nil ~= self.m_pMask then
			self.m_pMask:setColor(cc.BLACK)
			self.m_pMask:setOpacity(100)
			self.m_pMask:setTextureRect(cc.rect(2 * c_width, 0 * c_height, c_width, c_height))
			self.m_pMask:setPosition(c_width * 0.5, c_height * 0.5)
			self:addChild(self.m_pMask)
		end
	end

	if nil ~= self.m_pMask then
		self.m_pMask:setVisible(bSelect)
	end	
end


--创建背面
function CardSprite:createBack( )
	local c_width = self.m_nCardWidth
	local c_height = self.m_nCardHeight

	local tex = cc.Director:getInstance():getTextureCache():getTextureForKey(self.m_strCardFile);
	--纹理区域
	local rect = cc.rect(0 * c_width, 4 * c_height, c_width, c_height);

	local cardSize = self:getContentSize();
    local m_spBack = cc.Sprite:createWithTexture(tex, rect);
    m_spBack:setPosition(cardSize.width * 0.5, cardSize.height * 0.5);
    m_spBack:setVisible(false);
    self:addChild(m_spBack);
    m_spBack:setLocalZOrder(BACK_Z_ORDER);
    self.m_spBack = m_spBack;
end

return CardSprite;