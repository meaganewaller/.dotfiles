function cert --description "Show SSL certificate info for a domain"
    if test (count $argv) -eq 0
        echo "Usage: cert <domain>"
        return 1
    end

    set domain $argv[1]

    set cert_info (echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -noout -issuer -subject -dates)

    for line in $cert_info
        set key_value (string split "=" $line -m 1)
        if test (count $key_value) -eq 2
            printf "%s%-10s%s %s\n" (set_color blue) $key_value[1] (set_color normal) $key_value[2]
        else
            echo $line
        end
    end
end
