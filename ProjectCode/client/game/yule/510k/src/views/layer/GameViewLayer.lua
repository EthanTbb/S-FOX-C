--
-- Author: zhong
-- Date: 2016-11-02 17:28:24
--
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local GameChatLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.game.GameChatLayer")
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. "ClipText")
local AnimationMgr = appdf.req(appdf.EXTERNAL_SRC .. "AnimationMgr")

local module_pre = "game.yule.510k.src"
local cmd = appdf.req(module_pre .. ".models.CMD_Game")
local Define = appdf.req(module_pre .. ".models.Define")
local CardSprite = appdf.req(module_pre .. ".views.layer.gamecard.CardSprite")
local CardsNode = appdf.req(module_pre .. ".views.layer.gamecard.CardsNode")
local GameLogic = appdf.req(module_pre .. ".models.GameLogic")
local ResultLayer = appdf.req(module_pre .. ".views.layer.ResultLayer")
local ChooseLayer = appdf.req(module_pre .. ".views.layer.ChooseLayer")
local PopupInfoHead = appdf.req(appdf.EXTERNAL_SRC .. "PopupInfoHead")

local TAG_ENUM = Define.TAG_ENUM
local TAG_ZORDER = Define.TAG_ZORDER

local GameViewLayer = class("GameViewLayer",function(scene)
        local gameViewLayer = display.newLayer()
    return gameViewLayer
end)

local CARD_WIDTH_SMALL = 96
local CARD_HEIGHT_SMALL = 127
local CARD_DISTANCE_UNIT = 12
local TEST_CARD_NUM = cmd.NORMAL_COUNT
GameViewLayer.enum = 
{

    Tag_userNick =1,    

    Tag_userScore=2,

    Tag_GameScore = 10,
    Tag_Buttom = 70 ,

    Tag_Head = 1,

    Tag_FindFriend = 100,
    Tag_CardsNum = 500, --玩家牌数量
    Tag_Cards = 1000,
    Tag_CardsEffct = 2000
}

local timeBgAngle = 
    {
        0,
        -90,
        -180,
        -270,
    }

local tabCardPositionChange = 
    {
        cc.p(0, 0),
        cc.p(0, - CARD_HEIGHT_SMALL / CARD_DISTANCE_UNIT),
        cc.p( - CARD_WIDTH_SMALL / (CARD_DISTANCE_UNIT - 4), 0),
        cc.p(0, - CARD_HEIGHT_SMALL / CARD_DISTANCE_UNIT),
    }

local tabCardNumPositionFlag = 
    {
        0,
        1,
        0,
        1
    }

local tabCardPosition = 
    {
        cc.p(0, -270),
        cc.p(475, 85),
        cc.p(0, 285),
        cc.p(-470, 85),
    }
--[[
local tabCardPosition = 
    {
        cc.p(0, -270),
        cc.p(0, -270),
        cc.p(0, -270),
        cc.p(0, -270),
    }
--]]
local tabCardsHandCount = 
    {
        cmd.NORMAL_COUNT,
        cmd.NORMAL_COUNT,
        cmd.NORMAL_COUNT,
        cmd.NORMAL_COUNT
    }
--玩家当前得分
local table_curScore ={0,0,0,0}
 

local TAG = GameViewLayer.enum

function GameViewLayer:registerTouchEvent(bSwallow, FixedPriority)
    local function onTouchBegan( touch, event )
        if nil == self.onTouchBegan then
            return false
        end
        return self:onTouchBegan(touch, event)
    end

    local function onTouchMoved(touch, event)
        if nil ~= self.onTouchMoved then
            self:onTouchMoved(touch, event)
        end
    end

    local function onTouchEnded( touch, event )
        if nil ~= self.onTouchEnded then
            self:onTouchEnded(touch, event)
        end       
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(bSwallow)
    self._listener = listener
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithFixedPriority(listener, FixedPriority)
end

function GameViewLayer:ctor(scene)
    --注册node事件
    ExternalFun.registerNodeEvent(self)
    CardsNode.registerTouchEvent(self,false,5)

    self._scene = scene

    --初始化
    self:paramInit()
    TEST_CARD_NUM = cmd.NORMAL_COUNT
    --加载资源
    self:loadResource()
    self.m_nCountDownView = cmd.MY_VIEWID
end

function GameViewLayer:paramInit()
    self.m_bSelfDu = false --自己是否为独

    self.m_bHaveBlackFive = false --是否拥有黑桃5
    -- 聊天层
    self.m_chatLayer = nil
    -- 结算层
    self.m_resultLayer = nil

    -- 手牌控制
    self.m_cardControl = nil
    -- 手牌数量
    self.m_tabCardCount = {}
    -- 报警动画
    self.m_tabSpAlarm = {}

    -- 叫分text
    self.m_textGameCall = nil
    -- 庄家牌
    self.m_nodeBankerCard = nil
    self.m_tabBankerCard = {}
    -- 准备按钮
    self.m_btnReady = nil
    
    -- 准备标签
    self.m_tabReadySp = {}
    -- 状态标签
    self.m_tabStateSp = {}

    -- 叫分控制
    self.m_callScoreControl = nil
    self.m_nMaxCallScore = 0
    self.m_tabCallScoreBtn = {}

    -- 操作控制
    self.m_onGameControl = nil
    self.m_bt_outCard = nil
    self.m_bt_pass = nil
    self.m_bt_tip = nil
    self.m_bMyCallBanker = false
    self.m_bMyOutCards = false
    --解散
    self.m_bt_dissolve = nil
    --暂离
    self.m_bt_depart = nil
    -- 出牌控制
    self.m_outCardsControl = nil
    -- 能否出牌
    self.m_bCanOutCard = false

    -- 用户信息
    self.m_userinfoControl = nil
    -- 用户头像
    self.m_tabUserHead = {}
    self.m_tabUserHeadPos = {}
    -- 用户信息
    self.m_tabUserItem = {}

    self.m_tabUserItemCopy = {}
    -- 用户昵称
    self.m_tabCacheUserNick = {}
    -- 用户游戏币
    self.m_atlasScore = nil
    -- 底分
    self.m_atlasDiFeng = nil
    -- 提示
    self.m_spInfoTip = nil
    -- 一轮提示组合
    self.m_promptIdx = 0
    -- 倒计时
    self.m_time_bg = nil
    self.m_time_num = nil
    self.m_tabTimerPos = {}

    --托管界面bg
    self.m_trusteeshipBg = nil
    -- 托管
    self.m_trusteeshipControl = nil

    -- 扑克
    self.m_tabNodeCards = {}

    -- 火箭
    self.m_actRocketRepeat = nil
    -- 火箭飞行
    self.m_actRocketShoot = nil

    -- 飞机
    self.m_actPlaneRepeat = nil
    -- 飞机飞行
    self.m_actPlaneShoot = nil

    -- 炸弹
    self.m_actBomb = nil
    --宣战按钮
    self.m_bt_declareWar = nil
    --不宣战按钮
    self.m_bt_no_declareWar = nil
    --菜单按钮
    self.m_menu_bg = nil
    --音效
    self.m_bt_music = nil
    --托管
    self.m_bt_trusteeship = nil

    self.m_bt_help = nil

    self.m_bt_exit = nil


    --历史记录背景框
    self.m_record_bg = nil
    --本轮得分
    self.m_round_outTotalScore = nil

    self.m_wChairId = self._scene:GetMeChairID()
    self.m_wTableId = self._scene:GetMeTableID()
    self.m_cardNum1 = nil

    self.m_tabSelectCards = {}

    self.m_bClickButton = false

    --历史成绩
    self.m_lCellScore = 1

    self.m_lGameScore = {} --游戏输赢分

    self.m_lCollectScore = {1,1,1,1} --汇总成绩

    self.m_cbScore = {0,0,0,0} --玩家当前游戏得分

    self.m_cbBaseTimes = 1 --基础倍数

    self.m_wBankerUser = 0 --庄家用户

    self.m_tabDwUserID = {1,1,1,1}

    self.m_historyScore = {
        {lTurnScore = 0,lCollectScore = 0},
        {lTurnScore = 0,lCollectScore = 0},
        {lTurnScore = 0,lCollectScore = 0},
        {lTurnScore = 0,lCollectScore = 0},
    } --历史积分信息

    self.m_historyUseItem = {}

    self.m_tabCbBaseTimes = {1, 1, 1, 1}

    self.m_nRoundCount = 0 -------玩了多少回合

    self.m_nCurTotalScore = 0

    self.m_bClickSuggest = false

    self.m_bTrustee = false

    self.m_tabVoiceBox = {}

    self.m_tabPopHeadPos = 
    {
        cc.p(143,160),
        cc.p(815,248),
        cc.p(605,237),
        cc.p(143,245),
    }

    self.m_tabPopHeadAnchorPoint =
    {
        cc.p(0, 0),
        cc.p(1, 0.7),
        cc.p(0.5, 1),
        cc.p(0, 0.7),
    }

    self.m_tabRecordNickName = {}
end

function GameViewLayer:getParentNode()
    return self._scene
end


function GameViewLayer:onTouchBegan(touch, event)
    print("GameViewLayer onTouchBegan")
    --if self.m_bClickSuggest then
        --self.m_bClickSuggest = false
        return true
    --else
        --return false
    --end
end

function GameViewLayer:onTouchMoved(touch, event)
 
end

function GameViewLayer:onTouchEnded(touch, event)
    print("GameViewLayer onTouchEnded")
end

function GameViewLayer:addToRootLayer( node , zorder)
    if nil == node then
        return
    end

    self.m_rootLayer:addChild(node)
    if type(zorder) == "number" then
        node:setLocalZOrder(zorder)
    end    
end

function GameViewLayer:loadResource()
    -- 加载卡牌纹理
    cc.Director:getInstance():getTextureCache():addImage("card_res/card.png")
    cc.Director:getInstance():getTextureCache():addImage("card_res/cardsmall.png")
    local tabCardEffectIndex = {3, 5, 7, 9,11}
    local tabCardEffectCount = {13, 12, 14, 16,14}
    local cardEffctWidth = 470
    local cardEffctHeight = 156
    --牌效果
    local aniTime = 0.12
    for i = 1,5 do
        cc.Director:getInstance():getTextureCache():addImage("card_res/cardEffect"..tabCardEffectIndex[i]..".png")
        cc.SpriteFrameCache:getInstance():addSpriteFrames("card_res/cardEffect"..tabCardEffectIndex[i]..".plist")
    end
 
    for i = 1,#tabCardEffectIndex do
        if tabCardEffectIndex[i] == 11 then
            aniTime = 0.08
        end
        local frames = {}
        for j = 1,tabCardEffectCount[i] do 
            local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("cardEffect"..tabCardEffectIndex[i].."_"..j..".png") 
            table.insert(frames, frame)   
        end

        local  animation = cc.Animation:createWithSpriteFrames(frames,aniTime)
        cc.AnimationCache:getInstance():addAnimation(animation, "cardEffectAnim"..tabCardEffectIndex[i])
    end
    --警报灯
    local alertFrames = {}
    for i = 1, 2 do
        local frame = cc.SpriteFrame:create("game_res/alert.png",cc.rect(114*(i-1),0,114,93))
        table.insert(alertFrames, frame)  
    end
    local  alertAnim = cc.Animation:createWithSpriteFrames(alertFrames,0.35)
    cc.AnimationCache:getInstance():addAnimation(alertAnim, "alertAnim")

    

    -- 加载动画纹理

    --语音动画
    cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/voice_ani.plist")
    local frames = {}
    for i=1, 2 do
        local frameName = "img_voice_" .. i ..".png"
        local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName) 
        table.insert(frames, frame)
    end
    local  animation =cc.Animation:createWithSpriteFrames(frames,0.3)

    cc.AnimationCache:getInstance():addAnimation(animation, Define.VOICE_ANIMATION_KEY)
    
    --播放背景音乐
    ExternalFun.playBackgroudAudio("background.wav")

    local rootLayer, csbNode = ExternalFun.loadRootCSB("game_res/GameLayer.csb", self)
    self.m_rootLayer = rootLayer
    self.m_csbNode = csbNode
    self.m_csbNode:setAnchorPoint(cc.p(0,0))
    self.m_csbNode:setPosition(cc.p(667,375))
    local function btnEvent( sender, eventType )
        if eventType == ccui.TouchEventType.began then
            ExternalFun.popupTouchFilter(1, false)
        elseif eventType == ccui.TouchEventType.canceled then
            ExternalFun.dismissTouchFilter()
        elseif eventType == ccui.TouchEventType.ended then
            ExternalFun.dismissTouchFilter()
            self:onButtonClickedEvent(sender:getTag(), sender)
            if nil ~= self.m_tabNodeCards then
                self.m_tabNodeCards[1]:onTouchEnded(sender,eventType)
            end   
        end
    end
    local csbNode = self.m_csbNode
    self.left_bg_pri = csbNode:getChildByName("left_bg_pri")
    self.left_bg_pri:setVisible(false)
    self.left_bg_normal = csbNode:getChildByName("left_bg_normal")
    -- 准备标签
    -- 扑克牌
    for i = 1, 4 do
        local bShow = false
        if i == cmd.MY_VIEWID then
            bShow = true
        end
        self.m_tabNodeCards[i] = CardsNode:createEmptyCardsNode(i,true,6)
        self.m_tabNodeCards[i]:setPosition(tabCardPosition[i])
        self.m_tabNodeCards[i]:setListener(self)
        self.m_csbNode:addChild(self.m_tabNodeCards[i])
    end
    self:initCardsNodeLayout()
    self.m_tabAlertSp = {}
    --3个警报灯
    for i = 2, 4 do
        local alert = csbNode:getChildByName("alert_"..i)
        alert:setVisible(false)
        self.m_tabAlertSp[i] = cc.Sprite:create("game_res/alert.png", cc.rect(0, 0, 114, 93))
        self.m_tabAlertSp[i]:setPosition(cc.p(alert:getPositionX(), alert:getPositionY()))
        self.m_tabAlertSp[i]:setLocalZOrder(TAG_ZORDER.Card_Alert)
        csbNode:addChild(self.m_tabAlertSp[i])
        local animation = cc.AnimationCache:getInstance():getAnimation("alertAnim")
        self.m_tabAlertSp[i]:runAction(cc.RepeatForever:create(cc.Animate:create(animation)))
        self.m_tabAlertSp[i]:setVisible(false)
    end

     -- 邀请按钮
    self.m_btnInvite = csbNode:getChildByName("bt_invite")
    self.m_btnInvite:setTag(TAG_ENUM.BT_INVITE)
    self.m_btnInvite:addTouchEventListener(btnEvent)
    self.m_btnInvite:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)

    if GlobalUserItem.bPrivateRoom then
        self.m_btnInvite:setVisible(false)
        self.m_btnInvite:setEnabled(false)
    end

    self.m_time_bg = csbNode:getChildByName("time_bg")
    self.m_time_num = self.m_time_bg:getChildByName("time_num")

    for i = 1, 4 do
		local viewId = self._scene:SwitchViewChairID(i - 1)
        local head_bg = csbNode:getChildByName(string.format("head_bg_%d", viewId))
        if viewId == 1 then
            -- 游戏币
            self.m_atlasScore = head_bg:getChildByName("player_score")
        else
            head_bg:setVisible(false)
        end
		local img_pri_own = head_bg:getChildByName("img_pri_own")
		img_pri_own:setLocalZOrder(TAG.Tag_Head + 7)
		local head_cover = head_bg:getChildByName("head_cover")
        head_cover:setLocalZOrder(TAG.Tag_Head + 1)

        local player_status = head_bg:getChildByName("player_status")
        player_status:setVisible(false)
        player_status:setLocalZOrder(TAG.Tag_Head + 2)
        
        local heart = head_bg:getChildByName("heart")
        heart:setVisible(false)
        heart:setLocalZOrder(TAG.Tag_Head + 5)
        --
        local tip_ready = csbNode:getChildByName(string.format("tip_ready_%d", viewId))
        tip_ready:setVisible(false)
        local tip_operate = csbNode:getChildByName(string.format("tip_operate_%d", viewId))
        tip_operate:setVisible(false)

        tip_addTime = csbNode:getChildByName(string.format("tip_addTime_%d", viewId))
        tip_addTime:setVisible(false)

        local tip_no_addTime = self.m_csbNode:getChildByName(string.format("tip_no_addTime_%d", viewId))
        tip_no_addTime:setVisible(false)

        local text_curScore = head_bg:getChildByName("text_curScore")
        text_curScore:setString("当前得分:0")

        local img_voice_box = csbNode:getChildByName("img_voice_box_"..viewId)
        img_voice_box:setVisible(false)
        local img_voice = img_voice_box:getChildByName("img_voice")
        img_voice_box:setLocalZOrder(TAG_ZORDER.VOICE_ZORDER)
        self.m_tabVoiceBox[i] = img_voice_box
        local animation = cc.AnimationCache:getInstance():getAnimation(Define.VOICE_ANIMATION_KEY)
        if nil ~= animation then
            local action = cc.RepeatForever:create(cc.Animate:create(animation))
            img_voice:runAction(action)
        end
    end

    self.m_record_bg = csbNode:getChildByName("record_bg")
    self.m_record_bg:setVisible(false)
    self.m_record_bg:setLocalZOrder(TAG_ZORDER.Card_Control)
    for i = 1, 4 do
        local nickName = self.m_record_bg:getChildByName("nickName_"..i)
        nickName:setVisible(false)
        self.m_tabRecordNickName[i] = ClipText:createClipText(cc.size(110, 30), "xx", nil, 16)
        self.m_tabRecordNickName[i]:setAnchorPoint(cc.p(0, 0.5))
        self.m_tabRecordNickName[i]:setPosition(cc.p(nickName:getPositionX(), nickName:getPositionY()))
        self.m_record_bg:addChild(self.m_tabRecordNickName[i])
    end
    --本轮得分
    self.m_round_outTotalScore = csbNode:getChildByName("round_outTotalScore")
    self.m_round_outTotalScore:setString("0")
    

    --顶部菜单

    --菜单按钮
    self.m_menu_bg = nil
    --音效
    self.m_bt_music = nil
    --
    self.m_bt_trusteeship = nil

    self.m_bt_help = nil

    self.m_bt_exit = nil

    self.m_cardNum1 = csbNode:getChildByName("cardNum1")
    self.m_cardNum1:setVisible(false)

    self.m_menu_bg = csbNode:getChildByName("menu_bg")
    --self.m_menu_bg:setVisible(false)
    self.m_menu_bg:setScale(0.01)
    --
    self.m_bMenuVisible = false
    self.m_bt_menu = csbNode:getChildByName("bt_menu")
    self.m_bt_menu:setTag(TAG_ENUM.BT_MENU)
    self.m_bt_menu:setSwallowTouches(true)
    self.m_bt_menu:addTouchEventListener(btnEvent)
    self.m_bt_menu:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)
    --设置界面
    self.m_bt_setting = self.m_menu_bg:getChildByName("bt_setting")
    self.m_bt_setting:setTag(TAG_ENUM.BT_SETTING)
    self.m_bt_setting:setSwallowTouches(true)
    self.m_bt_setting:addTouchEventListener(btnEvent)
    self.m_bt_setting:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)

    --托管按钮
    self.m_bt_trusteeship = self.m_menu_bg:getChildByName("bt_trusteeship")
    self.m_bt_trusteeship:setTag(TAG_ENUM.BT_TRU)
    self.m_bt_trusteeship:setSwallowTouches(true)
    self.m_bt_trusteeship:addTouchEventListener(btnEvent)
    self.m_bt_trusteeship:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)
    self:changeBtnState(self.m_bt_trusteeship,false)
    --帮助按钮
    self.m_bt_help = self.m_menu_bg:getChildByName("bt_help")
    self.m_bt_help:setTag(TAG_ENUM.BT_HELP)
    self.m_bt_help:setSwallowTouches(true)
    self.m_bt_help:addTouchEventListener(btnEvent)
    self.m_bt_help:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)
    --退出按钮
    self.m_bt_exit = self.m_menu_bg:getChildByName("bt_exit")
    self.m_bt_exit:setTag(TAG_ENUM.BT_EXIT)
    self.m_bt_exit:setSwallowTouches(true)
    self.m_bt_exit:addTouchEventListener(btnEvent)
    self.m_bt_exit:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)

    self.m_bt_record = csbNode:getChildByName("bt_record")
    self.m_bt_record:setTag(TAG_ENUM.BT_RECORD)
    self.m_bt_record:setSwallowTouches(true)
    self.m_bt_record:addTouchEventListener(btnEvent)
    self.m_bt_record:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)

    self.m_bt_record_2 = csbNode:getChildByName("bt_record_2")
    self.m_bt_record_2:setTag(TAG_ENUM.BT_RECORD)
    self.m_bt_record_2:setSwallowTouches(true)
    self.m_bt_record_2:addTouchEventListener(btnEvent)
    self.m_bt_record_2:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)


    --标签
    local str = ""
    
    --退出按钮
    --宣战按钮
    --local cards = {0x01,0x02,0x03}
    --self.m_tabNodeCards[cmd.RIGHT_VIEWID]:updateCardsNode(cards, true, false)

    
    self.m_bt_declareWar = csbNode:getChildByName("bt_declareWar")
    self.m_bt_declareWar:setVisible(false)
    self.m_bt_declareWar:setTag(TAG_ENUM.BT_DELAREWAR)
    self.m_bt_declareWar:setSwallowTouches(true)
    self.m_bt_declareWar:addTouchEventListener(btnEvent)
    self.m_bt_declareWar:setLocalZOrder(TAG_ZORDER.Btns_ZORDER) 
    
    --不宣战按钮
    self.m_bt_no_declareWar = csbNode:getChildByName("bt_no_declareWar")
    self.m_bt_no_declareWar:setVisible(false)
    self.m_bt_no_declareWar:setTag(TAG_ENUM.BT_NO_DELAREWAR)
    self.m_bt_no_declareWar:setSwallowTouches(true)
    self.m_bt_no_declareWar:addTouchEventListener(btnEvent)
    self.m_bt_no_declareWar:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)


    --准备按钮
    self.m_btnReady = csbNode:getChildByName("bt_start")
    self.m_btnReady:setTag(TAG_ENUM.BT_READY)
    self.m_btnReady:addTouchEventListener(btnEvent)
    self.m_btnReady:setEnabled(false)
    self.m_btnReady:setVisible(false)
    self.m_btnReady:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)
    --self.m_btnReady:loadTextureDisabled("btn_ready_0.png",UI_TEX_TYPE_PLIST)

    self.m_bt_pass = csbNode:getChildByName("bt_pass")
    self.m_bt_pass:setTag(TAG_ENUM.BT_PASS)
    self.m_bt_pass:addTouchEventListener(btnEvent)
    self.m_bt_pass:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)

    --提示按钮
    self.m_bt_tip = csbNode:getChildByName("bt_tip")
    self.m_bt_tip:setTag(TAG_ENUM.BT_SUGGEST)
    self.m_bt_tip:setSwallowTouches(true)
    self.m_bt_tip:addTouchEventListener(btnEvent)
    self.m_bt_tip:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)

    --出牌按钮
    self.m_bt_outCard = csbNode:getChildByName("bt_outCard")
    self.m_bt_outCard:setTag(TAG_ENUM.BT_OUTCARD)
    self.m_bt_outCard:addTouchEventListener(btnEvent)
    self.m_bt_outCard:setSwallowTouches(true)
    self.m_bt_outCard:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)

    --问队友
    self.m_bt_ask = csbNode:getChildByName("bt_ask")
    self.m_bt_ask:setTag(TAG_ENUM.BT_ASK)
    self.m_bt_ask:addTouchEventListener(btnEvent)
    self.m_bt_ask:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)


    self.m_bt_no_ask = csbNode:getChildByName("bt_no_ask")
    self.m_bt_no_ask:setTag(TAG_ENUM.BT_NO_ASK)
    self.m_bt_no_ask:addTouchEventListener(btnEvent)
    self.m_bt_no_ask:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)

    self.m_bt_add = csbNode:getChildByName("bt_add")
    self.m_bt_add:setTag(TAG_ENUM.BT_ADD)
    self.m_bt_add:addTouchEventListener(btnEvent)
    self.m_bt_add:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)

    self.m_bt_no_add = csbNode:getChildByName("bt_no_add")
    self.m_bt_no_add:setTag(TAG_ENUM.BT_NO_ADD)
    self.m_bt_no_add:addTouchEventListener(btnEvent)
    self.m_bt_no_add:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)

    --语音
    self.m_bt_voice = csbNode:getChildByName("bt_voice")
    self.m_bt_voice:setTag(TAG_ENUM.BT_VOICE)
    self.m_bt_voice:addTouchEventListener(btnEvent)
    self.m_bt_voice:setLocalZOrder(TAG_ZORDER.Btns_ZORDER)
    self.m_bt_voice:setVisible(false)

    --通用语音按钮
    if not GlobalUserItem.isAntiCheat() then
        self:getParentNode():getParentNode():createVoiceBtn(cc.p(self.m_bt_voice:getPositionX(), self.m_bt_voice:getPositionY()),TAG_ZORDER.Btns_ZORDER,self.m_csbNode)
    end
    
    
    self:hideAddTimesBtns()
    self:hideOutCardsBtns()
    self:hideAskFriendBtns()

    self.m_trusteeshipBg = csbNode:getChildByName("trusteeship_bg")
    self.m_trusteeshipBg:setLocalZOrder(TAG_ZORDER.TRUSTEESHIP_ZORDER)
    self.m_trusteeshipBg:setVisible(false)
    -- 游戏托管
    self.m_trusteeshipControl = self.m_trusteeshipBg:getChildByName("bt__cancelTrusteeship")
    self.m_trusteeshipControl:setTag(TAG_ENUM.BT_TRU) 
    self.m_trusteeshipControl:addTouchEventListener(btnEvent)
    --[[
    self.m_trusteeshipControl:addTouchEventListener(function( ref, tType)
        if tType == ccui.TouchEventType.ended then
            if self.m_trusteeshipBg:isVisible() then
                self.m_trusteeshipBg:setVisible(false)
                self.m_bTrustee = false
            end
        end
    end)
    --]]
    --self:openFindRriendLayer()
    self.m_outCardsControl = cc.LayerColor:create(cc.c4b(0,0,0,0),yl.WIDTH,yl.HEIGHT)
    self.m_outCardsControl:setPosition(cc.p(- yl.WIDTH / 2, - yl.HEIGHT / 2))
    --self.m_outCardsControl:setContentSize(cc.size(yl.WIDTH,yl.HEIGHT))
    csbNode:addChild(self.m_outCardsControl, TAG_ZORDER.Card_Control, "")
    --node:setContentSize(cc.size(10, 10))

    self.m_txt_curDesk = csbNode:getChildByName("txt_curDesk")
    self.m_txt_curDesk:setVisible(false)
    self.m_txt_curDesk:setString(self.m_wTableId.."号桌")
    self.m_txt_rule = csbNode:getChildByName("txt_rule")
    self.m_txt_rule:setVisible(false)
    self:updateRule()

    
end

function GameViewLayer:createAnimation()
    local param = AnimationMgr.getAnimationParam()
    param.m_fDelay = 0.1
    -- 火箭动画
    param.m_strName = Define.ROCKET_ANIMATION_KEY
    local animate = AnimationMgr.getAnimate(param)
    if nil ~= animate then
        local rep = cc.RepeatForever:create(animate)
        self.m_actRocketRepeat = rep
        self.m_actRocketRepeat:retain()
        local moDown = cc.MoveBy:create(0.1, cc.p(0, -20))
        local moBy = cc.MoveBy:create(2.0, cc.p(0, 500))
        local fade = cc.FadeOut:create(2.0)
        local seq = cc.Sequence:create(cc.DelayTime:create(2.0), cc.CallFunc:create(function()

            end), fade)
        local spa = cc.Spawn:create(cc.EaseExponentialIn:create(moBy), seq)
        self.m_actRocketShoot = cc.Sequence:create(cc.CallFunc:create(function( ref )
            ref:runAction(rep)
        end), moDown, spa, cc.RemoveSelf:create(true))
        self.m_actRocketShoot:retain()
    end

    -- 飞机动画    
    param.m_strName = Define.AIRSHIP_ANIMATION_KEY
    local animate = AnimationMgr.getAnimate(param)
    if nil ~= animate then
        local rep = cc.RepeatForever:create(animate)
        self.m_actPlaneRepeat = rep
        self.m_actPlaneRepeat:retain()
        local moTo = cc.MoveTo:create(3.0, cc.p(0, yl.HEIGHT * 0.5))
        local fade = cc.FadeOut:create(1.5)
        local seq = cc.Sequence:create(cc.DelayTime:create(1.5), cc.CallFunc:create(function()
            ExternalFun.playSoundEffect("common_plane.wav")
            end), fade)
        local spa = cc.Spawn:create(moTo, seq)
        self.m_actPlaneShoot = cc.Sequence:create(cc.CallFunc:create(function( ref )
            ref:runAction(rep)
        end), spa, cc.RemoveSelf:create(true))
        self.m_actPlaneShoot:retain()
    end

    -- 炸弹动画
    param.m_strName = Define.BOMB_ANIMATION_KEY
    local animate = AnimationMgr.getAnimate(param)
    if nil ~= animate then
        local fade = cc.FadeOut:create(1.0)
        self.m_actBomb = cc.Sequence:create(animate, fade, cc.RemoveSelf:create(true))
        self.m_actBomb:retain()
    end    
end

function GameViewLayer:unloadResource()

    local tabCardEffectIndex = {3, 5, 7, 9,11}
    for i = 1,5 do
        cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("card_res/cardEffect"..tabCardEffectIndex[i]..".png")
        cc.Director:getInstance():getTextureCache():removeTextureForKey("card_res/cardEffect"..tabCardEffectIndex[i]..".plist")
    end

    AnimationMgr.removeCachedAnimation(Define.CALLSCORE_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation(Define.CALLONE_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation(Define.CALLTWO_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation(Define.CALLTHREE_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation(Define.AIRSHIP_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation(Define.ROCKET_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation(Define.ALARM_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation(Define.BOMB_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation(Define.VOICE_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation("alertAnim")

    cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/voice_ani.plist")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/voice_ani.png")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/alert.png")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("card_res/card.png")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("card_res/cardsmall.png")

    cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("public_res/public_res.plist")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("public_res/public_res.png")
    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
end
-- 重置
function GameViewLayer:reSetGame()
    self:reSetUserState()
    self.m_time_bg:setVisible(false)
    self.m_time_num:setString("")
    self.m_cardNum1:setVisible(false)
    -- 取消托管
    --self.m_trusteeshipControl:setVisible(false)
    for i = 1, cmd.PLAYER_COUNT do
        local head_bg = self.m_csbNode:getChildByName(string.format("head_bg_%d", i))
        local player_status = head_bg:getChildByName("player_status")
        player_status:setVisible(false)

        local tip_operate = self.m_csbNode:getChildByName(string.format("tip_operate_%d", i))
        tip_operate:setVisible(false)
        local text_curScore = head_bg:getChildByName("text_curScore")
        text_curScore:setString("当前得分:0")
        local nodeCard = self.m_tabNodeCards[i]
        nodeCard:setCardsCount(cmd.NORMAL_COUNT)
        nodeCard:setVisible(false)
        local heart = head_bg:getChildByName("heart")
        heart:setVisible(false)

        tip_addTime = self.m_csbNode:getChildByName(string.format("tip_addTime_%d", i))
        tip_addTime:setVisible(false)

        self.m_cbScore[i] = 0
    end
    self.m_bMyCallBanker = false
    self.m_bMyOutCards = false

end

-- 重置(新一局)
function GameViewLayer:reSetForNewGame()
    -- 清理手牌
    for k,v in pairs(self.m_tabNodeCards) do
        v:removeAllCards()

        self.m_tabSpAlarm[k]:stopAllActions()
        self.m_tabSpAlarm[k]:setSpriteFrame("blank.png")
    end
    for k,v in pairs(self.m_tabCardCount) do
        v:setString("")
    end
    -- 清理桌面
    self.m_outCardsControl:removeAllChildren()
    -- 庄家叫分
    self.m_textGameCall:setString("")
    -- 庄家扑克
    for k,v in pairs(self.m_tabBankerCard) do
        v:setVisible(false)
        v:setCardValue(0)
    end
    -- 用户切换
    for k,v in pairs(self.m_tabUserHead) do
        v:reSet()
    end
end

-- 重置用户状态
function GameViewLayer:reSetUserState()
    for k,v in pairs(self.m_tabReadySp) do
        v:setVisible(false)
    end

    for k,v in pairs(self.m_tabStateSp) do
        v:setSpriteFrame("blank.png")
    end
    self.m_btnReady:setEnabled(true)
    self.m_btnReady:setVisible(true)
end

-- 重置用户信息
function GameViewLayer:reSetUserInfo()
    local score = self:getParentNode():GetMeUserItem().lScore or 0
    local str = ""
    if score < 0 then
        str = "." .. score
    else
        str = "" .. score        
    end 
    if string.len(str) > 11 then
        str = string.sub(str, 1, 11)
        str = str .. "///"
    end  
    self.m_atlasScore:setString(str) 
end

function GameViewLayer:onExit()
    if nil ~= self.m_actRocketRepeat then
        self.m_actRocketRepeat:release()
        self.m_actRocketRepeat = nil
    end

    if nil ~= self.m_actRocketShoot then
        self.m_actRocketShoot:release()
        self.m_actRocketShoot = nil
    end

    if nil ~= self.m_actPlaneRepeat then
        self.m_actPlaneRepeat:release()
        self.m_actPlaneRepeat = nil
    end

    if nil ~= self.m_actPlaneShoot then
        self.m_actPlaneShoot:release()
        self.m_actPlaneShoot = nil
    end

    if nil ~= self.m_actBomb then
        self.m_actBomb:release()
        self.m_actBomb = nil
    end
    self:unloadResource()

    self.m_tabUserItem = {}
end

function GameViewLayer:onButtonClickedEvent(tag, ref)   
    local function addBG()
        local bg = ccui.ImageView:create()
        bg:setContentSize(cc.size(yl.WIDTH, yl.HEIGHT))
        bg:setScale9Enabled(true)
        bg:setPosition(yl.WIDTH/2, yl.HEIGHT/2)
        bg:setTouchEnabled(true)
        self:addChild(bg,50)
        bg:addTouchEventListener(function (sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                bg:removeFromParent()

            end
        end)

        return bg
    end
    ExternalFun.playClickEffect()
    if TAG_ENUM.BT_HELP == tag then
        --print("-------- BT_HELP -------")
        --self._scene:popHelpLayer(yl.HTTP_URL .. "/Mobile/Introduce.aspx?kindid=238&typeid=0")
        local nType = 0

        if  GlobalUserItem.bPrivateRoom then
            nType = 1
        end

        self:getParentNode():getParentNode():popHelpLayer2(238,nType,10)
    elseif TAG_ENUM.BT_VOICE == tag then

    elseif TAG_ENUM.BT_RECORD == tag then
        local is = self.m_record_bg:isVisible()
        is = not is

        self.m_record_bg:setVisible(is)
        self.m_bt_record:setFlippedY(is)
        if is then
        else         
        end        
    elseif TAG_ENUM.BT_CHAT == tag then             --聊天        
        if nil == self.m_chatLayer then
            self.m_chatLayer = GameChatLayer:create(self._scene._gameFrame)
            self:addToRootLayer(self.m_chatLayer, TAG_ZORDER.CHAT_ZORDER)
        end
        self.m_chatLayer:showGameChat(true)
    elseif TAG_ENUM.BT_MUSIC == tag then            --设置音效
        --self.m_time_bg:runAction(cc.RotateBy:create(0.45,-90))
        --self.m_time_num:runAction(cc.RotateBy:create(0.45,90))
         GlobalUserItem.bVoiceAble = not GlobalUserItem.bVoiceAble
                GlobalUserItem.bSoundAble = GlobalUserItem.bVoiceAble

                if GlobalUserItem.bVoiceAble then
                    AudioEngine.resumeMusic()
                    AudioEngine.setMusicVolume(1.0)
                    self.m_bt_music:loadTextures("game_res/bt_musicOn_1.png", "game_res/bt_musicOn_2.png", "game_res/bt_musicOn_1.png")
                else
                    AudioEngine.setMusicVolume(0)
                    AudioEngine.pauseMusic() -- 暂停音乐
                    self.m_bt_music:loadTextures("game_res/bt_musicOff_1.png", "game_res/bt_musicOff_2.png", "game_res/bt_musicOff_1.png")
                end
    elseif TAG_ENUM.BT_SETTING == tag then
        local bMute = false

        local  bg = addBG()

        local csbNode = ExternalFun.loadCSB("game_res/Setting.csb", bg)
        csbNode:setAnchorPoint(0.5,0.5)
        csbNode:setPosition(yl.WIDTH/2,yl.HEIGHT/2)

        local Image_setBG = csbNode:getChildByName("Image_setBG")
        local btnClose = csbNode:getChildByName("bt_close")

        btnClose:addTouchEventListener(function ( sender , eventType )
            if eventType == ccui.TouchEventType.ended then
                bg:removeFromParent()
            end
        end)

        --[[
        local txt_version = csbNode:getChildByName("txt_version")
        txt_version:setVisible(false)
        local mgr = self._scene:getParentNode():getApp():getVersionMgr()
        local verstr = mgr:getResVersion(Game_CMD.KIND_ID) or "0"
        verstr = "游戏版本:" .. appdf.BASE_C_VERSION .. "." .. verstr
        print("----- verstr ----"..verstr)
        local lbVersion =  cc.Label:createWithSystemFont(verstr, "Microsoft Yahei", 20)
        lbVersion:setAnchorPoint(cc.p(1,0.5))
        lbVersion:setPosition(cc.p(txt_version:getPositionX(), txt_version:getPositionY()))
        csbNode:addChild(lbVersion)
        --]]

--静音按钮
        local btn_music = csbNode:getChildByName("btn_music")
        
        if  GlobalUserItem.bVoiceAble then
            btn_music:loadTextures("setting_res/bt_off_1.png", "setting_res/bt_off_2.png", "setting_res/bt_off_1.png")
        else
            btn_music:loadTextures("setting_res/bt_on_1.png", "setting_res/bt_on_2.png", "setting_res/bt_on_1.png")
        end

        local btn_effect = csbNode:getChildByName("btn_effect")
        if  GlobalUserItem.bSoundAble then
            btn_effect:loadTextures("setting_res/bt_off_1.png", "setting_res/bt_off_2.png", "setting_res/bt_off_1.png")
        else
            btn_effect:loadTextures("setting_res/bt_on_1.png", "setting_res/bt_on_2.png", "setting_res/bt_on_1.png")
        end
        
        if (self._tag == 0) and not (GlobalUserItem.bVoiceAble and GlobalUserItem.bSoundAble) then
            self._tag = 1
        end

        btn_music:addTouchEventListener(function( sender,eventType )

            if eventType == ccui.TouchEventType.ended then

                GlobalUserItem.bVoiceAble = not GlobalUserItem.bVoiceAble
                print("GlobalUserItem.bVoiceAble",GlobalUserItem.bVoiceAble)
                GlobalUserItem.setVoiceAble(GlobalUserItem.bVoiceAble)
                if GlobalUserItem.bVoiceAble == true then
                    ExternalFun.playBackgroudAudio("background.wav")
                end
                if  GlobalUserItem.bVoiceAble then
                    --AudioEngine.setMusicVolume(1.0)   
                    btn_music:loadTextures("setting_res/bt_off_1.png", "setting_res/bt_off_2.png", "setting_res/bt_off_1.png")
                else
                    --AudioEngine.setMusicVolume(0)
                    btn_music:loadTextures("setting_res/bt_on_1.png", "setting_res/bt_on_2.png", "setting_res/bt_on_1.png")
                end
            end
        end)

        btn_effect:addTouchEventListener(function( sender,eventType )

            if eventType == ccui.TouchEventType.ended then

                GlobalUserItem.bSoundAble = not GlobalUserItem.bSoundAble
                print("GlobalUserItem.bSoundAble",GlobalUserItem.bSoundAble)
                GlobalUserItem.setSoundAble(GlobalUserItem.bSoundAble)
                if  GlobalUserItem.bSoundAble then
                    --AudioEngine.resumeMusic() 
                    btn_effect:loadTextures("setting_res/bt_off_1.png", "setting_res/bt_off_2.png", "setting_res/bt_off_1.png")
                else
                    --AudioEngine.pauseMusic() -- 暂停音乐
                    btn_effect:loadTextures("setting_res/bt_on_1.png", "setting_res/bt_on_2.png", "setting_res/bt_on_1.png")
                end

                
            end
        end)

        local mgr = self._scene._scene:getApp():getVersionMgr()
        local verstr = mgr:getResVersion(cmd.KIND_ID) or "0"
        verstr = "游戏版本:" .. appdf.BASE_C_VERSION .. "." .. verstr
        print("------- verstr ------"..verstr)
        local txt_version = csbNode:getChildByName("txt_version")
        txt_version:setString(verstr)
    elseif TAG_ENUM.BT_DELAREWAR == tag then
        self:hideDeclareWarBtns()
        self._scene:sendDelareWar(1)
    elseif TAG_ENUM.BT_NO_DELAREWAR == tag then
        self:hideDeclareWarBtns()
        self._scene:sendDelareWar(0)
    elseif TAG_ENUM.BT_MENU == tag then
        --self.m_tabNodeCards[cmd.MY_VIEWID]:dragCards({})

        local isVis = self.m_menu_bg:isVisible()
        self.m_bMenuVisible = not self.m_bMenuVisible
        --print("---- TAG_ENUM.BT_MENU ----", self.m_bMenuVisible)
        ---[[
        if self.m_bMenuVisible == true then
            self.m_menu_bg:runAction(cc.ScaleTo:create(0.3, 1.0))
        else
            self.m_menu_bg:runAction(cc.ScaleTo:create(0.3, 0.01))
        end

    elseif TAG_ENUM.BT_DISSOLVE == tag then
        self.m_time_bg:runAction(cc.RotateBy:create(0.5,-90))
        self.m_time_num:runAction(cc.RotateBy:create(0.5,90))
    elseif TAG_ENUM.BT_TRU == tag then          --托管
        self.m_bTrustee = not self.m_bTrustee
        self:onGameTrusteeship(self.m_bTrustee)
        local cbTrustee = 1
        if not self.m_bTrustee then
            cbTrustee = 0
        end
        self._scene:sendTrustees(cbTrustee)
    elseif TAG_ENUM.BT_SET == tag then          --设置

    elseif TAG_ENUM.BT_EXIT == tag then         --退出
        self:getParentNode():onQueryExitGame()
    elseif TAG_ENUM.BT_READY == tag then        --准备
        self:onClickReady()
    elseif TAG_ENUM.BT_INVITE == tag then       -- 邀请
        GlobalUserItem.bAutoConnect = false
        self:getParentNode():getParentNode():popTargetShare(function(target, bMyFriend)
            bMyFriend = bMyFriend or false
            local function sharecall( isok )
                if type(isok) == "string" and isok == "true" then
                    --showToast(self, "分享成功", 2)
                end
                GlobalUserItem.bAutoConnect = true
            end
            local shareTxt = "510k游戏精彩刺激, 一起来玩吧! "
            local url = GlobalUserItem.szSpreaderURL or yl.HTTP_URL
            if bMyFriend then
                PriRoom:getInstance():getTagLayer(PriRoom.LAYTAG.LAYER_FRIENDLIST, function( frienddata )
                    dump(frienddata)
                end)
            elseif nil ~= target then
                MultiPlatform:getInstance():shareToTarget(target, sharecall, "510k游戏邀请", shareTxt, url, "")
            end
        end)        
    elseif TAG_ENUM.BT_PASS == tag then         --不出
        self:onPassOutCard()
        self:hideOutCardsBtns()
    elseif TAG_ENUM.BT_SUGGEST == tag then      --提示
        --print("------- BT_SUGGEST -------")
        self.m_bClickSuggest = true
        self:onPromptOut(false)        
    elseif TAG_ENUM.BT_OUTCARD == tag then      --出牌
        local sel = self.m_tabNodeCards[cmd.MY_VIEWID]:getSelectCards()
        --dump(sel,"outCards",6)
        -- 扑克对比
        self:getParentNode():compareWithLastCards(sel, cmd.MY_VIEWID)

        --self.m_onGameControl:setVisible(false)
        self:hideOutCardsBtns()
        local vec = self.m_tabNodeCards[cmd.MY_VIEWID]:outCard(sel)
        self:outCardEffect(cmd.MY_VIEWID, sel, vec)
        self._scene:sendOutCard(sel)
    elseif TAG_ENUM.BT_NO_ASK == tag then
        self._scene:sendAskFriend(0)
        self:hideAskFriendBtns()
    elseif TAG_ENUM.BT_ASK == tag then
        self._scene:sendAskFriend(1)
        self:hideAskFriendBtns()
    elseif TAG_ENUM.BT_NO_ADD == tag then
        self._scene:sendAddTimes(0)
        self:hideAddTimesBtns()
    elseif TAG_ENUM.BT_ADD == tag then
        self._scene:sendAddTimes(1)
        self:hideAddTimesBtns()
    elseif TAG_ENUM.BT_VOICE == tag then
        self._scene:sendAddTimes(1)
        self:hideAddTimesBtns()
    end
end

function GameViewLayer:onClickReady()
    self.m_btnReady:setEnabled(false)
    self.m_btnReady:setVisible(false)
    
    self:getParentNode():sendReady()

    if self:getParentNode().m_bRoundOver then
        self:getParentNode().m_bRoundOver = false
        -- 界面清理
        self:reSetForNewGame()
    end 
end

-- 出牌效果
-- @param[outViewId]        出牌视图id
-- @param[outCards]         出牌数据
-- @param[vecCards]         扑克精灵
function GameViewLayer:outCardEffect(outViewId, outCards, vecCards)
    local controlSize = self.m_outCardsControl:getContentSize()

    -- 移除出牌
    self.m_outCardsControl:removeChildByTag(outViewId)
    local holder = cc.Node:create()
    self.m_outCardsControl:addChild(holder)
    holder:setTag(outViewId)

    local outCount = #outCards
    -- 计算牌型
    local cardType = GameLogic:GetCardType(outCards, outCount)
    if GameLogic.CT_THREE_TAKE_ONE == cardType then
        --[[
        if outCount > 4 then
            cardType = GameLogic.CT_THREE_LINE
        end    
        --]]    
    end
    if GameLogic.CT_THREE_TAKE_TWO == cardType then
        --[[
        if outCount > 5 then
            cardType = GameLogic.CT_THREE_LINE
        end    
        --]]    
    end

    -- 出牌
    local targetPos = cc.p(0, 0)
    local center = outCount * 0.5
    local scale = 0.5
    local nodeCard = self.m_tabNodeCards[outViewId]
    local holderPos = nodeCard:getParent():convertToWorldSpace(cc.p(nodeCard:getPositionX(), nodeCard:getPositionY()))
    local effectPosX = 0
    local effectPosY = - yl.HEIGHT * 0.1
    holder:setPosition(holderPos)
    --dump(holderPos, "---- outCardEffect Position ----", 6)
    if cmd.MY_VIEWID == outViewId then
        scale = 0.6
        targetPos = holder:convertToNodeSpace(cc.p(controlSize.width * 0.48, controlSize.height * 0.42))
    elseif cmd.LEFT_VIEWID == outViewId then
        center = 0
        holder:setAnchorPoint(cc.p(0, 0.5))
        targetPos = holder:convertToNodeSpace(cc.p(controlSize.width * 0.33 - 80, controlSize.height * 0.58))
        effectPosX = -yl.WIDTH * 0.32
        effectPosY = yl.HEIGHT * 0.1
    elseif cmd.RIGHT_VIEWID == outViewId then
        center = outCount
        holder:setAnchorPoint(cc.p(1, 0.5))
        targetPos = holder:convertToNodeSpace(cc.p(controlSize.width * 0.67 + 80, controlSize.height * 0.58))
        effectPosX = yl.WIDTH * 0.32
        effectPosY = yl.HEIGHT * 0.1
    elseif cmd.TOP_VIEWID == outViewId then
        center = outCount / 2
        holder:setAnchorPoint(cc.p(0.5, 0.5))
        targetPos = holder:convertToNodeSpace(cc.p(controlSize.width * 0.48, controlSize.height * 0.72))
        effectPosX = 0
        effectPosY = yl.HEIGHT * 0.3
    end
    effectPosX = 0
    effectPosY = yl.HEIGHT * 0.05
    for k,v in pairs(vecCards) do
        v:retain()
        v:removeFromParent()
        holder:addChild(v)
        v:release()

        v:showCardBack(false)
        local pos = cc.p((k - center) * CardsNode.CARD_X_DIS * scale + targetPos.x, targetPos.y)
        local moveTo = cc.MoveTo:create(0.3, pos)
        local spa = cc.Spawn:create(moveTo, cc.ScaleTo:create(0.3, scale))
        v:stopAllActions()
        v:runAction(spa)
    end

    --print("## 出牌类型")
    --print(cardType)
    --print("## 出牌类型")
    local headitem = self.m_tabUserItem[outViewId]
    if nil == headitem then
        print("===== outCardEffect headitem ====",nil)
        return
    end
    local deleyTime = 0.35
    -- 牌型音效
    local bCompare = self:getParentNode().m_bLastCompareRes
    bCompare = false
    print("===== outCardEffect cardType ====",cardType)
    if GameLogic.CT_SINGLE == cardType then
        -- 音效
        local poker = yl.POKER_VALUE[outCards[1]]
        print("===== outCardEffect poker ====",poker)
        if nil ~= poker then
            ExternalFun.playSoundEffect(""..headitem.cbGender.."/"..poker .. ".wav", headitem.m_userItem) 
        end        
    else
        if bCompare then
            -- 音效
            ExternalFun.playSoundEffect(""..headitem.cbGender.."/".."ya" .. math.random(0, 1) .. ".wav", headitem.m_userItem) 
        else
            -- 音效
            print("===== outCardEffect type "..cardType.." ")
            ExternalFun.playSoundEffect( ""..headitem.cbGender.."/".."type" .. cardType .. ".wav", headitem.m_userItem)
        end
    end

    -- 牌型动画/牌型音效
    if GameLogic.CT_THREE_TAKE_ONE == cardType or GameLogic.CT_THREE_TAKE_TWO == cardType then
        cardType = GameLogic.CT_THREE_TAKE_ONE
    end

    if GameLogic.CT_THREE_LINE_TAKE_ONE == cardType or GameLogic.CT_THREE_LINE_TAKE_TWO == cardType then
        cardType = GameLogic.CT_THREE_LINE_TAKE_ONE
    end


    if GameLogic.CT_BOMB_CARD == cardType or GameLogic.CT_510K_FALSE == cardType or GameLogic.CT_510K_TRUE == cardType then          -- 炸弹
            ExternalFun.playSoundEffect( "common_bomb.wav" ) 
            cardType = GameLogic.CT_510K_FALSE
    end
    --if GameLogic.CT_SINGLE ~= cardType and GameLogic.CT_510K_FALSE ~= cardType and GameLogic.CT_510K_TRUE ~= cardType then 

    --end
    if cardType >= GameLogic.CT_510K_FALSE and cardType <= GameLogic.CT_BOMB_CARD then
        deleyTime = 0.04
    end
    local anim = cc.AnimationCache:getInstance():getAnimation("cardEffectAnim"..cardType)

    if nil ~= anim then
        self.m_csbNode:removeChildByTag(TAG.Tag_CardsEffct)
        local sp =  cc.Sprite:create("card_res/cardEffect"..cardType..".png", cc.rect(0, 0, 470, 156))
        sp:setPosition(effectPosX, effectPosY)
        sp:setTag(TAG.Tag_CardsEffct)
        self.m_csbNode:addChild(sp, TAG_ZORDER.EFFECT_ZORDER)
        local call1 = cc.CallFunc:create(function()
            sp:removeFromParent()
        end)
        sp:runAction(cc.Sequence:create(cc.Animate:create(anim), cc.DelayTime:create(deleyTime), call1))
    end
end

function GameViewLayer:onChangePassBtnState( bEnable )
    self.m_bt_pass:setEnabled(bEnable)
    if bEnable then
        self.m_bt_pass:setOpacity(255)
    else
        self.m_bt_pass:setOpacity(125)
    end
end

function GameViewLayer:changeBtnState( targetBtn, bEnable )
    if nil == targetBtn then
        return
    end
    --print("changeBtnState",bEnable)
    targetBtn:setEnabled(bEnable)
    if bEnable then
        targetBtn:setOpacity(255)
    else
        targetBtn:setOpacity(125)
    end
end

function GameViewLayer:onPassOutCard()
    --print("---------- onPassOutCard ------------")
    self:getParentNode():sendOutCard({}, true)
    self.m_tabNodeCards[cmd.MY_VIEWID]:reSetCards()
    ExternalFun.playSoundEffect( ""..self:getParentNode():GetMeUserItem().cbGender.."/".."pass" .. math.random(0, 1) .. ".wav", self:getParentNode():GetMeUserItem())
    --self.m_onGameControl:setVisible(false)
    -- 提示
   -- self.m_spInfoTip:setSpriteFrame("blank.png")
    -- 显示不出
    --[[
    local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("game_nooutcard.png")
    if nil ~= frame then
        self.m_tabStateSp[cmd.MY_VIEWID]:setSpriteFrame(frame)
    end

    -- 音效
    
    --]]
end

function GameViewLayer:getUserNick( viewId )
    if nil ~= self.m_tabUserHead[viewId] then
        return self.m_tabUserHead[viewId].m_userItem.szNickName
    end
    return ""
end

------
-- 扑克代理

-- 扑克状态变更
-- @param[cbCardData]       扑克数据
-- @param[status]           状态(ture:选取、false:非选取)
-- @param[cardsNode]        扑克节点
function GameViewLayer:onCardsStateChange( cbCardData, status, cardsNode )

end

-- 扑克选择
-- @param[selectCards]      选择扑克
-- @param[cardsNode]        扑克节点
function GameViewLayer:onSelectedCards( selectCards, cardsNode )
    -- 出牌对比
    self.m_tabSelectCards = selectCards
    local outCards = self:getParentNode().m_tabCurrentCards
    local outCount = #outCards

    local selectCount = #selectCards
    local selectType = GameLogic:GetCardType(selectCards, selectCount)

    --print("------------- onSelectedCards selectType -----------",selectType,outCount,self.m_bCanOutCard)
    --dump(outCards, "------------- outCards  -----------", 6)
    local enable = false
    local opacity = 125

    if 0 == outCount then
        if true == self.m_bCanOutCard and GameLogic.CT_ERROR ~= selectType then
            enable = true
            opacity = 255
        end        
    elseif GameLogic:CompareCard(outCards, outCount, selectCards, selectCount) and true == self.m_bCanOutCard then
        enable = true
        opacity = 255
    end

    self.m_bt_outCard:setEnabled(enable)
    self.m_bt_outCard:setOpacity(opacity)
end

-- 牌数变动
-- @param[outCards]         出牌数据
-- @param[cardsNode]        扑克节点
function GameViewLayer:onCountChange( count, cardsNode, isOutCard )
    isOutCard = isOutCard or false
    local viewId = cardsNode.m_nViewId
    if nil ~= self.m_tabCardCount[viewId] then
        self.m_tabCardCount[cardsNode.m_nViewId]:setString(count .. "")
    end

    if count <= 2 and nil ~= self.m_tabSpAlarm[viewId] and isOutCard then
        local param = AnimationMgr.getAnimationParam()
        param.m_fDelay = 0.1
        param.m_strName = Define.ALARM_ANIMATION_KEY
        local animate = AnimationMgr.getAnimate(param)
        local rep = cc.RepeatForever:create(animate)
        self.m_tabSpAlarm[viewId]:runAction(rep)
        -- 音效
        ExternalFun.playSoundEffect( "common_alert.wav" )
    end
end

------
-- 扑克代理

-- 提示出牌
-- @param[bOutCard]        是否出牌
function GameViewLayer:onPromptOut( bOutCard )
    bOutCard = bOutCard or false
    if bOutCard then
        local promptCard = self:getParentNode().m_tabPromptCards
        local promptCount = #promptCard
        if promptCount > 0 then
            promptCard = GameLogic:SortCardList(promptCard, promptCount, 0)

            -- 扑克对比
            self:getParentNode():compareWithLastCards(promptCard, cmd.MY_VIEWID)

            local vec = self.m_tabNodeCards[cmd.MY_VIEWID]:outCard(promptCard)
            self:outCardEffect(cmd.MY_VIEWID, promptCard, vec)
            self:getParentNode():sendOutCard(promptCard)
            --dump(promptCard, "---- 提示自动出牌 ----", 6)
            --self.m_onGameControl:setVisible(false)
        else
            self:onPassOutCard()
            self:hideOutCardsBtns()
        end
    else
        if 0 >= self.m_promptIdx then
            self.m_promptIdx = #self:getParentNode().m_tabPromptList
        end

        if 0 ~= self.m_promptIdx then
            -- 提示回位
            local sel = self.m_tabNodeCards[cmd.MY_VIEWID]:getSelectCards()
            if #sel > 0 
                and self.m_tabNodeCards[cmd.MY_VIEWID].m_bSuggested
                and #self:getParentNode().m_tabPromptList > 1 then
                self.m_tabNodeCards[cmd.MY_VIEWID]:suggestShootCards(sel)
            end
            -- 提示扑克
            local prompt = self:getParentNode().m_tabPromptList[self.m_promptIdx]
            print("## 提示扑克")
            for k,v in pairs(prompt) do
                print(yl.POKER_VALUE[v])
            end
            print("## 提示扑克")
            if table.nums(prompt) > 0 then
                self.m_tabNodeCards[cmd.MY_VIEWID]:suggestShootCards(prompt)
            else
                self:onPassOutCard()
            end
            self.m_promptIdx = self.m_promptIdx - 1
        else
            self:onPassOutCard()
            self:hideOutCardsBtns()
        end
    end
end

function GameViewLayer:onGameTrusteeship( bTrusteeship )
    self.m_trusteeshipBg:setVisible(bTrusteeship)
    self:hideOutCardsBtns() 
    if bTrusteeship then
        if self.m_bMyCallBanker then
            self.m_bMyCallBanker = false
            --self.m_callScoreControl:setVisible(false)
           -- self:getParentNode():sendCallScore(255)
           self:hideOutCardsBtns()          
        end

        if self.m_bMyOutCards then
            self.m_bMyOutCards = false
            --self:onPromptOut(true)
        end
    end
end

function GameViewLayer:updateClock( clockId, cbTime)
    self.m_time_num:setString( string.format("%02d", cbTime ))
    if cbTime <= 0 then
        if cmd.TAG_COUNTDOWN_READY == clockId then
            --退出防作弊
            self:getParentNode():getFrame():setEnterAntiCheatRoom(false)
        elseif cmd.TAG_COUNTDOWN_DECLAREWAR == clockId then --宣战阶段时间到直接退出
            -- 私人房无自动托管
            if not GlobalUserItem.bPrivateRoom and self.m_nCountDownView == cmd.MY_VIEWID then
                --self:onGameTrusteeship(true)
                self._scene:onExitTable()
            end
        elseif cmd.TAG_COUNTDOWN_ADD_TIMES == clockId then --宣战阶段时间到直接退出
            -- 私人房无自动托管
            if not GlobalUserItem.bPrivateRoom and self.m_nCountDownView == cmd.MY_VIEWID then
                --self:onGameTrusteeship(true)
                self._scene:onExitTable()
            end            
        elseif cmd.TAG_COUNTDOWN_OUTCARD == clockId then
            -- 私人房无自动托管
            if not GlobalUserItem.bPrivateRoom  and self.m_nCountDownView == cmd.MY_VIEWID then
                self.m_bTrustee = true
                self:onGameTrusteeship(self.m_bTrustee)
                self._scene:sendTrustees(1)
            end
        end
    end
end

function GameViewLayer:OnUpdataClockView( viewId, cbTime )
    self.m_time_bg:setVisible(cbTime ~= 0)
    if viewId <= cmd.PLAYER_COUNT then
        --[[
        print("-------- OnUpdataClockView ---------", self.m_nCountDownView,viewId)
        local lastAngle = timeBgAngle[self.m_nCountDownView]
        local curAngle = timeBgAngle[viewId]
        local angle = curAngle - lastAngle  
        
        if angle > 0 then
            angle = -(360 - angle)
        end
        
        print("------- OnUpdataClockView angle --------", angle)
        self.m_time_bg:runAction(cc.RotateBy:create(0.5,angle))
        self.m_time_num:runAction(cc.RotateBy:create(0.5,-angle))
        --]]
        --self.m_time_num:runAction(cc.RotateBy:create(0.5,-angle))
        self.m_time_bg:setRotation(timeBgAngle[viewId])
        self.m_time_num:setRotation(-self.m_time_bg:getRotation())
    else
        self.m_time_bg:setRotation(0)
        self.m_time_num:setRotation(0)
    end
    --print("------OnUpdataClockView",viewId,timeBgAngle[viewId])
    if viewId ~= cmd.INVALID_CHAIRID then
        self.m_nCountDownView = viewId
    end
    self.m_time_num:setString( string.format("%02d", cbTime ))

    if self:getParentNode():IsValidViewID(viewId) then
        --self.m_time_bg:setPosition(self.m_tabTimerPos[viewId])
    end
end
------------------------------------------------------------------------------------------------------------
--更新
------------------------------------------------------------------------------------------------------------

-- 文本聊天
function GameViewLayer:onUserChat(chatdata, viewId)
    local roleItem = self.m_tabUserHead[viewId]
    if nil ~= roleItem then
        roleItem:textChat(chatdata.szChatString)
    end
end

-- 表情聊天
function GameViewLayer:onUserExpression(chatdata, viewId)
    local roleItem = self.m_tabUserHead[viewId]
    if nil ~= roleItem then
        roleItem:browChat(chatdata.wItemIndex)
    end
end

-- 语音聊天
function GameViewLayer:onUserVoice(filepath, viewId)
    local roleItem = self.m_tabUserHead[viewId]
    if nil ~= roleItem then
        roleItem:voiceChat(filepath)
    end
end
function GameViewLayer:removeHead(viewId)
    local head_bg = self.m_csbNode:getChildByName(string.format("head_bg_%d", viewId))
    head_bg:setVisible(false)
    head_bg:removeChildByTag(TAG.Tag_Head)
    self.m_tabUserItem[viewId] = nil
    self:onUserReady(viewId, false)
    self.m_tabNodeCards[viewId]:setVisible(false)
    self.m_historyScore[viewId].lTurnScore = 0
    self.m_historyScore[viewId].lCollectScore = 0
end
-- 用户更新
function GameViewLayer:OnUpdateUser(viewId, userItem, bLeave)
    --print(" update user " .. viewId)
    local head_bg = self.m_csbNode:getChildByName(string.format("head_bg_%d", viewId))
    local head = head_bg:getChildByTag(TAG.Tag_Head)
    print("==== OnUpdateUser head nil  ====:",head == nil)
    if nil == userItem then
        if bLeave then
            self:removeHead(viewId)
        else
            if nil ~= head then
                print("==== head:setVisible  ====:")
                --head:setVisible(false)
                convertToGraySprite(head.m_head.m_spRender)
                --head.m_head:setColor(cc.c3b(127,127,127))
            end        
        end
        return
    end
    
    print("--- OnUpdateUser  userItem.cbUserStatus ---",userItem.cbUserStatus,userItem.lScore)
    if bLeave and userItem.cbUserStatus == yl.US_FREE then
        self:removeHead(viewId)
    elseif userItem.cbUserStatus == yl.US_OFFLINE then
        if nil ~= head then
            --head:setVisible(false)
            print("==== head:setVisible US_OFFLINE ====:")
            convertToGraySprite(head.m_head.m_spRender)
            --head.m_head:setColor(cc.c3b(127,127,127))
        end
    elseif userItem.cbUserStatus == yl.US_PLAYING then
        if nil ~= head then
            print("==== head:setVisible  US_PLAYING====:")
            convertToNormalSprite(head.m_head.m_spRender)
            --head:setVisible(true)
            --head.m_head:setColor(cc.c3b(255,255,255))
        end      
    end

    --[[
    local bHide = ((table.nums(self.m_tabUserHead)) == (self:getParentNode():getFrame():GetChairCount()))
    if not GlobalUserItem.bPrivateRoom then
        self.m_btnInvite:setVisible(not bHide)
        self.m_btnInvite:setEnabled(not bHide)
    end  
    --]]  
    self.m_btnInvite:setVisible(false)
    self.m_btnInvite:setEnabled(false)

    
    

    local bReady = userItem.cbUserStatus == yl.US_READY
    self:onUserReady(viewId, bReady)

    --print(string.format("-------------viewid %d userItem.wChairId %d--------------", viewId ,userItem.wChairID ))
    if nil == self.m_tabUserItem[viewId] then
        self.m_tabUserItem[viewId] = userItem
        self.m_tabUserItemCopy[viewId] = userItem
        head_bg:setVisible(true)
        self.m_historyUseItem[viewId] = self.m_tabUserItem[viewId]
        local head = PopupInfoHead:createNormal(userItem, 82)
        --head:enableInfoPop(true, popPosition[viewId], popAnchor[viewId])
        head:enableInfoPop(true, self.m_tabPopHeadPos[viewId], self.m_tabPopHeadAnchorPoint[viewId])
        head:setTag(TAG.Tag_Head)
        head:setPosition(cc.p(45,45))
        head:setLocalZOrder(TAG.Tag_Head)
        --head:enableHeadFrame(true, {_framefile = "land_headframe.png", _zorder = -1, _scaleRate = 0.75, _posPer = cc.p(0.5, 0.63)})
        head_bg:addChild(head)
        local text_nickName = head_bg:getChildByName("text_nickName")

        text_nickName:setString(userItem.szNickName)
        if GlobalUserItem.isAntiCheat() and viewId ~= cmd.MY_VIEWID then
            text_nickName:setString("玩家"..viewId)
        end
        --玩家当前金币数
        local player_score = head_bg:getChildByName("player_score")
        player_score:setString(string.format("%d",userItem.lScore))
        --玩家当前游戏得分
        local text_curScore = head_bg:getChildByName("text_curScore")
        text_curScore:setString("当前得分:0")
    else
        self.m_tabUserItem[viewId] = userItem

        local player_score = head_bg:getChildByName("player_score")
        player_score:setString(string.format("%d",userItem.lScore))
        if nil ~= head and userItem.cbUserStatus ~= yl.US_OFFLINE then

            print("==== head:setVisible  US_PLAYING2====:")
            convertToNormalSprite(head.m_head.m_spRender)
        end 

    end
	
    if cmd.MY_VIEWID == viewId then
        self:reSetUserInfo()
    end
	
	if PriRoom and GlobalUserItem.bPrivateRoom then
		if userItem.dwUserID == PriRoom:getInstance().m_tabPriData.dwTableOwnerUserID then
		local img_pri_own = head_bg:getChildByName("img_pri_own")
		img_pri_own:setVisible(true)
		end
	end
end

function GameViewLayer:onUserReady(viewId, bReady)
    --用户准备
    local tip_ready = self.m_csbNode:getChildByName(string.format("tip_ready_%d", viewId))
        
    if bReady then
        tip_ready:setVisible(true)
    else
        tip_ready:setVisible(false)
    end
end

function GameViewLayer:onGetCellScore( score )
    score = score or 0
    local str = ""
    if score < 0 then
        str = "." .. score
    else
        str = "" .. score        
    end 
    if string.len(str) > 11 then
        str = string.sub(str, 1, 11)
        str = str .. "///"
    end  
    --self.m_atlasDiFeng:setString(str) 
end

function GameViewLayer:onGetGameFree()
    --print(string.format("------------------bEnterAntiCheatRoom-----------------", tostring(self:getParentNode():getFrame().bEnterAntiCheatRoom)))
    if false == self:getParentNode():getFrame().bEnterAntiCheatRoom and not GlobalUserItem.isAntiCheat() then
        self.m_btnReady:setEnabled(true)
        self.m_btnReady:setVisible(true)
    end
    self:updateRule()
    --self:openFindRriendLayer()    
end

function GameViewLayer:onGameStart()
    --self:resetTotalScore()
    self:updateRule()
    self.m_round_outTotalScore = self.m_csbNode:getChildByName("round_outTotalScore")
    self.m_round_outTotalScore:setString("0")
    for i = 1 ,cmd.PLAYER_COUNT do 
        tabCardsHandCount [i] =  cmd.NORMAL_COUNT
        local viewId = self._scene:SwitchViewChairID(i - 1)
        local head_bg = self.m_csbNode:getChildByName(string.format("head_bg_%d", viewId))
        local heart = head_bg:getChildByName("heart")
        heart:setVisible(false)
        if viewId ~= cmd.MY_VIEWID then
            self:updateCardsNodeLayout(viewId, 0, false)
            self.m_tabAlertSp[viewId]:setVisible(false)
        else
            self.m_cardNum1:setString(string.format("%d", 0))
            self.m_cardNum1:setVisible(false)
        end
        --self.m_tabNodeCards[i]:setCardsCount(cmd.NORMAL_COUNT)
        --self.m_tabNodeCards[i]:setVisible(true)

        local tip_operate = self.m_csbNode:getChildByName(string.format("tip_operate_%d", i))
        tip_operate:setVisible(false)

        local tip_addTime = self.m_csbNode:getChildByName(string.format("tip_addTime_%d", i))
        tip_addTime:setVisible(false)

        self.m_outCardsControl:removeChildByTag(i)
        local text_curScore = head_bg:getChildByName("text_curScore")
        text_curScore:setString("当前得分:0")
    end

    self.m_historyUseItem =  self.m_tabUserItem 
    if self.m_nRoundCount == 0 then
        self:initHistoryScore()
    end
    
    self.m_nCurTotalScore = 0

    self.m_nMaxCallScore = 0
    if self._scene.m_wCurrentUser == self.m_wChairId then
        --self:presentDeclareWarBtns()
    end

    local handCards = self.m_tabNodeCards[1]:getHandCards()
    --self.m_cardNum1:setVisible(true)
    --self.m_cardNum1:setString(string.format("%d", #handCards))

    --庄家s
    local bankView = self._scene:SwitchViewChairID(self._scene.m_wBankerUser)
    local head_bg = self.m_csbNode:getChildByName(string.format("head_bg_%d", bankView))
    local heart = head_bg:getChildByName("heart")
    heart:setVisible(true)
    --[[
    self.m_spInfoTip:setSpriteFrame("blank.png")
    for k,v in pairs(self.m_tabStateSp) do
        v:stopAllActions()
        v:setSpriteFrame("blank.png")
    end

    for k,v in pairs(self.m_tabCardCount) do
        v:setString("")
    end
    self.m_promptIdx = 0
    --]]
end

function GameViewLayer:onGameDeclareWar(wUser,bDeclare)

    if true == bDeclare then --有人宣战
        local declareWarView = self._scene:SwitchViewChairID(wUser)
        local declareWarHead_bg = self.m_csbNode:getChildByName(string.format("head_bg_%d", declareWarView))
        local declarePlayer_status = declareWarHead_bg:getChildByName("player_status")
        declarePlayer_status:setVisible(true)
        declarePlayer_status:loadTexture("game_res/head_fight.png")
        if wUser == self.m_wChairId then
            for i = 1, 4 do
                if i ~= declareWarView then
                    local head_bg = self.m_csbNode:getChildByName(string.format("head_bg_%d", i))
                    local player_status = head_bg:getChildByName("player_status")
                    player_status:loadTexture("game_res/head_enemy.png")
                    player_status:setVisible(true)
                end
            end

        else
            for i = 1, 4 do
                if i ~= declareWarView then
                    local head_bg = self.m_csbNode:getChildByName(string.format("head_bg_%d", i))
                    local player_status = head_bg:getChildByName("player_status")
                    player_status:loadTexture("game_res/head_league.png")
                    player_status:setVisible(true)
                end
            end
        end
        --[[
        if self._scene.m_wCurrentUser == self.m_wChairId then
            -- 不出按钮
            
            self:onChangePassBtnState(false)
            local handCards = self.m_tabNodeCards[cmd.MY_VIEWID]:getHandCards()
            self._scene:updatePromptList({}, handCards, cmd.MY_VIEWID, cmd.MY_VIEWID)
            -- 开始出牌
            self:onGetOutCard(1, 1, {})
            self:presentOutCardsBtns()
            
        end
        --]]
    else --三次未宣战 找同盟
        if self._scene.m_wCurrentUser == self.m_wChairId then
            self:openFindRriendLayer()
        end
    end
    
    --local startView = self._scene:SwitchViewChairID(self._scene.m_wCurrentUser)

end

function GameViewLayer:onGameAskFriend(dataBuffer) 
    if true == dataBuffer.bAsk then
        local wFriend = dataBuffer.wFriend[1]
        local wMyFriend = wFriend[self.m_wChairId + 1]
        for i = 1, cmd.PLAYER_COUNT do
            local viewId = self._scene:SwitchViewChairID(i - 1)
            local head_bg = self.m_csbNode:getChildByName(string.format("head_bg_%d", viewId))
            local player_status = head_bg:getChildByName("player_status")
            player_status:setVisible(true)

            if (i - 1) == self.m_wChairId then

                if self._scene.m_cbFriendFlag == 3 then 
                    if (i - 1) == self._scene.m_wBankerUser then
                        player_status:loadTexture("game_res/head_mingDu.png")
                    else
                        player_status:loadTexture("game_res/head_league.png")
                    end
                else
                    player_status:loadTexture("game_res/head_league.png")
                end
            else
                if self._scene.m_cbFriendFlag == 3 then 
                    if (i - 1) == self._scene.m_wBankerUser then
                        player_status:loadTexture("game_res/head_mingDu.png")
                    else
                        if self.m_wChairId == self._scene.m_wBankerUser then
                            player_status:loadTexture("game_res/head_enemy.png")
                        else
                            player_status:loadTexture("game_res/head_league.png")
                        end
                    end
                else
                    if (i - 1 == wMyFriend) then
                        player_status:loadTexture("game_res/head_league.png")
                    else
                        player_status:loadTexture("game_res/head_enemy.png")
                    end
                end
            end
        end
    else
        for i = 1, cmd.PLAYER_COUNT do
            local viewId = self._scene:SwitchViewChairID(i - 1)
            local head_bg = self.m_csbNode:getChildByName(string.format("head_bg_%d", viewId))
            local player_status = head_bg:getChildByName("player_status")
            player_status:setVisible(true)
            if(i - 1) == self.m_wChairId then -- (i - 1 == wMyFriend) or 
                if (i - 1) == self._scene.m_wBankerUser and self._scene.m_cbFriendFlag ~= 1 and self._scene.m_cbFriendFlag ~= 3 and self._scene.m_cbFriendFlag ~= 4 then
                    player_status:loadTexture("game_res/head_anDu.png")
                else
                    player_status:loadTexture("game_res/head_unknow.png")
                end
            else
                --if self.m_wChairId == self._scene.m_wBankerUser and self._scene.m_cbFriendFlag == 2 then
                    --player_status:loadTexture("game_res/head_enemy.png")
                --else
                    player_status:loadTexture("game_res/head_unknow.png")
                --end
                
            end
        end
    end
    
end

function GameViewLayer:onGameAddTimes(dataBuffer) 
    local wAddTimesUser =  dataBuffer.wAddTimesUser
    local addViewId = self._scene:SwitchViewChairID(wAddTimesUser)
    if dataBuffer.bAddTimes then
        local tip_addTime = self.m_csbNode:getChildByName(string.format("tip_addTime_%d", addViewId))
        tip_addTime:setVisible(true)
    else
        local tip_no_addTime = self.m_csbNode:getChildByName(string.format("tip_no_addTime_%d", addViewId))
        tip_no_addTime:setVisible(true)
    end 
end

function GameViewLayer:SetFriendFlag(wChairID, cbFlag)
    if wChairID  == cmd.INVALID_CHAIRID then
        self._scene.m_tab_cbFriendFlag = {}
    else
        self._scene.m_tab_cbFriendFlag[wChairID + 1] = cbFlag
    end
end

function GameViewLayer:SetAddTimes(wChairID, bAddTimes)
    if wChairID  == cmd.INVALID_CHAIRID then
        self._scene.m_tab_cbAddTimesFlag = {}
    else
        if true == bAddTimes then
            self._scene.m_tab_cbAddTimesFlag[wChairID + 1] = 1
        else
            self._scene.m_tab_cbAddTimesFlag[wChairID + 1] = 2
        end
    end
        
end

function GameViewLayer:SetFriendFlag2(tabFriend,wXuanZhanUser)
    local wFriend = tabFriend
    local wMyFriend = wFriend[self.m_wChairId + 1]
    print("SetFriendFlag2:",self.m_wChairId)
    if wXuanZhanUser ~= cmd.INVALID_CHAIRID then
        local xuanZhanViewId = self._scene:SwitchViewChairID(wXuanZhanUser)
        print("--- xuanZhanViewId---",xuanZhanViewId)
        for i = 1, cmd.PLAYER_COUNT do
            local viewId = self._scene:SwitchViewChairID(i - 1)
            local head_bg = self.m_csbNode:getChildByName(string.format("head_bg_%d", viewId))
            local player_status = head_bg:getChildByName("player_status")
            player_status:setVisible(true)
            if xuanZhanViewId == cmd.MY_VIEWID then
                if viewId == cmd.MY_VIEWID then
                    if self._scene.m_cbFriendFlag == 2 then
                        player_status:loadTexture("game_res/head_anDu.png")
                    elseif self._scene.m_cbFriendFlag == 3 then
                        player_status:loadTexture("game_res/head_mingDu.png")
                    else
                        player_status:loadTexture("game_res/head_fight.png")
                    end
                else
                    player_status:loadTexture("game_res/head_enemy.png")
                end
            else
                if viewId == xuanZhanViewId then
                    if self._scene.m_cbFriendFlag == 2 then
                        player_status:loadTexture("game_res/head_unknow.png")
                    elseif self._scene.m_cbFriendFlag == 3 then
                        player_status:loadTexture("game_res/head_mingDu.png")
                    else
                        player_status:loadTexture("game_res/head_fight.png")
                    end
                else
                    if self._scene.m_cbFriendFlag == 3 then
                        player_status:loadTexture("game_res/head_league.png")
                    elseif self._scene.m_cbFriendFlag == 1 then
                        player_status:loadTexture("game_res/head_league.png")
                    else
                        player_status:loadTexture("game_res/head_unknow.png")
                    end
                end
            end
        end
    else
        if self._scene.m_cbFriendFlag ~= 1 and self._scene.m_cbFriendFlag ~= 3 and self._scene.m_cbFriendFlag ~= 4 then
            for i = 1, cmd.PLAYER_COUNT do
                local viewId = self._scene:SwitchViewChairID(i - 1)
                local head_bg = self.m_csbNode:getChildByName(string.format("head_bg_%d", viewId))
                local player_status = head_bg:getChildByName("player_status")
                player_status:setVisible(true)

                player_status:loadTexture("game_res/head_unknow.png")
            end 
        else
            for i = 1, cmd.PLAYER_COUNT do
                local viewId = self._scene:SwitchViewChairID(i - 1)
                local head_bg = self.m_csbNode:getChildByName(string.format("head_bg_%d", viewId))
                local player_status = head_bg:getChildByName("player_status")
                player_status:setVisible(true)

                if self._scene.m_cbFriendFlag == 3 then
                    if (i - 1) == self._scene.m_wBankerUser then
                        player_status:loadTexture("game_res/head_mingDu.png")
                    else
                        if (i -1) == self.m_wChairId then
                            player_status:loadTexture("game_res/head_league.png")
                        else
                            if self.m_wChairId == self._scene.m_wBankerUser then
                                player_status:loadTexture("game_res/head_enemy.png")
                            else
                                player_status:loadTexture("game_res/head_league.png")
                            end
                        end
                    end
                else
                    if (i - 1 == wMyFriend) or (i -1) == self.m_wChairId then
                        player_status:loadTexture("game_res/head_league.png")
                    else
                        player_status:loadTexture("game_res/head_enemy.png")
                    end
                end    
            end 
        end
        
    end 
end

-- 获取到扑克数据
-- @param[viewId] 界面viewid
-- @param[cards] 扑克数据
-- @param[bReEnter] 是否断线重连
-- @param[pCallBack] 回调函数
function GameViewLayer:onGetGameCard(viewId, cards, bReEnter, pCallBack)
    print("================ onGetGameCard ================",viewId, cards, bReEnter)
    if viewId == cmd.MY_VIEWID then
        self:findBlackFive(cards)
    end
    if bReEnter then
        self.m_tabNodeCards[viewId]:updateCardsNode(cards, (viewId == cmd.MY_VIEWID), false)
    else
        if nil ~= pCallBack then
            pCallBack:retain()
        end
        local call = cc.CallFunc:create(function()
            -- 非自己扑克
            local empTyCard = GameLogic:emptyCardList(cmd.NORMAL_COUNT)
            self.m_tabNodeCards[cmd.LEFT_VIEWID]:updateCardsNode(cards, true, true)
            empTyCard = GameLogic:emptyCardList(cmd.NORMAL_COUNT)
            self.m_tabNodeCards[cmd.RIGHT_VIEWID]:updateCardsNode(cards, true, true)
            self.m_tabNodeCards[cmd.TOP_VIEWID]:updateCardsNode(cards, true, true)

            -- 自己扑克
            self.m_tabNodeCards[cmd.MY_VIEWID]:updateCardsNode(cards, true, true, pCallBack)

            -- 庄家扑克
            -- 50 525
            -- 50 720
            for k,v in pairs(self.m_tabBankerCard) do
                v:setVisible(true)
            end
        end)
        local call2 = cc.CallFunc:create(function()
            -- 音效
            --ExternalFun.playSoundEffect( "dispatch.wav" )
        end)
        local seq = cc.Sequence:create(call2, cc.DelayTime:create(0.3), call)
        self:stopAllActions()
        self:runAction(seq)
    end
end


-- 用户出牌
-- @param[curViewId]        当前出牌视图id
-- @param[lastViewId]       上局出牌视图id
-- @param[lastOutCards]     上局出牌
-- @param[bRenter]          是否断线重连
function GameViewLayer:onGetOutCard(curViewId, lastViewId, lastOutCards, bReEnter)
    bReEnter = bReEnter or false
    self.m_outCardsControl:removeChildByTag(curViewId)
    if curViewId ~= cmd.INVALID_CHAIRID then
        self.m_bMyOutCards = (curViewId == cmd.MY_VIEWID)
        --[[
        if nil ~= self.m_tabStateSp[curViewId] then
            self.m_tabStateSp[curViewId]:setSpriteFrame("blank.png")
        end
        --]]
        for k,v in pairs (lastOutCards) do
            local turnScore = 0
            local logicValue = GameLogic:GetCardLogicValue(v) 
            if logicValue == 0x05 then
                    turnScore = 5
            elseif logicValue == 0x0A then
                    turnScore = 10
            elseif logicValue == 0x0D then
                    turnScore = 10
            end
            self.m_nCurTotalScore = self.m_nCurTotalScore + turnScore
        end
        self.m_round_outTotalScore:setString(string.format("%d", self.m_nCurTotalScore))
    -- 自己出牌
        if lastViewId == cmd.MY_VIEWID then
            local handCards = self.m_tabNodeCards[1]:getHandCards()
            self.m_cardNum1:setVisible(false)
            self.m_cardNum1:setString(string.format("%d", #handCards))
            --算出牌分
            
            
        else
            local outCardsCount = #lastOutCards
            if nil == lastOutCards then
                outCardsCount = 0
            end
            --[[
            local m_nodeCard = self.m_tabNodeCards[lastViewId]--if self
            if 0 ~= outCardsCount then
                self:updateCardsNodeLayout(lastViewId, m_nodeCard:getCardsCount(), true)
            end
            --]]
        end
        if curViewId == cmd.MY_VIEWID then
            if self.m_trusteeshipBg:isVisible() then--自动提示出牌
                --self:onPromptOut(true)
            else
            -- 移除上轮出牌
            --self.m_outCardsControl:removeChildByTag(curViewId)

            --self.m_onGameControl:setVisible(true)
                self:presentOutCardsBtns()
                self.m_bt_outCard:setEnabled(false)
                self.m_bt_outCard:setOpacity(125)

                local promptList = self:getParentNode().m_tabPromptList
                dump(promptList, "---------- promptList ---------", 6)
                self.m_bCanOutCard = (#promptList > 0)

            -- 出牌控制
                if not self.m_bCanOutCard then
                --self.m_spInfoTip:setSpriteFrame("game_tips_00.png")
                --self.m_spInfoTip:setPosition(yl.WIDTH * 0.5, 160)
                else
                    self.m_bt_outCard:setEnabled(true)
                    self.m_bt_outCard:setOpacity(255)
                    local sel = self.m_tabNodeCards[cmd.MY_VIEWID]:getSelectCards()
                    local selCount = #sel
                    if selCount > 0 then
                        local selType = GameLogic:GetCardType(sel, selCount)
                        if GameLogic.CT_ERROR ~= selType then
                            local lastOutCount = #lastOutCards
                            if lastOutCount == 0 then
                                self.m_bt_outCard:setEnabled(true)
                                self.m_bt_outCard:setOpacity(255)
                                elseif lastOutCount > 0 and GameLogic:CompareCard(lastOutCards, lastOutCount, sel, selCount) then
                                    self.m_bt_outCard:setEnabled(true)
                                    self.m_bt_outCard:setOpacity(255)
                                    elseif false == GameLogic:CompareCard(lastOutCards, lastOutCount, sel, selCount) then
                                        self.m_bt_outCard:setEnabled(false)
                                        self.m_bt_outCard:setOpacity(125)
                                    end
                                end
                            else
                                self.m_bt_outCard:setEnabled(false)
                                self.m_bt_outCard:setOpacity(125)
                            end
                --self.m_spInfoTip:setSpriteFrame("blank.png")
                        end
                    end
                end
            end

    -- 出牌消息

    if (lastViewId ~= cmd.MY_VIEWID or self.m_trusteeshipBg:isVisible() ) and #lastOutCards > 0  then
        ExternalFun.playSoundEffect( "sendcard.wav" )
        local vec = self.m_tabNodeCards[lastViewId]:outCard(lastOutCards, bReEnter)
        --dump(lastOutCards, "--------- lastOutCards ------------", 6)
        --dump(vec, "--------- vec ------------", 6)
        self:outCardEffect(lastViewId, lastOutCards, vec)
        if lastViewId == cmd.MY_VIEWID then
            local handCards = self.m_tabNodeCards[1]:getHandCards()
            self.m_cardNum1:setVisible(false)
            self.m_cardNum1:setString(string.format("%d", #handCards))
        end
    end
end

-- 用户pass
-- @param[passViewId]       放弃视图id
function GameViewLayer:onGetPassCard( dataBuffer )
    local passViewId = self._scene:SwitchViewChairID(dataBuffer.wPassCardUser)
    local winViewID = self._scene:SwitchViewChairID(dataBuffer.wTurnWinner)
    local curViewId = self._scene:SwitchViewChairID(dataBuffer.wCurrentUser)
    if passViewId ~= cmd.MY_VIEWID then
        local headitem = self.m_tabUserItem[passViewId]
        if nil ~= headitem then
            -- 音效
            ExternalFun.playSoundEffect( ""..headitem.cbGender.."/".."pass" .. math.random(0, 1) .. ".wav", headitem.m_userItem)
        end        
    end
    self.m_outCardsControl:removeChildByTag(passViewId)
    self.m_outCardsControl:removeChildByTag(curViewId)
    local tip_operate = self.m_csbNode:getChildByName(string.format("tip_operate_%d", passViewId))
    tip_operate:setVisible(true)
    -- 显示不出
    local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("game_nooutcard.png")
    if nil ~= frame then
        self.m_tabStateSp[passViewId]:setSpriteFrame(frame)
    end
    if 1 == dataBuffer.cbTurnOver then
        self.m_cbScore[winViewID] = self.m_cbScore[winViewID] + dataBuffer.cbTurnWinnerScore
        local head_bg = self.m_csbNode:getChildByName(string.format("head_bg_%d", winViewID))
        local text_curScore = head_bg:getChildByName("text_curScore")
        text_curScore:setString(string.format("当前得分:%d", dataBuffer.cbTurnWinnerScore))

        --算总分
        self.m_nCurTotalScore = self.m_nCurTotalScore + dataBuffer.cbTurnWinnerScore
        self.m_nCurTotalScore = 0
        self.m_round_outTotalScore:setString(string.format("%d", self.m_nCurTotalScore))
        for i = 1, cmd.PLAYER_COUNT do
            self.m_outCardsControl:removeChildByTag(i)
        end
    end  
end

-- 游戏结束
function GameViewLayer:onGetGameConclude( rs )
    -- 界面重置
    self.m_bTrustee = false
    self.m_bSelfDu = false 
    self.m_bHaveBlackFive = false
    self.m_nRoundCount = self.m_nRoundCount + 1
    self:reSetGame()
    self:hideOutCardsBtns()
    self:hideAddTimesBtns()
    self:hideAskFriendBtns()
    self:hideDeclareWarBtns()
    -- 取消托管
    --self.m_trusteeshipControl:setVisible(false)

    -- 显示准备
    self.m_btnReady:setEnabled(true)
    self.m_btnReady:setVisible(true)
    --历史记录
    self.m_wBankerUser = self._scene.m_wBankerUser
    self.m_lCellScore = rs.lCellScore
    self.m_cbBaseTimes = rs.cbBaseTimes
    self.m_lGameScore = rs.lGameScore[1]
    self.m_cbScore = rs.cbScore[1]
    --dump(self.m_lCollectScore, "----------- m_lCollectScore -----------", 6)
    --dump(self.m_historyScore, "----------- m_historyScore -----------", 6)
    --dump(rs.lGameScore, "----------- lGameScore -----------", 6)
    for i = 1 ,cmd.PLAYER_COUNT do
        local viewId = self._scene:SwitchViewChairID(i - 1)
        self.m_lCollectScore[i]  =  self.m_historyScore[viewId].lCollectScore + rs.lGameScore[1][i]
        local userItem = self.m_historyUseItem[viewId]
        if nil == userItem then
             userItem = self.m_tabUserItemCopy[viewId]
        end
        --self.m_tabDwUserID[viewId]  = userItem.dwUserID
        --历史成绩
        self.m_historyScore[viewId].lTurnScore = rs.lGameScore[1][i]
        self.m_historyScore[viewId].lCollectScore = self.m_historyScore[viewId].lCollectScore + rs.lGameScore[1][i]

        self.m_outCardsControl:removeChildByTag(viewId)
    end
    -- 取消托管
    if self.m_trusteeshipBg:isVisible() then
        self.m_trusteeshipBg:setVisible(false)
    end
    -- 结算
    if nil == self.m_resultLayer then
        self.m_resultLayer = ResultLayer:create(self,rs)
        self.m_resultLayer:setPosition(cc.p(680,410))
        self:addToRootLayer(self.m_resultLayer, TAG_ZORDER.RESULT_ZORDER)
    else
        self.m_resultLayer:showGameResult(rs)
    end

    self:updateHistoryScore()
    self.m_rootLayer:removeChildByName("__effect_ani_name__")
    for i = 1, cmd.PLAYER_COUNT do
        local viewId = self._scene:SwitchViewChairID(i - 1)
        local head_bg = self.m_csbNode:getChildByName(string.format("head_bg_%d", viewId))
        if nil ~= self.m_tabUserItem[viewId] then
            
            userItem = self.m_tabUserItem[i]
            --userItem.lScore = userItem.lScore + rs.lGameScore[1][i]
            local player_score = head_bg:getChildByName("player_score")
            player_score:setString(string.format("%d",userItem.lScore))
        ----------当前游戏得分
            --local text_curScore = head_bg:getChildByName("text_curScore")
            --text_curScore:setString("当前得分:0")
        else
            player_score:setString(0)
        end
        self.m_cbScore[i] = 0
    end
    --警报灯
    for i = 2, 4 do
        self.m_tabAlertSp[i]:setVisible(false)
    end
end

function GameViewLayer:updateRule()
    local str = "game_res/large_A.png"
    if self._scene.m_b2Biggest then
        str = "game_res/large_2.png"
    end
    self.m_txt_rule:setString(str)
    if  GlobalUserItem.bPrivateRoom then
        --self.m_txt_curDesk:setVisible(false)
        --self.left_bg_pri:setVisible(true)
        self.left_bg_normal:setVisible(false)

    else
        self.left_bg_pri:setVisible(false)
        self.left_bg_normal:setVisible(true)
        local room_id = self.left_bg_normal:getChildByName("room_id")
        room_id:setString(""..self.m_wTableId + 1)
        local img_rule = self.left_bg_normal:getChildByName("img_rule")
        img_rule:loadTexture(str)
    end  
end

function GameViewLayer:updateHistoryScore()
    local  record_bg = self.m_record_bg
    --dump(self.m_historyScore,"-------------- updateHistoryScore ---------------- ",6)
    for i = 1, cmd.PLAYER_COUNT do
        local viewId = self._scene:SwitchViewChairID(i - 1)
        local nickName = record_bg:getChildByName(string.format("nickName_%d", viewId))
        local userItem = self.m_historyUseItem[viewId]
        if nil ~= userItem then
            nickName:setString(self.m_historyUseItem[viewId].szNickName)
            self.m_tabRecordNickName[viewId]:setString(self.m_historyUseItem[viewId].szNickName)
        else
            nickName:setString("xx")
            self.m_tabRecordNickName[viewId]:setString("xx")
        end
        
        local lastRoundScore = record_bg:getChildByName(string.format("lastRoundScore_%d", viewId))
        lastRoundScore:setString(self.m_historyScore[viewId].lTurnScore)

        local totalScore = record_bg:getChildByName(string.format("totalScore_%d", viewId))
        totalScore:setString(self.m_historyScore[viewId].lCollectScore)
    end
end

function GameViewLayer:resetTotalScore()
    local  record_bg = self.m_record_bg

    for i = 1, 4 do
        local viewId = self._scene:SwitchViewChairID(i - 1)
        local totalScore = record_bg:getChildByName(string.format("totalScore_%d", viewId))
        totalScore:setString("0")
    end
end

function GameViewLayer:initHistoryScore()
    local  record_bg = self.m_record_bg
    --print(···)
    for i = 1, 4 do
        local viewId = self._scene:SwitchViewChairID(i - 1)
        local userItem = self.m_historyUseItem[viewId]
        local szNickName = ""
        if nil == userItem then
            szNickName = "玩家"..viewId
        else
            szNickName = userItem.szNickName
        end
        print("szNickName ",i,viewId,szNickName)
        local nickName = record_bg:getChildByName(string.format("nickName_%d", viewId))
        nickName:setString(szNickName)
        self.m_tabRecordNickName[viewId]:setString(szNickName)
        if GlobalUserItem.isAntiCheat() and viewId ~= cmd.MY_VIEWID then
            nickName:setString("玩家"..viewId)
            self.m_tabRecordNickName[viewId]:setString("玩家"..viewId)
        end
        
        local lastRoundScore = record_bg:getChildByName(string.format("lastRoundScore_%d", viewId))
        lastRoundScore:setString(0)

        local totalScore = record_bg:getChildByName(string.format("totalScore_%d", viewId))
        totalScore:setString(0)
    end
end

function GameViewLayer:setOperateTipVisible(viewId,bIsVisible)--不出提示
    local operateTip = self.m_csbNode:getChildByName(string.format("tip_operate_%d", viewId))
    operateTip:setVisible(bIsVisible)
end

function GameViewLayer:hideAskFriendBtns()
    self.m_bt_ask:setVisible(false)
    self.m_bt_no_ask:setVisible(false)
end

function GameViewLayer:presentAskFriendBtns()
    self.m_bt_ask:setVisible(true)
    if self.m_wChairId == self._scene.m_wBankerUser and self.m_bSelfDu == true  then --and self.m_bHaveBlackFive
        self:changeBtnState(self.m_bt_ask,false)
    else
        self:changeBtnState(self.m_bt_ask,true)
    end
    
    
    self.m_bt_no_ask:setVisible(true)
end

function GameViewLayer:presentDeclareWarBtns()
    self.m_bt_declareWar:setVisible(true)
    self.m_bt_no_declareWar:setVisible(true)
end

function GameViewLayer:hideDeclareWarBtns()
    self.m_bt_declareWar:setVisible(false)
    self.m_bt_no_declareWar:setVisible(false)
end

function GameViewLayer:presentOutCardsBtns()
    if self.m_trusteeshipBg:isVisible() then
        return
    end
    self.m_tabNodeCards[cmd.MY_VIEWID]:dragCards(self.m_tabNodeCards[cmd.MY_VIEWID]:filterDragSelectCards(false))
    self.m_tabNodeCards[cmd.MY_VIEWID]:dragCards({})
    self.m_bt_pass:setVisible(true)
    self.m_bt_tip:setVisible(true)
    self.m_bt_outCard:setVisible(true)
end

function GameViewLayer:hideOutCardsBtns()
    self.m_bt_pass:setVisible(false)
    self.m_bt_tip:setVisible(false)
    self.m_bt_outCard:setVisible(false)
end

function GameViewLayer:presentAddTimesBtns()
    self.m_bt_add:setVisible(true)
    self.m_bt_no_add:setVisible(true)
end

function GameViewLayer:hideAddTimesBtns()
    self.m_bt_add:setVisible(false)
    self.m_bt_no_add:setVisible(false)
end

function GameViewLayer:hideAllAddTimesTip()
    for i = 1, cmd.PLAYER_COUNT do
        local tip_addTime = self.m_csbNode:getChildByName(string.format("tip_addTime_%d", i))
        tip_addTime:setVisible(false)

        local tip_no_addTime = self.m_csbNode:getChildByName(string.format("tip_no_addTime_%d", i))
        tip_no_addTime:setVisible(false)
    end
end

function GameViewLayer:setTrusteeBtnEnable(bEnable)
    self.m_bt_trusteeship:setEnabled(bEnable)
end



function GameViewLayer:openFindRriendLayer()
    local tChooseLayer = ChooseLayer:create(self)
    tChooseLayer:setPosition(cc.p(680,200))
    tChooseLayer:setTag(TAG.Tag_FindFriend)
    self:addChild(tChooseLayer, Define.TAG_ZORDER.Choose_ZORDER)
end

function GameViewLayer:closeFindRriendLayer( )
    self:removeChildByTag(TAG.Tag_FindFriend)
end

function GameViewLayer:initCardsNodeLayout()
    for index = 2, cmd.PLAYER_COUNT do 
        local NodeCards = self.m_tabNodeCards[index]
        NodeCards:setVisible(false)
        NodeCards.m_cardsHolder:setVisible(false)
        local num = cc.Label:createWithCharMap("game_res/player_cardNum_small.png",29,38,string.byte("0"))
        num:setString(string.format("%d", 0))
        num:setTag(TAG.Tag_CardsNum)
        num:setVisible(false)
        NodeCards:addChild(num, cmd.NORMAL_COUNT + 1,"")
        for i = 1, cmd.NORMAL_COUNT do
            local card = cc.Sprite:create("card_res/cardsmall.png")
            card:setTextureRect(cc.rect(0, 4 * CARD_HEIGHT_SMALL, CARD_WIDTH_SMALL, CARD_HEIGHT_SMALL))
            card:setTag(TAG.Tag_Cards + i)
            card:setPosition( tabCardPositionChange[index].x * (i - 1), tabCardPositionChange[index].y * (i - 1))
            card:setVisible(false)
            if 0 == tabCardNumPositionFlag[index] then
                card:setPosition( tabCardPositionChange[index].x * (i - 1), tabCardPositionChange[index].y * (i - 1))
            elseif 1 == tabCardNumPositionFlag[index] then
                local halfNum = math.floor(cmd.NORMAL_COUNT / 2)
                if cmd.NORMAL_COUNT / 2 == math.floor(cmd.NORMAL_COUNT / 2) then --是否为偶数
                    local dy = - CARD_HEIGHT_SMALL / CARD_DISTANCE_UNIT / 2
                    card:setPosition(tabCardPositionChange[index].x * (i - 1), tabCardPositionChange[index].y * (i - 1  - 6) + dy)
                else
                    card:setPosition(tabCardPositionChange[index].x * (i - 1), tabCardPositionChange[index].y * (i - 1  - 6))
                end
            end

            NodeCards:addChild(card, i,"")
            if i == cmd.NORMAL_COUNT then
                if 0 == tabCardNumPositionFlag[index] then
                    num:setPosition(cc.p(card:getPositionX(),0))
                elseif 1 == tabCardNumPositionFlag[index] then
                    num:setPosition(cc.p(0,card:getPositionY()))
                end
            end   
        end
    end

    
end

function GameViewLayer:updateCardsNodeLayout( viewid, cardCount,visible)

    --for index = 2, cmd.PLAYER_COUNT do 
        print("========== updateCardsNodeLayout =========",viewid,cardCount,visible)
        local NodeCards = self.m_tabNodeCards[viewid]
        NodeCards:setVisible(visible)
        local num = NodeCards:getChildByTag(TAG.Tag_CardsNum)
        num:setVisible(false)
        if  cardCount > 0 then
            num:setVisible(true)
        else
            num:setVisible(false)
        end
        num:setString(string.format("%d", cardCount))
        for i = 1, cmd.NORMAL_COUNT do
            local card = NodeCards:getChildByTag(TAG.Tag_Cards + i)
            if card ~= nil then
                if i > cardCount then
                    card:setVisible(false)
                else
                    card:setVisible(true)
                    card:setPosition( tabCardPositionChange[viewid].x * (i - 1), tabCardPositionChange[viewid].y * (i - 1))

                    if 0 == tabCardNumPositionFlag[viewid] then
                        card:setPosition( tabCardPositionChange[viewid].x * (i - 1), tabCardPositionChange[viewid].y * (i - 1))
                        elseif 1 == tabCardNumPositionFlag[viewid] then
                            local halfNum = math.floor(cardCount / 2)
                if cardCount / 2 == math.floor(cardCount / 2) then --是否为偶数
                    local dy = CARD_HEIGHT_SMALL / CARD_DISTANCE_UNIT
                    if i > halfNum then
                        dy = CARD_HEIGHT_SMALL / CARD_DISTANCE_UNIT
                    end
                    dy = - CARD_HEIGHT_SMALL / CARD_DISTANCE_UNIT / 2
                    card:setPosition(tabCardPositionChange[viewid].x * (i - 1), tabCardPositionChange[viewid].y * (i - 1  - halfNum) + dy)
                else
                    card:setPosition(tabCardPositionChange[viewid].x * (i - 1), tabCardPositionChange[viewid].y * (i - 1  - halfNum))
                end
            end

            if i == cardCount then
                if 0 == tabCardNumPositionFlag[viewid] then
                    num:setPosition(cc.p(card:getPositionX(),0))
                    elseif 1 == tabCardNumPositionFlag[viewid] then
                        num:setPosition(cc.p(0,card:getPositionY()))
                    end
                end   
            end
        end

    --end

end
end

function GameViewLayer:findBlackFive( cards )
    if nil == cards or 0 == #cards then
        return
    end

    for k,v in pairs (cards) do
        if v == 0x45 then
            print("========= HaveBlackFive =========")
            self.m_bHaveBlackFive = true
            break
        end
    end 
end

return GameViewLayer