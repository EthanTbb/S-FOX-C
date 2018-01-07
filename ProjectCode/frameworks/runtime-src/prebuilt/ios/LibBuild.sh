# /////////////////////////////////////////////////////////////
#	iOS_Build_SH 2016-08-25 11:23:38 by: Ravioyla
# /////////////////////////////////////////////////////////////

# /////////////////////////////////////////////////////////////
#	编译出现 Permission denied
#   输入命令 chmod 777 *.sh
#   查看编译后静态库属性 lipo -info
# /////////////////////////////////////////////////////////////

# 主体代码
echo "*********************静态库合并*********************"
Cur_Dir=$(pwd)

lipo -create -output $Cur_Dir/libmc_kernel.a $Cur_Dir/Debug-iphoneos/libmc_kernel.a $Cur_Dir/Debug-iphonesimulator/libmc_kernel.a
if [ $? -eq 1 ]
then
echo "*********************合并出错*********************"
fi

if [ $? -eq 0 ]
then
echo "*********************合并成功*********************"
lipo -info $Cur_Dir/libmc_kernel.a
fi