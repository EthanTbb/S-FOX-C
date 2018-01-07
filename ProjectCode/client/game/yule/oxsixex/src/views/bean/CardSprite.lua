--region *.lua
--Date
--此文件由[BabeLua]插件自动生成



--endregion
local CardSprite = class("CardSprite",cc.Node)
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.oxsixex.src.models.GameLogic")
CardSprite.CARD_TYPE_HNAD = "HAND"
CardSprite.CARD_TYPE_DESK = "DESK"
function CardSprite:ctor(cardData,texture,iType)
    self.m_nCardColor_ = GameLogic.GetCardColor(cardData)
    self.m_nCardValue_ = GameLogic.GetCardValue(cardData)
    print("self.m_nCardColor_===" .. self.m_nCardColor_  ,"self.m_nCardValue_===," .. self.m_nCardValue_)
    self.m_nCardLogicValue_ = GameLogic.GetCardLogicValue(cardData)
    self.m_bSelect_ = false
    if self.m_nCardValue_ == 0 then
        --牌背面
        return
    end
    local fWidth,fHeight = 0,0
    if iType == CardSprite.CARD_TYPE_HNAD then
        fWidth = 145.0
        fHeight = 161.0
    else
        fWidth = 90.0
        fHeight = 119.0
    end
    local x = (self.m_nCardValue_-1)*fWidth
	local y = self.m_nCardColor_*fHeight
    if self.m_nCardValue_ == 14  then
        x = fWidth
    elseif self.m_nCardValue_ == 15 then
        x = 0
    end

    local cardRect = cc.rect(x,y,fWidth,fHeight);
	self.sprite_card = cc.Sprite:createWithTexture(texture,cardRect)
    self.sprite_card:setAnchorPoint(display.LEFT_BOTTOM)
    self.sprite_card:setPosition(display.left_bottom)
	self:addChild(self.sprite_card)

    self:setContentSize(self.sprite_card:getContentSize())
end

function CardSprite:GetCardColor()
    return self.m_nCardColor_
end

function CardSprite:GetCardLogicValue()
    return self.m_nCardLogicValue_
end

function CardSprite:isTouchCard(pos)
	if self.sprite_card then
        return cc.rectContainsPoint(self:getBoundingBox(),pos)
	end
	return false
end

function CardSprite:getSelectBool()
    return self.m_bSelect_
end

function CardSprite:setSelectCard(bSelect)
    if true==bSelect then
        if self.m_bSelect_ == true then
            self:setPositionY(10)
            self.m_bSelect_ = false
        else
            self:setPositionY(10+self.sprite_card:getContentSize().height/2)
            self.m_bSelect_ = true
        end
    else
        self:setPositionY(10)
        self.m_bSelect_ = false
    end

    --print("self:getPositionY====" .. self:getPositionY())
end

return CardSprite
