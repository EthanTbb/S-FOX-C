local cmd = {}

--[[
******
* 结构体描述
* {k = "key", t = "type", s = len, l = {}}
* k 表示字段名,对应C++结构体变量名
* t 表示字段类型,对应C++结构体变量类型
* s 针对string变量特有,描述长度
* l 针对数组特有,描述数组长度,以table形式,一维数组表示为{N},N表示数组长度,多维数组表示为{N,N},N表示数组长度
* d 针对table类型,即该字段为一个table类型
* ptr 针对数组,此时s必须为实际长度

** egg
* 取数据的时候,针对一维数组,假如有字段描述为 {k = "a", t = "byte", l = {3}}
* 则表示为 变量a为一个byte型数组,长度为3
* 取第一个值的方式为 a[1][1],第二个值a[1][2],依此类推

* 取数据的时候,针对二维数组,假如有字段描述为 {k = "a", t = "byte", l = {3,3}}
* 则表示为 变量a为一个byte型二维数组,长度都为3
* 则取第一个数组的第一个数据的方式为 a[1][1], 取第二个数组的第一个数据的方式为 a[2][1]
******
]]

--游戏版本
cmd.VERSION 					= appdf.VersionValue(6,0,3)
--游戏标识
cmd.KIND_ID						= 128
	
--游戏人数
cmd.GAME_PLAYER					= 100

--房间名长度
cmd.SERVER_LEN					= 32

--游戏记录长度
cmd.RECORD_LEN					= 5

--视图位置
cmd.MY_VIEWID					= 2

--动物索引
cmd.ANIMAL_LION							=0							--狮子
cmd.ANIMAL_PANDA						=1							--熊猫
cmd.ANIMAL_MONKEY						=2							--猴子
cmd.ANIMAL_RABBIT						=3							--兔子
cmd.ANIMAL_EAGLE						=4							--老鹰
cmd.ANIMAL_PEACOCK						=5							--孔雀
cmd.ANIMAL_PIGEON						=6							--鸽子
cmd.ANIMAL_SWALLOW						=7							--燕子
cmd.ANIMAL_SLIVER_SHARK					=8							--银鲨
cmd.ANIMAL_GOLD_SHARK					=9							--金鲨
cmd.ANIMAL_BIRD							=10							--飞禽
cmd.ANIMAL_BEAST						=11							--走兽
cmd.ANIMAL_MAX							=12

--分类信息
cmd.ANIMAL_TYPE_NULL					=0							--无
cmd.ANIMAL_TYPE_BEAST					=1							--走兽
cmd.ANIMAL_TYPE_BIRD					=2							--飞禽
cmd.ANIMAL_TYPE_GOLD					=3							--黄金
cmd.ANIMAL_TYPE_SLIVER					=4							--白银

--游戏开始
cmd.GAME_START 					= 1
--游戏进行
cmd.GAME_PLAY					= 100
--下注状态
cmd.GAME_JETTON					= 100
--游戏结束
cmd.GAME_END					= 101

--游戏倒计时
cmd.kGAMEFREE_COUNTDOWN			= 1
cmd.kGAMEPLAY_COUNTDOWN			= 2
cmd.kGAMEOVER_COUNTDOWN			= 3

---------------------------------------------------------------------------------------
--服务器命令结构

--游戏空闲
cmd.GAME_SCENE_FREE				= 0
--游戏开始
cmd.GAME_SCENE_BET			    = 100

cmd.GAME_SCENE_END			    = 101
---------------------------------------------------------------------------------------
cmd.SUB_S_GAME_FREE = 1121						        --游戏空闲
cmd.SUB_S_GAME_START = 1122	    						--游戏开始
cmd.SUB_S_GAME_END = 1123								--游戏结束
cmd.SUB_S_PLAY_BET = 1124								--用户下注
cmd.SUB_S_PLAY_BET2 = 1125								--用户下注
cmd.SUB_S_PLAY_BET_FAIL = 1126						    --用户下注失败
cmd.SUB_S_BET_CLEAR = 1127							    --清除下注
------


--配置结构
cmd.SUPERBANKERCONFIG = 
{
    --抢庄类型
    {k = "superbankerType", t = "int"},
    --vip索引
    {k = "enVipIndex", t = "int"},
    --抢庄消耗
    {k = "lSuperBankerConsume", t = "score"}
}


------





--游戏状态 free
cmd.CMD_S_StatusFree = 
{
	--剩余时间
	{k = "cbTimeLeave", t = "byte"},
	--底分
	{k = "lCellScore", t = "int"},
	--玩家分数
	{k = "lPlayScore", t = "score"},
	--库存
	--{k = "lStorageStart", t = "score"},

	--
	{k = "lAreaLimitScore", t = "score"},
	--玩家限制
	{k = "lPlayLimitScore", t = "score"},						
    
    --
    {k = "nCode", t = "int"},

    --游戏记录										
    {k = "nTurnTableRecord", t = "int", l = {20}}					

}

--游戏状态 play/jetton
cmd.CMD_S_StatusPlay = 
{

	--全局信息					
    {k = "cbTimeLeave", t = "byte"},					--剩余时间					
    {k = "lCellScore", t = "int"},					--底分
    
    --玩家分数						
    {k = "lPlayScore", t = "score"},			
    {k = "lPlayChip", t = "score"},                 	--玩家筹码
    
    --玩家积分				
    {k = "lAreaLimitScore", t = "score"},				--区域限制	
    {k = "lPlayLimitScore", t = "score"},				--玩家限制
    
    --玩家输赢 AREA_MAX						
    {k = "nAnimalMultiple", t = "int", l = {12}},         --动物倍数
    {k = "lAllBet", t = "score" , l = {12}},              --总下注
    {k = "lPlayBet", t = "score", l = {12}},				--玩家下注
    --玩家成绩
    
				
    {k = "nCode", t = "int"},				
    {k = "nTurnTableRecord", t = "int", l = {20}}					--游戏记录	
}
--游戏状态 play/jetton
cmd.CMD_S_StatusEnd = 
{

	--全局信息					
    {k = "cbTimeLeave", t = "byte"},					--剩余时间					
    {k = "lCellScore", t = "int"},					--底分
    
    --玩家分数						
    {k = "lPlayScore", t = "score"},			
    {k = "lPlayChip", t = "score"},                 	--玩家筹码
    
    --玩家积分				
    {k = "lAreaLimitScore", t = "score"},				--区域限制	
    {k = "lPlayLimitScore", t = "score"},				--玩家限制
    
    --玩家输赢 AREA_MAX						
    {k = "nAnimalMultiple", t = "int", l = {12}},         --动物倍数
    {k = "lAllBet", t = "score" , l = {12}},              --总下注
    {k = "lPlayBet", t = "score", l = {12}},				--玩家下注
    --玩家成绩
    
				
    {k = "nCode", t = "int"},				
    {k = "nTurnTableRecord", t = "int", l = {20}}					--游戏记录	
}
--游戏空闲
cmd.CMD_S_GameFree = 
{
    {k = "cbTimeLeave", t = "byte"},
	{k = "lPlayScore", t = "score"}				--玩家限制玩家分数
}

--游戏开始
cmd.CMD_S_GameStart = 
{
    {k = "cbTimeLeave", t = "byte"},
	{k = "nAnimalMultiple", t = "int",l={12}},				--动物倍数
    --
    {k = "nCode", t = "int"},
    
    --
    {k = "lUserMaxScore", t = "score"}
};
--游戏结束
cmd.CMD_S_GameEnd = 
{

    
--    {k = "cbTimeLeave", t = "byte"},
--    {k = "bTurnTwoTime", t = "bool"},				                --转2次
--    {k = "nTurnTableTarget", t = "int",l ={2}},                       --转盘目标

--    {k = "nPrizesMultiple", t = "int"} ,                             --彩金  
--    --

--    --玩家输赢
--    {k = "lPlayWin", t = "score",l = {2}},
--    --玩家彩金
--    {k = "lPlayPrizes", t = "score"},
--    --显示彩金
--     {k = "lPlayShowPrizes", t = "score"},
--    {k = "lUserWinScore", t = "score"}

  

    {k = "nPrizesMultiple", t = "score"},                           --彩金  


    --玩家彩金
    {k = "lPlayPrizes", t = "score"},
    --显示彩金

    {k = "lPlayShowPrizes", t = "score"},  
    {k = "lUserWinScore", t = "score"}, 
     --玩家输赢
    {k = "nTurnTableTarget", t = "score",l ={2}},                       --转盘目标
    {k = "lPlayWin", t = "score",l = {2}},
    {k = "cbTimeLeave", t = "byte"},
    {k = "bTurnTwoTime", t = "bool"}				                --转2次
}

--用户下注
cmd.CMD_S_PlayBet = 
{
    --用户位置
	{k = "wChairID", t = "word"},
    --筹码数量
    {k = "lBetChip", t = "score"},
    --下注动物
    {k = "nAnimalIndex", t = "int"},

    --机器标识
    {k = "cbAndroid", t = "byte"},
    --机器标识
    {k = "wAndroid2", t = "WORD"},
};
--下注失败
cmd.CMD_S_PlayBetFail =
{	
	--下注玩家
	{k = "wChairID", t = "word"},
	--下注区域
	{k = "nAnimalIndex", t = "int"},
	--下注数额
	{k = "lBetChip", t = "score"}
}

cmd.CMD_S_BetClear = 
{

    	--下注玩家
	{k = "wChairID", t = "word"},
    	--玩家清除数量
	{k = "lPlayBet", t = "score",l= {12}}
}


---------------------------------------------------------------------------------------
--客户端命令结构

--用户下注
cmd.SUB_C_PLAY_BET				= 676
cmd.SUB_C_BET_CLEAR             = 677               
---------------------------------------------------------------------------------------

--用户下注
cmd.CMD_C_PlayBet = 
{
	--筹码区域
	{k = "nAnimalIndex", t = "int"},
	--加注数目
	{k = "lBetChip", t = "score"},
    --
    {k = "lCheckCode", t = "score"},
    --{k = "cbCheckCode", t = "byte",l ={32}}
    {k = "cbCheckCode", t = "string", s = cmd.SERVER_LEN}	
}
cmd.CMD_C_BetClear = 
{

}


cmd.RES_PATH 					= 	"SharkBattle/res/"
print("********************************************************load cmd");
return cmd