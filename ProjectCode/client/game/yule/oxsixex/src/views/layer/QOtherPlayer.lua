--region *.lua
--Date
--此文件由[BabeLua]插件自动生成



--endregion
local QBasePlayer = import(".QBasePlayer")
local QOtherPlayer = class("QOtherPlayer",QBasePlayer)
local cmd = appdf.req(appdf.GAME_SRC.."yule.oxsixex.src.models.CMD_Game")
local CardSprite = appdf.req(appdf.GAME_SRC.."yule.oxsixex.src.views.bean.CardSprite")
local NGResources = appdf.req(appdf.GAME_SRC.."yule.oxsixex.src.views.NGResources")
function QOtherPlayer:ctor(viewID,vpos)
    QOtherPlayer.super.ctor(self)

    if viewID then
        self.m_nViewID_ = viewID
    end

    if vpos then
        self.vHeadPos = vpos
    end

    self:initContain()
    self:initBackAct()
end

function QOtherPlayer:playSendCardAction(cbCardData)
    local function removeThis()
        local x = self.m_pNodeContain_:getPositionX() + 65.0
        local y = self.m_pNodeContain_:getPositionY() + 160.0
  
        for i,v in pairs(self.m_pImageBack_) do
            v:setPosition(x,y)
            v:setVisible(false)
        end

        self:showHandCardUI(cbCardData)
    end

    local posX,posY = 0,0
    for i,v in pairs(self.m_pImageBack_) do
        v:setVisible(true)
        posX = self.m_pNodeContain_:getPositionX() + (i-1)*26 + 2
        posY = self.m_pNodeContain_:getPositionY() + 2 
       
        if i==cmd.MAX_COUNT then
            v:runAction(cc.Sequence:create(cc.MoveTo:create(1.0,cc.p(posX,posY)),cc.CallFunc:create(removeThis)))
        else
            v:runAction(cc.Sequence:create(cc.MoveTo:create(1.0,cc.p(posX,posY))))
        end
    end
end

function QOtherPlayer:showHandCardUI(cbCardData)
    self.m_pNodeContain_:removeAllChildren()
    local pTexture  = cc.Director:getInstance():getTextureCache():addImage(NGResources.GameRes.sDeskCardPath)
    local pSprite = nil
    local posX = 0
    for i=1,cmd.MAX_COUNT do
        local cardRect = cc.rect(2*90.0,4*119.0,90.0,119.0);
	    pSprite = cc.Sprite:createWithTexture(pTexture,cardRect)
        pSprite:setAnchorPoint(display.LEFT_BOTTOM)
        posX = 2 + (i-1)*26.0
        pSprite:setPosition(cc.p(posX,2.0))
        self.m_pNodeContain_:addChild(pSprite)
    end
end

function QOtherPlayer:showDeskCardUI(cbCardData,bOx)
    self.m_pNodeContain_:removeAllChildren()
    
    local pTexture  = cc.Director:getInstance():getTextureCache():addImage(NGResources.GameRes.sDeskCardPath)
    local pNode = nil
    local posX = 0
    local posY = 0
    local offerX = 0
    local tag = 2
    for i,v in pairs(cbCardData) do
        pNode = CardSprite:create(v,pTexture,CardSprite.CARD_TYPE_DESK)
        posX = 2 + (i-1)*26.0
        posY = 2.0
        if bOx ~=0 and bOx~= 255 then
            if self.m_nViewID_ == cmd.VIEW_MIDDLE_RIGHT or self.m_nViewID_ == cmd.VIEW_TOP_RIGHT  then
                offerX = 72.0
            else
                offerX = 0
            end
            posX = posX + offerX
            if i>=4 then
                posX = 2.0 + 13.0 + (i-4)*26.0 + offerX
                posY = 2.0 + 50.0
                tag = 1
            end
        end
        pNode:setPosition(cc.p(posX,posY))
        self.m_pNodeContain_:addChild(pNode,tag)
    end
end

return QOtherPlayer