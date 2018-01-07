--
-- Author: zhong
-- Date: 2016-11-02 17:28:24
--
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local GameChatLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.game.GameChatLayer")
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. "ClipText")
local AnimationMgr = appdf.req(appdf.EXTERNAL_SRC .. "AnimationMgr")

local module_pre = "game.qipai.land.src"
local cmd = appdf.req(module_pre .. ".models.CMD_Game")
local Define = appdf.req(module_pre .. ".models.Define")
local GameRoleItem = appdf.req(module_pre .. ".views.layer.GameRoleItem")
local CardSprite = appdf.req(module_pre .. ".views.layer.gamecard.CardSprite")
local CardsNode = appdf.req(module_pre .. ".views.layer.gamecard.CardsNode")
local GameLogic = appdf.req(module_pre .. ".models.GameLogic")
local GameResultLayer = appdf.req(module_pre .. ".views.layer.GameResultLayer")
local SettingLayer = appdf.req(module_pre .. ".views.layer.SettingLayer")

local TAG_ENUM = Define.TAG_ENUM
local TAG_ZORDER = Define.TAG_ZORDER

local GameViewLayer = class("GameViewLayer",function(scene)
        local gameViewLayer = display.newLayer()
    return gameViewLayer
end)

function GameViewLayer:ctor(scene)
    --注册node事件
    ExternalFun.registerNodeEvent(self)
    self._scene = scene

    --初始化
    self:paramInit()

    --加载资源
    self:loadResource()
end

function GameViewLayer:paramInit()
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
    self.m_btnOutCard = nil
    self.m_btnPass = nil
    self.m_bMyCallBanker = false
    self.m_bMyOutCards = false

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
    self.m_spTimer = nil
    -- 倒计时
    self.m_atlasTimer = nil
    self.m_tabTimerPos = {}

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
end

function GameViewLayer:getParentNode()
    return self._scene
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
    cc.Director:getInstance():getTextureCache():addImage("game/card.png")
    cc.Director:getInstance():getTextureCache():addImage("game/cardsmall.png")
    -- 加载动画纹理
    cc.SpriteFrameCache:getInstance():addSpriteFrames("game/animation.plist")
    -- 叫分
    AnimationMgr.loadAnimationFromFrame("call_point_0%d.png", 0, 5, Define.CALLSCORE_ANIMATION_KEY)
    -- 一分
    AnimationMgr.loadAnimationFromFrame("call_point_0%d.png", 5, 3, Define.CALLONE_ANIMATION_KEY)
    -- 两分
    AnimationMgr.loadAnimationFromFrame("call_point_1%d.png", 5, 3, Define.CALLTWO_ANIMATION_KEY)
    -- 三分
    AnimationMgr.loadAnimationFromFrame("call_point_2%d.png", 5, 3, Define.CALLTHREE_ANIMATION_KEY)
    -- 飞机
    AnimationMgr.loadAnimationFromFrame("plane_%d.png", 0, 5, Define.AIRSHIP_ANIMATION_KEY)
    -- 火箭
    AnimationMgr.loadAnimationFromFrame("rocket_%d.png", 0, 5, Define.ROCKET_ANIMATION_KEY)
    -- 报警
    AnimationMgr.loadAnimationFromFrame("game_alarm_0%d.png", 0, 5, Define.ALARM_ANIMATION_KEY)
    -- 炸弹
    AnimationMgr.loadAnimationFromFrame("game_bomb_0%d.png", 0, 5, Define.BOMB_ANIMATION_KEY)
    -- 语音动画
    AnimationMgr.loadAnimationFromFrame("record_play_ani_%d.png", 1, 3, Define.VOICE_ANIMATION_KEY)

    --播放背景音乐
    ExternalFun.playBackgroudAudio("background.mp3")

    local rootLayer, csbNode = ExternalFun.loadRootCSB("game/GameLayer.csb", self)
    self.m_rootLayer = rootLayer
    self.m_csbNode = csbNode

    local function btnEvent( sender, eventType )
        if eventType == ccui.TouchEventType.began then
            ExternalFun.popupTouchFilter(1, false)
        elseif eventType == ccui.TouchEventType.canceled then
            ExternalFun.dismissTouchFilter()
        elseif eventType == ccui.TouchEventType.ended then
            ExternalFun.dismissTouchFilter()
            self:onButtonClickedEvent(sender:getTag(), sender)
        end
    end
    local csbNode = self.m_csbNode

    self.m_cardControl = csbNode:getChildByName("card_control")
    self.m_tabCardCount[cmd.LEFT_VIEWID] = self.m_cardControl:getChildByName("atlas_count_1")
    self.m_tabCardCount[cmd.LEFT_VIEWID]:setLocalZOrder(1)
    self.m_tabCardCount[cmd.RIGHT_VIEWID] = self.m_cardControl:getChildByName("atlas_count_3")
    self.m_tabCardCount[cmd.RIGHT_VIEWID]:setLocalZOrder(1)

    ------
    --顶部菜单

    local top = csbNode:getChildByName("btn_layout")
    --聊天按钮
    local btn = top:getChildByName("chat_btn")
    btn:setTag(TAG_ENUM.BT_CHAT)
    btn:setSwallowTouches(true)
    btn:addTouchEventListener(btnEvent)

    --托管按钮
    btn = top:getChildByName("tru_btn")
    btn:setTag(TAG_ENUM.BT_TRU)
    btn:setSwallowTouches(true)
    btn:addTouchEventListener(btnEvent)
    btn:setEnabled(not GlobalUserItem.bPrivateRoom)
    if GlobalUserItem.bPrivateRoom then
        btn:setOpacity(125)
    end

    --设置按钮
    btn = top:getChildByName("set_btn")
    btn:setTag(TAG_ENUM.BT_SET)
    btn:setSwallowTouches(true)
    btn:addTouchEventListener(btnEvent)

    --退出按钮
    btn = top:getChildByName("back_btn")
    btn:setTag(TAG_ENUM.BT_EXIT)
    btn:setSwallowTouches(true)
    btn:addTouchEventListener(btnEvent)

    --叫分
    self.m_textGameCall = top:getChildByName("gamecall_text")

    -- 庄家扑克
    self.m_nodeBankerCard = cc.Node:create()
    self.m_nodeBankerCard:setPosition(667, 720)
    top:addChild(self.m_nodeBankerCard)

    --准备按钮
    self.m_btnReady = top:getChildByName("ready_btn")
    self.m_btnReady:setTag(TAG_ENUM.BT_READY)
    self.m_btnReady:addTouchEventListener(btnEvent)
    self.m_btnReady:setEnabled(false)
    self.m_btnReady:setVisible(false)
    self.m_btnReady:loadTextureDisabled("btn_ready_0.png",UI_TEX_TYPE_PLIST)

    -- 邀请按钮
    self.m_btnInvite = top:getChildByName("btn_invite")
    self.m_btnInvite:setTag(TAG_ENUM.BT_INVITE)
    self.m_btnInvite:addTouchEventListener(btnEvent)
    if GlobalUserItem.bPrivateRoom then
        self.m_btnInvite:setVisible(false)
        self.m_btnInvite:setEnabled(false)
    end

    -- 语音按钮 gameviewlayer -> gamelayer -> clientscene
    self:getParentNode():getParentNode():createVoiceBtn(cc.p(1250, 120), 0, top)

    -- 帮助按钮 gameviewlayer -> gamelayer -> clientscene
    local url = yl.HTTP_URL .. "/Mobile/Introduce.aspx?kindid=200&typeid=0"
    self:getParentNode():getParentNode():createHelpBtn(cc.p(1287, 698), 0, url, top)

    --顶部菜单
    ------

    local tabCardPosition = 
    {
        cc.p(320, 435),
        cc.p(725, 150),
        cc.p(1014, 435)
    }

    local tabBankerCardPosition = 
    {
        cc.p(-50, 0),
        cc.p(0, 0),
        cc.p(50, 0)
    }
    ------
    --用户状态
    local userState = csbNode:getChildByName("userstate_control")    

    --标签
    local str = ""
    for i = 1, 3 do
        -- 准备标签
        str = "ready" .. i
        local tmpsp = userState:getChildByName(str)
        self.m_tabReadySp[i] = tmpsp

        -- 状态标签
        str = "state_sp" .. i
        tmpsp = userState:getChildByName(str)
        self.m_tabStateSp[i] = tmpsp

        -- 扑克牌
        self.m_tabNodeCards[i] = CardsNode:createEmptyCardsNode(i)
        self.m_tabNodeCards[i]:setPosition(tabCardPosition[i])
        self.m_tabNodeCards[i]:setListener(self)
        self.m_cardControl:addChild(self.m_tabNodeCards[i])

        -- 庄家扑克牌
        tmpsp = CardSprite:createCard(0, {_width = 40, _height = 50, _file = "game/cardsmall.png"})
        tmpsp:setVisible(false)
        tmpsp:setPosition(tabBankerCardPosition[i])
        self.m_nodeBankerCard:addChild(tmpsp)
        self.m_tabBankerCard[i] = tmpsp

        -- 报警动画
        tmpsp = self.m_cardControl:getChildByName("alarm_" .. i)
        self.m_tabSpAlarm[i] = tmpsp
    end

    --用户状态
    ------

    ------
    --叫分控制

    local callScore = csbNode:getChildByName("callscore_control")
    self.m_callScoreControl = callScore
    self.m_callScoreControl:setVisible(false)
    --叫分按钮
    for i = 1, 4 do
        str = "score_btn" .. i
        btn = callScore:getChildByName(str)
        btn:setTag(TAG_ENUM.BT_CALLSCORE0 + i - 1)
        btn:addTouchEventListener(btnEvent)
        self.m_tabCallScoreBtn[i] = btn
    end

    --叫分控制
    ------

    ------
    --操作控制

    local onGame = csbNode:getChildByName("ongame_control")
    self.m_onGameControl = onGame
    self.m_onGameControl:setVisible(false)

    --不出按钮
    btn = onGame:getChildByName("pass_btn")
    btn:setTag(TAG_ENUM.BT_PASS)
    btn:addTouchEventListener(btnEvent)
    self.m_btnPass = btn

    --提示按钮
    btn = onGame:getChildByName("suggest_btn")
    btn:setTag(TAG_ENUM.BT_SUGGEST)
    btn:addTouchEventListener(btnEvent)

    --出牌按钮
    btn = onGame:getChildByName("outcard_btn")
    btn:setTag(TAG_ENUM.BT_OUTCARD)
    btn:addTouchEventListener(btnEvent)
    btn:setSwallowTouches(true)
    self.m_btnOutCard = btn

    --操作控制
    ------

    ------
    -- 出牌控制
    self.m_outCardsControl = csbNode:getChildByName("outcards_control")
    -- 出牌控制
    ------

    ------
    -- 用户信息

    local infoLayout = csbNode:getChildByName("info")
    self.m_userinfoControl = infoLayout

    --用户昵称
    self.m_clipNick = ClipText:createClipText(cc.size(200, 30), GlobalUserItem.szNickName, "fonts/round_body.ttf", 30)
    local tmp = infoLayout:getChildByName("tmpname_text")
    self.m_clipNick:setPosition(tmp:getPosition())
    self.m_clipNick:setAnchorPoint(tmp:getAnchorPoint())
    infoLayout:addChild(self.m_clipNick)
    tmp:removeFromParent()

    -- 游戏币
    self.m_atlasScore = infoLayout:getChildByName("score_atlas")

    -- 底分
    self.m_atlasDiFeng = infoLayout:getChildByName("dizhu_atlas")
    self.m_atlasDiFeng:setString("")

    -- 头像位置
    self.m_tabUserHeadPos[cmd.LEFT_VIEWID] = cc.p(207, 416)
    self.m_tabUserHeadPos[cmd.MY_VIEWID] = cc.p(122, 178)
    self.m_tabUserHeadPos[cmd.RIGHT_VIEWID] = cc.p(1150, 416)

    -- 提示tip
    self.m_spInfoTip = infoLayout:getChildByName("info_tip")

    -- 倒计时
    self.m_spTimer = infoLayout:getChildByName("bg_clock")
    self.m_atlasTimer = self.m_spTimer:getChildByName("atlas_time")
    self.m_tabTimerPos[cmd.MY_VIEWID] = cc.p(yl.WIDTH * 0.5, 580)
    self.m_tabTimerPos[cmd.LEFT_VIEWID] = cc.p(yl.WIDTH * 0.15, 580)
    self.m_tabTimerPos[cmd.RIGHT_VIEWID] = cc.p(yl.WIDTH * 0.85, 580)
    -- 用户信息
    ------

    ------
    -- 游戏托管
    self.m_trusteeshipControl = csbNode:getChildByName("tru_control")
    self.m_trusteeshipControl:addTouchEventListener(function( ref, tType)
        if tType == ccui.TouchEventType.ended then
            if self.m_trusteeshipControl:isVisible() then
                self.m_trusteeshipControl:setVisible(false)
            end
        end
    end)
    -- 游戏托管
    ------

    self:reSetGame()
    self:createAnimation()
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
    cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game/animation.plist")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("game/animation.png")
    AnimationMgr.removeCachedAnimation(Define.CALLSCORE_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation(Define.CALLONE_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation(Define.CALLTWO_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation(Define.CALLTHREE_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation(Define.AIRSHIP_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation(Define.ROCKET_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation(Define.ALARM_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation(Define.BOMB_ANIMATION_KEY)
    AnimationMgr.removeCachedAnimation(Define.VOICE_ANIMATION_KEY)

    cc.Director:getInstance():getTextureCache():removeTextureForKey("game/card.png")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("game/cardsmall.png")
    cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game/game.plist")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("game/game.png")
    cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("public_res/public_res.plist")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("public_res/public_res.png")
    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
end
-- 重置
function GameViewLayer:reSetGame()
    self:reSetUserState()

    self.m_spTimer:setVisible(false)
    self.m_atlasTimer:setString("")
    -- 取消托管
    self.m_trusteeshipControl:setVisible(false)

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
    ExternalFun.playClickEffect()
    if TAG_ENUM.BT_CHAT == tag then             --聊天        
        if nil == self.m_chatLayer then
            self.m_chatLayer = GameChatLayer:create(self._scene._gameFrame)
            self:addToRootLayer(self.m_chatLayer, TAG_ZORDER.CHAT_ZORDER)
        end
        self.m_chatLayer:showGameChat(true)
    elseif TAG_ENUM.BT_TRU == tag then          --托管
        self:onGameTrusteeship(true)
    elseif TAG_ENUM.BT_SET == tag then          --设置
        local set = SettingLayer:create()
        self:addToRootLayer(set, TAG_ZORDER.SET_ZORDER)
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
            local shareTxt = "斗地主游戏精彩刺激, 一起来玩吧! "
            local url = GlobalUserItem.szSpreaderURL or yl.HTTP_URL
            if bMyFriend then
                PriRoom:getInstance():getTagLayer(PriRoom.LAYTAG.LAYER_FRIENDLIST, function( frienddata )
                    dump(frienddata)
                end)
            elseif nil ~= target then
                MultiPlatform:getInstance():shareToTarget(target, sharecall, "斗地主游戏邀请", shareTxt, url, "")
            end
        end)        
    elseif TAG_ENUM.BT_CALLSCORE0 == tag then   --不叫
        ExternalFun.playSoundEffect( "cs0.wav", self:getParentNode():GetMeUserItem())
        self:getParentNode():sendCallScore(255)
        self.m_callScoreControl:setVisible(false)
    elseif TAG_ENUM.BT_CALLSCORE1 == tag then   --一分
        ExternalFun.playSoundEffect( "cs1.wav", self:getParentNode():GetMeUserItem())
        self:getParentNode():sendCallScore(1)
        self.m_callScoreControl:setVisible(false)
    elseif TAG_ENUM.BT_CALLSCORE2 == tag then   --两分
        ExternalFun.playSoundEffect( "cs2.wav", self:getParentNode():GetMeUserItem())
        self:getParentNode():sendCallScore(2)
        self.m_callScoreControl:setVisible(false)
    elseif TAG_ENUM.BT_CALLSCORE3 == tag then   --三分
        ExternalFun.playSoundEffect( "cs3.wav", self:getParentNode():GetMeUserItem())
        self:getParentNode():sendCallScore(3)
        self.m_callScoreControl:setVisible(false)
    elseif TAG_ENUM.BT_PASS == tag then         --不出
        self:onPassOutCard()
    elseif TAG_ENUM.BT_SUGGEST == tag then      --提示
        self:onPromptOut(false)        
    elseif TAG_ENUM.BT_OUTCARD == tag then      --出牌
        local sel = self.m_tabNodeCards[cmd.MY_VIEWID]:getSelectCards()
        -- 扑克对比
        self:getParentNode():compareWithLastCards(sel, cmd.MY_VIEWID)

        self.m_onGameControl:setVisible(false)
        local vec = self.m_tabNodeCards[cmd.MY_VIEWID]:outCard(sel)
        self:outCardEffect(cmd.MY_VIEWID, sel, vec)
        self:getParentNode():sendOutCard(sel)
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
        if outCount > 4 then
            cardType = GameLogic.CT_THREE_LINE
        end        
    end
    if GameLogic.CT_THREE_TAKE_TWO == cardType then
        if outCount > 5 then
            cardType = GameLogic.CT_THREE_LINE
        end        
    end

    -- 出牌
    local targetPos = cc.p(0, 0)
    local center = outCount * 0.5
    local scale = 0.5
    holder:setPosition(self.m_tabNodeCards[outViewId]:getPosition())
    if cmd.MY_VIEWID == outViewId then
        scale = 0.6
        targetPos = holder:convertToNodeSpace(cc.p(controlSize.width * 0.5, controlSize.height * 0.42))
    elseif cmd.LEFT_VIEWID == outViewId then
        center = 0
        holder:setAnchorPoint(cc.p(0, 0.5))
        targetPos = holder:convertToNodeSpace(cc.p(controlSize.width * 0.33, controlSize.height * 0.58))
    elseif cmd.RIGHT_VIEWID == outViewId then
        center = outCount
        holder:setAnchorPoint(cc.p(1, 0.5))
        targetPos = holder:convertToNodeSpace(cc.p(controlSize.width * 0.67, controlSize.height * 0.58))
    end
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
    local headitem = self.m_tabUserHead[outViewId]
    if nil == headitem then
        return
    end

    -- 牌型音效
    local bCompare = self:getParentNode().m_bLastCompareRes
    if GameLogic.CT_SINGLE == cardType then
        -- 音效
        local poker = yl.POKER_VALUE[outCards[1]]
        if nil ~= poker then
            ExternalFun.playSoundEffect(poker .. ".wav", headitem.m_userItem) 
        end        
    else
        if bCompare then
            -- 音效
            ExternalFun.playSoundEffect("ya" .. math.random(0, 1) .. ".wav", headitem.m_userItem) 
        else
            -- 音效
            ExternalFun.playSoundEffect( "type" .. cardType .. ".wav", headitem.m_userItem)
        end
    end

    self.m_rootLayer:removeChildByName("__effect_ani_name__")
    -- 牌型动画/牌型音效
    if GameLogic.CT_THREE_LINE == cardType then             -- 飞机
        local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("plane_0.png")
        if nil ~= frame then
            local sp = cc.Sprite:createWithSpriteFrame(frame)
            sp:setPosition(yl.WIDTH * 0.5, yl.HEIGHT * 0.5)
            sp:setName("__effect_ani_name__")
            self:addToRootLayer(sp, TAG_ZORDER.EFFECT_ZORDER)
            sp:runAction(self.m_actPlaneShoot)
        end
    elseif GameLogic.CT_BOMB_CARD == cardType then          -- 炸弹
        local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("game_bomb_01.png")
        if nil ~= frame then
            local sp = cc.Sprite:createWithSpriteFrame(frame)
            sp:setPosition(yl.WIDTH * 0.5, yl.HEIGHT * 0.5)
            sp:setName("__effect_ani_name__")
            self:addToRootLayer(sp, TAG_ZORDER.EFFECT_ZORDER)
            sp:runAction(self.m_actBomb)
            -- 音效
            ExternalFun.playSoundEffect( "common_bomb.wav" ) 
        end
    elseif GameLogic.CT_MISSILE_CARD == cardType then       -- 火箭
        local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("rocket_0.png")
        if nil ~= frame then
            local sp = cc.Sprite:createWithSpriteFrame(frame)
            sp:setPosition(yl.WIDTH * 0.5, yl.HEIGHT * 0.5)
            sp:setName("__effect_ani_name__")
            self:addToRootLayer(sp, TAG_ZORDER.EFFECT_ZORDER)
            sp:runAction(self.m_actRocketShoot)
        end
    end
end

function GameViewLayer:onChangePassBtnState( bEnable )
    self.m_btnPass:setEnabled(bEnable)
    if bEnable then
        self.m_btnPass:setOpacity(255)
    else
        self.m_btnPass:setOpacity(125)
    end
end

function GameViewLayer:onPassOutCard()
    self:getParentNode():sendOutCard({}, true)
    self.m_tabNodeCards[cmd.MY_VIEWID]:reSetCards()
    self.m_onGameControl:setVisible(false)
    -- 提示
    self.m_spInfoTip:setSpriteFrame("blank.png")
    -- 显示不出
    local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("game_nooutcard.png")
    if nil ~= frame then
        self.m_tabStateSp[cmd.MY_VIEWID]:setSpriteFrame(frame)
    end

    -- 音效
    ExternalFun.playSoundEffect( "pass" .. math.random(0, 1) .. ".wav", self:getParentNode():GetMeUserItem())
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
    local outCards = self:getParentNode().m_tabCurrentCards
    local outCount = #outCards

    local selectCount = #selectCards
    local selectType = GameLogic:GetCardType(selectCards, selectCount)

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

    self.m_btnOutCard:setEnabled(enable)
    self.m_btnOutCard:setOpacity(opacity)
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
            self.m_onGameControl:setVisible(false)
        else
            self:onPassOutCard()
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
            if #prompt > 0 then
                self.m_tabNodeCards[cmd.MY_VIEWID]:suggestShootCards(prompt)
            else
                self:onPassOutCard()
            end
            self.m_promptIdx = self.m_promptIdx - 1
        else
            self:onPassOutCard()
        end
    end
end

function GameViewLayer:onGameTrusteeship( bTrusteeship )
    self.m_trusteeshipControl:setVisible(bTrusteeship)
    if bTrusteeship then
        if self.m_bMyCallBanker then
            self.m_bMyCallBanker = false
            self.m_callScoreControl:setVisible(false)
            self:getParentNode():sendCallScore(255)          
        end

        if self.m_bMyOutCards then
            self.m_bMyOutCards = false
            self:onPromptOut(true)
        end
    end
end

function GameViewLayer:updateClock( clockId, cbTime)
    self.m_atlasTimer:setString( string.format("%02d", cbTime ))
    if cbTime <= 0 then
        if cmd.TAG_COUNTDOWN_READY == clockId then
            --退出防作弊
            self:getParentNode():getFrame():setEnterAntiCheatRoom(false)
        elseif cmd.TAG_COUNTDOWN_CALLSCORE == clockId then
            -- 私人房无自动托管
            if not GlobalUserItem.bPrivateRoom then
                self:onGameTrusteeship(true)
            end            
        elseif cmd.TAG_COUNTDOWN_OUTCARD == clockId then
            -- 私人房无自动托管
            if not GlobalUserItem.bPrivateRoom then
                self:onGameTrusteeship(true)
            end
        end
    end
end

function GameViewLayer:OnUpdataClockView( viewId, cbTime )
    self.m_spTimer:setVisible(cbTime ~= 0)
    self.m_atlasTimer:setString( string.format("%02d", cbTime ))

    if self:getParentNode():IsValidViewID(viewId) then
        self.m_spTimer:setPosition(self.m_tabTimerPos[viewId])
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

-- 用户更新
function GameViewLayer:OnUpdateUser(viewId, userItem, bLeave)
    print(" update user " .. viewId)
    if bLeave then
        local roleItem = self.m_tabUserHead[viewId]
        if nil ~= roleItem then
            roleItem:removeFromParent()
            self.m_tabUserHead[viewId] = nil
        end
        self:onUserReady(viewId, false)
    end
    local bHide = ((table.nums(self.m_tabUserHead)) == (self:getParentNode():getFrame():GetChairCount()))
    if not GlobalUserItem.bPrivateRoom then
        self.m_btnInvite:setVisible(not bHide)
        self.m_btnInvite:setEnabled(not bHide)
    end    
    self.m_btnInvite:setVisible(false)
    self.m_btnInvite:setEnabled(false)

    if nil == userItem then
        return
    end
    self.m_tabUserItem[viewId] = userItem

    local bReady = userItem.cbUserStatus == yl.US_READY
    self:onUserReady(viewId, bReady)

    if nil == self.m_tabUserHead[viewId] then
        local roleItem = GameRoleItem:create(userItem, viewId)
        roleItem:setPosition(self.m_tabUserHeadPos[viewId])
        self.m_tabUserHead[viewId] = roleItem
        self.m_userinfoControl:addChild(roleItem)
    else
        self.m_tabUserHead[viewId].m_userItem = userItem
        self.m_tabUserHead[viewId]:updateStatus()
    end

    if cmd.MY_VIEWID == viewId then
        self:reSetUserInfo()
    end
end

function GameViewLayer:onUserReady(viewId, bReady)
    --用户准备
    if bReady then
        local readySp = self.m_tabReadySp[viewId]
        if nil ~= readySp then
            readySp:setVisible(true)
        end
    else
        local readySp = self.m_tabReadySp[viewId]
        if nil ~= readySp then
            readySp:setVisible(false)
        end
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
    self.m_atlasDiFeng:setString(str) 
end

function GameViewLayer:onGetGameFree()
    if false == self:getParentNode():getFrame().bEnterAntiCheatRoom then
        self.m_btnReady:setEnabled(true)
        self.m_btnReady:setVisible(true)
    end    
end

function GameViewLayer:onGameStart()
    self.m_nMaxCallScore = 0
    self.m_textGameCall:setString("")
    for k,v in pairs(self.m_tabBankerCard) do
        v:setVisible(false)
        v:setCardValue(0)
    end
    self.m_spInfoTip:setSpriteFrame("blank.png")
    for k,v in pairs(self.m_tabStateSp) do
        v:stopAllActions()
        v:setSpriteFrame("blank.png")
    end

    for k,v in pairs(self.m_tabCardCount) do
        v:setString("")
    end
    self.m_promptIdx = 0
end

-- 获取到扑克数据
-- @param[viewId] 界面viewid
-- @param[cards] 扑克数据
-- @param[bReEnter] 是否断线重连
-- @param[pCallBack] 回调函数
function GameViewLayer:onGetGameCard(viewId, cards, bReEnter, pCallBack)
    if bReEnter then
        print(viewId)
        self.m_tabNodeCards[viewId]:updateCardsNode(cards, (viewId == cmd.MY_VIEWID), false)
    else
        if nil ~= pCallBack then
            pCallBack:retain()
        end
        local call = cc.CallFunc:create(function()
            -- 非自己扑克
            local empTyCard = GameLogic:emptyCardList(cmd.NORMAL_COUNT)
            self.m_tabNodeCards[cmd.LEFT_VIEWID]:updateCardsNode(empTyCard, false, true)
            empTyCard = GameLogic:emptyCardList(cmd.NORMAL_COUNT)
            self.m_tabNodeCards[cmd.RIGHT_VIEWID]:updateCardsNode(empTyCard, false, true)

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
            ExternalFun.playSoundEffect( "dispatch.wav" )
        end)
        local seq = cc.Sequence:create(call2, cc.DelayTime:create(0.3), call)
        self:stopAllActions()
        self:runAction(seq)
    end
end

-- 获取到玩家叫分
-- @param[callViewId]   当前叫分玩家
-- @param[lastViewId]   上个叫分玩家
-- @param[callScore]    当前叫分分数
-- @param[lastScore]    上个叫分分数
-- @param[bReEnter]     是否断线重连
function GameViewLayer:onGetCallScore( callViewId, lastViewId, callScore, lastScore, bReEnter )
    bReEnter = bReEnter or false

    if 255 == lastScore then
        print("不叫")
        -- 不叫
        local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("game_tips_callscore0.png")
        if nil ~= frame then
            self.m_tabStateSp[lastViewId]:setSpriteFrame(frame)
        end    
    elseif lastScore > 0 and lastScore < 4 then
        local param = AnimationMgr.getAnimationParam()
        param.m_fDelay = 0.1
        param.m_strName = lastScore .. "_score_key"

        -- 播放叫分动画
        if bReEnter then
            local callscore = AnimationMgr.getAnimate(param)
            local frames = callscore:getAnimation():getFrames()
            if #frames > 0 then
                self.m_tabStateSp[lastViewId]:setSpriteFrame(frames[#frames]:getSpriteFrame())
            end
        else
            param.m_strName = Define.CALLSCORE_ANIMATION_KEY
            local animate = AnimationMgr.getAnimate(param)
            param.m_strName = lastScore .. "_score_key"
            local callscore = AnimationMgr.getAnimate(param)
            local call = cc.CallFunc:create(function()
                local frames = callscore:getAnimation():getFrames()
                if #frames > 0 then
                    self.m_tabStateSp[lastViewId]:setSpriteFrame(frames[#frames]:getSpriteFrame())
                end
            end)
            local seq = cc.Sequence:create(animate, callscore, call)
            self.m_tabStateSp[lastViewId]:stopAllActions()
            self.m_tabStateSp[lastViewId]:runAction(seq)
        end
    end

    lastScore = (lastScore > 3) and 0 or lastScore
    if lastScore > self.m_nMaxCallScore then
        self.m_nMaxCallScore = lastScore
    end
    if cmd.MY_VIEWID ~= lastViewId then
        local headitem = self.m_tabUserHead[lastViewId]
        if nil ~= headitem then
            -- 音效
            ExternalFun.playSoundEffect( "cs" .. lastScore .. ".wav", headitem.m_userItem)
        end
    end

    self.m_bMyCallBanker = (cmd.MY_VIEWID == callViewId)
    if cmd.MY_VIEWID == callViewId and not self:getParentNode().m_bRoundOver then
        -- 托管不叫
        if self.m_trusteeshipControl:isVisible() then
            self.m_callScoreControl:setVisible(false)
            self:getParentNode():sendCallScore(0)
        else
            self.m_spInfoTip:setSpriteFrame("blank.png")
            -- 计算叫分
            local maxCall = self.m_nMaxCallScore + 1
            for i = 2, #self.m_tabCallScoreBtn do
                local btn = self.m_tabCallScoreBtn[i]
                btn:setEnabled(true)
                btn:setOpacity(255)
                if i <= maxCall  then
                    btn:setEnabled(false)
                    btn:setOpacity(125)
                end
            end
            self.m_callScoreControl:setVisible(true)
        end
    else
        if not bReEnter and not self:getParentNode().m_bRoundOver then
            -- 等待叫分
            self.m_spInfoTip:setPosition(yl.WIDTH * 0.5, 375)
            self.m_spInfoTip:setSpriteFrame("game_tips_01.png")
        end        
    end
end

-- 获取到庄家信息
-- @param[bankerViewId]         庄家视图id
-- @param[cbBankerScore]        庄家分数
-- @param[bankerCards]          庄家牌
-- @param[bReEnter]             是否断线重连
function GameViewLayer:onGetBankerInfo(bankerViewId, cbBankerScore, bankerCards, bReEnter)
    bReEnter = bReEnter or false
    self.m_bMyCallBanker = false
    -- 更新庄家扑克
    if 3 == #bankerCards then
        for k,v in pairs(bankerCards) do
            self.m_tabBankerCard[k]:setVisible(true)
            self.m_tabBankerCard[k]:setCardValue(v)
        end
    end
    -- 叫分
    self.m_textGameCall:setString(cbBankerScore .. "") 

    -- 庄家切换
    for k,v in pairs(self.m_tabUserHead) do
        v:switeGameState(k == bankerViewId)

        self.m_tabStateSp[k]:stopAllActions()
        self.m_tabStateSp[k]:setSpriteFrame("blank.png")
    end

    if false == bReEnter then
        -- 庄家增加牌
        local handCards = self.m_tabNodeCards[bankerViewId]:getHandCards()
        local count = #handCards
        if bankerViewId == cmd.MY_VIEWID then
            handCards[count + 1] = bankerCards[1]
            handCards[count + 2] = bankerCards[2]
            handCards[count + 3] = bankerCards[3]
            handCards = GameLogic:SortCardList(handCards, cmd.MAX_COUNT, 0)
        else
            handCards[count + 1] = 0
            handCards[count + 2] = 0
            handCards[count + 3] = 0
        end
        self.m_tabNodeCards[bankerViewId]:addCards(bankerCards, handCards)
    end

    -- 提示
    self.m_spInfoTip:setSpriteFrame("blank.png")
end

-- 用户出牌
-- @param[curViewId]        当前出牌视图id
-- @param[lastViewId]       上局出牌视图id
-- @param[lastOutCards]     上局出牌
-- @param[bRenter]          是否断线重连
function GameViewLayer:onGetOutCard(curViewId, lastViewId, lastOutCards, bReEnter)
    bReEnter = bReEnter or false

    self.m_bMyOutCards = (curViewId == cmd.MY_VIEWID)
    if nil ~= self.m_tabStateSp[curViewId] then
        self.m_tabStateSp[curViewId]:setSpriteFrame("blank.png")
    end
    -- 自己出牌
    if curViewId == cmd.MY_VIEWID then
        -- 托管
        if self.m_trusteeshipControl:isVisible() then
            self:onPromptOut(true)
        else
            -- 移除上轮出牌
            self.m_outCardsControl:removeChildByTag(curViewId)

            self.m_onGameControl:setVisible(true)

            self.m_btnOutCard:setEnabled(false)
            self.m_btnOutCard:setOpacity(125)

            local promptList = self:getParentNode().m_tabPromptList
            self.m_bCanOutCard = (#promptList > 0)

            -- 出牌控制
            if not self.m_bCanOutCard then
                self.m_spInfoTip:setSpriteFrame("game_tips_00.png")
                self.m_spInfoTip:setPosition(yl.WIDTH * 0.5, 160)
            else
                local sel = self.m_tabNodeCards[cmd.MY_VIEWID]:getSelectCards()
                local selCount = #sel
                if selCount > 0 then
                    local selType = GameLogic:GetCardType(sel, selCount)
                    if GameLogic.CT_ERROR ~= selType then
                        local lastOutCount = #lastOutCards
                        if lastOutCount == 0 then
                            self.m_btnOutCard:setEnabled(true)
                            self.m_btnOutCard:setOpacity(255)
                        elseif lastOutCount > 0 and GameLogic:CompareCard(lastOutCards, lastOutCount, sel, selCount) then
                            self.m_btnOutCard:setEnabled(true)
                            self.m_btnOutCard:setOpacity(255)
                        end
                    end
                end
                self.m_spInfoTip:setSpriteFrame("blank.png")
            end
        end
    end

    -- 出牌消息
    if lastViewId ~= cmd.MY_VIEWID and #lastOutCards > 0 then
        local vec = self.m_tabNodeCards[lastViewId]:outCard(lastOutCards, bReEnter)
        self:outCardEffect(lastViewId, lastOutCards, vec)
    end
end

-- 用户pass
-- @param[passViewId]       放弃视图id
function GameViewLayer:onGetPassCard( passViewId )
    if passViewId ~= cmd.MY_VIEWID then
        local headitem = self.m_tabUserHead[passViewId]
        if nil ~= headitem then
            -- 音效
            ExternalFun.playSoundEffect( "pass" .. math.random(0, 1) .. ".wav", headitem.m_userItem)
        end        
    end
    self.m_outCardsControl:removeChildByTag(passViewId)

    -- 显示不出
    local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("game_nooutcard.png")
    if nil ~= frame then
        self.m_tabStateSp[passViewId]:setSpriteFrame(frame)
    end
end

-- 游戏结束
function GameViewLayer:onGetGameConclude( rs )
    -- 界面重置
    self:reSetGame()

    -- 取消托管
    self.m_trusteeshipControl:setVisible(false)

    -- 显示准备
    self.m_btnReady:setEnabled(true)
    self.m_btnReady:setVisible(true)

    self.m_spInfoTip:setSpriteFrame("blank.png")
    self.m_spInfoTip:setPosition(yl.WIDTH * 0.5, 375)

    -- 结算
    if nil == self.m_resultLayer then
        self.m_resultLayer = GameResultLayer:create(self)
        self:addToRootLayer(self.m_resultLayer, TAG_ZORDER.RESULT_ZORDER)
    end
    if not GlobalUserItem.bPrivateRoom then
        self:runAction(cc.Sequence:create(cc.DelayTime:create(2), cc.CallFunc:create(function()
            self.m_resultLayer:showGameResult(rs)
        end)))        
    else
        self.m_resultLayer:showGameResult(rs)
    end    
    self.m_rootLayer:removeChildByName("__effect_ani_name__")
end

------------------------------------------------------------------------------------------------------------
--更新
------------------------------------------------------------------------------------------------------------

return GameViewLayer