--
-- Author: Tang
-- Date: 2016-10-11 17:21:57
--
local  GameFrame = class("GameFrame")


function GameFrame:ctor()

	self.m_BankList = {}  			--上庄列表
	self.m_UserList = {}			--用户列表
	self.m_ChatRecord = {}

	self._Multiple = 1
	

end


function GameFrame:getRcordList()
	return  self.m_ChatRecord
end

function GameFrame:getBankList()
	return  self.m_BankList
end

function GameFrame:getUserList()
	return self.m_UserList
end

function GameFrame:getUserByChair(userList,wchair)
	local item

	--dump(userList, "useritem is ======================== >", 6)
	for k,v in pairs(userList) do
		local userItem = v
	
		if userItem.wChairID == wchair then

			item = userItem
			return item
		end
	end

	return item
end


--------------------------------------------------------------上庄列表操作
function GameFrame:insertBankerList(useritem)
	
	if #self.m_BankList > 0 then
		for k,v in pairs(self.m_BankList) do
			local item = v
			if item.dwUserID == useritem.dwUserID then
				print("Eror:the userItem is exist,do not allowed insert repeat")
				return
			end
		end
	end

 	table.insert(self.m_BankList, useritem)

end


function GameFrame:removeBankList(useritem)

	if not useritem then
		return
	end
	
	local bItem = false
	if #self.m_BankList > 0 then
		for i=1,#self.m_BankList do
			local item = self.m_BankList[i]
			if item.dwUserID == useritem.dwUserID then
				bItem = true
				table.remove(self.m_BankList,i)
				return
			end
		end
	end

	if not bItem then
		print("Eror:the userItem do not exist,remove failure!!!")
	end

end
-------------------------------------------------------------------

------------------------------------------------------------------用户列表操作

function GameFrame:insertUserList(useritem)
	if #self.m_UserList > 0 then
		for k,v in pairs(self.m_UserList) do
			local item = v
			if item.dwUserID == useritem.dwUserID then
				print("Eror:the userItem is exist,do not allowed insert repeat")
				return
			end
		end
	end
 	table.insert(self.m_UserList, useritem)
end

function GameFrame:removeUserList(useritem)
	
	local bItem = false
	if #self.m_UserList > 0 then
		for i=1,#self.m_UserList do
			local item = self.m_UserList[i]
			if item.dwUserID == useritem.dwUserID then
				bItem = true
				table.remove(self.m_UserList,i)
				return
			end
		end
	end

	if not bItem then
		print("Eror:the userItem do not exist,remove failure!!!")
	end

end

------------------------------------------------------------------

function GameFrame:insertRecord(record)

	if type(record) ~= "table" then
		error("the param type is error,talbe is expected",1)
		return
	end

	if #self.m_ChatRecord == 60 then
		table.remove(self.m_ChatRecord,60)
	end

	table.insert(self.m_ChatRecord, 1,record)
end


function GameFrame:DeepCopy(source)

	local _table = {}
	for i=1,#source do
		local m = source[i]
		table.insert(_table,m)
	end
	return _table
end

function GameFrame:reverse(source)
	if #source == 0 or not source then
		return
	end

	if math.mod(#source,2) == 0 then

		local mid = math.floor(#source/2)

		for i=1,mid do
			local temp 
			temp = source[i]
			source[i] = source[#source+1-i]
			source[#source+1-i]  = temp
		end
	else 
	
		local mid = math.floor(#source/2) + 1

		for i=1,mid-1 do
			local temp = {} 
			temp = source[i]
			source[i] = source[#source+1-i]
			source[#source+1-i]  = temp
		end	
	end
end


return GameFrame