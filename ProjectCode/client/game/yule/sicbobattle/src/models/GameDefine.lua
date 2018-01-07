--
-- Author: zhong
-- Date: 2016-06-27 09:51:53
--
local cmd = require("game.yule.sicbobattle.src.models.CMD_Game")
local Define = Define or {};

--用户选择 enUserSelect
-- Define.kSelectDefault = -1
-- --庄赢
-- Define.kSelectMasterWin = 0
-- --闲赢
-- Define.kSelectIdleWin = 1
-- --平局
-- Define.kSelectDraw = 2

--申请列表
function Define.getEmptyApplyInfo(  )
    return
    {
        --用户信息
        m_userItem = {},
        --是否当前庄家
        m_bCurrent = false,
        --编号
        m_llIdx = 0,
        --是否超级抢庄
        m_bRob = false
    }
end

--路单
--服务器记录空table
-- function Define.getEmptyServerRecord(  )
--     return {0,0,0}
-- end

--游戏记录空table
function Define.getEmptyRecord(  )
    return 
    {
        --骰子数
        cbDiceValue = {0,0,0},
        --点数
        cbDicePoints = 0,
        --大小
        cbDiceDaxiao = "小"
    }
end

--获取空路单
-- function Define.getEmptyWallBill(  )
--     return
--     {
--         --路单一列数据 6个
--         m_pRecords = {-1,-1,-1,-1,-1,-1},
--         --路单列数据索引
--         m_cbIndex = 0,
--         --路单除去平局索引
--         m_cbIndexWithoutPing = 1,
--         --是否连胜
--         m_bWinList = false,
--         --是否跳过
--         m_bJumpIdx = false
--     }
-- end

--游戏结果定义
function Define.getEmptyGameResult( )
	return 
	{
		--分数
		m_pAreaScore = {},
		--总分
		m_llTotal = 0,
        --骰子数
        cbDiceValue = {},
        --点数
        cbDicePoints = 0,
        --大小
        cbDiceDaxiao = "小",
        --庄家成绩
        lBankerScore = 0,
        --玩家成绩
        lUserScore = 0,
        --玩家返回积分
        lUserReturnScore = 0
	}
end

--庄家信息
function Define.getEmptyBankInfo(  )
    return
    {
        wBankerUser = 0,
        lBankerScore = 0, 
        nBankerTime = 0,
        lBankerWinScore = 0
    }
end


--游戏扑克牌数据定义
function Define.getEmptyCardsResult( )
	return
	{
		m_idleCards = {},
		m_masterCards = {}
	}
end

function Define.getEmptyDispatchCard(  )
	return
	{
		m_dir = -1,
		m_cbCardData = 0
	}
end
return Define