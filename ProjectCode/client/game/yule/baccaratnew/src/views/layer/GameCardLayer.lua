--
-- Author: zhong
-- Date: 2016-07-15 11:03:17
--
--游戏扑克层
local GameCardLayer = class("GameCardLayer", cc.Layer)

local module_pre = "game.yule.baccaratnew.src"
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local g_var = ExternalFun.req_var;
local CardsNode = module_pre .. ".views.layer.gamecard.CardsNode"
local GameLogic = module_pre .. ".models.GameLogic"
local cmd = module_pre .. ".models.CMD_Game"
local bjlDefine = module_pre .. ".models.bjlGameDefine"

local scheduler = cc.Director:getInstance():getScheduler()

local kPointDefault = 0
local kDraw = 1 --平局
local kIdleWin = 2 --闲赢
local kMasterWin = 3 --庄赢
local DIS_SPEED = 0.5
local DELAY_TIME = 1.0
local kLEFT_ROLE = 1
local kRIGHT_ROLE = 2

function GameCardLayer:ctor(parent)
	self.m_parent = parent
	--加载csb资源
	local csbNode = ExternalFun.loadCSB("game/GameCardLayer.csb",self)	
	self.m_actionNode = csbNode
	csbNode:setVisible(false)
	self.m_action = nil

	--点数
	self.m_tabPoint = {}
	self.m_tabPoint[kLEFT_ROLE] = csbNode:getChildByName("idle_res_sp")
	self.m_tabPoint[kRIGHT_ROLE] = csbNode:getChildByName("master_res_sp")

	--状态
	self.m_tabStatus = {}
	self.m_tabStatus[kLEFT_ROLE] = csbNode:getChildByName("idle_sp")
	self.m_tabStatus[kRIGHT_ROLE] = csbNode:getChildByName("master_sp")

	--平局
	self.m_spDraw = csbNode:getChildByName("draw_sp")

	--pk精灵
	self.m_spPk = csbNode:getChildByName("ani_pk")
	--左右底板
	self.m_spLeftBoard = csbNode:getChildByName("sp_pk_l_1")
	self.m_spRightBoard = csbNode:getChildByName("sp_pk_r_2")

	--扑克
	self.m_tabCards = {}	
	local idle = g_var(CardsNode):createEmptyCardsNode()
	idle:setPosition(334, 400)
	csbNode:addChild(idle)
	self.m_tabCards[kLEFT_ROLE] = idle

	local master = g_var(CardsNode):createEmptyCardsNode()
	master:setPosition(1000, 400)
	csbNode:addChild(master)
	self.m_tabCards[kRIGHT_ROLE] = master	

	self.m_vecDispatchCards = {}
	self.m_nTotalCount = 0
	self.m_scheduler = nil
	self.m_nDispatchedCount = 0
	self.m_bAnimation = false

	self:reSet()
end

function GameCardLayer:clean(  )
	if nil ~= self.m_action then
		self.m_action:release()
	end

	if nil ~= self.m_scheduler then
		scheduler:unscheduleScriptEntry(self.m_scheduler)
		self.m_scheduler = nil
	end

	self.m_actionNode:stopAllActions()
end

function GameCardLayer:showLayer( var )
	self.m_actionNode:setVisible(var)
	self:setVisible(var)
	if false == var then
		self.m_actionNode:stopAllActions()
		if nil ~= self.m_scheduler then
			print("stop dispatch")
			scheduler:unscheduleScriptEntry(self.m_scheduler)
			self.m_scheduler = nil
		end
	end
end

function GameCardLayer:refresh( tabRes, bAni, cbTime )
	self:reSet()

	local m_nTotalCount = #tabRes.m_idleCards + #tabRes.m_masterCards
	self.m_nTotalCount = m_nTotalCount

	local masterIdx = 1
	local idleIdx = 1
	local loopCount = m_nTotalCount - 1
	for i = 0, loopCount do
		local dis = g_var(bjlDefine).getEmptyDispatchCard()		
		if 0 ~= bit:_and(i,1) then
			if nil ~= tabRes.m_masterCards[masterIdx] then
				dis.m_dir = kRIGHT_ROLE
				dis.m_cbCardData = tabRes.m_masterCards[masterIdx]
				masterIdx = masterIdx + 1
			else
				dis.m_dir = kLEFT_ROLE
				dis.m_cbCardData = tabRes.m_idleCards[idleIdx]
				idleIdx = idleIdx + 1
			end
		else
			if nil ~= tabRes.m_idleCards[idleIdx] then
				dis.m_dir = kLEFT_ROLE
				dis.m_cbCardData = tabRes.m_idleCards[idleIdx]
				idleIdx = idleIdx + 1
			else
				dis.m_dir = kRIGHT_ROLE
				dis.m_cbCardData = tabRes.m_masterCards[masterIdx]
				masterIdx = masterIdx + 1
			end
		end

		if 0 == dis.m_cbCardData then
			print("dis error")
		end		
		table.insert(self.m_vecDispatchCards, dis)
	end	
	
	self.m_bAnimation = bAni
	if bAni then
		self:switchLayout(false)
		if nil == self.m_action then 
			self:initAni()
		end
		self.m_actionNode:stopAllActions()
		self.m_action:gotoFrameAndPlay(0,false)	
		self.m_actionNode:runAction(self.m_action)	
	else
		self:switchLayout(true)
		self.m_tabStatus[kLEFT_ROLE]:setVisible(true)
		self.m_tabStatus[kRIGHT_ROLE]:setVisible(true)

		--刷新点数
		self.m_tabCards[kLEFT_ROLE]:updateCardsNode(tabRes.m_idleCards, true, false)
		self.m_tabCards[kLEFT_ROLE]:setScale(0.75)
		self:refreshPoint(kLEFT_ROLE)
		
		self.m_tabCards[kRIGHT_ROLE]:updateCardsNode(tabRes.m_masterCards, true, false)
		self.m_tabCards[kRIGHT_ROLE]:setScale(0.75)
		self:refreshPoint(kRIGHT_ROLE)		

		self:calResult()
	end	
end

function GameCardLayer:initAni(  )
	local act = ExternalFun.loadTimeLine("game/GameCardLayer.csb")
	self.m_action = act
	self.m_action:retain()
	local function onFrameEvent( frame )
		if nil == frame then
            return
        end        

        local str = frame:getEvent()
        print("frame event ==> "  .. str)
        if str == "end_fun" 
        and true == self.m_bAnimation
        and true == self:isVisible() then
        	self.m_actionNode:stopAllActions()
        	self:onAnimationEnd()
        elseif str == "end_draw" then
        	self:switchLayout(true)
        end
	end
	act:setFrameEventCallFunc(onFrameEvent)
end

function GameCardLayer:reSet()
	self.m_vecDispatchCards = {}

	local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("room_clearing_ldlefail.png")
	if nil == frame then
		frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("blank.png")
	end
	self.m_tabStatus[kLEFT_ROLE]:setSpriteFrame(frame)

	frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("room_clearing_masterfail.png")
	if nil == frame then
		frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("blank.png")
	end
	self.m_tabStatus[kRIGHT_ROLE]:setSpriteFrame(frame)

	self.m_tabCards[kLEFT_ROLE]:removeAllCards()
	self.m_tabCards[kRIGHT_ROLE]:removeAllCards()

	frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("blank.png")
	self.m_tabPoint[kLEFT_ROLE]:setSpriteFrame(frame)
	self.m_tabPoint[kRIGHT_ROLE]:setSpriteFrame(frame)
	self.m_spDraw:setVisible(false)

	self.m_nTotalCount = 0
	self.m_nDispatchedCount = 0
	self.m_enPointResult = kPointDefault

	self.m_tabStatus[kLEFT_ROLE]:setPosition(334, 519)
	self.m_tabStatus[kLEFT_ROLE]:setOpacity(255)
	self.m_tabStatus[kRIGHT_ROLE]:setPosition(1000, 519)
	self.m_tabStatus[kRIGHT_ROLE]:setOpacity(255)
end

function GameCardLayer:onAnimationEnd( )
	--定时器发牌
	local function countDown(dt)
		self:dispatchUpdate()
	end
	if nil == self.m_scheduler then
		self.m_scheduler = scheduler:scheduleScriptFunc(countDown, DIS_SPEED, false)
	end
end

function GameCardLayer:dispatchUpdate( )
	if 0 ~= #self.m_vecDispatchCards then
		self.m_nDispatchedCount = self.m_nDispatchedCount + 1
		local dis = self.m_vecDispatchCards[1]
		table.remove(self.m_vecDispatchCards, 1)

		local cbCard = dis.m_cbCardData
		local function callFun( sender, tab )
			self:refreshPoint(tab[1])
		end
		self:addCards(cbCard, dis.m_dir, cc.CallFunc:create(callFun,{dis.m_dir}))

		self:noticeTips()
	else
		self:calResult()
		if nil ~= self.m_scheduler then
			scheduler:unscheduleScriptEntry(self.m_scheduler)
			self.m_scheduler = nil
		end	

		if nil ~= self.m_parent then
			self.m_parent:showBetAreaBlink()
		end
	end
end

function GameCardLayer:calResult( )
	--不做排序，按顺序计算
	local idleCards = self.m_tabCards[kLEFT_ROLE]:getHandCards()
	--g_var(GameLogic).SortCardList(idleCards, GameLogic.ST_ORDER)
	local idlePoint = g_var(GameLogic).GetCardListPip(idleCards)

	local masterCards = self.m_tabCards[kRIGHT_ROLE]:getHandCards()
	--g_var(GameLogic).SortCardList(masterCards, GameLogic.ST_ORDER)
	local masterPoint = g_var(GameLogic).GetCardListPip(masterCards)
	--点数记录
	self.m_parent:getDataMgr().m_tabGameResult.m_cbIdlePoint = idlePoint
	self.m_parent:getDataMgr().m_tabGameResult.m_cbMasterPoint = masterPoint

	local nowCBWinner = g_var(cmd).AREA_MAX
	local nowCBKingWinner = g_var(cmd).AREA_MAX

	local cbBetAreaBlink = {0,0,0,0,0,0,0,0}
	if idlePoint > masterPoint then		
		self.m_enPointResult = kIdleWin

		--闲
		nowCBWinner = g_var(cmd).AREA_XIAN
		cbBetAreaBlink[g_var(cmd).AREA_XIAN + 1] = 1
		--闲天王
		if 8 == idlePoint or 9 == idlePoint then
			nowCBKingWinner = g_var(cmd).AREA_XIAN_TIAN
			cbBetAreaBlink[g_var(cmd).AREA_XIAN_TIAN + 1] = 1
		end
	elseif idlePoint < masterPoint then
		self.m_enPointResult = kMasterWin

		--庄
		nowCBWinner = g_var(cmd).AREA_ZHUANG
		cbBetAreaBlink[g_var(cmd).AREA_ZHUANG + 1] = 1
		if 8 == masterPoint or 9 == masterPoint then
			nowCBKingWinner = g_var(cmd).AREA_ZHUANG_TIAN
			cbBetAreaBlink[g_var(cmd).AREA_ZHUANG_TIAN + 1] = 1
		end
	elseif idlePoint == masterPoint then
		self.m_enPointResult = kDraw

		--平
		nowCBWinner = g_var(cmd).AREA_PING
		cbBetAreaBlink[g_var(cmd).AREA_PING + 1] = 1
		--判断是否为同点平
		local bAllPointSame = false
		if #idleCards == #masterCards then
			local cbCardIdx = 1
			for i = cbCardIdx, #idleCards do
				local cbBankerValue = g_var(GameLogic).GetCardValue(masterCards[cbCardIdx])
				local cbIdleValue = g_var(GameLogic).GetCardValue(idleCards[cbCardIdx])

				if cbBankerValue ~= cbIdleValue then
					break
				end

				if cbCardIdx == #masterCards then
					bAllPointSame = true
				end
			end
		end

		--同点平
		if true == bAllPointSame then
			nowCBKingWinner = g_var(cmd).AREA_TONG_DUI
			cbBetAreaBlink[g_var(cmd).AREA_TONG_DUI + 1] = 1
		end
	end

	--对子判断
	local nowBIdleTwoPair = false
	local nowBMasterTwoPair = false
	--闲对子
	if g_var(GameLogic).GetCardValue(idleCards[1]) == g_var(GameLogic).GetCardValue(idleCards[2]) then
		nowBIdleTwoPair = true
		cbBetAreaBlink[g_var(cmd).AREA_XIAN_DUI + 1] = 1
	end
	--庄对子
	if g_var(GameLogic).GetCardValue(masterCards[1]) == g_var(GameLogic).GetCardValue(masterCards[2]) then
		nowBMasterTwoPair = true
		cbBetAreaBlink[g_var(cmd).AREA_ZHUANG_DUI + 1] = 1
	end
	self.m_parent:getDataMgr().m_tabBetArea = cbBetAreaBlink

	local bJoin = self.m_parent:getDataMgr().m_bJoin
	local res = self.m_parent:getDataMgr().m_tabGameResult
	if nil ~= self.m_parent and false == yl.m_bDynamicJoin then
		--添加路单记录
		local rec = g_var(bjlDefine).getEmptyRecord()

        local serverrecord = g_var(bjlDefine).getEmptyServerRecord()
        serverrecord.cbKingWinner = nowCBKingWinner
        serverrecord.bPlayerTwoPair = nowBIdleTwoPair
        serverrecord.bBankerTwoPair = nowBMasterTwoPair
        serverrecord.cbPlayerCount = idlePoint
        serverrecord.cbBankerCount = masterPoint
        rec.m_pServerRecord = serverrecord
        rec.m_cbGameResult = nowCBWinner
        
        rec.m_tagUserRecord.m_bJoin = bJoin
        if bJoin then        	
        	rec.m_tagUserRecord.m_bWin = res.m_llTotal > 0
        end

        self.m_parent:getDataMgr():addGameRecord(rec)
	end

	--刷新结果
	self:refreshResult(self.m_enPointResult)

	--播放音效
	if true == bJoin then
		--
		if res.m_llTotal > 0 then
			ExternalFun.playSoundEffect("END_WIN.wav")
		elseif res.m_llTotal < 0 then
			ExternalFun.playSoundEffect("END_LOST.wav")
		else
			ExternalFun.playSoundEffect("END_DRAW.wav")
		end
	else
		ExternalFun.playSoundEffect("END_DRAW.wav")
	end
end

function GameCardLayer:addCards( cbCard, dir, pCallBack )
	--print("on add card:" .. g_var(GameLogic).GetCardValue(cbCard) .. ";dir " .. dir)
	if nil == self.m_tabCards[dir] then
		return
	end

	if nil ~= pCallBack then
		pCallBack:retain()
	end
	self.m_tabCards[dir]:addCards(cbCard, pCallBack)
end

function GameCardLayer:refreshPoint( dir )
	if nil == self.m_tabCards[dir] then
		return
	end
	local handCards = self.m_tabCards[dir]:getHandCards()

	--切换动画
	local sca = cc.ScaleTo:create(0.2,0.0001,1.0)
	local call = cc.CallFunc:create(function ()
		local point = g_var(GameLogic).GetCardListPip(handCards)
		local str = string.format("clearing_%d.png", point)
		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(str)
		if nil ~= frame then
			self.m_tabPoint[dir]:setSpriteFrame(frame)
		end
	end)
	local sca2 = cc.ScaleTo:create(0.2,1.0)
	local seq = cc.Sequence:create(sca, call, sca2)
	self.m_tabPoint[dir]:stopAllActions()
	self.m_tabPoint[dir]:runAction(seq)
end

function GameCardLayer:refreshResult( enResult )
	local call_switch = cc.CallFunc:create(function()
		self:switchLayout(true)
	end)

	if kDraw == enResult then
		if nil == self.m_action then 
			self:initAni()
		end
		self.m_actionNode:stopAllActions()
		self.m_action:gotoFrameAndPlay(10,false)	
		self.m_actionNode:runAction(self.m_action)
	elseif kIdleWin == enResult then
		local sca = cc.ScaleTo:create(0.2,0.0001,1.0)
		local call = cc.CallFunc:create(function(  )
			local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("room_clearing_ldlewin.png")
			if nil ~= frame then
				self.m_tabStatus[kLEFT_ROLE]:setSpriteFrame(frame)
			end
		end)
		local sca2 = cc.ScaleTo:create(0.2,1.0)
		local seq = cc.Sequence:create(sca, call, sca2, cc.DelayTime:create(0.5), call_switch)
		self.m_tabStatus[kLEFT_ROLE]:stopAllActions()
		self.m_tabStatus[kLEFT_ROLE]:runAction(seq)
	elseif kMasterWin == enResult then
		local sca = cc.ScaleTo:create(0.2,0.0001,1.0)
		local call = cc.CallFunc:create(function(  )
			local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("room_clearing_masterwin.png")
			if nil ~= frame then
				self.m_tabStatus[kRIGHT_ROLE]:setSpriteFrame(frame)
			end
		end)
		local sca2 = cc.ScaleTo:create(0.2,1.0)
		local seq = cc.Sequence:create(sca, call, sca2, cc.DelayTime:create(0.5), call_switch)
		self.m_tabStatus[kRIGHT_ROLE]:stopAllActions()
		self.m_tabStatus[kRIGHT_ROLE]:runAction(seq)
	end
end

function GameCardLayer:noticeTips(  )
	local m_nTotalCount = self.m_nTotalCount
	local m_nDispatchedCount = self.m_nDispatchedCount

	if m_nTotalCount > 4 then
		if m_nDispatchedCount >= 4 and nil ~= self.m_scheduler then
			scheduler:unscheduleScriptEntry(self.m_scheduler)
			self.m_scheduler = nil
			local call = cc.CallFunc:create(function()
				self:onAnimationEnd()
			end)
			local seq = cc.Sequence:create(cc.DelayTime:create(DELAY_TIME), call)
			self:stopAllActions()
			self:runAction(seq)
		end

		local idleCards = self.m_tabCards[kLEFT_ROLE]:getHandCards()
		--g_var(GameLogic).SortCardList(idleCards, GameLogic.ST_ORDER)
		local idlePoint = g_var(GameLogic).GetCardListPip(idleCards)

		local masterCards = self.m_tabCards[kRIGHT_ROLE]:getHandCards()
		--g_var(GameLogic).SortCardList(masterCards, GameLogic.ST_ORDER)
		local masterPoint = g_var(GameLogic).GetCardListPip(masterCards)

		local idleCount = #idleCards
		local masterCount = #masterCards
		local str = ""
		if m_nDispatchedCount == 4 then
			if idleCount == 2 and (6 == idlePoint or 7 == idlePoint) then
				str = string.format("闲前两张 %d 点,庄 %d 点,庄继续拿牌", idlePoint, masterPoint)
			elseif idleCount == 2 and idlePoint < 6 then
				str = string.format("闲 %d 点, 庄 %d 点,闲继续拿牌", idlePoint, masterPoint)
			elseif idleCount == 2 and (masterPoint >= 3 and masterPoint <= 5) then
				str = string.format("闲不补牌, 庄 %d 点,闲继续拿牌", masterPoint)
			end
		elseif m_nDispatchedCount == 5 then
			if idleCount == 3 and masterCount == 2 and m_nTotalCount == 6 then
				local cbValue = g_var(GameLogic).GetCardPip(idleCards[3])
				str = string.format("闲第三张牌 %d 点,庄 %d 点,庄继续拿牌", cbValue, masterPoint)
			end
		end

		if "" ~= str then
			showToast(self,str,1)
		end
	end
end

--调整显示界面 bDisOver 是否发牌结束
function GameCardLayer:switchLayout( bDisOver )
	if bDisOver then 
		if self.m_enPointResult == kDraw then
			self:cardMoveAni()
		else
			--状态位置挪动
			local mo = cc.MoveTo:create(0.2, cc.p(434, 519))
			self.m_tabStatus[kLEFT_ROLE]:stopAllActions()
			self.m_tabStatus[kLEFT_ROLE]:runAction(mo)

			mo = cc.MoveTo:create(0.2, cc.p(900, 519))
			local call = cc.CallFunc:create(function()
				self:cardMoveAni()
			end)
			local seq = cc.Sequence:create(mo, cc.DelayTime:create(0.5), call)
			self.m_tabStatus[kRIGHT_ROLE]:stopAllActions()
			self.m_tabStatus[kRIGHT_ROLE]:runAction(seq)
		end				
	else
		--回位
		self.m_tabCards[kLEFT_ROLE]:stopAllActions()
		self.m_tabCards[kLEFT_ROLE]:setScale(1.0)
		self.m_tabCards[kLEFT_ROLE]:setPosition(334, 400)
		self.m_tabCards[kRIGHT_ROLE]:stopAllActions()
		self.m_tabCards[kRIGHT_ROLE]:setScale(1.0)
		self.m_tabCards[kRIGHT_ROLE]:setPosition(1000, 400)	

		self.m_tabStatus[kLEFT_ROLE]:setPosition(334, 519)
		self.m_tabStatus[kLEFT_ROLE]:setOpacity(255)
		self.m_tabStatus[kRIGHT_ROLE]:setPosition(1000, 519)
		self.m_tabStatus[kRIGHT_ROLE]:setOpacity(255)

		self.m_tabPoint[kLEFT_ROLE]:setPosition(334, 296)
		self.m_tabPoint[kRIGHT_ROLE]:setPosition(1000, 296)
		self.m_spPk:setVisible(true)
	end
end

function GameCardLayer:cardMoveAni(  )
	--扑克、点数，移动位置
	self.m_tabCards[kLEFT_ROLE]:stopAllActions()
	local move = cc.MoveTo:create(0.2, cc.p(434,400))
	local scal = cc.ScaleTo:create(0.2, 0.75)
	local spa = cc.Spawn:create(move, scal)
	self.m_tabCards[kLEFT_ROLE]:runAction(spa)

	self.m_tabCards[kRIGHT_ROLE]:stopAllActions()
	move = cc.MoveTo:create(0.2, cc.p(900,400))
	scal = cc.ScaleTo:create(0.2, 0.75)
	spa = cc.Spawn:create(move, scal)
	self.m_tabCards[kRIGHT_ROLE]:runAction(spa)

	move = cc.MoveTo:create(0.2, cc.p(434,296))
	self.m_tabPoint[kLEFT_ROLE]:stopAllActions()
	self.m_tabPoint[kLEFT_ROLE]:runAction(move)

	move = cc.MoveTo:create(0.2, cc.p(900,296))
	self.m_tabPoint[kRIGHT_ROLE]:stopAllActions()
	self.m_tabPoint[kRIGHT_ROLE]:runAction(move)

	self:showAniBoard(false)
end

function GameCardLayer:showAniBoard( bShow )
	self.m_spLeftBoard:setVisible(bShow)
	self.m_spRightBoard:setVisible(bShow)
	self.m_spPk:setVisible(bShow)
end

return GameCardLayer