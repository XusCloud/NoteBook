git config --global http.https://github.com.proxy socks5://127.0.0.1:1086

git config --global --unset http.https://github.com.proxy

统计项目成员
bash复制代码git log --pretty='%aN' | sort -u | wc -l

项目总提交
bash复制代码git log --pretty='%aN' | wc -l

项目个人提交
bash复制代码git log --author="xxx" --pretty='%aN' | wc -l

项目个人提交前五
bash复制代码git log --pretty='%aN' | sort | uniq -c | sort -k1 -n -r | head -n 5

提交提交总行数
bash复制代码git log --pretty=tformat: --numstat | \
awk '{ add += $1; subs += $2; loc += $1 - $2 } END { printf "%15s %15s %15s \n", loc, add, subs }'

项目个人提交行数
bash复制代码git log --format='%aN' | sort -u -r | while read name; do printf "%25s" "$name"; \
git log --author="$name" --pretty=tformat: --numstat | \
awk '{ add += $1; subs += $2; loc += $1 - $2 } END { printf "%15s %15s %15s \n", loc, add, subs }' \
-; done
