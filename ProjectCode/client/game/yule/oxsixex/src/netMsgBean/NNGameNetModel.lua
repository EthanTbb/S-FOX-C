--region *.lua
--Date
--此文件由[BabeLua]插件自动生成



--endregion
local NNGameNetModel = class("NNGameNetModel")
local cmd = appdf.req(appdf.GAME_SRC.."yule.oxsixex.src.models.CMD_Game")

function NNGameNetModel:ctor()

end

function NNGameNetModel:readSubFreeStatues(dataBuffer)
    local int64 = Integer64.new()
    local t_data = {}
    t_data.lTurnScore = {}
    t_data.lCollectScore = {}
    t_data.CustomAndroid = {}
        
    --游戏变量
    t_data.lCellScore          = dataBuffer:readscore(int64):getvalue()    --基础积分
    t_data.lRoomStorageStart   = dataBuffer:readscore(int64):getvalue()    --房间起始库存
    t_data.lRoomStorageCurrent = dataBuffer:readscore(int64):getvalue()    --房间当前库存

    --历史积分
    for i=1,cmd.GAME_PLAYER do
        t_data.lTurnScore[i]    = dataBuffer:readscore(int64):getvalue()
    end
        
        for i=1,cmd.GAME_PLAYER do
        t_data.lCollectScore[i]    = dataBuffer:readscore(int64):getvalue()
    end

    --机器人配置
    t_data.CustomAndroid.lRobotScoreMin = dataBuffer:readscore(int64):getvalue()
    t_data.CustomAndroid.lRobotScoreMax = dataBuffer:readscore(int64):getvalue()
    t_data.CustomAndroid.lRobotBankGet = dataBuffer:readscore(int64):getvalue()
    t_data.CustomAndroid.lRobotBankGetBanker = dataBuffer:readscore(int64):getvalue()
    t_data.CustomAndroid.lRobotBankStoMul = dataBuffer:readscore(int64):getvalue()

    return t_data
end

function NNGameNetModel:readSubPlayingStatues(dataBuffer)
    local int64 = Integer64.new()
    local t_data = {}
    t_data.cbPlayStatus = {}
    t_data.lTableScore = {}
    t_data.CustomAndroid = {}
    t_data.bOxCard = {}
    t_data.cbOxCardData = {}
    t_data.cbHandCardData = {}
    t_data.lTurnScore = {}
    t_data.lCollectScore = {}
    --状态信息
    t_data.cbDynamicJoin = dataBuffer:readbyte()                --动态加入
    for i=1,cmd.GAME_PLAYER do
        t_data.cbPlayStatus[i]  = dataBuffer:readbyte()         --用户状态    
    end

    for i=1,cmd.GAME_PLAYER do  
        t_data.lTableScore[i]   = dataBuffer:readscore(int64):getvalue()   --下注数目
    end
    t_data.lCellScore          = dataBuffer:readscore(int64):getvalue()    --基础积分
    t_data.wBankerUser         = dataBuffer:readword()                     --庄家用户
    t_data.lRoomStorageStart   = dataBuffer:readscore(int64):getvalue()    --房间起始库存
    t_data.lRoomStorageCurrent = dataBuffer:readscore(int64):getvalue()    --房间当前库存

    --机器人配置
    t_data.CustomAndroid.lRobotScoreMin = dataBuffer:readscore(int64):getvalue()
    t_data.CustomAndroid.lRobotScoreMax = dataBuffer:readscore(int64):getvalue()
    t_data.CustomAndroid.lRobotBankGet = dataBuffer:readscore(int64):getvalue()
    t_data.CustomAndroid.lRobotBankGetBanker = dataBuffer:readscore(int64):getvalue()
    t_data.CustomAndroid.lRobotBankStoMul = dataBuffer:readscore(int64):getvalue()
    --扑克信息
    for i=1,cmd.GAME_PLAYER do
        t_data.bOxCard[i]  = dataBuffer:readbyte()  --牛牛数据    
    end

    local t_card = {}
    for i=1,cmd.GAME_PLAYER do
        t_data.cbOxCardData[i]   =  {} 
        t_card = {}
        for j=1,cmd.MAX_COUNT do
            t_card[j] = dataBuffer:readbyte()
        end
        t_data.cbOxCardData[i]   =  t_card     --牛牛扑克
    end

    for i=1,cmd.GAME_PLAYER do
        t_data.cbHandCardData[i] = {}
        t_card = {}
        for j=1,cmd.MAX_COUNT do
            t_card[j] = dataBuffer:readbyte()
        end
        t_data.cbHandCardData[i] = t_card  --桌面扑克
    end

    --历史积分
    for i=1,cmd.GAME_PLAYER do
        t_data.lTurnScore[i]    = dataBuffer:readscore(int64):getvalue()
    end

    for i=1,cmd.GAME_PLAYER do
        t_data.lCollectScore[i] = dataBuffer:readscore(int64):getvalue()
    end

    return t_data
end

--游戏开始
function NNGameNetModel:readSubGameStart(dataBuffer)
    local int64 = Integer64.new()
    local t_data = {}
    t_data.cbPlayStatus = {}
    t_data.cbCardData = {}

    t_data.wBankerUser = dataBuffer:readword()  --庄家用户
    for i=1,cmd.GAME_PLAYER do 
        t_data.cbPlayStatus[i] = dataBuffer:readbyte() --用户状态
    end

    local t_l = {}
    for i=1,cmd.GAME_PLAYER do 
        t_l = {}
        t_data.cbCardData[i] = {}
        for j=1,cmd.MAX_COUNT do
            t_l[j] = dataBuffer:readbyte()
        end
        t_data.cbCardData[i] = t_l    --用户状态
    end

    t_data.lCellScore = dataBuffer:readscore(int64):getvalue()    --游戏底分
    return t_data
end
--用户摊牌
function NNGameNetModel:readSubOpenCard(dataBuffer)
    local t_data = {}
    t_data.wPlayerID	= dataBuffer:readword() --摊牌用户
	t_data.bOpen = dataBuffer:readbyte()	--摊牌标志

    return t_data
end

--用户强退
function NNGameNetModel:readSubPlayerExit(dataBuffer)
    local wPlayerID	= dataBuffer:readword()
    return wPlayerID
end

--游戏结束
function NNGameNetModel:readSubGameEnd(dataBuffer)
    local ilen = dataBuffer:getlen()
    print(ilen)
    local int64 = Integer64.new()
    local t_data = {}
    t_data.lGameTax = {}
    t_data.lGameScore = {}
    t_data.cbCardData = {}
    for i=1,cmd.GAME_PLAYER do 
        t_data.lGameTax[i] = dataBuffer:readscore(int64):getvalue() --游戏税收
    end

    for i=1,cmd.GAME_PLAYER do 
        t_data.lGameScore[i] = dataBuffer:readscore(int64):getvalue() --游戏得分
    end

    local t_d = {}
    for i=1,cmd.GAME_PLAYER do 
        t_data.cbCardData[i] = {}
        t_d = {}
        for j=1,cmd.MAX_COUNT do
            t_d[j] = dataBuffer:readbyte()
        end
        t_data.cbCardData[i] = t_d --用户扑克
    end

    t_data.cbDelayOverGame = dataBuffer:readbyte()

    return t_data
end
--特殊客户端信息
function NNGameNetModel:readSubAdminStorageInfo(dataBuffer)
    local int64 = Integer64.new()
    local t_data = {}
    t_data.lRoomStorageStart = dataBuffer:readscore(int64):getvalue() --房间起始库存
    t_data.lRoomStorageCurrent = dataBuffer:readscore(int64):getvalue()
    t_data.lRoomStorageDeduct = dataBuffer:readscore(int64):getvalue()

    t_data.lMaxRoomStorage = {}
    for i=1,2 do
        t_data.lMaxRoomStorage[i] = dataBuffer:readscore(int64):getvalue()
    end

    t_data.wRoomStorageMul = {}
    for i=1,2 do
        t_data.wRoomStorageMul[i] = dataBuffer:readword()
    end

    return t_data
end
--查询用户结果
function NNGameNetModel:readSubRequestQueryResult(dataBuffer)
    -- body
    local t_data = {}
    --用户信息
    t_data.userinfo.wChairID = dataBuffer:readword()    --椅子ID
    t_data.userinfo.wTableID = dataBuffer:readword()    --桌子ID
    t_data.userinfo.dwGameID = dataBuffer:readdword()   --GAMEIDID
    t_data.userinfo.bAndroid = dataBuffer:readbool()    --机器人标识
    t_data.userinfo.szNickName = dataBuffer:readstring(cmd.SERVER_LEN)    --用户昵称
    t_data.userinfo.cbUserStatus = dataBuffer:readbyte()    --用户状态
    t_data.userinfo.cbGameStatus = dataBuffer:readbyte()    --游戏状态

	t_data.bFind = dataBuffer:readbool()    --找到标识

    return t_data
end

--用户控制
function NNGameNetModel:readSubUserControl(dataBuffer)
    local t_data = {}
    t_data.dwGameID = dataBuffer:readdword()   --GAMEIDID
    t_data.szNickName = dataBuffer:readstring(cmd.SERVER_LEN)    --用户昵称
    t_data.controlResult = dataBuffer:readbyte()    --控制结果
    t_data.controlType = dataBuffer:readbyte()    --控制类型
    t_data.cbControlCount = dataBuffer:readbyte()    --控制局数

    return t_data
end

--用户控制结果
function NNGameNetModel:readSubUserControlComplete(dataBuffer)
    local t_data = {}
    t_data.dwGameID = dataBuffer:readdword()   --GAMEIDID
    t_data.szNickName = dataBuffer:readstring(cmd.SERVER_LEN)    --用户昵称
    t_data.controlType = dataBuffer:readbyte()    --控制类型
    t_data.cbRemainControlCount = dataBuffer:readbyte()    --剩余控制局数

    return t_data
end

--操作记录
function NNGameNetModel:readSubOperationRecord(dataBuffer)
    local t_data = {}
    t_data.szRecord = {}
    for i=1,cmd.MAX_OPERATION_RECORD do
        t_data.szRecord[i] = dataBuffer:readstring(cmd.cmd.RECORD_LENGTH)
    end

    return t_data
end

function NNGameNetModel:readSubUpdateRoomInfo(dataBuffer)
    local int64 = Integer64.new()
    local t_data = {}
    t_data.currentqueryuserinfo = {}
    t_data.currentusercontrol = {}
    t_data.lRoomStorageCurrent = dataBuffer:readscore(int64):getvalue() --房间当前库存

    t_data.currentqueryuserinfo.wChairID = dataBuffer:readword()    --椅子ID
    t_data.currentqueryuserinfo.wTableID = dataBuffer:readword()    --桌子ID
    t_data.currentqueryuserinfo.dwGameID = dataBuffer:readdword()   --GAMEIDID
    t_data.currentqueryuserinfo.bAndroid = dataBuffer:readbool()    --机器人标识
    t_data.currentqueryuserinfo.szNickName = dataBuffer:readstring(cmd.SERVER_LEN)    --用户昵称
    t_data.currentqueryuserinfo.cbUserStatus = dataBuffer:readbyte()    --用户状态
    t_data.currentqueryuserinfo.cbGameStatus = dataBuffer:readbyte()    --游戏状态

    t_data.bExistControl = dataBuffer:readbool()    --查询用户存在控制标识

    t_data.currentusercontrol.control_type = dataBuffer:readbyte()      --控制类型
    t_data.currentusercontrol.cbControlCount = dataBuffer:readbyte()    --控制局数
    t_data.currentusercontrol.bCancelControl = dataBuffer:readbool()    --取消标识

    return t_data
end

return NNGameNetModel