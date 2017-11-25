# pushOnline
上线脚本

# 使用方法

上传 github 时我已修改文件执行权限，如果权限不够请给予 proOnline.sh 脚本 u+x 或者 a+x 权限

1. clone项目到本地
2. 软件一个你喜欢的名字到 proOnline.sh 例如：ln -s /Users/Carl/Tools/pushOnline/proOnline.sh /usr/local/bin/in
3. 在开发分支使用 in 命令，上线。当然你也可以将 in 换成你喜欢的任何标记

# 待续
1. 跳过 merge 要求输入合并信息的界面 使用 --no-edit 参数跳过编辑界面 2017-11-25实现
2. 推送钉钉最近一条的 commit 上线信息
3. 尾部显示最近五条 commit 信息 使用 git --no-pager log 跳过编辑界面 2017-11-25实现

# 示例
![示例](http://oz8myse7t.bkt.clouddn.com/github/2017/11/push.png)
