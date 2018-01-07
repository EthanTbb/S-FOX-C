--
-- Author: zhong
-- Date: 2016-11-11 09:59:23
--
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. "ClipText")

local module_pre = "game.yule.510k.src"
local cmd = appdf.req(module_pre .. ".models.CMD_Game")

local ResultLayer = class("ResultLayer", cc.Layer)

local BT_CONTINUE = 101
local BT_QUIT = 102
local BT_CLOSE = 103

function ResultLayer.getTagSettle()
    return 
    {
        -- 用户名
        m_userName = "",
        -- 文本颜色
        nameColor = cc.c4b(255,255,255,255),
        -- 计算游戏币
        m_settleCoin = "",
        -- 文本颜色
        coinColor = cc.c4b(255,255,255,255),       
        -- 特殊标志
        m_cbFlag = cmd.kFlagDefault,
    }
end

function ResultLayer.getTagGameResult()
    return
    {
        -- 结果
        enResult = cmd.kDefault,
        -- 结算
        settles = 
        {
            ResultLayer.getTagSettle(),
            ResultLayer.getTagSettle(),
            ResultLayer.getTagSettle(),
        } 
    }
end

function ResultLayer:ctor( parent,rs)
    self.m_parent = parent
    self.m_rs = rs
    self.tabClipText = {}
    --注册node事件
    ExternalFun.registerTouchEvent(self, true)

    --加载csb资源
    local csbNode = ExternalFun.loadCSB("game_res/ResultLayer.csb", self)

    local bg = csbNode:getChildByName("bg")
    self.m_spBg = bg

    -- 结算精灵
    self.m_spResultSp = bg:getChildByName("spResult")

    local function btnEvent( sender, eventType )
        if eventType == ccui.TouchEventType.ended then
            self:onBtnClick(sender:getTag(), sender)
        end
    end
    -- 继续按钮
    local btn = bg:getChildByName("bt_again")
    btn:setTag(BT_CONTINUE)
    btn:addTouchEventListener(btnEvent)

    -- 退出按钮
    btn = bg:getChildByName("bt_exit")
    btn:setTag(BT_QUIT)
    btn:addTouchEventListener(btnEvent)

    for i = 1,cmd.PLAYER_COUNT do
        local viewId = self.m_parent._scene:SwitchViewChairID(i - 1)
        local nickName = self.m_spBg:getChildByName(string.format("nickName_%d", viewId))
        nickName:setVisible(false)
        self.tabClipText[viewId] = ClipText:createClipText(cc.size(195, 30), "xx", nil, 30)
        self.tabClipText[viewId]:setAnchorPoint(cc.p(0.5, 0.5))
        self.tabClipText[viewId]:setPosition(cc.p(nickName:getPositionX(), nickName:getPositionY()))
        self.m_spBg:addChild(self.tabClipText[viewId])
        local userItem = self.m_parent.m_historyUseItem[viewId]
        if nil == userItem then
             userItem = self.m_parent.m_tabUserItemCopy[viewId]
        end
        if nil ~= userItem then
             self.tabClipText[viewId]:setString(userItem.szNickName)
        else
            self.tabClipText[viewId]:setString("玩家"..viewId)
        end
        
        if GlobalUserItem.isAntiCheat() and viewId ~= cmd.MY_VIEWID then
            self.tabClipText[viewId]:setString("玩家"..viewId)
        end
        local curScore = self.m_spBg:getChildByName(string.format("curScore_%d", viewId))
        curScore:setString(string.format("%d分",rs.cbScore[1][i]))

        local curCellTimes = self.m_spBg:getChildByName(string.format("curCellTimes_%d", viewId))
        curCellTimes:setString(string.format("%d",rs.cbUserTimes[1][i]))            
        
        local curResult = self.m_spBg:getChildByName(string.format("curResult_%d", viewId))
        local score = rs.lGameScore[1][i]
        local img_result = self.m_spBg:getChildByName(string.format("img_result_%d", viewId))
        
        local szScore = string.format("%d",score)
        if score >= 0 then
            szScore = string.format("+%d",score)
            img_result:loadTexture("result_res/win.png")
        else 
            img_result:loadTexture("result_res/lose.png")
        end
        curResult:setString(szScore)
    end
end

function ResultLayer:onTouchBegan(touch, event)
    return self:isVisible()
end

function ResultLayer:onTouchEnded(touch, event)
    local pos = touch:getLocation() 
    local m_spBg = self.m_spBg
    pos = m_spBg:convertToNodeSpace(pos)
    local rec = cc.rect(0, 0, m_spBg:getContentSize().width, m_spBg:getContentSize().height)
    if false == cc.rectContainsPoint(rec, pos) then
        self:hideGameResult()
    end
end

function ResultLayer:onBtnClick(tag, sender)
    if BT_CONTINUE == tag then
        self:hideGameResult()
        self.m_parent:onClickReady()
    elseif BT_QUIT == tag then
        self.m_parent:getParentNode():onQueryExitGame()
    elseif BT_CLOSE == tag then
        self:hideGameResult()
    end
end

function ResultLayer:hideGameResult()
    self:reSet()
    self:setVisible(false)
end

function ResultLayer:showGameResult( rs )
    self.m_rs = rs
    self:reSet()
    self:setVisible(true)

    for i = 1,cmd.PLAYER_COUNT do
        local viewId = self.m_parent._scene:SwitchViewChairID(i - 1)
        local userItem = self.m_parent.m_historyUseItem[viewId]
        if nil == userItem then
             userItem = self.m_parent.m_tabUserItemCopy[viewId]
        end
        if nil ~= userItem then
             self.tabClipText[viewId]:setString(userItem.szNickName)
        else
            self.tabClipText[viewId]:setString("玩家"..viewId)
        end
        if GlobalUserItem.isAntiCheat() and viewId ~= cmd.MY_VIEWID then
            self.tabClipText[viewId]:setString("玩家"..viewId)
        end

        local curScore = self.m_spBg:getChildByName(string.format("curScore_%d", viewId))
        curScore:setString(string.format("%d分",rs.cbScore[1][i]))

        local curCellTimes = self.m_spBg:getChildByName(string.format("curCellTimes_%d", viewId))
        curCellTimes:setString(string.format("%d",rs.cbUserTimes[1][i]))            
        
        local curResult = self.m_spBg:getChildByName(string.format("curResult_%d", viewId))
        local score = rs.lGameScore[1][i]
        local img_result = self.m_spBg:getChildByName(string.format("img_result_%d", viewId))
        
        local szScore = string.format("%d",score)
        if score >= 0 then
            szScore = string.format("+%d",score)
            img_result:loadTexture("result_res/win.png")
        else 
            img_result:loadTexture("result_res/lose.png")
            
        end
        curResult:setString(szScore)
    end

end

function ResultLayer:reSet()
    if true then 
        return
    end
    self.m_spResultSp:setVisible(false)
    for i = 1, 3 do
        -- 昵称
        self.m_tabClipNickName[i]:setString("")
        self.m_tabClipNickName[i]:setTextColor(cc.c4b(255,255,255,255))

        -- 游戏币
        self.m_tabTextCoin[i]:setString("")
        self.m_tabTextCoin[i]:setColor(cc.c4b(255,255,255,255))

        self.m_tabFlag[i]:setString("")
    end
end

return ResultLayer