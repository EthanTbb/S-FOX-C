local GameViewLayer = class("GameViewLayer",function(scene)
		local gameViewLayer =  display.newLayer()
    return gameViewLayer
end)

if not yl then
require("client.src.plaza.models.yl")
end
local GameChat = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.game.GameChatLayer")
local cmd = appdf.req(appdf.GAME_SRC.."yule.zhajinhua.src.models.CMD_Game")
local PopupInfoHead = appdf.req("client.src.external.PopupInfoHead")

local CompareView = appdf.req(appdf.GAME_SRC.."yule.zhajinhua.src.views.layer.CompareView")
local GameEndView = appdf.req(appdf.GAME_SRC.."yule.zhajinhua.src.views.layer.GameEndView")
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")

GameViewLayer.BT_EXIT 				= 1
GameViewLayer.BT_CHAT 				= 2
GameViewLayer.BT_GIVEUP				= 3
GameViewLayer.BT_READY				= 4
GameViewLayer.BT_LOOKCARD			= 5
GameViewLayer.BT_FOLLOW				= 6
GameViewLayer.BT_ADDSCORE			= 7
GameViewLayer.BT_CHIP				= 8
GameViewLayer.BT_CHIP_1				= 9
GameViewLayer.BT_CHIP_2				= 10
GameViewLayer.BT_CHIP_3				= 11
GameViewLayer.BT_COMPARE 			= 12
GameViewLayer.BT_CARDTYPE			= 13
GameViewLayer.BT_SET				= 14
GameViewLayer.BT_MENU				= 15
GameViewLayer.BT_BANK 				= 16
GameViewLayer.CBT_VOICE				= 17

GameViewLayer.CHIPNUM 				= 100

local ptPlayer = {cc.p(100, 530), cc.p(100, 290), cc.p(667, 181), cc.p(1234, 290), cc.p(1234, 530)}
local ptCoin = {cc.p(180, 490), cc.p(180, 250), cc.p(637, 137), cc.p(1024, 250), cc.p(1024, 490)}
local ptCard = {cc.p(210, 550), cc.p(210, 310), cc.p(620, 310), cc.p(1054, 310), cc.p(1054, 550)}
local ptArrow = {cc.p(185, 620), cc.p(185, 380), cc.p(0, 0), cc.p(1149, 380), cc.p(1149, 620)}
local ptReady = {cc.p(244, 520), cc.p(244, 310), cc.p(640, 297), cc.p(1090, 310), cc.p(1090, 550)}
local ptLookCard = {cc.p(245, 541), cc.p(245, 301), cc.p(670, 284), cc.p(1089, 301), cc.p(1089, 541)}
local ptAddScore = {cc.p(245, 542), cc.p(245, 302), cc.p(670, 290), cc.p(1089, 302), cc.p(1089, 542)}
local ptGiveUpCard = {cc.p(245, 541), cc.p(245, 301), cc.p(670, 290), cc.p(1089, 301), cc.p(1089, 541)}
local ptChat = {cc.p(175, 635), cc.p(175, 395), cc.p(474, 312), cc.p(1159, 395), cc.p(1159, 635)}
local ptUserInfo = {cc.p(175, 430), cc.p(130, 340), cc.p(593, 225), cc.p(790, 340), cc.p(746, 430)}
local anchorPoint = {cc.p(0, 0), cc.p(0, 0), cc.p(0, 0), cc.p(1, 0), cc.p(1, 0)}


function GameViewLayer:OnResetView()
	self:stopAllActions()

	self.btReady:setVisible(false)
	self:OnShowIntroduce(false)

	self.m_ChipBG:setVisible(false)
	self.nodeButtomButton:setVisible(false)
    self.m_GameEndView:setVisible(false)

	self:SetBanker(yl.INVALID_CHAIR)
	self:SetAllTableScore(0)
	self:SetCompareCard(false)
	self:CleanAllJettons()
	self:StopCompareCard()
	self:SetMaxCellScore(0)

	for i = 1 ,cmd.GAME_PLAYER do
		--self:OnUpdateUser(i,nil)
		self:SetLookCard(i, false)
		self:SetUserCardType(i)
		self:SetUserTableScore(i, 0)
		self:SetUserGiveUp(i,false)
		self:SetUserCard(i, nil)
        self:clearCard(i)
	end
end

function GameViewLayer:onExit()
	print("GameViewLayer onExit")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(cmd.RES.."game_zjh_res.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey(cmd.RES.."game_zjh_res.png")
	cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
end
function GameViewLayer:ctor(scene)
	local this = self

	local function onNodeEvent(event)  
       if "exit" == event then  
            this:onExit()  
        end  
    end  

    self.m_UserChat = {}
  
    self:registerScriptHandler(onNodeEvent)  

	self._scene = scene

	self.nChip = {1, 2, 5}

	display.loadSpriteFrames(cmd.RES.."game_zjh_res.plist",cmd.RES.."game_zjh_res.png")

	--背景显示
	display.newSprite(cmd.RES.."game_desk.png")
		:move(667,375)
		:addTo(self)

	--按钮回调
	local  btcallback = function(ref, type)
        if type == ccui.TouchEventType.ended then
			this:OnButtonClickedEvent(ref:getTag(),ref)
        end
    end


	--筹码缓存
	self.nodeChipPool = cc.Node:create():addTo(self)

	--顶部信息
	self.m_AllScoreBG= display.newSprite("#game_bg_scoreinfo.png")
		:move(667,580)
		:addTo(self)

	display.newSprite("#game_word_allscore.png")
		:move(50,25)
		:addTo(self.m_AllScoreBG)

    --所有下注
	self.m_txtAllScore = cc.LabelAtlas:create("0",cmd.RES.."game_num_score.png",14,20,string.byte("0"))
		:move(90,25)
		:setAnchorPoint(cc.p(0,0.5))
		:addTo(self.m_AllScoreBG)

	--聊天按钮
	ccui.Button:create("bt_game_chat_0.png","bt_game_chat_1.png","",ccui.TextureResType.plistType)
		:move(600-220,45+135)
		:setTag(GameViewLayer.BT_CHAT)
		:addTo(self)
		:addTouchEventListener(btcallback)

	--底部按钮父节点
	self.nodeButtomButton = cc.Node:create()
		:setVisible(false)
		:addTo(self)

	--弃牌按钮
	self.btGiveUp = ccui.Button:create("bt_game_giveup_0.png","bt_game_giveup_1.png","",ccui.TextureResType.plistType)
		:move(667 - 60*2  - 192*2, 50)
		:setEnabled(false)
		:setColor(cc.c3b(158, 112, 8))
		:setTag(GameViewLayer.BT_GIVEUP)
		:addTo(self.nodeButtomButton)

	--看牌按钮
	self.btLookCard = ccui.Button:create("bt_game_look_0.png","bt_game_look_1.png","",ccui.TextureResType.plistType)
		:move(667 - 60  - 192, 50)
		:setEnabled(false)
		:setColor(cc.c3b(158, 112, 8))
		:setTag(GameViewLayer.BT_LOOKCARD)
		:addTo(self.nodeButtomButton)

	self.bCompareChoose = false
	--比牌按钮
	self.btCompare = ccui.Button:create("bt_game_compare_0.png","bt_game_compare_1.png","",ccui.TextureResType.plistType)
		:move(667, 50)
		:setEnabled(false)
		:setColor(cc.c3b(158, 112, 8))
		:setTag(GameViewLayer.BT_COMPARE)
		:addTo(self.nodeButtomButton)
	
	--加注按钮
	self.btAddScore = ccui.Button:create("bt_game_addscore_0.png","bt_game_addscore_1.png","",ccui.TextureResType.plistType)
		:move(667 + 60 + 192, 50)
		:setEnabled(false)
		:setColor(cc.c3b(158, 112, 8))
		:setTag(GameViewLayer.BT_ADDSCORE)
		:addTo(self.nodeButtomButton)
	
	--跟注按钮
	self.btFollow = ccui.Button:create("bt_game_follow_0.png","bt_game_follow_1.png","",ccui.TextureResType.plistType)
		:move(667 + 60*2 + 192*2, 50)
		:setEnabled(false)
		:setColor(cc.c3b(158, 112, 8))
		:setTag(GameViewLayer.BT_FOLLOW)
		:addTo(self.nodeButtomButton)
	
	self.btGiveUp:addTouchEventListener(btcallback)
	self.btLookCard:addTouchEventListener(btcallback)
	self.btCompare:addTouchEventListener(btcallback)
	self.btAddScore:addTouchEventListener(btcallback)
	self.btFollow:addTouchEventListener(btcallback)

	--玩家
	self.nodePlayer = {}
	--比牌判断区域
	self.rcCompare = {}

	self.m_UserHead = {}

	self.txtConfig = string.getConfig("fonts/round_body.ttf" , 20)
	self.MytxtConfig = string.getConfig("fonts/round_body.ttf" , 24)

	--时钟
	self.m_TimeProgress = {}

	for i = 1, cmd.GAME_PLAYER do
		--玩家总节点
		self.nodePlayer[i] = cc.Node:create()
							:move(ptPlayer[i])
							:setVisible(false)
							:addTo(self)

		self.rcCompare[i] = cc.rect(ptPlayer[i].x - 72 , ptPlayer[i].y -105 , 144 , 210)
		self.m_UserHead[i] = {}
		--玩家背景
		self.m_UserHead[i].bg = display.newSprite( (i == cmd.MY_VIEWID and "#game_head_frame_h.png" or "#game_head_frame_v.png"))
			--:setVisible(false)
			:addTo(self.nodePlayer[i])

		local txtsize = (i == cmd.MY_VIEWID and 24 or 20)
		local namepos = i == cmd.MY_VIEWID and cc.p(228,110) or cc.p(72,182)
		local scorepos = i == cmd.MY_VIEWID and cc.p(175,69) or cc.p(32,28)

		--昵称
		self.m_UserHead[i].name = cc.Label:createWithTTF("", "fonts/round_body.ttf", txtsize)
			:move(namepos)
			:setAnchorPoint(cc.p(0.5,0.5))
			:setLineBreakWithoutSpace(false)
			:setColor(cc.c3b(255, 255, 255))
			:addTo(self.m_UserHead[i].bg)
		--金币
		self.m_UserHead[i].score = cc.Label:createWithTTF("", "fonts/round_body.ttf", txtsize)
			:move(scorepos)
			:setAnchorPoint(cc.p(0,0.5))
			:setColor(cc.c3b(250, 250, 0))
			:addTo(self.m_UserHead[i].bg)

		--计时器
		self.m_TimeProgress[i] = cc.ProgressTimer:create(display.newSprite( (i == cmd.MY_VIEWID and "#game_time_progressex.png" or "#game_time_progress.png")))
             :setReverseDirection(true)
             :move(ptPlayer[i])
             :setVisible(false)
             :setPercentage(100)
             :addTo(self)
	end
	--手牌显示
	self.userCard = {}
	--下注显示
	self.m_ScoreView = {}
	--准备显示
	self.m_flagReady = {}
	--比牌箭头
	self.m_flagArrow = {}
	--看牌标示
	self.m_LookCard = {}
	--弃牌标示
	self.m_GiveUp = {}

	for i = 1, cmd.GAME_PLAYER do
		self.m_ScoreView[i] = {}
		--下注背景
		if i ~= cmd.MY_VIEWID then
			self.m_ScoreView[i].frame = display.newSprite("#bg_addscore.png",{scale9 = true ,capInsets=cc.rect(34, 0, 20, 36)})
				:setAnchorPoint(cc.p(0,0.5))
				:move(ptCoin[i])
				:setVisible(false)
				:setContentSize(134,36)
				:addTo(self)
		end
		--下注数额
		self.m_ScoreView[i].score = cc.LabelAtlas:create("0",cmd.RES.."game_num_addscore.png",14,20,string.byte("0"))
				:move(ptCoin[i].x+40,ptCoin[i].y)
				:setAnchorPoint(cc.p(0,0.5))
				:setVisible(false)
				:addTo(self)

		self.userCard[i] = {}
		self.userCard[i].card = {}
		--牌区域
		self.userCard[i].area = cc.Node:create()
			:setVisible(false)
			:addTo(self)
		--牌显示
		for j = 1, 3 do
			self.userCard[i].card[j] = display.newSprite("#card_back.png")
					:move(ptCard[i].x + (i==cmd.MY_VIEWID and 50 or 35)*(j - 1), ptCard[i].y)
					:setVisible(false)
					:addTo(self.userCard[i].area)
			if i ~= cmd.MY_VIEWID then
				self.userCard[i].card[j]:setScale(0.7)
			end
		end
		--牌类型
		self.userCard[i].cardType = display.newSprite("#card_type_0.png")
			:move(ptCard[i].x +  (i==cmd.MY_VIEWID and 50 or 35), ptCard[i].y- (i == 3 and 32 or 21))
			:setVisible(false)
			:addTo(self.userCard[i].area)


		--等待比牌箭头
		self.m_flagArrow[i] = display.newSprite((i <= 3 and "#arrow_l.png" or "#arrow_r.png"))
				:move(ptArrow[i])
				:setVisible(false)
				:addTo(self)

		--看牌标记
		self.m_LookCard[i] = display.newSprite("#game_flag_lookcard.png")
			:setVisible(false)
			:setScale(1.1)
			:move(ptLookCard[i])
			:addTo(self)

		--弃牌标示
		self.m_GiveUp[i] = display.newSprite("#game_flag_giveup.png")
			:setVisible(false)
			:setScale(1.3)
			:move(ptGiveUpCard[i])
			:addTo(self)

		self.m_flagReady[i] =  display.newSprite("#room_ready.png")
			:move(ptReady[i])
			:setVisible(false)
			:addTo(self)

		if i ~= cmd.MY_VIEWID then
			self.userCard[i].cardType:setScale(0.7)
			self.m_GiveUp[i]:setScale(1.1)
		end
				
	end

	--顶部信息
	local scoreinfo = display.newSprite("#game_bg_scoreinfo.png")
		:move(667,635)
		:addTo(self)
	display.newSprite("#game_word_cellscore.png")
		:move(50,25)
		:addTo(scoreinfo)
	display.newSprite("#game_word_maxscore.png")
		:move(220,25)
		:addTo(scoreinfo)
	--底注信息
	self.txt_CellScore = cc.LabelAtlas:create("0",cmd.RES.."game_num_score.png",14,20,string.byte("0"))
		:move(90,25)
		:setAnchorPoint(cc.p(0,0.5))
		:addTo(scoreinfo)
	--封顶显示
	self.txt_MaxCellScore = cc.LabelAtlas:create("0",cmd.RES.."game_num_score.png",14,20,string.byte("0"))
		:move(260, 25)
		:setAnchorPoint(cc.p(0,0.5))
		:addTo(scoreinfo)
			
	--庄家
	self.m_BankerFlag = display.newSprite("#banker.png")
		:setVisible(false)
		:addTo(self)
	--筹码按钮
	self.m_ChipBG = display.newSprite("#game_chip_bg.png")		--背景
		:move(1000, 145)
		:setVisible(false)
		:addTo(self)
	self.btChip = {}
	for i = 1, 3 do
		local strBigChip = string.format("bigchip_%d.png", i - 1)
		self.btChip[i] = ccui.Button:create(strBigChip, "", "bigchip_gray.png",ccui.TextureResType.plistType)
			:move(79 + 120*(i - 1), 66)
			:setPressedActionEnabled(true)
			:setTag(GameViewLayer.BT_CHIP + i)
			:addTo(self.m_ChipBG)

		self.btChip[i]:addTouchEventListener(btcallback)
		cc.Label:createWithTTF("0", "fonts/round_body.ttf", 18)
			:move(54, 53)
			:setColor(cc.c3b(48, 48, 48))
			:setTag(GameViewLayer.CHIPNUM)
			:addTo(self.btChip[i])
	end

	--菜单按钮
	ccui.Button:create("bt_game_menu_0.png","bt_game_menu_1.png","",ccui.TextureResType.plistType)
		:move(48,750-48)
		:setTag(GameViewLayer.BT_MENU)
		:addTo(self)
		:addTouchEventListener(btcallback)

	--显示菜单
	self.m_bShowMenu = false
	--菜单背景
	self.m_AreaMenu = display.newSprite("#game_menu_bg.png")
		:move(-178,613)
		:setVisible(false)
		:addTo(self)

	--银行按钮
	ccui.Button:create("bt_game_bank_0.png","bt_game_bank_1.png","",ccui.TextureResType.plistType)
		:move(58,51)
		:setVisible(false)
		:setTag(GameViewLayer.BT_BANK)
		:addTo(self.m_AreaMenu)
		:addTouchEventListener(btcallback)	

	--牌型按钮
	ccui.Button:create("bt_game_cardtype_0.png","bt_game_cardtype_1.png","",ccui.TextureResType.plistType)
		:move(58,51)
		:setTag(GameViewLayer.BT_CARDTYPE)
		:addTo(self.m_AreaMenu)
		:addTouchEventListener(btcallback)

	--声音按钮
	if GlobalUserItem.bVoiceAble then
		AudioEngine.playMusic(cmd.RES.."sound_res/BACK_MUSIC.mp3", true)
	end
	local bAble = GlobalUserItem.bSoundAble or GlobalUserItem.bVoiceAble
	ccui.CheckBox:create("sound_open_0.png",
		"sound_open_1.png",
		"sound_close_1.png",
		"sound_open_0.png","sound_open_0.png",ccui.TextureResType.plistType
		)
		:move(58+116,51)
		:setSelected(not bAble)
		:setTag(GameViewLayer.CBT_VOICE)
		:addTo(self.m_AreaMenu)
		:addEventListenerCheckBox(function(sender,eventType)
			local effect = not (GlobalUserItem.bSoundAble or GlobalUserItem.bVoiceAble)
			GlobalUserItem.setSoundAble(effect)
			GlobalUserItem.setVoiceAble(effect)
			if effect == true then
				AudioEngine.playMusic(cmd.RES.."sound_res/BACK_MUSIC.mp3", true)
			end
		end   
		)

	--退出按钮
	ccui.Button:create("bt_game_back_0.png","bt_game_back_1.png","",ccui.TextureResType.plistType)
		:move(290,51)
		:setTag(GameViewLayer.BT_EXIT)
		:addTo(self.m_AreaMenu)
		:addTouchEventListener(btcallback)

	--开始按钮
	self.btReady = ccui.Button:create("game_bt_ready_0.png","game_bt_ready_1.png","",ccui.TextureResType.plistType)
		:move(ptPlayer[3].x+267, ptPlayer[3].y)
		:setVisible(false)
		:setTag(GameViewLayer.BT_READY)
		:addTo(self)
	self.btReady:addTouchEventListener(btcallback)


	--缓存聊天
	self.m_UserChatView = {}
	--聊天泡泡
	for i = 1 , cmd.GAME_PLAYER do
		if i <= cmd.MY_VIEWID then
		self.m_UserChatView[i] = display.newSprite("#game_chat_lbg.png"	,{scale9 = true ,capInsets=cc.rect(30, 14, 46, 20)})
			:setAnchorPoint(cc.p(0,0.5))
			:move(ptChat[i])
			:setVisible(false)
			:addTo(self)
		else
		self.m_UserChatView[i] = display.newSprite( "#game_chat_rbg.png",{scale9 = true ,capInsets=cc.rect(14, 14, 46, 20)})
			:setAnchorPoint(cc.p(1,0.5))
			:move(ptChat[i])
			:setVisible(false)
			:addTo(self)
		end
	end

	--牌型介绍
	self.bIntroduce = false
	self.cardTypeIntroduce = display.newSprite("#card_type.png")
		:move(-163, display.cy)
		:setVisible(false)
		:addTo(self)

	--点击事件
	local touch = display.newLayer()
		:setLocalZOrder(10)
		:addTo(self)
	touch:setTouchEnabled(true)
	touch:registerScriptTouchHandler(function(eventType, x, y)
		return this:onTouch(eventType, x, y)
	end)

	self.m_CompareView = CompareView:create()
		:setVisible(false)
		:addTo(self)

	self.m_GameEndView	= GameEndView:create(self.MytxtConfig)
		:setVisible(false)
		:addTo(self)

	--聊天窗口
	self.m_GameChat = GameChat:create(scene._gameFrame)
		:setLocalZOrder(10)
        :addTo(self)
end

--更新时钟
function GameViewLayer:OnUpdataClockView(viewid,time)

end

--更新用户显示
function GameViewLayer:OnUpdateUser(viewid,userItem)
	if not viewid or viewid == yl.INVALID_CHAIR then
		print("OnUpdateUser viewid is nil")
		return
	end
	self.nodePlayer[viewid]:setVisible(userItem ~= nil)

	if not userItem then
		if self.m_UserHead[viewid].head then
			self.m_UserHead[viewid].head:setVisible(false)
		end
		self.m_UserHead[viewid].name:setString("")
		self.m_UserHead[viewid].score:setString("")
		self.m_flagReady[viewid]:setVisible(false)
	else
		self.nodePlayer[viewid]:setVisible(true)
		self.m_UserHead[viewid].name:setString(string.EllipsisByConfig(userItem.szNickName,viewid == cmd.MY_VIEWID and 150 or 105,viewid == cmd.MY_VIEWID and self.MytxtConfig or self.txtConfig))
		self.m_UserHead[viewid].score:setString(string.EllipsisByConfig(string.formatNumberThousands(userItem.lScore,true),viewid == cmd.MY_VIEWID and 150 or 105,viewid == cmd.MY_VIEWID and self.MytxtConfig or self.txtConfig))
		self.m_flagReady[viewid]:setVisible(yl.US_READY == userItem.cbUserStatus)
		if not self.m_UserHead[viewid].head then
			self.m_UserHead[viewid].head = PopupInfoHead:createNormal(userItem, 120)
			if viewid == cmd.MY_VIEWID then
				self.m_UserHead[viewid].head:move(72, 72)
			else
				self.m_UserHead[viewid].head:move(72, 105)
			end
			--self.m_UserHead[viewid].head:enableHeadFrame(true)
			self.m_UserHead[viewid].head:enableInfoPop(true, ptUserInfo[viewid], anchorPoint[viewid])
			self.m_UserHead[viewid].head:addTo(self.m_UserHead[viewid].bg)
		else
			self.m_UserHead[viewid].head:updateHead(userItem)
		end
		self.m_UserHead[viewid].head:setVisible(true)
	end
end

--屏幕点击
function GameViewLayer:onTouch(eventType, x, y)

	if eventType == "began" then
		--牌型显示判断
		if self.bIntroduce == true then
			return true
		end

		if self.m_bShowMenu == true then
			local rc = self.m_AreaMenu:getBoundingBox()
			if rc then
				if not cc.rectContainsPoint(rc,cc.p(x,y)) then
					self:ShowMenu(false)
					return true
				end
			end
		end

		--比牌选择判断
		if self.bCompareChoose == true then
			for i = 1, cmd.GAME_PLAYER do
				if cc.rectContainsPoint(self.rcCompare[i],cc.p(x,y)) then
					return true
				end
			end
		end

		--结算框
		if self.m_GameEndView:isVisible() then
			local rc = self.m_GameEndView:GetMyBoundingBox()
			if rc and not cc.rectContainsPoint(rc, cc.p(x, y)) then
				self.m_GameEndView:setVisible(false)
				return true
			end
		end

		return false
	elseif eventType == "ended" then
		--取消牌型显示
		if self.bIntroduce == true then
			local rectIntroduce = self.cardTypeIntroduce:getBoundingBox()
			if rectIntroduce and not cc.rectContainsPoint(rectIntroduce, cc.p(x, y)) then
				self:OnShowIntroduce(false)
			end
		end

		--比牌选择
		if self.bCompareChoose == true then
			for i = 1, cmd.GAME_PLAYER do
				if cc.rectContainsPoint(self.rcCompare[i],cc.p(x,y)) then
					self._scene:OnCompareChoose(i)
					break
				end
			end
		end
	end

	return true
end

--牌类型介绍的弹出与弹入
function GameViewLayer:OnShowIntroduce(bShow)
	if self.bIntroduce == bShow then
		return
	end

	local point
	if bShow then
		point = cc.p(163, display.cy) 			--移入的位置
	else
		point = cc.p(-163, display.cy)			--移出的位置
	end
	self.bIntroduce = bShow
	self.cardTypeIntroduce:stopAllActions()
	if bShow == true then
		self.cardTypeIntroduce:setVisible(true)
		self:ShowMenu(false)
	end
	local this = self
	self.cardTypeIntroduce:runAction(cc.Sequence:create(
		cc.MoveTo:create(0.3, point), 
		cc.CallFunc:create(function()
				this.cardTypeIntroduce:setVisible(this.bIntroduce)
			end)
		))

end

--筹码移动
function GameViewLayer:PlayerJetton(wViewChairId, num,notani)
	if not num or num < 1 or not self.m_lCellScore or self.m_lCellScore < 1 then
		return
	end
	local chipscore = num
	while chipscore > 0 
	do
		local strChip
		local strScore 
		if chipscore >= self.m_lCellScore * 5 then
			strChip = "#bigchip_2.png"
			chipscore = chipscore - self.m_lCellScore * 5
			strScore = (self.m_lCellScore*5)..""
		elseif chipscore >= self.m_lCellScore*2 then
			strChip = "#bigchip_1.png"
			chipscore = chipscore - self.m_lCellScore * 2
			strScore = (self.m_lCellScore*2)..""
		else
			strChip = "#bigchip_0.png"
			chipscore = chipscore - self.m_lCellScore 
			strScore = self.m_lCellScore..""
		end
		local chip = display.newSprite(strChip)
			:setScale(0.5)
			:addTo(self.nodeChipPool)

		cc.Label:createWithTTF(strScore, "fonts/round_body.ttf", 18)
			:move(54, 53)
			:setColor(cc.c3b(48, 48, 48))
			:addTo(chip)
		if notani == true then
			if wViewChairId < 3 then	
				chip:move( cc.p(350+ math.random(315), 390 + math.random(190)))
			elseif wViewChairId > 3 then
				chip:move(cc.p(667+ math.random(315), 390 + math.random(190)))
			else
				chip:move(cc.p(507+ math.random(315), 390 + math.random(190)))
			end
		else
			chip:move(ptCoin[wViewChairId].x,  ptCoin[wViewChairId].y)
			if wViewChairId < 3 then	
				chip:runAction(cc.MoveTo:create(0.2, cc.p(350+ math.random(315), 390 + math.random(190))))
			elseif wViewChairId > 3 then
				chip:runAction(cc.MoveTo:create(0.2, cc.p(667+ math.random(315), 390 + math.random(190))))
			else
				chip:runAction(cc.MoveTo:create(0.2, cc.p(507+ math.random(315), 390 + math.random(190))))
			end
		end
	end
	if not notani then
		self._scene:PlaySound(cmd.RES.."sound_res/ADD_SCORE.wav")
	end
end

--停止比牌动画
function GameViewLayer:StopCompareCard()
	self.m_CompareView:setVisible(false)
	self.m_CompareView:StopCompareCard()
end

--比牌
function GameViewLayer:CompareCard(firstuser,seconduser,firstcard,secondcard,bfirstwin,callback)
	self.m_CompareView:setVisible(true)
	self.m_CompareView:CompareCard(firstuser,seconduser,firstcard,secondcard,bfirstwin,callback)
end

--底注显示
function GameViewLayer:SetCellScore(cellscore)
	self.m_lCellScore = cellscore
	if not cellscore then
		self.txt_CellScore:setString("0")
		for i = 1, 3 do
			self.btChip[i]:getChildByTag(GameViewLayer.CHIPNUM):setString("")
		end
	else
		self.txt_CellScore:setString(cellscore)
		for i = 1, 3 do
			self.btChip[i]:getChildByTag(GameViewLayer.CHIPNUM):setString(cellscore*self.nChip[i])
		end
	end
end

--封顶分数
function GameViewLayer:SetMaxCellScore(cellscore)
	if not cellscore then
		self.txt_MaxCellScore:setString("")
	else
		self.txt_MaxCellScore:setString(""..cellscore)
	end
end

--庄家显示
function GameViewLayer:SetBanker(viewid)
	if not viewid or viewid == yl.INVALID_CHAIR then
		self.m_BankerFlag:setVisible(false)
		return
	end
	local x
	local y
	if viewid < 3 then
		x = ptPlayer[viewid].x + 54 
		y = ptPlayer[viewid].y + 86
	elseif viewid > 3 then
		x = ptPlayer[viewid].x - 54
		y = ptPlayer[viewid].y + 86
	else
		x = ptPlayer[viewid].x -148
		y = ptPlayer[viewid].y + 54
	end

	self.m_BankerFlag:setPosition(x, y)
	self.m_BankerFlag:setVisible(true)
end

--下注总额
function GameViewLayer:SetAllTableScore(score)
	if not score or score == 0 then
		self.m_AllScoreBG:setVisible(false)
	else
		self.m_txtAllScore:setString(score)
		self.m_AllScoreBG:setVisible(true)
	end
	
end

--玩家下注
function GameViewLayer:SetUserTableScore(viewid, score)
	--增加桌上下注金币
	if not score or score == 0 then
		if viewid ~= cmd.MY_VIEWID then
			self.m_ScoreView[viewid].frame:setVisible(false)
		end
		self.m_ScoreView[viewid].score:setVisible(false)
	else
		if viewid ~= cmd.MY_VIEWID then
			self.m_ScoreView[viewid].frame:setVisible(true)
		end
		self.m_ScoreView[viewid].score:setVisible(true)
		self.m_ScoreView[viewid].score:setString(score)
	end
end

--发牌
function GameViewLayer:SendCard(viewid,index,fDelay)
	if not viewid or viewid == yl.INVALID_CHAIR then
		return
	end
	local fInterval = 0.1

	local this = self
	local nodeCard = self.userCard[viewid]
	nodeCard.area:setVisible(true)

	local spriteCard = nodeCard.card[index]
	spriteCard:stopAllActions()
	spriteCard:setScale(1.0)
	spriteCard:setVisible(true)
	spriteCard:setSpriteFrame("card_back.png")
	spriteCard:move(display.cx, display.cy + 170)
	spriteCard:runAction(
		cc.Sequence:create(
		cc.DelayTime:create(fDelay),
		cc.CallFunc:create(
			function ()
				this._scene:PlaySound(cmd.RES.."sound_res/CENTER_SEND_CARD.wav")
			end
			),
			cc.Spawn:create(
				cc.ScaleTo:create(0.25,viewid==cmd.MY_VIEWID and 1.0 or 0.7),
				cc.MoveTo:create(0.25, cc.p(
					ptCard[viewid].x + (viewid==cmd.MY_VIEWID and 50 or 35)*(index- 1),ptCard[viewid].y))
				)
			)
		)

end

--看牌状态
function GameViewLayer:SetLookCard(viewid , bLook)
	if viewid == cmd.MY_VIEWID then
		return
	end

	self.m_LookCard[viewid]:setVisible(bLook)
end

--弃牌状态
function GameViewLayer:SetUserGiveUp(viewid ,bGiveup)
	local nodeCard = self.userCard[viewid]
    for i = 1, 3 do
        nodeCard.card[i]:setSpriteFrame("card_break.png")
        nodeCard.card[i]:setVisible(true)
    end
    self.m_GiveUp[viewid]:setVisible(bGiveup)
    if bGiveup == true then
    	self:SetLookCard(viewid, false)
    end
end

--清理牌
function GameViewLayer:clearCard(viewid)
	local nodeCard = self.userCard[viewid]
	for i = 1, 3 do
		nodeCard.card[i]:setSpriteFrame("card_break.png")
		nodeCard.card[i]:setVisible(false)
	end
	self.m_GiveUp[viewid]:setVisible(false)
end

--显示牌值
function GameViewLayer:SetUserCard(viewid, cardData)
	if not viewid or viewid == yl.INVALID_CHAIR then
		return
	end
	for i = 1, 3 do
		self.userCard[viewid].card[i]:stopAllActions()
		if viewid ~= cmd.MY_VIEWID then
			self.userCard[viewid].card[i]:setScale(0.7)
		end
		self.userCard[viewid].card[i]:move(ptCard[viewid].x +  (viewid==cmd.MY_VIEWID and 50 or 35)*(i- 1),ptCard[viewid].y)
	end
	--纹理
	if not cardData then
		for i = 1, 3 do
			self.userCard[viewid].card[i]:setSpriteFrame("card_back.png")
			self.userCard[viewid].card[i]:setVisible(false)
		end
	else
		for i = 1, 3 do
			local spCard = self.userCard[viewid].card[i]
			if not cardData[i] or cardData[i] == 0 or cardData[i] == 0xff  then
				spCard:setSpriteFrame("card_back.png")
			else
				local strCard = string.format("card_player_%02d.png",cardData[i])
				spCard:setSpriteFrame(strCard)
			end
			self.userCard[viewid].card[i]:setVisible(true)
		end
	end
end

GameViewLayer.RES_CARD_TYPE = {"card_type_0.png","card_type_1.png","card_type_2.png","card_type_3.png","card_type_14.png","card_type_5.png"}
--显示牌类型
function GameViewLayer:SetUserCardType(viewid,cardtype)
	local spriteCardType = self.userCard[viewid].cardType
	if cardtype and cardtype >= 1 and cardtype <= 6 then
		spriteCardType:setSpriteFrame(GameViewLayer.RES_CARD_TYPE[cardtype])
		spriteCardType:setVisible(true)
	else
		spriteCardType:setVisible(false)
	end
end

--赢得筹码
function GameViewLayer:WinTheChip(wWinner)
	--筹码动作
	local children = self.nodeChipPool:getChildren()
	for k, v in pairs(children) do
		v:runAction(cc.Sequence:create(cc.DelayTime:create(0.1*(#children - k)),
			cc.MoveTo:create(0.4, cc.p(ptPlayer[wWinner].x, ptPlayer[wWinner].y )),
			cc.CallFunc:create(function(node)
				node:removeFromParent()
			end)))
	end
end

--清理筹码
function GameViewLayer:CleanAllJettons()
	self.nodeChipPool:removeAllChildren()
end

--取消比牌选择
function GameViewLayer:SetCompareCard(bchoose,status)
	self.bCompareChoose = bchoose
    for i = 1, cmd.GAME_PLAYER do
    	if bchoose and status and status[i] then
    	 	self.m_flagArrow[i]:setVisible(true)
    	 	self.m_flagArrow[i]:runAction(cc.RepeatForever:create(cc.Sequence:create(
    	 		cc.ScaleTo:create(0.3,1.5),
    	 		cc.ScaleTo:create(0.3,1.0)
    	 		)))
    	else
    		self.m_flagArrow[i]:stopAllActions()
    	 	self.m_flagArrow[i]:setVisible(false)
    	end 
        
    end
end

--按键响应
function GameViewLayer:OnButtonClickedEvent(tag,ref)
	if tag == GameViewLayer.BT_EXIT then
		self._scene:onQueryExitGame()
	elseif tag == GameViewLayer.BT_READY then
		self._scene:onStartGame(true)
	elseif tag == GameViewLayer.BT_GIVEUP then
		self._scene:onGiveUp()
	elseif tag == GameViewLayer.BT_LOOKCARD then
		self._scene:onLookCard()
	elseif tag == GameViewLayer.BT_ADDSCORE then
		self.nodeButtomButton:setVisible(false)
		self.m_ChipBG:setVisible(true)
	elseif tag == GameViewLayer.BT_COMPARE then
		self._scene:onCompareCard()
	elseif tag == GameViewLayer.BT_CARDTYPE then
		self:OnShowIntroduce(true)
	elseif tag == GameViewLayer.BT_FOLLOW then
		self._scene:addScore(0)
	elseif tag == GameViewLayer.BT_CHIP_1 then
		self._scene:addScore(1)
	elseif tag == GameViewLayer.BT_CHIP_2 then
		self._scene:addScore(2)
	elseif tag == GameViewLayer.BT_CHIP_3 then
		self._scene:addScore(5)
	elseif tag == GameViewLayer.BT_CHAT then
		self.m_GameChat:showGameChat(true)
	elseif tag == GameViewLayer.BT_MENU then
		self:ShowMenu(not self.m_bShowMenu)
	elseif tag == GameViewLayer.BT_BANK then
		showToast(self, "该功能尚未开放，敬请期待...", 1)
	end
end

function GameViewLayer:ShowMenu(bShow)
	if self.m_bShowMenu ~= bShow then
		self.m_bShowMenu = bShow
		self.m_AreaMenu:stopAllActions()
		if self.m_bShowMenu == true and not self.m_AreaMenu:isVisible() then
			self.m_AreaMenu:setVisible(true)
			self.m_AreaMenu:runAction(cc.MoveTo:create(0.3,cc.p(178,613)))
		elseif self.m_AreaMenu:isVisible() == true then
			local this = self
			self.m_AreaMenu:runAction(
				cc.Sequence:create(
					cc.MoveTo:create(0.3,cc.p(-178,613)),
					cc.CallFunc:create(
					function()
						this.m_AreaMenu:setVisible(false)
					end
				)))
		end
	end
end

function GameViewLayer:runAddTimesAnimate(viewid)
	display.newSprite("#game_flag_addscore.png")
		:move(ptAddScore[viewid])
		:setScale(viewid == cmd.MY_VIEWID and 1.3 or 1.1)
		:addTo(self)
		:runAction(cc.Sequence:create(
						cc.DelayTime:create(2),
						cc.CallFunc:create(function(ref)
							ref:removeFromParent()
						end)
						))
end

--显示聊天
function GameViewLayer:ShowUserChat(viewid ,message)
	if message and #message > 0 then
		self.m_GameChat:showGameChat(false)
		--取消上次
		if self.m_UserChat[viewid] then
			self.m_UserChat[viewid]:stopAllActions()
			self.m_UserChat[viewid]:removeFromParent()
			self.m_UserChat[viewid] = nil
		end

		--创建label
		local limWidth = 20*12
		local labCountLength = cc.Label:createWithSystemFont(message,"Arial", 20)  
		if labCountLength:getContentSize().width > limWidth then
			self.m_UserChat[viewid] = cc.Label:createWithSystemFont(message,"Arial", 20, cc.size(limWidth, 0))
		else
			self.m_UserChat[viewid] = cc.Label:createWithSystemFont(message,"Arial", 20)
		end
		self.m_UserChat[viewid]:addTo(self)
		if viewid <= 3 then
			self.m_UserChat[viewid]:move(ptChat[viewid].x + 14 , ptChat[viewid].y + 5)
				:setAnchorPoint( cc.p(0, 0.5) )
		else
			self.m_UserChat[viewid]:move(ptChat[viewid].x - 14 , ptChat[viewid].y + 5)
				:setAnchorPoint(cc.p(1, 0.5))
		end
		--改变气泡大小
		self.m_UserChatView[viewid]:setContentSize(self.m_UserChat[viewid]:getContentSize().width+28, self.m_UserChat[viewid]:getContentSize().height + 27)
			:setVisible(true)
		--动作
		self.m_UserChat[viewid]:runAction(cc.Sequence:create(
						cc.DelayTime:create(3),
						cc.CallFunc:create(function()
							self.m_UserChatView[viewid]:setVisible(false)
							self.m_UserChat[viewid]:removeFromParent()
							self.m_UserChat[viewid]=nil
						end)
				))
	end
end

--显示表情
function GameViewLayer:ShowUserExpression(viewid,index)
	self.m_GameChat:showGameChat(false)
	--取消上次
	if self.m_UserChat[viewid] then
		self.m_UserChat[viewid]:stopAllActions()
		self.m_UserChat[viewid]:removeFromParent()
		self.m_UserChat[viewid] = nil
	end
	local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame( string.format("e(%d).png", index))
	if frame then
		self.m_UserChat[viewid] = cc.Sprite:createWithSpriteFrame(frame)
			:addTo(self)
		if viewid <= 3 then
			self.m_UserChat[viewid]:move(ptChat[viewid].x + 45 , ptChat[viewid].y + 5)
		else
			self.m_UserChat[viewid]:move(ptChat[viewid].x - 45 , ptChat[viewid].y + 5)
		end
		self.m_UserChatView[viewid]:setVisible(true)
			:setContentSize(90,65)
		self.m_UserChat[viewid]:runAction(cc.Sequence:create(
						cc.DelayTime:create(3),
						cc.CallFunc:create(function()
							self.m_UserChatView[viewid]:setVisible(false)
							self.m_UserChat[viewid]:removeFromParent()
							self.m_UserChat[viewid]=nil
						end)
				))
	end
end

return GameViewLayer