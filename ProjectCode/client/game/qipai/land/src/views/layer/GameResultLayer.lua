--
-- Author: zhong
-- Date: 2016-11-11 09:59:23
--
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. "ClipText")

local module_pre = "game.qipai.land.src"
local cmd = appdf.req(module_pre .. ".models.CMD_Game")

local GameResultLayer = class("GameResultLayer", cc.Layer)

local BT_CONTINUE = 101
local BT_QUIT = 102
local BT_CLOSE = 103

function GameResultLayer.getTagSettle()
    return 
    {
        -- 用户名
        m_userName = "",
        -- 文本颜色
        nameColor = cc.c4b(255,255,255,255),
        -- 计算金币
        m_settleCoin = "",
        -- 文本颜色
        coinColor = cc.c4b(255,255,255,255),       
        -- 特殊标志
        m_cbFlag = cmd.kFlagDefault,
    }
end

function GameResultLayer.getTagGameResult()
    return
    {
        -- 结果
        enResult = cmd.kDefault,
        -- 结算
        settles = 
        {
            GameResultLayer.getTagSettle(),
            GameResultLayer.getTagSettle(),
            GameResultLayer.getTagSettle(),
        } 
    }
end

function GameResultLayer:ctor( parent )
    self.m_parent = parent
    --注册node事件
    ExternalFun.registerTouchEvent(self, true)

    --加载csb资源
    local csbNode = ExternalFun.loadCSB("game/GameResultLayer.csb", self)

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
    local btn = bg:getChildByName("btnContinue")
    btn:setTag(BT_CONTINUE)
    btn:addTouchEventListener(btnEvent)

    -- 退出按钮
    btn = bg:getChildByName("btnQuit")
    btn:setTag(BT_QUIT)
    btn:addTouchEventListener(btnEvent)

    -- 关闭按钮
    btn = bg:getChildByName("btnClose")
    btn:setTag(BT_CLOSE)
    btn:addTouchEventListener(btnEvent)

    local str = ""
    self.m_tabClipNickName = {}
    self.m_tabTextCoin = {}
    self.m_tabFlag = {}

    -- 用户信息
    local csbGroup = bg:getChildByName("u_group")
    for i = 1, 3 do
        local idx = i - 1
        str = "user" .. idx .. "Text"
        local txt = csbGroup:getChildByName(str)
        self.m_tabClipNickName[i] = ClipText:createClipText(txt:getContentSize(), "", nil, 30)
        self.m_tabClipNickName[i]:setPosition(txt:getPosition())
        self.m_tabClipNickName[i]:setAnchorPoint(txt:getAnchorPoint())
        csbGroup:addChild(self.m_tabClipNickName[i])
        txt:removeFromParent()

        str = "user" .. idx .. "Coin"
        self.m_tabTextCoin[i] = csbGroup:getChildByName(str)

        str = "flag" .. idx 
        self.m_tabFlag[i] = csbGroup:getChildByName(str)
    end

    self:hideGameResult()
end

function GameResultLayer:onTouchBegan(touch, event)
    return self:isVisible()
end

function GameResultLayer:onTouchEnded(touch, event)
    local pos = touch:getLocation() 
    local m_spBg = self.m_spBg
    pos = m_spBg:convertToNodeSpace(pos)
    local rec = cc.rect(0, 0, m_spBg:getContentSize().width, m_spBg:getContentSize().height)
    if false == cc.rectContainsPoint(rec, pos) then
        self:hideGameResult()
    end
end

function GameResultLayer:onBtnClick(tag, sender)
    if BT_CONTINUE == tag then
        self:hideGameResult()
        self.m_parent:onClickReady()
    elseif BT_QUIT == tag then
        self.m_parent:getParentNode():onQueryExitGame()
    elseif BT_CLOSE == tag then
        self:hideGameResult()
    end
end

function GameResultLayer:hideGameResult()
    self:reSet()
    self:setVisible(false)
end

function GameResultLayer:showGameResult( rs )
    self:reSet()
    self:setVisible(true)

    -- 更新图片
    local str = "gameend_" .. rs.enResult .. "_pic.png"
    local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(str)
    if nil ~= frame then
        self.m_spResultSp:setSpriteFrame(frame)
        self.m_spResultSp:setVisible(true)
    end

    -- 更新文本
    for i = 1, 3 do
        local settle = rs.settles[i]
        -- 昵称
        self.m_tabClipNickName[i]:setString(settle.m_userName)
        self.m_tabClipNickName[i]:setTextColor(settle.nameColor)

        -- 金币
        self.m_tabTextCoin[i]:setString(settle.m_settleCoin)
        self.m_tabTextCoin[i]:setColor(settle.coinColor)

        -- 标志
        if cmd.kFlagChunTian == settle.m_cbFlag then
            self.m_tabFlag[i]:setString("春天*2")
        elseif cmd.kFlagFanChunTian == settle.m_cbFlag then
            self.m_tabFlag[i]:setString("反春天*2")
        else
            self.m_tabFlag[i]:setString("")
        end
    end
end

function GameResultLayer:reSet()
    self.m_spResultSp:setVisible(false)
    for i = 1, 3 do
        -- 昵称
        self.m_tabClipNickName[i]:setString("")
        self.m_tabClipNickName[i]:setTextColor(cc.c4b(255,255,255,255))

        -- 金币
        self.m_tabTextCoin[i]:setString("")
        self.m_tabTextCoin[i]:setColor(cc.c4b(255,255,255,255))

        self.m_tabFlag[i]:setString("")
    end
end

return GameResultLayer