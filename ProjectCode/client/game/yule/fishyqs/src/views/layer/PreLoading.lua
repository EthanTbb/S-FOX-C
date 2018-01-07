--
-- Author: Tang
-- Date: 2016-08-09 10:31:32
-- 预加载资源
local PreLoading = {}
local module_pre = "game.yule.fishyqs.src"	
local cmd = module_pre .. ".models.CMD_YQSGame"
local ExternalFun = require(appdf.EXTERNAL_SRC.."ExternalFun")
local g_var = ExternalFun.req_var
PreLoading.bLoadingFinish = false
PreLoading.loadingPer = 20
PreLoading.bFishData = false
PreLoading.bEnd = false
function PreLoading.resetData()
	PreLoading.bLoadingFinish = false
	PreLoading.loadingPer = 20
	PreLoading.bFishData = false
	PreLoading.bEnd = true
end

function PreLoading.StopAnim(bRemove)

	local scene = cc.Director:getInstance():getRunningScene()
	local layer = scene:getChildByTag(2000) 

	if not layer  then
		return
	end

	if not bRemove then
		if nil ~= PreLoading.fish then
			PreLoading.fish:stopAllActions()
		end
	else
	
		layer:stopAllActions()
		layer:removeFromParent()
	end
end

function PreLoading.setEnded(is)
	PreLoading.bEnd = is
	if false == is then
		PreLoading.resetData()
	end
	PreLoading.bEnd = false
	print("setEnded bEnd ".. tostring(PreLoading.bEnd))
end


function PreLoading.loadTextures()

	local m_nImageOffset = 0

	local totalSource = 11 

	local plists = {"whater.plist",
					"bullet.plist",
					"fish_ignot.plist",
					"fish_dead.plist",
					"watch.plist",
					"fish_move1.plist",
					"fish_move2.plist",
					"fish_lock.plist",
					"bomb.plist",
					"bullet_guns_coins.plist",
					"image.plist"
				   }

	local function imageLoaded(texture)
   		if true == PreLoading.bEnd then
			return
		end
   		print("Image loaded:..."..texture:getPath())
        m_nImageOffset = m_nImageOffset + 1

        PreLoading.loadingPer = 20 + m_nImageOffset*2
        if m_nImageOffset == totalSource then

        	--加载PLIST
        	for i=1,#plists do
        		cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/"..plists[i])
        	end

        	PreLoading.readAniams()
        	PreLoading.bLoadingFinish = true

        	--通知
			local event = cc.EventCustom:new(g_var(cmd).Event_LoadingFinish)
			cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
			print(tostring(PreLoading.bFishData))
			if PreLoading.bFishData then
				
				local scene = cc.Director:getInstance():getRunningScene()
				local layer = scene:getChildByTag(2000) 

				if not layer  then
					return
				end

				PreLoading.loadingPer = 100
				PreLoading.updatePercent(PreLoading.loadingPer)
				local callfunc = cc.CallFunc:create(function()
					PreLoading.loadingBar:stopAllActions()
					PreLoading.loadingBar = nil
		
					layer:stopAllActions()
					layer:removeFromParent()
				end)
				layer:stopAllActions()
				layer:runAction(cc.Sequence:create(cc.DelayTime:create(2.2),callfunc))
			end

        	print("资源加载完成")
        end
    end

    local function 	loadImages()
      
        cc.Director:getInstance():getTextureCache():addImageAsync("game_res/whater.png", imageLoaded)
        cc.Director:getInstance():getTextureCache():addImageAsync("game_res/bullet.png",imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/fish_ignot.png", imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/fish_dead.png", imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/watch.png", imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/fish_move1.png", imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/fish_move2.png", imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/fish_lock.png", imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/bomb.png", imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/bullet_guns_coins.png", imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/image.png", imageLoaded)
       
    end


    local function createSchedule( )
    	local function update( dt )
			PreLoading.updatePercent(PreLoading.loadingPer)
		end

		local scheduler = cc.Director:getInstance():getScheduler()
		PreLoading.m_scheduleUpdate = scheduler:scheduleScriptFunc(update, 0, false)
    end

	loadImages()

	--进度条
	PreLoading.GameLoadingView()

	createSchedule()

	PreLoading.addEvent()

end

function PreLoading.addEvent()

   --通知监听
  local function eventListener(event)
  	cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(g_var(cmd).Event_FishCreate)
	PreLoading.Finish()
  end

  local listener = cc.EventListenerCustom:create(g_var(cmd).Event_FishCreate, eventListener)
  cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listener, 1)

end

function PreLoading.Finish()

	PreLoading.bFishData = true

	if  PreLoading.bLoadingFinish then
		PreLoading.loadingPer = 100
		PreLoading.updatePercent(PreLoading.loadingPer)

		local scene = cc.Director:getInstance():getRunningScene()
		local layer = scene:getChildByTag(2000) 

		if nil ~= layer then
			local callfunc = cc.CallFunc:create(function()
				PreLoading.loadingBar:stopAllActions()
				PreLoading.loadingBar = nil
				PreLoading.fish:stopAllActions()
				PreLoading.fish = nil
				layer:stopAllActions()
				layer:removeFromParent()

			end)

			layer:stopAllActions()
			layer:runAction(cc.Sequence:create(cc.DelayTime:create(2.2),callfunc))
		end
	end
end

function PreLoading.GameLoadingView()
	
	local scene = cc.Director:getInstance():getRunningScene()
	local layer = display.newLayer()
	layer:setTag(2000)
	scene:addChild(layer,30)

	local loadingBG = ccui.ImageView:create("loading/bg.png")
	loadingBG:setTag(1)
	loadingBG:setTouchEnabled(true)
	loadingBG:setPosition(cc.p(yl.WIDTH/2,yl.HEIGHT/2))
	layer:addChild(loadingBG)

	---[[
	local loadingBarBG = ccui.ImageView:create("loading/loadingBG.png")
	loadingBarBG:setVisible(false)
	loadingBarBG:setTag(2)
	loadingBarBG:setPosition(cc.p(yl.WIDTH/2,yl.HEIGHT/2-300))
	layer:addChild(loadingBarBG)
	--]]

	local loading_text = ccui.ImageView:create("loading/loading_text.png")
	loading_text:setTag(4)
	loading_text:setPosition(cc.p(yl.WIDTH/2,yl.HEIGHT/2 - 205))
	layer:addChild(loading_text)

	PreLoading.loadingBar = cc.ProgressTimer:create(cc.Sprite:create("loading/loading_cell.png"))
	PreLoading.loadingBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
	PreLoading.loadingBar:setMidpoint(cc.p(0.0,0.5))
	PreLoading.loadingBar:setBarChangeRate(cc.p(1,0))
    PreLoading.loadingBar:setPosition(cc.p(layer:getContentSize().width/2,111))
    PreLoading.loadingBar:runAction(cc.ProgressTo:create(0.2,20))
    layer:addChild(PreLoading.loadingBar)

	local frames = {}
   	local actionTime = 0.1
	for i=1,9 do
		local frameName
		frameName = string.format("loading/loading_".."%d.png", i)
		local frame = cc.SpriteFrame:create(frameName,cc.rect(0,0,258,97))
		table.insert(frames, frame)
	end

	local  animation =cc.Animation:createWithSpriteFrames(frames,actionTime)

    PreLoading.fish = cc.Sprite:create("loading/loading_1.png")
    PreLoading.fish:setAnchorPoint(cc.p(1.0,0.5))
    PreLoading.fish:setPosition(cc.p(170,PreLoading.loadingBar:getContentSize().height/2))
    PreLoading.loadingBar:addChild(PreLoading.fish)

    PreLoading.fish:stopAllActions()
    local action = cc.RepeatForever:create(cc.Animate:create(animation))
	PreLoading.fish:runAction(action)

	local move = cc.MoveTo:create(0.2,cc.p(980*(20/100),PreLoading.loadingBar:getContentSize().height/2))
	move:setTag(1)
    PreLoading.fish:runAction(move)
end

function PreLoading.updatePercent(percent )
	if true == PreLoading.bEnd then
		return
	end
	if nil ~= PreLoading.loadingBar then

		local dt = 1.0
		if percent == 100 then
			dt = 2.0
		end

		PreLoading.loadingBar:runAction(cc.ProgressTo:create(dt,percent))
		cc.Director:getInstance():getActionManager():removeActionByTag(1, PreLoading.fish)
		local move =  cc.MoveTo:create(dt,cc.p(1060*(percent/100),PreLoading.loadingBar:getContentSize().height/2))
		move:setTag(1)
		PreLoading.fish:runAction(move)
	end

	if PreLoading.bLoadingFinish then
		if nil ~= PreLoading.m_scheduleUpdate then
    		local scheduler = cc.Director:getInstance():getScheduler()
			scheduler:unscheduleScriptEntry(PreLoading.m_scheduleUpdate)
			PreLoading.m_scheduleUpdate = nil
		end
	end
end


function PreLoading.unloadTextures( )
	
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/whater.plist")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/whater.png")
	
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/bullet.plist")
    cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/bullet.png")
	
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/fish_ignot.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/fish_ignot.png")
	
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/fish_dead.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/fish_dead.png")
	
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/watch.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/watch.png")
	
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/fish_move1.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/fish_move1.png")
	
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/fish_move2.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/fish_move2.png")
	
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/fish_lock.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/fish_lock.png")

		cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/bomb.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/bomb.png")
	
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/bullet_guns_coins.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/bullet_guns_coins.png")
	

	
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/image.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/image.png")
	
	
    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
end


--[[
@function : readAnimation
@file : 资源文件
@key  : 动作 key
@num  : 幀数
@time : float time 
@formatBit 

]]
function PreLoading.readAnimation(file, key, num, time,formatBit)
	local frames = {}
   	local actionTime = time
	for i=1,num do

		local frameName
		if formatBit == 1 then
			frameName = string.format(file.."%d.png", i-1)
		elseif formatBit == 2 then
		 	frameName = string.format(file.."%2d.png", i-1)
		end
		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName) 
		
		table.insert(frames, frame)
	end

	local  animation =cc.Animation:createWithSpriteFrames(frames,actionTime)
   	cc.AnimationCache:getInstance():addAnimation(animation, key)
end

function PreLoading.readAniByFileName( file,width,height,rownum,linenum,savename)
	local frames = {}
	for i=1,rownum do
		for j=1,linenum do
			
			local frame = cc.SpriteFrame:create(file,cc.rect(width*(j-1),height*(i-1),width,height))
			table.insert(frames, frame)
		end
		
	end
	local  animation =cc.Animation:createWithSpriteFrames(frames,0.03)
   	cc.AnimationCache:getInstance():addAnimation(animation, savename)
end

function PreLoading.removeAllActions()

	--鱼游动动画
	for i=1,g_var(cmd).Fish_MOVE_TYPE_NUM do
		
		local key = string.format("animation_fish_move%d", i)
		cc.AnimationCache:getInstance():removeAnimation(key)

	end

	--鱼死亡动画
	for i=1,g_var(cmd).Fish_DEAD_TYPE_NUM do
		local key = string.format("animation_fish_dead%d", i)
		cc.AnimationCache:getInstance():removeAnimation(key)
	end	

   	--元宝鱼金币翻滚动画
   	cc.AnimationCache:getInstance():removeAnimation("fish_ignot_coin")

    cc.AnimationCache:getInstance():removeAnimation("WaterAnim")
    cc.AnimationCache:getInstance():removeAnimation("FortAnim")
    cc.AnimationCache:getInstance():removeAnimation("FortLightAnim")
    cc.AnimationCache:getInstance():removeAnimation("SilverAnim")
    cc.AnimationCache:getInstance():removeAnimation("CopperAnim")
    cc.AnimationCache:getInstance():removeAnimation("BombAnim")
    cc.AnimationCache:getInstance():removeAnimation("GoldAnim")
    cc.AnimationCache:getInstance():removeAnimation("BombDartsAnim")
    cc.AnimationCache:getInstance():removeAnimation("BlueIceAnim")
    cc.AnimationCache:getInstance():removeAnimation("BulletAnim")
    cc.AnimationCache:getInstance():removeAnimation("LightAnim")
    cc.AnimationCache:getInstance():removeAnimation("watchAnim")
    cc.AnimationCache:getInstance():removeAnimation("FishBall")
    cc.AnimationCache:getInstance():removeAnimation("FishLight")

end

function PreLoading.readAniams()

	local fishFrameMoveNum =
	{
		6,8,12,
    	12,12,13,
    	12,10,12,
    	8,12,6,
    	12,10,12,
    	12,12,9,
    	16,10,10,
    	7,1,10,
    	8,2
	}

	local fishFrameDeadNum =
	{
		2,2,2,
    	3,3,3,
    	6,3,2,
    	6,4,3,
    	3,3,3,
    	3,3,3,
    	4,3,3,
    	3,0,3,
    	0,8
	}

	--鱼游动动画
	for i=1,g_var(cmd).Fish_MOVE_TYPE_NUM do
		
		local frames = {}
		local actionTime = 0.09
		if i == 21 then
			actionTime = 0.15
		end

		local num = fishFrameMoveNum[i]
    	for j=1,num do
	        local frameName =string.format("fishMove_%03d_%d.png",i,j)  
	      --  print("frameName is =========================================================="..frameName)
	        local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName) 
	        table.insert(frames, frame)
    	end

    	local  animation =cc.Animation:createWithSpriteFrames(frames,actionTime)
		local key = string.format("animation_fish_move%d", i)
		cc.AnimationCache:getInstance():addAnimation(animation, key)
	end

	--鱼死亡动画
	for i=1,g_var(cmd).Fish_DEAD_TYPE_NUM do
		frames = {}
		local actionTime = 0.05
		local num = fishFrameDeadNum[i]
		if 0 ~= num then
			for j=1,num do
	        	local frameName =string.format("fishDead_%03d_%d.png",i,j)  
	        	local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName) 
	        	table.insert(frames, frame)
    		end

    		local  animation =cc.Animation:createWithSpriteFrames(frames,actionTime)
			local key = string.format("animation_fish_dead%d", i)
		--print("key is =============================================="..key)
			cc.AnimationCache:getInstance():addAnimation(animation, key)
		end
	end	

   	--元宝鱼金币翻滚动画
   	frames = {}
   	local actionTime = 0.05
	for i=1,15 do
		local frameName = string.format("ignot_coin_%d.png", i)
		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName) 
		table.insert(frames, frame)
	end

	local  animation =cc.Animation:createWithSpriteFrames(frames,actionTime)
   	cc.AnimationCache:getInstance():addAnimation(animation, "fish_ignot_coin")

   	PreLoading.readAnimation("water_","WaterAnim",12,0.12,1)
   	PreLoading.readAnimation("fort_","FortAnim",6,0.02,1)
   	PreLoading.readAnimation("fort_light_", "FortLightAnim", 6, 0.02,1);
    PreLoading.readAnimation("silver_coin_", "SilverAnim", 12, 0.05,1);
    PreLoading.readAnimation("gold_coin_", "GoldAnim", 12, 0.08,1);
    PreLoading.readAnimation("copper_coin_", "CopperAnim", 10, 0.05,1);
    PreLoading.readAnimation("boom", "BombAnim", 32,0.03,2);
    PreLoading.readAnimation("bullet_", "BulletAnim", 10,1);
    PreLoading.readAnimation("light_", "LightAnim", 16, 0.05,1);
    PreLoading.readAnimation("watch_", "watchAnim", 24, 0.08,1);
    PreLoading.readAnimation("Reward_Box_", "rewardCircleAnim", 24, 0.08,1);

    PreLoading.readAniByFileName("game_res/fish_bomb_ball.png", 70, 70, 2, 5, "FishBall")
    PreLoading.readAniByFileName("game_res/fish_bomb_light.png", 40, 256, 1, 6, "FishLight")
end

return PreLoading