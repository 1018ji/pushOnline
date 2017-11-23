#!/bin/bash

# 全局缩进
indent='---'

function echoRed()
{
	echo -e "\033[31m$1\033[0m"
	echo -e "\033[31m$2. 程序因异常终止执行退出...\033[0m"
	exit 1
}

function echoGreen()
{
	echo -e "\033[32m$1\033[0m"
}

function echoPurple()
{
	echo -e "\033[36m$1\033[0m"
}

function echoBlack()
{
	echo -e "$1"
}

function echoYellow()
{
	echo -e "\033[33m$1\033[0m"
}

##########################################

# 校验Git
echoBlack '1. 校验系统是否安装Git'
type git >/dev/null 2>&1 || echoRed ${indent}'没有安装Git' 2
echoGreen ${indent}'校验Git正常'

# 输出当前路径
echoBlack '2. 输出当前目录'
currentPath=$(pwd)
echoGreen "${indent}${currentPath}"

# 输出当前branch
echoBlack '3. 输出项目Branch'
getGitBranch=$(git symbolic-ref HEAD 2> /dev/null) || echoRed ${indent}'获取当前分支失败...' 4
currentBranch=${getGitBranch#refs/heads/}
echoGreen "${indent}${currentBranch}"

if [[ "$currentBranch" =~ master ]]; then
	echoRed ${indent}'当前分支 master 无法进行上线操作' 4;
else
	echoGreen ${indent}'当前分支 '${currentBranch}' 非master分支'
fi

# 校验当前目录是否为干净目录
echoBlack '4. 检查Branch状态'
getBranchStatus=$(git status 2> /dev/null | tail -n1) || $(git status 2> /dev/null | head -n 2 | tail -n1)
echoYellow "${indent}${getBranchStatus}"

if [[ "$getBranchStatus" =~ nothing\ to\ commit || "$getBranchStatus" =~  Your\ branch\ is\ up\-to\-date\ with ]]; then
	echoGreen ${indent}'当前分支内容已提交'
elif [[ "$getBranchStatus" =~ Changes\ not\ staged || "$getBranchStatus" =~ no\ changes\ added ]]; then
	echoRed ${indent}'当前分支内容未提交' 5;
elif [[ "$getBranchStatus" =~ Changes\ to\ be\ committed ]]; then
	echoRed ${indent}'当前分支内容已暂存' 5;
elif [[ "$getBranchStatus" =~ Untracked\ files ]]; then
	echoRed ${indent}'当前分支存在未被追踪文件' 5;
elif [[ "$getBranchStatus" =~ Your\ branch\ is\ ahead ]]; then
	echoRed ${indent}'当前分支落后远程分支' 5;
else
	echoRed ${indent}'当前分支状态未知' 5;
fi

# 切换到 master 目录
echoBlack '5. 切换分支为master'
git checkout master >/dev/null 2>&1
masterBranch=$(git symbolic-ref HEAD 2> /dev/null) || echoRed ${indent}'获取当前分支失败...' 6

if [[ "$masterBranch" =~ master ]]; then
	echoGreen ${indent}'当前分支 '${currentBranch}' 已切换至 master'
else
	echoRed ${indent}'当前分支未切换至 master' 6;
fi

# 拉取 master 更新
echoBlack '6. 更新 master 分支'
# >/dev/null 2>&1
git pull --rebase origin master || echoRed ${indent}'执行 git pull --rebase origin master 失败...' 7
echoGreen ${indent}'执行 git pull --rebase origin master 成功'
echoGreen ${indent}'当前分支 master 更新完成'

# rebase 到目标分支
echoBlack '7. 更新 '${currentBranch}' 分支'
# >/dev/null 2>&1
git rebase ${currentBranch} || echoRed ${indent}'执行 git rebase '${currentBranch}' 失败...' 8
echoGreen ${indent}'执行 git rebase '${currentBranch}' 成功'
echoGreen ${indent}'当前分支 '${currentBranch}' 更新完成'

# merage 到 master 分支
echoBlack '8. 合并 '${currentBranch}' 分支 至 master 分支'
git merge --no-ff ${currentBranch} || echoRed ${indent}'执行 git merge --no-ff '${currentBranch}' 失败...' 9
echoGreen ${indent}'执行 git merge --no-ff '${currentBranch}' 成功'
echoGreen ${indent}'分支 '${currentBranch}' 合并至 master 完成'

# 用户确认上线操作
read -r -p "9. 上述操作无异常执行上线操作？ [Y/n] " input

case $input in
    [yY][eE][sS]|[yY])
        echoGreen ${indent}'执行上线操作 pushtest'
		pushtest || echoRed ${indent}'执行上线失败' 10
		echoGreen ${indent}'上线操作完成。'
		;;
    *)
	echoRed ${indent}'不上线，退出...'
	echoGreen ${indent}'上线操作未完成。'
	;;
esac

# 切换至 当前开发分支
echoBlack '10.切换分支为开发分支'
git checkout ${currentBranch} >/dev/null 2>&1
getGitBranch=$(git symbolic-ref HEAD 2> /dev/null) || echoRed ${indent}'获取当前分支失败...' 6
devBranch=${getGitBranch#refs/heads/}

if [[ "$currentBranch" = "$devBranch" ]]; then
	echoGreen ${indent}'当前分支 master 已切换至 '${currentBranch}
else
	echoRed ${indent}'当前分支未切换至 '${currentBranch} 11;
fi

# rebase master 分支
echoBlack '11.当前分支 rebase master 分支'
git rebase master || echoRed ${indent}'执行 git rebase master 失败...' 12
echoGreen ${indent}'执行 git rebase master 成功'
echoGreen ${indent}'分支 master 合并至 '${currentBranch}' 完成'

## 完成
echoPurple '12.已经结束了'
exit 0