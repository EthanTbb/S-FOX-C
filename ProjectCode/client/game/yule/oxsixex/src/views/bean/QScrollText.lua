local QScrollText = class("QScrollText", cc.Node)

function QScrollText:ctor(strContent, nTextSize, nTextNum)
    local pContLayer = ccui.Layout:create()
    local pScrollView = cc.ScrollView:create(cc.c4b(128, 64, 0, 255))
    self.m_size_ = cc.size(nTextNum * nTextSize, nTextSize)
    local function ScrollViewDidScroll()
        cclog("ScrollViewDidZoom")
    end
    local function ScrollViewDidZoom()
        cclog("ScrollViewDidZoom")
    end

    if nil ~= pScrollView and nil ~= pContLayer then
        pScrollView:setTouchEnabled(false)
        pScrollView:setAnchorPoint(cc.p(0, 0))
        pScrollView:setViewSize(cc.size(nTextNum * nTextSize, nTextSize))
        pScrollView:setContentSize(cc.size(nTextNum * nTextSize, nTextSize))
        pScrollView:setDirection(cc.SCROLLVIEW_DIRECTION_HORIZONTAL)
        pScrollView:setPosition(cc.p(0, 0))
        pScrollView:setContainer(pContLayer)
        pScrollView:registerScriptHandler(ScrollViewDidScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
        pScrollView:registerScriptHandler(ScrollViewDidZoom, cc.SCROLLVIEW_SCRIPT_ZOOM)
    end
    self:addChild(pScrollView)
    
    self.m_pLable_ = cc.Label:createWithSystemFont("", "Arial-BoldMT", nTextSize)
    self.m_pLable_:setAnchorPoint(cc.p(0, 0.5))
    self.m_pLable_:setPosition(cc.p(0, nTextSize / 2.0))
    pContLayer:addChild(self.m_pLable_)

    self.m_pContLayer_  = pContLayer
    self.m_pScrollView_ = pScrollView
    self.m_pSpriteBq_ = nil
    self:showStr(strContent)
    
end

function QScrollText:showStr(strContent)
    if strContent.wItemIndex then
        if self.m_pLable_ then
            self.m_pLable_:setString("")
        end
       self:showBq(strContent.wItemIndex)
    else
        if self.m_pSpriteBq_ then
            self.m_pSpriteBq_:setVisible(false)
        end
        self:showText(strContent.szChatString)
    end
end

function QScrollText:showBq(idx)
    local str = string.format("e(%d).png", idx )
    local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(str)
    if frame == nil then
        print(" QScrollText:showBq...error")
        return 
    end

    if self.m_pSpriteBq_ then
        self.m_pSpriteBq_:setSpriteFrame(frame)
        self.m_pSpriteBq_:setVisible(true)
    else
        self.m_pSpriteBq_ = cc.Sprite:createWithSpriteFrame(frame)
        self.m_pSpriteBq_:setAnchorPoint(display.LEFT_CENTER)
        self.m_pSpriteBq_:setPosition(cc.p(0,self.m_size_.height / 2.0))
        self:addChild(self.m_pSpriteBq_,1)
        self.m_pSpriteBq_:setScale(0.8)

        self:setContentSize(cc.size(self.m_size_.width, self.m_size_.height))
    end

    local delay = cc.DelayTime:create(2.0)
    local seq = cc.Sequence:create(delay,cc.CallFunc:create(handler(self,self.actionDone)))
    self.m_pSpriteBq_:runAction(seq)
 end

function QScrollText:showText(strContent)
    if self.m_pLable_ == nil then
        return
    end
    self.m_pLable_:setString(strContent)
    local fMoveX = self.m_pLable_:getContentSize().width - self.m_size_.width

    local function actionDone(tar)
        local pObj = self:getParent()
        if pObj then
            pObj:setVisible(false)
        end

        if tar then
            self.m_pContLayer_:setPositionX(self.m_pContLayer_:getPositionX() + fMoveX)
        end
    end

    self.m_pContLayer_:setPositionX(0)
    self.m_pContLayer_:stopAllActions()
    if fMoveX > 0 then
        self:setContentSize(cc.size(self.m_size_.width, self.m_size_.height))
        local fSpeed = (fMoveX / self.m_size_.height)/2.0
        local moveBy = cc.MoveBy:create(fSpeed, cc.p(- fMoveX, 0))
        local moveBy_back = cc.MoveBy:create(0.03, cc.p(fMoveX, 0))
        local delay = cc.DelayTime:create(1.0)
        local seq = cc.Sequence:create(delay, moveBy, delay:clone(), cc.CallFunc:create(handler(self,self.actionDone),{dis=fMoveX}))
        self.m_pContLayer_:runAction(seq)
    else
        self.m_pScrollView_:setContentSize(cc.size(self.m_pLable_:getContentSize().width, self.m_size_.height))
        self:setContentSize(cc.size(self.m_pLable_:getContentSize().width, self.m_size_.height))
        local delay = cc.DelayTime:create(2.0)
        local seq = cc.Sequence:create(delay,cc.CallFunc:create(handler(self,self.actionDone)))
        self.m_pContLayer_:runAction(seq)
    end
end

function QScrollText:actionDone(node,tar)
    local pObj = self:getParent()
    if pObj then
        pObj:setVisible(false)
    end

    if tar then
        self.m_pContLayer_:setPositionX(self.m_pContLayer_:getPositionX() + tar.dis)
    end
end

return QScrollText


