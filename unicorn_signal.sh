kill -USR2 `pgrep -f 'unicorn_rails master'`
sleep 1;
kill -QUIT `pgrep -f 'unicorn_rails master \(old\)'`
