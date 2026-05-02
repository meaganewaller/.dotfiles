# Defined in /var/folders/jg/rs8mb6z91438t16wy08lj1cm0000gp/T//fish.xGHX3R/count-dupes.fish @ line 2
function count-dupes
	awk '
	systime() - tt > 3 {
		last=""
	}
	$0!=last&&n {
		print " "
	}
	$0!=last {
		print $0
		n=0
	}
	$0==last&&!n{
	  printf "Ommitting N repeats:  "
	}
	$0==last{
		i = 1
		do {
			printf "\b"
		  i *= 10
		} while (i <= n)
		n++
		printf n
	}
	{
		last=$0
		tt=systime()
	}
	' $argv;
end
