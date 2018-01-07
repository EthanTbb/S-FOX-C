--region *.lua
--Date
--此文件由[BabeLua]插件自动生成



--endregion
local QBasePlayer = class("QBasePlayer",function ()
	-- body
	return cc.Layer:create()
end)

local cmd = appdf.req(appdf.GAME_SRC.."yule.oxsixex.src.models.CMD_Game")
local CardSprite = appdf.req(appdf.GAME_SRC.."yule.oxsixex.src.views.bean.CardSprite")
local QScrollText = appdf.req(appdf.GAME_SRC.."yule.oxsixex.src.views.bean.QScrollText")
local NGResources = appdf.req(appdf.GAME_SRC.."yule.oxsixex.src.views.NGResources")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.oxsixex.src.models.GameLogic")

function QBasePlayer:ctor()
    self.m_nViewID_ = -1
    self.m_pImageHand_ = {}
    self.m_tHandCardData_ = {}
    self.m_pNodeType_ = nil
    self.m_pNodeContain_ = nil
    self.m_pTextJs_ = nil
    self.m_pImageBack_ = {}
    self.m_pImageTipsCard_ = nil
    self.vHeadPos = nil
    self.m_pImageChat_ = nil
end

function QBasePlayer:setViewID(id)
    self.m_nViewID_ = id
end

function QBasePlayer:initContain()
    if self.m_nViewID_ == cmd.MY_VIEW_CHAIRID then
        return
    end

    self.m_pNodeContain_ = cc.Node:create()
    self.m_pNodeContain_:setContentSize(cc.size(220.0,140.0))
    self:addChild(self.m_pNodeContain_)
    if self.m_nViewID_ == cmd.VIEW_TOP_MIDDLE  then
        self.m_pNodeContain_:setPosition(cc.p(self.vHeadPos.x + 70.0,self.vHeadPos.y - 70))
    elseif self.m_nViewID_ == cmd.VIEW_TOP_LEFFT then
        self.m_pNodeContain_:setPosition(cc.p(self.vHeadPos.x + 70.0,self.vHeadPos.y - 70))
    elseif self.m_nViewID_ == cmd.VIEW_MIDDLE_LEFFT  then
        self.m_pNodeContain_:setPosition(cc.p(self.vHeadPos.x + 70.0,self.vHeadPos.y - 70))
    elseif self.m_nViewID_ == cmd.VIEW_MIDDLE_RIGHT then
        self.m_pNodeContain_:setPosition(cc.p(self.vHeadPos.x - 290.0,self.vHeadPos.y - 70))
    elseif self.m_nViewID_ == cmd.VIEW_TOP_RIGHT then
        self.m_pNodeContain_:setPosition(cc.p(self.vHeadPos.x - 290.0,self.vHeadPos.y - 70))
    end
end

function QBasePlayer:initBackAct()
    local pTexture  = cc.Director:getInstance():getTextureCache():addImage(NGResources.GameRes.sDeskCardPath)
    local pSprite = nil
    local x = display.width/2 - 45.0
    local y = 200
    if self.m_nViewID_ ~= cmd.MY_VIEW_CHAIRID then
        x = self.m_pNodeContain_:getPositionX() + 65.0
        y = self.m_pNodeContain_:getPositionY() + 160.0
    end
    for i=1,cmd.MAX_COUNT do
        local cardRect = cc.rect(2*90.0,4*119.0,90.0,119.0);
	    pSprite = cc.Sprite:createWithTexture(pTexture,cardRect)
        pSprite:setAnchorPoint(display.LEFT_BOTTOM)
        pSprite:setPosition(x,y)
        pSprite:setVisible(false)
        self:addChild(pSprite)
        table.insert(self.m_pImageBack_,pSprite)
    end
end

--显示牛几
function QBasePlayer:showCardTypeUI(iValue,iType)
    if self.m_pNodeType_ then
        self.m_pNodeType_:removeAllChildren()
    else
        self.m_pNodeType_ = cc.Node:create()
        self:addChild(self.m_pNodeType_,10)
        if self.m_nViewID_ == cmd.VIEW_TOP_MIDDLE  then
            self.m_pNodeType_:setPosition(cc.p(self.vHeadPos.x + 180.0,self.vHeadPos.y - 50))
        elseif self.m_nViewID_ == cmd.VIEW_TOP_LEFFT then
            self.m_pNodeType_:setPosition(cc.p(self.vHeadPos.x + 180.0,self.vHeadPos.y - 50))
        elseif self.m_nViewID_ == cmd.VIEW_MIDDLE_LEFFT  then
            self.m_pNodeType_:setPosition(cc.p(self.vHeadPos.x + 180.0,self.vHeadPos.y - 50))
        elseif self.m_nViewID_ == cmd.MY_VIEW_CHAIRID then
            self.m_pNodeType_:setPosition(cc.p(675.0,280.0))
        elseif self.m_nViewID_ == cmd.VIEW_MIDDLE_RIGHT then
            self.m_pNodeType_:setPosition(cc.p(self.vHeadPos.x - 170.0,self.vHeadPos.y - 50))
        elseif self.m_nViewID_ == cmd.VIEW_TOP_RIGHT then
            self.m_pNodeType_:setPosition(cc.p(self.vHeadPos.x - 170.0,self.vHeadPos.y - 50))
        end
    end

    local pSprite1 = nil
    local pSprite2 = nil
    local pGameViewObj = self:getParent()
    if pGameViewObj then
        pSprite1,pSprite2 = pGameViewObj:getCardTypeSprite(iValue,iType)
    end

    if pSprite1 and pSprite2 then
        local cSize = pSprite1:getContentSize()
        self.m_pNodeType_:setContentSize(cc.size(cSize.width*2,cSize.height))
        self.m_pNodeType_:addChild(pSprite1)
        self.m_pNodeType_:addChild(pSprite2)
        --pSprite1:setAnchorPoint(display.LEFT_BOTTOM)
        --pSprite2:setAnchorPoint(display.LEFT_BOTTOM)
        pSprite1:setPosition(cc.p(-cSize.width/2,0))
        pSprite2:setPosition(cc.p(cSize.width/2,0))
    elseif pSprite1 then
        local cSize = pSprite1:getContentSize()
        self.m_pNodeType_:setContentSize(cc.size(cSize.width*2,cSize.height))
        self.m_pNodeType_:addChild(pSprite1)
        pSprite1:setPosition(cc.p(0,0))
    end
end

function QBasePlayer:showJskUI(iScore)
    if self.m_pTextJs_== nil then
        self.m_pTextJs_ = ccui.TextAtlas:create()
        self:addChild(self.m_pTextJs_,9)

        if self.m_nViewID_ == cmd.VIEW_MIDDLE_RIGHT or self.m_nViewID_ == cmd.VIEW_TOP_RIGHT then
            self.m_pTextJs_:setAnchorPoint(display.RIGHT_BOTTOM)
            self.m_pTextJs_:setPosition(cc.p(self.vHeadPos.x - 80.0,self.vHeadPos.y))
        else
            self.m_pTextJs_:setAnchorPoint(display.LEFT_BOTTOM)
            self.m_pTextJs_:setPosition(cc.p(self.vHeadPos.x + 80.0,self.vHeadPos.y))
        end
    else
        self.m_pTextJs_:setVisible(true)
    end
    if iScore >=0 then
        self.m_pTextJs_:setProperty("/" .. iScore, NGResources.GameRes.sTextAddNum, 19, 23, "/")
    else
        self.m_pTextJs_:setProperty("/" .. iScore, NGResources.GameRes.sTextSubNum, 19, 23, "/")
    end
end

function QBasePlayer:showTipsOpenCard(bShow)
    if self.m_nViewID_ == cmd.MY_VIEW_CHAIRID then
        return
    end

    if self.m_pImageTipsCard_ then
        self.m_pImageTipsCard_:setVisible(bShow)
    else
        if bShow then
            self.m_pImageTipsCard_ = ccui.ImageView:create(NGResources.GameRes.sImageOpenCardPath,ccui.TextureResType.plistType)
            self:addChild(self.m_pImageTipsCard_,11)

            if self.m_nViewID_ ~= cmd.MY_VIEW_CHAIRID  then
                self.m_pImageTipsCard_:setPosition(cc.p(self.vHeadPos.x,self.vHeadPos.y-105.0))
            end
        end
    end
end

function QBasePlayer:removeCardTypeUI()
    if self.m_pNodeType_ then
        self.m_pNodeType_:removeAllChildren()
    end
end

function QBasePlayer:removeHandCardUI()
    for i,v in pairs(self.m_pImageHand_) do
        v:removeFromParent()
        v = nil
    end

    self.m_pImageHand_ = {}
    self.m_tHandCardData_ = {}
end

function QBasePlayer:removeDeskCardUI()
    if self.m_pNodeContain_ then
        self.m_pNodeContain_:removeAllChildren()
    end
end

function QBasePlayer:removeJskUI()
    if self.m_pTextJs_ then 
        self.m_pTextJs_:setVisible(false)
    end
end

function QBasePlayer:showChat(strChat)
    if self.m_pImageChat_ == nil then
        if self.m_nViewID_ == cmd.VIEW_MIDDLE_RIGHT or self.m_nViewID_ == cmd.VIEW_TOP_RIGHT then
            self.m_pImageChat_ = ccui.ImageView:create(NGResources.GameRes.sChatBj2,ccui.TextureResType.plistType)
            self.m_pImageChat_:setAnchorPoint(display.RIGHT_BOTTOM)
        else
            self.m_pImageChat_ = ccui.ImageView:create(NGResources.GameRes.sChatBj1,ccui.TextureResType.plistType)
            self.m_pImageChat_:setAnchorPoint(display.LEFT_BOTTOM)
        end
        self.m_pImageChat_:setPosition(cc.p(self.vHeadPos.x,self.vHeadPos.y + 55.0))
        self:addChild(self.m_pImageChat_,20)

        local pChat = QScrollText:create(strChat, 22.0, 7)
	    pChat:setAnchorPoint(display.LEFT_CENTER)
	    pChat:setPosition(cc.p(9.0, 24.0))
	    self.m_pImageChat_:addChild(pChat,1,1)
    else
        local pChat = self.m_pImageChat_:getChildByTag(1)
        if pChat then
            pChat:showStr(strChat)
        end

        self.m_pImageChat_:setVisible(true)
    end


end

function QBasePlayer:removeUI()
    self:removeCardTypeUI()
    self:removeHandCardUI()
    self:removeDeskCardUI()
    self:removeJskUI()
end


return QBasePlayer

