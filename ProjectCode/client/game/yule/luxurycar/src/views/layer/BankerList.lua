--
-- Author: Tang
-- Date: 2016-10-13 16:08:13
--
local BankerList = class("BankerList", function(module)

	return display.newNode()
end)

local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local PopupInfoHead = appdf.EXTERNAL_SRC .. "PopupInfoHead"
local ClipText = appdf.EXTERNAL_SRC .. "ClipText"
local g_var = ExternalFun.req_var

function BankerList:ctor(module)

	self._dataModule = module

	self:InitData()

end


function BankerList:InitData()
 
	self.m_pTableView = cc.TableView:create(cc.size(260, 310))
	self.m_pTableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
	self.m_pTableView:setPosition(cc.p(0,0))
	self.m_pTableView:setDelegate()
	self.m_pTableView:registerScriptHandler(self.cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)
	self.m_pTableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
	self.m_pTableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
	self:addChild(self.m_pTableView)

end


function BankerList:reloadData()
	self.m_pTableView:reloadData()
end

--------------------------------------------------------------------tableview
function BankerList.cellSizeForTable( view, idx )
	return 260,90
end

function BankerList:numberOfCellsInTableView( view )

	--print("#self._dataModule:getBankList() is =========================>"..#self._dataModule:getBankList())
	if 0 == #self._dataModule:getBankList() then
		return 0
	else
		return #self._dataModule:getBankList()
	end
end

function BankerList:tableCellAtIndex( view, idx )
	--print("idx is =================================================================== >" .. idx)
	local cell = view:dequeueCell()
	local userlist = self._dataModule:DeepCopy(self._dataModule.m_BankList)
	self._dataModule:reverse(userlist)
	
	local useritem = userlist[idx+1]
	if nil == cell then

		cell = cc.TableViewCell:new()

		--cell背景
		local cellBG = ccui.ImageView:create("game_res/dikuang5.png")
		cellBG:setTag(1)
		cellBG:setPosition(cc.p(130, 75/2))
		cell:addChild(cellBG)

	
		--玩家昵称
		local nick =  g_var(ClipText):createClipText(cc.size(150, 20),useritem.szNickName)
		nick:setTag(2)
		nick:setAnchorPoint(cc.p(0.0,0.5))
		nick:setPosition(cc.p(100,50))
		cell:addChild(nick)

		--金币图标
		local icon = ccui.ImageView:create("game_res/tubiao2.png")
		icon:setPosition(110, 20)
		cell:addChild(icon)

		--玩家金币
		local coin = cc.Label:createWithTTF(ExternalFun.numberThousands(useritem.lScore*self._dataModule._Multiple), "fonts/round_body.ttf", 20)   
		coin:setAnchorPoint(cc.p(0.0,0.5))
		coin:setTag(4)
		coin:setPosition(122, 20)
		cell:addChild(coin)


		--玩家头像
		local headBG = ccui.ImageView:create("game_res/dikuang6.png")
		headBG:setAnchorPoint(cc.p(0.0,0.5))
		headBG:setTag(5)
		headBG:setPosition(cc.p(12,75/2))
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


return BankerList