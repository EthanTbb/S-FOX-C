--
-- Author: Tang
-- Date: 2016-08-09 14:50:01
--
local GameFrame = class("GameFrame")

local MATERIAL_DEFAULT = cc.PhysicsMaterial(0.1, 0.5, 0.5)

 function GameFrame:ctor()
 	
 	self.m_autoshoot = false    --自动射击
 	self.m_autolock = false 	--自动锁定
 	self.m_reversal = false
 	self.m_fishIndex = 2147483647
 	self.m_ivalidFishIndex = 2147483647 --非法的锁定鱼
 	self._exchangeSceneing	= false

 	self.m_getFishScore = 0     --捕鱼收获
 	
 	self.m_waitList = {}  --等待鱼列表
 	self.m_fishList = {}  --鱼列表
 	self.m_fishKingList = {} --记录鱼王
 	self.m_fishCreateList = {} --创建鱼

 	self.m_fishArray = {}	--场景中鱼

 	self.m_bodyList = {}  --物体刚体数据

 	self.m_secene = {}	--场景数据
    self.m_nMultiple = {1,10,100,500,1000,5000} --房间倍数

    self.m_sinList = {}
    self.m_cosList = {}


   	self:readyBodyPlist("game_res/fish_0.plist")
   	self:readyBodyPlist("game_res/fish_1.plist")
   	self:readyBodyPlist("game_res/fish_2.plist")
   	self.m_enterTime = 0	--进入时间 

    self:initTrigonomentirc()

 end


--解析刚体数据 plist
function GameFrame:readyBodyPlist( param )
	
    local Path = cc.FileUtils:getInstance():fullPathForFilename(param)
    local datalist = cc.FileUtils:getInstance():getValueMapFromFile(Path) 
    local bodies = datalist["bodies"]
  
  --解析数据
 	 for k,v in pairs(bodies) do
    	if  k ~= nil then
    		local bodyName = k
    		print(string.format("bodyName %s", bodyName))
    		local sub = bodies[bodyName]
    		local fixtures = sub["fixtures"]
    		local polygonsarr = fixtures[1]
    		local polygons = polygonsarr["polygons"]
    		
    		local points = {}
    		for i=1,#polygons do	
    		  	table.insert(points, polygons[i])
    		end
    		table.insert(self.m_bodyList,{k = bodyName,p = points})

    	   
    	end
    end
end

function GameFrame:getBodyByType( param )
	local type = string.format("fish_%d_yd_0", param)
	return self:getBodyByName(type)
end

function GameFrame:getBodyByName( param )
	--print( string.format("getBodyByName begin %s", param))
	if #self.m_bodyList ~= 0 then
		for i=1,#self.m_bodyList do
			local sublist = self.m_bodyList[i]
			local k = sublist.k
	
			if k == param then
				local points = sublist.p
				local physicsBody = cc.PhysicsBody:create(PHYSICS_INFINITY, PHYSICS_INFINITY)
				for s=1,#points do
					local onePoint = points[s]
					local resultPoints = {}
					for t=1,#onePoint do
						local vector = onePoint[t]
						--去掉大括号
						local result = string.sub(vector, 2, -2)
						local len = string.len(result)
						local dindex = string.find(result,",")

						local subx = string.sub(result,1,dindex-1)
						local x = tonumber(subx)
						local suby = string.sub(result,dindex+1,len)
						local y = tonumber(suby)
		
						local p = cc.p(x,y)
						table.insert(resultPoints, p)
					end

					local center = cc.PhysicsShape:getPolyonCenter(resultPoints)
				    local shape = cc.PhysicsShapePolygon:create(resultPoints,cc.PHYSICSBODY_MATERIAL_DEFAULT,cc.p(-center.x, -center.y))
				    physicsBody:addShape(shape)
					physicsBody:setGravityEnable(false)
					return physicsBody

				end
			 break
			end
		end

	end

end

--[[
@function  convertCoordinateSystem

@param type : 0 左下角坐标系转换到左上角坐标系 
			  1 左上角坐标系转换到左下角坐标系
			  2 爆炸动画坐标系

@return cc.p
]]
function GameFrame:convertCoordinateSystem( point,type,bconvert )

 local WIN32_W = 1280
 local WIN32_H = 800
 local scalex = yl.WIDTH/WIN32_W
 local scaley = yl.HEIGHT/WIN32_H

 local point1 = point 
 if type ==0 then
 	point1.x = point.x/scalex
 	point1.y = WIN32_H - point1.y/scaley
 	if bconvert  then
 	   point1.x = WIN32_W - point1.x
 	   point1.y = WIN32_H - point1.y
 	end
 elseif type == 1 then
 	
    point1.x = point.x*scalex
    point1.y = yl.HEIGHT - point.y*scaley

    if bconvert then
    	point1.x = yl.WIDTH - point1.x
    	point1.y = yl.HEIGHT - point1.y
    end

 else
 	point1.x = point1.x/scalex

 	if bconvert then
 		point1.x = WIN32_W - point1.x
 		point1.y = WIN32_H - point1.y/scaley
 	end

 end

  return point1
   
end

function GameFrame:getAngleByTwoPoint( param,param1 )

   if type(param) ~= "table" or type(param1) ~= "table" then
   	print("传入参数有误")
   	return
   end

	local point = cc.p(param.x-param1.x,param.y-param1.y)
	local angle = 90 - math.deg(math.atan2(point.y, point.x))
   -- print("angle is ========>"..angle)
    return angle

end


function GameFrame:getNetColor( param )

	if type(param) ~= "number" then
		return
	end

	if param == 0 or param > 5 then
		param = 1
	end

	local switch = 
	{
		[1] = function( )
			--print("case 1")
			return  cc.BLUE
		end,

		[2] = function( )
			--print("case 2")
			return  cc.GREEN
		end,

		[3] = function( )
			--print("case 3")
			return cc.c3b(232, 51, 217)
		end,

		[4] = function( )
			--print("case 4")
			return  cc.RED
		end,

		[5] = function( )
			--print("case 5")
			return cc.YELLOW
		end,

		[6] = function( )
			--print("case 6")
			return cc.YELLOW
		end
	}

	local f = switch[param]
	return f()

end


--自动锁定搜寻大鱼
function GameFrame:selectMaxFish( )
	
	local fishlist = {}
	local fishtype = 0
	local rect = cc.rect(0,0,yl.WIDTH,yl.HEIGHT)


	for k,v in pairs(self.m_fishList) do
		local fish = v
		if nil ~= fish and nil ~=  fish.m_data and false == fish.m_bRemove then
			if self.m_fishIndex ~= fish.m_data.nFishKey and self.m_ivalidFishIndex ~= fish.m_data.nFishKey and fish.m_data.nFishType > fishtype then
			local pos = cc.p(fish:getPositionX(),fish:getPositionY())
				if cc.rectContainsPoint( rect, pos ) then
				fishtype = fish.m_data.nFishType
				fishlist = {}
				table.insert(fishlist,fish)
				end
			end

			if fish.m_data.nFishType == fishtype then
			table.insert(fishlist,fish)
			end
		
		end
		
	end

	local mid = cc.p(yl.WIDTH/2,yl.HEIGHT/2)
	local distant = 1000
	local fishIndex = 2147483647
	for i=1,#fishlist do
		local fish = fishlist[i]
		local pos = cc.p(fish:getPositionX(),fish:getPositionY())
		local distant1 =  cc.pGetDistance(pos,mid)

		if distant1 < distant then
			distant = distant1
			fishIndex = fish.m_data.nFishKey
		end
	end

	fishlist = {}
	print("selectMaxFish fish type ",fishIndex,fishtype)
	return fishIndex
end

function GameFrame:initTrigonomentirc( )
	for i=1,360 do
		local sin = math.sin(3.14 / 180 * i)
		local cos = math.cos(3.14 / 180 * i)
		table.insert(self.m_sinList, sin)
		table.insert(self.m_cosList, cos)
	end
end

function GameFrame:playEffect( file )
	if not GlobalUserItem.bVoiceAble then
		return
	end
	
	AudioEngine.playEffect(file)

end



return GameFrame