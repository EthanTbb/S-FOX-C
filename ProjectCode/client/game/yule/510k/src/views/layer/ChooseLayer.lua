

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. "ClipText")

local module_pre = "game.yule.510k.src"
local cmd = appdf.req(module_pre .. ".models.CMD_Game")
local GameLogic = appdf.req(module_pre .. ".models.GameLogic")
local CardsNode = appdf.req(module_pre .. ".views.layer.gamecard.CardsNode")
local ChooseLayer = class("ChooseLayer",function(scene)
        local chooseLayer = display.newLayer()
    return chooseLayer
end)

function ChooseLayer:ctor( parent )
	CardsNode.registerTouchEvent(self,false,3)
	self._parent = parent
	self.m_csbNode = nil
	self._scene = parent._scene
	self.m_bt_ensure = nil

	self.m_tabNodeCard = nil
	--ExternalFun.registerTouchEvent(self)
	self:initView()
end

function  ChooseLayer:initView()
	local csbNode = ExternalFun.loadCSB("game_res/ChooseLayer.csb", self)
	self.m_csbNode = csbNode
		
	local bg = csbNode:getChildByName("bg")
	self.m_bt_ensure = bg:getChildByName("bt_ensure")

	local function btnEvent( sender, eventType )
        if eventType == ccui.TouchEventType.began then
            ExternalFun.popupTouchFilter(1, false)
        elseif eventType == ccui.TouchEventType.canceled then
            ExternalFun.dismissTouchFilter()
        elseif eventType == ccui.TouchEventType.ended then
            ExternalFun.dismissTouchFilter()
            self:onButtonClickedEvent(sender:getTag(), sender)
            --self.m_tabNodeCard:onTouchEnded(sender,eventType)
        end
    end

    --self.m_bt_ensure:setTag(TAG_ENUM.BT_READY)
    self.m_bt_ensure:addTouchEventListener(btnEvent)

   	--统计手上的 5 10 k
   	local _veiwHandCards = self._parent.m_tabNodeCards[1]:getHandCards()
   	local vecCards = {}
   	for k, v in pairs (_veiwHandCards) do 
   		if 0x05 == GameLogic:GetCardLogicValue(v) or 0x0A == GameLogic:GetCardLogicValue(v) or 0x0d == GameLogic:GetCardLogicValue(v) then
   			table.insert(vecCards,v)
   		end
   	end
   	dump(vecCards, "--- setCardsBlack vecCards ---", 6)
    self.m_tabNodeCard = CardsNode:createEmptyCardsNode(1,true,4)
    local cards = {0x05,0x15,0x25,0x35,0x0A,0x1A,0x2A,0x3A,0x0D,0x1D,0x2D,0x3D}
    self.m_tabNodeCard:updateCardsNode(cards, true, false, nil) 
    self.m_tabNodeCard:setCardsBlack(vecCards)
    self.m_tabNodeCard:setPosition(cc.p(-40, -5))
    self.m_tabNodeCard:setListener(self)
    self.m_csbNode:addChild(self.m_tabNodeCard)
end

function ChooseLayer:onButtonClickedEvent(tag, sender)
	print("ChooseLayer onTouchEnded")
	local selectCards = self.m_tabNodeCard:getSelectCards()
	local sortCards = GameLogic:SortCardList(selectCards, #selectCards, 0)

	if #selectCards ~= 1 then
		self.m_tabNodeCard:onTouchEnded(sender,eventType)
		return
	elseif #selectCards == 1 then
		local cmddata = CCmd_Data:create(1)
		local cardData = selectCards[1]
		print("------ cardData ---------", cardData)
    	cmddata:pushbyte(cardData)
    	self._scene:SendData(cmd.SUB_C_FIND_FRIEND,cmddata)
      local cardSp =  self.m_tabNodeCard.m_mapCard[cardData]
      if cardSp.m_bIsBlack then
        self._parent.m_bSelfDu = true
      end
      print("================ ChooseLayer =========== ",self._parent.m_bSelfDu)
    	self:removeFromParent()
	end
end

function ChooseLayer:onTouchBegan(touch, event)

	return true
end

function ChooseLayer:onTouchMoved(touch, event)
end

function ChooseLayer:onTouchEnded(touch, event)

	
end

return ChooseLayer