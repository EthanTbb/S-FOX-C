local GameViewLayer = class("GameViewLayer",function(scene)
		local gameViewLayer =  display.newLayer()
    return gameViewLayer
end)
local module_pre = "game.yule.sicbobattle.src"
GameViewLayer.RES_PATH = "game/yule/sicbobattle/res/"
--external
--
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local g_var = ExternalFun.req_var
local ClipText = appdf.EXTERNAL_SRC .. "ClipText"
local PopupInfoHead = appdf.EXTERNAL_SRC .. "PopupInfoHead"
--

local cmd = module_pre .. ".models.CMD_Game"
local game_cmd = appdf.HEADER_SRC .. "CMD_GameServer"
local QueryDialog   = require("app.views.layer.other.QueryDialog")

--utils
--
local UserListLayer = module_pre .. ".views.layer.userlist.UserListLayer"
local ApplyListLayer = module_pre .. ".views.layer.userlist.ApplyListLayer"
local BtnListLayer = module_pre .. ".views.layer.BtnListLayer"
local SettingLayer = module_pre .. ".views.layer.SetLayer"
--

GameViewLayer.TAG_START				= 100
local enumTable = 
{
	"BT_EXIT",
	"BT_START",
	"BT_LUDAN",
	"BT_BANK",
	"BT_SET",
	"BT_RULE",
	"BT_ROBBANKER",
	"BT_APPLYBANKER",
	"BT_USERLIST",
	"BT_APPLYLIST",
	"BANK_LAYER",
	"BT_CLOSEBANK",
	"BT_TAKESCORE",
	"BT_MENU"
}
local TAG_ENUM = ExternalFun.declarEnumWithTable(GameViewLayer.TAG_START, enumTable);
local zorders = 
{
	"CLOCK_ZORDER",
	"SITDOWN_ZORDER",
	"DROPDOWN_ZORDER",
	"DROPDOWN_CHECK_ZORDER",
	"GAMECARD_ZORDER",
	"SETTING_ZORDER",
	"ROLEINFO_ZORDER",
	"RULE_ZORDER",
	"BANK_ZORDER",
	"USERLIST_ZORDER",
	"WALLBILL_ZORDER",
	"BTNLISTLAYER_ZORDER",

	"GAMERS_ZORDER",	
	"ENDCLOCK_ZORDER"
}
local TAG_ZORDER = ExternalFun.declarEnumWithTable(1, zorders);

local enumApply =
{
	"kCancelState",
	"kApplyState",
	"kApplyedState",
	"kSupperApplyed"
}
GameViewLayer._apply_state = ExternalFun.declarEnumWithTable(0, enumApply)
local APPLY_STATE = GameViewLayer._apply_state

--默认选中的筹码
local DEFAULT_BET = 1
--筹码运行时间
local BET_ANITIME = 0.2

function GameViewLayer:ctor(scene)
	--注册node事件
	ExternalFun.registerNodeEvent(self)
	
	self._scene = scene
	self:gameDataInit();
	--初始化csb界面
	self:initCsbRes();
	--初始化通用动作
	self:initAction();
end

function GameViewLayer:loadRes(  )
	--加载plist
	cc.SpriteFrameCache:getInstance():addSpriteFrames(GameViewLayer.RES_PATH.."game/118_gameLayer.plist")
	cc.SpriteFrameCache:getInstance():addSpriteFrames(GameViewLayer.RES_PATH.."game/118_diceAni.plist")
	cc.SpriteFrameCache:getInstance():addSpriteFrames(GameViewLayer.RES_PATH.."game/118_userList.plist")
	cc.SpriteFrameCache:getInstance():addSpriteFrames(GameViewLayer.RES_PATH.."game/118_applyList.plist")
	cc.SpriteFrameCache:getInstance():addSpriteFrames(GameViewLayer.RES_PATH.."bank/118_bank.plist")
	cc.SpriteFrameCache:getInstance():addSpriteFrames(GameViewLayer.RES_PATH.."set/118_setLayer.plist")
end

---------------------------------------------------------------------------------------
--界面初始化
function GameViewLayer:initCsbRes(  )
	print("ljb --------initCsbRes")
	local rootLayer, csbNode = ExternalFun.loadRootCSB(GameViewLayer.RES_PATH .. "118_gameLayer.csb", self);
	self.m_rootLayer = rootLayer
	self._csbNode = csbNode


	--摇骰子的节点
	self.m_nodeDiceBg = self._csbNode:getChildByName("Node_dice")

	--轮庄tip
	self.m_nodeBankerTip = self._csbNode:getChildByName("Node_tips")

	--初始化按钮
	self:initBtn(csbNode);

	--初始化庄家信息
	self:initBankerInfo();

	--初始化玩家信息
	self:initUserInfo(csbNode);

	--初始化桌面下注
	self:initJetton(csbNode);

	--刷新上庄列表
	self:refreshAppLyInfo()

	--倒计时
	self:createClockNode(csbNode)
end

function GameViewLayer:reSet(  )

end

function GameViewLayer:reSetForNewGame(  )
	--重置下注区域
	self:cleanJettonArea()
	--闪烁停止
	self:jettonAreaBlinkClean()

	self:showGameResult(false)
end

--初始化按钮
function GameViewLayer:initBtn( csbNode )
	------

	------
	--按钮列表
	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onButtonClickedEvent(sender:getTag(), sender);
		end
	end

	-- local btn_list = csbNode:getChildByName("Sprite_ListBtn");
	-- self.m_btnList = btn_list;
	-- btn_list:setScaleY(0.0000001)
	-- btn_list:setLocalZOrder(TAG_ZORDER.DROPDOWN_ZORDER)

	--self.m_btnList = btn_list;
	--btn_list:setLocalZOrder(TAG_ZORDER.DROPDOWN_ZORDER)

	-- --离开
	-- local btn = self.m_btnListLayer.m_spBg:getChildByName("Button_back");
	-- btn:setTag(TAG_ENUM.BT_EXIT);
	-- btn:addTouchEventListener(btnEvent);

	-- --规则
	-- btn = self.m_btnListLayer.m_spBg:getChildByName("Button_rule");
	-- btn:setTag(TAG_ENUM.BT_RULE);
	-- btn:addTouchEventListener(btnEvent);

	-- --银行
	-- btn = self.m_btnListLayer.m_spBg:getChildByName("Button_bank");
	-- btn:setTag(TAG_ENUM.BT_BANK);
	-- btn:addTouchEventListener(btnEvent);

	-- --玩家列表
	-- btn = self.m_btnListLayer.m_spBg:getChildByName("Button_playList");
	-- btn:setTag(TAG_ENUM.BT_USERLIST);
	-- btn:addTouchEventListener(btnEvent);

	--菜单
	self.m_BtnMenu = csbNode:getChildByName("Button_menu");
	self.m_BtnMenu:addTouchEventListener(btnEvent);
	self.m_BtnMenu:setTag(TAG_ENUM.BT_MENU);

	------

	------
	--上庄、抢庄
	local banker_bg = csbNode:getChildByName("Node_zhuangjiaInfo");
	self.m_NodeBankerBg = banker_bg;

	--上庄列表
	btn = csbNode:getChildByName("Button_shangzhuang");
	btn:setTag(TAG_ENUM.BT_APPLYLIST);
	btn:addTouchEventListener(btnEvent);	
	self.m_btnApply = btn;
	------

	--玩家列表
	-- btn = self.m_spBottom:getChildByName("userlist_btn");
	-- btn:setTag(TAG_ENUM.BT_USERLIST);
	-- btn:addTouchEventListener(btnEvent);

	-------------
	--路单 Node_ludan1
	local nodeLudan1 = csbNode:getChildByName("Node_ludan1");
	btn = nodeLudan1:getChildByName("ludan_btn");
	btn:setTag(TAG_ENUM.BT_LUDAN);
	btn:addTouchEventListener(btnEvent);

	local nodeLudan2 = csbNode:getChildByName("Node_ludan2");
	btn = nodeLudan2:getChildByName("ludan_btn");
	btn:setTag(TAG_ENUM.BT_LUDAN);
	btn:addTouchEventListener(btnEvent);
end

--初始化庄家信息
function GameViewLayer:initBankerInfo( ... )
	local banker_bg = self.m_NodeBankerBg;
	--庄家姓名
	local tmp = banker_bg:getChildByName("Text_name");
	self.m_clipBankerNick = g_var(ClipText):createClipText(tmp:getContentSize(), "");
	self.m_clipBankerNick:setAnchorPoint(tmp:getAnchorPoint());
	self.m_clipBankerNick:setPosition(tmp:getPosition());
	banker_bg:addChild(self.m_clipBankerNick);

	--庄家金币
	self.m_textBankerCoin = banker_bg:getChildByName("Text_score");

	--庄家局数 
	self.m_textBankerRound = banker_bg:getChildByName("Text_round");

	--庄家成绩 
	self.m_textBankerChengJi = banker_bg:getChildByName("Text_chengji");


	self:reSetBankerInfo();
end

function GameViewLayer:reSetBankerInfo( )
	self.m_clipBankerNick:setString("");
	self.m_textBankerCoin:setString("");
end

--初始化玩家信息
function GameViewLayer:initUserInfo( csbNode )
	--玩家头像
	local tmp = csbNode:getChildByName("Sprite_headBg")
	local head = g_var(PopupInfoHead):createClipHead(self:getMeUserItem(), tmp:getContentSize().width-20)
	head:setPosition(tmp:getPosition())
	csbNode:addChild(head)
	head:enableInfoPop(true)

	--玩家金币
	self.m_textUserCoin = csbNode:getChildByName("Text_score")

	--玩家当前下注
	self.m_textDangqian = csbNode:getChildByName("Text_dangqian")
	--总共下注
	self.m_textallUserIn = csbNode:getChildByName("Text_allUserIn")

	self:reSetUserInfo()
end

function GameViewLayer:reSetUserInfo( score )
	self.m_scoreUser = 0
	local myUser = self:getMeUserItem()
	if nil ~= myUser then
		self.m_scoreUser = score or  myUser.lScore;
	end
	if score then
		self.m_scoreUser = score
	end
	--自己金币
	local lUserCoin = ExternalFun.formatScoreText(self.m_scoreUser);
	--print("自己金币:" .. lUserCoin)
	self.m_textUserCoin:setString(lUserCoin);
	--自己投注
	local lUserJetton = ExternalFun.formatScoreText(self.m_lHaveJetton);
	print("自己投注:" .. lUserJetton)
	self.m_textDangqian:setString(lUserJetton)

end



--初始化桌面下注
function GameViewLayer:initJetton( csbNode )
	local bottom_sp = self.m_spBottom;
	------
	--下注按钮	
	-- local clip_layout = bottom_sp:getChildByName("clip_layout");
	-- self.m_layoutClip = clip_layout;
	self:initJettonBtnInfo(csbNode);
	------

	------
	--下注区域
	self:initJettonArea(csbNode);
	------

	-----
	--下注胜利提示
	-----
	self:initJettonSp(csbNode);
end

--初始化上庄列表
function GameViewLayer:refreshAppLyInfo()
	local userList = self:getDataMgr():getApplyBankerUserList()
	--print("@@@@@@@@@@@@@@上庄列表@@@@@@@@@@@@@@")
	--print(#userList)
	dump(userList[#userList])
	if self.m_nodeApply == nil then
		self.m_nodeApply= self._csbNode:getChildByName("Node_shangzhuang")
	end
	--local userNum = #userList >= 4 and 4 or #userList
	for i=1,4 do
		--Text_name1
		local nameLabelStr = "Text_name" .. i
		local name = self.m_nodeApply:getChildByName(nameLabelStr)
		--Text_score1
		local scoreLabelStr = "Text_score" .. i
		local score = self.m_nodeApply:getChildByName(scoreLabelStr)

		if userList[#userList-i+1] then
			local str = userList[#userList-i+1].m_userItem.szNickName

			if self.m_labelApplyName[i] == nil then
				self.m_labelApplyName[i] = g_var(ClipText):createClipText(cc.size(120, 20), "",nil,16)
				self.m_labelApplyName[i]:setPosition(cc.p(name:getPositionX(), name:getPositionY()))
				self.m_labelApplyName[i]:setAnchorPoint(cc.p(0,0.5));
				self.m_labelApplyName[i]:setTextColor(cc.c4b(255,255,255,255))
				self.m_nodeApply:addChild(self.m_labelApplyName[i])
				name:setVisible(false)
			else
				self.m_labelApplyName[i]:setVisible(true)
			end

			--print("str",str)
			self.m_labelApplyName[i]:setString(str)

			local scoreStr = ExternalFun.formatScoreText(userList[#userList-i+1].m_userItem.lScore)
			score:setString(scoreStr)
			score:setVisible(true)
		else
			if self.m_labelApplyName[i] then
				self.m_labelApplyName[i]:setVisible(false)
			end
			name:setVisible(false)
			score:setVisible(false)
		end
	end
end

function GameViewLayer:enableJetton( var )
	--下注按钮
	self:reSetJettonBtnInfo(var);

	--下注区域
	self:reSetJettonArea(var);
end

--下注按钮
function GameViewLayer:initJettonBtnInfo( csbNode )
	local clip_layout = csbNode:getChildByName("Node_ChipBtn")
	--local clip_layout = self.m_layoutClip; --Node_Btn

	local function clipEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onJettonButtonClicked(sender:getTag(), sender);
		end
	end

	self.m_pJettonNumber = 
	{
		{k = 500, i = 1},
		{k = 1000, i = 2}, 
		{k = 10000, i = 3}, 
		{k = 100000, i = 4},  
		{k = 1000000, i = 5},
		{k = 5000000, i = 6} 
	}

	self.m_tabJettonAnimate = {}
	for i=1,#self.m_pJettonNumber do
		--local tag = i - 1
		local str = string.format("Button_chip_%d", i)
		local btn = clip_layout:getChildByName(str)

		btn:setTag(i)
		btn:addTouchEventListener(clipEvent)
		self.m_tableJettonBtn[i] = btn
		-- str = string.format("chip%d", tag)
		-- self.m_tabJettonAnimate[i] = clip_layout:getChildByName(str)
	end
	local blink = cc.Blink:create(1.0,1)
	self.m_spriteSelect = clip_layout:getChildByName("Sprite_selectBtn")
	self.m_spriteSelect:runAction(cc.RepeatForever:create(blink))

	self:reSetJettonBtnInfo(false);
end

function GameViewLayer:reSetJettonBtnInfo( var )
	for i=1,#self.m_tableJettonBtn do
		self.m_tableJettonBtn[i]:setTag(i)
		self.m_tableJettonBtn[i]:setEnabled(var)

		self.m_spriteSelect:stopAllActions()
		self.m_spriteSelect:setVisible(true)
		-- self.m_tabJettonAnimate[i]:stopAllActions()
		-- self.m_tabJettonAnimate[i]:setVisible(false)
	end
end

function GameViewLayer:adjustJettonBtn(  )
	--可以下注的数额
	local lCanJetton = self.m_llMaxJetton - self.m_lHaveJetton;
	local lCondition = math.min(self.m_scoreUser, lCanJetton);

	for i=1,#self.m_tableJettonBtn do
		local enable = false
		if self.m_bOnGameRes then
			enable = false
		else
			enable = self.m_bOnGameRes or (lCondition >= self.m_pJettonNumber[i].k)
		end
		self.m_tableJettonBtn[i]:setEnabled(enable);

		--判断是否要换成小一点的筹码
		-- local nextJettonSelect = self.m_nSelectBet > 6 and 6 or self.m_nJettonSelect
		-- local ischange = self.m_tableJettonBtn[self.m_nSelectBet]:isEnabled()
		-- if  enable == false and self.m_bOnGameRes == false and not ischange  then
		-- 	-- print("enable",enable)
		-- 	-- print("m_bOnGameRes",self.m_bOnGameRes)

		-- 	--for i=1,#self.m_tableJettonBtn do
		-- 		if self.m_tableJettonBtn[1]:isEnabled() == true then
		-- 			self:switchJettonBtnState(1)
		-- 			self.m_nJettonSelect = self.m_pJettonNumber[1].k
		-- 			break
		-- 		end
		-- 	--end
		-- -- elseif self.m_cbGameStatus == g_var(cmd).GS_GAME_END then
		-- -- 	self:switchJettonBtnState(1)
		-- end

	end

	if self.m_nJettonSelect > self.m_scoreUser then
		self.m_nJettonSelect = -1;
	end

	--筹码动画
	local enable = lCondition >= self.m_pJettonNumber[self.m_nSelectBet].k;
	if false == enable then

		self.m_spriteSelect:stopAllActions()
		self.m_spriteSelect:setVisible(true)
		-- self.m_tabJettonAnimate[self.m_nSelectBet]:setVisible(false)

	end

end

function GameViewLayer:refreshJetton(  )
	local str = ExternalFun.formatScoreText(self.m_lHaveJetton)
	self.m_textDangqian:setString(str)
	--self.m_userJettonLayout:setVisible(self.m_lHaveJetton > 0)
	--print("self.m_lAllJetton",self.m_lAllJetton)
	local lAllJetton = ExternalFun.formatScoreText(self.m_lAllJetton);
	self.m_textallUserIn:setString(lAllJetton)

end


function GameViewLayer:switchJettonBtnState( idx )
	-- for i=1,#self.m_tabJettonAnimate do
	-- 	self.m_tabJettonAnimate[i]:stopAllActions()
	-- 	self.m_tabJettonAnimate[i]:setVisible(false)
	-- end

	--可以下注的数额
	local lCanJetton = self.m_llMaxJetton - self.m_lHaveJetton;
	local lCondition = math.min(self.m_scoreUser, lCanJetton);
	if nil ~= idx and nil ~= self.m_spriteSelect and nil ~= self.m_tableJettonBtn[idx] then
		local enable = lCondition >= self.m_pJettonNumber[idx].k;
		if enable then
			if self.m_spriteSelect:isRunning() == true then
				local blink = cc.Blink:create(1.0,1)
				self.m_spriteSelect:runAction(cc.RepeatForever:create(blink))
			end
			
			self.m_spriteSelect:setPosition(self.m_tableJettonBtn[idx]:getPositionX(),self.m_tableJettonBtn[idx]:getPositionY())
		end
	end
end

--下注筹码结算动画
function GameViewLayer:betAnimation( )
	local cmd_gameend = self:getDataMgr().m_tabGameEndCmd
	dump(cmd_gameend)
	if nil == cmd_gameend then
		return
	end

	local tmp = self.m_betAreaLayout:getChildren()
	--数量控制
	local maxCount = 300
	local count = 0
	local children = {}
	for k,v in pairs(tmp) do
		table.insert(children, v)
		count = count + 1
		if count > maxCount then
			break
		end
	end
	local left = {}
	-- print("下注筹码结算动画")
	local returnScore = cmd_gameend.lUserReturnScore or cmd_gameend.lEndUserReturnScore
	local returnBankScore = cmd_gameend.lBankerScore or cmd_gameend.lBankerWinScore
	print("returnBankScore",returnBankScore)
	--庄家的
	local meChair =  self:getMeUserItem().wChairID
	local call = cc.CallFunc:create(function()
		--print("庄家的")
		left = self:userBetAnimation(children, "banker", returnBankScore)
	end)
	local delay = cc.DelayTime:create(1)
	--自己的 

	local call2 = cc.CallFunc:create(function()		

		-- print("自己金币回来")
		left = self:userBetAnimation(left, meChair, returnScore)
		self:reSetUserInfo(self.m_scoreUser)
	end)	
	local delay2 = cc.DelayTime:create(0.5)

	--其余玩家的
	local call4 = cc.CallFunc:create(function()
		self:userBetAnimation(left, "other", 1)
		self:refreshApplyList()
		self:refreshUserList()
	end)

	--剩余没有移走的
	local call5 = cc.CallFunc:create(function()
		--下注筹码数量显示移除
		self:cleanJettonArea()
	end)

	local seq = cc.Sequence:create(call, delay, call2, delay2, call4, cc.DelayTime:create(1), call5)
	self:stopAllActions()
	self:runAction(seq)	
end

--玩家分数
function GameViewLayer:userBetAnimation( children, wchair, score )
	if nil == score or score <= 0 then
		return children
	end

	local left = {}
	local getScore = score
	local tmpScore = 0
	local totalIdx = #self.m_pJettonNumber
	local winSize = self.m_betAreaLayout:getContentSize()
	local remove = true
	local count = 0
	for k,v in pairs(children) do
		local idx = nil
		if remove then
			if nil ~= v and v:getTag() == wchair then
				idx = tonumber(v:getName())
				local pos = self.m_betAreaLayout:convertToNodeSpace(self:getBetFromPos(wchair))
				print("自己下注")
				self:generateBetAnimtion(v, {x = pos.x, y = pos.y}, count)
				if nil ~= idx and nil ~= self.m_pJettonNumber[idx] then
					tmpScore = tmpScore + self.m_pJettonNumber[idx].k
				end

				print("wchair tmpScore",tmpScore)
				print("score",score)
				if tmpScore >= score then
					remove = false
				end
			elseif yl.INVALID_CHAIR == wchair then
				--随机抽下注筹码

				idx = self:randomGetBetIdx(getScore, totalIdx)

				local pos = self.m_betAreaLayout:convertToNodeSpace(self:getBetFromPos(wchair))

				if nil ~= idx and nil ~= self.m_pJettonNumber[idx] then
					tmpScore = tmpScore + self.m_pJettonNumber[idx].k
					getScore = getScore - tmpScore
				end

				if tmpScore >= score then

					remove = false
				end
			elseif "banker" == wchair then
				--随机抽下注筹码
				idx = tonumber(v:getName())

				local pos = cc.p(self.m_textBankerCoin:getPositionX(), self.m_textBankerCoin:getPositionY())
				--pos = self.m_textBankerCoin:convertToWorldSpace(pos)
				--pos = self.m_betAreaLayout:convertToNodeSpace(pos)
				pos = self.m_betAreaLayout:convertToNodeSpace(cc.p(667,610))
				--self:generateBetAnimtion(v, {x = 667, y = 610}, count)
				self:generateBetAnimtion(v, {x = pos.x, y = pos.y}, count)

				if nil ~= idx and nil ~= self.m_pJettonNumber[idx] then
					tmpScore = tmpScore + self.m_pJettonNumber[idx].k
					--getScore = getScore - tmpScore
				end

				print("bank tmpScore",tmpScore)
				print("score",score)
				if tmpScore >= score then
					remove = false
				end
			elseif "other" == wchair then
				local pos = cc.p(self.m_BtnMenu:getPositionX(), self.m_BtnMenu:getPositionY())
				if self.m_btnListLayer and self.m_btnListLayer:isVisible() == true then
					pos =  {x = 60,y = 452}
					--pos = self.m_tagControl:convertToWorldSpace(pos)
				else

				end
				self:generateBetAnimtion(v, {x = pos.x, y = pos.y}, count)
			else
				table.insert(left, v)
			end
		else
			table.insert(left, v)
		end	
		count = count + 1	
	end
	return left
end

function GameViewLayer:generateBetAnimtion( bet, pos, count)
	--筹码动画	
	local moveTo = cc.MoveTo:create(BET_ANITIME, cc.p(pos.x, pos.y))
	local call = cc.CallFunc:create(function ( )
		bet:removeFromParent()
	end)
	bet:stopAllActions()
	bet:runAction(cc.Sequence:create(cc.DelayTime:create(0.05 * count),moveTo, call))
end

function GameViewLayer:randomGetBetIdx( score, totalIdx )
	if score > self.m_pJettonNumber[1].k and score < self.m_pJettonNumber[2].k then
		return math.random(1,2)
	elseif score > self.m_pJettonNumber[2].k and score < self.m_pJettonNumber[3].k then
		return math.random(1,3)
	elseif score > self.m_pJettonNumber[3].k and score < self.m_pJettonNumber[4].k then
		return math.random(1,4)
	else
		return math.random(totalIdx)
	end
end

--下注区域
function GameViewLayer:initJettonArea( csbNode )
	local tag_control = csbNode:getChildByName("Node_InBtn");
	self.m_tagControl = tag_control

	--筹码区域
	self.m_betAreaLayout = tag_control:getChildByName("bet_area")

	--按钮列表
	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onJettonAreaClicked(sender:getTag(), sender);
		end
	end	

	for i=1,52 do
		--local tag = i - 1;
		local str = string.format("Button_%d", i);
		local tag_btn = tag_control:getChildByName(str);
		tag_btn:setTag(i);
		tag_btn:addTouchEventListener(btnEvent);
		self.m_tableJettonArea[i] = tag_btn; 
	end

	--下注信息
	-- local m_userJettonLayout = csbNode:getChildByName("jetton_control");
	-- local infoSize = m_userJettonLayout:getContentSize()
	-- local text = ccui.Text:create("本次下注为:", "fonts/round_body.ttf", 20)
	-- text:setAnchorPoint(cc.p(1.0,0.5))
	-- text:setPosition(cc.p(infoSize.width * 0.495, infoSize.height * 0.19))
	-- m_userJettonLayout:addChild(text)
	-- m_userJettonLayout:setVisible(false)

	-- local m_clipJetton = g_var(ClipText):createClipText(cc.size(120, 23), "")
	-- m_clipJetton:setPosition(cc.p(infoSize.width * 0.5, infoSize.height * 0.19))
	-- m_clipJetton:setAnchorPoint(cc.p(0,0.5));
	-- m_clipJetton:setTextColor(cc.c4b(255,165,0,255))
	-- m_userJettonLayout:addChild(m_clipJetton)

	-- self.m_userJettonLayout = m_userJettonLayout;
	-- self.m_clipJetton = m_clipJetton;

	self:reSetJettonArea(false);
end

function GameViewLayer:reSetJettonArea( var )
	for i=1,#self.m_tableJettonArea do
		self.m_tableJettonArea[i]:setEnabled(var);
	end
end

function GameViewLayer:cleanJettonArea(  )
	--移除界面已下注
	self.m_betAreaLayout:removeAllChildren()

	for i=1,#self.m_tableJettonArea do
		if nil ~= self.m_tableJettonNode[i] then
			--self.m_tableJettonNode[i]:reSet()
			self:reSetJettonNode(self.m_tableJettonNode[i])
		end
	end
	--self.m_userJettonLayout:setVisible(false)
	--self.m_clipJetton:setString("")
	self.m_lHaveJetton = 0;
	self.m_textDangqian:setString(self.m_lHaveJetton)
	self.m_lAllJetton = 0;
	self.m_textallUserIn:setString(self.m_lAllJetton)
end

--下注胜利提示
function GameViewLayer:initJettonSp( csbNode )
	self.m_tagSpControls = {};
	local sp_control = csbNode:getChildByName("Node_area");
	for i=1,52 do
		--local tag = i - 1;
		local str = string.format("Sprite_%d", i);
		local tagsp = sp_control:getChildByName(str);
		self.m_tagSpControls[i] = tagsp;
	end

	self:reSetJettonSp();
end

function GameViewLayer:reSetJettonSp(  )
	for i=1,#self.m_tagSpControls do
		self.m_tagSpControls[i]:setVisible(false);
	end
end

--胜利区域闪烁
function GameViewLayer:jettonAreaBlink( tabArea )
	--dump(tabArea)
	-- for i = 1, #tabArea do
	-- 	local score = tabArea[i]
	-- 	if score > 0 then
	-- 		local rep = cc.RepeatForever:create(cc.Blink:create(1.0,1))
	-- 		self.m_tagSpControls[i]:runAction(rep)
	-- 	end
	-- end
	for k,v in pairs(tabArea) do
		local score = tabArea[i]
		--if score > 0 then
			local rep = cc.RepeatForever:create(cc.Blink:create(1.0,1))
			self.m_tagSpControls[k]:setVisible(true)
			self.m_tagSpControls[k]:runAction(rep)
		--end
	end
end

function GameViewLayer:jettonAreaBlinkClean(  )
	for i = 1, g_var(cmd).AREA_COUNT do
		self.m_tagSpControls[i]:stopAllActions()
		self.m_tagSpControls[i]:setVisible(false)
	end
end

--座位列表
-- function GameViewLayer:initSitDownList( csbNode )
-- 	local m_roleSitDownLayer = csbNode:getChildByName("role_control")
-- 	self.m_roleSitDownLayer = m_roleSitDownLayer

-- 	--按钮列表
-- 	local function btnEvent( sender, eventType )
-- 		if eventType == ccui.TouchEventType.ended then
-- 			self:onSitDownClick(sender:getTag(), sender);
-- 		end
-- 	end

-- 	local str = ""
-- 	for i=1,g_var(cmd).MAX_OCCUPY_SEAT_COUNT do
-- 		str = string.format("sit_btn_%d", i)
-- 		self.m_tabSitDownList[i] = m_roleSitDownLayer:getChildByName(str)
-- 		self.m_tabSitDownList[i]:setTag(i)
-- 		self.m_tabSitDownList[i]:addTouchEventListener(btnEvent);
-- 	end
-- end

function GameViewLayer:initAction(  )
	local dropIn = cc.ScaleTo:create(0.2, 1.0);
	dropIn:retain();
	self.m_actDropIn = dropIn;

	local dropOut = cc.ScaleTo:create(0.2, 1.0, 0.0000001);
	dropOut:retain();
	self.m_actDropOut = dropOut;
end
--设置状态
function GameViewLayer:SetGameStaus( gameStaus )
    self.m_cbGameStatus = gameStaus;
end

---------------------------------------------------------------------------------------

function GameViewLayer:onButtonClickedEvent(tag,ref)
	ExternalFun.playClickEffect()
	if tag == TAG_ENUM.BT_EXIT then
		self:getParentNode():onQueryExitGame()
	elseif tag == TAG_ENUM.BT_START then
		--self:getParentNode():onStartGame()
	elseif tag == TAG_ENUM.BT_USERLIST then
		if nil == self.m_userListLayer then
			self.m_userListLayer = g_var(UserListLayer):create()
			self:addToRootLayer(self.m_userListLayer, TAG_ZORDER.USERLIST_ZORDER)
		end
		local userList = self:getDataMgr():getUserList()		
		self.m_userListLayer:refreshList(userList)
	elseif tag == TAG_ENUM.BT_APPLYLIST then
		if nil == self.m_applyListLayer then
			self.m_applyListLayer = g_var(ApplyListLayer):create(self)
			self:addToRootLayer(self.m_applyListLayer, TAG_ZORDER.USERLIST_ZORDER)
		end
		local userList = self:getDataMgr():getApplyBankerUserList()	

		self.m_applyListLayer:refreshList(userList)

	elseif tag == TAG_ENUM.BT_RULE then  --帮助
    	self:getParentNode():getParentNode():popHelpLayer2(118,0)
	elseif tag == TAG_ENUM.BT_BANK then
		--银行未开通
		if 0 == GlobalUserItem.cbInsureEnabled then
			showToast(self,"初次使用，请先开通银行！",1)
			return
		end
		if nil == self.m_cbGameStatus or g_var(cmd).GS_GAME_FREE ~= self.m_cbGameStatus then
			showToast(self,"游戏过程中不能进行银行操作",1)
			return
		end

		--房间规则
		local rule = self:getParentNode()._roomRule
		if rule == yl.GAME_GENRE_SCORE
		or rule == yl.GAME_GENRE_EDUCATE then 
			print("练习 or 积分房")
		end
		if false == self:getParentNode():getFrame():OnGameAllowBankTake() then
			--showToast(self,"不允许银行取款操作操作",1)
			--return
		end

		if nil == self.m_bankLayer then
			self:createBankLayer()
		end
		self.m_bankLayer:setVisible(true)
		self:refreshScore()
	elseif tag == TAG_ENUM.BT_SET then
 		local mgr = self._scene._scene:getApp():getVersionMgr()
    	local verstr = mgr:getResVersion(g_var(cmd).KIND_ID) or "0"
    	verstr = "游戏版本:" .. appdf.BASE_C_VERSION .. "." .. verstr
		local setting = g_var(SettingLayer):create(verstr)
		self:addToRootLayer(setting, TAG_ZORDER.SETTING_ZORDER)
	elseif tag == TAG_ENUM.BT_LUDAN then

		local nodeLudan1 = self._csbNode:getChildByName("Node_ludan1")
		local nodeLudan2 = self._csbNode:getChildByName("Node_ludan2")
		if nodeLudan1:isVisible() == true then
			nodeLudan1:setVisible(false)
			nodeLudan2:setVisible(true)
		else
			nodeLudan1:setVisible(true)
			nodeLudan2:setVisible(false)
		end

	elseif tag == TAG_ENUM.BT_ROBBANKER then
		--超级抢庄
		-- if g_var(cmd).SUPERBANKER_CONSUMETYPE == self.m_tabSupperRobConfig.superbankerType then
		-- 	local str = "超级抢庄将花费 " .. self.m_tabSupperRobConfig.lSuperBankerConsume .. ",确定抢庄?"
		-- 	local query = QueryDialog:create(str, function(ok)
		--         if ok == true then
		--             self:getParentNode():sendRobBanker()
		--         end
		--     end):setCanTouchOutside(false)
		--         :addTo(self) 
		-- else
		-- 	self:getParentNode():sendRobBanker()
		-- end
	elseif tag == TAG_ENUM.BT_CLOSEBANK then
		if nil ~= self.m_bankLayer then
			self.m_bankLayer:setVisible(false)
		end
	elseif tag == TAG_ENUM.BT_TAKESCORE then
		self:onTakeScore()
	elseif tag == TAG_ENUM.BT_MENU then
		if nil == self.m_btnListLayer then

			self.m_btnListLayer = g_var(BtnListLayer):create(self)
			self:addToRootLayer(self.m_btnListLayer, TAG_ZORDER.BTNLISTLAYER_ZORDER)
			self.m_btnListLayer.superParent = self
		else
			self.m_btnListLayer:setVisible(true)
		end
		self.m_BtnMenu:setVisible(false)
		self.m_btnListLayer.m_spBg:stopAllActions()
	    self.m_btnListLayer.m_spBg:runAction(self.m_actDropIn)
	else
		showToast(self,"功能尚未开放！",1)
	end
end

function GameViewLayer:onJettonButtonClicked( tag, ref )
	if tag >= 1 and tag <= 6 then
		self.m_nJettonSelect = self.m_pJettonNumber[tag].k;
	else
		self.m_nJettonSelect = -1;
	end

	self.m_nSelectBet = tag
	self:switchJettonBtnState(tag)
	print("click jetton:" .. self.m_nJettonSelect);
end

function GameViewLayer:onJettonAreaClicked( tag, ref )
	local m_nJettonSelect = self.m_nJettonSelect;
		if m_nJettonSelect < 0 then
			return;
	end
	print("@@@tag@@@",tag)
	local area = tag - 1;
	--self.m_lHaveJetton = self.m_lHaveJetton + m_nJettonSelect;
	-- self.m_lAllJetton = self.m_lAllJetton + m_nJettonSelect
 --    self:refreshJetton()
	-- print("self.m_lHaveJetton",self.m_lHaveJetton)
	-- print("self.m_llMaxJetton",self.m_llMaxJetton)
	if self.m_lHaveJetton > self.m_llMaxJetton then
		showToast(self,"已超过最大下注限额",1)
		--self.m_lHaveJetton = self.m_lHaveJetton - m_nJettonSelect;
		--self.m_lAllJetton = self.m_lAllJetton - m_nJettonSelect
		return;
	end

	--下注
	self:getParentNode():sendUserBet(area, m_nJettonSelect);
end

function GameViewLayer:showGameResult( bShow )
	if true == bShow then
		if nil == self.m_gameResultLayer then

			self.m_gameResultLayer = self._csbNode:getChildByName("Sprite_resultBg")
		end

		if true == bShow then--and true == self:getDataMgr().m_bJoin then
			self:showResult()
		end
	else
		if nil ~= self.m_gameResultLayer then
			self:hideResult()
			local diceResult = self.m_nodeDiceBg:getChildByName("dice_result")
			diceResult:setVisible(false)
		end
	end
end

function GameViewLayer:showResult(  )

	local resultData = self:getDataMgr().m_tabGameResult
	self.m_gameResultLayer:setVisible(true)

	--播放声音
	if resultData.lUserScore > 0 then
        ExternalFun.playSoundEffect("END_WIN.wav")
	elseif resultData.lUserScore <0  then
		ExternalFun.playSoundEffect("END_LOST.wav")
	else 
		ExternalFun.playSoundEffect("END_DRAW.wav")
	end
	--   
	-- --玩家分数
	local textMyScore = self.m_gameResultLayer:getChildByName("Text_myScore")
	local myScore = self:getParentNode():formatScoreText(resultData.lUserScore)
	textMyScore:setString(myScore)

	--玩家返回积分
	local textMyRe = self.m_gameResultLayer:getChildByName("Text_myRe")
	local returnScore =self:getParentNode():formatScoreText(resultData.lUserReturnScore)
	textMyRe:setString(returnScore)
	--庄家分数
	local textBankerScore = self.m_gameResultLayer:getChildByName("Text_bankerScore")
	local bankerScore = self:getParentNode():formatScoreText(resultData.lBankerScore)
	textBankerScore:setString(bankerScore)
end

function GameViewLayer:hideResult(  )
	self.m_gameResultLayer:setVisible(false)
end 

function GameViewLayer:onCheckBoxClickEvent( sender,eventType )
	ExternalFun.playClickEffect()
	if eventType == ccui.CheckBoxEventType.selected then
		self.m_btnList:stopAllActions();
		self.m_btnList:runAction(self.m_actDropIn);
	elseif eventType == ccui.CheckBoxEventType.unselected then
		self.m_btnList:stopAllActions();
		self.m_btnList:runAction(self.m_actDropOut);
	end
end

-- function GameViewLayer:onSitDownClick( tag, sender )
-- 	print("sit ==> " .. tag)
-- 	local useritem = self:getMeUserItem()
-- 	if nil == useritem then
-- 		return
-- 	end

-- 	--重复判断
-- 	if nil ~= self.m_nSelfSitIdx and tag == self.m_nSelfSitIdx then
-- 		return
-- 	end

-- 	if nil ~= self.m_nSelfSitIdx then --and tag ~= self.m_nSelfSitIdx  then
-- 		showToast(self, "当前已占 " .. self.m_nSelfSitIdx .. " 号位置,不能重复占位!", 2)
-- 		return
-- 	end	

-- 	--坐下条件限制
-- 	if self.m_tabSitDownConfig.occupyseatType == g_var(cmd).OCCUPYSEAT_CONSUMETYPE then --金币占座
-- 		if useritem.lScore < self.m_tabSitDownConfig.lOccupySeatConsume then
-- 			local str = "坐下需要消耗 " .. self.m_tabSitDownConfig.lOccupySeatConsume .. " 金币,金币不足!"
-- 			showToast(self, str, 2)
-- 			return
-- 		end
-- 		local str = "坐下将花费 " .. self.m_tabSitDownConfig.lOccupySeatConsume .. ",确定坐下?"
-- 			local query = QueryDialog:create(str, function(ok)
-- 		        if ok == true then
-- 		            self:getParentNode():sendSitDown(tag - 1, useritem.wChairID)
-- 		        end
-- 		    end):setCanTouchOutside(false)
-- 		        :addTo(self)
-- 	elseif self.m_tabSitDownConfig.occupyseatType == g_var(cmd).OCCUPYSEAT_VIPTYPE then --会员占座
-- 		if useritem.cbMemberOrder < self.m_tabSitDownConfig.enVipIndex then
-- 			local str = "坐下需要会员等级为 " .. self.m_tabSitDownConfig.enVipIndex .. " 会员等级不足!"
-- 			showToast(self, str, 2)
-- 			return
-- 		end
-- 		self:getParentNode():sendSitDown(tag - 1, self:getMeUserItem().wChairID)
-- 	elseif self.m_tabSitDownConfig.occupyseatType == g_var(cmd).OCCUPYSEAT_FREETYPE then --免费占座
-- 		if useritem.lScore < self.m_tabSitDownConfig.lOccupySeatFree then
-- 			local str = "免费坐下需要携带金币大于 " .. self.m_tabSitDownConfig.lOccupySeatFree .. " ,当前携带金币不足!"
-- 			showToast(self, str, 2)
-- 			return
-- 		end
-- 		self:getParentNode():sendSitDown(tag - 1, self:getMeUserItem().wChairID)
-- 	end
-- end

function GameViewLayer:onResetView()
	self:stopAllActions()
	self:gameDataReset()
end

function GameViewLayer:onExit()

	print("GameViewLayer onExit")

 	--播放大厅背景音乐
    ExternalFun.playPlazzBackgroudAudio()
    self:onResetView()
end

--上庄状态
function GameViewLayer:applyBanker( state )
	if state == APPLY_STATE.kCancelState then
		self:getParentNode():sendApplyBanker()
	elseif state == APPLY_STATE.kApplyState then
		self:getParentNode():sendCancelApply()
	elseif state == APPLY_STATE.kApplyedState then
		self:getParentNode():sendCancelApply()		
	end
end

---------------------------------------------------------------------------------------
--网络消息

------
--网络接收
function GameViewLayer:onGetUserScore( item )
	--自己
	if item.dwUserID == GlobalUserItem.dwUserID then
       self:reSetUserInfo()
    end

    --庄家
    if self.m_wBankerUser == item.wChairID then
    	--庄家金币
		local str = ExternalFun.formatScoreText(item.lScore);
		self.m_textBankerCoin:setString(str);
    end

end

function GameViewLayer:refreshCondition(  )
	local applyable = self:getApplyable()
	if applyable then
		------
		--超级抢庄

		--如果当前有超级抢庄用户且庄家不是自己
		--if (yl.INVALID_CHAIR ~= self.m_wCurrentRobApply) or (true == self:isMeChair(self.m_wBankerUser)) then
			--ExternalFun.enableBtn(self.m_btnRob, false)
		-- else
		-- 	local useritem = self:getMeUserItem()
		-- 	--判断抢庄类型
		-- 	if g_var(cmd).SUPERBANKER_VIPTYPE == self.m_tabSupperRobConfig.superbankerType then
		-- 		--vip类型				
		-- 		ExternalFun.enableBtn(self.m_btnRob, useritem.cbMemberOrder >= self.m_tabSupperRobConfig.enVipIndex)
		-- 	elseif g_var(cmd).SUPERBANKER_CONSUMETYPE == self.m_tabSupperRobConfig.superbankerType then
		-- 		--游戏币消耗类型(抢庄条件+抢庄消耗)
		-- 		local condition = self.m_tabSupperRobConfig.lSuperBankerConsume + self.m_llCondition
		-- 		ExternalFun.enableBtn(self.m_btnRob, useritem.lScore >= condition)
		-- 	end
		-- end		
	-- else
	-- 	ExternalFun.enableBtn(self.m_btnRob, false)
	end
end

--游戏free
function GameViewLayer:onGameFree( )
	yl.m_bDynamicJoin = false

	self:reSetForNewGame()

	--上庄条件刷新
	self:refreshCondition()

	--申请按钮状态更新
	self:refreshApplyBtnState()

end

--游戏开始
function GameViewLayer:onGameStart( )
	self.m_nJettonSelect = self.m_pJettonNumber[DEFAULT_BET].k;

	--获取玩家携带游戏币	
	self:reSetUserInfo();

	self.m_bOnGameRes = false

	--不是自己庄家,且有庄家
	if false == self:isMeChair(self.m_wBankerUser) and false == self.m_bNoBanker then
		--下注
		self:enableJetton(true);
		--调整下注按钮
		self:adjustJettonBtn();

		--默认选中的筹码
		self:switchJettonBtnState(DEFAULT_BET)
	end	

	math.randomseed(tostring(os.time()):reverse():sub(1, 6))

	--申请按钮状态更新
	self:refreshApplyBtnState()	
end

--游戏进行
function GameViewLayer:reEnterStart( lUserJetton )
	self.m_nJettonSelect = self.m_pJettonNumber[DEFAULT_BET].k;
	self.m_lHaveJetton = lUserJetton;

	--获取玩家携带游戏币
	self.m_scoreUser = 0
	self:reSetUserInfo();

	self.m_bOnGameRes = false

	--不是自己庄家
	if false == self:isMeChair(self.m_wBankerUser) then
		--下注
		self:enableJetton(true);
		--调整下注按钮
		self:adjustJettonBtn();

		--默认选中的筹码
		self:switchJettonBtnState(DEFAULT_BET)
	end		
end

--下注条件
function GameViewLayer:onGetApplyBankerCondition( llCon , rob_config)
	self.m_llCondition = llCon
	--超级抢庄配置
	-- if rob_config then
	-- 	self.m_tabSupperRobConfig = rob_config
	-- end

	self:refreshCondition();
end

--刷新庄家信息
function GameViewLayer:onChangeBanker( _wBankerUser, _lBankerScore,_cbBankerTime ,_lBankerWinScore)
	local gameBankInfo =  self:getParentNode():getDataMgr().m_tabGameBankInfo
	-- dump(gameBankInfo)
	local wBankerUser = _wBankerUser and _wBankerUser or  gameBankInfo.wBankerUser
	local lBankerScore = _lBankerScore and _lBankerScore or  gameBankInfo.lBankerScore
	local cbBankerTime = _cbBankerTime and _cbBankerTime or  gameBankInfo.nBankerTime
	local lBankerWinScore = _lBankerWinScore and _lBankerWinScore or gameBankInfo.lBankerWinScore
	local bEnableSysBanker = self:getParentNode().m_bEnableSystemBanker
	print("更新庄家数据:" .. wBankerUser .. "; coin =>" .. lBankerScore)
	--print("cbBankerTime,lBankerWinScore",cbBankerTime,lBankerWinScore)
	--上一个庄家是自己，且当前庄家不是自己，标记自己的状态
	if self.m_wBankerUser ~= wBankerUser and self:isMeChair(self.m_wBankerUser) then
		self.m_enApplyState = APPLY_STATE.kCancelState
	end
	-- 5 无人坐庄  6 由您坐庄   7 轮换坐庄
	if self.m_wBankerUser ~= wBankerUser then
		if self:isMeChair(wBankerUser) then
			--print("由您坐庄")
			self:refreshBankerTip(6)
		elseif wBankerUser ~= yl.INVALID_CHAIR then
			--print("轮换坐庄")
			self:refreshBankerTip(7)
		else
			--print("无人坐庄")
			self:refreshBankerTip(5)
		end
	end
	self.m_wBankerUser = wBankerUser 
	--获取庄家数据
	self.m_bNoBanker = false
	local nickstr = "";
	--庄家姓名
	--print("bEnableSysBanker",bEnableSysBanker)
	if true == bEnableSysBanker then --允许系统坐庄
		if yl.INVALID_CHAIR == self.m_wBankerUser then
			nickstr = "系统坐庄"
			lBankerScore = 0
		else
			local userItem = self:getDataMgr():getChairUserList()[self.m_wBankerUser + 1];
			if nil ~= userItem then
				nickstr = userItem.szNickName 

				if self:isMeChair(wBankerUser) then
					self.m_enApplyState = APPLY_STATE.kApplyedState
				end
			else
				print("获取用户数据失败")
			end
		end	
	else
		--print("yl.INVALID_CHAIR == wBankerUser",yl.INVALID_CHAIR == wBankerUser)
		if yl.INVALID_CHAIR == wBankerUser then
			nickstr = "无人坐庄"
			self.m_bNoBanker = true
		else
			local userItem = self:getDataMgr():getChairUserList()[wBankerUser + 1];
			if nil ~= userItem then
				nickstr = userItem.szNickName 

				if self:isMeChair(wBankerUser) then
					self.m_enApplyState = APPLY_STATE.kApplyedState
				end
				--提示
				--print("获取用户数据成功")
			else
				--print("获取用户数据失败")
			end
		end
	end
	self.m_clipBankerNick:setString(nickstr);
	--庄家金币
	local str = ExternalFun.formatScoreText(lBankerScore);
	self.m_textBankerCoin:setString(str);

	--如果是超级抢庄用户上庄
	--if wBankerUser == self.m_wCurrentRobApply then
		--self.m_wCurrentRobApply = yl.INVALID_CHAIR
		--self:refreshCondition()
	--end
	--庄家局数
	if cbBankerTime then
		self.m_textBankerRound:setString(cbBankerTime)
	else
		self.m_textBankerRound:setString("0")
	end

	--庄家成绩 
	if lBankerWinScore then
		local chengJiStr = self:getParentNode():formatScoreText(lBankerWinScore);
		self.m_textBankerChengJi:setString(chengJiStr)
	else
		self.m_textBankerChengJi:setString("0")
	end

end

function GameViewLayer:refreshBankerTip( tag )
	--空闲状态
	-- print("self.m_cbGameStatus ~= g_var(cmd).SUB_S_GAME_FREE",self.m_cbGameStatus ~= g_var(cmd).SUB_S_GAME_FREE)
	-- print("self.m_cbGameStatus",self.m_cbGameStatus)
	-- print("g_var(cmd).SUB_S_GAME_FREE",g_var(cmd).SUB_S_GAME_FREE)
	-- if self.m_cbGameStatus ~= g_var(cmd).SUB_S_GAME_FREE then
	-- 	return
	-- end
	print("@@@@@@@@@@上庄提示@@@@@@@@@")
	local spriteTip = self.m_nodeBankerTip:getChildByName("Sprite_tips")

	local call1 = cc.CallFunc:create(function (  )
		self.m_nodeBankerTip:setVisible(true)
	end)
	local scale = cc.ScaleTo:create(0.2, 0.0001, 1.0)
	local call2 = cc.CallFunc:create(function (  )
		local str = string.format("118_tips_%d.png", tag)
		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(str)

		--self.m_pClock.m_spTip:setVisible(false)
		if nil ~= frame then
			spriteTip:setVisible(true)
			spriteTip:setSpriteFrame(frame)
		end
	end)
	local scaleBack = cc.ScaleTo:create(0.2,1.0)
	local delayTime = cc.DelayTime:create(1.5)
	local call3 = cc.CallFunc:create(function (  )
		self.m_nodeBankerTip:setVisible(false)
	end)
	local seq = cc.Sequence:create(call1,scale, call2, scaleBack,delayTime,call3)
	spriteTip:runAction(seq)
end

--更新用户下注
function GameViewLayer:onGetUserBet( )
	local data = self:getParentNode().cmd_placebet;
	-- dump(data)
	if nil == data then
		return
	end
	local area = data.cbJettonArea + 1;
	local wUser = data.wChairID;
	local llScore = data.lJettonScore

	local nIdx = self:getJettonIdx(data.lJettonScore);
	local str = string.format("118_chip_%d.png", nIdx);
	local sp = nil
	local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(str)
	if nil ~= frame then
		sp = cc.Sprite:createWithSpriteFrame(frame);
	end
	local btn = self.m_tableJettonArea[area];
	--print("jettonBtn")
	--dump(self.m_tableJettonArea)
	if nil == sp then
		print("sp nil");
	end

	if nil == btn then
		print("btn nil");
	end
	if nil ~= sp and nil ~= btn then
		--下注
		sp:setTag(wUser);
		local name = string.format("%d", nIdx) --ExternalFun.formatScore(data.lBetScore);
		sp:setName(name)
		
		--筹码飞行起点位置
		local pos = self.m_betAreaLayout:convertToNodeSpace(self:getBetFromPos(wUser))
		--pos = self.m_betAreaLayout:convertToNodeSpace(self:getBetFromPos(wUser))
		sp:setPosition(pos)
		--筹码飞行动画
		local act = self:getBetAnimation(self:getBetRandomPos(btn), cc.CallFunc:create(function()
			--播放下注声音
			ExternalFun.playSoundEffect("ADD_SCORE.wav")
		end))
		sp:stopAllActions()
		sp:runAction(act)
		self.m_betAreaLayout:addChild(sp)

		--下注信息显示
		print("self.m_tableJettonNode[area]",self.m_tableJettonNode[area])
		if nil == self.m_tableJettonNode[area] then
			local jettonNode = self:createJettonNode(area)
			jettonNode:setPosition(btn:getPosition());
			self.m_tagControl:addChild(jettonNode);
			jettonNode:setTag(-1);
			self.m_tableJettonNode[area] = jettonNode;
		end

		self:refreshJettonNode(self.m_tableJettonNode[area], llScore, llScore, self:isMeChair(wUser))
	end

	if self:isMeChair(wUser) then
		self.m_scoreUser = self.m_scoreUser - self.m_nJettonSelect;
		self.m_lHaveJetton = self.m_lHaveJetton + self.m_nJettonSelect;
		self:reSetUserInfo(self.m_scoreUser)
		--调整下注按钮
		self:adjustJettonBtn();
		--显示下注信息
		self:refreshJetton();
	end
end

--更新用户下注失败
function GameViewLayer:onGetUserBetFail(  )
	local data = self:getParentNode().cmd_jettonfail;
	if nil == data then
		return;
	end
	--下注玩家
	local wUser = data.wPlaceUser;
	--下注区域
	local cbArea = data.lJettonArea + 1;
	--下注数额
	local llScore = data.lPlaceScore;

	if self:isMeChair(wUser) then
		--提示下注失败
		local str = string.format("下注 %s 失败", ExternalFun.formatScore(llScore))
		showToast(self,str,1)
		--自己下注失败
		self.m_scoreUser = self.m_scoreUser + llScore;
		--self.m_lHaveJetton = self.m_lHaveJetton - llScore;
		--self.m_lAllJetton = self.m_lAllJetton -  llScore
		self:adjustJettonBtn();
		self:refreshJetton()
		--
		if 0 ~= self.m_lHaveJetton then
			if nil ~= self.m_tableJettonNode[cbArea] then
				--self:refreshJetton(-llScore, -llScore, true)
				self:refreshJettonNode(self.m_tableJettonNode[cbArea],0, 0, true)
			end

			--移除界面下注元素
			local name = string.format("%d", cbArea) --ExternalFun.formatScore(llScore);
			self.m_betAreaLayout:removeChildByName(name)
		end
	end
end

--断线重连更新界面已下注
function GameViewLayer:reEnterGameBet( cbArea, llScore )
	local btn = self.m_tableJettonArea[cbArea];
	if nil == btn or 0 == llSocre  then
		return;
	end


	local vec = self:getDataMgr().calcuteJetton(llScore, false);
	for k,v in pairs(vec) do
		local info = v;

		for i=1,info.m_cbCount do
			local str = string.format("118_chip_%d.png", info.m_cbIdx);
			local sp = cc.Sprite:createWithSpriteFrameName(str);
			if nil ~= sp then
				--sp:setScale(0.35);
				sp:setTag(yl.INVALID_CHAIR);
				local name = string.format("%d", cbArea) --ExternalFun.formatScore(info.m_llScore);
				sp:setName(name);

				self:randomSetJettonPos(btn, sp);
				self.m_betAreaLayout:addChild(sp);
			end
		end
	end

	--下注信息显示
	if nil == self.m_tableJettonNode[cbArea] then
		print("cbArea",cbArea)
		local jettonNode = self:createJettonNode(cbArea)
		jettonNode:setPosition(btn:getPosition());
		self.m_tagControl:addChild(jettonNode);
		jettonNode:setTag(-1);
		self.m_tableJettonNode[cbArea] = jettonNode;
	end

	self:refreshJettonNode(self.m_tableJettonNode[cbArea], llScore, llScore, false)
end

--断线重连更新玩家已下注
function GameViewLayer:reEnterUserBet( cbArea, llScore )
	local btn = self.m_tableJettonArea[cbArea];
	if nil == btn or 0 == llSocre then
		return;
	end
	--print("@@@@@@@@@@@断线重连更新玩家已下注@@@@@@@@@@@")
	-- print("cbArea",cbArea)
	-- print("llScore",llScore)

	local vec = self:getDataMgr().calcuteJetton(llScore, false);
	for k,v in pairs(vec) do
		local info = v;

		for i=1,info.m_cbCount do
			local str = string.format("118_chip_%d.png", info.m_cbIdx);
			local sp = cc.Sprite:createWithSpriteFrameName(str);
			if nil ~= sp then
				--sp:setScale(0.35);
				sp:setTag(yl.INVALID_CHAIR);
				local name = string.format("%d", cbArea) --ExternalFun.formatScore(info.m_llScore);
				sp:setName(name);

				self:randomSetJettonPos(btn, sp);
				self.m_betAreaLayout:addChild(sp);
			end
		end
	end

	--下注信息显示
	if nil == self.m_tableJettonNode[cbArea] then
		local jettonNode = self:createJettonNode(cbArea)
		jettonNode:setPosition(btn:getPosition());
		self.m_tagControl:addChild(jettonNode);
		jettonNode:setTag(-1);
		self.m_tableJettonNode[cbArea] = jettonNode;
	end
	self:refreshJettonNode(self.m_tableJettonNode[cbArea], llScore, 0, true)
end

--游戏结束
function GameViewLayer:onGetGameEnd( cbTimeLeave )
	self.m_bOnGameRes = true
	--不可下注
	self:enableJetton(false)

	--界面资源清理
	self:reSet()
	--骰子动画
	self:runDiceAnimate(cbTimeLeave)

end

--骰子动画
function GameViewLayer:runDiceAnimate(cbTimeLeave)
	if self.m_nodeDiceBg == nil then
		self.m_nodeDiceBg = self._csbNode:getChildByName("Node_dice")
	end
	local sprite = self.m_nodeDiceBg:getChildByName("Sprite_diceAni")
	if cbTimeLeave > 16 then
		--有骰子动画
		local spriteFrameNum = 8
		local perUnit = 0.05
		local animation =cc.Animation:create()
		for i=1,spriteFrameNum do  
		    local frameName =string.format("118_diceAni_%d.png",i)                                            
		    --print("frameName =%s",frameName)  
		    local spriteFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName)               
		   animation:addSpriteFrame(spriteFrame)                                                             
		end  
	   	animation:setDelayPerUnit(perUnit)          --设置两个帧播放时间                   
	   	animation:setRestoreOriginalFrame(true)    --动画执行后还原初始状态    
	   	local repeatNum = math.floor((cbTimeLeave-16)/(spriteFrameNum*perUnit))
	   	--print("repeatNum",repeatNum)
	   	local action =  cc.Repeat:create(cc.Animate:create(animation),repeatNum)    
	   	sprite:runAction(cc.Sequence:create(
	   		cc.CallFunc:create(function ()
		   		sprite:setVisible(true)
		   		local diceResult = self.m_nodeDiceBg:getChildByName("dice_result")
		   		diceResult:setVisible(false)
		   		ExternalFun.playSoundEffect("IDW_SHACK_DICE.wav")
		   	end),
	   		action,
	   		cc.CallFunc:create(function ()
		   		sprite:setVisible(false)
		   		local diceResult = self.m_nodeDiceBg:getChildByName("dice_result")
		   		diceResult:setVisible(true)
		   		self:setDiceData()
		   		self:showBetAreaBlink()
		   		ExternalFun.playSoundEffect("DISPATCH_CARD.wav")
		   	end)
	   	))  
	else   
		--无骰子动画
   		sprite:setVisible(false)
   		local diceResult = self.m_nodeDiceBg:getChildByName("dice_result")
   		diceResult:setVisible(true)
   		self:setDiceData()
   		self:showBetAreaBlink()
	end
end

function GameViewLayer:setDiceData()
	local gameResult =  self:getDataMgr().m_tabGameResult
	--dump(gameResult)
	local diceResult = self.m_nodeDiceBg:getChildByName("dice_result")
	--骰子
	for i=1,3 do
		local diceStr = string.format("dice_%d",i)
		local dice = diceResult:getChildByName(diceStr)
		local diceFrameStr = string.format("118_dice_%d.png",gameResult.cbDiceValue[i])
		dice:setSpriteFrame(diceFrameStr)
	end
	--点数
	local Text_dianshu = diceResult:getChildByName("Text_dianshu")
	Text_dianshu:setString(gameResult.cbDicePoints)
	--大小
	local Text_daxiao = diceResult:getChildByName("Text_daxiao")
	Text_daxiao:setString(gameResult.cbDiceDaxiao)
end

--申请庄家
function GameViewLayer:onGetApplyBanker( )
	if self:isMeChair(self:getParentNode().cmd_applybanker.wApplyUser) then
		self.m_enApplyState = APPLY_STATE.kApplyState
	end
	self:refreshApplyList()
end

--取消申请庄家
function GameViewLayer:onGetCancelBanker(  )
	if self:isMeChair(self:getParentNode().cmd_cancelbanker.wCancelUser) then
		self.m_enApplyState = APPLY_STATE.kCancelState
	end
	self:refreshApplyList()
end

--刷新列表
function GameViewLayer:refreshApplyList(  )
	local userList = self:getDataMgr():getApplyBankerUserList()
	if nil ~= self.m_applyListLayer and self.m_applyListLayer:isVisible() then

		self.m_applyListLayer:refreshList(userList)
	end
	--刷新上庄列表
	self:refreshAppLyInfo(userList)
end

function GameViewLayer:refreshUserList(  )
	if nil ~= self.m_userListLayer and self.m_userListLayer:isVisible() then
		local userList = self:getDataMgr():getUserList()
		self.m_userListLayer:refreshList(userList)
	end
end

--刷新申请列表按钮状态
function GameViewLayer:refreshApplyBtnState(  )
	if nil ~= self.m_applyListLayer and self.m_applyListLayer:isVisible() then
		self.m_applyListLayer:refreshBtnState()
	end
end

--刷新路单
function GameViewLayer:updateWallBill()
	--dump(gameRecord)
	--dump(self:getDataMgr().m_vecRecord)
	local gameRecord = self:getDataMgr().m_vecRecord
	if nil ~= gameRecord then--and self.m_wallBill:isVisible() then

		local nodeLudan1 = self._csbNode:getChildByName("Node_ludan1")
		--local maxRecordNum1 = #gameRecord > 4 and 4 or #gameRecord
		for i=1,4 do
			local strItem = string.format("ludan_%d",i)
			local ludanItem = nodeLudan1:getChildByName(strItem)
			--dump(gameRecord[#gameRecord-i+1])
			if gameRecord[#gameRecord-i+1] then
				ludanItem:setVisible(true)
				--local num = 0
				--骰子
				for j=1,3 do
					local diceStr = string.format("dice_%d",j)
					local dice =  ludanItem:getChildByName(diceStr)
					local diceFrameStr = string.format("118_ludan_%d.png",gameRecord[#gameRecord-i+1].cbDiceValue[j])
					dice:setSpriteFrame(diceFrameStr)
					--num = num + gameRecord[#gameRecord-i+1].cbDiceValue[j]
				end
				--数字
				local Text_num = ludanItem:getChildByName("Text_num")
				Text_num:setString(gameRecord[#gameRecord-i+1].cbDicePoints)
				--大小 
				local Text_daxiao = ludanItem:getChildByName("Text_daxiao")
				Text_daxiao:setString(gameRecord[#gameRecord-i+1].cbDiceDaxiao)
				--颜色
				if gameRecord[#gameRecord-i+1].cbDiceDaxiao == "大" then
					Text_daxiao:setTextColor(cc.c3b(238,255,50))
				else
					Text_daxiao:setTextColor(cc.c3b(69,255,50))
				end
			else
				ludanItem:setVisible(false)
			end
		end

		local nodeLudan2 = self._csbNode:getChildByName("Node_ludan2")
		--local maxRecordNum2 = #gameRecord > 10 and 10 or #gameRecord
		for i=1,10 do
			local strItem = string.format("ludan_%d",i)
			local ludanItem = nodeLudan2:getChildByName(strItem)
			if gameRecord[#gameRecord-i+1] then
				ludanItem:setVisible(true)
				--骰子
				for j=1,3 do
					local strDice = string.format("dice_%d",j)
					local dice =  ludanItem:getChildByName(strDice)
					local strDiceFrame = string.format("118_ludan_%d.png",gameRecord[#gameRecord-i+1].cbDiceValue[j])
					dice:setSpriteFrame(strDiceFrame)
				end
				--数字
				local Text_num = ludanItem:getChildByName("Text_num")
				Text_num:setString(gameRecord[#gameRecord-i+1].cbDicePoints)
				--大小 
				local Text_daxiao = ludanItem:getChildByName("Text_daxiao")
				Text_daxiao:setString(gameRecord[#gameRecord-i+1].cbDiceDaxiao)
				if gameRecord[#gameRecord-i+1].cbDiceDaxiao == "大" then
					Text_daxiao:setTextColor(cc.c3b(238,255,50))
				else
					Text_daxiao:setTextColor(cc.c3b(69,255,50))
				end
			else
				ludanItem:setVisible(false)
			end
		end
	end
end

--银行操作成功
function GameViewLayer:onBankSuccess( )
	local bank_success = self:getParentNode().bank_success
	if nil == bank_success then
		return
	end
	GlobalUserItem.lUserScore = bank_success.lUserScore
	GlobalUserItem.lUserInsure = bank_success.lUserInsure

	if nil ~= self.m_bankLayer and true == self.m_bankLayer:isVisible() then
		self:refreshScore()
	end
	showToast(self, bank_success.szDescribrString, 2)
end

--银行操作失败
function GameViewLayer:onBankFailure( )
	local bank_fail = self:getParentNode().bank_fail
	if nil == bank_fail then
		return
	end

	showToast(self, bank_fail.szDescribeString, 2)
end

--银行资料
function GameViewLayer:onGetBankInfo(bankinfo)
	bankinfo.wRevenueTake = bankinfo.wRevenueTake or 10
	if nil ~= self.m_bankLayer then
		local str = "温馨提示:取款将扣除" .. bankinfo.wRevenueTake .. "%的手续费"
		self.m_bankLayer.m_textTips:setString(str)
		self:refreshScore(bankinfo)
	end
end
------
---------------------------------------------------------------------------------------
function GameViewLayer:getParentNode( )
	return self._scene;
end

function GameViewLayer:getMeUserItem(  )
	if nil ~= GlobalUserItem.dwUserID then
		return self:getDataMgr():getUidUserList()[GlobalUserItem.dwUserID];
	end
	return nil;
end

function GameViewLayer:isMeChair( wchair )
	local useritem = self:getDataMgr():getChairUserList()[wchair + 1];
	if nil == useritem then
		return false
	else 
		return useritem.dwUserID == GlobalUserItem.dwUserID
	end
end

function GameViewLayer:addToRootLayer( node , zorder)
	if nil == node then
		return
	end

	self.m_rootLayer:addChild(node)
	node:setLocalZOrder(zorder)
end

function GameViewLayer:getChildFromRootLayer( tag )
	if nil == tag then
		return nil
	end
	return self.m_rootLayer:getChildByTag(tag)
end

function GameViewLayer:getApplyState(  )
	return self.m_enApplyState
end

function GameViewLayer:getApplyCondition(  )
	return self.m_llCondition
end

--获取能否上庄
function GameViewLayer:getApplyable(  )
	--自己超级抢庄已申请，则不可进行普通申请
	-- if APPLY_STATE.kSupperApplyed == self.m_enApplyState then
	-- 	return false
	-- end

	local userItem = self:getMeUserItem();
	if nil ~= userItem then
		return userItem.lScore > self.m_llCondition
	else
		return false
	end
end

--获取能否取消上庄
function GameViewLayer:getCancelable( )
	return self.m_cbGameStatus == g_var(cmd).GS_GAME_FREE
end

--下注区域闪烁
function GameViewLayer:showBetAreaBlink(  )
	local blinkArea = self:getDataMgr().m_tabBetArea
	self:jettonAreaBlink(blinkArea)
end

function GameViewLayer:getDataMgr( )
	return self:getParentNode():getDataMgr()
end

function GameViewLayer:logData(msg)
	local p = self:getParentNode()
	if nil ~= p.logData then
		p:logData(msg)
	end	
end

function GameViewLayer:showPopWait( )
	self:getParentNode():showPopWait()
end

function GameViewLayer:dismissPopWait( )
	self:getParentNode():dismissPopWait()
end

function GameViewLayer:gameDataInit(  )
	--搜索路径
    local gameList = self:getParentNode():getParentNode():getApp()._gameList;
    local gameInfo = {};
    for k,v in pairs(gameList) do
        if tonumber(v._KindID) == tonumber(g_var(cmd).KIND_ID) then
            gameInfo = v;
            break;
        end
    end
    if nil ~= gameInfo._Module then
    	self._searchPath = device.writablePath.."game/" .. gameInfo._Module .. "/res/";
        cc.FileUtils:getInstance():addSearchPath(self._searchPath);
    end

	local oldPaths = cc.FileUtils:getInstance():getSearchPaths();
    dump(oldPaths)
    --播放背景音乐
    print("播放背景音乐")
    ExternalFun.playBackgroudAudio("BACK_GROUND.wav")

    --用户列表
	self:getDataMgr():initUserList(self:getParentNode():getUserList())

    --加载资源
	self:loadRes()

	--变量声明
	--限制信息
	self.m_lMeMaxScore = 0								--最大下注
	self.m_lAreaLimitScore = 0							--区域限制
	self.m_lApplyBankerCondition = 0					--申请条件
	--个人下注
	self.m_lUserBet = {}								--个人总注
	self.m_lAllUserBet = {}								--全体总注
	self.m_lInitUserScore = {}							--原始分数
	self.m_lUserJettonScore = {}
	--庄家信息
	self.m_lBankerScore = 0								--庄家积分
	self.m_wCurrentBanker = 0							--当前庄家
	self.m_cbLeftCardCount = 0							--数量
	self.m_bEnableSysBanker = false						--系统坐庄
	--状态变量
	self.m_bMeApplyBanker = false   					--申请标识
	self.m_bCanPlaceJetton = false						--可以下注

	self.m_nJettonSelect = -1    						--选择筹码
	self.m_lCurrentJetton = 0							--当前筹码

	self.m_lHaveJetton = 0;								--
	self.m_lAllJetton = 0
	self.m_llMaxJetton = 0;
	self.m_llCondition = 0;
	yl.m_bDynamicJoin = false;
	self.m_scoreUser = self:getMeUserItem().lScore or 0	--个人分数

	--下注信息
	self.m_tableJettonBtn = {};
	self.m_tableJettonArea = {};
	--上庄列表名
	self.m_labelApplyName = {}
	--下注提示
	self.m_tableJettonNode = {};

	self.m_applyListLayer = nil
	self.m_userListLayer = nil
	self.m_btnListLayer = nil
	--self.m_cardLayer = nil
	self.m_gameResultLayer = nil
	self.m_pClock = nil
	self.m_bankLayer = nil

	--申请状态
	self.m_enApplyState = APPLY_STATE.kCancelState
	--超级抢庄申请
	self.m_bSupperRobApplyed = false
	--超级抢庄配置
	self.m_tabSupperRobConfig = {}
	--金币抢庄提示
	self.m_bRobAlert = false

	--用户坐下配置
	self.m_tabSitDownConfig = {}
	self.m_tabSitDownUser = {}
	--自己坐下
	self.m_nSelfSitIdx = nil

	--座位列表
	self.m_tabSitDownList = {}

	--当前抢庄用户
	self.m_wCurrentRobApply = yl.INVALID_CHAIR

	--当前庄家用户
	self.m_wBankerUser = yl.INVALID_CHAIR

	--选中的筹码
	self.m_nSelectBet = DEFAULT_BET

	--是否结算状态
	self.m_bOnGameRes = false

	--是否无人坐庄
	self.m_bNoBanker = false
end

function GameViewLayer:gameDataReset(  )
	--资源释放
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(GameViewLayer.RES_PATH.."game/118_gameLayer.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey(GameViewLayer.RES_PATH.."game/118_gameLayer.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(GameViewLayer.RES_PATH.."game/118_dice.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey(GameViewLayer.RES_PATH.."game/118_dice.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(GameViewLayer.RES_PATH.."game/118_userList.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey(GameViewLayer.RES_PATH.."game/118_userList.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(GameViewLayer.RES_PATH.."game/118_applyList.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey(GameViewLayer.RES_PATH.."game/118_applyList.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(GameViewLayer.RES_PATH.."bank/118_bank.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey(GameViewLayer.RES_PATH.."bank/118_bank.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(GameViewLayer.RES_PATH.."bank/118_setLayer.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey(GameViewLayer.RES_PATH.."bank/118_setLayer.png")
	cc.Director:getInstance():getTextureCache():removeUnusedTextures()
	cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()

	--播放大厅背景音乐
	ExternalFun.playPlazzBackgroudAudio()

	--重置搜索路径
	local oldPaths = cc.FileUtils:getInstance():getSearchPaths();
	local newPaths = {};
	for k,v in pairs(oldPaths) do
		if tostring(v) ~= tostring(self._searchPath) then
			table.insert(newPaths, v);
		end
	end
	cc.FileUtils:getInstance():setSearchPaths(newPaths);

	--变量释放
	self.m_actDropIn:release();
	self.m_actDropOut:release();
	if nil ~= self.m_cardLayer then
		self.m_cardLayer:clean()
	end

	yl.m_bDynamicJoin = false;
	self:getDataMgr():removeAllUser()
	self:getDataMgr():clearRecord()
end

function GameViewLayer:getJettonIdx( llScore )
	local idx = 2;
	for i=1,#self.m_pJettonNumber do
		if llScore == self.m_pJettonNumber[i].k then
			idx = self.m_pJettonNumber[i].i;
			break;
		end
	end
	return idx;
end

function GameViewLayer:randomSetJettonPos( nodeArea, jettonSp )
	if nil == jettonSp then
		return;
	end

	local pos = self:getBetRandomPos(nodeArea)
	jettonSp:setPosition(cc.p(pos.x, pos.y));
end

function GameViewLayer:getBetFromPos( wchair )
	if nil == wchair then
		return {x = 0, y = 0}
	end
	local winSize = cc.Director:getInstance():getWinSize()

	--是否是自己
	if self:isMeChair(wchair) then
		--print("从自己发出筹码")
		local tmp = self._csbNode:getChildByName("Sprite_headBg")
		if nil ~= tmp then
			--print("从自己发出筹码")
			local pos = cc.p(tmp:getPositionX(), tmp:getPositionY())
			--pos = self.m_spBottom:convertToWorldSpace(pos)
			return {x = pos.x, y = pos.y}
		else
			if self.m_btnListLayer and self.m_btnListLayer:isVisible() == true then
				return {x = 60, y = 452}
			else
				local posX = self.m_BtnMenu:getPositionX()
				local posY = self.m_BtnMenu:getPositionY()
				return {x = posX, y = posY}
			end

		end
	else
		if self.m_btnListLayer and self.m_btnListLayer:isVisible() == true then
			return {x = 60, y = 452}
		else
			local posX = self.m_BtnMenu:getPositionX()
			local posY = self.m_BtnMenu:getPositionY()
			return {x = posX, y = posY}
		end
	end

	-- local useritem = self:getDataMgr():getChairUserList()[wchair + 1]
	-- if nil == useritem then
	-- 	return {x = winSize.width, y = 0}
	-- end

	-- --是否是坐下列表
	-- local idx = nil
	-- for i = 1,g_var(cmd).MAX_OCCUPY_SEAT_COUNT do
	-- 	if (nil ~= self.m_tabSitDownUser[i]) and (wchair == self.m_tabSitDownUser[i]:getChair()) then
	-- 		idx = i
	-- 		break
	-- 	end
	-- end
	-- if nil ~= idx then
	-- 	local pos = cc.p(self.m_tabSitDownUser[idx]:getPositionX(), self.m_tabSitDownUser[idx]:getPositionY())
	-- 	pos = self.m_roleSitDownLayer:convertToWorldSpace(pos)
	-- 	return {x = pos.x, y = pos.y}
	-- end

	--默认位置

end

function GameViewLayer:getBetAnimation( pos, call_back )
	--print("筹码终点位置1：",pos.x,pos.y)
	pos = self.m_betAreaLayout:convertToNodeSpace(pos)
	--print("筹码终点位置2：",pos.x,pos.y)
	local moveTo = cc.MoveTo:create(BET_ANITIME, cc.p(pos.x, pos.y))
	if nil ~= call_back then
		return cc.Sequence:create(cc.EaseIn:create(moveTo, 2), call_back)
	else
		return cc.EaseIn:create(moveTo, 2)
	end
end

function GameViewLayer:getBetRandomPos(nodeArea)
	if nil == nodeArea then
		return {x = 0, y = 0}
	end

	local nodeSize = cc.size(nodeArea:getContentSize().width - 80, nodeArea:getContentSize().height - 80);
	local xOffset = math.random()
	local yOffset = math.random()

	local posX = nodeArea:getPositionX() - nodeArea:getAnchorPoint().x * nodeSize.width
	local posY = nodeArea:getPositionY() - nodeArea:getAnchorPoint().y * nodeSize.height
	local pos = cc.p(xOffset * nodeSize.width + posX, yOffset * nodeSize.height + posY)
	--print("pos pos",pos.x,pos.y)
	return pos
end

------
--倒计时节点
function GameViewLayer:createClockNode(csbNode)
	self.m_pClock = cc.Node:create()
	self.m_pClock:setPosition(665,450)
	self:addToRootLayer(self.m_pClock, TAG_ZORDER.CLOCK_ZORDER)

	local nodeClock = csbNode:getChildByName("Node_clock")
	--倒计时
	self.m_pClock.m_atlasTimer = nodeClock:getChildByName("Text_num")
	self.m_pClock.m_atlasTimer:setString("0")

	--提示
	self.m_pClock.m_spTip = nodeClock:getChildByName("Sprite_tips")

end

function GameViewLayer:updateClock(tag, left)
	self.m_pClock:setVisible(left > 0)

	local str = string.format("%02d", left)
	self.m_pClock.m_atlasTimer:setString(str)

	if g_var(cmd).kGAMEOVER_COUNTDOWN == tag then
		if 15 == left then

			self:showGameResult(true)
			--改变庄家分数
			self:onChangeBanker()
		elseif 8 == left then				
			--筹码动画
			self:betAnimation()	
		elseif 6 == left then

		elseif 4 == left then	
			--更新路单列表
			self:updateWallBill()	
			self:refreshApplyList()	
			--self:showResult()
		elseif 3 == left then

		elseif 0 == left then
			self:showGameResult(false)	
			--闪烁停止
			self:jettonAreaBlinkClean()
		end
	elseif g_var(cmd).kGAMEPLAY_COUNTDOWN == tag then
		if 5 >= left then
    		ExternalFun.playSoundEffect("TIME_WARIMG.wav")
		end
	end
end

function GameViewLayer:showTimerTip(tag)
	tag = tag or -1
	local scale = cc.ScaleTo:create(0.2, 0.0001, 1.0)
	local call = cc.CallFunc:create(function (  )
		local str = string.format("118_tips_%d.png", tag)
		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(str)

		self.m_pClock.m_spTip:setVisible(false)
		if nil ~= frame then
			self.m_pClock.m_spTip:setVisible(true)
			self.m_pClock.m_spTip:setSpriteFrame(frame)
		end
	end)
	local scaleBack = cc.ScaleTo:create(0.2,1.0)
	local seq = cc.Sequence:create(scale, call, scaleBack)

	self.m_pClock.m_spTip:stopAllActions()
	self.m_pClock.m_spTip:runAction(seq)
end
------

------
--下注节点
function GameViewLayer:createJettonNode(area)
	local jettonNode = cc.Node:create()

	local Node_myjetton = self._csbNode:getChildByName("Node_myjetton")
	local str = string.format("Text_%d",area)
	--print("下注节点 str000",str)
	local m_textMyJetton = Node_myjetton:getChildByName(str)
	--m_textMyJetton:setVisible(false)


	if area == 1 or area == 2 then 
		local m_textTotalJetton = Node_myjetton:getChildByName(string.format("Text_1_%d",area))
		jettonNode.m_textTotalJetton = m_textTotalJetton
	end
	--jettonNode.m_imageBg = m_imageBg
	jettonNode.m_textMyJetton = m_textMyJetton

	jettonNode.m_llMyTotal = 0
	jettonNode.m_llAreaTotal = 0

	jettonNode.m_llOtherTotal = 0

	jettonNode.area = area
	return jettonNode
end

--刷新下注节点
function GameViewLayer:refreshJettonNode( node, my, total, bMyJetton )	

	if true == bMyJetton then
		node.m_llMyTotal = node.m_llMyTotal + my
	else
		node.m_llOtherTotal = node.m_llOtherTotal + my
	end
	--总数
	node.m_llAreaTotal = node.m_llAreaTotal + total

	node:setVisible( node.m_llMyTotal > 0)
	local isShow = node.m_llAreaTotal > 0 or node.m_llMyTotal > 0  
	--下注 大小的时候
	if node.area == 1 or node.area == 2 then
		--自己下注数额
		local score = 0
		if self.m_wBankerUser == self:getParentNode():GetMeChairID() then
			node.m_textMyJetton:setTextColor(cc.c3b(255,255,0))
			node.m_textMyJetton:setVisible(false)
		else
			local score = node.m_llMyTotal
			node.m_textTotalJetton:setTextColor(cc.c3b(0,0,255))
			--node.m_textMyJetton:setVisible(node.m_llAreaTotal > 0)
			node.m_textMyJetton:setVisible(isShow)
		end

		local str = ExternalFun.formatScoreText(node.m_llMyTotal);
		str = str .. "/"
		node.m_textMyJetton:setString(str);

		str = ExternalFun.formatScoreText(node.m_llAreaTotal)
		node.m_textTotalJetton:setString(str);
		--node.m_textTotalJetton:setVisible( node.m_llAreaTotal > 0)
		node.m_textTotalJetton:setVisible(isShow)
		--调整背景宽度
		local mySize = node.m_textMyJetton:getContentSize();
		local posX = node.m_textMyJetton:getPositionX()
		local totalSize = node.m_textTotalJetton:getContentSize();
		--local total = cc.size(mySize.width + totalSize.width + 18, 32);
		--node.m_imageBg:setContentSize(total);
		print("posX,mySize.width",posX,mySize.width)
		node.m_textTotalJetton:setPositionX( posX + mySize.width/2);
	else
		--自己下注数额 或者别人
		local score = 0

		if self.m_wBankerUser == self:getParentNode():GetMeChairID() then
			node.m_textMyJetton:setTextColor(cc.c3b(0,0,255))
			score = node.m_llOtherTotal
		else
			node.m_textMyJetton:setTextColor(cc.c3b(255,255,0))
			score = node.m_llMyTotal
		end
		local str = ExternalFun.formatScoreText(score);

		--node.m_textMyJetton:setVisible( node.m_llAreaTotal > 0)
		node.m_textMyJetton:setVisible(isShow)
		node.m_textMyJetton:setString(str);
	end

end

function GameViewLayer:reSetJettonNode(node)
	--node:setVisible(false);

	node.m_textMyJetton:setString("0/")
	node.m_textMyJetton:setVisible(false)
	if node.m_textTotalJetton then
		node.m_textTotalJetton:setString("0")
		node.m_textTotalJetton:setVisible(false)
	end

	--node.m_textTotalJetton:setString("")
	--node.m_imageBg:setContentSize(cc.size(34, 32))

	node.m_llMyTotal = 0
	node.m_llAreaTotal = 0
end
------

------
--银行节点
function GameViewLayer:createBankLayer()
	self.m_bankLayer = cc.Node:create()
	self:addToRootLayer(self.m_bankLayer, TAG_ZORDER.BANK_ZORDER)
	self.m_bankLayer:setTag(TAG_ENUM.BANK_LAYER)

	--加载csb资源
	local csbNode = ExternalFun.loadCSB("bank/118_BankLayer.csb", self.m_bankLayer)
	local sp_bg = csbNode:getChildByName("Sprite_Bg")

	------
	--按钮事件
	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onButtonClickedEvent(sender:getTag(), sender)
		end
	end	
	--关闭按钮
	local btn = sp_bg:getChildByName("Button_close")
	btn:setTag(TAG_ENUM.BT_CLOSEBANK)
	btn:addTouchEventListener(btnEvent)

	--取款按钮
	btn = sp_bg:getChildByName("Button_out")
	btn:setTag(TAG_ENUM.BT_TAKESCORE)
	btn:addTouchEventListener(btnEvent)
	------

	------
	--编辑框
	--取款金额
	local tmp = sp_bg:getChildByName("Sprite_outScoreText")
	local editbox = ccui.EditBox:create(tmp:getContentSize(),"118_bank_editText.png",UI_TEX_TYPE_PLIST)
		:setPosition(tmp:getPosition())
		:setFontName("fonts/round_body.ttf")
		:setPlaceholderFontName("fonts/round_body.ttf")
		:setFontSize(24)
		:setPlaceholderFontSize(24)
		:setMaxLength(32)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setPlaceHolder("请输入取款金额")
		:setFontColor(cc.c3b(71,255,255))
		:setPlaceholderFontColor(cc.c3b(71,255,255))
	sp_bg:addChild(editbox)
	self.m_bankLayer.m_editNumber = editbox
	tmp:removeFromParent()

	--取款密码
	tmp = sp_bg:getChildByName("Sprite_bankPWText")
	editbox = ccui.EditBox:create(tmp:getContentSize(),"118_bank_editText.png",UI_TEX_TYPE_PLIST)
		:setPosition(tmp:getPosition())
		:setFontName("fonts/round_body.ttf")
		:setPlaceholderFontName("fonts/round_body.ttf")
		:setFontSize(24)
		:setPlaceholderFontSize(24)
		:setMaxLength(32)
		:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setPlaceHolder("请输入取款密码")
		:setFontColor(cc.c3b(71,255,255))
		:setPlaceholderFontColor(cc.c3b(71,255,255))
	sp_bg:addChild(editbox)
	self.m_bankLayer.m_editPasswd = editbox
	tmp:removeFromParent()
	------

	--当前游戏币
	self.m_bankLayer.m_textCurrent = sp_bg:getChildByName("Text_curScore")

	--银行游戏币
	self.m_bankLayer.m_textBank = sp_bg:getChildByName("Text_bankScore")

	--取款费率
	self.m_bankLayer.m_textTips = sp_bg:getChildByName("Text_tip")
	self:getParentNode():sendRequestBankInfo()
end

--取款
function GameViewLayer:onTakeScore()
	--参数判断
	local szScore = string.gsub(self.m_bankLayer.m_editNumber:getText(),"([^0-9])","")
	local szPass = self.m_bankLayer.m_editPasswd:getText()

	if #szScore < 1 then 
		showToast(self,"请输入操作金额！",2)
		return
	end

	local lOperateScore = tonumber(szScore)
	if lOperateScore<1 then
		showToast(self,"请输入正确金额！",2)
		return
	end

	if #szPass < 1 then 
		showToast(self,"请输入银行密码！",2)
		return
	end
	if #szPass <6 then
		showToast(self,"密码必须大于6个字符，请重新输入！",2)
		return
	end

	self:showPopWait()	
	self:getParentNode():sendTakeScore(szScore,szPass)
end

--刷新金币
function GameViewLayer:refreshScore( userinfo )
	local userinfo = userinfo and userinfo or GlobalUserItem
	--携带游戏币
	local str = ExternalFun.numberThousands(userinfo.lUserScore)
	if string.len(str) > 19 then
		str = string.sub(str, 1, 19)
	end
	str = string.gsub(str,",","/")
	self.m_bankLayer.m_textCurrent:setString(str)
	--银行存款
	str = ExternalFun.numberThousands(userinfo.lUserInsure)
	if string.len(str) > 19 then
		str = string.sub(str, 1, 19)
	end
	str = string.gsub(str,",","/")
	self.m_bankLayer.m_textBank:setString(str)
	--self.m_bankLayer.m_textBank:setString(ExternalFun.numberThousands(userinfo.lUserInsure))

	self.m_bankLayer.m_editNumber:setText("")
	self.m_bankLayer.m_editPasswd:setText("")
end

------
return GameViewLayer