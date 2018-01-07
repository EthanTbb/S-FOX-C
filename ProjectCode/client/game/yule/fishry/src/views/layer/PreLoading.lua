--
-- Author: Tang
-- Date: 2016-08-09 10:31:32
-- 预加载资源


local PreLoading = {}
local module_pre = "game.yule.fishry.src"	
local cmd = module_pre .. ".models.CMD_RYGame"
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

function PreLoading.setEnded(is)
	PreLoading.bEnd = is
	if false == is then
		PreLoading.resetData()
	end
	PreLoading.bEnd = false
	print("setEnded bEnd ".. tostring(PreLoading.bEnd))
	--PreLoading.bLoadingFinish = false
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
function PreLoading.loadTextures()

	local m_nImageOffset = 0

	local totalSource = 12 

	local plists = {"fish_yd_0.plist",
					"fish_yd_1.plist",
					"fish_renyu_0.plist",
					"fish_renyu_1.plist",
					"fish_die_0.plist",
					"fish_die_1.plist",
					"whater.plist",
					"bullet.plist",
					"fish_light.plist",
					"watch.plist",
					"fishLock.plist",
				   }
	totalSource = #plists		   
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
       	cc.Director:getInstance():getTextureCache():addImageAsync("game_res/fish_yd_0.png", imageLoaded)
        cc.Director:getInstance():getTextureCache():addImageAsync("game_res/fish_yd_1.png",imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/fish_renyu_0.png", imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/fish_renyu_1.png", imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/fish_die_0.png", imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/fish_die_1.png", imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/whater.png", imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/bullet.png", imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/fish_light.png", imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/watch.png", imageLoaded)
		cc.Director:getInstance():getTextureCache():addImageAsync("game_res/fishLock.png", imageLoaded)
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

	local login_logo = ccui.ImageView:create("loading/login_logo.png")
	login_logo:setTag(3)
	login_logo:setPosition(cc.p(yl.WIDTH/2,yl.HEIGHT/2))
	layer:addChild(login_logo)

	local loadingBarBG = ccui.ImageView:create("loading/loadingBG.png")
	loadingBarBG:setTag(2)
	loadingBarBG:setPosition(cc.p(yl.WIDTH/2,yl.HEIGHT/2-200))
	layer:addChild(loadingBarBG)

	

	local loading_text = ccui.ImageView:create("loading/loading_text.png")
	loading_text:setTag(4)
	loading_text:setPosition(cc.p(yl.WIDTH/2,yl.HEIGHT/2 - 150))
	layer:addChild(loading_text)


	PreLoading.loadingBar = cc.ProgressTimer:create(cc.Sprite:create("loading/loading_cell.png"))
	PreLoading.loadingBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
	PreLoading.loadingBar:setMidpoint(cc.p(0.0,0.5))
	PreLoading.loadingBar:setBarChangeRate(cc.p(1,0))
    PreLoading.loadingBar:setPosition(cc.p(loadingBarBG:getContentSize().width/2,loadingBarBG:getContentSize().height/2))
    PreLoading.loadingBar:runAction(cc.ProgressTo:create(0.2,20))
    loadingBarBG:addChild(PreLoading.loadingBar)

	local frames = {}
   	local actionTime = 0.03
	for i=1,24 do
		local frameName
		frameName = string.format("loading/fish_16_yd_".."%d.png", i)
		local frame = cc.SpriteFrame:create(frameName,cc.rect(0,0,160,370))
		table.insert(frames, frame)
	end

	local  animation =cc.Animation:createWithSpriteFrames(frames,actionTime)

    PreLoading.fish = cc.Sprite:create("loading/fish_16_yd_1.png")
    PreLoading.fish:setScale(0.5)
    PreLoading.fish:setFlippedX(true)
    PreLoading.fish:setAnchorPoint(cc.p(1.0,0.5))
    PreLoading.fish:setRotation(90)
    PreLoading.fish:setPosition(cc.p(158,PreLoading.loadingBar:getContentSize().height/2 - 45))
    loadingBarBG:addChild(PreLoading.fish)

    PreLoading.fish:stopAllActions()
    local action = cc.RepeatForever:create(cc.Animate:create(animation))
	PreLoading.fish:runAction(action)

	local move = cc.MoveTo:create(0.2,cc.p(800*(20/100),PreLoading.loadingBar:getContentSize().height/2 - 45))
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
		local move =  cc.MoveTo:create(dt,cc.p(800*(percent/100),PreLoading.loadingBar:getContentSize().height/2 - 45))
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
--鱼游动动画的帧数
PreLoading.FishAnimNum = 12

--鱼的种类数
PreLoading.FishTypeNum = 20

--导入图片数量
PreLoading.LoadingImageNum = 9

function PreLoading.loadTextures2()

	cc.Director:getInstance():getTextureCache():addImage("game_res/fish_yd_0.png")
	cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/fish_yd_0.plist")

    	cc.Director:getInstance():getTextureCache():addImage("game_res/fish_yd_1.png")
	cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/fish_yd_1.plist")

	cc.Director:getInstance():getTextureCache():addImage("game_res/fish_renyu_0.png")
	cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/fish_renyu_0.plist")

	cc.Director:getInstance():getTextureCache():addImage("game_res/fish_renyu_1.png")
	cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/fish_renyu_1.plist")

	cc.Director:getInstance():getTextureCache():addImage("game_res/fish_die_0.png")
	cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/fish_die_0.plist")

	cc.Director:getInstance():getTextureCache():addImage("game_res/fish_die_1.png")
	cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/fish_die_1.plist")

	cc.Director:getInstance():getTextureCache():addImage("game_res/whater.png")
	cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/whater.plist")

	cc.Director:getInstance():getTextureCache():addImage("game_res/bullet.png")
	cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/bullet.plist")

	cc.Director:getInstance():getTextureCache():addImage("game_res/fish_light.png")
	cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/fish_light.plist")

	cc.Director:getInstance():getTextureCache():addImage("game_res/watch.png")
	cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/watch.plist")

	cc.Director:getInstance():getTextureCache():addImage("game_res/fishLock.png")
	cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/fishLock.plist")
		

end

function PreLoading.unloadTextures( )
	
	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/fish_yd_0.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/fish_yd_0.plist")

    	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/fish_yd_1.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/fish_yd_1.plist")

	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/fish_renyu_0.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/fish_renyu_0.plist")

	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/fish_renyu_1.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/fish_renyu_1.plist")

	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/fish_die_0.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/fish_die_0.plist")

	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/fish_die_1.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/fish_die_1.plist")

	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/whater.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/whater.plist")

	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/bullet.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/bullet.plist")

	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/fish_light.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/fish_light.plist")

	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/watch.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/watch.plist")

	cc.Director:getInstance():getTextureCache():removeTextureForKey("game_res/fishLock.png")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("game_res/fishLock.plist")
	
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
	for i=0,num - 1 do
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

function PreLoading.readFishAnimation(file, key,FishType, num, time)
	local frames = {}
   	local actionTime = time
   	local  n = num - 1
	for i=0,n do
		local frameName = string.format(file,FishType, i)
		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName) 
		table.insert(frames, frame)
	end
	local savename = string.format(key,FishType)
	local  animation =cc.Animation:createWithSpriteFrames(frames,actionTime)
   	cc.AnimationCache:getInstance():addAnimation(animation, savename)
end

function PreLoading.readAniByFileName( file,width,height,rownum,linenum,savename)
	local frames = {}
	for i=0,rownum - 1 do
		for j=0,linenum - 1 do
			
			local frame = cc.SpriteFrame:create(file,cc.rect(width*(j-1),height*(i-1),width,height))
			table.insert(frames, frame)
		end
		
	end
	local  animation =cc.Animation:createWithSpriteFrames(frames,0.03)
   	cc.AnimationCache:getInstance():addAnimation(animation, savename)
end

function PreLoading.removeAllActions()

	for index=0,PreLoading.FishTypeNum - 1 do
		cc.AnimationCache:getInstance():removeAnimation(string.format("fish_%d_yd", index))
	end
    for i=0,17 do
    	cc.AnimationCache:getInstance():removeAnimation(string.format("fish_%d_die", i))
	end

    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).RenYu_B_To_Q)
    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).RenYu_Q_To_B)
    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).WaterAnim)
    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).FortAnim)
    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).FortLightAnim)
    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).SilverAnim)
    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).GoldAnim)
    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).CopperAnim)
    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).BombAnim)
    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).BulletAnim)
    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).LightAnim)
    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).watchAnim)
    cc.AnimationCache:getInstance():removeAnimation("fish_19_die")
    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).FishBall)
    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).FishLight)
    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).YBFish)
    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).YBDie)
    cc.AnimationCache:getInstance():removeAnimation(g_var(cmd).YBAnim)
end

function PreLoading.readAniams()

	--鱼游动动画
	for index=0,PreLoading.FishTypeNum - 1 do
		local animnum = PreLoading.FishAnimNum
		local animtime = 0.1

		if index == 5 then
			animnum = 36
            		animtime = 0.1
            	elseif index >= 13 and index<PreLoading.FishTypeNum-1 then
            		animnum = 24
            		animtime = 0.1
            	end
            	PreLoading.readFishAnimation("fish_%d_yd_%d.png", "fish_%d_yd", index, animnum, animtime)
	end
    	for i=0,17 do
		PreLoading.readFishAnimation("fish_%d_die_%d.png", "fish_%d_die", i, 12, 0.05)
	end

	for index=0,6 do
		local animnum = 12
        		if  index == 5 then
           			animnum = 36
        		end
        		PreLoading.readFishAnimation("fish_%d_yd_light_%d.png", "fish_%d_yd_light", index, animnum,0.1)
        		PreLoading.readFishAnimation("fish_%d_die_light_%d.png", "fish_%d_die_light", index, 12,0.1);
        		PreLoading.readFishAnimation("fish_%d_bomb_%d.png", "fish_%d_bomb", index, 2,0.1);
	end

   	PreLoading.readAnimation("fish_btoq_yd_",g_var(cmd).RenYu_B_To_Q,8,0.1,1)
   	PreLoading.readAnimation("fish_qtob_yd_",g_var(cmd).RenYu_Q_To_B,8,0.1,1)
   	PreLoading.readAnimation("water_", g_var(cmd).WaterAnim, 12, 0.12,1);
    	PreLoading.readAnimation("fort_", g_var(cmd).FortAnim, 6, 0.02,1);
   	PreLoading.readAnimation("fort_light_", g_var(cmd).FortLightAnim, 6, 0.02,1);
    	PreLoading.readAnimation("silver_coin_", g_var(cmd).SilverAnim, 10, 0.05,1);
    	PreLoading.readAnimation("gold_coin_", g_var(cmd).GoldAnim, 10 , 0.08,1);
    	PreLoading.readAnimation("copper_coin_", g_var(cmd).CopperAnim, 10,0.05,1);
    	PreLoading.readAnimation("bomb_", g_var(cmd).BombAnim, 15,0.12,1);
    	PreLoading.readAnimation("bullet_", g_var(cmd).BulletAnim, 10,0.12,1);
    	PreLoading.readAnimation("light_", g_var(cmd).LightAnim, 16,0.05,1);
    	PreLoading.readAnimation("watch_", g_var(cmd).watchAnim, 24, 0.08,1);
    	PreLoading.readAnimation("fish_19_die_", "fish_19_die", 12, 0.05,1);

    	PreLoading.readAniByFileName("game_res/fish_bomb_ball.png", 70, 70, 2, 5, g_var(cmd).FishBall)
    	PreLoading.readAniByFileName("game_res/fish_bomb_light.png", 40, 256, 1, 6, g_var(cmd).FishLight)
    	PreLoading.readAniByFileName("game_res/im_yb_fish.png", 239, 226, 2, 1, g_var(cmd).YBFish)
    	PreLoading.readAniByFileName("game_res/im_yb_die.png", 215, 245, 2, 4, g_var(cmd).YBDie)
    	PreLoading.readAniByFileName("game_res/im_yb_end.png", 164, 185, 3, 5, g_var(cmd).YBAnim)



end

return PreLoading