printf "\x1B[2J\x1B[1;1H"
printf "\x1B[7m\x1B[4l"
e='\e'
s=\
"\x1B[2Haaa\nbbb\nccc\nddd\neee\nfff\nggg\nhhh\x1B[3;6r\x1B[2;2H\x1B[2M*"
printf $s




printf "\e[1;24r\e[22;1H\e[4l"
sleep 1;
