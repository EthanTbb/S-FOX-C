--
-- Author: zhong
-- Date: 2016-07-07 18:09:11
--
--玩家列表

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. "ClipText")
local PopupInfoHead = appdf.req(appdf.EXTERNAL_SRC .. "PopupInfoHead")

local UserItem = appdf.req(appdf.GAME_SRC.."yule.oxbattle.src.views.layer.UserItem")

local UserListLayer = class("UserListLayer", cc.Layer)
--UserListLayer.__index = UserListLayer
UserListLayer.BT_CLOSE = 1

function UserListLayer:ctor( )
	--用户列
	self.m_userlist = {}

	--加载csb资源
	local csbNode = ExternalFun.loadCSB("UserListLayer.csb", self)

	local sp_bg = csbNode:getChildByName("sp_userlist_bg")
	self.m_spBg = sp_bg
	local content = sp_bg:getChildByName("content")

	--用户列表
	local m_tableView = cc.TableView:create(content:getContentSize())
	m_tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
	m_tableView:setPosition(content:getPosition())
	m_tableView:setDelegate()
	m_tableView:registerScriptHandler(self.cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)
	m_tableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
	m_tableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
	sp_bg:addChild(m_tableView)
	self.m_tableView = m_tableView
	content:removeFromParent()

	--关闭按钮
	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onButtonClickedEvent(sender:getTag(), sender);
		end
	end
	local btn = sp_bg:getChildByName("close_btn")
	btn:setTag(UserListLayer.BT_CLOSE)
	btn:addTouchEventListener(btnEvent)

	local layout_bg = csbNode:getChildByName("layout_bg")
	layout_bg:setTag(UserListLayer.BT_CLOSE)
	layout_bg:addTouchEventListener(btnEvent)

	content:removeFromParent()
end

function UserListLayer:refreshList( userlist )
	self:setVisible(true)
	self.m_userlist = userlist
	self.m_tableView:reloadData()
end

--tableview
function UserListLayer.cellSizeForTable( view, idx )
	return UserItem.getSize()
end

function UserListLayer:numberOfCellsInTableView( view )
	if nil == self.m_userlist then
		return 0
	else
		return #self.m_userlist
	end
end

function UserListLayer:tableCellAtIndex( view, idx )
	local cell = view:dequeueCell()
	
	if nil == self.m_userlist then
		return cell
	end

	local useritem = self.m_userlist[idx+1]
	local item = nil

	if nil == cell then
		cell = cc.TableViewCell:new()
		item = UserItem:create()
		item:setPosition(view:getViewSize().width * 0.5, 0)
		item:setName("user_item_view")
		cell:addChild(item)
	else
		item = cell:getChildByName("user_item_view")
	end

	if nil ~= useritem and nil ~= item then
		item:refresh(useritem, false, 0.5)
	end

	return cell
end
--

function UserListLayer:onButtonClickedEvent( tag, sender )
	ExternalFun.playClickEffect()
	if UserListLayer.BT_CLOSE == tag then
		self:setVisible(false)
	end
end

return UserListLayer