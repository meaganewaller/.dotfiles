function log-current-business
  set -l config_file $PWD/input/configuration.json
  set -l business_name (jq ".businessName" $config_file -r)
	echo $business_name
  ls  $PWD/output/$business_name
  ls -1 $PWD/output/$business_name/temp/log* | tail -n1 | xargs tail -n200 -F
end
