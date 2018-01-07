--
-- Author: Tang
-- Date: 2016-08-09 10:27:07
--炮
local Cannon = class("Cannon", cc.Sprite)
local module_pre = "game.yule.fishry.src"			
local ExternalFun = require(appdf.EXTERNAL_SRC.."ExternalFun")
local cmd = module_pre..".models.CMD_RYGame"
local Bullet = require(module_pre..".views.layer.Bullet")
local QueryDialog = appdf.req("base.src.app.views.layer.other.QueryDialog")
local g_var = ExternalFun.req_var
local scheduler = cc.Director:getInstance():getScheduler()
Cannon.Tag = 
{

	Tag_Award = 10,
	Tag_Light = 20,
	Tag_Type  = 30,
	Tag_lock  = 3000

}

require("app.models.bit")

local TagEnum = Cannon.Tag

function Cannon:ctor(viewParent)
	
	self.m_pos = 0    --炮台位置
	self.m_fort = nil
	self.m_nickName = nil
	self.m_score = nil
	self.m_multiple = nil
	self.m_isShoot = false
	self.m_canShoot = true
	self.m_autoShoot = false
	self.m_typeTime = 0
	self.orignalAngle = 0
	self.m_fishIndex = g_var(cmd).INT_MAX
	self.m_index  = 0 --子弹索引
	self.m_ChairID  = yl.INVALID_CHAIR
	self.m_autoShootSchedule = nil
	self.m_otherShootSchedule = nil
	self.m_typeSchedule = nil
	self.m_userId = 0
	self.m_targetPoint = cc.p(0,0)
	self.m_cannonPoint = cc.p(0,0)
	self.m_firelist = {}

	self.m_nCurrentBulletScore = 1
	
	self.m_Type = g_var(cmd).CannonType.Normal_Cannon
	self.parent = viewParent

	self._dataModel = self.parent._dataModel
	self.frameEngine = self.parent._gameFrame 

--获取自己信息
	self.m_pUserItem = self.frameEngine:GetMeUserItem()
  	self.m_nTableID  = self.m_pUserItem.wTableID
  	self.m_nChairID  = self.m_pUserItem.wChairID

--其他玩家信息
  	self.m_pOtherUserItem = nil
 	self.m_nMutipleIndex = self._dataModel.m_secene.nMultipleIndex--0
  	--注册事件
    ExternalFun.registerTouchEvent(self,false)
end


function Cannon:onExit( )

	self:unAutoSchedule()
	self:unTypeSchedule()
	self:unOtherSchedule()
end


function Cannon:setCannonMuitle(multiple)
	
	self.m_nMutipleIndex = multiple
end

function Cannon:initWithUser(userItem)
	
	self.m_ChairID = userItem.wChairID
	if self.m_ChairID ~= self.m_nChairID then
		self.m_pOtherUserItem = userItem
	end
	self.m_userId = userItem.dwUserID
	self:setContentSize(238,106)
	self:removeChildByTag(1000)
	self.m_fort = cc.Sprite:createWithSpriteFrameName("fort_0.png")
	self.m_fort:setTag(1000)
	self.m_fort:setPosition(35,58)
	self:addChild(self.m_fort,1)
	self.m_pos = userItem.wChairID
	if self._dataModel.m_reversal then 
		self.m_pos = 5 - self.m_pos
	end

	if self.m_pos < 3 then
		self.m_fort:setRotation(180)
	end

	if self.m_ChairID == self.m_nChairID then
		--self:setCannonType(g_var(cmd).CannonType.Laser_Cannon, 0)
	end
end



function Cannon:setFishIndex(index)
	self.m_fishIndex = index
end


function Cannon:setMultiple(multiple)

	--dump(self._dataModel.m_secene.nMultipleIndex, "xxxxis ===========================", 6)
	--print("mutiple is =========================="..multiple)
	self.m_nMutipleIndex = multiple

	local nMultipleValue = self._dataModel.m_secene.nMultipleValue[1][multiple+1]

	self.m_nCurrentBulletScore = nMultipleValue

	local nNum = 1

	if self.m_Type == g_var(cmd).CannonType.Special_Cannon then
		nNum = 2
	end

	local bulletNum = math.floor(self.m_nMutipleIndex/2) + 1

	--local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(string.format("gun_%d_%d.png", bulletNum,nNum))

	--self.m_fort:setSpriteFrame(frame)
	--nMultipleValue = multiples
	self.parent:updateMultiple(nMultipleValue,self.m_pos+1)

end

function Cannon:updateMultiple(multiple)
	self.parent:updateMultiple(multiple,self.m_pos+1)
end

--自动射击
function Cannon:setAutoShoot( b )

	self.m_autoShoot = b

	if self.m_cannonPoint.x == 0 and self.m_cannonPoint.y == 0 then 
		self.m_cannonPoint = self:convertToWorldSpace(cc.p(self.m_fort:getPositionX(),self.m_fort:getPositionY()))
	end

	if self.m_Type >= g_var(cmd).CannonType.Laser_Cannon then
		return
	end

	if self.m_autoShoot then

		local time =  self._dataModel.m_secene.nBulletCoolingTime[1][g_var(cmd).BULLET_MAX]/1000
		if self.m_Type == g_var(cmd).CannonType.Special_Cannon then
			time = time / 2
		end

		self:autoSchedule(time)

	else
		self:unAutoSchedule()	
	end
end

function Cannon:typeTimeUpdate( dt )

	self.m_typeTime = self.m_typeTime - dt

	--print("self.m_typeTime is ======================== "..self.m_typeTime)
	local tmp = self:getChildByTag(TagEnum.Tag_Type)
	if nil ~= tmp then
		local timeshow = tmp:getChildByTag(1)
		if nil ~= timeshow then
			timeshow:setString(string.format("%d",self.m_typeTime))
		end
		
	end

	if self.m_typeTime <= 0 then
		self:unTypeSchedule()
		self:removeTypeTag()	
		self:setCannonType(g_var(cmd).CannonType.Normal_Cannon, 0)
	end
end


--自己开火
function Cannon:shoot( vec , isbegin )

	if not self.m_canShoot then
		self.m_isShoot = isbegin
		return
	end
	print("m_cannonPoint.x %d m_cannonPoint.y %d",self.m_cannonPoint.x, self.m_cannonPoint.y)
	if self.m_cannonPoint.x == 0 and self.m_cannonPoint.y == 0 then		
		self.m_cannonPoint = self:convertToWorldSpace(cc.p(self.m_fort:getPositionX(),self.m_fort:getPositionY()))
	end

	local angle = self._dataModel:getAngleByTwoPoint(vec, self.m_cannonPoint)

	self.m_targetPoint = vec

	if angle < 90  then 

		if not self._dataModel.m_autolock then
			self.m_fort:setRotation(angle)
		end
	end

	if self.m_Type == g_var(cmd).CannonType.Laser_Shooting then
		return
	end

	if self.m_Type == g_var(cmd).CannonType.Laser_Cannon  then
		self:shootLaser()
		return
	end

	if self.m_autoShoot or self._dataModel.m_autolock then
		return
	end

	if not self.m_isShoot and isbegin then
		self.m_isShoot = true
		local time = self._dataModel.m_secene.nBulletCoolingTime[1][g_var(cmd).BULLET_MAX]/1000
		if self.m_Type == g_var(cmd).CannonType.Special_Canonn then
			time = time / 2 
		end

		self:autoUpdate(0)
		self:autoSchedule(time)
	end

	if not isbegin then
		self.m_isShoot = false
		self:unAutoSchedule()
	end

end

--其他玩家开火
function Cannon:othershoot( firedata )
	if  true == self.parent.parent.m_bLeaveGame then
		return
	end
	table.insert(self.m_firelist,firedata)
	self:setMultiple(self.m_nMutipleIndex)
	self:updateMultiple(firedata.nBulletScore)
	--self:setMultiple(firedata.nBulletScore)
	self.m_nCurrentBulletScore = firedata.nBulletScore
	local time = self._dataModel.m_secene.nBulletCoolingTime[1][g_var(cmd).BULLET_MAX]/1000
	if self.m_Type == g_var(cmd).CannonType.Special_Cannon then
		time = time/2
	end

	self:otherSchedule(time)
end

--发射激光
function Cannon:shootLaser()

    self._dataModel:playEffect(g_var(cmd).Prop_armour_piercing)

	self.m_Type = g_var(cmd).CannonType.Laser_Shooting

	local anim = cc.Animate:create(cc.AnimationCache:getInstance():getAnimation(g_var(cmd).FortLightAnim))
	self.m_fort:runAction(anim)
	self:removeChildByTag(TagEnum.Tag_Light)

	local node = cc.Node:create()
	node:setAnchorPoint(0.5,0.5)
	node:setContentSize(cc.size(10, 10))
	local angle = self.m_fort:getRotation()
	local moveDir = cc.pForAngle(math.rad(90-angle))
	cc.pMul(moveDir,50)
	node:setPosition(cc.pAdd(self.m_cannonPoint,moveDir))
	self.parent:addChild(node)

	local light = cc.Sprite:createWithSpriteFrameName("light.png")
	light:setPosition(node:getContentSize().width/2,0)
	light:setScale(0.5,1.0)
	node:addChild(light)

	local callFunc = cc.CallFunc:create(function ()
		light:removeFromParent()
	end)

	local action = cc.Sequence:create(cc.ScaleTo:create(1,1,1),cc.ScaleTo:create(1,0.5,1),callFunc)
	light:runAction(action)


	for i=1,4 do
		local fortLight = cc.Sprite:createWithSpriteFrameName(string.format("fortlight_%d.png", i-1))
		fortLight:setPosition(node:getContentSize().width/2,fortLight:getContentSize().height*0.6+(i-1)*fortLight:getContentSize().height*1.2-5*(i-1))
		fortLight:setScale(0.1,1.2)
		fortLight:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5,1.0,1.2),cc.ScaleTo:create(2,0,1.2)))
		node:addChild(fortLight)

	end
	node:setRotation(self.m_fort:getRotation())

	callFunc = cc.CallFunc:create(function()

		node:removeFromParent()
		self:setCannonType(g_var(cmd).CannonType.Normal_Cannon,0)
		self.m_Type = g_var(cmd).CannonType.Normal_Cannon

		if self.m_autoShoot --[[or self.m_isShoot]] then
			local time = self._dataModel.m_secene.nBulletCoolingTime[1][g_var(cmd).BULLET_MAX]/1000
			if self.m_Type == g_var(cmd).CannonType.Special_Cannon then
				time = time/2
			end

			self:autoUpdate(0)
			self:autoSchedule(time)

		elseif 0 ~= #self.m_firelist then
			local time = self._dataModel.m_secene.nBulletCoolingTime[1][g_var(cmd).BULLET_MAX]/1200
			if self.m_Type == g_var(cmd).CannonType.Special_Cannon then
				time = time/2
			end
			self:otherSchedule(time)
				
		end
	end)

	node:runAction(cc.Sequence:create(cc.DelayTime:create(2.3),callFunc))

	if  self.m_ChairID == self.m_nChairID then 
		
		local tmp =  cc.p(self.m_cannonPoint.x,self.m_cannonPoint.y)

		local  beginPos = self._dataModel:convertCoordinateSystem(tmp, 0, self._dataModel.m_reversal)
		local  endPos	= self._dataModel:convertCoordinateSystem(cc.p(node:getPositionX(),node:getPositionY()), 0, self._dataModel.m_reversal)

		local unLossTime = currentTime() - self._dataModel.m_enterTime

		local cmddata = CCmd_Data:create(12)
		cmddata:pushshort(beginPos.x)
		cmddata:pushshort(beginPos.y)
		cmddata:pushshort(endPos.x)
		cmddata:pushshort(endPos.y)
		cmddata:pushint(unLossTime)

		if not self.frameEngine:sendSocketData(cmddata) then
			self.frameEngine._callBack(-1,"发送激光消息失败")
		end
	end
end

--制造子弹
function Cannon:productBullet( isSelf,fishIndex, netColor)

	self.m_index = self.m_index + 1
	local angle = self.m_fort:getRotation()
	self:setFishIndex(self._dataModel.m_fishIndex)
	local paction = cc.Animate:create(cc.AnimationCache:getInstance():getAnimation(g_var(cmd).FortAnim))
	self.m_fort:runAction(paction)
	local bullet0 = Bullet:create(angle,self)
	local bullet1 = Bullet:create(angle,self)
	angle = math.rad(90-angle)
	local movedir = cc.pForAngle(angle)
	movedir = cc.p(movedir.x * 25 , movedir.y * 25)
	local offset = cc.p(20 * math.sin(angle),20 * math.cos(angle))
	--local moveBy = cc.MoveBy:create(0.065,cc.p(-movedir.x*0.65,-movedir.y * 0.65))
	--self.m_fort:runAction(cc.Sequence:create(moveBy,moveBy:reverse()))

	bullet0:setType(self.m_Type)
	bullet0:setIndex(self.m_index)
	bullet0:setIsSelf(isSelf)
	bullet0:setBbullet(bullet1)
	bullet0.m_bbullet = bullet1
	bullet0:setNetColor(netColor)
	bullet0:setFishIndex(fishIndex)
	bullet0:initPhysicsBody()
	bullet0:setTag(g_var(cmd).Tag_Bullet)
	local pos = cc.p(self.m_cannonPoint.x+movedir.x +offset.x/2,self.m_cannonPoint.y+movedir.y - offset.y/2)
	--pos = cc.p(pos.x , pos.y - offset.y/2)
	bullet0:setPosition(pos)
	self.parent.parent._gameView:addChild(bullet0,5) --self.parent.parent为GameLayer

	---[[
	bullet1:setType(self.m_Type)
	bullet1:setIndex(self.m_index)
	bullet1:setIsSelf(isSelf)
	bullet1:setBbullet(bullet0)
	bullet1.m_bbullet = bullet0
	bullet1:setNetColor(netColor)
	bullet1:setFishIndex(fishIndex)
	bullet1:initPhysicsBody()
	bullet1:setTag(g_var(cmd).Tag_Bullet +1)
	local pos1 = cc.p(self.m_cannonPoint.x+movedir.x - offset.x/2,self.m_cannonPoint.y+movedir.y +offset.y/2)
	bullet1:setPosition(pos1)
	self.parent.parent._gameView:addChild(bullet1,5)
	--]]
	if isSelf then

		self.parent.parent:setSecondCount(60)


		local cmddata = CCmd_Data:create(20)

   		cmddata:setcmdinfo(yl.MDM_GF_GAME, g_var(cmd).SUB_C_FIRE)
   		local rbg_value = RGB2INT(255,0,0)
   		cmddata:pushint(rbg_value);
   		cmddata:pushint(g_var(cmd).PROP_COUNT_MAX)
    		--cmddata:pushint(self._dataModel.m_secene.nMultipleValue[1][self.m_ChairID+1])
    	--print(bullet0.m_fishIndex)
  		cmddata:pushint(bullet0.m_fishIndex)
  		--print(self.m_index)
  		cmddata:pushint(self.m_index)

  		local pos = cc.p(movedir.x * 25 , movedir.y * 25)
  		pos = cc.p(self.m_cannonPoint.x + pos.x , self.m_cannonPoint.y + pos.y)
  		pos = self._dataModel:convertCoordinateSystem(pos, 0, self._dataModel.m_reversal)

  		self._dataModel:playEffect(g_var(cmd).Shell_8)

  		cmddata:pushshort(pos.x)
  		cmddata:pushshort(pos.y)

   		 --发送失败
   		if nil == self.frameEngine then
   			return
   		end
		if not self.frameEngine:sendSocketData(cmddata) then
			if nil ~= self.frameEngine then
   				self.frameEngine._callBack(-1,"发送开火息失败")
   			end	
		end
	end
end

function Cannon:fastDeal(  )
	self.m_canShoot = false
	self:runAction(cc.Sequence:create(cc.DelayTime:create(5.0),cc.CallFunc:create(function(	)
		self.m_canShoot = true
	end)))
end

function Cannon:setCannonType( cannontype,times)	

	if self.m_Type == g_var(cmd).CannonType.Special_Cannon and cannontype ~= g_var(cmd).CannonType.Special_Cannon then 
		if self.m_autoShoot or self.m_isShoot then
			self:unAutoSchedule()
			local time = self._dataModel.m_secene.nBulletCoolingTime[1][g_var(cmd).BULLET_MAX]/1000
			self:autoSchedule(time)
		end

		if 0 ~= #self.m_firelist then
			self:unOtherSchedule()
			local time = self._dataModel.m_secene.nBulletCoolingTime[1][g_var(cmd).BULLET_MAX]/1200
			self:otherSchedule(time)
		end
	end

	if cannontype == g_var(cmd).CannonType.Special_Cannon then
		--[[
		local nBulletNum = math.floor(self.m_nMutipleIndex/2) + 1
		local str = string.format("gun_%d_2.png", nBulletNum)
		self.m_fort:setSpriteFrame(cc.SpriteFrameCache:getInstance():getSpriteFrame(str))

		
		--]]
		self.m_Type = g_var(cmd).CannonType.Special_Cannon
		if self.m_autoShoot or self.m_isShoot then
			self:unAutoSchedule()
			local  time = self._dataModel.m_secene.nBulletCoolingTime[1][g_var(cmd).BULLET_MAX]/2000
			self:autoSchedule(time)
		end

	
		if #self.m_firelist > 0 then 
			self:unOtherSchedule()
			local  time = self._dataModel.m_secene.nBulletCoolingTime[1][g_var(cmd).BULLET_MAX]/2400
			self:otherSchedule(time)
		end


		local Type = cc.Sprite:create("game_res/im_icon_0.png")
		Type:setTag(TagEnum.Tag_Type)
		Type:setPosition(-29, 13)
		self:removeTypeTag()
		self:addChild(Type)

		if self.m_pos < 3 then
			Type:setPositionY(self:getContentSize().height - 23)
		end
		--[[
		local pos = nil
		if self.m_pos < 3 then
			pos = cc.p(110,-45)
		else
			pos = cc.p(110,150)
		end
		]]
		--Type:setPosition(pos.x,pos.y)

		self.m_typeTime = times
		self:typeTimeSchedule(1.0)


		local timeShow = cc.LabelAtlas:create(string.format("%d", times),"game_res/lockNum.png",16,22,string.byte("0"))
		timeShow:setAnchorPoint(0.5,0.5)
		timeShow:setPosition(Type:getContentSize().width/2, 25)
		timeShow:setTag(1)
		Type:addChild(timeShow)

		--Type:runAction(cc.RepeatForever:create(CirCleBy:create(1.0,cc.p(pos.x,pos.y),10)))


	elseif cannontype == g_var(cmd).CannonType.Laser_Cannon then
		
		if self.m_Type == g_var(cmd).CannonType.Laser_Cannon  then
			
			if self.m_ChairID == self.m_nChairID then
				self:unAutoSchedule()
				self.m_fort:setSpriteFrame("fort_light_0.png")
				self.m_typeTime = times
			end

			return
		end

		self._dataModel:playEffect(g_var(cmd).Small_Begin)

		self.m_Type = g_var(cmd).CannonType.Laser_Cannon

		self:unAutoSchedule()

		self.m_fort:setSpriteFrame("fort_light_0.png")

		local light = cc.Sprite:createWithSpriteFrameName("light_0.png")
		light:setTag(TagEnum.Tag_Light)

		if self.m_cannonPoint.x == 0 and self.m_cannonPoint.y == 0 then 
			self.m_cannonPoint = self:convertToWorldSpace(cc.p(self.m_fort:getPositionX(),self.m_fort:getPositionY()))
		end
		light:setPosition(self.m_fort:getPositionX(),self:getPositionY())
		self:addChild(light)

		local animate = cc.Animate:create(cc.AnimationCache:getInstance():getAnimation(g_var(cmd).LightAnim))
		local action = cc.RepeatForever:create(cc.Sequence:create(animate,animate:reverse()))
		light:runAction(action)
	
	elseif cannontype== g_var(cmd).CannonType.Bignet_Cannon then
		
		self.m_Type = g_var(cmd).CannonType.Bignet_Cannon
	
		self:removeTypeTag()

		local Type = cc.Sprite:create("game_res/im_icon_1.png")
		Type:setTag(TagEnum.Tag_Type)
		Type:setPosition(-29, 13)
		self:removeTypeTag()
		self:addChild(Type)
		if self.m_pos < 3 then
			Type:setPositionY(self:getContentSize().height - 23)
		end
		self.m_typeTime = times
		self:typeTimeSchedule(1.0)
		local timeShow = cc.LabelAtlas:create(string.format("%d", times),"game_res/lockNum.png",16,22,string.byte("0"))
		
		timeShow:setAnchorPoint(0.5,0.5)
		timeShow:setPosition(Type:getContentSize().width/2, 25)
		timeShow:setTag(1)
		Type:addChild(timeShow)
	elseif cannontype == g_var(cmd).CannonType.Normal_Cannon then
		
		self.m_Type = g_var(cmd).CannonType.Normal_Cannon
		self:removeTypeTag()
	end
end

--补给
function Cannon:ShowSupply( data )
	
	local pos = {}
	local box = cc.Sprite:createWithSpriteFrameName("fish_19_die_0.png")
	if self.m_pos < 3 then
		pos = cc.p(-30,20)
		
	else
		pos = cc.p(-40,self:getPositionY() - 30)
	end

	box:setPosition(pos.x, pos.y)
	self:addChild(box,1)

	local nSupplyType = data.nSupplyType
	--print("ShowSupply type is nil ",nSupplyType, tostring(nSupplyType == nil))
	local action = cc.Animate:create(cc.AnimationCache:getInstance():getAnimation("fish_19_die"))

	local call = cc.CallFunc:create(function ()
		if nSupplyType ~= g_var(cmd).EST_NULL then
			local gold = cc.Sprite:create("game_res/im_box_gold.png")
			gold:setPosition(box:getContentSize().width/2,box:getContentSize().height/2)
			box:addChild(gold)

			local typeStr = string.format("game_res/im_supply_%d.png", nSupplyType)
			local title = cc.Sprite:create(typeStr)
			if nil ~= title  then
				title:setPosition(box:getContentSize().width/2,100)
				box:addChild(title)
			end
		end
	end)

	box:runAction(cc.Sequence:create(action,call))


	call = cc.CallFunc:create(function()
		box:removeFromParent()
	end)

	local delay = cc.DelayTime:create(4)
	box:runAction(cc.Sequence:create(delay,call))

	if nSupplyType == g_var(cmd).EST_Laser and self.m_userId == self.m_pUserItem.dwUserID then

		if self.m_ChairID == self.m_nChairID then

			self:setCannonType(g_var(cmd).CannonType.Laser_Cannon, data.lSupplyCount)
			local ptPos = cc.p(0,0)
			ptPos.x = math.random(200) + 200
			ptPos.y = math.random(200) + 200
			local cmddata = CCmd_Data:create(4)
			cmddata:pushword(ptPos.x)
			cmddata:pushword(ptPos.y)
			if not self.frameEngine:sendSocketData(cmddata) then
				self.frameEngine._callBack(-1,"发送准备激光消息失败")
			end
		end

	elseif nSupplyType == g_var(cmd).EST_Speed then
		self:setCannonType(g_var(cmd).CannonType.Special_Cannon, data.lSupplyCount)
	
	elseif nSupplyType == g_var(cmd).EST_Strong then
	 	self:setCannonType(g_var(cmd).CannonType.Bignet_Cannon, data.lSupplyCount)
	elseif nSupplyType == g_var(cmd).EST_Gift then
		print("EST_Gift")
		self._dataModel.m_secene.lPlayCurScore[1][self.m_nChairID + 1] = self._dataModel.m_secene.lPlayCurScore[1][self.m_nChairID + 1] + data.lSupplyCount
		---[[
		local cannonPos = self.m_nChairID
             if self._dataModel.m_reversal then 
                cannonPos = 5 - cannonPos
             end
             --]]
		self.parent:updateUserScore( self._dataModel.m_secene.lPlayCurScore[1][self.m_nChairID + 1],cannonPos+1 )
	end
end


--自己开火
function Cannon:autoUpdate(dt)
	if  true == self.parent.parent.m_bLeaveGame then
		return
	end	
	if not self.m_canShoot or self.m_Type == g_var(cmd).CannonType.Laser_Cannon  then
		return
	end

	self:setFishIndex(self._dataModel.m_fishIndex)

	local score = self._dataModel.m_secene.nMultipleValue[1][self._dataModel.m_secene.nMultipleIndex+1]
	local nNum = g_var(cmd).MULTIPLE_MAX_INDEX

	local curScore = self._dataModel.m_secene.lPlayCurScore[1][self.m_nChairID + 1]

	score =  curScore - score

	if score < 0 then
		self:unAutoSchedule()
		self.m_autoShoot = false

		if nil == self._queryDialog then
      		local this = self
	    	self._queryDialog = QueryDialog:create("金币不足,请充值", function(ok)
	        this._queryDialog = nil
	    	end):setCanTouchOutside(false)
	        :addTo(cc.Director:getInstance():getRunningScene()) 
    	end

    	self._dataModel.m_autoShoot = false
    	local shoot = self.parent.parent._gameView:getChildByTag(self.parent.parent._gameView.m_TAG.tag_autoshoot)
    	self.parent.parent._gameView:setAutoShoot(self._dataModel.m_autoShoot,shoot)


    	self._dataModel.m_autolock = false
    	local lock = self.parent.parent._gameView:getChildByTag(self.parent.parent._gameView.m_TAG.tag_autolock)
    	self.parent.parent._gameView:setAutoLock(self._dataModel.m_autolock,lock)


    	return

	end

	if self.m_autoShoot  and  self._dataModel.m_autolock then
		
		if self.m_fishIndex == g_var(cmd).INT_MAX then
			 self:removeLockTag()
			 return
		end
		self:setFishIndex(self._dataModel.m_fishIndex)
		local fish = self._dataModel.m_fishList[self.m_fishIndex]

		if fish == nil then
			self:removeLockTag()
			table.remove(self._dataModel.m_fishList, self.m_fishIndex)
			local count = 0  
			for k,v in pairs(self._dataModel.m_fishList) do  
    			count = count + 1  
			end  
			--local count = #self._dataModel.m_fishList
			local num = 0;
			math.randomseed(os.time())
			local index = math.random(count)
			print(string.format("m_autolock fish nil m_fishList count %d index %d",count,index))
			for k,v in pairs (self._dataModel.m_fishList) do
				print(string.format("for curNUm %d ",num))
				--[[
				if num == index then
					return
				end 
				]]
				if nil ~= v and nil ~= v.m_data then
					self._dataModel.m_fishIndex = v.m_data.nFishKey
					print(string.format("random key is %d",v.m_data.nFishKey))
					return
				end
				num = num + 1
			end
			--[[
			self._dataModel.m_ivalidFishIndex = self._dataModel.m_fishIndex --self.m_fishIndex
			self:setFishIndex(self._dataModel.m_fishIndex)
			self._dataModel.m_fishIndex = g_var(cmd).INT_MAX
			--]]
		    return
		end

		local fishData = fish.m_data

		if fishData == nil then
			self:removeLockTag()
		    return
		end

		local frameName = string.format("fishLock_%d.png", fishData.nFishType+1)
		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName)

		if nil ~= frame then
			local sp = self:getChildByTag(TagEnum.Tag_lock)
			if nil == sp then
				local myNum = self.m_nChairID/3
				local playerNum = self.m_ChairID/3
				local pos = cc.p(-40,145)
				if myNum ~= playerNum then
					pos = cc.p(-30,-30)
				end
				sp = cc.Sprite:createWithSpriteFrame(frame)
				self:removeLockTag()
				sp:setTag(TagEnum.Tag_lock)
				sp:setPosition(pos.x,pos.y)
				self:addChild(sp)

				sp:runAction(cc.RepeatForever:create(CirCleBy:create(1.0,cc.p(pos.x,pos.y),10)))
			else
				sp:setSpriteFrame(frame)
			end
		else
			self:removeLockTag()					
		end

		local pos = cc.p(fish:getPositionX(),fish:getPositionY())
		if self._dataModel.m_reversal then
			pos = cc.p(yl.WIDTH-pos.x,yl.HEIGHT-pos.y)
		end

		local angle = self._dataModel:getAngleByTwoPoint(pos, self.m_cannonPoint)
		self.m_fort:setRotation(angle)

		self:productBullet(true,self.m_fishIndex,self._dataModel:getNetColor(self.parent.parent._gameView.netColorIndex))
	else
		self:productBullet(true,g_var(cmd).INT_MAX,self._dataModel:getNetColor(self.parent.parent._gameView.netColorIndex))

	end
	if  false == self.parent.parent.m_bLeaveGame then
		self:updateScore(score)
	end	
	
	self._dataModel.m_secene.lPlayCurScore[1][self.m_nChairID + 1] = score
	--print(string.format("开火分数 %d", self._dataModel.m_secene.nMultipleValue[1][self.m_nMutipleIndex+1]))
	--print(string.format("s",1))
	self._dataModel.m_secene.lBulletConsume[1][self.m_nChairID+1] = self._dataModel.m_secene.lBulletConsume[1][self.m_nChairID+1] + self._dataModel.m_secene.nMultipleValue[1][self._dataModel.m_secene.nMultipleIndex+1]


end


function Cannon:autoSchedule(dt)

	local function updateAuto(dt)
		self:autoUpdate(dt)
	end

	if nil == self.m_autoShootSchedule then
		self.m_autoShootSchedule = scheduler:scheduleScriptFunc(updateAuto, dt, false)
	end

end

function Cannon:unAutoSchedule()
	if nil ~= self.m_autoShootSchedule then
		scheduler:unscheduleScriptEntry(self.m_autoShootSchedule)
		self.m_autoShootSchedule = nil
	end
end

--其他玩家开火
function Cannon:otherUpdate(dt)
	
	if 0 == #self.m_firelist then
		self:unOtherSchedule()
		self.m_isShoot = false
		return
	end

	local fire = self.m_firelist[1]
	table.remove(self.m_firelist,1)


	local pos = cc.p(fire.ptPos.x,fire.ptPos.y)
	pos = self._dataModel:convertCoordinateSystem(pos, 1, self._dataModel.m_reversal)

	if self.m_cannonPoint.x == 0 and self.m_cannonPoint.y == 0 then 
		self.m_cannonPoint = self:convertToWorldSpace(cc.p(self.m_fort:getPositionX(),self.m_fort:getPositionY()))
	end

	local angle = self._dataModel:getAngleByTwoPoint(pos, self.m_cannonPoint)
	
	
	--if  fire.nTrackFishIndex == g_var(cmd).INT_MAX then
		self.m_fort:setRotation(angle)
	--end


	self:productBullet(false, fire.nTrackFishIndex, cc.WHITE)	
	--print(string.format("开火分数 %d", fire.nBulletScore))
	--更新分数
	self.m_pOtherUserItem.lScore = self.m_pOtherUserItem.lScore - fire.nBulletScore
	self:updateScore(self.m_pOtherUserItem.lScore)

end

function Cannon:updateScore(score)

	self.parent:updateUserScore(score,self.m_pos+1)	
end

function Cannon:updateIngot(ingot)

	self.parent:updateUserIngot(ingot,self.m_pos+1)	
end

function Cannon:otherSchedule(dt)

	local function updateOther(dt)
		self:otherUpdate(dt)
	end

	if nil == self.m_otherShootSchedule then
		self.m_otherShootSchedule = scheduler:scheduleScriptFunc(updateOther, dt, false)
	end

end

function Cannon:unOtherSchedule()
	if nil ~= self.m_otherShootSchedule then
		scheduler:unscheduleScriptEntry(self.m_otherShootSchedule)
		self.m_otherShootSchedule = nil
	end
end

function Cannon:typeTimeSchedule( dt )

	local function  update( dt  )
		self:typeTimeUpdate(dt)
	end

	if nil == self.m_typeSchedule then
		self.m_typeSchedule = scheduler:scheduleScriptFunc(update, dt, false)
	end
	
end

function Cannon:unTypeSchedule()
	if nil ~= self.m_typeSchedule then
		scheduler:unscheduleScriptEntry(self.m_typeSchedule)
		self.m_typeSchedule = nil
	end
end


function Cannon:removeLockTag()

	self:removeChildByTag(TagEnum.Tag_lock)
end


function Cannon:removeTypeTag()
	

	self:removeChildByTag(TagEnum.Tag_Type)

end

function RGB2INT(r,g,b)
	local nValue =  bit:_lshift(bit:_and(255, 0xff), 24) + bit:_lshift(bit:_and(r, 0xff),16) + bit:_lshift(bit:_and(g, 0xff), 8) + bit:_and(b, 0xff)
	return nValue
end

return Cannon