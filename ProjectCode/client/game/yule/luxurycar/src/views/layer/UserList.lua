--
-- Author: Tang
-- Date: 2016-10-13 16:08:36
--
local UserList = class("UserList", function(module)

	return display.newLayer()
end)

local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local PopupInfoHead = appdf.EXTERNAL_SRC .. "PopupInfoHead"
local ClipText = appdf.EXTERNAL_SRC .. "ClipText"
local g_var = ExternalFun.req_var

function UserList:ctor(module)

	self._dataModule = module

	self:InitData()

end

function UserList:InitData()

	local bg = ccui.ImageView:create()
    bg:setContentSize(cc.size(yl.WIDTH, yl.HEIGHT))
    bg:setScale9Enabled(true)
    bg:setAnchorPoint(cc.p(0.5,0.5))
    bg:setPosition(yl.WIDTH/2, yl.HEIGHT/2)
    bg:setTouchEnabled(true)
    self:addChild(bg)
    bg:addTouchEventListener(function (sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            self:setVisible(false)
        end
    end)

    --table背景
    local viewBG = ccui.ImageView:create("game_res/dikuang19.png")
    viewBG:setAnchorPoint(cc.p(0.5,0.5))
    viewBG:setTouchEnabled(true)
    viewBG:setPosition(cc.p(yl.WIDTH/2, yl.HEIGHT/2))
    bg:addChild(viewBG)

    --标题
    local title = ccui.ImageView:create("game_res/biaoti6.png")
    title:setAnchorPoint(cc.p(0.5,1.0))
    title:setPosition(cc.p(viewBG:getContentSize().width/2,viewBG:getContentSize().height - 5))
    viewBG:addChild(title)

    --关闭按钮
    local close = ccui.Button:create("game_res/anniu25.png","game_res/anniu26.png")
    close:setAnchorPoint(cc.p(1.0,1.0))
    close:setPosition(cc.p(viewBG:getContentSize().width - 5,viewBG:getContentSize().height - 5))
	close:addTouchEventListener(function (sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            self:setVisible(false)
        end
    end) 
    viewBG:addChild(close)

    --昵称
    local nick =  cc.Label:createWithTTF("昵称", "fonts/round_body.ttf", 20)
    nick:setTextColor(cc.c3b(0,255,210))
    nick:setPosition(cc.p(130,viewBG:getContentSize().height - 70))
    viewBG:addChild(nick)

    --游戏币
    local coin =  cc.Label:createWithTTF("游戏币", "fonts/round_body.ttf", 20)
    coin:setTextColor(cc.c3b(0,255,210))
    coin:setPosition(cc.p(300,viewBG:getContentSize().height - 70))
    viewBG:addChild(coin)

	self.m_pTableView = cc.TableView:create(cc.size(viewBG:getContentSize().width - 5, viewBG:getContentSize().height - 100 ))
	self.m_pTableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
	self.m_pTableView:setPosition(cc.p(0,10))
	self.m_pTableView:setDelegate()
	self.m_pTableView:registerScriptHandler(self.cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)
	self.m_pTableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
	self.m_pTableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
	viewBG:addChild(self.m_pTableView)

end


function UserList:reloadData()

	if not self:isVisible() then 
		return
	end

	self.m_pTableView:reloadData()
end

--------------------------------------------------------------------tableview
function UserList.cellSizeForTable( view, idx )
	print("cellSizeForTable............................................")
	return 422,70
end

function UserList:numberOfCellsInTableView( view )

	print("#self._dataModule:getUserList() is =========================>"..#self._dataModule:getUserList())
	if 0 == #self._dataModule:getUserList() then
		return 0
	else
		return #self._dataModule:getUserList()
	end
end

function UserList:tableCellAtIndex( view, idx )
	print("idx is =================================================================== >" .. idx)
	local cell = view:dequeueCell()
	local useritem = self._dataModule.m_UserList[idx+1]
	if nil == cell then

		cell = cc.TableViewCell:new()
		--cell背景
		local cellBG = ccui.ImageView:create("game_res/dikuang21.png")
		cellBG:setTag(1)
		cellBG:setPosition(cc.p(213, 65/2))
		cell:addChild(cellBG)

	
		--玩家昵称
		local nick =  g_var(ClipText):createClipText(cc.size(150, 20),useritem.szNickName)
		nick:setTag(2)
		nick:setAnchorPoint(cc.p(0.0,0.5))
		nick:setPosition(cc.p(100,35))
		cell:addChild(nick)

		--金币图标
		local icon = ccui.ImageView:create("game_res/tubiao2.png")
		icon:setPosition(260, 35)
		cell:addChild(icon)

		--玩家金币
		local coin = cc.Label:createWithTTF(ExternalFun.numberThousands(useritem.lScore*self._dataModule._Multiple), "fonts/round_body.ttf", 20)   
		coin:setAnchorPoint(cc.p(0.0,0.5))
		coin:setTag(4)
		coin:setPosition(280, 35)
		cell:addChild(coin)


		--玩家头像
		local headBG = ccui.ImageView:create("game_res/dikuang6.png")
		headBG:setAnchorPoint(cc.p(0.0,0.5))
		headBG:setTag(5)
		headBG:setPosition(cc.p(22,35))
		cell:addChild(headBG)

		local head = g_var(PopupInfoHead):createClipHead(useritem, 47)
		head:setPosition(cc.p(headBG:getContentSize().width/2,headBG:getContentSize().height/2))
		head:setTag(1)
		headBG:addChild(head)

		head:enableInfoPop(false)

	else

		if nil ~= cell:getChildByTag(2) then 
			local nick = cell:getChildByTag(2)
			nick:setString(useritem.szNickName)
		end

		if nil ~= cell:getChildByTag(4) then
			local coin = cell:getChildByTag(4)
			coin:setString(ExternalFun.numberThousands(useritem.lScore*self._dataModule._Multiple))
		end

		if nil ~= cell:getChildByTag(5) then
			local headBG = cell:getChildByTag(5)
			local head = headBG:getChildByTag(1)
			if nil ~= head then
				head:removeFromParent()

				head = g_var(PopupInfoHead):createClipHead(useritem, 47)
				head:setPosition(cc.p(headBG:getContentSize().width/2,headBG:getContentSize().height/2))
				head:setTag(1)
				headBG:addChild(head)

				head:enableInfoPop(false)

			end
		end
		
	end

	return cell
end

-----------------------------------------------------------------------------


return UserList