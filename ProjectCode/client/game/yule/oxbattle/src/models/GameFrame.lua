--
-- Author: zhouweixiang
-- Date: 2016-11-24 14:51:31
--

local BrnnCMD = appdf.req(appdf.GAME_SRC.."yule.oxbattle.src.models.CMD_Game")
local GameFrame = class("GameFrame")

local RecordMaxNum = 12  --最大路单记录

function GameFrame:ctor()
	--以座椅号管理
    self.m_tableChairUserList = {}
    --以uid管理
    self.m_tableUidUserList = {}
    --编号管理
    self.m_tableList = {}
    --上庄用户
    self.m_tableApplyList = {}
    --申请上庄数量
    self.m_llApplyCount = 0

    --路单
    self.m_vecRecord = {}
end

--游戏玩家管理

--初始化用户列表
function GameFrame:initUserList( userList )
    --以座椅号管理
    self.m_tableChairUserList = {}
    --以uid管理
    self.m_tableUidUserList = {}
    self.m_tableList = {}

    for k,v in pairs(userList) do
        self.m_tableChairUserList[v.wChairID + 1] = v;
        self.m_tableUidUserList[v.dwUserID] = v;
        table.insert(self.m_tableList, v)
    end
end

--增加用户
function GameFrame:addUser( userItem )
    if nil == userItem then
        return;
    end

    self.m_tableChairUserList[userItem.wChairID + 1] = userItem;
    self.m_tableUidUserList[userItem.dwUserID] = userItem;
    
    local user = self:isUserInList(userItem)
    if nil == user then
        table.insert(self.m_tableList, userItem)
    else
        user = userItem
    end 

    print("after add:" .. #self.m_tableList)
end

function GameFrame:updateUser( useritem )
    if nil == useritem then
        return
    end

    local user = self:isUserInList(useritem)
    if nil == user then
        table.insert(self.m_tableList, useritem)
    else
        user = useritem
    end

    self.m_tableChairUserList[useritem.wChairID + 1] = useritem;
    self.m_tableUidUserList[useritem.dwUserID] = useritem;
end

function GameFrame:isUserInList( useritem )
    local user = nil
    for k,v in pairs(self.m_tableList) do
        if v.dwUserID == useritem.dwUserID then
            user = useritem
            break
        end
    end
    return user
end

--移除用户
function GameFrame:removeUser( useritem )
    if nil == useritem then
        return
    end

    local deleteidx = nil
    for k,v in pairs(self.m_tableList) do
        local item = v
        if v.dwUserID == useritem.dwUserID then
            deleteidx = k
            break
        end
    end

    if nil ~= deleteidx then
        table.remove(self.m_tableList,deleteidx)
    end

    table.remove(self.m_tableChairUserList,useritem.wChairID + 1)
    table.remove(self.m_tableUidUserList,useritem.dwUserID)

    print("after remove:" .. #self.m_tableList)
end

function GameFrame:removeAllUser(  )
    --以座椅号管理
    self.m_tableChairUserList = {}
    --以uid管理
    self.m_tableUidUserList = {}

    self.m_tableList = {}
    --上庄用户
    self.m_tableApplyList = {}
end

function GameFrame:getChairUserList(  )
    return self.m_tableChairUserList;
end

function GameFrame:getUidUserList(  )
    return self.m_tableUidUserList;
end

function GameFrame:getUserList( )
    return self.m_tableList
end

function GameFrame:sortList(  )
    --排序
    local function sortFun( a,b )
        return a.m_llIdx > b.m_llIdx
    end
    table.sort(self.m_tableApplyList, sortFun)
end

------
--庄家管理

--添加庄家申请用户
function GameFrame:addApplyUser( wchair,bRob )
    local useritem = self.m_tableChairUserList[wchair + 1]
    if nil == useritem then
        return
    end
    bRob = bRob or false

    local info = BrnnCMD.getEmptyApplyInfo()
    
    info.m_userItem = useritem
    info.m_bCurrent = useritem.dwUserID == GlobalUserItem.dwUserID
    if bRob then
        --超级抢庄排最前
        info.m_llIdx = -1
    else
        self.m_llApplyCount = self.m_llApplyCount + 1
        if self.m_llApplyCount > yl.MAX_INT then
            self.m_llApplyCount = 0
        end
        info.m_llIdx = self.m_llApplyCount
    end    
    info.m_bRob = bRob

    local user = self:getApplyUser(wchair)
    if nil ~= user then
        user = info
    else
        table.insert(self.m_tableApplyList, info)
    end    

    self:sortList()
end

function GameFrame:getApplyUser( wchair )
    local user = nil
    for k,v in pairs(self.m_tableApplyList) do
        if v.m_userItem.wChairID == wchair then
            user = v
            break
        end
    end
    return user
end

--超级抢庄用户
--rob[抢庄用户] cur[当前用户]
function GameFrame:updateSupperRobBanker( rob,cur )
    if rob ~= cur then
        self:updateSupperRobState(cur, false)
    end
    if nil == self:updateSupperRobState(rob, true) then
        --添加
        self:addApplyUser(rob, true)
    end
    self:sortList()
end

--移除庄家申请用户
function GameFrame:removeApplyUser( wchair )
    local removeIdx = nil
    for k,v in pairs(self.m_tableApplyList) do
        if v.m_userItem.wChairID == wchair then
            removeIdx = k
            break
        end
    end

    if nil ~= removeIdx then
        table.remove(self.m_tableApplyList,removeIdx)
    end

    self:sortList()
end

--更新超级抢庄用户状态
function GameFrame:updateSupperRobState( wchair, state )
    local user = nil
    for k,v in pairs(self.m_tableApplyList) do
        if v.m_userItem.wChairID == wchair then
             --超级抢庄排最前
            v.m_llIdx = -1
            v.m_bRob = state
            user = v
            break
        end
    end
    return user
end

--获取申请庄家列表
function GameFrame:getApplyBankerUserList(  )
    return self.m_tableApplyList
end

---路单数据
function GameFrame:addGameRecord(rec)
    table.insert(self.m_vecRecord, rec)
    local listnum = #self.m_vecRecord
    if listnum > RecordMaxNum then
        local movenum = listnum - RecordMaxNum
        for i=1, movenum do
            table.remove(self.m_vecRecord, 1)
        end
    end
end

--获取路单
function GameFrame:getGameRecord(  )
    return self.m_vecRecord
end

--清除路单
function GameFrame:clearRecord()
    self.m_vecRecord = {}
end

------
return GameFrame