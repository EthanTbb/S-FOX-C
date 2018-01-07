--
-- Author: Tang
-- Date: 2016-12-08 15:41:53
--
local GameViewLayer = class("GameViewLayer",function(scene)
		local gameViewLayer =  display.newLayer()
    return gameViewLayer
end)
local module_pre = "game.yule.gobang.src"

local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local g_var = ExternalFun.req_var
local ClipText = appdf.EXTERNAL_SRC .. "ClipText"
local PopupInfoHead = appdf.EXTERNAL_SRC .. "PopupInfoHead"

local cmd = module_pre .. ".models.cmd_game"
local Clock = module_pre..".views.layer.Clock"
local Chess = module_pre..".views.layer.Chess"
local game_cmd = appdf.HEADER_SRC .. "CMD_GameServer"
local QueryDialog   = require("app.views.layer.other.QueryDialog")
GameViewLayer.Enum = 
{

 
    TAG_CHESS               = 5, --+225
    TAG_RECTCUR             = 240,

    TAG_BTN_READY           = 241,
    TAG_BTN_PEACE           = 242,
    TAG_BTN_LOSE            = 243,
    TAG_BTN_REGRET          = 244,
    TAG_BTN_COACH           = 245,
    TAG_BTN_MENU            = 246,
    TAG_BTN_SET             = 247,
    TAG_BTN_BACK            = 248,
    TAG_IMAGE_OVER          = 249,
    TAG_CHESSTAG            = 250,
    TAG_CLOCK               = 300,

    TAG_ALERT               = 400

}

local TAG = GameViewLayer.Enum
GameViewLayer.TopZorder = 30
GameViewLayer.MenuZorder = 20

function GameViewLayer:ctor(scene)

  self._scene = scene

  self.m_lCoach = 0   --指导费
  self._stepRecord = {}  

  self._cancellTime = 0
  self._cancellCall = nil
  self._cancellLabel= nil

  self._bAllowPlaceChess= true   --控制每次下一颗棋

  self:gameDataInit()

  	--初始化csb界面
  self:initCsbRes()

  self:initGame()

  	 --注册事件
  ExternalFun.registerTouchEvent(self,true)
end

function GameViewLayer:onExit()
  self:gameDataReset()
end

function GameViewLayer:resetData()
  self._stepRecord = {}  
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

    self.m_bMusic = true
    AudioEngine.playMusic("game_res/back_music.mp3",false)
end

function GameViewLayer:gameDataReset()

  --播放大厅背景音乐
  self.m_bMusic = false
  AudioEngine.stopMusic()
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

  cc.AnimationCache:getInstance():removeAnimation("box_effect")

end

function GameViewLayer:initCsbRes()
    local rootLayer, csbNode = ExternalFun.loadRootCSB("game_res/Game.csb",self)
    self._rootNode = csbNode

    self:initButtonEvent()
    self:showUserInfo(self._scene:GetMeUserItem())
end

function GameViewLayer:initGame()
 
    --棋盘每格添加NODE
    for row=1,self._scene._dataModle._nRows do
        for col=1,self._scene._dataModle._nColumns do
            local chess = g_var(Chess):create(self._scene._dataModle)
            chess:setTag(TAG.TAG_CHESS+(row-1)*self._scene._dataModle._nColumns+col)
            chess:setCurPos(row,col)
            chess:setPosition(cc.p(339 + (col - 1)*47,714 - (row - 1)*47))
            self:addChild(chess)
        end
    end


  --加载动画
  local frames = {}
  local actionTime = 0.05
  for i=1,32 do
    local frameName = "game_res/box_effect/QiHe_Effect_"..string.format("%02d.png", i-1)
    local frame = cc.SpriteFrame:create(frameName,cc.rect(0,0,128,128))
    table.insert(frames, frame)
  end

  local  animation =cc.Animation:createWithSpriteFrames(frames,actionTime)
  cc.AnimationCache:getInstance():addAnimation(animation, "box_effect")
 
end

function GameViewLayer:showReadyBtn(isShow)
    if not self:getChildByTag(TAG.TAG_BTN_READY) then 
          local  ready = ccui.Button:create("game_res/btn_ready.png","game_res/btn_ready_1.png")
          ready:setTag(TAG.TAG_BTN_READY)
          ready:setPosition(cc.p(667,150))
          ready:addTouchEventListener(handler(self, self.onEvent))
          self:addChild(ready,GameViewLayer.TopZorder)
    end

    self:getChildByTag(TAG.TAG_BTN_READY):setVisible(isShow)

end

function GameViewLayer:convertLogicPosToView(pos,color,isSelf)
     local viewPos = {x = pos.cbYPos+1,y = pos.cbXPos+1}
     local  chessNode = self:getChildByTag(TAG.TAG_CHESS+(viewPos.x-1)*self._scene._dataModle._nColumns+viewPos.y)

     self._scene._dataModle:setSign(viewPos.x, viewPos.y,1)
     table.insert(self._stepRecord, {x=viewPos.x,y=viewPos.y})

     if not  isSelf  then
         local wOtherSideChairID = math.mod((self._scene:GetMeUserItem().wChairID+1),g_var(cmd).GAME_PLAER) 
         self:insertRecord({x=viewPos.x,y=viewPos.y},wOtherSideChairID)

     else
     
         self:insertRecord({x=viewPos.x,y=viewPos.y},self._scene:GetMeUserItem().wChairID)
     end

     local  chess = ccui.ImageView:create(string.format("game_res/chess_%d.png", color))
     chess:setTag(1)
     chess:setPosition(cc.p(chessNode:getContentSize().width/2,chessNode:getContentSize().height/2))
     chessNode:addChild(chess)

     self:removeChildByTag(TAG.TAG_CHESSTAG)
     local chessTag  = ccui.ImageView:create("game_res/effect_chess.png")
     chessTag:setTag(TAG.TAG_CHESSTAG)
     chessTag:setPosition(cc.p(chessNode:getPositionX()-1,chessNode:getPositionY()+2))
     self:addChild(chessTag)
end

function GameViewLayer:initButtonEvent()
   
    local btn = self._rootNode:getChildByName("btn_menu")
    btn:setTag(TAG.TAG_BTN_MENU)
    btn:addTouchEventListener(handler(self, self.onEvent))

    --认输
    btn = self._rootNode:getChildByName("bt_lose")
    btn:setTag(TAG.TAG_BTN_LOSE)
    btn:addTouchEventListener(handler(self, self.onEvent))


    --求和
    btn = self._rootNode:getChildByName("btn_peace")
    btn:setTag(TAG.TAG_BTN_PEACE)
    btn:addTouchEventListener(handler(self, self.onEvent))

    --悔棋
    btn = self._rootNode:getChildByName("btn_regret")
    btn:setTag(TAG.TAG_BTN_REGRET)
    btn:addTouchEventListener(handler(self, self.onEvent))

    --指导费
    btn = self._rootNode:getChildByName("btn_coach")
    btn:setTag(TAG.TAG_BTN_COACH)
    btn:addTouchEventListener(handler(self, self.onEvent))

end


function GameViewLayer:showUserInfo( useritem )

    local headBG = self._rootNode:getChildByName("player_bg_"..string.format("%d",useritem.wChairID+1))
    if true == headBG:isVisible() then 
       return
    end

    headBG:setVisible(true)

    --时间
    local timeBG = self._rootNode:getChildByName("time_bg_"..string.format("%d",useritem.wChairID+1))
    timeBG:setVisible(true)

       --闹钟
    local clockPos = 
    {
        cc.p(114,265),
        cc.p(114,225),
        cc.p(1160,268),
        cc.p(1160,225)
    }

    for i=1,2 do
        local clock = g_var(Clock):create(self._scene)
        clock:setTag(TAG.TAG_CLOCK+useritem.wChairID*2+i)
        clock:setPosition(clockPos[useritem.wChairID*2+i])
        self._rootNode:addChild(clock)
    end

    --玩家头像
    local anr = {cc.p(0.0,0.0),cc.p(1.0,1.0)}
    local pos = {cc.p(334,220),cc.p(650,220)}

    local head = g_var(PopupInfoHead):createNormal(useritem, 200)
    head:setAnchorPoint(cc.p(0.5,0.5))
    head:setPosition(cc.p(134,222))
    headBG:addChild(head)
    head:enableInfoPop(true,pos[useritem.wChairID+1] , anr[useritem.wChairID+1])
    

    local nickNode = self._rootNode:getChildByName("user_nick_"..string.format("%d",useritem.wChairID+1))

    --玩家昵称
    local nick =  g_var(ClipText):createClipText(cc.size(120, 22),useritem.szNickName,"fonts/round_body.ttf",22);
    nick:setAnchorPoint(cc.p(0.5,0.5))
    nick:setPosition(cc.p(nickNode:getContentSize().width/2,nickNode:getContentSize().height/2))
    nickNode:addChild(nick)

    --用户游戏币
    local _scoreUser = 0
    local scoreNode = self._rootNode:getChildByName("user_scoreNode_"..string.format("%d",useritem.wChairID+1))
    if nil ~= useritem then
       _scoreUser = useritem.lScore;
    end 

    local str = ExternalFun.numberThousands(_scoreUser)
    if string.len(str) > 11 then
        str = string.sub(str,1,11) .. "...";
    end

    local coin =  cc.Label:createWithTTF(str, "fonts/round_body.ttf", 24)
    coin:setTextColor(cc.YELLOW)
    coin:setTag(1)
    coin:setAnchorPoint(cc.p(0.5,0.5))
    coin:setPosition(cc.p(scoreNode:getContentSize().width/2,scoreNode:getContentSize().height/2))
    scoreNode:addChild(coin)
    
end

function GameViewLayer:deleteUserInfo(useritem)
  if useritem == self._scene:GetMeUserItem() then
    return
  end

  local wOtherSideChairID = math.mod((self._scene:GetMeUserItem().wChairID+1),g_var(cmd).GAME_PLAER) 

  local headBG = self._rootNode:getChildByName("player_bg_"..string.format("%d",wOtherSideChairID+1))
  headBG:setVisible(false)

  --时间
  local timeBG = self._rootNode:getChildByName("time_bg_"..string.format("%d",wOtherSideChairID+1))
  timeBG:setVisible(false)

  for i=1,2 do
      local clock = self._rootNode:getChildByTag(TAG.TAG_CLOCK+wOtherSideChairID*2+i)
      if nil ~= clock then
        clock:removeFromParent()
      end
      
  end

  local headNode = self._rootNode:getChildByName("user_headNode_"..string.format("%d",wOtherSideChairID+1))
  local nickNode = self._rootNode:getChildByName("user_nick_"..string.format("%d",wOtherSideChairID+1))
  local scoreNode = self._rootNode:getChildByName("user_scoreNode_"..string.format("%d",wOtherSideChairID+1))
  headNode:removeAllChildren()
  nickNode:removeAllChildren()
  scoreNode:removeAllChildren()

end

--局时
function GameViewLayer:setRoundTime(sec)

  local _min = math.floor(sec/60)
  local _sec = math.mod(sec,60)

  --自己
  local clock = self._rootNode:getChildByTag(TAG.TAG_CLOCK + self._scene:GetMeUserItem().wChairID*2+1)
  clock:setTime(_min,_sec) 

  --玩家
  local wOtherSideChairID = math.mod((self._scene:GetMeUserItem().wChairID+1),g_var(cmd).GAME_PLAER) 
  print("the other user id is =================== > "..wOtherSideChairID*2+1)
 
  local clockOther =  self._rootNode:getChildByTag(TAG.TAG_CLOCK + wOtherSideChairID*2+1)
  if clockOther then
    clockOther:setTime(_min,_sec)
  end

end

--刷新步时
function GameViewLayer:UpdataClockTime(chair,time)

   if nil ~= self._scene.m_wLeftClock[chair+1] then
      self._scene.m_wLeftClock[chair+1] = self._scene.m_wLeftClock[chair+1] - 1
   end

   if 0 ~= self._cancellTime then
    self._cancellTime = self._cancellTime - 1
    self:updateCancellTime(self._cancellTime)

   end
   
   local clock = self._rootNode:getChildByTag(TAG.TAG_CLOCK + chair*2+2)
   if not clock then
     return
   end

   local _min = math.floor(time/60)
   local _sec = math.mod(time,60)
   clock:setTime(_min,_sec)

   if time == 0 then
      self._scene:KillGameClock()
      self:LogicTimeZero()
  end
end


function GameViewLayer:updateCancellTime(time)

    if nil ~= self._cancellLabel then
      self._cancellLabel:setString(string.format("%d",time))
    end
    
    if 0 == time then
       if nil ~= self._cancellCall then 
           self._cancellCall()
       end
    end
end



function GameViewLayer:setClockView(chair,time)
   local clock = self._rootNode:getChildByTag(TAG.TAG_CLOCK + chair*2+2)
   local _min = math.floor(time/60)
   local _sec = math.mod(time,60)

   if not clock then
     return
   end
   clock:setTime(_min,_sec)

end

function GameViewLayer:LogicTimeZero()
  if self._scene:GetMeUserItem().wChairID == self._scene.m_wCurrentUser then
    if self._scene.m_cbGameStatus == g_var(cmd).GS_GAME_FREE then
       self._scene:onExitTable()
    else
        local dataBuffer = CCmd_Data:create()
        self._scene:SendData(g_var(cmd).SUB_C_GIVEUP_REQ,dataBuffer)
    end
  end
end

function GameViewLayer:onEvent(sender ,eventType )
  
   local tag = sender:getTag()
   if eventType == ccui.TouchEventType.ended  then
      if tag == TAG.TAG_BTN_READY then
          self:onStartReady(sender,eventType)
      elseif tag == TAG.TAG_BTN_LOSE then
          self:onLose(sender, eventType) 
      elseif tag == TAG.TAG_BTN_PEACE then
          self:onPeace(sender, eventType)
      elseif tag == TAG.TAG_BTN_REGRET then
          self:onRegret(sender, eventType)   
      elseif tag == TAG.TAG_BTN_COACH then
          self:showCoachView()
      elseif tag == TAG.TAG_BTN_MENU then
          sender:loadTextureNormal("game_res/BT_menu_1.png")
          self:popMenu()            
     end
   end
end


function GameViewLayer:getParentNode()
	return self._scene
end

function GameViewLayer:getDataMgr( )
	return self:getParentNode():getDataMgr()
end

function GameViewLayer:showPopWait( )
	self:getParentNode():showPopWait()
end

function GameViewLayer:showReady(chair,isShow)
   local headBG = self._rootNode:getChildByName("player_bg_"..string.format("%d",chair+1))
   local readyIcon = headBG:getChildByName("icon_ready")
   if 1 == isShow then
      readyIcon:setVisible(true)
    elseif 0 == isShow then
      readyIcon:setVisible(false)  
   end
end

function GameViewLayer:showChessColor(chair,color)
  local node = self._rootNode:getChildByName("player_bg_"..string.format("%d",chair+1))
  node:removeChildByTag(10)
  local str 
  if color == 0 then
     str = "box_white.png"
  elseif color == 1 then
     str = "box_black.png" 
  end
  local chessBox = ccui.ImageView:create("game_res/"..str)
  chessBox:setAnchorPoint(cc.p(0.5,0.5))
  chessBox:setPosition(cc.p(54,328))
  chessBox:setTag(10)
  node:addChild(chessBox)

  local wOtherSideChairID = math.mod((chair+1),g_var(cmd).GAME_PLAER)
  local otherNode = self._rootNode:getChildByName("player_bg_"..string.format("%d",wOtherSideChairID+1))
  otherNode:removeChildByTag(10)
  if true ==  otherNode:isVisible() and not otherNode:getChildByTag(10) then 
      if color == 0 then
         str = "box_black.png"
      elseif color == 1 then
         str = "box_white.png" 
      end
      chessBox = ccui.ImageView:create("game_res/"..str)
      chessBox:setAnchorPoint(cc.p(0.5,0.5))
      chessBox:setPosition(cc.p(54,328))
      chessBox:setTag(10)
      otherNode:addChild(chessBox)
  end
  if self._scene.m_cbGameStatus ~= g_var(cmd).GS_GAME_FREE and self._scene.m_wCurrentUser ~= yl.INVALID_CHAIR then
       self:showBoxAnim(self._scene.m_wCurrentUser)
  end
end

function GameViewLayer:showBoxAnim(chair,isShow)
     local node = self._rootNode:getChildByName("player_bg_"..string.format("%d",chair+1))
     local chessBox = node:getChildByTag(10)

     local wOtherSideChairID = math.mod((chair+1),g_var(cmd).GAME_PLAER)
     local otherNode = self._rootNode:getChildByName("player_bg_"..string.format("%d",wOtherSideChairID+1))
     local otherChessBox  = otherNode:getChildByTag(10)
 
     local boxEffect = otherChessBox:getChildByTag(1)
     if nil ~= boxEffect then
        boxEffect:removeFromParent()
     end

     if nil ~= isShow then
        boxEffect = chessBox:getChildByTag(1)
        if nil ~= boxEffect then
          boxEffect:removeFromParent()
        end
        return
     end
    
     chessBox:removeChildByTag(1)
     boxEffect = cc.Sprite:create("game_res/box_effect/QiHe_Effect_00.png")
     boxEffect:setTag(1)
     boxEffect:setPosition(cc.p(chessBox:getContentSize().width/2-4,chessBox:getContentSize().height/2+3))
     chessBox:addChild(boxEffect)

     local animate = cc.AnimationCache:getInstance():getAnimation("box_effect")
     boxEffect:runAction(cc.RepeatForever:create(cc.Animate:create(animate)))

end

--回应
function GameViewLayer:ShowUserReq( req )
  local str
  if req == g_var(cmd).RegretReq then
      str = "对家请求{悔棋},您是否同意 ?"
      self:gobangAlert(str, 
      2, 
      function()
        self:OnRegretAnswer(1)
      end ,

      function()
        self:OnRegretAnswer(0)
      end)

                        
  elseif req == g_var(cmd).PeaceReq then

      str = "对家请求{和棋},您是否同意 ?" 
      self:gobangAlert(str,
       2, 
       function()
        self:OnPeaceAnswer(1)
       end,

       function()
         self:OnPeaceAnswer(0)
       end )
  end

end

function GameViewLayer:popMenu(sender)

  local  menuBtn  = self._rootNode:getChildByName("btn_menu")

  local menuview  = ccui.ImageView:create()
  menuview:setContentSize(cc.size(yl.WIDTH, yl.HEIGHT))
  menuview:setScale9Enabled(true)
  menuview:setPosition(yl.WIDTH/2, yl.HEIGHT/2)
  menuview:setTouchEnabled(true)
  self:addChild(menuview,GameViewLayer.MenuZorder)
  menuview:addTouchEventListener(function (sender,eventType)
          if eventType == ccui.TouchEventType.ended then

              menuBtn:loadTextureNormal("game_res/BT_menu_0.png")
              menuview:removeFromParent()
              
          end
        end)

  local menuBG = ccui.ImageView:create("game_res/menu_bg.png")
  menuBG:setTouchEnabled(true)
  menuBG:setAnchorPoint(cc.p(0.5,1.0))
  menuBG:setPosition(cc.p(980,750))
  menuview:addChild(menuBG)

 --设置
 local setBtn =  ccui.Button:create("game_res/BT_set_0.png","game_res/BT_set_1.png")
 setBtn:setAnchorPoint(cc.p(1.0,0.5))
 setBtn:setPosition(cc.p(menuBG:getContentSize().width/2-2,menuBG:getContentSize().height/2))
 setBtn:addTouchEventListener(function(sender,eventType)
         if eventType == ccui.TouchEventType.ended then
            menuBtn:loadTextureNormal("game_res/BT_menu_0.png")
            menuview:removeFromParent()
            self:setView()
         end
     
 end)
 menuBG:addChild(setBtn)

 --返回大厅
 local  back = ccui.Button:create("game_res/BT_quit_0.png","game_res/BT_quit_1.png")
 back:setAnchorPoint(cc.p(0.0,0.5))
 back:setPosition(cc.p(menuBG:getContentSize().width/2+2,menuBG:getContentSize().height/2))
 back:addTouchEventListener(function(sender,eventType)
         if eventType == ccui.TouchEventType.ended then
              self._scene:onExitTable()
         end
     
 end)
 menuBG:addChild(back)

end

function GameViewLayer:setView()

  local setView  = ccui.ImageView:create()
  setView:setContentSize(cc.size(yl.WIDTH, yl.HEIGHT))
  setView:setScale9Enabled(true)
  setView:setPosition(yl.WIDTH/2, yl.HEIGHT/2)
  setView:setTouchEnabled(true)
  self:addChild(setView,GameViewLayer.MenuZorder)
  setView:addTouchEventListener(function (sender,eventType)
          if eventType == ccui.TouchEventType.ended then
              setView:removeFromParent()
          end
        end)

  --加载CSB
  local csbnode = cc.CSLoader:createNode("game_res/Setting.csb");
  csbnode:setPosition(yl.WIDTH/2, yl.HEIGHT/2)
  setView:addChild(csbnode)

   --关闭按钮
  local btnClose = csbnode:getChildByName("btn_close")
  btnClose:addTouchEventListener(function ( sender,eventType )
       if eventType == ccui.TouchEventType.ended then
              setView:removeFromParent()
       end

  end)

  local quitBtn = csbnode:getChildByName("quit_btn")
   quitBtn:addTouchEventListener(function ( sender,eventType )
       if eventType == ccui.TouchEventType.ended then
           self.m_bMusic = not  self.m_bMusic 
           if false == self.m_bMusic then
              quitBtn:loadTextureNormal("game_res/BT_suond_1.png")
              AudioEngine.setMusicVolume(0)
              AudioEngine.pauseMusic() -- 暂停音乐
             
           else
              quitBtn:loadTextureNormal("game_res/BT_suond_0.png")
              AudioEngine.resumeMusic()
              AudioEngine.setMusicVolume(1.0) 
           end
       end
  end)
  
end

function GameViewLayer:showCoachView()
  print("self._scene.m_nCoachRestarin is ====================== >"..self._scene.m_nCoachRestarin)
  print("self._scene:GetMeUserItem().lScore is =================== >"..self._scene:GetMeUserItem().lScore)

  if self._scene.m_nCoachRestarin > self._scene:GetMeUserItem().lScore then 
      showToast(cc.Director:getInstance():getRunningScene(),"你携带的金币少于指导费最低限制,请取款或者充值!",2)
      return
  end

  local coachview  = ccui.ImageView:create()
  coachview:setContentSize(cc.size(yl.WIDTH, yl.HEIGHT))
  coachview:setScale9Enabled(true)
  coachview:setPosition(yl.WIDTH/2, yl.HEIGHT/2)
  coachview:setTouchEnabled(true)
  self:addChild(coachview,GameViewLayer.MenuZorder)
  coachview:addTouchEventListener(function (sender,eventType)
          if eventType == ccui.TouchEventType.ended then
              coachview:removeFromParent()
          end
        end)

  --加载CSB
  local csbnode = cc.CSLoader:createNode("game_res/Coach.csb");
  csbnode:setPosition(yl.WIDTH/2, yl.HEIGHT/2)
  coachview:addChild(csbnode)

  --对方昵称
  local nickNode = csbnode:getChildByName("user_nick")
  local str = self._scene._otherNick --or "玩家"
  local nick = cc.Label:createWithTTF(str, "fonts/round_body.ttf", 24)
  nickNode:addChild(nick)

  --Editbox
  local editbox = ccui.EditBox:create(cc.size(340, 63),"")
            :setPosition(cc.p(100,-28))
            :setFontName("fonts/round_body.ttf")
            :setPlaceholderFontName("fonts/round_body.ttf")
            :setFontSize(24)
            :setPlaceholderFontSize(24)
            :setMaxLength(9)
            :setInputMode(cc.EDITBOX_INPUT_MODE_PHONENUMBER)
            :setPlaceHolder(string.format("请输入不低于%d指导费", self._scene.m_nCoachRestarin))
        csbnode:addChild(editbox)

   --关闭按钮
  local btnClose = csbnode:getChildByName("btn_close")
  btnClose:addTouchEventListener(function ( sender,eventType )
       if eventType == ccui.TouchEventType.ended then
              coachview:removeFromParent()
          end
  end)

  --确定
  local sureBtn = csbnode:getChildByName("btn_sure")
  sureBtn:addTouchEventListener(function ( sender,eventType )
       if eventType == ccui.TouchEventType.ended then
              
       --参数判断
              local szScore = string.gsub( editbox:getText(),"([^0-9])","")
              if #szScore < 1 or tonumber(szScore) < self._scene.m_nCoachRestarin then 
                  showToast(cc.Director:getInstance():getRunningScene(),string.format("请输入不低于%d指导费!",self._scene.m_nCoachRestarin),2)
                  if #szScore>=1 then
                      editbox:setText("")
                  end 
                  coachview:removeFromParent()       
                  return
              end
             
              if tonumber(szScore) > self._scene:GetMeUserItem().lScore then 
                  showToast(cc.Director:getInstance():getRunningScene(),string.format("请输入少于%d指导费!",self._scene:GetMeUserItem().lScore ),2)
                  editbox:setText("")
                  coachview:removeFromParent()
                 return
              end
              coachview:removeFromParent()
              self.m_lCoach = tonumber(szScore)
              self:onCoach(sender, eventType)
              
        end
  end)

  --取消
  local cancellBtn = csbnode:getChildByName("btn_cancell")
  cancellBtn:addTouchEventListener(function ( sender,eventType )
       if eventType == ccui.TouchEventType.ended then
              coachview:removeFromParent()
          end
  end)

end

function GameViewLayer:gobangAlert(str,nType,OKCallback,CancellCallback,target)
      
  if self:getChildByTag(TAG.TAG_ALERT) then
      --self:removeChildByTag(TAG.TAG_ALERT)
      if nil ~= self._cancellCall then
          self._cancellCall() 
      end
      --[[self._cancellTime = 0
      self._cancellCall = nil
      self._cancellLabel = nil]]
  end

  local alert  = ccui.ImageView:create()
  alert:setTag(TAG.TAG_ALERT)
  alert:setContentSize(cc.size(yl.WIDTH, yl.HEIGHT))
  alert:setScale9Enabled(true)
  alert:setPosition(yl.WIDTH/2, yl.HEIGHT/2)
  alert:setTouchEnabled(true)
  self:addChild(alert,GameViewLayer.MenuZorder)
  alert:addTouchEventListener(function (sender,eventType)
          if eventType == ccui.TouchEventType.ended then
              alert:removeFromParent()
              self._cancellTime = 0
              self._cancellCall = nil
              self._cancellLabel = nil

              if nil ~= CancellCallback then
                CancellCallback() 
              end

              if nil ~= target then
                 target:setEnabled(true)
              end
          end
        end)

  --加载CSB
  local csbnode = cc.CSLoader:createNode("game_res/Alert.csb")
  csbnode:setPosition(yl.WIDTH/2, yl.HEIGHT/2)
  alert:addChild(csbnode)

  --关闭按钮
  local btnClose = csbnode:getChildByName("btn_close")
  btnClose:addTouchEventListener(function ( sender,eventType )
       if eventType == ccui.TouchEventType.ended then
              alert:removeFromParent()
              self._cancellTime = 0
              self._cancellCall = nil
              self._cancellLabel = nil

              if nil ~= target then
                 target:setEnabled(true)
              end
          end

  end)

  --content背景
  local contentBG = csbnode:getChildByName("alertBG")

  --内容
  local content =cc.Label:createWithTTF(str, "fonts/round_body.ttf", 24)
  content:setAnchorPoint(cc.p(0.5,0.5))
  content:setPosition(cc.p(324.5,189))
  contentBG:addChild(content)

  --按钮
  if nType == 1 then
    --确定
      local btnSure = ccui.Button:create("game_res/btn_sure_0.png","game_res/btn_sure_1.png")
      btnSure:setAnchorPoint(cc.p(0.5,0.5))
      btnSure:setPosition(cc.p(324.5,110))
      btnSure:addTouchEventListener(function(sender,eventType)
         if eventType == ccui.TouchEventType.ended then
              if nil ~= OKCallback then
               OKCallback()
              end
              self._cancellTime = 0
              self._cancellCall = nil
              self._cancellLabel = nil
              alert:removeFromParent()
          
         end
      end)
      contentBG:addChild(btnSure)
  else

      --同意
      local btnAgree = ccui.Button:create("game_res/BT_agree_0.png","game_res/BT_agree_1.png")
      btnAgree:setAnchorPoint(cc.p(1.0,0.5))
      btnAgree:setPosition(cc.p(300,110))
      btnAgree:addTouchEventListener(function(sender,eventType)
         if eventType == ccui.TouchEventType.ended then
              if nil ~= OKCallback then
                 OKCallback()
              end
             alert:removeFromParent()
             self._cancellTime = 0 
             self._cancellCall = nil
             self._cancellLabel = nil
              
         end
      end)
      contentBG:addChild(btnAgree)

      --不同意
      local btnDisAgree = ccui.Button:create("game_res/BT_disagree_0.png","game_res/BT_disagree_1.png")
      btnDisAgree:setAnchorPoint(cc.p(0.0,0.5))
      btnDisAgree:setPosition(cc.p(349,110))
      btnDisAgree:addTouchEventListener(function(sender,eventType)
         if eventType == ccui.TouchEventType.ended then
              if nil ~= CancellCallback then
                CancellCallback() 
              end
              alert:removeFromParent()
              self._cancellTime = 0
              self._cancellCall = nil
              self._cancellLabel = nil
              
         end
      end)

      contentBG:addChild(btnDisAgree)

      --倒计时
      self._cancellTime = 8
      self._cancellCall = function()
       
        if nil ~= CancellCallback then
          CancellCallback() 
        end 

        alert:removeFromParent()
        self._cancellTime = 0
        self._cancellCall = nil
        self._cancellLabel = nil
      end

      self._cancellLabel = cc.LabelAtlas:create(string.format("%d",self._cancellTime),"game_res/BT_time_num.png",18,27,string.byte("0")) 
      self._cancellLabel:setAnchorPoint(cc.p(0.5,0.5))
      self._cancellLabel:setPosition(cc.p(btnDisAgree:getContentSize().width/2 + 62 , btnDisAgree:getContentSize().height/2))
      btnDisAgree:addChild(self._cancellLabel)
  end
end

function GameViewLayer:showGameEnd(data)

  if self then self:getChildByTag(TAG.TAG_ALERT)
      self:removeChildByTag(TAG.TAG_ALERT)
      self._cancellTime = 0
      self._cancellCall = nil
      self._cancellLabel = nil
  end

  if type(data) ~= "table" then
    return
  end

  local EndView  = ccui.ImageView:create()
  EndView:setContentSize(cc.size(yl.WIDTH, yl.HEIGHT))
  EndView:setTag(TAG.TAG_IMAGE_OVER)
  EndView:setScale9Enabled(true)
  EndView:setPosition(yl.WIDTH/2, yl.HEIGHT/2)
  EndView:setTouchEnabled(true)
  self:addChild(EndView,GameViewLayer.MenuZorder)
  EndView:addTouchEventListener(function (sender,eventType)
          if eventType == ccui.TouchEventType.ended then
              EndView:removeFromParent()
          end
        end)

  --加载CSB
  local csbnode = cc.CSLoader:createNode("game_res/GameOver.csb")
  csbnode:setPosition(yl.WIDTH/2, yl.HEIGHT/2)
  EndView:addChild(csbnode)

  --关闭按钮
  local btnClose = csbnode:getChildByName("btn_close")
  btnClose:addTouchEventListener(function ( sender,eventType )
       if eventType == ccui.TouchEventType.ended then
              EndView:removeFromParent()
          end
  end)

  local nick_1 = csbnode:getChildByName("nick_1")
  local archive_1 = csbnode:getChildByName("archive_1")

  --输赢情况
  local  meItem = self._scene:GetMeUserItem()
  local  MeNick  = g_var(ClipText):createClipText(cc.size(120, 22),meItem.szNickName,"fonts/round_body.ttf",22);
  MeNick:setAnchorPoint(cc.p(1.0,0.5))
  MeNick:setTextColor(cc.c3b(255,243,175))
  MeNick:setPosition(cc.p(nick_1:getContentSize().width,nick_1:getContentSize().height/2))
  nick_1:addChild(MeNick)

  local score = data.lUserScore[1][meItem.wChairID+1] or 0

  local  scoreMe = cc.Label:createWithTTF(string.format("%d", score), "fonts/round_body.ttf", 24)
  scoreMe:setAnchorPoint(cc.p(0.0,0.5))
  scoreMe:setPosition(cc.p(0 ,archive_1:getContentSize().height/2))
  scoreMe:setTextColor(cc.c3b(255,243,175))
  archive_1:addChild(scoreMe)

  local wOtherSideChairID = math.mod((meItem.wChairID+1),g_var(cmd).GAME_PLAER)
  local nick_2 = csbnode:getChildByName("nick_2")
  local archive_2 = csbnode:getChildByName("archive_2")
  local  otherNick = g_var(ClipText):createClipText(cc.size(120, 22),self._scene._otherNick,"fonts/round_body.ttf",22);
  otherNick:setAnchorPoint(cc.p(1.0,0.5))
  otherNick:setTextColor(cc.c3b(255,243,175))
  otherNick:setPosition(cc.p(nick_2:getContentSize().width/2,nick_2:getContentSize().height/2))
  nick_2:addChild(otherNick)

  score = data.lUserScore[1][wOtherSideChairID+1] or 0
  local  scoreOther = cc.Label:createWithTTF(string.format("%d", score), "fonts/round_body.ttf", 24)
  scoreOther:setAnchorPoint(cc.p(0.0,0.5))
  scoreOther:setPosition(cc.p(0 ,archive_2:getContentSize().height/2))
  scoreOther:setTextColor(cc.c3b(255,243,175))
  archive_2:addChild(scoreOther)
end

function GameViewLayer:updateScore(item)
    
    local scoreNode = self._rootNode:getChildByName("user_scoreNode_"..string.format("%d",item.wChairID+1))
    local  _scoreUser = 0
    if nil ~= item then
      _scoreUser = item.lScore;
    end 

    local str = ExternalFun.numberThousands(_scoreUser)
    if string.len(str) > 11 then
        str = string.sub(str,1,11) .. "...";
    end

    local coin =  scoreNode:getChildByTag(1)
    coin:setString(str)
end

function GameViewLayer:gameClean()

    for k,v in pairs(self._stepRecord) do
        local  pos = v
        local  chessNode = self:getChildByTag(TAG.TAG_CHESS+(pos.x-1)*self._scene._dataModle._nColumns+pos.y)
        
        chessNode:removeAllChildren()
    end
    _stepRecord = {}
end

--准备
function GameViewLayer:onStartReady(sender,eventType)

    if eventType == ccui.TouchEventType.ended then

        self:gameClean()
        self:removeChildByTag(TAG.TAG_IMAGE_OVER)
        self:removeChildByTag(TAG.TAG_CHESSTAG)
        sender:setVisible(false)
        self:resetData()
        self._scene:SendUserReady()

        self:setClockView(self._scene:GetMeUserItem().wChairID,0)
        self._scene:KillGameClock()

        --显示准备状态
        local item = self._scene:GetMeUserItem()
        self:showReady(item.wChairID, 1)

    end
end

--认输
function GameViewLayer:onLose( sender,eventType )

    sender:setEnabled(false)
  
    local  function okCall()
        local dataBuffer = CCmd_Data:create()
        self._scene:SendData(g_var(cmd).SUB_C_GIVEUP_REQ,dataBuffer)
    end

    self:gobangAlert("您确定要认输吗 ?", 1,okCall,nil,sender )

end

function setLoseBtnEnable(enable)
    local btn = self._rootNode:getChildByName("bt_lose")
    btn:setEnabled(enable)
end

--求和
function GameViewLayer:onPeace(sender,eventType)
  
   sender:setEnabled(false)
   if self._scene.m_nPeaceTimeControl >=3 then
      showToast(cc.Director:getInstance():getRunningScene(),"你的[求和]次数已经超过3次了，请求不能处理",2)
      return
   end

   local function okCall()
      local dataBuffer = CCmd_Data:create()
      self._scene:SendData(g_var(cmd).SUB_C_PEACE_REQ,dataBuffer)

      self._scene.m_nPeaceTimeControl = self._scene.m_nPeaceTimeControl + 1
   end
   
   self:gobangAlert("您确定要和棋吗 ?", 1,okCall,nil,sender)
end

function GameViewLayer:setPeaceBtnEnable(enable)
  local btn = self._rootNode:getChildByName("btn_peace")
  btn:setEnabled(enable)
end

--悔棋
function GameViewLayer:onRegret(sender,eventType)
  sender:setEnabled(false)

  local dataBuffer = CCmd_Data:create()
  self._scene:SendData(g_var(cmd).SUB_C_REGRET_REQ,dataBuffer)

end

function GameViewLayer:setRegretBtnEnable(enable)
  local btn = self._rootNode:getChildByName("btn_regret")
  btn:setEnabled(enable)
end

--指导费
function GameViewLayer:onCoach( sender ,eventType )
     if eventType == ccui.TouchEventType.ended then
        --支付对象
        local wOtherSideChairID = math.mod((self._scene:GetMeUserItem().wChairID+1),g_var(cmd).GAME_PLAER) 

        local  dataBuffer = CCmd_Data:create(26)
       
        dataBuffer:pushword(wOtherSideChairID)
        dataBuffer:pushscore(self.m_lCoach)
        
        local aesKey = self._scene:getAesKey()     --加密
        for i = 1, 16 do
            dataBuffer:pushbyte(aesKey[i])
        end

        self._scene:SendData(g_var(cmd).SUB_C_PAY_CHARGE,dataBuffer)
     end
end

function GameViewLayer:OnPeaceAnswer(param)

     local dataBuffer = CCmd_Data:create(1)
     dataBuffer:pushbyte(param)
     self._scene:SendData(g_var(cmd).SUB_C_PEACE_ANSWER,dataBuffer)

end

function GameViewLayer:OnRegretAnswer( param )
     local dataBuffer = CCmd_Data:create(1)
     dataBuffer:pushbyte(param)
     self._scene:SendData(g_var(cmd).SUB_C_REGRET_ANSWER,dataBuffer)
end

function GameViewLayer:OnPlaceChess( row,col )

   local  chessNode = self:getChildByTag(TAG.TAG_CHESS+(row-1)*self._scene._dataModle._nColumns+col)

   local  chess = ccui.ImageView:create(string.format("game_res/chess_%d.png", self._scene._color))
   chess:setTag(1)
   chess:setPosition(cc.p(chessNode:getContentSize().width/2,chessNode:getContentSize().height/2))
   chessNode:addChild(chess)

   self:removeChildByTag(TAG.TAG_CHESSTAG)
   local chessTag  = ccui.ImageView:create("game_res/effect_chess.png")
   chessTag:setTag(TAG.TAG_CHESSTAG)
   chessTag:setPosition(cc.p(chessNode:getPositionX()-1,chessNode:getPositionY()+2))
   self:addChild(chessTag)

   local  dataBuffer = CCmd_Data:create(2)
   dataBuffer:pushbyte(col-1)
   dataBuffer:pushbyte(row-1)

   self._scene:SendData(g_var(cmd).SUB_C_PLACE_CHESS,dataBuffer)
   self._scene.m_wCurrentUser = yl.INVALID_CHAIR
   self:insertRecord({x=row,y=col},self._scene:GetMeUserItem().wChairID)
end

function GameViewLayer:updateControl()

  local btnLost = self._rootNode:getChildByName("bt_lose")   --认输
  local btnPeace = self._rootNode:getChildByName("btn_peace") --求和
  local btnRegret = self._rootNode:getChildByName("btn_regret")
  local btnCoach = self._rootNode:getChildByName("btn_coach")

  if self._scene.m_cbGameStatus == g_var(cmd).GS_GAME_FREE then
      btnLost:setEnabled(false)
      btnPeace:setEnabled(false)
      btnRegret:setEnabled(false)
      btnCoach:setVisible(false)
   else 
      --认输
      btnLost:setEnabled(true)

      --求和
      if self._scene.m_nPeaceTimeControl >=3 then
         btnPeace:setEnabled(false)
      else
         btnPeace:setEnabled(true)
      end


     --悔棋按钮
      if self._scene._steps[self._scene:GetMeUserItem().wChairID+1] > 0 and not self._scene.m_bRegretTimeBeyond then
          btnRegret:setEnabled(true)
      else
          btnRegret:setEnabled(false)  
      end

      --打开指导费
     if self._scene.m_wPayCoachUser == self._scene:GetMeUserItem().wChairID and true == self._scene.m_bpermitCoach  then
        btnCoach:setVisible(true)
     end
  end
end

function GameViewLayer:insertRecord(record,chair)
    assert(type(record)=="table","the param is should be a table")
    table.insert(self._scene._stepRecordNear[chair+1],record)
end

function GameViewLayer:dealRegret(regretUser,round)
    
    if 1 == round then

       local  record = self._scene._stepRecordNear[regretUser+1][#self._scene._stepRecordNear[regretUser+1]]
       local  chessNode = self:getChildByTag(TAG.TAG_CHESS+(record.x-1)*self._scene._dataModle._nColumns+record.y)
       chessNode:removeAllChildren()

       table.remove(self._scene._stepRecordNear[regretUser+1],#self._scene._stepRecordNear[regretUser+1])
       self._scene._steps[regretUser+1] = self._scene._steps[regretUser+1] - 1

       self._scene._dataModle:setSign(record.x,record.y,0)

    elseif 2 == round  then

         for i=1,2 do
             local  record = self._scene._stepRecordNear[i][#self._scene._stepRecordNear[i]]
             local  chessNode = self:getChildByTag(TAG.TAG_CHESS+(record.x-1)*self._scene._dataModle._nColumns+record.y)
             chessNode:removeAllChildren()

             table.remove(self._scene._stepRecordNear[i],#self._scene._stepRecordNear[i])
             self._scene._steps[i] = self._scene._steps[i] - 1
             self._scene._dataModle:setSign(record.x,record.y,0)
         end
    end

    self:removeChildByTag(TAG.TAG_CHESSTAG)
    self:updateControl()
end


function GameViewLayer:huntTargetPos(touch)
   local pos = touch:getLocation()
   local row = math.floor(math.abs(pos.y - 710)/44 + 1)
   local col = math.floor(math.abs(pos.x-340)/44 + 1)

   --搜素范围
   local rbegin = row
   local rend = row
   local cbegin = col
   local cend = col

  --目标位置
   local targetRow = 0
   local targetCol = 0

   --判断临界
   if rbegin - 1 > 0 then 
       rbegin = rbegin - 1
   end

   if  rend + 1 <= 15  then
       rend = rend + 1
   end

   if cbegin - 1 > 0 then 
       cbegin = cbegin - 1
   end

   if  cend + 1 <= 15  then
       cend = cend + 1
   end

   --搜索
   for _row=rbegin,rend do
       for _col=cbegin,cend do
           local chess = self:getChildByTag(TAG.TAG_CHESS + (_row-1)*self._scene._dataModle._nColumns+_col)
           if chess then
                local chessPos = chess:convertToNodeSpace(touch:getLocation())
              
                local rect = cc.rect(0,0,chess:getBoundingBox().width,chess:getBoundingBox().height)
                if  cc.rectContainsPoint( rect, chessPos ) and chess.getCurPos then
                    targetRow , targetCol = chess:getCurPos()

                    if 0 == self._scene._dataModle:getSign(self._scene._dataModle._targetRow,self._scene._dataModle._targetCol) then
                       --加矩形光标
                        self:removeChildByTag(TAG.TAG_RECTCUR)
                        local cur = ccui.ImageView:create("game_res/select_icon.png")
                        cur:setAnchorPoint(cc.p(0.5,0.5))
                        cur:setPosition(cc.p(chess:getPositionX(),chess:getPositionY()))
                        cur:setTag(TAG.TAG_RECTCUR)
                        self:addChild(cur)
                    end
                    break
                end
           end
       end
   end
   
   return targetRow,targetCol
end

function GameViewLayer:onTouchBegan(touch, event)

    local userItem = self._scene:GetMeUserItem()
    if self._scene.m_cbGameStatus == g_var(cmd).GS_GAME_FREE or userItem.wChairID ~= self._scene.m_wCurrentUser then
        return false
    end

   --棋盘
    local chessboard = self._rootNode:getChildByName("game_table")
    local pos = touch:getLocation()
    local nodePos = chessboard:convertToNodeSpace(pos)
    local rect = cc.rect(0,0,chessboard:getBoundingBox().width,chessboard:getBoundingBox().height)
    if not cc.rectContainsPoint( rect, nodePos ) then 
        return false
    end

    self._scene._dataModle._targetRow , self._scene._dataModle._targetCol = self:huntTargetPos(touch)
    return true
end

function GameViewLayer:onTouchMoved(touch, event)
    self._scene._dataModle._targetRow , self._scene._dataModle._targetCol = self:huntTargetPos(touch)
end


function GameViewLayer:onTouchEnded(touch, event )
     self:removeChildByTag(TAG.TAG_RECTCUR)
     if  self._scene._dataModle._targetRow *  self._scene._dataModle._targetCol ~= 0 then
         if 0 == self._scene._dataModle:getSign(self._scene._dataModle._targetRow,self._scene._dataModle._targetCol) then

             if not self._bAllowPlaceChess  then
               return
             end 

             self:OnPlaceChess(self._scene._dataModle._targetRow,self._scene._dataModle._targetCol)
             self._scene._dataModle:setSign(self._scene._dataModle._targetRow, self._scene._dataModle._targetCol,1)
             table.insert(self._stepRecord, {x=self._scene._dataModle._targetRow,y=self._scene._dataModle._targetCol})

             self._bAllowPlaceChess = false
         end
     end
end

return GameViewLayer