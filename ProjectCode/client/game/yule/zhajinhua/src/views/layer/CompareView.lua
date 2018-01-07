local CompareView  = class("CompareView",function(config)
		local compareView =  display.newLayer(cc.c4b(0, 0, 0, 125))
    return compareView
end)
local HeadSprite = appdf.req(appdf.EXTERNAL_SRC .. "HeadSprite")

function CompareView:onExit()
	print("CompareView onExit")
	cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()	-- body
end

function CompareView:ctor(config)

	local this = self
	self.m_config = config

	local function onNodeEvent(event)  
       if "exit" == event then  
            this:onExit()  
        end  
    end  
  
    self:registerScriptHandler(onNodeEvent)  

	-- self:setTouchEnabled(true)
	-- self:registerScriptTouchHandler(function(eventType, x, y)
	-- 	return this:onTouch(eventType, x, y)
	-- end)

	display.newSprite("#game_vs_bg.png")
		:move(667,400)
		:addTo(self)

	display.newSprite("#vs.png")
		:move(667,500)
		:addTo(self)

	display.newSprite("#game_vs_user.png")
		:move(667+250,475)
		:addTo(self)

	display.newSprite("#game_vs_user.png")
		:move(667-250,475)
		:addTo(self)

	self.m_FirstCard = {}
	self.m_SecondCard = {}

	for i = 1, 3 do
		self.m_FirstCard[i] = display.newSprite("#card_back.png")
				:setAnchorPoint(cc.p(0,1))
				:move(667-250-72 + 26*(i - 1), 365)
				:addTo(self)
		self.m_SecondCard[i] = display.newSprite("#card_back.png")
				:move(667+250 - 72 + 26*(i - 1), 365)
				:setAnchorPoint(cc.p(0,1))
				:addTo(self)
	end
	self.m_bFirstWin = false

	self.m_flagBall = {}

	self.m_flagBall[1] = display.newSprite("#game_vs_boll.png")
		:move(667+673/2 -75,315)
		:setVisible(false)
		:addTo(self)
	self.m_flagBall[2] = display.newSprite("#game_vs_boll.png")
		:move(667-673/2 + 75 ,315)
		:setVisible(false)
		:addTo(self)

	self.m_flushAni = display.newSprite("#game_ani_vs1.png")
		:setVisible(false)
		:move(667,295)
		:addTo(self)

	self.m_LoseFlag = display.newSprite("#game_vs_lose.png")
		:setVisible(false)
		:addTo(self)

	self.m_UserInfo = {}
	self.m_UserInfo[1] = {}
	self.m_UserInfo[1].head = HeadSprite:createNormal({}, 120)
		:move(667-250,493)
		:addTo(self)
	self.m_UserInfo[1].name = cc.Label:createWithTTF("游戏玩家", "fonts/round_body.ttf", 24)
		:move(667-250,475-63)
		:addTo(self)
	self.m_UserInfo[2] = {}
	self.m_UserInfo[2].head = HeadSprite:createNormal({}, 120)
		:move(667+250,493)
		:addTo(self)
	self.m_UserInfo[2].name = cc.Label:createWithTTF("游戏玩家", "fonts/round_body.ttf", 24)
		:move(667+250,475-63)
		:addTo(self)

	self.m_AniCallBack = nil
end

-- function CompareView:onTouch(eventType, x, y)
-- 	if eventType == "began" then
-- 		self:ShowCompare()
-- 	end

-- 	return true
-- end
function CompareView:StopCompareCard()
	self.m_flushAni:stopAllActions()
	self.m_flagBall[1]:stopAllActions()
	self.m_flagBall[2]:stopAllActions()

	self.m_flushAni:setVisible(false)
	self.m_flagBall[1]:setVisible(false)
	self.m_flagBall[2]:setVisible(false)

	self.m_LoseFlag:setVisible(false)
	self.m_LoseFlag:stopAllActions()

end

function CompareView:CompareCard(firstuser,seconduser,firstcard,secondcard,bfirstwin,callback)
	self.m_AniCallBack = callback
	for i = 1 , 3  do
		self.m_FirstCard[i]:setSpriteFrame("card_back.png")
		self.m_SecondCard[i]:setSpriteFrame("card_back.png")
	end

	self.m_bFirstWin = bfirstwin

	self.m_UserInfo[1].head:updateHead(firstuser)
	self.m_UserInfo[2].head:updateHead(seconduser)

	local nickname 
	if firstuser and firstuser.szNickName then
		nickname = firstuser.szNickName
	else
		nickname = "游戏玩家"
	end

	self.m_UserInfo[1].name:setString(string.EllipsisByConfig(nickname,105, self.m_config))

	if seconduser and seconduser.szNickName then
		nickname = seconduser.szNickName
	else
		nickname = "游戏玩家"
	end

	self.m_UserInfo[2].name:setString(string.EllipsisByConfig(nickname,105, self.m_config))

	self:setVisible(true)

	local this = self
	self.m_flushAni:stopAllActions()
	self.m_flagBall[1]:stopAllActions()
	self.m_flagBall[2]:stopAllActions()

	self.m_flushAni:setVisible(true)
	self.m_flagBall[1]:setVisible(true)
	self.m_flagBall[2]:setVisible(true)

	local animation = cc.Animation:create()
	local i = 1
	while true do
		local strVS = string.format("game_ani_vs%d.png",i)
		i = i + 1
		local spriteFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(strVS)
		if spriteFrame then
			animation:addSpriteFrame(spriteFrame)
		else
			break
		end
	end

	animation:setLoops(2)
	animation:setDelayPerUnit(0.1)
	local animate = cc.Animate:create(animation)

	self.m_flagBall[1]:runAction(cc.RepeatForever:create(cc.Sequence:create(
		cc.ScaleTo:create(0.3,0.7),
		cc.ScaleTo:create(0.3,1)
		)))
	self.m_flagBall[2]:runAction(cc.RepeatForever:create(cc.Sequence:create(
		cc.ScaleTo:create(0.3,0.7),
		cc.ScaleTo:create(0.3,1)
		)))
	self.m_flushAni:runAction(cc.Sequence:create(
		animate,
		cc.CallFunc:create(
			function()
				this:FlushEnd()
			end)
		))

end

function CompareView:FlushEnd()
	local this = self
	self.m_flushAni:stopAllActions()
	self.m_flagBall[1]:stopAllActions()
	self.m_flagBall[2]:stopAllActions()

	self.m_flushAni:setVisible(false)
	self.m_flagBall[1]:setVisible(false)
	self.m_flagBall[2]:setVisible(false)

	if self.m_bFirstWin == true then
		self.m_LoseFlag:move(667+250 - 72 + 26+45, 315)
	else
		self.m_LoseFlag:move(667-250-72 + 26+45, 315)
	end
	self.m_LoseFlag:setVisible(true)
	self.m_LoseFlag:setScale(3.0)
	self.m_LoseFlag:setOpacity(0)

	self.m_LoseFlag:runAction(cc.Sequence:create(
		cc.Spawn:create(
			cc.ScaleTo:create(0.3,1.0),
			cc.FadeTo:create(0.3,255)),
		cc.CallFunc:create(
			function()
				for i = 1 , 3  do
					if not this.m_bFirstWin then 
						this.m_FirstCard[i]:setSpriteFrame("card_break.png")
					else
						this.m_SecondCard[i]:setSpriteFrame("card_break.png")
					end
				end
			end),
		cc.DelayTime:create(0.5),
		cc.CallFunc:create(
			function()
				this.m_AniCallBack()
			end
			)
	))
end


return CompareView