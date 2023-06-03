Erigon Archive + Lighthouse Beacon Install
========================================================
### **Install Rust** ###

If you dont currently have rust installed, log out and back in after install.

`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`



### **Download install.sh** ###
`git clone git@github.com:vilija19/erigon_bash.git`

`cd erigon_bash`

`chmod +x install.sh`

### **Set variables** ###

In file .env set clients versions and checkpoint sync url

Is checkpoint sync less secure? No, in fact it is more secure! Checkpoint sync guards against long-range attacks that genesis sync does not. This is due to a property of Proof of Stake consensus known as Weak Subjectivity.


### **Run install.sh** ###
`./install.sh`

### **Check on the erigon service:** ###

`sudo journalctl -fu erigon`

### **Check on lighthouse beacon service** ###

`sudo journalctl -fu lighthousebeacon`

### **To make changes to erigon.service** ###

`sudo nano /etc/systemd/system/erigon.service`

### **To make changes to lighthousebeacon.service** ###

`sudo nano /etc/systemd/system/lighthousebeacon.service`

### **After making changes, dont forget to update** ###

`sudo systemctl daemon-reload`

`sudo systemctl restart erigon`

`sudo systemctl restart lighthousebeacon`


### **Allow Peers** ###

```ufw allow 30303```

```ufw allow 9000```

### **Allow RPC endpoint** ###
```ufw allow from 1.1.1.1 to any port 8545```  

Recommended block all outgoin traffic to private network.  
(Some hosting providers could block you for outgoin traffic to private network)  

`ufw deny out from any to 10.0.0.0/8
ufw deny out from any to 172.16.0.0/12
ufw deny out from any to 192.168.0.0/16
ufw deny out from any to 100.64.0.0/10
ufw deny out from any to 198.18.0.0/15
ufw deny out from any to 169.254.0.0/16`








