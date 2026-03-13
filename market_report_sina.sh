#!/bin/bash
# 📊 A股收盘简报生成脚本（新浪财经实时数据）
# 用于获取实时行情数据

data=$(curl -s 'https://hq.sinajs.cn/list=sh000001,sz399001,sz399006,sh000688,sh000016,sz300033,sz300760,sh600276,sz000001,sz000063,sz159780,sz000969,sh600029' \
  -H 'Referer: https://finance.sina.com.cn' | iconv -f gb2312 -t utf-8)

echo "======================================================================"
echo "📊 A股收盘简报（新浪财经实时数据）"
echo "📅 日期: $(date '+%Y年%m月%d日 (%a)') 15:00:00"
echo "======================================================================"
echo ""

echo "【大盘指数】"
echo "$data" | grep 'sh000001' | awk -F'"' '{split($2,a,","); chg=a[3]-a[2]; pct=chg/a[2]*100; em=(chg>=0)?"📈":"📉"; printf "%s 上证指数: %9.2f (%+7.2f, %+5.2f%%)\n", em, a[3], chg, pct}'
echo "$data" | grep 'sz399001' | awk -F'"' '{split($2,a,","); chg=a[3]-a[2]; pct=chg/a[2]*100; em=(chg>=0)?"📈":"📉"; printf "%s 深证成指: %9.2f (%+7.2f, %+5.2f%%)\n", em, a[3], chg, pct}'
echo "$data" | grep 'sz399006' | awk -F'"' '{split($2,a,","); chg=a[3]-a[2]; pct=chg/a[2]*100; em=(chg>=0)?"📈":"📉"; printf "%s 创业板指: %9.2f (%+7.2f, %+5.2f%%)\n", em, a[3], chg, pct}'
echo "$data" | grep 'sh000688' | awk -F'"' '{split($2,a,","); chg=a[3]-a[2]; pct=chg/a[2]*100; em=(chg>=0)?"📈":"📉"; printf "%s 科创50:   %9.2f (%+7.2f, %+5.2f%%)\n", em, a[3], chg, pct}'
echo "$data" | grep 'sh000016' | awk -F'"' '{split($2,a,","); chg=a[3]-a[2]; pct=chg/a[2]*100; em=(chg>=0)?"📈":"📉"; printf "%s 上证50:   %9.2f (%+7.2f, %+5.2f%%)\n", em, a[3], chg, pct}'

echo ""
echo "【持仓股票动态】"

process_stock() {
    local code=$1 name=$2 cost=$3 shares=$4
    local price prev change pct cost_val curr_val pnl emoji trend
    
    price=$(echo "$data" | grep "$code" | awk -F'"' '{split($2,a,","); print a[3]}')
    prev=$(echo "$data" | grep "$code" | awk -F'"' '{split($2,a,","); print a[2]}')
    
    if [ -n "$price" ]; then
        change=$(echo "$price - $prev" | bc)
        pct=$(echo "scale=2; ($change / $prev) * 100" | bc)
        cost_val=$(echo "$cost * $shares" | bc)
        curr_val=$(echo "$price * $shares" | bc)
        pnl=$(echo "$curr_val - $cost_val" | bc)
        
        if [ $(echo "$pnl >= 0" | bc) -eq 1 ]; then emoji="✅"; else emoji="❌"; fi
        if [ $(echo "$change >= 0" | bc) -eq 1 ]; then trend="📈"; else trend="📉"; fi
        
        printf "%s %-10s: %8.2f (%+6.2f, %+5.2f%%) | %s %+10.0f\n" "$trend" "$name" "$price" "$change" "$pct" "$emoji" "$pnl"
    fi
}

process_stock 'sz300033' '同花顺' 316.46 900
process_stock 'sz300760' '迈瑞医疗' 245.307 400
process_stock 'sh600276' '恒瑞医药' 44.941 1000
process_stock 'sz000001' '平安银行' 18.437 2000
process_stock 'sz000063' '中兴通讯' 43.974 500
process_stock 'sz159780' '双创ETF' 1.002 10000
process_stock 'sz000969' '安泰科技' 16.440 500
process_stock 'sh600029' '南方航空' 15.677 100

echo ""
echo "【持仓汇总】"
echo "$data" | awk -F'"' 'BEGIN {
    c[1]=316.46; s[1]=900; code[1]="sz300033"
    c[2]=245.307; s[2]=400; code[2]="sz300760"
    c[3]=44.941; s[3]=1000; code[3]="sh600276"
    c[4]=18.437; s[4]=2000; code[4]="sz000001"
    c[5]=43.974; s[5]=500; code[5]="sz000063"
    c[6]=1.002; s[6]=10000; code[6]="sz159780"
    c[7]=16.440; s[7]=500; code[7]="sz000969"
    c[8]=15.677; s[8]=100; code[8]="sh600029"
}
{
    for(i=1;i<=8;i++) if($0 ~ code[i]) {split($2,a,","); tc+=c[i]*s[i]; tv+=a[3]*s[i]; dp+=(a[3]-a[2])*s[i]}
}
END {tp=tv-tc; printf "  总成本:   %14.2f\n  总市值:   %14.2f\n  今日盈亏: %+.2f (%.2f%%)\n  累计盈亏: %+.2f (%.2f%%)\n", tc, tv, dp, dp/tv*100, tp, tp/tc*100}'

echo ""
echo "======================================================================"
echo "💡 数据来源: 新浪财经实时行情 | 生成时间: $(date '+%H:%M:%S')"
echo "======================================================================"
