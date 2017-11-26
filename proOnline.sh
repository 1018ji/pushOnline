#!/bin/bash

# 全局缩进
# indent='---'
indent=''

function echoError()
{
	echo -e "\033[31m$1\033[0m"
	echo -e "\033[31m$2. 程序因异常终止执行退出\033[0m"
	exit 1
}

function echoOK()
{
	echo -e "\033[32m$1\033[0m"
}

function echoInfo()
{
	echo -e "\033[36m$1\033[0m"
}

function echoEnd()
{
	echo -e "\033[33m$1\033[0m"
}

##########################################

# 校验Git
echoInfo '1. 校验系统是否安装Git'
type git >/dev/null 2>&1 || echoError ${indent}'没有安装Git环境' 2
echoOK ${indent}'校验Git正常'

# 输出当前路径
echoInfo '2. 输出当前目录'
currentPath=$(pwd)
echoOK "${indent}${currentPath}"

# 输出当前branch
echoInfo '3. 输出当前分支'
getCurrentBranch=$(git symbolic-ref HEAD 2> /dev/null) || echoError ${indent}'获取当前分支失败' 4
currentBranch=${getCurrentBranch#refs/heads/}
echoOK "${indent}${currentBranch}"

if [[ "$currentBranch" =~ master ]]; then
	echoError ${indent}'当前分支 master 无法进行上线操作' 4;
else
	echoOK ${indent}'当前分支 '${currentBranch}' 非 master 分支'
fi

# 校验当前目录是否为干净目录
echoInfo '4. 检查Branch状态'
getBranchStatus=$(git status 2> /dev/null | tail -n1) || $(git status 2> /dev/null | head -n 2 | tail -n1)
echoEnd "${indent}${getBranchStatus}"

if [[ "$getBranchStatus" =~ nothing\ to\ commit || "$getBranchStatus" =~  Your\ branch\ is\ up\-to\-date\ with ]]; then
	echoOK ${indent}'当前分支内容已提交'
elif [[ "$getBranchStatus" =~ Changes\ not\ staged || "$getBranchStatus" =~ no\ changes\ added ]]; then
	echoError ${indent}'当前分支内容未提交' 5;
elif [[ "$getBranchStatus" =~ Changes\ to\ be\ committed ]]; then
	echoError ${indent}'当前分支内容已暂存' 5;
elif [[ "$getBranchStatus" =~ Untracked\ files ]]; then
	echoError ${indent}'当前分支存在未被追踪文件' 5;
elif [[ "$getBranchStatus" =~ Your\ branch\ is\ ahead ]]; then
	echoError ${indent}'当前分支落后远程分支' 5;
else
	echoError ${indent}'当前分支状态未知' 5;
fi

# 切换到 master 分支
echoInfo '5. 切换分支为 master 分支'
git checkout master >/dev/null 2>&1
getCurrentBranch=$(git symbolic-ref HEAD 2> /dev/null) || echoError ${indent}'获取当前分支失败' 6
masterBranch=${getCurrentBranch#refs/heads/}

if [[ "$masterBranch" =~ master ]]; then
	echoOK ${indent}'当前分支 '${currentBranch}' 已切换至 master 分支'
else
	echoError ${indent}'当前分支 '${currentBranch}'未切换至 master 分支' 6;
fi

# 拉取 master 更新
echoInfo '6. 更新 master 分支'
git pull --rebase origin master || echoError ${indent}'执行 git pull --rebase origin master 失败' 7
echoOK ${indent}'执行 git pull --rebase origin master 成功'
echoOK ${indent}'当前分支 master 更新完成'

# 切换到 开发 分支
echoInfo '7. 切换分支为 '${currentBranch}' 分支'
git checkout ${currentBranch} >/dev/null 2>&1
getCurrentBranch=$(git symbolic-ref HEAD 2> /dev/null) || echoError ${indent}'获取当前分支失败' 6
devBranch=${getCurrentBranch#refs/heads/}

if [[ "$devBranch" = "$currentBranch" ]]; then
	echoOK ${indent}'当前分支 master 已切换至 '${currentBranch}' 分支'
else
	echoError ${indent}'当前分支 master 未切换至 '${currentBranch}' 分支' 8;
fi

# rebase master 至 dev 分支
echoInfo '8. 更新 rebase '${currentBranch}' 分支'
git rebase master || echoError ${indent}'执行 git rebase master 失败' 8
echoOK ${indent}'执行 git rebase master 成功'
echoOK ${indent}'当前分支 '${currentBranch}' 更新 rebase 完成'

# 切换到 master 分支
echoInfo '9. 切换分支为 master 分支'
git checkout master >/dev/null 2>&1
getCurrentBranch=$(git symbolic-ref HEAD 2> /dev/null) || echoError ${indent}'获取当前分支失败' 10
masterBranch=${getCurrentBranch#refs/heads/}

if [[ "$masterBranch" =~ master ]]; then
	echoOK ${indent}'当前分支 '${currentBranch}' 已切换至 master 分支'
else
	echoError ${indent}'当前分支 '${currentBranch}'未切换至 master 分支' 10;
fi

# merage 到 master 分支
echoInfo '11. 合并 '${currentBranch}' 分支 至 master 分支'
git merge --no-ff --no-edit ${currentBranch} || echoError ${indent}'执行 git merge --no-ff --no-edit '${currentBranch}' 失败' 12
echoOK ${indent}'执行 git merge --no-ff --no-edit '${currentBranch}' 成功'
echoOK ${indent}'分支 '${currentBranch}' 合并至 master 分支完成'

# 用户确认上线操作
read -r -p "12. 上述操作无异常执行上线操作？ [Y/n] " input

case $input in
    [yY][eE][sS]|[yY])
        echoOK ${indent}'执行上线操作 git push origin master'
		git push origin master || echoError ${indent}'执行 git push origin master 失败' 13
		echoOK ${indent}'当前分支内容已推送到远程分支'
        echoOK ${indent}'执行上线操作 pushtest'
		pushtest || echoError ${indent}'执行上线失败' 13
		echoOK ${indent}'上线 pushtest 操作完成'
		;;
    *)
	echoError ${indent}'上线操作未完成' 13
	;;
esac

# 切换至 当前开发分支
echoInfo '13. 切换分支为开发分支'
git checkout ${currentBranch} >/dev/null 2>&1
getGitBranch=$(git symbolic-ref HEAD 2> /dev/null) || echoError ${indent}'获取当前分支失败' 14
devBranch=${getGitBranch#refs/heads/}

if [[ "$currentBranch" = "$devBranch" ]]; then
	echoOK ${indent}'当前分支 master 已切换至 '${currentBranch}' 分支'
else
	echoError ${indent}'当前分支未切换至 '${currentBranch}' 分支' 14;
fi

# rebase master 分支
echoInfo '14. 当前分支 rebase master 分支'
git rebase master || echoError ${indent}'执行 git rebase master 失败' 15
echoOK ${indent}'执行 git rebase master 成功'
echoOK ${indent}'分支 master 合并至 '${currentBranch}' 分支完成'

## 完成
echoInfo '15. 已经结束了'

# 输出最近1条的上线 message
echoInfo '16. 当前分支最近 commit 说明'
echoOK '---------------------'
git --no-pager log --no-merges --pretty=oneline -5
echoOK '---------------------'

# 推出
exit 0