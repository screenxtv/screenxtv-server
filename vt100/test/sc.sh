printf "\x1B[2J\x1B[1;1H"
printf "\x1B[7m\x1B[4l"
e='\e'
s=\
"\na\x09b\x09c\x09d"
printf $s




printf "\e[1;24r\e[22;1H\e[4l"
sleep 1;
