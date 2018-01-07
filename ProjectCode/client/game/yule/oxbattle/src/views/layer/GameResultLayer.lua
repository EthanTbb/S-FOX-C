--
-- Author: zhouweixiang
-- Date: 2016-12-27 17:55:44
--
--游戏结算层
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. "ClipText")

local GameResultLayer = class("GameResultLayer", cc.Layer)
local wincolor = cc.c3b(255, 247, 178)
local failedcolor = cc.c3b(178, 243, 255)

function GameResultLayer:ctor(viewParent)
	self.m_parent = viewParent

	self.m_winNode = nil

	self.m_failedNode = nil
end

function GameResultLayer:initWinLayer()
	local csbNode = ExternalFun.loadCSB("GameWin.csb", self)
	csbNode:setVisible(false)
	self.m_winNode = csbNode

	self.m_winAction = ExternalFun.loadTimeLine("GameWin.csb", self)
	self.m_winAction:retain()

	local temp = csbNode:getChildByName("im_win")
	temp = temp:getChildByName("num_score")
	self.m_winScore = temp

	--庄家名称
	temp = csbNode:getChildByName("im_frame")
	local pname = temp:getChildByName("txt_banker")
	local clipText = ClipText:createClipText(pname:getContentSize(), "")
	clipText:setTextFontSize(30)
	clipText:setAnchorPoint(pname:getAnchorPoint())
	clipText:setPosition(pname:getPosition())
	clipText:setTextColor(cc.c3b(177, 139, 80))
	temp:addChild(clipText)
	pname:removeFromParent()
	self.m_winBankerName = clipText

	--玩家名称
	pname = temp:getChildByName("txt_self")
	clipText = ClipText:createClipText(pname:getContentSize(), "")
	clipText:setTextFontSize(30)
	clipText:setTextColor(cc.c3b(177, 139, 80))
	clipText:setAnchorPoint(pname:getAnchorPoint())
	clipText:setPosition(pname:getPosition())
	temp:addChild(clipText)
	pname:removeFromParent()
	self.m_winSelfName = clipText

	self.m_winBankerScore = temp:getChildByName("num_banker")
	self.m_winSelfScore = temp:getChildByName("num_self")
	self.m_winmaohao = temp:getChildByName("txt_maohao_1")
	self.m_winmaohao1 = temp:getChildByName("txt_maohao_0")
end

function GameResultLayer:initFailedLayer()
	local csbNode = ExternalFun.loadCSB("GameFailed.csb", self)
	csbNode:setVisible(false)
	self.m_failedNode = csbNode

	self.m_failedAction = ExternalFun.loadTimeLine("GameFailed.csb", self)
	self.m_failedAction:retain()

	local temp = csbNode:getChildByName("im_failed")
	temp = temp:getChildByName("num_score")
	self.m_failedscore = temp

	--庄家名称
	temp = csbNode:getChildByName("im_frame")
	local pname = temp:getChildByName("txt_banker")
	local clipText = ClipText:createClipText(pname:getContentSize(), "")
	clipText:setTextFontSize(30)
	clipText:setAnchorPoint(pname:getAnchorPoint())
	clipText:setPosition(pname:getPosition())
	clipText:setTextColor(cc.c3b(177, 139, 80))
	temp:addChild(clipText)
	pname:removeFromParent()
	self.m_failedBankerName = clipText

	--玩家名称
	pname = temp:getChildByName("txt_self")
	clipText = ClipText:createClipText(pname:getContentSize(), "")
	clipText:setTextFontSize(30)
	clipText:setTextColor(cc.c3b(177, 139, 80))
	clipText:setAnchorPoint(pname:getAnchorPoint())
	clipText:setPosition(pname:getPosition())
	temp:addChild(clipText)
	pname:removeFromParent()
	self.m_failedSelfName = clipText

	self.m_failedBankerScore = temp:getChildByName("num_banker")
	self.m_failedSelfScore = temp:getChildByName("num_self")
	self.m_failedmaohao = temp:getChildByName("txt_maohao_1")
	self.m_failedmaohao1 = temp:getChildByName("txt_maohao_0")
end

function GameResultLayer:showGameResult(selfscore, bankerscore, bankername, bbanker)
	self.m_selfscore = selfscore
	self.m_bankerscore = bankerscore
	self.m_bbanker = bbanker
	self.m_selfname = "自 己"
	self.m_bankername = "庄 家"
	self:setVisible(true)
	if selfscore > 0 then
		self:showGameWin()
	else
		self:showGameFailed()
	end
end

function GameResultLayer:showGameWin()
	if nil == self.m_winNode then
		self:initWinLayer()
	end
	if nil  ~= self.m_failedNode then
		self.m_failedNode:setVisible(false)
		self.m_failedNode:stopAllActions()
	end
	
	self.m_winNode:setVisible(true)

	self.m_winNode:stopAllActions()
	self.m_winAction:gotoFrameAndPlay(0, false)
	self.m_winNode:runAction(self.m_winAction)

	local winstr = "/"..self.m_selfscore
	self.m_winScore:setString(winstr)

	self.m_winBankerName:setString(self.m_bankername)
	local bankerstr = ExternalFun.numberThousands(self.m_bankerscore)
	if self.m_bankerscore > 0 then
		bankerstr = "+"..bankerstr
	end
	self.m_winBankerScore:setString(bankerstr)
	self.m_winSelfName:setString(self.m_selfname)
	local scorestr = ExternalFun.numberThousands(self.m_selfscore)
	if self.m_selfscore > 0 then
		scorestr = "+"..scorestr
	end
	self.m_winSelfScore:setString(scorestr)
	-- if self.m_bbanker == true then
	-- 	self.m_winSelfName:setVisible(false)
	-- 	self.m_winSelfScore:setVisible(false)
	-- 	self.m_winmaohao:setVisible(false)
	-- else
	-- 	self.m_winSelfName:setVisible(true)
	-- 	self.m_winSelfScore:setVisible(true)
	-- 	self.m_winmaohao:setVisible(true)
	-- end

	if self.m_bankerscore >= 0 then
		self.m_winBankerName:setTextColor(wincolor)
		self.m_winBankerScore:setTextColor(wincolor)
		self.m_winmaohao1:setTextColor(wincolor)
	else
		self.m_winBankerName:setTextColor(failedcolor)
		self.m_winBankerScore:setTextColor(failedcolor)
		self.m_winmaohao1:setTextColor(failedcolor)
	end

	if self.m_selfscore >= 0 then
		self.m_winSelfName:setTextColor(wincolor)
		self.m_winSelfScore:setTextColor(wincolor)
		self.m_winmaohao:setTextColor(wincolor)
	else
		self.m_winSelfName:setTextColor(failedcolor)
		self.m_winSelfScore:setTextColor(failedcolor)
		self.m_winmaohao:setTextColor(failedcolor)
	end

	ExternalFun.playSoundEffect("gameWin.wav")
end

function GameResultLayer:showGameFailed()
	if nil == self.m_failedNode then
		self:initFailedLayer()
	end
	if nil  ~= self.m_winNode then
		self.m_winNode:setVisible(false)
		self.m_winNode:stopAllActions()
	end

	self.m_failedNode:setVisible(true)

	self.m_failedNode:stopAllActions()
	self.m_failedAction:gotoFrameAndPlay(0, false)
	self.m_failedNode:runAction(self.m_failedAction)

	local winstr = "/"..self.m_selfscore
	self.m_failedscore:setString(winstr)

	self.m_failedBankerName:setString(self.m_bankername)
	local bankerstr = ExternalFun.numberThousands(self.m_bankerscore)
	if self.m_bankerscore > 0 then
		bankerstr = "+"..bankerstr
	end
	self.m_failedBankerScore:setString(bankerstr)
	self.m_failedSelfName:setString(self.m_selfname)
	local scorestr = ExternalFun.numberThousands(self.m_selfscore)
	if self.m_selfscore > 0 then
		scorestr = "+"..scorestr
	end
	self.m_failedSelfScore:setString(scorestr)
	-- if self.m_bbanker == true then
	-- 	self.m_failedSelfName:setVisible(false)
	-- 	self.m_failedSelfScore:setVisible(false)
	-- 	self.m_failedmaohao:setVisible(false)
	-- else
	-- 	self.m_failedSelfName:setVisible(true)
	-- 	self.m_failedSelfScore:setVisible(true)
	-- 	self.m_failedmaohao:setVisible(true)
	-- end

	if self.m_bankerscore >= 0 then
		self.m_failedBankerName:setTextColor(wincolor)
		self.m_failedBankerScore:setTextColor(wincolor)
		self.m_failedmaohao1:setTextColor(wincolor)
	else
		self.m_failedBankerName:setTextColor(failedcolor)
		self.m_failedBankerScore:setTextColor(failedcolor)
		self.m_failedmaohao1:setTextColor(failedcolor)
	end

	if self.m_selfscore >= 0 then
		self.m_failedSelfName:setTextColor(wincolor)
		self.m_failedSelfScore:setTextColor(wincolor)
		self.m_failedmaohao:setTextColor(wincolor)
	else
		self.m_failedSelfName:setTextColor(failedcolor)
		self.m_failedSelfScore:setTextColor(failedcolor)
		self.m_failedmaohao:setTextColor(failedcolor)
	end

	ExternalFun.playSoundEffect("gameLose.wav")
end

function GameResultLayer:clear()
	if nil ~= self.m_failedNode then
		self.m_failedNode:stopAllActions()
		self.m_failedAction:release()
	end

	if nil ~= self.m_winNode then
		self.m_winNode:stopAllActions()
		self.m_winAction:release()
	end
end

return GameResultLayer