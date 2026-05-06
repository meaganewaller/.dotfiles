#!/usr/bin/fish
function to-gif
	argparse --name "to-gif" 'f/file=' 'r/rate=' 'd/delay=' -- $argv
	set -l file $_flag_file
	set -l rate $_flag_rate
	if test -z $rate
		set rate 15
	end
	set -l delay $_flag_delay
	if test -z $delay
		set delay 0
	end
	ffmpeg -i $file -r $rate -vcodec ppm -f image2pipe - | convert -loop 0 -delay $delay -layers optimize - (dirname $file)/(basename $file).gif
end









































