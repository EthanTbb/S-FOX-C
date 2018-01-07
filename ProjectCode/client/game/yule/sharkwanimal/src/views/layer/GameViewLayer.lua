local GameViewLayer = class("GameViewLayer",function(scene)
		local gameViewLayer =  display.newLayer()
    return gameViewLayer
end)
local module_pre = "game.yule.sharkwanimal.src"

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

local UserListLayer = module_pre .. ".views.layer.userlist.UserListLayer"

----------------------------------------------------------
--定时器以及控制速率
local scheduler = cc.Director:getInstance():getScheduler()
--动物光圈闪动频率
local BLINK_SPEED_RANDOM = 0.5
local CHIPPOOL_BLINK_SPEED = 0.1
local BLINK_SPEED_RESULT = 0.5
--拖尾持续时间
local DISMIS_SPEED = 0.3
local DELAY_TWOCIRCLE = 1
local THISROUND_POSY = {normalAnimal = 330, goldShark = 210,normalShark = 295}
----------------------------------------------------------
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
local TAG_ENUM = ExternalFun.declarEnumWithTable(100, enumTable);
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
--定义按钮tag
local enumBtn = 
{
	"BT_100",
	"BT_1K",
	"BT_1W",
	"BT_10W",
	"BT_100W",

	"BT_GOON",
	"BT_CLEAR",

	"BT_BIRD",
	"BT_SHARK",
	"BT_ANIMAL",
	"BT_YANZI",
	"BT_GEZI",
	"BT_KONGQUE",
	"BT_LAOYING",
	"BT_SHIZI",
	"BT_XIONGMAO",
	"BT_HOUZI",
	"BT_TUZI",
	

	"BT_MENU",
	"BT_BANK",
	"BT_SETTING",
	"BT_BACK"
}
local ENUM_BTN = ExternalFun.declarEnumWithTable(0, enumBtn);

--定义下注数字
local enumChipNum = 
{
	"NUM_CHIPPOOl",	
	"NUM_TIME",
	"NUM_THISROUNDCHIP",
	"NUM_TOTLECHIP",
	"NUM_MYCHIP",

	"NUM_BIRE_ALL",
	"NUM_BIRE_SELF",
	"NUM_SHARK_ALL",
	"NUM_SHARK_SELF",
	"NUM_ANIMAL_ALL",
	"NUM_ANIMAL_SELF",
	"NUM_YANZI_ALL",
	"NUM_YANZI_SELF",
	"NUM_GEZI_ALL",
	"NUM_GEZI_SELF",
	"NUM_KONGQUE_ALL",
	"NUM_KONGQUE_SELF",
	"NUM_LAOYING_ALL",
	"NUM_LAOYING_SELF",
	"NUM_SHIZI_ALL",
	"NUM_SHIZI_SELF",
	"NUM_XIONGMAO_ALL",
	"NUM_XIONGMAO_SELF",
	"NUM_HOUZI_ALL",
	"NUM_HOUZI_SELF",
	"NUM_TUZI_ALL",
	"NUM_TUZI_SELF",
	

	"NUM_GOLDSHARK_OTHER0",
	"NUM_GOLDSHARK_OTHER1",
	"NUM_GOLDSHARK_OTHER2",

	"NUM_NORMALSHARK_RANDOM",
	"NUM_NORMALSHARK_END",
	"NUM_NORMALSHARK_OTHER"
}
local ENUM_CHIPNUM = ExternalFun.declarEnumWithTable(0, enumChipNum);
--额外附加动物精灵
local enumOtherAnimalSpr = 
{
	"SPR_GOLDSHARK_OTHER0",
	"SPR_GOLDSHARK_OTHER1",
	"SPR_GOLDSHARK_OTHER2",
	"SPR_NORMALSHARK_OTHER"
}
local ENUM_OTHERANIMALSPR = ExternalFun.declarEnumWithTable(0, enumOtherAnimalSpr);
--utils

--local UserListLayer = module_pre .. ".views.layer.userlist.UserListLayer"
--local ApplyListLayer = module_pre .. ".views.layer.userlist.ApplyListLayer"
local SettingLayer = module_pre .. ".views.layer.SettingLayer"
--local WallBillLayer = module_pre .. ".views.layer.WallBillLayer"
--local SitRoleNode = module_pre .. ".views.layer.SitRoleNode"
--local GameCardLayer = module_pre .. ".views.layer.GameCardLayer"
--local GameResultLayer = module_pre .. ".views.layer.GameResultLayer"



function GameViewLayer:ctor(scene)
	--注册node事件
	ExternalFun.registerNodeEvent(self)
	self._scene = scene
	--初始化游戏信息
	self:gameDataInit();
	--初始化csb界面
	self:initCsbRes();
	--初始化通用动作
	self:initAction();
end

---------------------------------------------------------------------------------------
--界面初始化
function GameViewLayer:initCsbRes(  )
	print("GameViewLayer:initCsbRes")
	local rootLayer, csbNode = ExternalFun.loadRootCSB("sharkwanimal/SharkGameLayer.csb", self);
	self.m_rootLayer = rootLayer
	self.m_csbNode = csbNode
    --定义动物光圈对象
	self:collectCircle(csbNode)

	--测试
	self:SetCircleRunInFree(true)

	--隐藏菜单层
	self.m_csbNode:getChildByName("button_allmenubg"):setScaleY(0)

	--初始化按钮
	self:initBtnAndNum(csbNode)

	--清理下注信息
	self:reSetChipString()

	--总共得分归零
	self:setChipString(ENUM_CHIPNUM.NUM_TOTLECHIP,0)

	--重置按钮光圈数组
	self:reSetCircleArry()

	--初始化上次下注信息
	self:initLastChips()

	--倒计时
	self:initTimer(csbNode)	
	print("GameViewLayer:initCsbRes end")
end

--初始化上次下注信息
function GameViewLayer:initLastChips( )
	self.m_lastChips = {}
	for i = ENUM_BTN.BT_BIRD,ENUM_BTN.BT_TUZI do
		self.m_lastChips[i] = 0
	end
	self.m_lastRoundChips = {}
    for i = ENUM_BTN.BT_BIRD,ENUM_BTN.BT_TUZI do
	    self.m_lastRoundChips[i] = 0
	end
    --print("____________________________________--------__________--------------");
end

function GameViewLayer:reSetForNewGame(  )
	--重置下注区域
	self:cleanJettonArea()
	--闪烁停止
	self:jettonAreaBlinkClean()
	--重置光圈数组
	self:reSetCircleArry()
	--选择注数重置
	self.m_jettonNum = nil;
	--停止动物光圈闪动
	if self.m_scheduler_animalCircle ~= nil then
		scheduler:unscheduleScriptEntry(self.m_scheduler_animalCircle)
		self.m_scheduler_animalCircle = nil
	end
end

--初始化按钮
function GameViewLayer:initBtnAndNum( csbNode )
	--历史成绩动物纹理
	self.histroyTexture = cc.Director:getInstance():getTextureCache():addImage("sharkwanimal/idb_niu_.png");
	--结局动物纹理
	self.roundEndTexture = cc.Director:getInstance():getTextureCache():addImage("sharkwanimal/tongji_dw_da.png");
	--按钮光圈文理
	--local circleTexture0 = cc.Director:getInstance():getTextureCache():addImage("sharkwanimal/select_animal_type.png");
	local circleTexture0_l = cc.Director:getInstance():getTextureCache():addImage("sharkwanimal/select_animal_type_l.png");
	local circleTexture0_r = cc.Director:getInstance():getTextureCache():addImage("sharkwanimal/select_animal_type_r.png");
	local circleTexture1 = cc.Director:getInstance():getTextureCache():addImage("sharkwanimal/select_shark.png");
	local circleTexture2 = cc.Director:getInstance():getTextureCache():addImage("sharkwanimal/select_animal_name.png");
	--下转按钮光圈
	local animalBtn = {}
	local animalBtnCircle = {}

	--按钮事件
	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onButtonClickedEvent(sender:getTag(), sender);
		end
	end	

	--下注大小选择按钮
	--100
	local btn = csbNode:getChildByName("btn100");
	animalBtn[ENUM_BTN.BT_100] = btn;
	btn:setTag(ENUM_BTN.BT_100);
	btn:addTouchEventListener(btnEvent);

	--1k
	btn = csbNode:getChildByName("btn1k");
	animalBtn[ENUM_BTN.BT_1K] = btn;
	btn:setTag(ENUM_BTN.BT_1K);
	btn:addTouchEventListener(btnEvent);
	--1w
	btn = csbNode:getChildByName("btn1w");
	animalBtn[ENUM_BTN.BT_1W] = btn;
	btn:setTag(ENUM_BTN.BT_1W);
	btn:addTouchEventListener(btnEvent);
	--10w
	btn = csbNode:getChildByName("btn10w");
	animalBtn[ENUM_BTN.BT_10W] = btn;
	btn:setTag(ENUM_BTN.BT_10W);
	btn:addTouchEventListener(btnEvent);
	--100w
	btn = csbNode:getChildByName("btn100w");
	animalBtn[ENUM_BTN.BT_100W] = btn;
	btn:setTag(ENUM_BTN.BT_100W);
	btn:addTouchEventListener(btnEvent);


	--续投
	btn = csbNode:getChildByName("btn_goon");
	animalBtn[ENUM_BTN.BT_GOON] = btn;
	btn:setTag(ENUM_BTN.BT_GOON);
	btn:addTouchEventListener(btnEvent);
	--清除
	btn = csbNode:getChildByName("btn_clear");
	animalBtn[ENUM_BTN.BT_CLEAR] = btn;
	btn:setTag(ENUM_BTN.BT_CLEAR);
	btn:addTouchEventListener(btnEvent);


	--飞禽
	btn = csbNode:getChildByName("btn_bird");
	animalBtn[ENUM_BTN.BT_BIRD] = btn;
	btn:setTag(ENUM_BTN.BT_BIRD);
	btn:addTouchEventListener(btnEvent);
	--燕子
	btn = csbNode:getChildByName("btn_yanzi");
	animalBtn[ENUM_BTN.BT_YANZI] = btn;
	btn:setTag(ENUM_BTN.BT_YANZI);
	btn:addTouchEventListener(btnEvent);
	--鸽子
	btn = csbNode:getChildByName("btn_gezi");
	animalBtn[ENUM_BTN.BT_GEZI] = btn;
	btn:setTag(ENUM_BTN.BT_GEZI);
	btn:addTouchEventListener(btnEvent);
	--孔雀
	btn = csbNode:getChildByName("btn_kongque");
	animalBtn[ENUM_BTN.BT_KONGQUE] = btn;
	btn:setTag(ENUM_BTN.BT_KONGQUE);
	btn:addTouchEventListener(btnEvent);
	--老鹰
	btn = csbNode:getChildByName("btn_laoying");
	animalBtn[ENUM_BTN.BT_LAOYING] = btn;
	btn:setTag(ENUM_BTN.BT_LAOYING);
	btn:addTouchEventListener(btnEvent);
	--鲨鱼
	btn = csbNode:getChildByName("btn_shark");
	animalBtn[ENUM_BTN.BT_SHARK] = btn;
	btn:setTag(ENUM_BTN.BT_SHARK);
	btn:addTouchEventListener(btnEvent);
	--狮子
	btn = csbNode:getChildByName("btn_shizi");
	animalBtn[ENUM_BTN.BT_SHIZI] = btn;
	btn:setTag(ENUM_BTN.BT_SHIZI);
	btn:addTouchEventListener(btnEvent);
	--熊猫
	btn = csbNode:getChildByName("btn_xiongmao");
	animalBtn[ENUM_BTN.BT_XIONGMAO] = btn;
	btn:setTag(ENUM_BTN.BT_XIONGMAO);
	btn:addTouchEventListener(btnEvent);
	--猴子
	btn = csbNode:getChildByName("btn_houzi");
	animalBtn[ENUM_BTN.BT_HOUZI] = btn;
	btn:setTag(ENUM_BTN.BT_HOUZI);
	btn:addTouchEventListener(btnEvent);
	--兔子
	btn = csbNode:getChildByName("btn_tuzi");
	animalBtn[ENUM_BTN.BT_TUZI] = btn;
	btn:setTag(ENUM_BTN.BT_TUZI);
	btn:addTouchEventListener(btnEvent);
	--走兽
	btn = csbNode:getChildByName("btn_animal");
	animalBtn[ENUM_BTN.BT_ANIMAL] = btn;
	btn:setTag(ENUM_BTN.BT_ANIMAL);
	btn:addTouchEventListener(btnEvent);


	--菜单
	btn = csbNode:getChildByName("Button_menu");
	animalBtn[ENUM_BTN.BT_MENU] = btn;
	btn:setTag(ENUM_BTN.BT_MENU);
	btn:addTouchEventListener(btnEvent);
	--银行
	btn = csbNode:getChildByName("button_allmenubg"):getChildByName("btn_bank");
	animalBtn[ENUM_BTN.BT_BANK] = btn;
	btn:setTag(ENUM_BTN.BT_BANK);
	btn:addTouchEventListener(btnEvent);
	--设置
	btn = csbNode:getChildByName("button_allmenubg"):getChildByName("btn_setting");
	animalBtn[ENUM_BTN.BT_SETTING] = btn;
	btn:setTag(ENUM_BTN.BT_SETTING);
	btn:addTouchEventListener(btnEvent);
	--返回大厅
	btn = csbNode:getChildByName("button_allmenubg"):getChildByName("btn_back");
	animalBtn[ENUM_BTN.BT_BACK] = btn;
	btn:setTag(ENUM_BTN.BT_BACK);
	btn:addTouchEventListener(btnEvent);
	--玩家列表
	btn = csbNode:getChildByName("Button_playerList");
	animalBtn[TAG_ENUM.BT_USERLIST] = btn;
	btn:setTag(TAG_ENUM.BT_USERLIST);
	btn:addTouchEventListener(btnEvent);
	

	

	--添加按钮光圈精灵
	for k,v in pairs(animalBtn) do
		print(k)
		local newspr = nil
		if k == ENUM_BTN.BT_BIRD then
			newspr = cc.Sprite:createWithTexture(circleTexture0_l)
		elseif k == ENUM_BTN.BT_ANIMAL then
			newspr = cc.Sprite:createWithTexture(circleTexture0_r)	
		elseif k >= ENUM_BTN.BT_YANZI and k <= ENUM_BTN.BT_TUZI then
			newspr = cc.Sprite:createWithTexture(circleTexture2)
		elseif k == ENUM_BTN.BT_SHARK then
			newspr = cc.Sprite:createWithTexture(circleTexture1)
		end

		if newspr ~= nil then
			newspr:setAnchorPoint(cc.p(0.5,0.5))
			newspr:setPosition(cc.p(v:getContentSize().width / 2 , v:getContentSize().height / 2))
			v:addChild(newspr)
			animalBtnCircle[k] = newspr
			newspr:setOpacity(0)
		end
	end
	-------------------------------------------------------
	--下注文本
	local texts = {}
	--彩金池
	local text = csbNode:getChildByName("panel_totle_bet"):getChildByName("AtlasLabel");
	texts[ENUM_CHIPNUM.NUM_CHIPPOOl] = text;
	--时钟
	text = csbNode:getChildByName("AtlasLabel_time");
	texts[ENUM_CHIPNUM.NUM_TIME] = text;
	--本局得分
	text = csbNode:getChildByName("panel_this_round"):getChildByName("AtlasLabel");
	texts[ENUM_CHIPNUM.NUM_THISROUNDCHIP] = text;
	--所有的分
	text = csbNode:getChildByName("panel_totle_score"):getChildByName("AtlasLabel");
	texts[ENUM_CHIPNUM.NUM_TOTLECHIP] = text;
	--我的资产
	text = csbNode:getChildByName("panle_my_money"):getChildByName("AtlasLabel");
	texts[ENUM_CHIPNUM.NUM_MYCHIP] = text;
	--飞禽-自己
	text = csbNode:getChildByName("btn_bird"):getChildByName("AtlasLabel_self");
	texts[ENUM_CHIPNUM.NUM_BIRE_SELF] = text;
	--飞禽-所有
	text = csbNode:getChildByName("btn_bird"):getChildByName("AtlasLabel_all");
	texts[ENUM_CHIPNUM.NUM_BIRE_ALL] = text;
	--燕子-自己
	text = csbNode:getChildByName("btn_yanzi"):getChildByName("AtlasLabel_self");
	texts[ENUM_CHIPNUM.NUM_YANZI_SELF] = text;
	--燕子-所有
	text = csbNode:getChildByName("btn_yanzi"):getChildByName("AtlasLabel_all");
	texts[ENUM_CHIPNUM.NUM_YANZI_ALL] = text;
	--鸽子-自己
	text = csbNode:getChildByName("btn_gezi"):getChildByName("AtlasLabel_self");
	texts[ENUM_CHIPNUM.NUM_GEZI_SELF] = text;
	--鸽子-所有
	text = csbNode:getChildByName("btn_gezi"):getChildByName("AtlasLabel_all");
	texts[ENUM_CHIPNUM.NUM_GEZI_ALL] = text;
	--孔雀-自己
	text = csbNode:getChildByName("btn_kongque"):getChildByName("AtlasLabel_self");
	texts[ENUM_CHIPNUM.NUM_KONGQUE_SELF] = text;
	--孔雀-所有
	text = csbNode:getChildByName("btn_kongque"):getChildByName("AtlasLabel_all");
	texts[ENUM_CHIPNUM.NUM_KONGQUE_ALL] = text;
	--老鹰-自己
	text = csbNode:getChildByName("btn_laoying"):getChildByName("AtlasLabel_self");
	texts[ENUM_CHIPNUM.NUM_LAOYING_SELF] = text;
	--老鹰-所有
	text = csbNode:getChildByName("btn_laoying"):getChildByName("AtlasLabel_all");
	texts[ENUM_CHIPNUM.NUM_LAOYING_ALL] = text;
	--鲨鱼-自己
	text = csbNode:getChildByName("btn_shark"):getChildByName("AtlasLabel_self");
	texts[ENUM_CHIPNUM.NUM_SHARK_SELF] = text;
	--鲨鱼-所有
	text = csbNode:getChildByName("btn_shark"):getChildByName("AtlasLabel_all");
	texts[ENUM_CHIPNUM.NUM_SHARK_ALL] = text;
	--狮子-自己
	text = csbNode:getChildByName("btn_shizi"):getChildByName("AtlasLabel_self");
	texts[ENUM_CHIPNUM.NUM_SHIZI_SELF] = text;
	--狮子-所有
	text = csbNode:getChildByName("btn_shizi"):getChildByName("AtlasLabel_all");
	texts[ENUM_CHIPNUM.NUM_SHIZI_ALL] = text;
	--熊猫-自己
	text = csbNode:getChildByName("btn_xiongmao"):getChildByName("AtlasLabel_self");
	texts[ENUM_CHIPNUM.NUM_XIONGMAO_SELF] = text;
	--熊猫-所有
	text = csbNode:getChildByName("btn_xiongmao"):getChildByName("AtlasLabel_all");
	texts[ENUM_CHIPNUM.NUM_XIONGMAO_ALL] = text;
	--猴子-自己
	text = csbNode:getChildByName("btn_houzi"):getChildByName("AtlasLabel_self");
	texts[ENUM_CHIPNUM.NUM_HOUZI_SELF] = text;
	--猴子-所有
	text = csbNode:getChildByName("btn_houzi"):getChildByName("AtlasLabel_all");
	texts[ENUM_CHIPNUM.NUM_HOUZI_ALL] = text;
	--兔子-自己
	text = csbNode:getChildByName("btn_tuzi"):getChildByName("AtlasLabel_self");
	texts[ENUM_CHIPNUM.NUM_TUZI_SELF] = text;
	--兔子-所有
	text = csbNode:getChildByName("btn_tuzi"):getChildByName("AtlasLabel_all");
	texts[ENUM_CHIPNUM.NUM_TUZI_ALL] = text;
	--走兽-自己
	text = csbNode:getChildByName("btn_animal"):getChildByName("AtlasLabel_self");
	texts[ENUM_CHIPNUM.NUM_ANIMAL_SELF] = text;
	--走兽-所有
	text = csbNode:getChildByName("btn_animal"):getChildByName("AtlasLabel_all");
	texts[ENUM_CHIPNUM.NUM_ANIMAL_ALL] = text;


	--额外层信息
	local sprAnimalOther ={}
	--金鲨鱼默认隐藏
	local goldSharkNode = csbNode:getChildByName("img_GoldShark")
	local goldShark_img0 = goldSharkNode:getChildByName("img_0")
	local goldShark_img1 = goldSharkNode:getChildByName("img_1")
	local goldShark_img2 = goldSharkNode:getChildByName("img_2")
	goldSharkNode:setVisible(false)
	goldShark_img0:setVisible(false)
	goldShark_img1:setVisible(false)
	goldShark_img2:setVisible(false)
	--金鲨鱼-额外1
	text = goldShark_img0:getChildByName("AtlasLabel");
	texts[ENUM_CHIPNUM.NUM_GOLDSHARK_OTHER0] = text;
	local sprOther = goldShark_img0:getChildByName("Node");
	sprAnimalOther[ENUM_OTHERANIMALSPR.SPR_GOLDSHARK_OTHER0] = sprOther
	--金鲨鱼-额外2
	text = goldShark_img1:getChildByName("AtlasLabel");
	texts[ENUM_CHIPNUM.NUM_GOLDSHARK_OTHER1] = text;
	sprOther = goldShark_img1:getChildByName("Node");
	sprAnimalOther[ENUM_OTHERANIMALSPR.SPR_GOLDSHARK_OTHER1] = sprOther
	--金鲨鱼-额外3
	text = goldShark_img2:getChildByName("AtlasLabel");
	texts[ENUM_CHIPNUM.NUM_GOLDSHARK_OTHER2] = text;
	sprOther = goldShark_img2:getChildByName("Node");
	sprAnimalOther[ENUM_OTHERANIMALSPR.SPR_GOLDSHARK_OTHER2] = sprOther
		
	--普通鲨鱼默认隐藏
	local normalSharkNode = csbNode:getChildByName("img_NormalShark")
	local normalShark_img = normalSharkNode:getChildByName("img_0")
	normalSharkNode:setVisible(false)
	normalShark_img:setVisible(false)
	--普通鲨鱼-随机
	text = normalSharkNode:getChildByName("AtlasLabel_Random");
	texts[ENUM_CHIPNUM.NUM_NORMALSHARK_RANDOM] = text;
	--普通鲨鱼-最终
	text = normalSharkNode:getChildByName("AtlasLabel_End");
	texts[ENUM_CHIPNUM.NUM_NORMALSHARK_END] = text;
	--普通鲨鱼-额外
	text = normalShark_img:getChildByName("AtlasLabel");
	texts[ENUM_CHIPNUM.NUM_NORMALSHARK_OTHER] = text;
	sprOther = normalShark_img:getChildByName("Node");
	sprAnimalOther[ENUM_OTHERANIMALSPR.SPR_NORMALSHARK_OTHER] = sprOther

	self.m_operateBtn = animalBtn;				--按钮
	self.m_animalBtnCircle = animalBtnCircle;	--动物按钮光圈
	self.m_atlasLabels = texts;					--所有数字文本
	self.m_animalSprOther = sprAnimalOther;		--额外动物节点
	self.m_goldSharkNode = goldSharkNode;		--金鲨鱼层
	self.m_normalSharkNode = normalSharkNode;	--银鲨鱼层
end

--重置金鲨鱼面板
function GameViewLayer:reSetGoldSharkLayer(  )
	local goldSharkNode = self.m_csbNode:getChildByName("img_GoldShark")
	local goldShark_img0 = goldSharkNode:getChildByName("img_0")
	local goldShark_img1 = goldSharkNode:getChildByName("img_1")
	local goldShark_img2 = goldSharkNode:getChildByName("img_2")
	local goldShark_animalNode0 = goldShark_img0:getChildByName("Node")
	local goldShark_animalNode1 = goldShark_img1:getChildByName("Node")
	local goldShark_animalNode2 = goldShark_img2:getChildByName("Node")
	goldSharkNode:setVisible(false)
	goldShark_img0:setVisible(false)
	goldShark_img1:setVisible(false)
	goldShark_img2:setVisible(false)
	goldShark_animalNode0:removeAllChildren()
	goldShark_animalNode1:removeAllChildren()
	goldShark_animalNode2:removeAllChildren()
end
--重置普通鲨鱼面板
function GameViewLayer:reSetNormalSharkLayer(  )
	local normalSharkNode = self.m_csbNode:getChildByName("img_NormalShark")
	local normalShark_img = normalSharkNode:getChildByName("img_0")
	local normalShark_animalNode = normalShark_img:getChildByName("Node")
	normalSharkNode:setVisible(false)
	normalShark_img:setVisible(false)
	normalShark_animalNode:removeAllChildren()

	self.m_atlasLabels[ENUM_CHIPNUM.NUM_NORMALSHARK_RANDOM]:setVisible(false)
	self.m_atlasLabels[ENUM_CHIPNUM.NUM_NORMALSHARK_END]:setVisible(false)
end
--显示金鲨鱼面板
function GameViewLayer:showGoldSharkLayer(cmd_gameend)
	local goldSharkNode = self.m_csbNode:getChildByName("img_GoldShark")
	local goldShark_img0 = goldSharkNode:getChildByName("img_0")
	local goldShark_img1 = goldSharkNode:getChildByName("img_1")
	local goldShark_img2 = goldSharkNode:getChildByName("img_2")
	local goldShark_animalNode0 = goldShark_img0:getChildByName("Node")
	local goldShark_animalNode1 = goldShark_img1:getChildByName("Node")
	local goldShark_animalNode2 = goldShark_img2:getChildByName("Node")

	--操作旋转回合数
	local otherAnimal = nil
	local endIndex = nil
	if self.m_circleRunTimes == 4 then
		goldSharkNode:setVisible(true)
		endIndex = cmd_gameend.cbTableCardArray[2][1]
	elseif self.m_circleRunTimes == 3 then
		goldShark_img0:setVisible(true)
		endIndex = cmd_gameend.cbTableCardArray[2][1]
    	otherAnimal = cc.Sprite:createWithTexture(
    		self.histroyTexture, 
    		cc.rect(self:chargeAnimalKind(endIndex) * 51, 0, 51, 41)
    		);
		goldShark_animalNode0:addChild(otherAnimal)
		self:setChipString(ENUM_CHIPNUM.NUM_GOLDSHARK_OTHER0, self:chargeAnimalMultiple(endIndex))
		endIndex = cmd_gameend.cbTableCardArray[2][2]
	elseif self.m_circleRunTimes == 2 then
		goldShark_img1:setVisible(true)
		endIndex = cmd_gameend.cbTableCardArray[2][2]
    	otherAnimal = cc.Sprite:createWithTexture(
    		self.histroyTexture, 
    		cc.rect(self:chargeAnimalKind(endIndex) * 51, 0, 51, 41)
    		);
		goldShark_animalNode1:addChild(otherAnimal)
		self:setChipString(ENUM_CHIPNUM.NUM_GOLDSHARK_OTHER1, self:chargeAnimalMultiple(endIndex))
		endIndex = cmd_gameend.cbTableCardArray[2][3]
	elseif self.m_circleRunTimes == 1 then
		goldShark_img2:setVisible(true)
		endIndex = cmd_gameend.cbTableCardArray[2][3]
    	otherAnimal = cc.Sprite:createWithTexture(
    		self.histroyTexture, 
    		cc.rect(self:chargeAnimalKind(endIndex) * 51, 0, 51, 41)
    		);
		goldShark_animalNode2:addChild(otherAnimal)
		self:setChipString(ENUM_CHIPNUM.NUM_GOLDSHARK_OTHER2, self:chargeAnimalMultiple(endIndex))
		--最后一次设置本剧得分的位置
		local thisRound = self.m_csbNode:getChildByName("panel_this_round")
		thisRound:setPositionY(THISROUND_POSY.goldShark)
		thisRound:setLocalZOrder(200)
        --显示最后得分
        self:setGameEndScore(cmd_gameend)
		return
	elseif self.m_circleRunTimes <= 0 or self.m_circleRunTimes == nil then
		return
	end
	self.m_circleRunTimes = self.m_circleRunTimes - 1
	--额外旋转
	self:otherCircleRun(endIndex,cmd_gameend,true)
end
--显示普通鲨鱼面板
function GameViewLayer:showNormalSharkLayer(cmd_gameend)
	local normalSharkNode = self.m_csbNode:getChildByName("img_NormalShark")
	local normalShark_img = normalSharkNode:getChildByName("img_0")
	local normalShark_animalNode = normalShark_img:getChildByName("Node")

	--操作旋转回合数
	local otherAnimal = nil
	local endIndex = nil


	local needRunTime = 3	--随机倍数动画运行时间
	local needRunCount = needRunTime / CHIPPOOL_BLINK_SPEED --运行次数
	--额外倍数动画
	function actOfMultiple(dt)
		self.m_atlasLabels[ENUM_CHIPNUM.NUM_NORMALSHARK_RANDOM]:setVisible(true)
		local randomNum = nil
		randomNum = math.random(1 , 99)
		if randomNum < 10 then
			randomNum = "0"..randomNum
		end
		self:setChipString(ENUM_CHIPNUM.NUM_NORMALSHARK_RANDOM, randomNum)
		needRunCount = needRunCount - 1
		if needRunCount <= 0 then
			scheduler:unscheduleScriptEntry(self.m_scheduler_addMultipleRandom)
			self.m_scheduler_addMultipleRandom = nil
			--设置最终倍数
			local nom0 = cmd_gameend.cbAddedMultiple
			local nom1 = cmd_gameend.cbAddedMultiple + 24
			if nom0 < 10 then
				nom0 = "0"..nom0
			end
			self:setChipString(ENUM_CHIPNUM.NUM_NORMALSHARK_RANDOM, nom0)
			self:setChipString(ENUM_CHIPNUM.NUM_NORMALSHARK_END, nom1)
			self.m_atlasLabels[ENUM_CHIPNUM.NUM_NORMALSHARK_END]:setVisible(true)
			--额外旋转
			endIndex = cmd_gameend.cbTableCardArray[2][1]
			self:otherCircleRun(endIndex,cmd_gameend,false)
		end
	end


	--动画判断
	if self.m_circleRunTimes == 2 then
		normalSharkNode:setVisible(true)
		self.m_atlasLabels[ENUM_CHIPNUM.NUM_NORMALSHARK_END]:setVisible(false)
		if self.m_scheduler_addMultipleRandom == nil then
			self.m_scheduler_addMultipleRandom = scheduler:scheduleScriptFunc(actOfMultiple, CHIPPOOL_BLINK_SPEED, false)
		end

		self.m_circleRunTimes = self.m_circleRunTimes - 1
		return
	elseif self.m_circleRunTimes == 1 then
		normalShark_img:setVisible(true)
		endIndex = cmd_gameend.cbTableCardArray[2][1]
    	otherAnimal = cc.Sprite:createWithTexture(
    		self.histroyTexture, 
    		cc.rect(self:chargeAnimalKind(endIndex) * 51, 0, 51, 41)
    		);
		normalShark_animalNode:addChild(otherAnimal)
		self:setChipString(ENUM_CHIPNUM.NUM_NORMALSHARK_OTHER, self:chargeAnimalMultiple(endIndex))
		--最后一次设置本剧得分的位置
		local thisRound = self.m_csbNode:getChildByName("panel_this_round")
		thisRound:setPositionY(THISROUND_POSY.normalShark)
		thisRound:setLocalZOrder(200)
        --显示最后得分
        self:setGameEndScore(cmd_gameend)
	elseif self.m_circleRunTimes <= 0 or self.m_circleRunTimes == nil then
		return
	end
	
end
--显示普通动物面板
function GameViewLayer:showNormalAnimalLayer(cmd_gameend)
	local endIndex = cmd_gameend.cbTableCardArray[1][1]
	local beginNode = self.m_sprAnimalCircle[endIndex]:getParent()
	local endNode = self.m_csbNode:getChildByName("panel_history")
	
	if self.m_normalAnimalSpr == nil then
		self.m_normalAnimalSpr = cc.Sprite:createWithTexture(
    		self.roundEndTexture, 
    		cc.rect(self:chargeAnimalKind(endIndex) * 229, 0, 229, 135)
    		):setPosition(beginNode:getPosition())
		self.m_normalAnimalSpr:setScale(0.4)
		self.m_csbNode:addChild(self.m_normalAnimalSpr)
		--普通动物动画
		--self.m_normalAnimalSpr:runAction(cc.Spawn:create(
		--	cc.ScaleTo:create(0.5, 1),
		--	cc.MoveTo:create(0.5,cc.p(endNode:getPositionX(),endNode:getPositionY()+150))
		--	)
		--)
		--self.m_normalAnimalSpr:runAction(cc.Sequence:create(
		--	cc.MoveTo:create(0.5,cc.p(endNode:getPositionX(),endNode:getPositionY()+150)),
		--	cc.ScaleTo:create(0.5, 1)
		--	)
		--)

		self.m_normalAnimalSpr:runAction(
			cc.Sequence:create(
				cc.MoveTo:create(0.5,cc.p(endNode:getPositionX(),endNode:getPositionY()+150)),
				cc.CallFunc:create(
					function()
						self.m_normalAnimalSpr:runAction(
							cc.RepeatForever:create(cc.Sequence:create(cc.ScaleTo:create(1,1.2),cc.ScaleTo:create(1,1)))
						)
					end
				)
			)
		)
		
    --设置本局得分的位置
	local thisRound = self.m_csbNode:getChildByName("panel_this_round")
	thisRound:setPositionY(THISROUND_POSY.normalAnimal)
	thisRound:setLocalZOrder(1)
    
    self:setGameEndScore(cmd_gameend)
	end

end
--设置菜单页面显示
function GameViewLayer:setMenuLayerVisible()
	local menulayer = self.m_csbNode:getChildByName("button_allmenubg")
	if menulayer:getScaleY() == 0 then
		menulayer:runAction(cc.ScaleTo:create(0.2, 1,1))
	elseif menulayer:getScaleY() == 1 then
		menulayer:runAction(cc.ScaleTo:create(0.2, 1,0))
	end
end

--设置筹码
function GameViewLayer:setChipString( theEnumChipNum, theNumStr)
	if "number" == type(theNumStr) and theNumStr < 0 then
		theNumStr = "."..(theNumStr * -1)
	end
	self.m_atlasLabels[theEnumChipNum]:setString(theNumStr);
end

--重置筹码数量（动物的筹码和本局得分的筹码设置）
function GameViewLayer:reSetChipString()
	--动物
	for i=ENUM_CHIPNUM.NUM_BIRE_ALL,ENUM_CHIPNUM.NUM_TUZI_SELF do
		self:setChipString(i,0)
	end
	--本局得分
	self:setChipString(ENUM_CHIPNUM.NUM_THISROUNDCHIP,0)
end

--获取以已下筹码数值
function GameViewLayer:getChipNum(theEnumChipNum)
	local numstr = self.m_atlasLabels[theEnumChipNum]:getString()
	return tonumber(numstr)
end

--初始化庄家信息
function GameViewLayer:initBankerInfo( ... )
	local banker_bg = self.m_spBankerBg;
	--庄家姓名
	local tmp = banker_bg:getChildByName("name_text");
	self.m_clipBankerNick = g_var(ClipText):createClipText(tmp:getContentSize(), "");
	self.m_clipBankerNick:setAnchorPoint(tmp:getAnchorPoint());
	self.m_clipBankerNick:setPosition(tmp:getPosition());
	banker_bg:addChild(self.m_clipBankerNick);

	--庄家金币
	self.m_textBankerCoin = banker_bg:getChildByName("bankercoin_text");

	self:reSetBankerInfo();
end

--设置下注数量按钮不可用
function GameViewLayer:setChipBtnEnabledExceptBtn(tag)
	if tag < ENUM_BTN.BT_100 or tag > ENUM_BTN.BT_100W then
		return
	end
    local btn
	for i = ENUM_BTN.BT_100,ENUM_BTN.BT_100W do
        btn = self.m_operateBtn[i];
        --if self:getBetButtonScore(i) <= GlobalUserItem.lUserScore then
        if self:getBetButtonScore(i) <= self:getChipNum(ENUM_CHIPNUM.NUM_MYCHIP) then
            btn:setEnabled(true)
            btn:setColor(cc.c3b(255,255,255))
        end
	end
    btn = self.m_operateBtn[tag];
	btn:setEnabled(false)
    btn:setColor(cc.c3b(255,216,0))
end

function GameViewLayer:checkChipButton(curJetton)
    for i = ENUM_BTN.BT_100, ENUM_BTN.BT_100W do
        if self:getBetButtonScore(i) > self:getChipNum(ENUM_CHIPNUM.NUM_MYCHIP) then
            self.m_operateBtn[i]:setEnabled(false)
            self.m_operateBtn[i]:setColor(cc.c3b(255, 255, 255))
            --当期选择不满足则清空选择
            if self:getBetButtonScore(i) == curJetton then
                print("11111 i = " .. i)
                self.m_jettonNum = nil
            end
        else
            if self:getBetButtonScore(i) == curJetton then
                self.m_operateBtn[i]:setEnabled(false)
                self.m_operateBtn[i]:setColor(cc.c3b(255,216,0))
            else
                self.m_operateBtn[i]:setEnabled(true)
                self.m_operateBtn[i]:setColor(cc.c3b(255, 255, 255))
            end
        end
    end
end

function GameViewLayer:onButtonClickedEvent(tag,ref)
	ExternalFun.playClickEffect()
	--退出游戏
	if tag == ENUM_BTN.BT_BACK then
		self:setMenuLayerVisible()
		self:getParentNode():onQueryExitGame()
	--显示菜单层
	elseif tag == ENUM_BTN.BT_MENU then
		self:setMenuLayerVisible()
	--注数选择
	elseif tag == ENUM_BTN.BT_100 then
		self.m_jettonNum = 100
		self:setChipBtnEnabledExceptBtn(tag)
	elseif tag == ENUM_BTN.BT_1K then
		self.m_jettonNum = 1000
		self:setChipBtnEnabledExceptBtn(tag)
	elseif tag == ENUM_BTN.BT_1W then
		self.m_jettonNum = 10000
		self:setChipBtnEnabledExceptBtn(tag)
	elseif tag == ENUM_BTN.BT_10W then
		self.m_jettonNum = 100000
		self:setChipBtnEnabledExceptBtn(tag)
	elseif tag == ENUM_BTN.BT_100W then
		self.m_jettonNum = 1000000
		self:setChipBtnEnabledExceptBtn(tag)
	elseif tag == ENUM_BTN.BT_BANK then
		self:setMenuLayerVisible()
		--银行未开通
		if 0 == GlobalUserItem.cbInsureEnabled then
			showToast(self,"初次使用，请先开通银行！",1)
			return
		end

		if nil == self.m_cbGameStatus or g_var(cmd).GAME_PLAY == self.m_cbGameStatus then
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
	elseif tag == TAG_ENUM.BT_CLOSEBANK then
		if nil ~= self.m_bankLayer then
			self.m_bankLayer:setVisible(false)
		end
	elseif tag == TAG_ENUM.BT_TAKESCORE then
		self:onTakeScore()
	elseif tag >= ENUM_BTN.BT_BIRD and tag <= ENUM_BTN.BT_TUZI then
		if self.m_jettonNum == nil or self.m_jettonNum < 0 then
			showToast(self,"请选择下注金额",1)
			return
		end

		if self:getChipNum(ENUM_CHIPNUM.NUM_BIRE_ALL + (tag - ENUM_BTN.BT_BIRD) * 2) + self.m_jettonNum > self.m_lAreaLimitScore then
			showToast(self,"已超过最大下注限额",1)
			return
		end
		--发送下注信息
        if self:getChipNum(ENUM_CHIPNUM.NUM_MYCHIP) - self.m_jettonNum >= 0 then
            self:getParentNode():sendUserBet(tag - ENUM_BTN.BT_BIRD + 1, self.m_jettonNum,false);
            print("发送下注消息...")
            --客户端下注显示
		    self:onGameBetOnGameView(tag, self.m_jettonNum , false)
            --下注后检测当前筹码是否足够
            self:checkChipButton(self.m_jettonNum)
        else
            showToast(self,"金额不足，无法下注",1)
        end
	elseif tag == ENUM_BTN.BT_CLEAR then
		--发送清空下注信息
		for i=ENUM_BTN.BT_BIRD,ENUM_BTN.BT_TUZI do
			if self.m_lastChips[i] ~= 0 then
				--发送清空信息
				self:getParentNode():sendUserBet(2, 100, true);
				--客户端下注显示
				self:onGameBetOnGameView(0, 0 , true)
                --
                self:checkChipButton(0)
                return
			end
		end
		--self:getParentNode():sendUserBet(0, 0, true);
	elseif tag == ENUM_BTN.BT_GOON then
		--发送下注信息
		for i=ENUM_BTN.BT_BIRD,ENUM_BTN.BT_TUZI do
			if self.m_lastRoundChips[i] ~= 0 then
                if self:getChipNum(ENUM_CHIPNUM.NUM_MYCHIP) - self.m_lastRoundChips[i] >= 0 then
				    --发送下注信息
				    self:getParentNode():sendUserBet(i - ENUM_BTN.BT_BIRD + 1, self.m_lastRoundChips[i], false);
				    --客户端下注显示
				    self:onGameBetOnGameView(i, self.m_lastRoundChips[i] , false)
				    print("i:"..i.."  m_lastRoundChips["..i.."]:"..self.m_lastRoundChips[i])
                    --下注后检测当前筹码是否足够
                    self:checkChipButton(self.m_lastRoundChips[i])
                else
                   showToast(self,"金额不足，请选择下注金额",1)
--                   print("余额不足，不能下注....")
                end
			end
		end

	elseif tag == ENUM_BTN.BT_SETTING then
		--设置
		local setting = g_var(SettingLayer):create()
		self:addToRootLayer(setting, TAG_ZORDER.SETTING_ZORDER)
	elseif tag == TAG_ENUM.BT_USERLIST then
		if nil == self.m_userListLayer then
			self.m_userListLayer = g_var(UserListLayer):create()
			self:addToRootLayer(self.m_userListLayer, TAG_ZORDER.USERLIST_ZORDER)
		end
		local userList = self:getDataMgr():getUserList()		
		self.m_userListLayer:refreshList(userList)
	else
		showToast(self,"功能尚未开放！",1)
	end
end
----初始化玩家信息
--function GameViewLayer:initUserInfo(  )	
--	--玩家头像
--	--local tmp = self.m_spBottom:getChildByName("player_head")
--	local head = g_var(PopupInfoHead):createClipHead(self:getMeUserItem(), tmp:getContentSize().width)
--	head:setPosition(tmp:getPosition())
--	self.m_spBottom:addChild(head)
--	head:enableInfoPop(true)

--	--玩家金币
--	self.m_textUserCoint = self.m_spBottom:getChildByName("coin_text")

--	self:reSetUserInfo()
--end

function GameViewLayer:reSetUserInfo(  )
	self.m_scoreUser = 0
	local myUser = self:getMeUserItem()
	if nil ~= myUser then
		self.m_scoreUser = myUser.lScore;
	end	
	print("自己金币:" .. ExternalFun.formatScore(self.m_scoreUser))
	local str = ExternalFun.numberThousands(self.m_scoreUser);
	if string.len(str) > 11 then
		str = string.sub(str,1,11) .. "...";
	end
	--self.m_textUserCoint:setString(str);
end

function GameViewLayer:onResetView()
	self:stopAllActions()
	self:gameDataReset()
	self:SetCircleRunInFree(false)
	self:stopTimer()
	--self:setChipPoolRandomRun(false)
end

function GameViewLayer:onExit()
	self:onResetView()
end

function GameViewLayer:showPopWait( )
	self:getParentNode():showPopWait()
end

function GameViewLayer:dismissPopWait( )
	self:getParentNode():dismissPopWait()
end

--初始化动物光圈
function GameViewLayer:collectCircle(csbNode)
	local circleTexture = cc.Director:getInstance():getTextureCache():addImage("sharkwanimal/circle_select.png");

	--获取动物信息
	local sprAnimal = {}
	sprAnimal[0] = csbNode:getChildByName("circle_gold_shark")
	sprAnimal[1] = csbNode:getChildByName("circle_swallow_0")
	sprAnimal[2] = csbNode:getChildByName("circle_swallow_1")
	sprAnimal[3] = csbNode:getChildByName("circle_swallow_2")
	sprAnimal[4] = csbNode:getChildByName("circle_pigon_0")
	sprAnimal[5] = csbNode:getChildByName("circle_pigon_1")
	sprAnimal[6] = csbNode:getChildByName("circle_pigon_2")
	sprAnimal[7] = csbNode:getChildByName("circle_win")
	sprAnimal[8] = csbNode:getChildByName("circle_peacock_0")
	sprAnimal[9] = csbNode:getChildByName("circle_peacock_1")
	sprAnimal[10] = csbNode:getChildByName("circle_peacock_2")
	sprAnimal[11] = csbNode:getChildByName("circle_eagle_0")
	sprAnimal[12] = csbNode:getChildByName("circle_eagle_1")
	sprAnimal[13] = csbNode:getChildByName("circle_eagle_2")
	sprAnimal[14] = csbNode:getChildByName("circle_shark")
	sprAnimal[15] = csbNode:getChildByName("circle_lion_0")
	sprAnimal[16] = csbNode:getChildByName("circle_lion_1")
	sprAnimal[17] = csbNode:getChildByName("circle_lion_2")
	sprAnimal[18] = csbNode:getChildByName("circle_panda_0")
	sprAnimal[19] = csbNode:getChildByName("circle_panda_1")
	sprAnimal[20] = csbNode:getChildByName("circle_panda_2")
	sprAnimal[21] = csbNode:getChildByName("circle_lose")
	sprAnimal[22] = csbNode:getChildByName("circle_monkey_0")
	sprAnimal[23] = csbNode:getChildByName("circle_monkey_1")
	sprAnimal[24] = csbNode:getChildByName("circle_monkey_2")
	sprAnimal[25] = csbNode:getChildByName("circle_rabbit_0")
	sprAnimal[26] = csbNode:getChildByName("circle_rabbit_1")
	sprAnimal[27] = csbNode:getChildByName("circle_rabbit_2")
	--添加动物光圈
	local sprAnimalCircle = {}
	for k,v in pairs(sprAnimal) do
		local spr = cc.Sprite:createWithTexture(circleTexture)
		spr:setAnchorPoint(cc.p(0,0))
		v:addChild(spr)
		sprAnimalCircle[k] = spr
		spr:setOpacity(0)
	end
	self.m_sprAnimalCircle = sprAnimalCircle
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
        print("bwa========"..self._searchPath)
    end

    --播放背景音乐
    ExternalFun.playBackgroudAudio("free.mp3")
    
    --用户列表
	self:getDataMgr():initUserList(self:getParentNode():getUserList())

    --enum
    self.ENUM_CHIPNUM = ENUM_CHIPNUM
    self.ENUM_BTN = ENUM_BTN
    self.ENUM_OTHERANIMALSPR = ENUM_OTHERANIMALSPR
    --玩家下注选择
    self.m_jettonNum = nil
    --用户累计得分
    self.m_totleChipsNum = 0
    --用户列表
	self:getDataMgr():initUserList(self:getParentNode():getUserList())
	--彩金池备份
	self.m_GamePondCopy = 0


    ----------------------------------------------------------------------------以下数据待筛选
	--变量声明
	self.m_nJettonSelect = -1
	self.m_lHaveJetton = 0;
	self.m_llMaxJetton = 0;
	self.m_llCondition = 0;
	yl.m_bDynamicJoin = false;
	self.m_scoreUser = self:getMeUserItem().lScore or 0

	--下注信息
	self.m_tableJettonBtn = {};
	self.m_tableJettonArea = {};

	--下注提示
	self.m_tableJettonNode = {};

	self.m_applyListLayer = nil
	self.m_userListLayer = nil
	self.m_wallBill = nil
	self.m_cardLayer = nil
	self.m_gameResultLayer = nil
	self.m_pClock = nil
	self.m_bankLayer = nil

	--申请状态
	--self.m_enApplyState = APPLY_STATE.kCancelState
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
	cc.Director:getInstance():getTextureCache():removeTextureForKey("sharkwanimal/idb_niu_.png")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("sharkwanimal/tongji_dw_da.png")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("sharkwanimal/circle_select.png")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("sharkwanimal/select_animal_type.png");
	cc.Director:getInstance():getTextureCache():removeTextureForKey("sharkwanimal/select_shark.png");
	cc.Director:getInstance():getTextureCache():removeTextureForKey("sharkwanimal/select_animal_name.png");
	
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("bank/bank.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("bank/bank.png")

	--特殊处理public_res blank.png 冲突
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


	--播放大厅背景音乐
	--ExternalFun.playPlazzBackgroudAudio()

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

---------------------------------------blink动画---------------------------------------------
--空闲状态下的动物光圈动画(随机闪动)
function GameViewLayer:SetCircleRunInFree(run)
	local function randBlink(dt)
		self.m_lastIndex = math.random(0,27)
		self.m_sprAnimalCircle[self.m_lastIndex]:runAction(cc.Sequence:create(cc.FadeIn:create(0),cc.FadeOut:create(DISMIS_SPEED)))
	end
	--重置定时器
	if nil ~= self.m_scheduler_randomBlink then
		scheduler:unscheduleScriptEntry(self.m_scheduler_randomBlink)
		self.m_scheduler_randomBlink = nil
	end	
	--开始动画或返回最后闪动的index
	if run == true then
		self.m_lastIndex = 0
		self.m_scheduler_randomBlink = scheduler:scheduleScriptFunc(randBlink, BLINK_SPEED_RANDOM, false)
	else
		return self.m_lastIndex
	end	
end

--判断需要旋转次数 每轮游戏仅调用一次
function GameViewLayer:chargeCircleRunTimes( cmd_gameend )
	local endIndex = cmd_gameend.cbTableCardArray[1][1]
	--数据清空
	self.m_circleRunTimes = 0
	--判断旋转回合数
	if endIndex == 0 then --金鲨鱼
		self.m_circleRunTimes = 4
	elseif endIndex == 14 then --普通鲨鱼
		self.m_circleRunTimes = 2
	else
		self.m_circleRunTimes = 1
	end
end
--旋转状态下的动物光圈动画(按照既定位置)
function GameViewLayer:SetCircleRunWithEndIndex(cmd_gameend)
	local endIndex = cmd_gameend.cbTableCardArray[1][1]
	local returnIndex = self:SetCircleRunInFree(false)
	local lastIndex = returnIndex + 1 
	local maxDelay = 0.6 --最大间隔时间
	local minDelay = 0.01 --最小间隔时间

	local delayTime = maxDelay --间隔时间
	local preTime = 0.1 --每次的加减时间
	local runTimes = 0  --运行次数
	local timesFromMinToMax = 0 --从最快到最慢需要的次数

	local maxDelay_back = maxDelay
	while (maxDelay_back - minDelay) > 0 do
		maxDelay_back = maxDelay_back - preTime
		timesFromMinToMax = timesFromMinToMax + 1  
	end


	print("-1-----endIndex:"..endIndex)
	local runFromMaxToMin = 0 --0递减 1不变 2递增

	local function circleRun(dt)
		if lastIndex > 27 then
			lastIndex = 0
		end

		if self.m_sprAnimalCircle == nil then
			return
		end

		self.m_sprAnimalCircle[lastIndex]:runAction(cc.Sequence:create(cc.FadeIn:create(0),cc.FadeOut:create(DISMIS_SPEED)))
		scheduler:unscheduleScriptEntry(self.m_scheduler_animalCircle)

		--结束旋转
		if lastIndex == endIndex and runFromMaxToMin == 2 then 
			--判断种类
			self:preInsertBtnCircleToArry(lastIndex)
			--判断动物
			self:insertAnimalCircleToArry(lastIndex)
			--插入历史记录
			self:insertHistroy(self:chargeAnimalKind(lastIndex))
			--播放音乐
            self:playSoundAnimal(lastIndex)
			--开始闪动
			self:SetCircleBlink(true)
			--其他情况处理
			if endIndex == 0 then --金鲨鱼
				self:showGoldSharkLayer(cmd_gameend)
			elseif endIndex == 14 then --普通鲨鱼
				self:showNormalSharkLayer(cmd_gameend)
			else --普通情况
				self:showNormalAnimalLayer(cmd_gameend)
			end
			return
		end

		--数据操作
		runTimes = runTimes + 1
		lastIndex = lastIndex + 1

		if runFromMaxToMin == 0 then --加速
			delayTime = delayTime - preTime
			
			if delayTime <= minDelay then
				delayTime = minDelay
				runFromMaxToMin = 1
			end
			--print("0-----delayTime:"..delayTime)
		elseif runFromMaxToMin == 1 and runTimes >= 28*4 then --匀速结束
			local toIndex = lastIndex + timesFromMinToMax

			if toIndex > 27 then
				toIndex = toIndex - 28
			end
			print("1-----toIndex:"..toIndex.."   endindex:"..endIndex)
			if toIndex == endIndex then
				runFromMaxToMin = 2
			end
		elseif runFromMaxToMin == 2 then --减速
			delayTime = delayTime + preTime
			if delayTime >= maxDelay then
				delayTime = maxDelay
			end
			--print("2-----delayTime:"..delayTime)
		end
        ExternalFun.playSoundEffect("run.WAV")
		self.m_scheduler_animalCircle = scheduler:scheduleScriptFunc(circleRun, delayTime, false)
	end

	self.m_scheduler_animalCircle = scheduler:scheduleScriptFunc(circleRun, delayTime, false)
end

--额外旋转
function GameViewLayer:otherCircleRun(endIndex,cmd_gameend,isGoldShark)
	local delayTime = 0.01
	local lastIndex = nil
	if isGoldShark == true then
		lastIndex = 0
	else
		lastIndex = 14
	end

	--回调函数
	local function circleRun(dt)
		if lastIndex > 27 then
			lastIndex = 0
		end

		if self.m_sprAnimalCircle == nil then
			return
		end

		self.m_sprAnimalCircle[lastIndex]:runAction(cc.Sequence:create(cc.FadeIn:create(0),cc.FadeOut:create(DISMIS_SPEED)))
		scheduler:unscheduleScriptEntry(self.m_scheduler_animalCircle)

        
        ExternalFun.playSoundEffect("run.WAV")
		--print("lastIndex:"..lastIndex.."    endIndex:"..endIndex)
		--结束旋转
		if lastIndex == endIndex then 
			--判断种类
			self:preInsertBtnCircleToArry(lastIndex)
			--播放音乐
            self:playSoundAnimal(lastIndex)
			--判断动物
			self:insertAnimalCircleToArry(lastIndex)
			--插入历史记录
			self:insertHistroy(self:chargeAnimalKind(lastIndex))
			--开始闪动
			self:SetCircleBlink(true)
			--其他情况处理
			if isGoldShark == true then --金鲨鱼
				self:showGoldSharkLayer(cmd_gameend)
			else --普通鲨鱼
				self:showNormalSharkLayer(cmd_gameend)
			end
			return
		end
		lastIndex = lastIndex + 1
		self.m_scheduler_animalCircle = scheduler:scheduleScriptFunc(circleRun, delayTime, false)
	end
	--开始旋转
	self.m_scheduler_animalCircle = scheduler:scheduleScriptFunc(circleRun, delayTime + DELAY_TWOCIRCLE, false)
end
--光圈闪动
function GameViewLayer:SetCircleBlink(run)
	if run == false then
		--重置定时器
		if nil ~= self.m_scheduler_btnCircleBlink then
			scheduler:unscheduleScriptEntry(self.m_scheduler_btnCircleBlink)
			self.m_scheduler_btnCircleBlink = nil
		end	
		--重置光圈
		for k,v in pairs(self.m_animalBtnCircle) do
			v:setOpacity(0)
		end
		for k,v in pairs(self.m_sprAnimalCircle) do
			v:setOpacity(0)
		end
		--重置光圈数组
		self:reSetCircleArry()
		return
	end


	local function randBlink(dt)
		local blinkOpacity = 0
		if self.m_blinkCtr == true then
			blinkOpacity = 255
		else
			blinkOpacity = 0
		end

		if self.m_btnCircleArry == nil or self.m_animalCircleArry == nil then
			return
		end

		for k,v in pairs(self.m_btnCircleArry) do
			--print("----v:"..v)
			self.m_animalBtnCircle[v]:stopAllActions()
			self.m_animalBtnCircle[v]:setOpacity(blinkOpacity)
		end

		for k,v in pairs(self.m_animalCircleArry) do
			self.m_sprAnimalCircle[v]:stopAllActions()
			self.m_sprAnimalCircle[v]:setOpacity(blinkOpacity)
		end
		self.m_blinkCtr = not self.m_blinkCtr
	end
	if run == true then
		if self.m_scheduler_btnCircleBlink == nil then
			self.m_blinkCtr = true
			self.m_scheduler_btnCircleBlink = scheduler:scheduleScriptFunc(randBlink, BLINK_SPEED_RESULT, false)
		end	
	end	
end
--彩金池数字随机闪动
function GameViewLayer:setChipPoolRandomRun( run  )
	if run == false then
		--重置定时器
		if nil ~= self.m_scheduler_chipPoolRandom then
			scheduler:unscheduleScriptEntry(self.m_scheduler_chipPoolRandom)
			self.m_scheduler_chipPoolRandom = nil
		end	
		--重置彩金池数据
		self:setChipString(ENUM_CHIPNUM.NUM_CHIPPOOl, self.m_GamePondCopy)
		return
	end

	if self.m_GamePondCopy == 0 then
		self.m_GamePondCopy = 8000000000
	end

	local function randBlink(dt)
		chipnum = math.random(self.m_GamePondCopy - self.m_GamePondCopy / 2 , self.m_GamePondCopy + self.m_GamePondCopy / 2)
		self:setChipString(ENUM_CHIPNUM.NUM_CHIPPOOl, chipnum)
	end
	if run == true then
		if self.m_scheduler_chipPoolRandom == nil then
			self.m_scheduler_chipPoolRandom = scheduler:scheduleScriptFunc(randBlink, CHIPPOOL_BLINK_SPEED, false)
		end	
	end	
end

--预插入动物按钮
function GameViewLayer:preInsertBtnCircleToArry( index )
	print("--------------------------------------------------------")
	if index == 1 or index == 2 or index == 3 then
		self:insertBtnCircleToArry(ENUM_BTN.BT_YANZI)
		self:insertBtnCircleToArry(ENUM_BTN.BT_BIRD)
	elseif index == 4 or index == 5 or index == 6 then
		self:insertBtnCircleToArry(ENUM_BTN.BT_GEZI)
		self:insertBtnCircleToArry(ENUM_BTN.BT_BIRD)
	elseif index == 8 or index == 9 or index == 10 then
		self:insertBtnCircleToArry(ENUM_BTN.BT_KONGQUE)
		self:insertBtnCircleToArry(ENUM_BTN.BT_BIRD)
	elseif index == 11 or index == 12 or index == 13 then
		self:insertBtnCircleToArry(ENUM_BTN.BT_LAOYING)
		self:insertBtnCircleToArry(ENUM_BTN.BT_BIRD)
	elseif index == 15 or index == 16 or index == 17 then
		self:insertBtnCircleToArry(ENUM_BTN.BT_SHIZI)
		self:insertBtnCircleToArry(ENUM_BTN.BT_ANIMAL)
	elseif index == 18 or index == 19 or index == 20 then
		self:insertBtnCircleToArry(ENUM_BTN.BT_XIONGMAO)
		self:insertBtnCircleToArry(ENUM_BTN.BT_ANIMAL)
	elseif index == 22 or index == 23 or index == 24 then
		self:insertBtnCircleToArry(ENUM_BTN.BT_HOUZI)
		self:insertBtnCircleToArry(ENUM_BTN.BT_ANIMAL)
	elseif index == 25 or index == 26 or index == 27 then
		self:insertBtnCircleToArry(ENUM_BTN.BT_TUZI)
		self:insertBtnCircleToArry(ENUM_BTN.BT_ANIMAL)
	elseif index == 0 or index == 7 or index == 14 or index == 21 then
		if index == 0 then--金鲨鱼不添加
			--todo
		elseif index == 7 then--通杀不添加
			--todo
		elseif index == 14 then--普通鲨鱼
			self:insertBtnCircleToArry(ENUM_BTN.BT_SHARK)
		elseif index == 21 then--通赔全添加
			for i=ENUM_BTN.BT_BIRD,ENUM_BTN.BT_TUZI do
				self:insertBtnCircleToArry(i)
			end
		end
		
	end
end
--判断动物种类
function GameViewLayer:chargeAnimalKind( index )
	if index == 1 or index == 2 or index == 3 then
		return 0
	elseif index == 4 or index == 5 or index == 6 then
		return 1
	elseif index == 8 or index == 9 or index == 10 then
		return 2
	elseif index == 11 or index == 12 or index == 13 then
		return 3
	elseif index == 15 or index == 16 or index == 17 then
		return 4
	elseif index == 18 or index == 19 or index == 20 then
		return 5
	elseif index == 22 or index == 23 or index == 24 then
		return 6
	elseif index == 25 or index == 26 or index == 27 then
		return 7
	elseif index == 0 or index == 7 or index == 14 or index == 21 then
		if index == 0 then--金鲨鱼不添加
			return 11
		elseif index == 7 then--通杀不添加
			return 10
		elseif index == 14 then--普通鲨鱼
			return 8
		elseif index == 21 then--通赔全添加
			return 9
		end
		
	end
end
--判断动物倍数
function GameViewLayer:chargeAnimalMultiple(index)
	if index == 1 or index == 2 or index == 3 then
		return 6
	elseif index == 4 or index == 5 or index == 6 then
		return 8
	elseif index == 8 or index == 9 or index == 10 then
		return 8
	elseif index == 11 or index == 12 or index == 13 then
		return 12
	elseif index == 15 or index == 16 or index == 17 then
		return 12
	elseif index == 18 or index == 19 or index == 20 then
		return 8
	elseif index == 22 or index == 23 or index == 24 then
		return 8
	elseif index == 25 or index == 26 or index == 27 then
		return 6
	elseif index == 0 or index == 7 or index == 14 or index == 21 then
		return 0
	end
end

--判断动物倍数
function GameViewLayer:playSoundAnimal(index)
	if index == 1 or index == 2 or index == 3 then
		ExternalFun.playSoundEffect("___yz_fq.mp3")
	elseif index == 4 or index == 5 or index == 6 then
		ExternalFun.playSoundEffect("___gz_fq.mp3")
	elseif index == 8 or index == 9 or index == 10 then
		ExternalFun.playSoundEffect("___kq_fq.mp3")
	elseif index == 11 or index == 12 or index == 13 then
		ExternalFun.playSoundEffect("___ly_fq.mp3")
	elseif index == 15 or index == 16 or index == 17 then
		ExternalFun.playSoundEffect("___sz_zs.mp3")
	elseif index == 18 or index == 19 or index == 20 then
		ExternalFun.playSoundEffect("___xm_zs.mp3")
	elseif index == 22 or index == 23 or index == 24 then
		ExternalFun.playSoundEffect("___hz_zs.mp3")
	elseif index == 25 or index == 26 or index == 27 then
		ExternalFun.playSoundEffect("___tz_zs.mp3")
	elseif index == 0  then
		ExternalFun.playSoundEffect("___jsy.mp3")
	elseif index == 7 then
		ExternalFun.playSoundEffect("___ts.mp3")
	elseif index == 14 then
		ExternalFun.playSoundEffect("___ysy.mp3")
	elseif index == 21 then
		ExternalFun.playSoundEffect("___tp.mp3")
	end
end
--添加对象的table:m_btnCircleArry
function GameViewLayer:insertBtnCircleToArry(tagOrEnum)
	self.m_btnCircleArry[tagOrEnum] = tagOrEnum
end

--添加对象的table:m_animalCircleArry
function GameViewLayer:insertAnimalCircleToArry(index)
	self.m_animalCircleArry[index] = index
end
--重置按钮光圈数组m_btnCircleArry
function GameViewLayer:reSetCircleArry()
	--停止按钮光圈闪动
	if self.m_scheduler_btnCircleBlink ~= nil then
		scheduler:unscheduleScriptEntry(self.m_scheduler_btnCircleBlink)
		self.m_scheduler_btnCircleBlink = nil
	end
	self.m_btnCircleArry = {}
	self.m_animalCircleArry = {}
end
--初始化定时器
function GameViewLayer:initTimer(csbNode)
	self.m_sprFreeTimer = csbNode:getChildByName("panel_free_time")
	self.m_sprPlayTimer = csbNode:getChildByName("panel_bet_time");
	self.m_sprAwardTimer = csbNode:getChildByName("panel_award_time");
	self.m_sprFreeTimer:setVisible(false);
	self.m_sprPlayTimer:setVisible(false);
	self.m_sprAwardTimer:setVisible(false);
	self.m_atlasLabels[ENUM_CHIPNUM.NUM_TIME]:setVisible(false);
end
--设置自己金币
function GameViewLayer:setSelfScore(score)
    print("setSelfScore score = "..score)
	self.m_atlasLabels[ENUM_CHIPNUM.NUM_MYCHIP]:setString(score);
end
--设置彩金池
function GameViewLayer:setChipPool(score)
	if "number" == type(score) and score < 0 then
		score = "."..(score * -1)
	end
	--print("setChipPool(score):"..score)
	self.m_atlasLabels[ENUM_CHIPNUM.NUM_CHIPPOOl]:setString(score);
end

function GameViewLayer:getBetButtonScore(name)
                if     name==ENUM_BTN.BT_100 then
                    return 100
                elseif name==ENUM_BTN.BT_1K then
                    return 1000
                elseif name==ENUM_BTN.BT_1W then
                    return 10000
                elseif name==ENUM_BTN.BT_10W then
                    return 100000
                elseif name==ENUM_BTN.BT_100W then
                    return 1000000
                end
                return 0
end

--设置下注按钮可用/不可用
function GameViewLayer:setAllChipButtonEnabled(canUse)

	for i = ENUM_BTN.BT_100, ENUM_BTN.BT_TUZI do
		self.m_operateBtn[i]:setEnabled(canUse)
        self.m_operateBtn[i]:setColor(cc.c3b(255,255,255))
	end
	--判断续投

    if canUse then

        for i = ENUM_BTN.BT_100, ENUM_BTN.BT_TUZI do
              if self:getBetButtonScore(i) > GlobalUserItem.lUserScore then
                    self.m_operateBtn[i]:setEnabled(false)
              end
        end

    end
end
--设置指定的下注按钮可用/不可用
function GameViewLayer:setChipButtonEnabled(tag,canUse)
		self.m_operateBtn[tag]:setEnabled(canUse)
end
function GameViewLayer:getMeUserItem(  )
	if nil ~= GlobalUserItem.dwUserID then
		return self:getDataMgr():getUidUserList()[GlobalUserItem.dwUserID];
	end
	return nil;
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
---------------------------------------------------------------------------------------



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

--    --坐下用户
--    for i = 1, g_var(cmd).MAX_OCCUPY_SEAT_COUNT do
--    	if nil ~= self.m_tabSitDownUser[i] then
--    		if item.wChairID == self.m_tabSitDownUser[i]:getChair() then
--    			self.m_tabSitDownUser[i]:updateScore(item)
--    		end
--    	end
--    end

--    --庄家
--    if self.m_wBankerUser == item.wChairID then
--    	--庄家金币
--		local str = string.formatNumberThousands(item.lScore);
--		if string.len(str) > 11 then
--			str = string.sub(str, 1, 9) .. "...";
--		end
--		self.m_textBankerCoin:setString("金币:" .. str);
--    end
end

function GameViewLayer:refreshCondition(  )
	local applyable = self:getApplyable()
	if applyable then
		------
		--超级抢庄

		--如果当前有超级抢庄用户且庄家不是自己
		if (yl.INVALID_CHAIR ~= self.m_wCurrentRobApply) or (true == self:isMeChair(self.m_wBankerUser)) then
			ExternalFun.enableBtn(self.m_btnRob, false)
		else
			local useritem = self:getMeUserItem()
			--判断抢庄类型
			if g_var(cmd).SUPERBANKER_VIPTYPE == self.m_tabSupperRobConfig.superbankerType then
				--vip类型				
				ExternalFun.enableBtn(self.m_btnRob, useritem.cbMemberOrder >= self.m_tabSupperRobConfig.enVipIndex)
			elseif g_var(cmd).SUPERBANKER_CONSUMETYPE == self.m_tabSupperRobConfig.superbankerType then
				--游戏币消耗类型(抢庄条件+抢庄消耗)
				local condition = self.m_tabSupperRobConfig.lSuperBankerConsume + self.m_llCondition
				ExternalFun.enableBtn(self.m_btnRob, useritem.lScore >= condition)
			end
		end		
	else
		ExternalFun.enableBtn(self.m_btnRob, false)
	end
end
--游戏结束
function GameViewLayer:onGameEnd( cmd_gameend )
	yl.m_bDynamicJoin = false
	print("========>  onGameEnd***********************wChairID="..self:getMeUserItem().wChairID);
	--设置按钮不可用
	self:setAllChipButtonEnabled(false);

	--保存上局的下注信息
	self.m_lastRoundChips = {}
	--self.m_lastRoundChips = self.m_lastChips

--    for k,v in pairs(self.m_lastRoundChips) do
--        print("k="..k..",v="..v);
--    end
   for i = ENUM_BTN.BT_BIRD,ENUM_BTN.BT_TUZI do
		self.m_lastRoundChips[i] = self.m_lastChips[i]
		self.m_lastChips[i] = 0
	end

	--彩金池数字随机闪动
	--self:setChipPoolRandomRun(false)
	-----
    --判断旋转次数
    self:chargeCircleRunTimes(cmd_gameend)
    --按指定信息转动
    self:SetCircleRunWithEndIndex(cmd_gameend)
    --选择注数设置为空
    self.m_jettonNum = nil
	--self:setGameEndScore(cmd_gameend)

    
	--播放音乐    
    ExternalFun.playBackgroudAudio("open.mp3")

end
--显示游戏得分
function GameViewLayer:setGameEndScore( cmd_gameend )

	--本剧得分
	self:setChipString(ENUM_CHIPNUM.NUM_THISROUNDCHIP, cmd_gameend.lUserScore)
	--保存累计成绩
	self.m_totleChipsNum = self.m_totleChipsNum + cmd_gameend.lUserScore
	--累计得分
	self:setChipString(ENUM_CHIPNUM.NUM_TOTLECHIP, self.m_totleChipsNum)

    if cmd_gameend.lUserScore>0 then
        ExternalFun.playSoundEffect("END_WIN.wav")
    elseif cmd_gameend.lUserScore<0 then
        ExternalFun.playSoundEffect("END_LOST.wav")
    else--if cmd_gameend.lUserScore==0 then    
        ExternalFun.playSoundEffect("END_DRAW.wav")
    end


end
--游戏下注（客户端界面）
function GameViewLayer:onGameBetOnGameView(enum,chips,isClear)
	local index = nil
	if isClear == true then
		--重置保存信息
		for i = ENUM_BTN.BT_BIRD,ENUM_BTN.BT_TUZI do
			self.m_lastChips[i] = 0
		end
		
		for k = ENUM_CHIPNUM.NUM_BIRE_SELF,ENUM_CHIPNUM.NUM_TUZI_SELF,2 do
			local v = self:getChipNum(k)
			if v ~= 0 then
				--所有下注金币
				index =  k -1
				self:setChipString(index, self:getChipNum(index) - v)
				--自己下注金币
				self:setChipString(k, 0)
				--自己金币
				self:setSelfScore(self:getChipNum(ENUM_CHIPNUM.NUM_MYCHIP) + v) 
			end
		end
	else 
--		--保存下注信息
--		self.m_lastChips[enum] = self.m_lastChips[enum] + chips
--		print("self.m_lastChips["..enum.."]111:"..self.m_lastChips[enum])
		--自己下注金币
		index = (enum - ENUM_BTN.BT_BIRD) * 2 + ENUM_CHIPNUM.NUM_BIRE_SELF
		self:setChipString(index, self:getChipNum(index) + chips)
		--所有下注金币
		index =  (enum - ENUM_BTN.BT_BIRD) * 2 + ENUM_CHIPNUM.NUM_BIRE_ALL
		self:setChipString(index, self:getChipNum(index) + chips)
		--自己金币
		self:setSelfScore(self:getChipNum(ENUM_CHIPNUM.NUM_MYCHIP) - chips)
	end
    
    ExternalFun.playSoundEffect("ADD_SCORE.wav") 
    
end
--游戏下注
function GameViewLayer:onGameBet( cmd_gamebet )
	local index = nil
	local meChairID = self:getMeUserItem().wChairID
	if cmd_gamebet.bClearUp == true then
		if meChairID == cmd_gamebet.wChairID then
			return
		end
		for i=2,12 do
			if cmd_gamebet.lUserJettonCleaUp[1][i] ~= 0 then
				index =  (i - 2) * 2 + ENUM_CHIPNUM.NUM_BIRE_ALL
				self:setChipString(index, self:getChipNum(index) - cmd_gamebet.lUserJettonCleaUp[1][i])
			end
		end	
	else 
		if meChairID == cmd_gamebet.wChairID then    
        	--保存下注信息
            index = (cmd_gamebet.cbJettonArea - 1) + ENUM_BTN.BT_BIRD
		    self.m_lastChips[index] = self.m_lastChips[index] + cmd_gamebet.lJettonScore   
			return
		end
		index =  (cmd_gamebet.cbJettonArea - 1) * 2 + ENUM_CHIPNUM.NUM_BIRE_ALL
		self:setChipString(index, self:getChipNum(index) + cmd_gamebet.lJettonScore)
	end   
end
--游戏下注失败
function GameViewLayer:onGameBetFail(cmd_gamejettonfail)
	local index = nil
	local meChairID = self:getMeUserItem().wChairID
	if meChairID == cmd_gamejettonfail.wPlaceUser then
        dump(cmd_gamejettonfail,"cmd_gamejettonfail")
		--自己下注金币
		index = (cmd_gamejettonfail.lJettonArea - 1) * 2 + ENUM_CHIPNUM.NUM_BIRE_SELF
		self:setChipString(index, self:getChipNum(index) - cmd_gamejettonfail.lPlaceScore)
		--自己金币
		self:setSelfScore(self:getChipNum(ENUM_CHIPNUM.NUM_MYCHIP) + cmd_gamejettonfail.lPlaceScore)
		--保存下注信息
--		index = (cmd_gamejettonfail.lJettonArea - 1) + ENUM_BTN.BT_BIRD
--		self.m_lastChips[index] = self.m_lastChips[index] - cmd_gamejettonfail.lPlaceScore
--		print("self.m_lastChips[index]222:"..self.m_lastChips[index])
	end
	index =  (cmd_gamejettonfail.lJettonArea - 1) * 2 + ENUM_CHIPNUM.NUM_BIRE_ALL
	self:setChipString(index, self:getChipNum(index) - cmd_gamejettonfail.lPlaceScore)
end

--游戏free
function GameViewLayer:onGameFree( )
	yl.m_bDynamicJoin = false
	print("========>  onGameFree")

	--设置按钮不可用
	self:setAllChipButtonEnabled(false);

	--关闭光圈闪动
	self:SetCircleBlink(false)

	--播放随机闪动动画
	self:SetCircleRunInFree(true)

	--隐藏鲨鱼面板
	self:reSetGoldSharkLayer()
	self:reSetNormalSharkLayer()
	--self.m_goldSharkNode:setVisible(false);		--金鲨鱼层
	--self.m_normalSharkNode:setVisible(false);	--银鲨鱼层

	--设置本剧得分的位置
	local thisRound = self.m_csbNode:getChildByName("panel_this_round")
	thisRound:setPositionY(-100)
	thisRound:setLocalZOrder(1)
	--移除普通动物
	if self.m_normalAnimalSpr ~= nil then
		self.m_normalAnimalSpr:stopAllActions()
		self.m_normalAnimalSpr:removeFromParent()
		self.m_normalAnimalSpr = nil
	end

	--清除下注信息
	self:reSetChipString();

	--更新自己信息
	--1.更新累计得分
	self:setChipString(ENUM_CHIPNUM.NUM_TOTLECHIP, self.m_totleChipsNum)
	--2.更新剩余资产
	--self:setChipString(ENUM_CHIPNUM.NUM_MYCHIP, self:getMeUserItem().lScore)    
    self:setSelfScore(self:getMeUserItem().lScore)
    
	print("================*****===========================================>  self:getMeUserItem().lScore"..self:getMeUserItem().lScore)
	--播放音乐    
    ExternalFun.playBackgroudAudio("free.mp3")
	
end

--游戏free 场景
function GameViewLayer:onGameSceneFree( )
	self:onGameFree()
end

--游戏下注 场景
function GameViewLayer:onGameSceneJetton( )
	--彩金池数字随机闪动
	--self:setChipPoolRandomRun(true)
	--设置按钮可用
	self:setAllChipButtonEnabled(true);
    
    --设置本局得分的位置
	local thisRound = self.m_csbNode:getChildByName("panel_this_round")
	thisRound:setPositionY(-100)
	thisRound:setLocalZOrder(5)

    self:setSelfScore(self:getMeUserItem().lScore)
    --self:setChipString(ENUM_CHIPNUM.NUM_MYCHIP, self:getMeUserItem().lScore)
end

--游戏结束 场景
function GameViewLayer:onGameSceneEnd( )
	--设置按钮不可用
	self:setAllChipButtonEnabled(false);

	--关闭光圈闪动
	self:SetCircleBlink(false)

	--播放随机闪动动画
	self:SetCircleRunInFree(true)

	--隐藏鲨鱼面板
	self:reSetGoldSharkLayer()
	self:reSetNormalSharkLayer()
	--self.m_goldSharkNode:setVisible(false);		--金鲨鱼层
	--self.m_normalSharkNode:setVisible(false);	--银鲨鱼层

	--设置本局得分的位置
	local thisRound = self.m_csbNode:getChildByName("panel_this_round")
	thisRound:setPositionY(THISROUND_POSY.normalAnimal)
	thisRound:setLocalZOrder(1)
		--移除普通动物
	if self.m_normalAnimalSpr ~= nil then
		self.m_normalAnimalSpr:stopAllActions()
		self.m_normalAnimalSpr:removeFromParent()
		self.m_normalAnimalSpr = nil
	end

	--更新自己信息
	--1.更新累计得分
	self:setChipString(ENUM_CHIPNUM.NUM_TOTLECHIP, self.m_totleChipsNum)
	--2.更新剩余资产
	--self:setChipString(ENUM_CHIPNUM.NUM_MYCHIP, self:getMeUserItem().lScore)    
    self:setSelfScore(self:getMeUserItem().lScore)
end

--游戏开始
function GameViewLayer:onGameStart( )
	print("========>  onGameStart")
        local chips = 0
		for i = ENUM_BTN.BT_BIRD,ENUM_BTN.BT_TUZI do
			chips = chips + self.m_lastRoundChips[i]
	end
    print("================*****=========****#########===============================>  chips"..chips)
	--设置按钮可用
	self:setAllChipButtonEnabled(true);

	--播放随机闪动动画
	self:SetCircleRunInFree(true)

end


--游戏记录
function GameViewLayer:insertHistroy( index )
	local histroyListView = self.m_csbNode:getChildByName("panel_history"):getChildByName("ListView")
	histroyListView:setScrollBarEnabled(false)
	--纹理区域
	local rect = cc.rect(index * 51, 0, 51, 41);
    local animalspr = cc.Sprite:createWithTexture(self.histroyTexture, rect);
    animalspr:setAnchorPoint(cc.p(0,0))
    local layout = ccui.Layout:create()
    layout:setContentSize(animalspr:getContentSize())
    layout:addChild(animalspr)
    histroyListView:insertCustomItem(layout,histroyListView:getChildrenCount());
    histroyListView:jumpToRight()
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


function GameViewLayer:getDataMgr( )
	return self:getParentNode():getDataMgr()
end

function GameViewLayer:logData(msg)
	local p = self:getParentNode()
	if nil ~= p.logData then
		p:logData(msg)
	end	
end


------
--倒计时节点
function GameViewLayer:setGameTimer(status,leaveTime)
	self.m_sprFreeTimer:setVisible(false)
	self.m_sprPlayTimer:setVisible(false)
	self.m_sprAwardTimer:setVisible(false)

	if status == g_var(cmd).GAME_SCENE_FREE then
		self.m_sprFreeTimer:setVisible(true)
	elseif status == g_var(cmd).GAME_JETTON then
		self.m_sprPlayTimer:setVisible(true)
	elseif status == g_var(cmd).GAME_END then
		self.m_sprAwardTimer:setVisible(true)
	end
	self.m_atlasLabels[ENUM_CHIPNUM.NUM_TIME]:setString(leaveTime);
	self.m_atlasLabels[ENUM_CHIPNUM.NUM_TIME]:setVisible(true);
	self:updateClock(leaveTime);
end

function GameViewLayer:updateClock(leaveTime)
	--重置定时器
	if nil ~= self.m_scheduler_timer then
		scheduler:unscheduleScriptEntry(self.m_scheduler_timer)
		self.m_scheduler_timer = nil
	end	
	--回调
	local timeNum = leaveTime;
	local function timercallback(dt)
		timeNum = timeNum - 1;
		self.m_atlasLabels[ENUM_CHIPNUM.NUM_TIME]:setString(timeNum);
		if timeNum == 0 then
			scheduler:unscheduleScriptEntry(self.m_scheduler_timer)
		end
	end
	--开始
	if nil == self.m_scheduler_timer then
		self.m_scheduler_timer = scheduler:scheduleScriptFunc(timercallback, 1, false)
	end	
end

--结束计时器
function GameViewLayer:stopTimer( )
	--重置定时器
	if nil ~= self.m_scheduler_timer then
		scheduler:unscheduleScriptEntry(self.m_scheduler_timer)
		self.m_scheduler_timer = nil
	end	
end
function GameViewLayer:showTimerTip(tag)

end
------
function GameViewLayer:refreshUserList(  )
	if nil ~= self.m_userListLayer and self.m_userListLayer:isVisible() then
		local userList = self:getDataMgr():getUserList()		
		self.m_userListLayer:refreshList(userList)
	end
end
------
--银行节点
function GameViewLayer:createBankLayer()
	self.m_bankLayer = cc.Node:create()
	self:addToRootLayer(self.m_bankLayer, TAG_ZORDER.BANK_ZORDER)
	self.m_bankLayer:setTag(TAG_ENUM.BANK_LAYER)

	--加载csb资源
	local csbNode = ExternalFun.loadCSB("bank/BankLayer.csb", self.m_bankLayer)
	local sp_bg = csbNode:getChildByName("sp_bg")

	------
	--按钮事件
	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onButtonClickedEvent(sender:getTag(), sender)
		end
	end	
	--关闭按钮
	local btn = sp_bg:getChildByName("close_btn")
	btn:setTag(TAG_ENUM.BT_CLOSEBANK)
	btn:addTouchEventListener(btnEvent)

	--取款按钮
	btn = sp_bg:getChildByName("out_btn")
	btn:setTag(TAG_ENUM.BT_TAKESCORE)
	btn:addTouchEventListener(btnEvent)
	------

	------
	--编辑框
	--取款金额
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

	--取款密码
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
	------

	--当前游戏币
	self.m_bankLayer.m_textCurrent = sp_bg:getChildByName("text_current")

	--银行游戏币
	self.m_bankLayer.m_textBank = sp_bg:getChildByName("text_bank")

	--取款费率
	self.m_bankLayer.m_textTips = sp_bg:getChildByName("text_tips")
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
function GameViewLayer:refreshScore(  )
	--携带游戏币
	local str = ExternalFun.numberThousands(GlobalUserItem.lUserScore)
	if string.len(str) > 19 then
		str = string.sub(str, 1, 19)
	end
	self.m_bankLayer.m_textCurrent:setString(str)

	--更新游戏内游戏币
	--self:setChipString(ENUM_CHIPNUM.NUM_MYCHIP, GlobalUserItem.lUserScore)
    self:setSelfScore(GlobalUserItem.lUserScore)
	--银行存款
	str = ExternalFun.numberThousands(GlobalUserItem.lUserInsure)
	if string.len(str) > 19 then
		str = string.sub(str, 1, 19)
	end
	self.m_bankLayer.m_textBank:setString(ExternalFun.numberThousands(GlobalUserItem.lUserInsure))

	self.m_bankLayer.m_editNumber:setText("")
	self.m_bankLayer.m_editPasswd:setText("")
end
------
return GameViewLayer