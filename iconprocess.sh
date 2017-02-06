#!/bin/bash
# /usr/libexec/PlistBuddy : PlistBuddy路径

INFO_PLIST="info.plist"
TARGET_PATH="icons"
RESSOURCE_PATH=config
RESSOURCE_TEMP=resourcetemp
RESSOURCE_TARGET=resourceTarget

# 定义空数组
iconName=()
iconTempName=()
iconSizeWidth=()
iconSizeHeight=()

iconItems=("CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles" "CFBundleIconFiles" "CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles")
# iconItems=("CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles" "CFBundleIconFiles" "CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles" "CFBundleIconFile")

for item in "${iconItems[@]}"
do
	count=0

	# 输出icon的设置项
	# count=`/usr/libexec/PlistBuddy -c "Print ${item}" ${INFO_PLIST}`

	# 利用管道，输出每个设置项的行数
	count=`/usr/libexec/PlistBuddy -c "Print ${item}" ${INFO_PLIST} | wc -l`

	# `expr argument operator argument`
	# array这个设置项会自动多了2行，需要手动减掉
	count=`expr $count - 2`

	echo " count : $count in path:$item 's icon"

	for((i=0; i<$count; i++));
	do
		# echo " count is : $count"
		# echo $i

		# 如果数量大于0
		if [ $count -gt 0 ]; then
			echo ${#iconTempName[@]}
			# 构造iconTempName数组
			# 每次取iconTempName的数量作为需要新增的那个数组对象，这样保证是新增一个
			# 内容则是取里面的内容
      		iconTempName[${#iconTempName[@]}]=`/usr/libexec/PlistBuddy -c "Print ${item}:${i}"  ${INFO_PLIST}`
		fi
	done
done


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

	# icon 有效性判断

	# 整体逻辑梳理：
	# 对上面得到的iconTempName遍历处理
	# 如果是合法的（有添加.后缀png，包括@2x这类，则直接添加到iconName这个待用数组）
	# 如果并不合法（没有添加.png，因为不确定这个icon尺寸是否有添加@2x这类型，都统统添加）

	for icon in "${iconTempName[@]}"
	do
		# shell 的字符截取功能，从右边第几个字符开始，及字符的个数 : x-y
		# http://www.jb51.net/article/56563.htm
		# 并且添加.png - @2x.png - ~ipad.png - @2x~ipad.png - @3x.png后缀
		# 之所以加上面的

		if [ ${icon:0-4} != ".png" ]; then
			tmpicon=$icon".png"
			# 如果目标icon存在相同的tmpicon，则重组一个icon输出
			# 相当于过滤一层
			if [ -f ${TARGET_PATH}/$tmpicon ]; then
				iconName[${#iconName[@]}]=$tmpicon
			fi

			# 将tmpicon覆盖，并且对没有后缀的icon开始补全 @2x.png
			tmpicon=$icon"@2x.png"
			if [ -f ${TARGET_PATH}/$tmpicon ]; then
				iconName[${#iconName[@]}]=$tmpicon
			fi

			# 将tmpicon覆盖，并且对没有后缀的icon开始补全 ~ipad.png
			tmpicon=$icon"~ipad.png"
			if [ -f ${TARGET_PATH}/$tmpicon ]; then
				iconName[${#iconName[@]}]=$tmpicon
			fi

			# 将tmpicon覆盖，并且对没有后缀的icon开始补全 @2x~ipad.png
   		 	tmpicon=$icon"@2x~ipad.png"
    		if [ -f ${TARGET_PATH}/$tmpicon ]; then
       			 iconName[${#iconName[@]}]=$tmpicon
    		fi

    		# 将tmpicon覆盖，并且对没有后缀的icon开始补全 @2x~ipad.png
   		 	tmpicon=$icon"@3x.png"
    		if [ -f ${TARGET_PATH}/$tmpicon ]; then
       			 iconName[${#iconName[@]}]=$tmpicon
    		fi
    	else
    		# 假设都是完整的png设置，不操作直接判断是否和目标的icon相同
   			 if [ -f ${targetpath}/$icon ]; then
        		iconName[${#iconName[@]}]=$icon
    		 fi
		fi
	done



for icon in "${iconName[@]}"
do
	echo $icon

	width=0
	height=0

	# width=`sips -g pixelWidth ${TARGET_PATH}/$icon | grep -e pixelWidth | cut -d ":" -f2`

	# width=`sips -g pixelWidth ${TARGET_PATH}/$icon`
	# 输出:  /Users/admin/Desktop/Shell/icon/icons/AppIcon57x57.png pixelWidth: 57

	# width=`sips -g pixelWidth ${TARGET_PATH}/$icon | grep -e pixelWidth`
	# 输出 pixelWidth: 57
	# grep 命令: 全局正则匹配 : global regular expression.


	# cut 命令 : 
	# http://blog.csdn.net/guicl0219/article/details/7241529
	# cut -d ":" -f2   指定":"为分隔符号，并且获取分隔后的域2作为目标
	# 最终输出尺寸

	width=`sips -g pixelWidth ${TARGET_PATH}/$icon | grep -e pixelWidth | cut -d ":" -f2`
	height=`sips -g pixelHeight ${TARGET_PATH}/$icon | grep -e pixelHeight | cut -d ":" -f2`

 	iconSizeWidth[${#iconSizeWidth[@]}]="$width"
  	iconSizeHeight[${#iconSizeHeight[@]}]="$height"

done




echo "-----------------------------------------------------"



# 新建一个暂存资源的文件夹 resourcetemp
# 待会会把每一个需要复制的尺寸的新icon放置在这个文件夹中
mkdir -p ${RESSOURCE_TEMP}

# 上面这个临时的文件夹收集的都是统一512尺寸的临时文件
# 需要裁剪尺寸之后重新放在另外一个临时文件中
mkdir -p ${RESSOURCE_TARGET}


# 因为 iconName 和 iconSizeWidth 这两个数组数量一样
# 并且对应的目标对象高度一致，则绑定遍历

icount=0

for width in ${iconSizeWidth[@]}
do
	icon=${iconName[$icount]}

	# 注意，这里 width 和 height 高度匹配
	height=${iconSizeHeight[$icount]}
	
	# 将目标icon 拷贝 到 所属资源区中
	# 这个时候你会发现 生成的尺寸都是512的，其实离目的就一步之遥了！
	# 只要将它尺寸规范然后替换即可！

	cp -f ${RESSOURCE_PATH}/Icon.png 		${RESSOURCE_TEMP}/$icon

	# 将它重新裁剪之后放置在两外一个临时文件夹
	sips -z $width $height ${RESSOURCE_TEMP}/$icon --out ${RESSOURCE_TARGET}/$icon

	# icount 自增一
	icount=`expr $icount + 1`
done



















