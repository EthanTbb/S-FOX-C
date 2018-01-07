--
-- Author: Tang
-- Date: 2016-12-13 09:41:59
--
local GameFrame = class("GameFrame")

GameFrame._nRows	 = 15	--行数
GameFrame._nColumns  = 15	--列数

function GameFrame:ctor()
 	
	self._sign = {}

	self:initSign() 

	self._targetRow = 0
	self._targetCol = 0

end

function GameFrame:initSign()
	self._sign = {}
	for r=1,GameFrame._nRows do
		for c=1,GameFrame._nColumns do
			local sign = 0
			table.insert(self._sign,sign)
		end
	end
end



function GameFrame:setSign(xpos,ypos,nSign)
	local pos = (xpos-1)*GameFrame._nColumns +  ypos 
	self._sign[pos] = nSign
end

function GameFrame:getSign( xpos,ypos )
	local pos = (xpos-1)*GameFrame._nColumns +  ypos 
	return self._sign[pos]
end




return GameFrame