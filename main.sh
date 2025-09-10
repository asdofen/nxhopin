#!/bin/bash

# In case script forcibly stopped
rm -r ./tmp 1> /dev/null

# Enter
echo -e "Script requires nmap on host.\n"
echo -e "Alert! By default path to nginx configs are set as [/etc/nginx/conf.d/*.conf], \nif your setup is different, change path in script manualy \n"
echo -e "Install nmap? If you type [n] script will be stopped; If nmap is already installed, type [Y].\n"
read -p "[Y/n] : " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt install -y nmap
        echo -e "\nnmap installed!\n"

        # grep every backend address with port from .../nginx/conf.d/*.conf
        mkdir ./tmp
        grep -E "^\s*server [a-z0-9]" /etc/nginx/conf.d/*.conf | 
                sed 's/max.*//g' |
                sed 's/^.*server//g' |
                sed 's/;//g' > ./tmp/output.txt

        # grep uniq ports
        grep ':[0-9]' ./tmp/output.txt | 
                sed 's/.*://g' | 
                sed 's/ //g' | 
                sort | 
                uniq > ./tmp/ports.txt

        ports="./tmp/ports.txt"

        # nmap ping for each port and address 
        while IFS= read -r port || [[ -n "$port" ]]; do
                grep $port ./tmp/output.txt | sed 's/:.*//g' > ./tmp/$port.txt
                echo "ping port $port"
                nmap -p "$port" -iL ./tmp/$port.txt >> ./tmp/nmap.log
                nmap -p "$port" -iL ./tmp/$port.txt |
                        grep -P '([0-9]{1,3}\.){3}[0-9]{3}|closed' |
                        grep -B 1 'closed' >> ./tmp/closed.txt
        done < "$ports"

        # Show results
        date > ./tmp/result.log
        echo -e "[0cn] Content\n# 1lu - List of uniq hosts and ports\n# 2rn - Results of nmap\n# 3nl - nmap log\n# To navigate use /[..]\n\n" >> ./tmp/result.log
        echo "[1lu] List of uniq hosts and ports specified in nginx/conf.d" >> ./tmp/result.log
        cat ./tmp/output.txt | sort | uniq >> ./tmp/result.log
        echo -e "\n[2rn] Results of nmap:" >> ./tmp/result.log
        cat ./tmp/closed.txt >> ./tmp/result.log
        echo -e "\n[3nl] nmap raw log:" >> ./tmp/result.log
        cat ./tmp/nmap.log >> ./tmp/result.log

        read -p "Script done! Press Enter to less output."
        less ./tmp/result.log
        cat ./tmp/result.log > ./nxhp.log

        # Remove ./tmp and files created by script
        rm -r ./tmp
        echo -e "Removed temporary files.\nLog saved as [./nxhp.log]"

elif [[ $REPLY =~ ^[Nn]$ ]]; then
        echo -e "\nScript stopped."

else
        echo -e "\n Wrong input."

fi
