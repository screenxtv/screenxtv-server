pid=`ps aux|grep \[^]]rails|sed 's/ \+/ /g'|cut -d' ' -f2`
kill -KILL $pid
