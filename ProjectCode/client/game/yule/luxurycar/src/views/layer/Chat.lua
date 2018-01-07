--
-- Author: Tang
-- Date: 2016-10-27 09:59:00
--聊天


local Chat = class("Chat", function(view,module,frameEngine)
	return display.newNode() 
end)

local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local ClipText = appdf.EXTERNAL_SRC .. "ClipText"
local g_var = ExternalFun.req_var

 function Chat:ctor(view,module,frameEngine)
	self._scene = view
	self._dataModule = module
	self._frameEngine = frameEngine
	self.m_pTableView = nil
	self._expressView = nil
	self:setContentSize(cc.size(290, 480))
	self:setAnchorPoint(cc.p(0.0,0.0))
	self:setPosition(cc.p(0,45))
	self._frameEngine = frameEngine
	self:initChat()
	self:initTableview()
end

function Chat:initChat()
	--editbox 
	--输入框背景
	local cell = self._scene:getChildByName("edit_cell")
	local editbox = ccui.EditBox:create(cc.size(130, 33),"")
		        :setPosition(cc.p(80,cell:getContentSize().height/2))
		        :setFontName("fonts/round_body.ttf")
		        :setPlaceholderFontName("fonts/round_body.ttf")
		        :setFontSize(20)
		        :setPlaceholderFontSize(20)
		        :setMaxLength(32)
		        :setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		        :setPlaceHolder("请输入聊天内容")
		    cell:addChild(editbox)

	self._editbox = editbox	    


	--表情按钮
	local expressBtn = self._scene:getChildByName("btn_expression")
	expressBtn:addTouchEventListener(function (ref,eventType)
            if eventType == ccui.TouchEventType.ended then
           		self:PopChat(ref, eventType)
            end
        end)

	--发送
	local send = self._scene:getChildByName("btn_send")
	send:addTouchEventListener(function (ref,eventType)
            if eventType == ccui.TouchEventType.ended then

	            local chatstr = self._editbox:getText()
				chatstr = string.gsub(chatstr, " " , "")
		        if ExternalFun.stringLen(chatstr) > 128 then
		            showToast(self, "聊天内容过长", 2)
		            return
		        end

		        if ExternalFun.stringLen(chatstr) ==  0 then
		            showToast(self, "请输入聊天内容", 2)
		            return
		        end

		        --判断emoji
		        if ExternalFun.isContainEmoji(chatstr) then
		            showToast(self, "聊天内容包含非法字符,请重试", 2)
		            return
		        end

		        --敏感词过滤  
		        if true == ExternalFun.isContainBadWords(chatstr) then
		            showToast(self, "聊天内容包含敏感词汇!", 2)
		            return
		        end

				if "" ~= chatstr then
					local valid, msg = self:sendTextChat(chatstr)
					if false == valid and type(msg) == "string" and "" ~= msg then
						showToast(self, msg, 2)
					else
						self._editbox:setText("")
					end
				end

				local useritem = self._frameEngine:GetMeUserItem()
           		local nick = useritem.szNickName
           		local record = {nick,{_type=0,_content=chatstr}}

           		self._dataModule:insertRecord(record)
           		self:reloadData()

           		self._editbox:setText("")
            end
        end)
end

function Chat:initTableview()
	self.m_pTableView = cc.TableView:create(cc.size(290, 480))
	self.m_pTableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
	self.m_pTableView:setPosition(cc.p(0,0))
	self.m_pTableView:setDelegate()
	self.m_pTableView:registerScriptHandler(self.cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)
	self.m_pTableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
	self.m_pTableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
	self:addChild(self.m_pTableView)
end

function Chat:PopChat(ref,eventType)
	if not self._expressView then

		self._expressView = ccui.ImageView:create()
	    self._expressView:setContentSize(cc.size(yl.WIDTH, yl.HEIGHT))
	    self._expressView:setScale9Enabled(true)
	    self._expressView:setAnchorPoint(cc.p(0.5,0.5))
	    self._expressView:setPosition(yl.WIDTH/2, yl.HEIGHT/2)
	    self._expressView:setTouchEnabled(true)
	    self._scene:getParent():getParent():addChild(self._expressView)  --self._scene:getParent():getParent()为 _gameView
	    self._expressView:addTouchEventListener(function (sender,eventType)
	        if eventType == ccui.TouchEventType.ended then
	            self._expressView:setVisible(false)
	        end
	    end) 

	    --加载CSB
	     local csbnode = cc.CSLoader:createNode("game_res/Chat.csb");
	     csbnode:setPosition(self._expressView:getContentSize().width/2	, self._expressView:getContentSize().height/2)
		 self._expressView:addChild(csbnode);

		 --表情按钮
		 for i=1,10 do
		 	local express = csbnode:getChildByName(string.format("btn_%d", i))
		 	express:addTouchEventListener(function (sender,eventType)
	        if eventType == ccui.TouchEventType.ended then
	           	local useritem = self._frameEngine:GetMeUserItem()
           		local nick = useritem.szNickName
           		local record = {nick,{_type=1,_content=i}}

           		self._dataModule:insertRecord(record)
           		self:reloadData()

           		self._expressView:setVisible(false)

           		self:sendBrowChat(i)
	        end
	    end) 
		 end

	 else
	 	 self._expressView:setVisible(true)
	end

end

function Chat:reloadData()
	self.m_pTableView:reloadData()
end

--------------------------------------------------------------------tableview
function Chat.cellSizeForTable( view, idx )
	return 290,60
end

function Chat:numberOfCellsInTableView( view )

	print("#self._dataModule:getRcordList() is =========================>"..#self._dataModule:getRcordList())
	if 0 == #self._dataModule:getRcordList() then
		return 0
	else
		return #self._dataModule:getRcordList()
	end
end

function Chat:tableCellAtIndex( view, idx )
	print("idx is =================================================================== >" .. idx)
	local cell = view:dequeueCell()
	local record = self._dataModule.m_ChatRecord[idx+1]
	if nil == cell then

		cell = cc.TableViewCell:new()
		--昵称
		local nick =  g_var(ClipText):createClipText(cc.size(145, 20),record[1].." :")
		nick:setTextColor(cc.c3b(36,236,255))
		nick:setTag(1)
		nick:setAnchorPoint(cc.p(0.0,0.5))
		nick:setPosition(cc.p(20,50))
		cell:addChild(nick)


		--内容 判断 文字 或 表情
		local content
		if record[2]._type == 0 then
			content = g_var(ClipText):createClipText(cc.size(245, 20),record[2]._content)
		else
			content = ccui.ImageView:create(string.format("game_res/tubiao%d.png", 50 + record[2]._content))
			content:setScale(0.5)	
		end

		content:setTag(2)
		content:setAnchorPoint(cc.p(0.0,0.5))
		content:setPosition(cc.p(20,20))
		cell:addChild(content)

	else
		if cell:getChildByTag(1) then 
		
			local nick = cell:getChildByTag(1)
			nick:setString(record[1]..":")
		end

		if cell:getChildByTag(2) then
			local content = cell:getChildByTag(2)
			content:removeFromParent()

			local content
			if record[2]._type == 0 then
				content = g_var(ClipText):createClipText(cc.size(145, 20),record[2]._content)
			else
				content = ccui.ImageView:create(string.format("game_res/tubiao%d.png", 50 + record[2]._content))
				content:setScale(0.5)	
			end

			content:setTag(2)
			content:setAnchorPoint(cc.p(0.0,0.5))
			content:setPosition(cc.p(20,20))
			cell:addChild(content)
		end
	end

	return cell
end

-----------------------------------------------------------------------------------------------------------------

--发送文本聊
function Chat:sendTextChat(msg)
	if nil ~= self._frameEngine and nil ~= self._frameEngine.sendTextChat then
		return self._frameEngine:sendTextChat(msg)
	end
	return false, ""
end

--发送表情聊天
function Chat:sendBrowChat(idx)
	if nil ~= self._frameEngine and nil ~= self._frameEngine.sendBrowChat then
		return self._frameEngine:sendBrowChat(idx)
	end

	return false, ""
end


--用户聊天
function Chat:onUserChat(nick, chatstr)
   	
   	
	local record = {nick,{_type=0,_content=chatstr}}

	self._dataModule:insertRecord(record)
	self:reloadData()
end

--用户表情
function Chat:onUserExpression(nick, index)
 	 if index > 10 then
  		return
 	 end

 	local record = {nick,{_type=1,_content=index}}

	self._dataModule:insertRecord(record)
	self:reloadData()

end

return Chat
