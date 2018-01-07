local GameViewLayer = class("GameViewLayer",function(scene)
		local gameViewLayer =  display.newLayer()
    return gameViewLayer
end)
local module_pre = "game.yule.sharkbattle.src"

local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local g_var = ExternalFun.req_var
local ClipText = appdf.EXTERNAL_SRC .. "ClipText"
local PopupInfoHead = appdf.EXTERNAL_SRC .. "PopupInfoHead"

local cmd = module_pre .. ".models.CMD_Game"
local game_cmd = appdf.HEADER_SRC .. "CMD_GameServer"
local QueryDialog   = require("app.views.layer.other.QueryDialog")

local SettingLayer = module_pre .. ".views.layer.SettingLayer"

local scheduler = cc.Director:getInstance():getScheduler()
GameViewLayer.TAG_START				= 100
local enumTable = 
{
	"BT_EXIT",
	"BT_START",
	"BT_LUDAN",
	"BT_BANK",
	"BT_SET",
	"BT_ROBBANKER",
	"BT_APPLYBANKER",
	"BT_USERLIST",
	"BT_APPLYLIST",
	"BANK_LAYER",
	"BT_CLOSEBANK",
	"BT_TAKESCORE"
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
	"BANK_ZORDER",
	"USERLIST_ZORDER",
	"WALLBILL_ZORDER",
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

local DEFAULT_BET = 1

function GameViewLayer:ctor(scene)
	ExternalFun.registerNodeEvent(self)
	
	self._scene = scene
	self:gameDataInit();
	self:initCsbRes();
	self:initAction();
end

function GameViewLayer:loadRes(  )
    for i=1,10 do
        str = string.format("Animal_0%d",i )
    	cc.Director:getInstance():getTextureCache():addImage(str);
        str = string.format("idb_niu__%d",i+1 )
    	cc.Director:getInstance():getTextureCache():addImage(str);
        if i <= 4 then
            str = string.format("RunningWater_0%d",i+1 )
    	    cc.Director:getInstance():getTextureCache():addImage(str);        
        end
    end
    
	cc.Director:getInstance():getTextureCache():addImage("game/IDB_SEL_PNG_01.png");
	cc.Director:getInstance():getTextureCache():addImage("game/IDB_SEL_PNG_02.png");
	cc.Director:getInstance():getTextureCache():addImage("game/IDB_SEL_PNG_03.png");
	cc.Director:getInstance():getTextureCache():addImage("game/IDB_SEL_PNG_04.png");
	cc.Director:getInstance():getTextureCache():addImage("game/IDB_SEL_PNG_05.png");
end

function GameViewLayer:gameDataInit(  )
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
    ExternalFun.playBackgroudAudio("GAME_BLACKGROUND.wav")

    self:AddMe(self:getParentNode():getUserList())
	self:loadRes()
    self.m_GameAnimation = nil
	self.m_nJettonSelect = -1
	self.m_lHaveJetton = 0;
	self.m_llMaxJetton = 1000000000;
	self.m_llCondition = 0;
	yl.m_bDynamicJoin = false;
	self.m_scoreUser = self:getMeUserItem().lScore or 0
    self.m_PresentWin = 0 ;
    self.m_Game_ConsequenceData = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    self.m_GameCondition = 0 ;
    self.m_AllJettonDown = {0,0,0,0,0,0,0,0,0,0,0,0} 
    self.m_PlayJettonDown = {0,0,0,0,0,0,0,0,0,0,0,0}
    self.m_Continuance_Data ={0,0,0,0,0,0,0,0,0,0,0,0}
    self.m_AnimalMultiple ={0,0,0,0,0,0,0,0,0,0,0,0}
	self.m_tableJettonBtn = {};
    self.m_tabJettonAnimate ={};
	self.m_nSelectBet = DEFAULT_BET;
    self.m_table_Area = {};
    self.m_BT_Continuance = {};
    self.m_BT_bright = {};
	self.m_textUserCoint = nil
	self.m_specifically = nil
    self.m_All_Jetton_Node = {};
    self.m_multiple_Node = {};
    self.m_Play_Jetton_Node ={};
    self.m_BetrothalGift = nil
    self.m_TransferSp = {};
    self.m_FlashOver = {};
    self.m_Game_Over = nil ;
    self.Game_Over_Special = nil;
    self.Game_Over_Animal = {};
    self.Game_ASP = {};
    self.Game_Over_Text ={};
    self.m_Game_Consequence = {};
	self.m_pClock = nil
	self.m_bankLayer = nil
	self.m_bOnGameRes = false

end
function GameViewLayer:initCsbRes(  )

	local rootLayer, csbNode = ExternalFun.loadRootCSB("game/GameLayer_GSS.csb", self);
	self.m_rootLayer = rootLayer
	local bottom_sp = csbNode:getChildByName("bottom_sp");
	self.m_spBottom = bottom_sp;
    self:initTEXT_Node(csbNode)
	self:initBtn(csbNode);

	self:initUserInfo();

	self:initJetton(csbNode);
    self:initArea(csbNode)
	self:createClockNode()	
    self:CresteGame_Over(csbNode)

    self:initTransfer(csbNode)
    self:initConsequence(csbNode)
    self:onAnimation()
end

function GameViewLayer:initConsequence(csbNode)
    self.m_Game_Consequence[1] = csbNode:getChildByName("Game_Consequence");
    for i =1 ,15 do
    	local str = string.format("Game_Consequence_%d", i-1)
		local Text = self.m_Game_Consequence[1]:getChildByName(str)
        self.m_Game_Consequence[i+1] = Text
        self.m_Game_Consequence[i+1]:setVisible(false)
    end
    
end
function GameViewLayer:initTransfer(csbNode)
    self.Game_Transfer = csbNode:getChildByName("Game_transfer");
    for i = 1 ,28 do
        local tag = i - 1
		local str = string.format("coordinate_%d", tag)
		local GameSp = self.Game_Transfer:getChildByName(str)
        self.m_TransferSp[i] = cc.Sprite:create("game/IDB_SEL_PNG_01.png") 
        self.m_TransferSp[i]:setVisible(false)
        GameSp:addChild(self.m_TransferSp[i]) 
    end
    
    self.m_FlashOver[1] = self.Game_Transfer:getChildByName("shan_1_1")
    self.m_FlashOver[2] = self.Game_Transfer:getChildByName("shan_1_2")   
    self.m_FlashOver[3] = self.Game_Transfer:getChildByName("shan_1_3")
    self.m_FlashOver[4] = self.Game_Transfer:getChildByName("shan_2_1")
    self.m_FlashOver[5] = self.Game_Transfer:getChildByName("shan_2_2")
    self.m_FlashOver[6] = self.Game_Transfer:getChildByName("shan_2_3")
    self.m_FlashOver[1]:setVisible(false)
    self.m_FlashOver[2]:setVisible(false)
    self.m_FlashOver[3]:setVisible(false)
    self.m_FlashOver[4]:setVisible(false)
    self.m_FlashOver[5]:setVisible(false)
    self.m_FlashOver[6]:setVisible(false)
end
function GameViewLayer:initTEXT_Node(csbNode)
    self.Game_Text = csbNode:getChildByName("TEXT_Node");
	self.m_textUserCoint = self.Game_Text:getChildByName("coin_text")
    self.m_specifically = self.Game_Text:getChildByName("specifically_text")
    for i=1,12 do
    	local tag = i - 1
		local str = string.format("All_Jetton_%d", tag)
		local Text = self.Game_Text:getChildByName(str)
        self.m_All_Jetton_Node[i] = Text

        str = string.format("multiple_%d", tag)
	    Text = self.Game_Text:getChildByName(str)
        self.m_multiple_Node[i] = Text

        str = string.format("Play_Jetton_%d", tag)
	    Text = self.Game_Text:getChildByName(str)
        self.m_Play_Jetton_Node[i] = Text

        str = string.format("0")
        self.m_All_Jetton_Node[i]:setString(str)
        self.m_Play_Jetton_Node[i]:setString(str)

        self.m_All_Jetton_Node[i]:setVisible(true)
        self.m_multiple_Node[i]:setVisible(true)
        self.m_Play_Jetton_Node[i]:setVisible(true)
    end
    self.m_BetrothalGift =  self.Game_Text:getChildByName("BetrothalGift")
end
function GameViewLayer:CresteGame_Over(csbNode)
    self.m_Game_Over = csbNode:getChildByName("Game_Over");
    self.m_Game_Over:setVisible(false)
    self.Game_Over_Special = self.m_Game_Over:getChildByName("Game_Over_Special");
    self.Game_Over_Animal[1] = self.m_Game_Over:getChildByName("Game_Over_Animal_0");
    self.Game_Over_Animal[2] = self.m_Game_Over:getChildByName("Game_Over_Animal_1");
    self.Game_Over_Special:setVisible(false)
    self.Game_Over_Animal[1]:setVisible(false)
    self.Game_Over_Animal[2]:setVisible(false)
    self.Game_ASP[1] = self.m_Game_Over:getChildByName("Game_ASP_0");
    self.Game_ASP[2] = self.m_Game_Over:getChildByName("Game_ASP_1");
    self.Game_ASP[1]:setVisible(false)
    self.Game_ASP[2]:setVisible(false)

    self.Game_Over_Text[1] = self.m_Game_Over:getChildByName("Game_Over_N_0");
    self.Game_Over_Text[2] = self.m_Game_Over:getChildByName("Game_Over_N_1");
    self.Game_Over_Text[3] = self.m_Game_Over:getChildByName("Game_Over_N_2");
    self.Game_Over_Text[1]:setVisible(false)
    self.Game_Over_Text[2]:setVisible(false)
    self.Game_Over_Text[3]:setVisible(false)
end
function GameViewLayer:initBtn( csbNode )
	local function checkEvent( sender,eventType )
		self:onCheckBoxClickEvent(sender, eventType);
	end
	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onButtonClickedEvent(sender:getTag(), sender);
		end
	end	
	btn = csbNode:getChildByName("bank_btn");
	btn:setTag(TAG_ENUM.BT_BANK);
	btn:addTouchEventListener(btnEvent);
	btn = csbNode:getChildByName("set_btn");
	btn:setTag(TAG_ENUM.BT_SET);
	btn:addTouchEventListener(btnEvent);
	btn = csbNode:getChildByName("back_btn");
	btn:setTag(TAG_ENUM.BT_EXIT);
	btn:addTouchEventListener(btnEvent);
    btn = csbNode:getChildByName("BT_Continuance");
	btn:setTag(10);
	btn:addTouchEventListener(btnEvent);
    self.m_BT_Continuance[1] = btn;
    btn = csbNode:getChildByName("BT_bright");
	btn:setTag(11);
	btn:addTouchEventListener(btnEvent);
    self.m_BT_bright[1] = btn;



end

function GameViewLayer:initUserInfo(  )	
	local tmp = self.m_spBottom:getChildByName("player_head")




	self:reSetUserInfo()
end

function GameViewLayer:reSetUserInfo(  )
	self.m_scoreUser = 0
	local myUser = self:getMeUserItem()
	if nil ~= myUser then
		self.m_scoreUser = myUser.lScore;
	end	
	print("自己金币:" .. ExternalFun.formatScore(self.m_scoreUser))
	local str = ExternalFun.numberThousands(self.m_scoreUser);
	if string.len(str) > 15 then
		str = string.sub(str,1,15) .. "...";
	end
	self.m_textUserCoint:setString(str);
end
function GameViewLayer:initJetton( csbNode )
	local bottom_sp = self.m_spBottom;
	local clip_layout = bottom_sp:getChildByName("clip_layout");
	self.m_layoutClip = clip_layout;
	self:initJettonBtnInfo();
end
function GameViewLayer:initArea(csbNode)
	local bottom_Area = csbNode:getChildByName("bottom_area");
    local function clipEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onJettonButtonClicked(sender:getTag(), sender);
		end
	end
    for i=1,12 do
	local tag = i - 1
	local str = string.format("Area_%d", tag)
	local btn = bottom_Area:getChildByName(str)
	btn:setTag(100+i)
	btn:addTouchEventListener(clipEvent)
	self.m_table_Area[i] = btn
	end
	self:reSetJettonBtnInfo(false);
end
function GameViewLayer:enableJetton( var )
	self:reSetJettonBtnInfo(var);

end

function GameViewLayer:initJettonBtnInfo(  )
	local clip_layout = self.m_layoutClip;

	local function clipEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onJettonButtonClicked(sender:getTag(), sender);
		end
	end

	self.m_pJettonNumber = 
	{
		{k = 100, i = 2},
		{k = 1000, i = 3}, 
		{k = 10000, i = 4}, 
		{k = 100000, i = 5}, 
		{k = 1000000, i = 6},
	}
   
	for i=1,#self.m_pJettonNumber do
		local tag = i - 1
		local str = string.format("chip%d_btn", tag)
		local btn = clip_layout:getChildByName(str)
		btn:setTag(i)
		btn:addTouchEventListener(clipEvent)
		self.m_tableJettonBtn[i] = btn
	end
    
        str = string.format("chip0")
		self.m_tabJettonAnimate[1] = clip_layout:getChildByName(str)

end

function GameViewLayer:reSetJettonBtnInfo( var )
	for i=1,#self.m_tableJettonBtn do
		self.m_tableJettonBtn[i]:setTag(i)
        self.m_tableJettonBtn[i]:setEnabled(var)
		self.m_tableJettonBtn[i]:setVisible(var)	
	end
    	self.m_tabJettonAnimate[1]:setVisible(var)
        for i = 1,#self.m_table_Area do
            self.m_table_Area[i]:setTag(100+i)
            self.m_table_Area[i]:setEnabled(var)
            self.m_table_Area[i]:setVisible(var)
        end
        
    self.m_BT_Continuance[1]:setVisible(var)
    self.m_BT_bright[1]:setVisible(var)
end

function GameViewLayer:adjustJettonBtn(  )

	local lCondition = self.m_scoreUser

	for i=1,#self.m_tableJettonBtn do
		local enable = false
		if self.m_bOnGameRes then
			enable = false
		else
			enable = self.m_bOnGameRes or (lCondition >= self.m_pJettonNumber[i].k)
		end
		self.m_tableJettonBtn[i]:setEnabled(enable);
	end

	if self.m_nJettonSelect > self.m_scoreUser then
		self.m_nJettonSelect = -1;
	end


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



function GameViewLayer:initAction(  )
	local dropIn = cc.ScaleTo:create(0.2, 1.0);
	dropIn:retain();
	self.m_actDropIn = dropIn;

	local dropOut = cc.ScaleTo:create(0.2, 1.0, 0.0000001);
	dropOut:retain();
	self.m_actDropOut = dropOut;
end

function GameViewLayer:onButtonClickedEvent(tag,ref)
	ExternalFun.playClickEffect()
	if tag == TAG_ENUM.BT_EXIT then
		self:getParentNode():onQueryExitGame()
	elseif tag == TAG_ENUM.BT_START then
		self:getParentNode():onStartGame()
	elseif tag == TAG_ENUM.BT_USERLIST then

	elseif tag == TAG_ENUM.BT_APPLYLIST then

	elseif tag == TAG_ENUM.BT_BANK then
		if 0 == GlobalUserItem.cbInsureEnabled then
			showToast(self,"初次使用，请先开通银行！",1)
			return
		end

		if nil == self.m_cbGameStatus or g_var(cmd).GAME_PLAY == self.m_cbGameStatus then
			showToast(self,"游戏过程中不能进行银行操作",1)
			return
		end
		local rule = self:getParentNode()._roomRule
		if rule == yl.GAME_GENRE_SCORE 
		or rule == yl.GAME_GENRE_EDUCATE then 
			print("练习 or 积分房")
		end
		if false == self:getParentNode():getFrame():OnGameAllowBankTake() then
		end

		if nil == self.m_bankLayer then
			self:createBankLayer()
		end
		self.m_bankLayer:setVisible(true)
		self:refreshScore()
	elseif tag == TAG_ENUM.BT_SET then
		local setting = g_var(SettingLayer):create()
		self:addToRootLayer(setting, TAG_ZORDER.SETTING_ZORDER)
	elseif tag == TAG_ENUM.BT_LUDAN then

	elseif tag == TAG_ENUM.BT_ROBBANKER then
	
	elseif tag == TAG_ENUM.BT_CLOSEBANK then
		if nil ~= self.m_bankLayer then
			self.m_bankLayer:setVisible(false)
		end
	elseif tag == TAG_ENUM.BT_TAKESCORE then
		self:onTakeScore()
    elseif tag == 10 then
        for i=1,12 do
            if self.m_Continuance_Data[i] >= 100  then
            	local m_nJettonSelect = self.m_Continuance_Data[i];
                self.m_lHaveJetton = self.m_lHaveJetton + m_nJettonSelect;
	            if self.m_lHaveJetton > self.m_llMaxJetton then
		            showToast(self,"已超过最大下注限额",1)
		            self.m_lHaveJetton = self.m_lHaveJetton - m_nJettonSelect;
		            return;
	            end
                if self.m_lHaveJetton > self.m_scoreUser then
		            showToast(self,"金币不足，下注失败！",1)
		            self.m_lHaveJetton = self.m_lHaveJetton - m_nJettonSelect;
		            return;
	            end
                self:getParentNode():sendUserBet(i-1, self.m_Continuance_Data[i]);
	            self:adjustJettonBtn();
            end 
        end
    elseif tag == 11 then
            for i=1,12 do
                self.m_AllJettonDown[i] = self.m_AllJettonDown[i] - self.m_PlayJettonDown[i]  ;
                self.m_PlayJettonDown[i] =   0 ;
            end
            self:onJettonBetClear()
	else
		showToast(self,"功能尚未开放！",1)
	end
end

function GameViewLayer:onJettonButtonClicked( tag, ref )
	if tag >= 1 and tag <= 5 then
		self.m_nJettonSelect = self.m_pJettonNumber[tag].k;
        self.m_nSelectBet = tag
        self.m_tabJettonAnimate[1]:setPosition(self.m_tableJettonBtn[self.m_nSelectBet]:getPositionX(),self.m_tableJettonBtn[self.m_nSelectBet]:getPositionY())
	elseif tag >= 101 and tag <= 112 then
        self:onJettonAreaClicked(tag,ref)

    else
		self.m_nJettonSelect = -1;
	end


	print("click jetton:" .. self.m_nJettonSelect);
end
function GameViewLayer:onJettonBetClear( )
	self:getParentNode():sendBetClear();
end
function GameViewLayer:onJettonAreaClicked( tag, ref )
	local m_nJettonSelect = self.m_nJettonSelect;

	if m_nJettonSelect < 0 then
		return;
	end

	local area = tag - 101;
	self.m_lHaveJetton = self.m_lHaveJetton + m_nJettonSelect;
	if self.m_lHaveJetton > self.m_llMaxJetton then
		showToast(self,"已超过最大下注限额",1)
		self.m_lHaveJetton = self.m_lHaveJetton - m_nJettonSelect;
		return;
	end
    if area > 11 then
    return ;
    end
	self:getParentNode():sendUserBet(area, m_nJettonSelect);
	self.m_scoreUser = self.m_scoreUser - m_nJettonSelect;
	self:adjustJettonBtn();


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



function GameViewLayer:onResetView()
	self:stopAllActions()
	self:gameDataReset()
end

function GameViewLayer:onExit()
	self:onResetView()
end


function GameViewLayer:onGameFree( )
	yl.m_bDynamicJoin = false
    for i = 1 , 12 do
        self.m_AllJettonDown[i] = 0
        self.m_PlayJettonDown[i] = 0
    end
    self:onGetUserBet()
      for i = 1,6 do
       self.m_FlashOver[i]:setVisible(false)
    end
    self:reSetUserInfo();
    self.m_Game_Over:setVisible(false)
end
function GameViewLayer:onGameStart( )
	self.m_nJettonSelect = self.m_pJettonNumber[self.m_nSelectBet].k;
	self.m_lHaveJetton = 0;
	self:reSetUserInfo();
    local str = string.format("0" )
    self.m_specifically:setString(str)
	self.m_bOnGameRes = false
		self:enableJetton(true);
		self:adjustJettonBtn();



	math.randomseed(tostring(os.time()):reverse():sub(1, 6))

end
function GameViewLayer:reEnterStart( lUserJetton )
	self.m_nJettonSelect = self.m_pJettonNumber[self.m_nSelectBet].k;
	self.m_lHaveJetton = lUserJetton;
	self.m_scoreUser = 0
	self:reSetUserInfo();

	self.m_bOnGameRes = false

		self:enableJetton(true);
		self:adjustJettonBtn();


end
function GameViewLayer:onGetApplyBankerCondition( llCon , rob_config)
	self.m_llCondition = llCon

end
function GameViewLayer:onGetUserBet( )

    for i=1,12 do
        str = string.format("%d", self.m_AllJettonDown[i])
        self.m_All_Jetton_Node[i]:setString(str)
        str = string.format("%d", self.m_PlayJettonDown[i])
        self.m_Play_Jetton_Node[i]:setString(str)

        self.m_All_Jetton_Node[i]:setVisible(true)
        self.m_Play_Jetton_Node[i]:setVisible(true)
    end
end
function GameViewLayer:reEnterGameBet( cbArea, llScore )

end
function GameViewLayer:reEnterUserBet( cbArea, llScore )

end
function GameViewLayer:onGetGameEnd(  )
	self.m_bOnGameRes = true

    for i = 1 ,12 do
        self.m_Continuance_Data[i] = self.m_PlayJettonDown[i]
    end
    
	self:enableJetton(false)

end

function GameViewLayer:refreshApplyList(  )

end

function GameViewLayer:refreshUserList(  )

end

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

function GameViewLayer:onBankFailure( )
	local bank_fail = self:getParentNode().bank_fail
	if nil == bank_fail then
		return
	end

	showToast(self, bank_fail.szDescribeString, 2)
end

function GameViewLayer:onGetBankInfo(bankinfo)
	bankinfo.wRevenueTake = bankinfo.wRevenueTake or 10
	if nil ~= self.m_bankLayer then
		local str = "温馨提示:取款将扣除" .. bankinfo.wRevenueTake .. "%的手续费"
		self.m_bankLayer.m_textTips:setString(str)
	end
end
function GameViewLayer:getParentNode( )
	return self._scene;
end

function GameViewLayer:getMeUserItem(  )
	if nil ~= GlobalUserItem.dwUserID then
      return self.ThisMe
	end
	return nil;
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



function GameViewLayer:getApplyCondition(  )
	return self.m_llCondition
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


function GameViewLayer:gameDataReset(  )
     for i=1,10 do
        str = string.format("Animal_0%d",i )
        cc.Director:getInstance():getTextureCache():removeTextureForKey(str);
        str = string.format("idb_niu__%d",i+1 )
    	cc.Director:getInstance():getTextureCache():removeTextureForKey(str);
        if i <= 4 then
            str = string.format("RunningWater_0%d",i+1 )
    	    cc.Director:getInstance():getTextureCache():removeTextureForKey(str);        
        end
    end
    	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game/GameGSS.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("game/GameGSS.png")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("game/IDB_SEL_PNG_01.png")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("game/IDB_SEL_PNG_02.png")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("game/IDB_SEL_PNG_03.png")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("game/IDB_SEL_PNG_04.png")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("game/IDB_SEL_PNG_05.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("bank/bank.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("bank/bank.png")
	local dict = cc.FileUtils:getInstance():getValueMapFromFile("public/public.plist")
	if nil ~= framesDict and type(framesDict) == "table" then
		for k,v in pairs(framesDict) do
			if k ~= "blank.png" then
				cc.SpriteFrameCache:getInstance():removeSpriteFrameByName(k)
			end
		end
	end
	cc.Director:getInstance():getTextureCache():removeTextureForKey("public_res/public_res.png")

	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("setting/setting.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("setting/setting.png")
	cc.Director:getInstance():getTextureCache():removeUnusedTextures()
	cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
	ExternalFun.playPlazzBackgroudAudio()
	local oldPaths = cc.FileUtils:getInstance():getSearchPaths();
	local newPaths = {};
	for k,v in pairs(oldPaths) do
		if tostring(v) ~= tostring(self._searchPath) then
			table.insert(newPaths, v);
		end
	end
	cc.FileUtils:getInstance():setSearchPaths(newPaths);
	self.m_actDropIn:release();
	self.m_actDropOut:release();


	yl.m_bDynamicJoin = false;
    if nil ~= self.m_GameAnimation then
		scheduler:unscheduleScriptEntry(self.m_GameAnimation)
		self.m_GameAnimation = nil
	end
end
function GameViewLayer:createClockNode()
	self.m_pClock = cc.Node:create()
    self.Game_Text:addChild(self.m_pClock) 
	self.m_pClock:setPosition(780,355)
	local csbNode = ExternalFun.loadCSB("game/GameClockNode_GSS.csb", self.m_pClock)
	self.m_pClock.m_atlasTimer = csbNode:getChildByName("timer_atlas")
	self.m_pClock.m_atlasTimer:setString("")
	self.m_pClock.m_spTip = csbNode:getChildByName("sp_tip")
  
	local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("blank.png")
	if nil ~= frame then
		self.m_pClock.m_spTip:setSpriteFrame(frame)
	end
    
end

function GameViewLayer:updateClock(tag, left)
	self.m_pClock:setVisible(left > 0)

	local str = string.format("%02d", left)
	self.m_pClock.m_atlasTimer:setString(str)

	if g_var(cmd).kGAMEPLAY_COUNTDOWN == tag then
		if 1 == left then
        self:reSetJettonBtnInfo(false)
		elseif 0 == left then

		end
	end
end

function GameViewLayer:showTimerTip(tag)
	tag = tag or -1
	local scale = cc.ScaleTo:create(0.2, 0.0001, 1.0)
	local call = cc.CallFunc:create(function (  )
		local str = string.format("TIME_FLAG_0%d.png", tag)
		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(str)

		self.m_pClock.m_spTip:setVisible(false)
		if nil ~= frame then
			self.m_pClock.m_spTip:setVisible(true)
			self.m_pClock.m_spTip:setSpriteFrame(frame)
		end
	end)
	local scaleBack = cc.ScaleTo:create(0.2,1.35)
	local seq = cc.Sequence:create(scale, call, scaleBack)

	self.m_pClock.m_spTip:stopAllActions()
	self.m_pClock.m_spTip:runAction(seq)
    self.m_GameCondition = tag
end

function GameViewLayer:refreshJettonNode( node, my, total, bMyJetton )	
	if true == bMyJetton then
		node.m_llMyTotal = node.m_llMyTotal + my
	end

	node.m_llAreaTotal = node.m_llAreaTotal + total
	node:setVisible( node.m_llAreaTotal > 0)
	local str = ExternalFun.numberThousands(node.m_llMyTotal);
	str = str .. " /";
	if string.len(str) > 15 then
		str = string.sub(str,1,12)
		str = str .. "... /";
	end
	node.m_textMyJetton:setString(str);
	str = ExternalFun.numberThousands(node.m_llAreaTotal)
	str = " " .. str;
	if string.len(str) > 15 then
		str = string.sub(str,1,12)
		str = str .. "..."
	else
		local strlen = string.len(str)
		local l = 15 + strlen
		if strlen > l then
			str = string.sub(str, 1, l - 3);
			str = str .. "...";
		end
	end
	node.m_textTotalJetton:setString(str);
	local mySize = node.m_textMyJetton:getContentSize();
	local totalSize = node.m_textTotalJetton:getContentSize();
	local total = cc.size(mySize.width + totalSize.width + 18, 32);
	node.m_imageBg:setContentSize(total);

	node.m_textTotalJetton:setPositionX(6 + mySize.width);
end

function GameViewLayer:reSetJettonNode(node)
	node:setVisible(false);

	node.m_textMyJetton:setString("")
	node.m_textTotalJetton:setString("")
	node.m_imageBg:setContentSize(cc.size(34, 32))

	node.m_llMyTotal = 0
	node.m_llAreaTotal = 0
end
function GameViewLayer:createBankLayer()
	self.m_bankLayer = cc.Node:create()
	self:addToRootLayer(self.m_bankLayer, TAG_ZORDER.BANK_ZORDER)
	self.m_bankLayer:setTag(TAG_ENUM.BANK_LAYER)
	local csbNode = ExternalFun.loadCSB("bank/BankLayer.csb", self.m_bankLayer)
	local sp_bg = csbNode:getChildByName("sp_bg")
	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onButtonClickedEvent(sender:getTag(), sender)
		end
	end	
	local btn = sp_bg:getChildByName("close_btn")
	btn:setTag(TAG_ENUM.BT_CLOSEBANK)
	btn:addTouchEventListener(btnEvent)
	btn = sp_bg:getChildByName("out_btn")
	btn:setTag(TAG_ENUM.BT_TAKESCORE)
	btn:addTouchEventListener(btnEvent)
	local tmp = sp_bg:getChildByName("count_temp")
	local editbox = ccui.EditBox:create(tmp:getContentSize(),"blank.png",UI_TEX_TYPE_PLIST)
		:setPosition(tmp:getPosition())
		:setFontName("fonts/round_body.ttf")
		:setPlaceholderFontName("fonts/round_body.ttf")
		:setFontSize(24)
		:setPlaceholderFontSize(24)
		:setMaxLength(32)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setPlaceHolder("请输入取款金额")
	sp_bg:addChild(editbox)
	self.m_bankLayer.m_editNumber = editbox
	tmp:removeFromParent()

	tmp = sp_bg:getChildByName("passwd_temp")
	editbox = ccui.EditBox:create(tmp:getContentSize(),"blank.png",UI_TEX_TYPE_PLIST)
		:setPosition(tmp:getPosition())
		:setFontName("fonts/round_body.ttf")
		:setPlaceholderFontName("fonts/round_body.ttf")
		:setFontSize(24)
		:setPlaceholderFontSize(24)
		:setMaxLength(32)
		:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		:setPlaceHolder("请输入取款密码")
	sp_bg:addChild(editbox)
	self.m_bankLayer.m_editPasswd = editbox
	tmp:removeFromParent()
	self.m_bankLayer.m_textCurrent = sp_bg:getChildByName("text_current")

	self.m_bankLayer.m_textBank = sp_bg:getChildByName("text_bank")

	self.m_bankLayer.m_textTips = sp_bg:getChildByName("text_tips")
	self:getParentNode():sendRequestBankInfo()
end

function GameViewLayer:onTakeScore()
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
function GameViewLayer:refreshScore(  )
	local str = ExternalFun.numberThousands(GlobalUserItem.lUserScore)
	if string.len(str) > 19 then
		str = string.sub(str, 1, 19)
	end
	self.m_bankLayer.m_textCurrent:setString(str)

	str = ExternalFun.numberThousands(GlobalUserItem.lUserInsure)
	if string.len(str) > 19 then
		str = string.sub(str, 1, 19)
	end
	self.m_bankLayer.m_textBank:setString(ExternalFun.numberThousands(GlobalUserItem.lUserInsure))

	self.m_bankLayer.m_editNumber:setText("")
	self.m_bankLayer.m_editPasswd:setText("")
end
function GameViewLayer:AddMe(userList)
    for k,v in pairs(userList) do
        if v.dwUserID ==  GlobalUserItem.dwUserID then
            self.ThisMe = v
        end
    end
    
end
function GameViewLayer:onAnimation()

	local function countDown(dt)
    self.m_IsFlicker_aid_1 = self.m_IsFlicker_aid_1 +1
    if self.m_IsFlicker_aid_1 == 2 then
        self.m_IsFlicker_aid_1 = 0;
                for i = 1 ,28 do
                     if self.m_IsFlicker[i] ~= 0 then
                         local str = string.format("game/IDB_SEL_PNG_0%d.png",self.m_IsFlicker[i])
                         self.m_TransferSp[i]:setTexture(str)
                         self.m_TransferSp[i]:setVisible(true)
                         self.m_IsFlicker[i] = self.m_IsFlicker[i] + 1;
                         if self.m_IsFlicker[i] > 5 then
                             self.m_IsFlicker[i] = 0
                             self.m_TransferSp[i]:setVisible(false)
                        end
                    end
                end  
    end
        if  self.m_GameCondition == 1 then
            self.m_ranmultiple_aid  = self.m_ranmultiple_aid  +1 
            if self.m_ranmultiple_aid  == 10 then
                 self.m_ranmultiple_aid  = 0
                 for i = 0 ,10000 do
                    local ranmultiple = math.random(1,5);
                    if ranmultiple ~=  self.m_ranmultiple then
                         self.m_ranmultiple = ranmultiple
                         break;
                    end
                 end
                 local  str = string.format("")
                 for i = 1 ,12 do
                      if i ~= 10 then
                            str = string.format("x%d",self.m_AreaMultiple[self.m_ranmultiple][i] )
                            else
                            str = string.format("x??" )
                      end
                      
                      self.m_multiple_Node[i]:setString(str)
                 end 
            end
       
        end
    if self.m_GameCondition == 1 or self.m_GameCondition == 2 then
        self.m_IsFlicker_aid = self.m_IsFlicker_aid  + 1

        if self.m_IsFlicker_aid  == 10 then
            self.m_IsFlicker_aid = 0
            local ranFlicker = math.random(1,28);
            self.m_IsFlicker[ranFlicker] = 1
            ranFlicker = math.random(1,700000000);
            ranFlicker = ranFlicker +123456789
            local str = string.format("%d",ranFlicker)
            self.m_BetrothalGift:setText(str)
        end
    end
    if self.m_GameCondition == 3 then
          if self.m_OverCondition == 1 or self.m_OverCondition == 3 then
                self.m_TurnTriggerCount = self.m_TurnTriggerCount +1 ;
                if self.m_TurnTriggerCount == self.m_TurnTrigger or (self.m_TurnTarget == 2 and self.m_TurnTwoTime == true) then
                    self.m_TurnTriggerCount = 0
                    if (self.m_TurnTarget == 1 and  self.m_TurnTwoTime == true) or self.m_TurnTwoTime == false then
                          if self.m_OverFrequency[self.m_TurnTarget + 2] < 10 and self.m_TurnTrigger > 1 then
                                self.m_TurnTrigger = self.m_TurnTrigger - 1
                          end
                          if self.m_OverFrequency[self.m_TurnTarget + 2] + 14 > self.m_OverFrequency[self.m_TurnTarget ]  then
                                self.m_TurnTrigger = self.m_TurnTrigger + 1
                          end
                    end
                    self.m_IsFlicker[self.m_OverFrequency[self.m_TurnTarget + 2]%28 + 1] = 1
                    self.m_OverFrequency[self.m_TurnTarget+2] = self.m_OverFrequency[self.m_TurnTarget + 2] + 1
                    if self.m_OverFrequency[self.m_TurnTarget] == self.m_OverFrequency[self.m_TurnTarget + 2] then
                        self.m_Game_Over:setVisible(true)
                        self.Game_Over_Special:setVisible(true)
                        local str = string.format("game/Animal_0%d.png",self.m_OverTurnTableAnimal[self.m_TurnTarget])
                        self.Game_Over_Animal[self.m_TurnTarget ]:setTexture(str)
                        self.Game_Over_Animal[self.m_TurnTarget ]:setVisible(true)

                        
                        self.m_OverCondition = self.m_OverCondition +1
                        if self.m_OverCondition ==2 then
                            self:AddConsequenceData(self.m_OverTurnTableAnimal[1]+1)
                        	local str = string.format("coordinate_%d", self.m_OverTurnTableTarget[1])
		                    local GameSp = self.Game_Transfer:getChildByName(str)
                            self.m_FlashOver[1]:setPosition(GameSp:getPosition())
                            self.m_FlashOver[2]:setPosition(self.m_table_Area[self.m_OverTurnTableAnimal[1]+1]:getPosition())
                              if self.m_OverTurnTableAnimal[1] <4 then
                                    self.m_FlashOver[3]:setPosition(self.m_table_Area[12]:getPosition())
                                else
                                    self.m_FlashOver[3]:setPosition(self.m_table_Area[11]:getPosition())
                              end
                              local strASP = string.format("game/Animal_0%d.png",self.m_OverTurnTableAnimal[self.m_TurnTarget])
                              self.Game_ASP[1]:setTexture(strASP)
                              self.Game_ASP[1]:setVisible(true)
                              strASP = string.format("x%d + ",self.m_AnimalMultiple[self.m_OverTurnTableAnimal[1]+1]  +  self.m_SharkJ)
                              self.Game_Over_Text[1]:setString(strASP)
                              self.Game_Over_Text[1]:setVisible(true)
                              
                              strASP = string.format("%d.wav",self.m_OverTurnTableAnimal[self.m_TurnTarget])
                              ExternalFun.playSoundEffect(strASP)
                            elseif self.m_OverCondition ==4 then
                                self:AddConsequenceData(self.m_OverTurnTableAnimal[2]+1)
                              	local str = string.format("coordinate_%d", self.m_OverTurnTableTarget[2])
		                        local GameSp = self.Game_Transfer:getChildByName(str)
                                self.m_FlashOver[4]:setPosition(GameSp:getPosition())
                                self.m_FlashOver[5]:setPosition(self.m_table_Area[self.m_OverTurnTableAnimal[2]+1]:getPosition())
                                if self.m_OverTurnTableAnimal[2] <4 then
                                    self.m_FlashOver[6]:setPosition(self.m_table_Area[12]:getPosition())
                                else
                                    self.m_FlashOver[6]:setPosition(self.m_table_Area[11]:getPosition())
                                end
                              local strASP = string.format("game/Animal_0%d.png",self.m_OverTurnTableAnimal[self.m_TurnTarget])
                              self.Game_ASP[2]:setTexture(strASP)
                              self.Game_ASP[2]:setVisible(true)
                              if self.m_TurnTwoTime == true then
                                   self.Game_ASP[2]:setPosition(793, self.Game_ASP[2]:getPositionY())
                                   self.Game_Over_Text[2]:setPosition(844, self.Game_ASP[2]:getPositionY())
                                   else
                                   self.Game_ASP[2]:setPosition(665, self.Game_ASP[2]:getPositionY())
                                   self.Game_Over_Text[2]:setPosition(716, self.Game_ASP[2]:getPositionY())
                              end
                              strASP = string.format("x%d",self.m_AnimalMultiple[self.m_OverTurnTableAnimal[2]+1] )
                              self.Game_Over_Text[2]:setString(strASP)
                              self.Game_Over_Text[2]:setVisible(true)
                              strASP = string.format("%d",self.m_PresentWin )
                              self.Game_Over_Text[3]:setString(strASP)
                              self.Game_Over_Text[3]:setVisible(true)
                              self.m_specifically:setString(strASP)
                              strASP = string.format("%d.wav",self.m_OverTurnTableAnimal[self.m_TurnTarget])
                              ExternalFun.playSoundEffect(strASP)
                        end
                    end
                end
          end
          if self.m_OverCondition > 1 then
               self.m_IsFlicker_aid_2 =   self.m_IsFlicker_aid_2 +1       
               if self.m_IsFlicker_aid_2  == 8 then
                    self.m_IsFlicker_aid_2  = 0
                    self.m_IsVis = (self.m_IsVis ~= true)
                    if self.m_TurnTwoTime == true then
                          self.m_FlashOver[1]:setVisible(self.m_IsVis)
                          self.m_FlashOver[2]:setVisible(self.m_IsVis)
                          if self.m_OverTurnTableAnimal[1]== 8 or self.m_OverTurnTableAnimal[1]== 9 then
                            self.m_FlashOver[3]:setVisible(false)
                            else
                            self.m_FlashOver[3]:setVisible(self.m_IsVis)
                         end
                    end
                    if self.m_OverCondition > 3 then
                         self.m_FlashOver[4]:setVisible(self.m_IsVis)
                         self.m_FlashOver[5]:setVisible(self.m_IsVis)
                         if self.m_OverTurnTableAnimal[2]== 8 or self.m_OverTurnTableAnimal[2]== 9  then
                            self.m_FlashOver[6]:setVisible(false)
                            else
                            self.m_FlashOver[6]:setVisible(self.m_IsVis)
                         end
                         
                    end
               end       
               
          end
          if self.m_OverCondition == 2 or self.m_OverCondition == 4 then
                self.m_IsFlicker_aid_3 = self.m_IsFlicker_aid_3 + 1;
                if self.m_IsFlicker_aid_3 % 2 == 0 then
                     if self.m_IsFlicker_aid_3 == 8 then
                          self.m_IsFlicker_aid_3 = 0
                     end
                     local str = string.format("game/RunningWater_0%d.png",self.m_IsFlicker_aid_3/2 + 1)
                     self.Game_Over_Special:setTexture(str)
                end
                local AnimalCoordinate = self.Game_Over_Animal[self.m_TurnTarget ]:getPositionX()

                if AnimalCoordinate > 700 then
                    AnimalCoordinate = AnimalCoordinate - 70
                    self.Game_Over_Animal[self.m_TurnTarget ]:setPosition(AnimalCoordinate, self.Game_Over_Animal[self.m_TurnTarget ]:getPositionY())
                    elseif AnimalCoordinate >650 then
                    AnimalCoordinate = AnimalCoordinate - 1
                    self.Game_Over_Animal[self.m_TurnTarget ]:setPosition(AnimalCoordinate, self.Game_Over_Animal[self.m_TurnTarget ]:getPositionY())
                    elseif AnimalCoordinate > -120 then
                    AnimalCoordinate = AnimalCoordinate - 120
                    self.Game_Over_Animal[self.m_TurnTarget ]:setPosition(AnimalCoordinate, self.Game_Over_Animal[self.m_TurnTarget ]:getPositionY())
                    elseif AnimalCoordinate > -230 then
                    AnimalCoordinate = AnimalCoordinate - 1
                    self.Game_Over_Animal[self.m_TurnTarget ]:setPosition(AnimalCoordinate, self.Game_Over_Animal[self.m_TurnTarget ]:getPositionY())
                    self.Game_Over_Animal[self.m_TurnTarget ]:setVisible(false)
                    self.Game_Over_Special:setVisible(false)
                    else
                    self.Game_Over_Animal[self.m_TurnTarget ]:setPosition(1400,self.Game_Over_Animal[self.m_TurnTarget ]:getPositionY())
                    self.m_TurnTarget = self.m_TurnTarget +1;
                        if self.m_TurnTarget > 2 then
                             self.m_TurnTarget = 2  
                        end
                        self.m_OverCondition = self.m_OverCondition +1
                end
              
        
          end
    end
	end
	if nil == self.m_GameAnimation then
        self:AnimationVariable()
		self.m_GameAnimation = scheduler:scheduleScriptFunc(countDown, 0.04, false)
	end
end
function GameViewLayer:AnimationVariable()
    self.m_AreaMultiple = {	                         
    {12,  8,  8,  6, 12,  8,  8,  6, 24, 24,  2,  2},
	{24, 24, 12,  3, 24, 24, 12,  3, 24, 24,  2,  2},
	{24,  8,  6,  6, 24,  8,  6,  6, 24, 24,  2,  2},
	{24, 12,  8,  4, 24, 12,  8,  4, 24, 24,  2,  2},
	{12, 12,  6,  6, 12, 12,  6,  6, 24, 24,  2,  2}}
    self.m_ranmultiple = 0                          
    self.m_ranmultiple_aid = 0                      
    self.m_IsFlicker = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    self.m_IsFlicker_aid = 0 ;
    self.m_IsFlicker_aid_1 = 0 ;
    self.m_IsFlicker_aid_2 = 0 ;
    self.m_IsFlicker_aid_3 = 0 ;
end
function GameViewLayer:GameOverVariable()
    self.m_OverTurnTableTarget = {0,0} ;
    self.m_OverTurnTableAnimal  = {0,0} ;
    self.m_IsVis = true;
    self.m_SharkJ = 0 ;
    self.m_TurnTwoTime = false ;
    self.m_TurnTarget = 0 ;
    self.m_AnimalSpecies = { 9,0,0,0 ,8,1,1,9,2,2,8,3,3,3,9,7,7,7,8,6,6,9,5,5,8,4,4,4};
    self.m_OverFrequency ={0,0,0,0}
     for i = 1 ,28 do
         if self.m_IsFlicker[i] ~= 0 then
             self.m_IsFlicker[i] = 0
             self.m_TransferSp[i]:setVisible(false)
         end
     end
     self.m_TurnTrigger = 10 ;
     self.m_TurnTriggerCount = 0;
     self.m_OverCondition = 0 ;

     self.Game_ASP[1]:setVisible(false)
     self.Game_Over_Text[1]:setVisible(false)
     self.Game_ASP[2]:setVisible(false)
     self.Game_Over_Text[2]:setVisible(false)
     self.Game_Over_Text[3]:setVisible(false)
end
function GameViewLayer:AddConsequenceData(Data)

    if self.m_Game_ConsequenceData[15] == 0 then
        for i = 1,15 do
            if  self.m_Game_ConsequenceData[i] == 0 then
                 self.m_Game_ConsequenceData[i] =Data
                 local str = string.format("game/idb_niu__%d.png",self.m_Game_ConsequenceData[i])
                 self.m_Game_Consequence[i+1]:setTexture(str)
                 self.m_Game_Consequence[i+1]:setVisible(true)
                 break ;
            end
        end 
        else
        for j = 1,14 do
                 self.m_Game_ConsequenceData[j] =  self.m_Game_ConsequenceData[j + 1]
                 local str = string.format("game/idb_niu__%d.png",self.m_Game_ConsequenceData[j])
                 self.m_Game_Consequence[j + 1]:setTexture(str)
        end
         self.m_Game_ConsequenceData[15] = Data
         local str = string.format("game/idb_niu__%d.png",self.m_Game_ConsequenceData[15])
         self.m_Game_Consequence[15 + 1]:setTexture(str)
    end
end
return GameViewLayer