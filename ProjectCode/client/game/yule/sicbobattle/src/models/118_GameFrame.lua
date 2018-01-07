--
-- Author: zhong
-- Date: 2016-07-05 11:29:56
--
local GameFrame = class("GameFrame")

local module_pre = "game.yule.sicbobattle.src";
local cmd = require(module_pre .. ".models.CMD_Game")
local bjlDefine = require(module_pre .. ".models.GameDefine")
local GameLogic = require(module_pre .. ".models.GameLogic")

------
--tips
-- lua的table下标是从1开始，所以在处理椅子号的时候 +1
------

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

    --游戏记录
    self.m_vecRecord = {}
    --路单
    self.m_vecWallBill = {}

    --游戏成绩
    self.m_llTotalScore =  0
    --命中率
    self.m_fGameRate = 0.00
    --游戏总局数
    self.m_nTotalRound = 0
    --赢局数量
    self.m_nTotalWinRound = 0

    --游戏结果
    self.m_tabGameResult = {}
    self.m_bJoin = false
    self.m_tabBetArea = {}
    self.m_tabGameEndCmd = {}
end

------
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
    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
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

    local info = bjlDefine.getEmptyApplyInfo()
    
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

------
--路单系统

--增加游戏记录
function GameFrame:addGameRecord( rec )
    table.insert(self.m_vecRecord, rec)

    if #self.m_vecRecord > 10 then
        table.remove(self.m_vecRecord,1)
    end
end

--获取游戏记录
function GameFrame:getRecords(  )
    return self.m_vecRecord
end

--获取路单
function GameFrame:getWallBills(  )
    return self.m_vecWallBill
end

--清理记录
function GameFrame:clearRecord(  )
    self.m_vecRecord = {}
    self.m_vecWallBill = {}
end

--在连赢的情况下，从指定索引开始，根据给定输赢结果寻找最近的上一局符合连赢条件的记录
-- function GameFrame:seekWinList( endIdx, cbResult )
--     if cmd.AREA_PING == cbResult then
--         return true
--     end

--     for i = endIdx, 1, -1 do
--         local rec = self.m_vecRecord[i]
--         --找到相同的即连赢
--         if cbResult == rec.m_cbGameResult then
--             return true
--         end

--         --找到一个不相同的就是非连赢
--         if (cbResult ~= rec.m_cbGameResult) and (cmd.AREA_PING ~= rec.m_cbGameResult) then
--             return false
--         end
--     end
--     return false
-- end

--找到最后一个连赢记录下标(idx bFound)
-- function GameFrame:lastWinListIdx( nBegin )
--     local idx = 1
--     local bFound = false
--     for i = nBegin, #self.m_vecWallBill do
--         local bill = self.m_vecWallBill[i]
--         if (bill.m_bWinList) and (false == bill.m_bJumpIdx) then
--             idx = i
--             bFound = true
--             break
--         end
--     end
--     return idx,bFound
-- end

------
--计算胜率
-- function GameFrame:calcuteRata( nWin, nLost )
--     self.m_nTotalRound = self.m_nTotalRound + nWin + nLost;
--     self.m_nTotalWinRound = self.m_nTotalWinRound + nWin;
    
--     self.m_fGameRate = self.m_nTotalWinRound / self.m_nTotalRound;
-- end
------

--计算下注标签
function GameFrame.calcuteJetton( llScore, bAllJetton )
    local vec = {};

    if bAllJetton then
        --已屏蔽全部下注
    else
        local tmpScore = llScore;
        --info = GameJettonNode.tagJettonInfo
        --计算千万下注数量
        -- local nCount = math.floor(tmpScore / 10000000);
        -- if (nCount > 0) then        
        --     local info = {m_cbIdx = 0, m_cbCount = 0, m_llScore = 0};
        --     info.m_llScore = 10000000;
        --     info.m_cbCount = nCount;
        --     info.m_cbIdx = 7;
        --     table.insert(vec,info);
            
        --     tmpScore = tmpScore - nCount * 10000000;
        -- end
        
        --计算五百万下注数量
        nCount = math.floor(tmpScore / 5000000);
        if (nCount > 0) then
            local info = {m_cbIdx = 0, m_cbCount = 0, m_llScore = 0};
            info.m_llScore = 5000000;
            info.m_cbCount = nCount;
            info.m_cbIdx = 6;
            table.insert(vec,info);
            
            tmpScore = tmpScore - nCount * 5000000;
        end
        
        --计算一百万下注数量
        nCount = math.floor(tmpScore / 1000000);
        if (nCount > 0) then
            local info = {m_cbIdx = 0, m_cbCount = 0, m_llScore = 0};
            info.m_llScore = 1000000;
            info.m_cbCount = nCount;
            info.m_cbIdx = 5;
            table.insert(vec,info);
            
            tmpScore = tmpScore - nCount * 1000000;
        end
        
        --计算十万下注数量
        nCount = math.floor(tmpScore / 100000);
        --print("count:" .. nCount .. "; score:" .. tmpScore )
        if (nCount > 0) then
            local info = {m_cbIdx = 0, m_cbCount = 0, m_llScore = 0};
            info.m_llScore = 100000;
            info.m_cbCount = nCount;
            info.m_cbIdx = 4;
            table.insert(vec,info);
            
            tmpScore = tmpScore - nCount * 100000;
        end
        
        --计算一万下注数量
        nCount = math.floor(tmpScore / 10000);
        if (nCount > 0) then
            local info = {m_cbIdx = 0, m_cbCount = 0, m_llScore = 0};
            info.m_llScore = 10000;
            info.m_cbCount = nCount;
            info.m_cbIdx = 3;
            table.insert(vec,info);
            
            tmpScore = tmpScore - nCount * 10000;
        end
        
        --计算一千下注数量
        nCount = math.floor(tmpScore / 1000);
        if (nCount > 0) then
            local info = {m_cbIdx = 0, m_cbCount = 0, m_llScore = 0};
            info.m_llScore = 1000;
            info.m_cbCount = nCount;
            info.m_cbIdx = 2;
            table.insert(vec,info);
            
            tmpScore = tmpScore - nCount * 1000;
        end
        
        --计算一百下注数量
        nCount = math.floor(tmpScore / 500);
        if (nCount > 0) then
            info = {m_cbIdx = 0, m_cbCount = 0, m_llScore = 0};
            info.m_llScore = 500;
            info.m_cbCount = nCount;
            info.m_cbIdx = 1;
            table.insert(vec,info);
            
            tmpScore = tmpScore - nCount * 500;
        end
        --计算一百下注数量
        -- nCount = math.floor(tmpScore / 100);
        -- if (nCount > 0) then
        --     info = GameJettonNode.tagJettonInfo;
        --     info.m_llScore = 100;
        --     info.m_cbCount = nCount;
        --     info.m_cbIdx = 1;
        --     vec.push_back(isnfo);
            
        --     tmpScore = tmpScore - nCount * 100;
        -- end
    end

    return vec;
end
return GameFrame;