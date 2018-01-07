--
-- Author: zhong
-- Date: 2016-07-07 18:09:11
--
--玩家列表
local module_pre = "game.yule.sicbobattle.src"

local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local g_var = ExternalFun.req_var;

local BtnListLayer = class("BtnListLayer", cc.Layer)

BtnListLayer.BT_EXIT = 100
BtnListLayer.BT_RULE = 105
BtnListLayer.BT_BANK = 103
BtnListLayer.BT_USERLIST = 108
BtnListLayer.BT_SET = 104
function BtnListLayer:ctor( )

	self.superParent = nil
	--注册事件
	local function onLayoutEvent( event )
		if event == "exit" then
			self:onExit();
        elseif event == "enterTransitionFinish" then
        	self:onEnterTransitionFinish();
        end
	end
	self:registerScriptHandler(onLayoutEvent)


	--加载csb资源
	local csbNode = ExternalFun.loadCSB("game/118_btnList.csb", self)
	csbNode:setPosition(60,720)
	local sp_bg = csbNode:getChildByName("Sprite_ListBtn")
	self.m_spBg = sp_bg
	self.m_spBg:setScaleY(0.0000001)
	
	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then

		    self:hideUserList()
            self:setVisible(false)
            self.superParent.m_BtnMenu:setVisible(true)
			self.superParent:onButtonClickedEvent(sender:getTag(), sender);
		end
	end
	-- local btn = sp_bg:getChildByName("Button_close")
	-- btn:setTag(BtnListLayer.BT_CLOSE)
	-- btn:addTouchEventListener(btnEvent);

	--离开
	local btn = sp_bg:getChildByName("Button_back");
	btn:setTag(BtnListLayer.BT_EXIT);
	btn:addTouchEventListener(btnEvent);

	--规则
	btn = sp_bg:getChildByName("Button_rule");
	btn:setTag(BtnListLayer.BT_RULE);
	btn:addTouchEventListener(btnEvent);

	--银行
	btn = sp_bg:getChildByName("Button_bank");
	btn:setTag(BtnListLayer.BT_BANK);
	btn:addTouchEventListener(btnEvent);

	--玩家列表
	btn = sp_bg:getChildByName("Button_playList");
	btn:setTag(BtnListLayer.BT_USERLIST);
	btn:addTouchEventListener(btnEvent);

	--set
	btn = sp_bg:getChildByName("Button_set");
	btn:setTag(BtnListLayer.BT_SET);
	btn:addTouchEventListener(btnEvent);


end


-- function BtnListLayer:onButtonClickedEvent( tag, sender )
-- 	ExternalFun.playClickEffect()
-- 	if BtnListLayer.BT_EXIT == tag then

-- 	elseif BtnListLayer.BT_RULE == tag then

-- 	elseif BtnListLayer.BT_BANK == tag then

-- 	elseif BtnListLayer.BT_USERLIST == tag then

-- 	end
-- end

function BtnListLayer:onExit()
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.listener)
end

function BtnListLayer:onEnterTransitionFinish()
	self:registerTouch()
end

function BtnListLayer:registerTouch()
	local function onTouchBegan( touch, event )
		return self:isVisible()
	end

	local function onTouchEnded( touch, event )
		local pos = touch:getLocation();
		local m_spBg = self.m_spBg
        pos = m_spBg:convertToNodeSpace(pos)
        local rec = cc.rect(0, 0, m_spBg:getContentSize().width, m_spBg:getContentSize().height)
        if false == cc.rectContainsPoint(rec, pos) then
            self:setVisible(false)
            self.superParent.m_BtnMenu:setVisible(true)
            self:hideUserList()
        end        
	end

	local listener = cc.EventListenerTouchOneByOne:create();
	listener:setSwallowTouches(true)
	self.listener = listener;
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN );
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED );
    local eventDispatcher = self:getEventDispatcher();
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self);
end

function BtnListLayer:hideUserList(  )
	self.m_spBg:setScaleY(0.0000001)
    self.m_spBg:stopAllActions()
    self.m_spBg:runAction(self.superParent.m_actDropOut)
end

return BtnListLayer