
--
-- Author: Tang
-- Date: 2016-08-09 14:46:36
--
local GameViewLayer = class("GameViewLayer", function(scene)
			local gameViewLayer = display.newLayer()
			return gameViewLayer

	end)

--Tag
GameViewLayer.VIEW_TAG = 
{
    tag_bg        = 200,
    tag_autoshoot = 210,
    tag_autolock = 211,
    tag_gameScore= 212,
    tag_gameMultiple = 213,
    tag_grounpTips = 214,
    tag_GoldCycle = 3000,
    tag_GoldCycleTxt = 4000,
    tag_Menu = 5000
}

local  TAG = GameViewLayer.VIEW_TAG

local ExternalFun = require(appdf.EXTERNAL_SRC.."ExternalFun")
local g_var = ExternalFun.req_var
local ClipText = appdf.EXTERNAL_SRC .. "ClipText"
local module_pre = "game.yule.fishry.src"	
local game_cmd = appdf.HEADER_SRC .. "CMD_GameServer"
local PRELOAD = require(module_pre..".views.layer.PreLoading") 
local cmd = module_pre .. ".models.CMD_RYGame"
function GameViewLayer:ctor( scene )

	local this = self
	self._scene = scene

	self:addSerchPaths()
            self.netColorIndex = 5
    PRELOAD.setEnded(false)
   --预加载资源
    PRELOAD.loadTextures()
    --self._gameFrame = scene._gameFrame
    --self._dataModel = scene._dataModel
      --注册事件
   ExternalFun.registerTouchEvent(self,true)
   self.m_TAG = TAG
end


function GameViewLayer:onExit()
    print("GameViewLayer onExit........")
    self._scene.m_bLeaveGame = true
    PRELOAD.unloadTextures()
    PRELOAD.removeAllActions()

    PRELOAD.resetData()

    self:StopLoading(true)
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

end

function GameViewLayer:StopLoading( bRemove )

    PRELOAD.StopAnim(bRemove)
end

function GameViewLayer:getDataMgr( )
    return self:getParentNode():getDataMgr()
end

function GameViewLayer:getParentNode( )
    return self._scene;
end

function GameViewLayer:addSerchPaths( )
   --搜索路径
    local gameList = self._scene._scene:getApp()._gameList;
    local gameInfo = {};
    for k,v in pairs(gameList) do
          if tonumber(v._KindID) == tonumber(g_var(cmd).KIND_ID) then
            gameInfo = v;
            break;
        end
    end

    if nil ~= gameInfo._KindName then
        self._searchPath = device.writablePath.."game/" .. gameInfo._Module .. "/res/";
        cc.FileUtils:getInstance():addSearchPath(self._searchPath);
    end
end

function GameViewLayer:initView(  )

    local bg =  ccui.ImageView:create("game_res/game_bg_0.png")
	bg:setAnchorPoint(cc.p(.5,.5))
    bg:setTag(TAG.tag_bg)
	bg:setPosition(cc.p(yl.WIDTH/2,yl.HEIGHT/2))
	self:addChild(bg)

    --底栏菜单栏
    local menuBG = cc.Sprite:create("game_res/game_buttom.png")
    menuBG:setAnchorPoint(0.5,0.0)
    menuBG:setScaleY(0.9)
    menuBG:setPosition(667, 0)
    self:addChild(menuBG,20)

    --倍数切换
    local mutipleBtn = ccui.Button:create("game_res/im_multiple_tip.png")
    mutipleBtn:setAnchorPoint(0.5,0.0)
    mutipleBtn:addTouchEventListener(function( sender , eventType )
        if eventType == ccui.TouchEventType.ended then
            local index = self._scene._dataModel.m_secene.nMultipleIndex
            index = index + 1
            index = math.mod(index,6)
            
        local cmddata = CCmd_Data:create(4)
         cmddata:setcmdinfo(yl.MDM_GF_GAME, g_var(cmd).SUB_C_MULTIPLE);
         cmddata:pushint(index)
        self._scene:sendNetData(cmddata)

    local cannonPos = self._scene.m_nChairID
    if self._scene._dataModel.m_reversal then 
           cannonPos = 5 - cannonPos
    end
    self._scene._dataModel.m_secene.nMultipleIndex = index
    local cannon = self._scene.m_cannonLayer:getCannoByPos(cannonPos + 1)
    cannon:setMultiple(self._scene._dataModel.m_secene.nMultipleIndex)

        self:updateMultiple(self._scene._dataModel.m_secene.nMultipleValue[1][index+1]) 
        end
    end)


    mutipleBtn:setPosition(yl.WIDTH/2 - 215, 38)
    self:addChild(mutipleBtn,21)


    local function callBack( sender, eventType)
        self:ButtonEvent(sender,eventType)
    end


    --自动射击
    local autoShootBtn = ccui.Button:create()
    autoShootBtn:setContentSize(cc.size(42, 36))
    autoShootBtn:setScale9Enabled(true)
    autoShootBtn:setPosition(609, 17)
    autoShootBtn:setTag(TAG.tag_autoshoot)
    autoShootBtn:addTouchEventListener(callBack)
    self:addChild(autoShootBtn,20)


    --自动锁定
    local autoLockBtn = ccui.Button:create()
    autoLockBtn:setContentSize(cc.size(42, 36))
    autoLockBtn:setScale9Enabled(true)
    autoLockBtn:setPosition(814, 17)
    autoLockBtn:setTag(TAG.tag_autolock)
    autoLockBtn:addTouchEventListener(callBack)
    self:addChild(autoLockBtn,20)

--菜单
    local menu = ccui.Button:create("game_res/bt_menu_0.png","game_res/bt_menu_1.png")
    menu:setScale(0.91)
    menu:addTouchEventListener(callBack)
    menu:setTag(TAG.tag_Menu)
    menu:setPosition(1227, 24)
    self:addChild(menu,20)

	
    --水波效果
    local render = cc.RenderTexture:create(1334,750)
    render:beginWithClear(0,0,0,0)
    local water = cc.Sprite:createWithSpriteFrameName("water_0.png")
    water:setScale(2.5)
    water:setOpacity(120)
    water:setBlendFunc(gl.SRC_ALPHA,gl.ONE)
    water:visit()
    render:endToLua()
    water:addChild(render)
    render:setPosition(667,375) 
    water:setPosition(667,375)
    self:addChild(water, 1)

    local ani1 = cc.Animate:create(cc.AnimationCache:getInstance():getAnimation(g_var(cmd).WaterAnim))
    local ani2 = ani1:reverse()

    local action = cc.RepeatForever:create(cc.Sequence:create(ani1,ani2))
    water:runAction(action)
end


function GameViewLayer:initUserInfo()
    --倍数
    local nick = cc.Label:createWithCharMap("game_res/num_multiple.png",19,20,string.byte("0"))
    nick:setString("1:")
    nick:setAnchorPoint(0.5,0.5)
    nick:setPosition(430,18)
    nick:setTag(TAG.tag_gameMultiple)
    self:addChild(nick,22)


    --用户分数 
    local score = cc.Label:createWithCharMap("game_res/num_score.png",14,14,string.byte("0"))
    score:setString(string.format("%d", self._scene.m_pUserItem.lScore))
    score:setAnchorPoint(0.5,0.5)
    score:setTag(TAG.tag_gameScore)
    score:setPosition(171, 22)
    self:addChild(score,22)
end

function GameViewLayer:updateUserScore( score )
    
    local _score  = self:getChildByTag(TAG.tag_gameScore)
    if nil ~=  _score then
        _score:setString(string.format("%d",score))
    end
end

function GameViewLayer:updateMultiple( multiple )
    local _Multiple = self:getChildByTag(TAG.tag_gameMultiple)
    if nil ~=  _Multiple then
        _Multiple:setString(string.format("%d:",multiple))
    end
end

function GameViewLayer:updteBackGround(param)


    local bg = self:getChildByTag(TAG.tag_bg)

    if bg  then
        local call = cc.CallFunc:create(function()
            bg:removeFromParent()
        end)

        bg:runAction(cc.Sequence:create(cc.FadeTo:create(2.5,0),call))

        local bgfile = string.format("game_res/game_bg_%d.png", param)
        local _bg = cc.Sprite:create(bgfile)
        _bg:setPosition(yl.WIDTH/2, yl.HEIGHT/2)
        _bg:setOpacity(0)
        _bg:setTag(TAG.tag_bg)
        self:addChild(_bg)

        _bg:runAction(cc.FadeTo:create(5,255))
    end

        --鱼阵提示
        local groupTips = ccui.ImageView:create("game_res/fish_grounp.png")
        groupTips:setPosition(cc.p(yl.WIDTH/2,yl.HEIGHT/2))
        groupTips:setTag(TAG.tag_grounpTips)
        self:addChild(groupTips,30)

        local callFunc = cc.CallFunc:create(function()
                groupTips:removeFromParent()
            end)

        groupTips:runAction(cc.Sequence:create(cc.DelayTime:create(5.0),callFunc))

       
end

function GameViewLayer:setAutoShoot(b,target)
    target:removeChildByTag(1)
    print("setAutoShoot "..tostring(b))
    if b then

        local auto = cc.Sprite:create("game_res/bt_check_yes.png")
        auto:setScaleX(1.15)
        --auto:setContentSize(cc.size(auto:getContentSize().width + 5, auto:getContentSize().height))
        auto:setTag(1)
        auto:setPosition(target:getContentSize().width/2 + 1, target:getContentSize().height/2 + 5)
        target:removeChildByTag(1)
        target:addChild(auto)

    else
         target:removeChildByTag(1)
    end
          
end

function GameViewLayer:setAutoLock(b,target)
    target:removeChildByTag(1)
    if b then
        local lock = cc.Sprite:create("game_res/bt_check_yes.png")
        --lock:setContentSize(cc.size(lock:getContentSize().width + 5, lock:getContentSize().height))
        lock:setScaleX(1.15)
        lock:setTag(1)
        lock:setPosition(target:getContentSize().width/2 + 1, target:getContentSize().height/2 + 5)
        target:removeChildByTag(1)
        target:addChild(lock)

    else
         target:removeChildByTag(1)

         --取消自动射击
         self._scene._dataModel.m_fishIndex = g_var(cmd).INT_MAX

        --删除自动锁定图标
         local cannonPos = self._scene.m_nChairID
         if self._scene._dataModel.m_reversal then 
           cannonPos = 5 - cannonPos
         end

         local cannon = self._scene.m_cannonLayer:getCannoByPos(cannonPos + 1)
         cannon:removeLockTag()

    end
                     
end


--银行操作成功
function GameViewLayer:onBankSuccess( )
    self._scene:dismissPopWait()
    local bank_success = self._scene.bank_success
    showToast(cc.Director:getInstance():getRunningScene(), bank_success.szDescribrString, 2)
    GlobalUserItem.lUserInsure = bank_success.lUserInsure
    if true then
        return
    end
    
    if nil == bank_success then
        return
    end

    local addScore = bank_success.lUserScore - GlobalUserItem.lUserScore
    GlobalUserItem.lUserScore = self._scene._dataModel.m_secene.lPlayCurScore[1][self._scene.m_nChairID + 1] + addScore
    
    print("onBankSuccess addScore lUserScore",addScore,bank_success.lUserScore,GlobalUserItem.lUserScore)
    self:refreshScore()

    
end

--银行操作失败
function GameViewLayer:onBankFailure( )

     self._scene:dismissPopWait()
    local bank_fail = self._scene.bank_fail
    if nil == bank_fail then
        return
    end

    showToast(cc.Director:getInstance():getRunningScene(), bank_fail.szDescribeString, 2)
end


  --刷新金币
function GameViewLayer:refreshScore( )
    --携带游戏币
    local str = ExternalFun.numberThousands(GlobalUserItem.lUserScore)
    if string.len(str) > 19 then
        str = string.sub(str, 1, 19)
    end
    if nil == self.textCurrent then
        return
    end
    self.textCurrent:setString(str)

    --银行存款
    str = ExternalFun.numberThousands(GlobalUserItem.lUserInsure)
    if string.len(str) > 19 then
        str = string.sub(str, 1, 19)
    end
    self._scene._dataModel.m_secene.lPlayCurScore[1][self._scene.m_nChairID + 1] = GlobalUserItem.lUserScore

    self.textBank:setString(ExternalFun.numberThousands(GlobalUserItem.lUserInsure))

    --用户分数
   self:updateUserScore(GlobalUserItem.lUserScore)


end

--子菜单
function GameViewLayer:subMenuEvent( sender , eventType)
    
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
                self.textCurrent = nil
                self.textBank = nil

            end
        end)

        return bg
    end


    local function showPopWait()
        self._scene:showPopWait()
    end

    --关闭等待
    local function dismissPopWait()
        self._scene:dismissPopWait()
    end

    local tag = sender:getTag()
    if 1 == tag then --银行

        --申请取款
        local function sendTakeScore( lScore,szPassword )
            local cmddata = ExternalFun.create_netdata(g_var(game_cmd).CMD_GR_C_TakeScoreRequest)
            cmddata:setcmdinfo(g_var(game_cmd).MDM_GR_INSURE, g_var(game_cmd).SUB_GR_TAKE_SCORE_REQUEST)
            cmddata:pushbyte(g_var(game_cmd).SUB_GR_TAKE_SCORE_REQUEST)
            cmddata:pushscore(lScore)
            cmddata:pushstring(md5(szPassword),yl.LEN_PASSWORD)

            self._scene:sendNetData(cmddata)
        end


        local function onTakeScore( )
                --参数判断
                local szScore = string.gsub( self.m_editNumber:getText(),"([^0-9])","")
                local szPass =   self.m_editPasswd:getText()

                if #szScore < 1 then 
                    showToast(cc.Director:getInstance():getRunningScene(),"请输入操作金额！",2)
                    return
                end

                local lOperateScore = tonumber(szScore)
                if lOperateScore<1 then
                    showToast(cc.Director:getInstance():getRunningScene(),"请输入正确金额！",2)
                    return
                end

                if #szPass < 1 then 
                    showToast(cc.Director:getInstance():getRunningScene(),"请输入银行密码！",2)
                    return
                end
                if #szPass <6 then
                    showToast(cc.Director:getInstance():getRunningScene(),"密码必须大于6个字符，请重新输入！",2)
                    return
                end

                showPopWait()
                sendTakeScore(lOperateScore,szPass)
                
         end


        local  bg = addBG()

        local csbNode = ExternalFun.loadCSB("game_res/Bank.csb", bg)
        csbNode:setAnchorPoint(0.5,0.5)
        csbNode:setPosition(yl.WIDTH/2,yl.HEIGHT/2)

--当前金币
        self.textCurrent =  csbNode:getChildByName("Text_Score")
        --local pos = cc.p(self.textCurrent:getPositionX(),self.textCurrent:getPositionY())
        --local text = self.textCurrent:getString()
        --self.textCurrent:removeFromParent()

        --self.textCurrent = cc.Label:createWithTTF(text, "fonts/round_body.ttf", 20)
        --self.textCurrent:setPosition(pos.x, pos.y)
        --csbNode:addChild(self.textCurrent)

        local str = ExternalFun.numberThousands(self._scene._dataModel.m_secene.lPlayCurScore[1][self._scene.m_nChairID + 1])
        if string.len(str) > 19 then
            str = string.sub(str, 1, 19)
        end
        self.textCurrent:setString(str)

--银行存款
        self.textBank    =  csbNode:getChildByName("Text_inSave")
        --[[
        pos = cc.p(self.textBank:getPositionX(),self.textBank:getPositionY())
        text = self.textBank:getString()

        self.textBank:removeFromParent()

        self.textBank = cc.Label:createWithTTF(text, "fonts/round_body.ttf", 20)
        self.textBank:setPosition(pos.x, pos.y)
        csbNode:addChild(self.textBank)
        --]]
        str = ExternalFun.numberThousands(GlobalUserItem.lUserInsure)
        if string.len(str) > 19 then
            str = string.sub(str, 1, 19)
        end
        self.textBank:setString(str)


        --self:refreshScore()

--输入取出金额

        local take = csbNode:getChildByName("Text_tipNum")
        ---[[
        pos = cc.p(take:getPositionX(),take:getPositionY())
        text = take:getString()

        take:removeFromParent()

        take = cc.Label:createWithTTF(text, "fonts/round_body.ttf", 20)
        take:setPosition(pos.x, pos.y)
        csbNode:addChild(take)
        --]]

--输入银行密码  

        local password = csbNode:getChildByName("Text_tipPassWord")
        ---[[
        pos = cc.p(password:getPositionX(),password:getPositionY())
        text = password:getString()

        password:removeFromParent()

        password = cc.Label:createWithTTF(text, "fonts/round_body.ttf", 20)
        password:setPosition(pos.x, pos.y)
        csbNode:addChild(password)
        --]]


--取款按钮
        local btnTake = csbNode:getChildByName("btn_takeout")
        btnTake:addTouchEventListener(function( sender , envetType )
            if envetType == ccui.TouchEventType.ended then
                onTakeScore()
            end
        end)

--关闭按钮
        --[[
        local btnClose = csbNode:getChildByName("bt_close")
        btnClose:addTouchEventListener(function( sender , eventType )
            if eventType == ccui.TouchEventType.ended then
                bg:removeFromParent()
            end
        end)
        --]]
------------------------------------EditBox---------------------------------------------------


--取款金额
    local editbox = ccui.EditBox:create(cc.size(325, 47),"bank_res/edit_frame.png")
        :setPosition(cc.p(100,take:getPositionY()))
        :setFontName("fonts/round_body.ttf")
        :setPlaceholderFontName("fonts/round_body.ttf")
        :setFontSize(24)
        :setPlaceholderFontSize(24)
        :setMaxLength(32)
        :setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        :setPlaceHolder("请输入取款金额")
    csbNode:addChild(editbox)
    self.m_editNumber = editbox
  

    --取款密码
    editbox = ccui.EditBox:create(cc.size(325, 47),"bank_res/edit_frame.png")
        :setPosition(cc.p(100,password:getPositionY()))
        :setFontName("fonts/round_body.ttf")
        :setPlaceholderFontName("fonts/round_body.ttf")
        :setFontSize(24)
        :setPlaceholderFontSize(24)
        :setMaxLength(32)
        :setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
        :setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
        :setPlaceHolder("请输入取款密码")
    csbNode:addChild(editbox)
    self.m_editPasswd = editbox
   

---------------------------------------------------------------------------------------------------------

    elseif 2 == tag then --帮助

        local  bg = addBG()

        local csbNode = ExternalFun.loadCSB("game_res/Help.csb", bg)
        csbNode:setAnchorPoint(0.5,0.5)
        csbNode:setPosition(yl.WIDTH/2,yl.HEIGHT/2)

        --切换按钮
        local btnLayout = csbNode:getChildByName("btn_layout")
        local btnOperate = btnLayout:getChildByName("Button_operate")
        local btnAward = btnLayout:getChildByName("Button_award")
        local btnGift = btnLayout:getChildByName("Button_gift")

        local btnClose = csbNode:getChildByName("btn_close")


        --背景
        local  operateBG = csbNode:getChildByName("help_operate")
        local  awardBG = csbNode:getChildByName("help_award")
        local  giftBG  = csbNode:getChildByName("help_gift")


        --添加点击事件
        btnOperate:addTouchEventListener(function ( sender , eventType )
            if eventType == ccui.TouchEventType.ended then
                operateBG:setVisible(true)
                awardBG:setVisible(false)
                giftBG:setVisible(false)
            end
        end)

        btnAward:addTouchEventListener(function ( sender , eventType )
            if eventType == ccui.TouchEventType.ended then
                operateBG:setVisible(false)
                awardBG:setVisible(true)
                giftBG:setVisible(false)



              if nil == awardBG:getChildByTag(1) then 
                local gameMultiple = self._scene._dataModel.m_secene.nFishMultiple
                --[[
                {
                  {2,3,4,5,6,7,8,9,10,12,15,18,20,25,30,40,150,200,300,400,400},

                  {2,3,4,5,6,7,8,9,10,12,15,18,20,25,30,40,150,200,300,400,1000}
                }
                --]]
                local startX = 0
                for i=1,18 do
                    startX = 0
                    if i ==10 then
                        startX = -30
                    end
                    if gameMultiple[i][1] == gameMultiple[i][2] then
                        local value = gameMultiple[i][1]
                        local mutiple = cc.LabelAtlas:create(string.format("%d:",value),"game_res/num_help.png",19,20,string.byte("0"))
                        mutiple:setTag(i)
                        mutiple:setPosition(90 + math.mod((i-1),5)*170, awardBG:getContentSize().height -145 -  math.floor((i-1)/5) * 70)
                        awardBG:addChild(mutiple)

                    else

                        local value = gameMultiple[i][1]
                        local mutiple = cc.LabelAtlas:create(string.format("%d",value),"game_res/num_help.png",19,20,string.byte("0"))
                        mutiple:setTag(i)
                        mutiple:setPosition(120 + startX + math.mod((i-1),5)*170, awardBG:getContentSize().height -145 - math.floor((i-1)/5) * 70)
                        awardBG:addChild(mutiple)


                        local sign = cc.Sprite:create()
                        sign:setAnchorPoint(0.5,0.5)
                        sign:initWithFile("game_res/num_clear_multiple.png",cc.rect(0,0,16,17))
                        sign:setPosition(120 + startX + math.mod((i-1),5)*170, awardBG:getContentSize().height -151 -  math.floor((i-1)/5) * 70)
                        awardBG:addChild(sign)


                        local _value = gameMultiple[i][2]
                        local _mutiple = cc.LabelAtlas:create(string.format("%d:",_value),"game_res/num_help.png",19,20,string.byte("0"))
                        _mutiple:setTag(i)
                        _mutiple:setPosition(130 + startX + math.mod((i-1),5)*170, awardBG:getContentSize().height -160 - math.floor((i-1)/5) * 70)
                        awardBG:addChild(_mutiple)
    
                    end
                end  
             end

            end
        end)

        btnGift:addTouchEventListener(function ( sender , eventType )
            if eventType == ccui.TouchEventType.ended then
                operateBG:setVisible(false)
                awardBG:setVisible(false)
                giftBG:setVisible(true)

            end
        end)

        --关闭
         btnClose:addTouchEventListener(function ( sender , eventType )
            if eventType == ccui.TouchEventType.ended then
                bg:removeFromParent()
            end
        end)

    elseif 3 == tag then --设置

        local bMute = false

        local  bg = addBG()

        local csbNode = ExternalFun.loadCSB("game_res/Setting.csb", bg)
        csbNode:setAnchorPoint(0.5,0.5)
        csbNode:setPosition(yl.WIDTH/2,yl.HEIGHT/2)

        local Image_setBG = csbNode:getChildByName("Image_setBG")
        local btnClose = Image_setBG:getChildByName("bt_close")


         btnClose:addTouchEventListener(function ( sender , eventType )
            if eventType == ccui.TouchEventType.ended then
                bg:removeFromParent()
            end
        end)

--静音按钮
        local muteBtn = Image_setBG:getChildByName("btn_mute")
        
        if  GlobalUserItem.bVoiceAble or GlobalUserItem.bSoundAble then
            muteBtn:loadTextureNormal("setting_res/bt_off.png")
        end

        
        if (self._tag == 0) and not (GlobalUserItem.bVoiceAble and GlobalUserItem.bSoundAble) then
            self._tag = 1
        end

        muteBtn:addTouchEventListener(function( sender,eventType )

            if eventType == ccui.TouchEventType.ended then

                GlobalUserItem.bVoiceAble = not GlobalUserItem.bVoiceAble
                GlobalUserItem.bSoundAble = GlobalUserItem.bVoiceAble

                if  self._tag == 1 then
                    self._tag = 2
                    muteBtn:loadTextureNormal("setting_res/bt_on.png")
                    AudioEngine.setMusicVolume(0)
                    AudioEngine.pauseMusic() 
                    GlobalUserItem.bSoundAble = false
                    GlobalUserItem.bVoiceAble = false
                    return
                end

                if GlobalUserItem.bVoiceAble then

                    muteBtn:loadTextureNormal("setting_res/bt_off.png")
                    AudioEngine.resumeMusic()
                    AudioEngine.setMusicVolume(1.0)     
                else
                    muteBtn:loadTextureNormal("setting_res/bt_on.png")
                    AudioEngine.setMusicVolume(0)
                    AudioEngine.pauseMusic() -- 暂停音乐
                end
            end
        end)

        local  btn_color_name = {
        {"setting_res/BT_blue_0.png", "setting_res/BT_blue_1.png"},
        {"setting_res/BT_green_0.png", "setting_res/BT_green_1.png"},
        {"setting_res/BT_purple_0.png", "setting_res/BT_purple_1.png"},
        {"setting_res/BT_red_0.png", "setting_res/BT_red_1.png"},
        {"setting_res/BT_yollew_0.png", "setting_res/BT_yollew_1.png"},
    }
    local im_net = Image_setBG:getChildByName("im_net")
    local im_net_dot = Image_setBG:getChildByName("im_net_dot")
        for i = 1,5 do
            local btn_color = Image_setBG:getChildByName(string.format("btn_color_%d", i))
            btn_color:setTag(i)
            if i == self.netColorIndex then
                btn_color:loadTextures(btn_color_name[i][2],btn_color_name[i][1],btn_color_name[i][2])
            else
                btn_color:loadTextures(btn_color_name[i][1],btn_color_name[i][2],btn_color_name[i][1])
            end


            btn_color:addTouchEventListener(function( sender,eventType )
            if eventType == ccui.TouchEventType.ended then
            local tag = btn_color:getTag()
                if tag == self.netColorIndex then
                    --btn_color:loadTextureNormal("setting_res/bt_on.png")
                else
                    btn_color:loadTextures(btn_color_name[tag][2],btn_color_name[tag][1],btn_color_name[tag][2])
                    local btn_color2 = Image_setBG:getChildByName(string.format("btn_color_%d", self.netColorIndex))
                    btn_color2:loadTextures(btn_color_name[self.netColorIndex][1],btn_color_name[self.netColorIndex][2],btn_color_name[self.netColorIndex][1])
                    self.netColorIndex = tag
                    im_net_dot:setColor(self._scene._dataModel:getNetColor(tag))
                    --im_net_dot:setBlendFunc(gl.SRC_ALPHA,gl.ONE)
                end
            end
        end)
        end
        

    else --结算
        local  bg = addBG()

        local csbNode = ExternalFun.loadCSB("game_res/GameClear.csb", bg)
        csbNode:setAnchorPoint(0.5,0.5)
        csbNode:setPosition(yl.WIDTH/2,yl.HEIGHT/2)

        --按钮
        local quit = csbNode:getChildByName("btn_gameQuit")
        quit:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                 self._scene.m_bLeaveGame = true
                 self._scene:unSchedule()
                 self._scene._gameFrame:StandUp(1)
            end
        end)

        local back = csbNode:getChildByName("btn_gameBack")
        back:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                 bg:removeFromParent()
            end
        end)

        local back2 = csbNode:getChildByName("btn_gameBack2")
        back2:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                 bg:removeFromParent()
            end
        end)

 --子弹消耗
       local bulletConsum = csbNode:getChildByName("Text_bulletConsum")
       bulletConsum:setString(string.format("%d",self._scene._dataModel.m_secene.lBulletConsume[1][self._scene.m_nChairID+1])) 
       --local  pos  = cc.p(bulletConsum:getPositionX(),bulletConsum:getPositionY())
       --local anrchor = bulletConsum:getAnchorPoint()
      -- bulletConsum:removeFromParent()

       --bulletConsum = cc.LabelAtlas:create(string.format("%d",self._scene._dataModel.m_secene.lBulletConsume[1][self._scene.m_nChairID+1]),"game_res/num_award.png",21,21,string.byte("0"))
       --bulletConsum:setPosition(pos.x, pos.y)
       --bulletConsum:setAnchorPoint(anrchor)
       --csbNode:addChild(bulletConsum)

  
  --捕鱼收获
       local getNum = self._scene._dataModel.m_getFishScore
       local fishGet = csbNode:getChildByName("Text_fishGet") 
       fishGet:setString(string.format("%d",getNum))
       --[[ 
       pos  = cc.p(fishGet:getPositionX(),fishGet:getPositionY())
       anrchor = fishGet:getAnchorPoint()
       fishGet:removeFromParent()

       fishGet = cc.LabelAtlas:create(string.format("%d",getNum),"game_res/num_award.png",21,21,string.byte("0"))
       fishGet:setPosition(pos.x, pos.y)
       fishGet:setAnchorPoint(anrchor)
       csbNode:addChild(fishGet)  
        ]]--
    --dump(self._scene._dataModel.m_secene.nFishMultiple, "nFishMultiple", 6)
        --[[
       local gameMultiple = 
       {
            {2,3,4,5,6,7,8,9,10,12,15,18,20,25,30,40,150,200,300,400,400},

            {2,3,4,5,6,7,8,9,10,12,15,18,20,25,30,40,150,200,300,400,1000}
       }
       --]]
       local gameMultiple = self._scene._dataModel.m_secene.nFishMultiple
       local startX  = 0
        for i=1,18 do
            startX  = 0
            if i == 18 then
                startX = 52
            end
            ---[[
            if gameMultiple[i][1] == gameMultiple[i][2] then
                local value = gameMultiple[i][1]
                local mutiple = cc.LabelAtlas:create(string.format("%d.",value),"game_res/num_clear_multiple.png",16,17,string.byte("-"))
                mutiple:setTag(i)
                mutiple:setPosition(-370 + startX + math.mod((i-1),5)*175, csbNode:getContentSize().height + 123 -  math.floor((i-1)/5) * 70)
                csbNode:addChild(mutiple)

            else

                local value = gameMultiple[i][1]
                local mutiple = cc.LabelAtlas:create(string.format("%d",value),"game_res/num_clear_multiple.png",16,17,string.byte("-"))
                mutiple:setTag(i)
                mutiple:setPosition(-370 + startX + math.mod((i-1),5)*175, csbNode:getContentSize().height + 123 -  math.floor((i-1)/5) * 70)
                csbNode:addChild(mutiple)


                local sign = cc.Sprite:create()
                sign:setAnchorPoint(0.5,0.5)
                sign:initWithFile("game_res/num_clear_multiple.png",cc.rect(0,0,16,17))
                sign:setPosition(-360 + startX + math.mod((i-1),5)*175, csbNode:getContentSize().height + 113 -  math.floor((i-1)/5) * 70)
                csbNode:addChild(sign)


                local _value = gameMultiple[i][2]
                local _mutiple = cc.LabelAtlas:create(string.format("%d.",_value),"game_res/num_clear_multiple.png",16,17,string.byte("-"))
                _mutiple:setTag(i)
                _mutiple:setPosition(-350 + startX + math.mod((i-1),5)*175, csbNode:getContentSize().height + 106 -  math.floor((i-1)/5) * 70)
                csbNode:addChild(_mutiple)
            
            end

            --]]
            local count = self._scene.m_catchFishCount[i]
            --[[
            if i == 18 then
                startX = 52
            end
            --]]
            local sign = cc.Sprite:create()
            sign:setAnchorPoint(0.5,0.5)
            sign:initWithFile("game_res/num_clear_strip.png",cc.rect(17*12,0,17,15))
            sign:setPosition(-346 + startX + math.mod((i-1),5)*175, csbNode:getContentSize().height + 155 -  math.floor((i-1)/5) * 70)
            csbNode:addChild(sign)

            local _count = cc.LabelAtlas:create(string.format("%d",count),"game_res/num_clear_strip.png",17,15,string.byte("0"))
            _count:setTag(i)
            _count:setPosition(-336 + startX + math.mod((i-1),5)*175, csbNode:getContentSize().height + 148 -  math.floor((i-1)/5) * 70)
            csbNode:addChild(_count)
         end

   --用户分数
        local userScore = csbNode:getChildByName("Text_totalScore")  
        userScore:setString(string.format("%d",self._scene._dataModel.m_secene.lPlayCurScore[1][self._scene.m_nChairID + 1]))
        --[[
        pos  = cc.p(userScore:getPositionX(),userScore:getPositionY())
        anrchor = userScore:getAnchorPoint()
        userScore:removeFromParent()

        userScore = cc.LabelAtlas:create(string.format("%d",GlobalUserItem.lUserScore),"game_res/num_award.png",21,21,string.byte("0"))
        userScore:setPosition(pos.x, pos.y)
        userScore:setAnchorPoint(anrchor)
        csbNode:addChild(userScore)    
        ]]--
    end
end


function GameViewLayer:ButtonEvent( sender , eventType)
    
    if eventType == ccui.TouchEventType.ended then

            local function getCannonPos()
                 --获取自己炮台
              local cannonPos = self._scene.m_nChairID
              if self._scene._dataModel.m_reversal then 
                 cannonPos = 5 - cannonPos
              end
              return cannonPos
            end

            local tag = sender:getTag()

            if tag == TAG.tag_autoshoot then --自动射击

              self._scene._dataModel.m_autoshoot = not self._scene._dataModel.m_autoshoot

              if self._scene._dataModel.m_autoshoot then
                  self._scene._dataModel.m_autolock = false
              end
  
              self:setAutoShoot(self._scene._dataModel.m_autoshoot,sender)
              local lock = self:getChildByTag(TAG.tag_autolock)
              self:setAutoLock(self._scene._dataModel.m_autolock,lock)

              local isauto = false

              if self._scene._dataModel.m_autoshoot or self._scene._dataModel.m_autolock then
                  isauto =  true
              end
             
              local cannon = self._scene.m_cannonLayer:getCannoByPos(getCannonPos() + 1)
              cannon:setAutoShoot(isauto)

              if self._scene._dataModel.m_autoshoot then
                  cannon:removeLockTag()
              end
                    
            elseif tag == TAG.tag_autolock then --自动锁定
                 
              self._scene._dataModel.m_autolock = not self._scene._dataModel.m_autolock
              if self._scene._dataModel.m_autolock then
                  self._scene._dataModel.m_autoshoot = false
              end
              
              local auto = self:getChildByTag(TAG.tag_autoshoot)
              self:setAutoShoot(self._scene._dataModel.m_autoshoot,auto)
              self:setAutoLock(self._scene._dataModel.m_autolock,sender) 

              local isauto = false

              if self._scene._dataModel.m_autoshoot or self._scene._dataModel.m_autolock then
                  isauto =  true
              end
             
              local cannon = self._scene.m_cannonLayer:getCannoByPos(getCannonPos() + 1)
              cannon:setAutoShoot(isauto)

              if self._scene._dataModel.m_autoshoot then
                  cannon:removeLockTag()
              end

              elseif tag == TAG.tag_Menu then --菜单

                local MenuBG = ccui.ImageView:create()
                MenuBG:setContentSize(cc.size(yl.WIDTH, yl.HEIGHT))
                MenuBG:setScale9Enabled(true)
                MenuBG:setPosition(yl.WIDTH/2, yl.HEIGHT/2)
                MenuBG:setTouchEnabled(true)
                self:addChild(MenuBG,21)
                MenuBG:addTouchEventListener(function (sender,eventType)
                    if eventType == ccui.TouchEventType.ended then
                        MenuBG:removeFromParent()
                    end
                end)


                --添加菜单背景
                local bg = ccui.ImageView:create("game_res/im_bt_frame.png")
                bg:setScale9Enabled(true)
                bg:setContentSize(cc.size(bg:getContentSize().width, 380))
                bg:setAnchorPoint(1.0,0.0)

                bg:setPosition(yl.WIDTH - 5, -260)
                MenuBG:addChild(bg)

                bg:runAction(cc.MoveTo:create(0.2,cc.p(yl.WIDTH-5,60)))

                local function subCallBack( sender , eventType )
                    if eventType == ccui.TouchEventType.ended  then
                        sender:getParent():getParent():removeFromParent()
                        self:subMenuEvent(sender,eventType)
                    end
                end

                --添加子菜单
                local bank = ccui.Button:create("game_res/bt_bank_0.png","game_res/bt_bank_1.png")
                bank:setTag(1)
                bank:addTouchEventListener(subCallBack)
                bank:setPosition(bg:getContentSize().width/2, bg:getContentSize().height - 53)
                bg:addChild(bank)

                local help = ccui.Button:create("game_res/bt_help_0.png","game_res/bt_help_1.png")
                help:setTag(2)
                help:addTouchEventListener(subCallBack)
                help:setPosition(bg:getContentSize().width/2, bg:getContentSize().height - 143)
                bg:addChild(help)

                local set = ccui.Button:create("game_res/bt_setting_0.png","game_res/bt_setting_1.png")
                set:setTag(3)
                set:addTouchEventListener(subCallBack)
                set:setPosition(bg:getContentSize().width/2, bg:getContentSize().height - 143 - 90 - 5)
                bg:addChild(set)

                local clear = ccui.Button:create("game_res/bt_clearing_0.png","game_res/bt_clearing_1.png")
                clear:setTag(4)
                clear:addTouchEventListener(subCallBack)
                clear:setPosition(bg:getContentSize().width/2, bg:getContentSize().height - 143 - 180 - 5)
                bg:addChild(clear)

            end
    end
end


function GameViewLayer:Showtips( tips )
  
    local lb =  cc.Label:createWithTTF(tips, "fonts/round_body.ttf", 20)
    local bg = ccui.ImageView:create("game_res/clew_box.png")
    lb:setTextColor(cc.YELLOW)
    bg:setScale9Enabled(true)
    bg:setContentSize(cc.size(lb:getContentSize().width + 60  , 40))
    bg:setScale(0.1)
    lb:setPosition(bg:getContentSize().width/2, 20)
    bg:addChild(lb)

    self:ShowTipsForBg(bg)

end

function GameViewLayer:ShowCoin( score,wChairID,pos,fishtype,ftype )

  --print("score.."..score.."wChairID.."..wChairID.."fishtype.."..fishtype)

  self._scene._dataModel:playEffect(g_var(cmd).Coinfly)

  local cannonPos = wChairID
--获取炮台
  if self._scene._dataModel.m_reversal then 
     cannonPos = 5 - cannonPos
   end

   local cannon = self._scene.m_cannonLayer:getCannoByPos(cannonPos + 1)

   if nil == cannon then
      return
   end

   local panim = nil
   local coinnum = 0
   local framstr
   local distant = 50.0

   if nfishtype == g_var(cmd).FISH_YUAN_BAO then

        panim = cc.AnimationCache:getInstance():getAnimation(g_var(cmd).YBAnim)
        framstr = "gold_coin_0.png"
        coinnum = 1

    elseif nfishtype == g_var(cmd).FISH_SHA_YU then

        panim = cc.AnimationCache:getInstance():getAnimation(g_var(cmd).GoldAnim)
        framstr = "gold_coin_0.png"
        coinnum = 10

    elseif score <= 100 then

        panim = cc.AnimationCache:getInstance():getAnimation(g_var(cmd).CopperAnim)
        framstr = "copper_coin_0.png"
        coinnum = score / 10

    elseif score <= 1000 then

        panim = cc.AnimationCache:getInstance():getAnimation(g_var(cmd).SilverAnim)
        framstr = "silver_coin_0.png"
        coinnum = score / 100

    else
        
        panim = cc.AnimationCache:getInstance():getAnimation(g_var(cmd).GoldAnim)
        framstr = "gold_coin_0.png"
        coinnum = score / 1000
        if score % 1000 ~= 0 then
            coinnum = coinnum + 1  
        end
          --todo  
    end

    local paction = cc.RepeatForever:create(cc.Animate:create(panim))

    if coinnum == 0 then
        coinnum = 1
    end

    if coinnum >= 10 then
        coinnum = 10
    end
    local node = cc.Node:create()
    node:setAnchorPoint(0.5,0.5)
    node:setContentSize(cc.size(distant*5 , distant*4))
  
    if coinnum > 5 then
        node:setContentSize(cc.size(distant*5 , distant*2+40))
    end

    node:setPosition(pos.x, pos.y)
    self._scene.m_cannonLayer:addChild(node,1)

    local ptext = cc.LabelAtlas:create(string.format("%d", score),"game_res/num_game_gold.png",37,34,string.byte("0"))
     ptext:setAnchorPoint(0.5,0.5)
     ptext:setPosition(node:getContentSize().width/2, node:getContentSize().height-140)
     node:addChild(ptext)
     local call = cc.CallFunc:create(function()
       ptext:removeFromParent()
     end)

     ptext:runAction(cc.Sequence:create(cc.DelayTime:create(1.0),call))

     local secondNum = coinnum
     if coinnum > 5 then
        secondNum = 5  
     end

     local node1 = cc.Node:create()
     node1:setContentSize(cc.size(distant*secondNum, distant))
     node1:setAnchorPoint(0.5,0.5)
     node1:setPosition(node:getContentSize().width/2, distant/2)
     node:addChild(node1)

     for i=1,secondNum do
       local pcoin

       local pscale = 1
       if nfishtype == g_var(cmd).FISH_YUAN_BAO then
            pcoin = cc.Sprite:create("game_res/im_yb_end.png",cc.rect(0, 0, 164,227.5))
        else
            pcoin = cc.Sprite:createWithSpriteFrameName(framstr)
            pscale = distant/pcoin:getContentSize().width
       end
       pcoin:setScale(pscale)
       pcoin:runAction(paction:clone())
       pcoin:setPosition(distant/2+(i-1)*distant, distant/2)
       node1:addChild(pcoin)
     end

     if coinnum > 5 then
       local firstNum = coinnum - 5
       local node2 = cc.Node:create()
       node2:setContentSize(cc.size(distant*firstNum, distant))
       node2:setAnchorPoint(0.5,0.5)
       node2:setPosition(node:getContentSize().width/2, distant*3/2)
       node:addChild(node2)
       for i=1,firstNum do
            local pcoin
            local pscale = 1
            if nfishtype == g_var(cmd).FISH_YUAN_BAO then
                pcoin = cc.Sprite:create("game_res/im_yb_end.png",cc.rect(0, 0, 164,227.5))
            else
                pcoin = cc.Sprite:createWithSpriteFrameName(framstr)
                pscale = distant/pcoin:getContentSize().width
            end
            pcoin:setScale(pscale)
            pcoin:runAction(paction:clone())
            pcoin:setPosition(distant/2+(i-1)*distant, distant/2)
            node2:addChild(pcoin)
       end
     end
     local cannonPosition = cc.p(cannon:getPositionX(),cannon:getPositionY())
     local call = cc.CallFunc:create(function()
        node:removeFromParent()
        --[[
        local userid = self._scene.m_cannonLayer:getUserIDByCannon(cannonPos+1)
        local userItem = self._scene._gameFrame._UserList[userid]
        print("getUserIDByCannon userid ......" .. tostring(userid))
        --print("lIngot ......" .. tostring(userItem.lIngot))
        if userItem ~= nil then
            if ftype == g_var(cmd).EST_YuanBao then
                self._scene._gameFrame._UserList[userid].lIngot = self._scene._gameFrame._UserList[userid] + score
                cannon:updateIngot(self._scene._gameFrame._UserList[userid].lIngot)
            else
                self._scene._dataModel.m_secene.lPlayCurScore[1][wChairID + 1] = self._scene._dataModel.m_secene.lPlayCurScore[1][wChairID + 1] + score
                cannon:updateScore(self._scene._dataModel.m_secene.lPlayCurScore[1][wChairID + 1])   
            end        
        end
        --]]
  end)

  node:runAction(cc.Sequence:create(cc.MoveBy:create(1.0,cc.p(0,40)),cc.MoveTo:create(0.35,cannonPosition),call))

  local paction1 = cc.Sequence:create(cc.DelayTime:create(2),cc.FadeTo:create(0.3,0))

  local children = node:getChildren()
  if nil ~= children then
    for k,v in pairs (children) do
        v:runAction(paction1:clone())
    end
  end
  
    --[[
    local playout = ccui.Layout:create()
    playout:setPosition(pos.x, pos.y)

    if coinnum >= 5 then
        playout:setContentSize(cc.size(distant*5 , distant*2 + 40))
    end

    playout:setAnchorPoint(0.5,0.5)
    --]]

end

function GameViewLayer:ShowAwardTip(data)


 local fishName = {"小黄鱼","小蓝鱼","小丑鱼","丝鲈鱼","神仙鱼","河豚鱼","灯笼鱼","八爪鱼","海龟","水母","剑鱼","魔鬼鱼","海豚","鲨鱼","蓝鲸","银鲸","金鲸","美人鱼"
    ,"炸弹","补给箱"}

  local labelList = {}

  local tipStr  = nil
  local tipStr1 = nil
  local tipStr2 = nil

  if data.nFishMultiple >= 50 then
    if data.nScoreType == g_var(cmd).EST_Cold then
       tipStr = "捕中了"..fishName[data.nFishType+1]..",获得"
    elseif data.nScoreType == g_var(cmd).EST_Laser then
       tipStr = "使用激光,获得"
    elseif data.nScoreType == g_var(cmd).EST_Kill then
       tipStr = "击中炸弹鱼，获得"
    end

  tipStr1 = string.format("%d倍 %d分数",data.nFishMultiple,data.lFishScore)
  if data.nFishMultiple > 500 then
     tipStr2 = "超神了!!!"
  elseif data.nFishMultiple == 19 then
       tipStr2 = "运气爆表!!!"   
  else
      tipStr2 = "实力超群!!!"     
  end

  local name = data.szPlayName
  local tableStr = nil
  if data.wTableID == self._scene.m_nTableID  then 
    tableStr = "本桌玩家"

  else
       tableStr = string.format("第%d桌玩家",data.wTableID+1)

  end

  local lb1 =  cc.Label:createWithTTF(tableStr, "fonts/round_body.ttf", 20)
  lb1:setTextColor(cc.YELLOW)
  lb1:setAnchorPoint(0,0.5)
  table.insert(labelList, lb1)
 

  local lb2 =  cc.Label:createWithTTF(name, "fonts/round_body.ttf", 20)
  lb2:setTextColor(cc.RED)
  lb2:setAnchorPoint(0,0.5)
  table.insert(labelList, lb2)

  local lb3 =  cc.Label:createWithTTF(tipStr, "fonts/round_body.ttf", 20)
  lb3:setTextColor(cc.YELLOW)
  lb3:setAnchorPoint(0,0.5)
  table.insert(labelList, lb3)

  local lb4 =  cc.Label:createWithTTF(tipStr1, "fonts/round_body.ttf", 20)
  lb4:setTextColor(cc.RED)
  lb4:setAnchorPoint(0,0.5)
  table.insert(labelList, lb4)

  local lb5 =  cc.Label:createWithTTF(tipStr2, "fonts/round_body.ttf", 20)
  lb5:setTextColor(cc.YELLOW)
  lb5:setAnchorPoint(0,0.5)
  table.insert(labelList, lb5)

  else

    local lb1 =  cc.Label:createWithTTF("恭喜你捕中了补给箱,获得", "fonts/round_body.ttf", 20)
    lb1:setTextColor(cc.YELLOW)
    lb1:setAnchorPoint(0,0.5)

    local lb1 =  cc.Label:createWithTTF(string.format("%d倍 %d分数 !", data.nFishMultiple,data.lFishScore), "fonts/round_body.ttf", 20)
    lb1:setTextColor(cc.RED)
    lb1:setAnchorPoint(0,0.5)

    table.insert(labelList, lb1)
    table.insert(labelList, lb2)

  end



  local length = 60
  for i=1,#labelList do
    local lb = labelList[i]
    lb:setPosition(length - 30 , 20)
    length =  length + lb:getContentSize().width + 5 
  end

    print("game_res/clew_box.png before")
   local bg = ccui.ImageView:create("game_res/clew_box.png")
   print("game_res/clew_box.png after")
    bg:setScale9Enabled(true)
  
    bg:setContentSize(length,40)
    bg:setScale(0.1)

    for i=1,#labelList do
      local lb = labelList[i]
      bg:addChild(lb)
    end

    self:ShowTipsForBg(bg)
    labelList = {}
end


function GameViewLayer:ShowTipsForBg( bg )
    print("ShowTipsForBg 1")
  local infoCount = #self._scene.m_infoList
  local sublist = {}

  while infoCount >= 3 do
    print("ShowTipsForBg infoCount ",infoCount)
    local node = self._scene.m_infoList[1]
    table.remove(self._scene.m_infoList,1)
    node:removeFromParent()

    for i=1,#self._scene.m_infoList do
      local bg = self._scene.m_infoList[i]
      bg:runAction(cc.MoveBy:create(0.2,cc.p(0,60)))
    end

    infoCount = #self._scene.m_infoList
  end

  bg:setPosition(yl.WIDTH/2, yl.HEIGHT-120-60*infoCount)
  self:addChild(bg,30)
  table.insert(self._scene.m_infoList, bg)

  local call = cc.CallFunc:create(function()
    bg:removeFromParent()
    for i=1,#self._scene.m_infoList do
      local _bg = self._scene.m_infoList[i]
      if bg == _bg then
        table.remove(self._scene.m_infoList,i)
        break
      end
    end

    if #self._scene.m_infoList > 0 then
      for i=1,#self._scene.m_infoList do

       local _bg = self._scene.m_infoList[i]
          _bg:runAction(cc.MoveBy:create(0.2,cc.p(0,60)))

       end
    end

  end)

  bg:runAction(cc.Sequence:create(cc.ScaleTo:create(0.17,1.0),cc.DelayTime:create(5),cc.ScaleTo:create(0.17,0.1,1.0),call)) 
end

function GameViewLayer:showLight(fishtype, nFishIndex)
    local fishList = {}
    local fish = self._scene._dataModel.m_fishList[fishIndex]
    if nil == fish then
         return
    end
    local rect = cc.rect(0,0,yl.WIDTH,yl.HEIGHT)

    for k,v in pairs(self._scene._dataModel.m_fishList) do
        if v.fishCreateData.nFishType == fishtype and v.fishCreateData.nFishIndex ~= nFishIndex then
            table.insert(fishList,v)
        end
    end
    if fishList == nil then
        return
    end

    local fishpoint = cc.p(fish:getPositionX(), fish:getPositionY())
    if self._scene._dataModel.m_reversal then
        fishpoint = cc.p(yl.WIDTH - fish:getPositionX(), yl.HEIGHT - fish:getPositionY())
    end
    self:showBall(fishpoint)

    for k,v in pairs(fishlist) do
        local point = cc.p(v:getPositionX(), v:getPositionY())
        if self._scene._dataModel.m_reversal then
            point = cc.p(yl.WIDTH - v:getPositionX(), yl.HEIGHT - v:getPositionY())
        end
        self:showBall(point)
        self:showLight2(fishpoint.x, fishpoint.y, point.x , point.y)
    end
 end   

function GameViewLayer:showLight2(point1X, point1Y, point2X, point2Y)

    local distant = cc.pGetDistance(cc.p(point1X,point1Y),cc.p(point2X,point2Y))
    local pscaley = distant / 256
    local angle = self._scene._gameFrame:getAngleByTwoPoint(point1, point2)
    local plight1 = cc.Sprite:create("game_res/fish_bomb_light.png", cc.rect(0, 0, 60, 256))
    plight1:setPosition(cc.p((point1.x + point2.x) / 2), cc.p((point1.y + point2.y) / 2))
    plight1:setColor(cc.c3b(255, 255, 0))
    plight1:setOpacity(255)
    plight1:setRotation(angle)
    plight1:setScaleY(pscaley)
    plight1:setBlendFunc(gl.SRC_ALPHA,gl.ONE)
    self:addChild(plight1,6)

    local plight2 = cc.Sprite:create("game_res/fish_bomb_light.png", cc.rect(0, 0, 60, 256))
    plight2:setPosition(cc.p((point1.x + point2.x) / 2), cc.p((point1.y + point2.y) / 2))
    plight2:setColor(cc.c3b(0, 215, 255))
    plight2:setOpacity(150)
    plight2:setRotation(angle)
    plight2:setScaleY(pscaley)
    plight2:setBlendFunc(gl.SRC_ALPHA,gl.ONE)
    self:addChild(plight2,6)

    local anim = cc.AnimationCache:getInstance():getAnimation(g_var(cmd).FishLight)
    local panim = cc.Repeat:create(cc.Animate:create(anim), 5)
    --local panim = cc.Repeat:create(cc.Animate:create(cc.AnimationCache:getInstance:getAnimation(g_var(cmd).FishLight)), 5)
    local call1 = cc.CallFunc:create(function()
            plight1:removeFromParent()
        end)
    local call2 = cc.CallFunc:create(function()
            plight2:removeFromParent()
        end)
    plight1:runAction(cc.Sequence:create(panim, call1)) 
    plight2:runAction(cc.Sequence:create(panim, call2))
end

function GameViewLayer:showBall(pos)
    local pball1 = cc.Sprite:create("game_res/fish_bomb_ball.png", cc.rect(0, 0, 70, 70))
    pball1:setPosition(pos)
    pball1:setColor(cc.c3b(255, 255, 0))
    pball1:setOpacity(255)
    pball1:setBlendFunc(gl.SRC_ALPHA,gl.ONE)
    self:addChild(pball1,6)

    local pball2 = cc.Sprite:create("game_res/fish_bomb_ball.png", cc.rect(0, 0, 70, 70))
    pball2:setPosition(pos)
    pball2:setColor(cc.c3b(255, 255, 0))
    pball2:setOpacity(150)
    pball2:setBlendFunc(gl.SRC_ALPHA,gl.ONE)
    self:addChild(pball2,6)

    local anim = cc.AnimationCache:getInstance():getAnimation(g_var(cmd).FishBall)
    local panim = cc.Repeat:create(cc.Animate:create(anim), 3)
    --local panim = cc.Repeat:create(cc.Animate:create(cc.AnimationCache:getInstance:getAnimation(g_var(cmd).FishBall)), 3)
    

    local call1 = cc.CallFunc:create(function()
            pball1:removeFromParent()
        end)
    local call2 = cc.CallFunc:create(function()
            pball1:removeFromParent()
        end)
    pball1:runAction(cc.Sequence:create(panim, call1)) 
    pball2:runAction(cc.Sequence:create(panim, call2))
end

return GameViewLayer
