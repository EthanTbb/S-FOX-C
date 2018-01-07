--
-- Author: zhong
-- Date: 2016-07-07 18:55:48
--
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. "ClipText")
local PopupInfoHead = appdf.req(appdf.EXTERNAL_SRC .. "PopupInfoHead")

local UserItem = class("UserItem", cc.Node)

function UserItem:ctor()
	--加载csb资源
	local csbNode = ExternalFun.loadCSB("UserItem.csb", self)
	self.m_csbNode = csbNode

	--头像
	local tmp = csbNode:getChildByName("sp_head")	
	self.m_headSize = tmp:getContentSize().width
	tmp:removeFromParent()

	--昵称
	tmp = csbNode:getChildByName("text_name")
	local clipText = ClipText:createClipText(tmp:getContentSize(), "")
	clipText:setTextFontSize(30)
	clipText:setAnchorPoint(tmp:getAnchorPoint())
	clipText:setPosition(tmp:getPosition())
	csbNode:addChild(clipText)
	tmp:removeFromParent()
	self.m_clipText = clipText

	--抢庄标志
	local rob = csbNode:getChildByName("sp_rob")
	rob:setVisible(false)
	self.m_spRob = rob

	--金币1
	local coin = csbNode:getChildByName("text_coin")
	coin:setString("")
	self.m_textCoin = coin
end

function UserItem.getSize( )
	return 502,70
end

--type == 1表示上庄申请列表
function UserItem:refresh( useritem,var_bRob, yPer, showtype)
	if nil == useritem then
		return
	end
	local showtype = showtype
	showtype = nil == showtype and 0 or 1
	--更新头像
	if nil ~= self.m_head and nil ~= self.m_head:getParent() then
		self.m_head:removeFromParent()
		self.m_head = nil
	end
	self.m_head = PopupInfoHead:createNormal(useritem, self.m_headSize)
	self.m_head:setPosition(-217,37)
	self.m_csbNode:addChild(self.m_head)
	local showpos = cc.p(360,320)
	local anchor = cc.p(1.0, yPer)
	if showtype == 1 then
		showpos = cc.p(10, 280)
	end
	self.m_head:enableInfoPop(true, showpos, anchor)

	--更新昵称
	local szNick = ""
	if nil ~= useritem.szNickName then
		szNick = useritem.szNickName
	end
	self.m_clipText:setString(szNick)

	--更新抢庄标志
	local bRob = var_bRob or false
	self.m_spRob:setVisible(bRob)

	--更新金币
	local coin = 0
	if nil ~= useritem.lScore then
		coin = useritem.lScore
	end
	local str = ExternalFun.formatScoreText(coin)
	self.m_textCoin:setString(str)
end

return UserItem