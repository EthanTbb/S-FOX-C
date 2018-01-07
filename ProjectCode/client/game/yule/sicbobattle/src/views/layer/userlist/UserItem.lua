--
-- Author: zhong
-- Date: 2016-07-07 18:55:48
--
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local g_var = ExternalFun.req_var
local ClipText = appdf.EXTERNAL_SRC .. "ClipText"
local PopupInfoHead = appdf.EXTERNAL_SRC .. "PopupInfoHead"

local UserItem = class("UserItem", cc.Node)

function UserItem:ctor()
	--加载csb资源
	local csbNode = ExternalFun.loadCSB("game/118_userItem.csb", self)
	self.m_csbNode = csbNode

	--头像
	local tmp = csbNode:getChildByName("Sprite_head")	
	self.m_headSize = tmp:getContentSize().width
	tmp:removeFromParent()

	--昵称
	local tmp = csbNode:getChildByName("Text_name")
	local clipText = g_var(ClipText):createClipText(tmp:getContentSize(), "","")
	clipText:setTextFontSize(36)
	clipText:setAnchorPoint(tmp:getAnchorPoint())
	clipText:setPosition(tmp:getPosition())
	csbNode:addChild(clipText)
	tmp:removeFromParent()
	self.m_clipText = clipText

	--抢庄标志
	-- local rob = csbNode:getChildByName("sp_rob")
	-- rob:setVisible(false)
	-- self.m_spRob = rob

	--金币1
	local coin = csbNode:getChildByName("Text_score")
	coin:setString("")
	self.m_textCoin = coin
end

function UserItem.getSize(  )
	return 530,57
end

function UserItem:refresh( useritem,var_bRob, yPer)
	if nil == useritem then
		return
	end
	--更新头像
	if nil ~= self.m_head and nil ~= self.m_head:getParent() then
		self.m_head:removeFromParent()
		self.m_head = nil
	end
	self.m_head = g_var(PopupInfoHead):createNormal(useritem, self.m_headSize)
	self.m_head:setPosition(-240,8)
	self.m_csbNode:addChild(self.m_head)
	self.m_head:enableInfoPop(true, cc.p(450,190), cc.p(0.5, 0.5))

	--更新昵称
	local szNick = ""
	if nil ~= useritem.szNickName then
		szNick = useritem.szNickName
	end
	print("szNick",szNick)
	self.m_clipText:setString(szNick)

	--更新抢庄标志
	-- local bRob = var_bRob or false
	-- self.m_spRob:setVisible(bRob)

	--更新金币
	local coin = 0
	if nil ~= useritem.lScore then
		coin = useritem.lScore
	end
	local str = ExternalFun.formatScoreText(coin)
	-- if string.len(str) > 11 then
	-- 	str = string.sub(str, 1, 7) .. "..."
	-- end
	self.m_textCoin:setString(str)
end

return UserItem