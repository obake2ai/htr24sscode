ssh -X -L 53682:127.0.0.1:53682 pi@raspberrypi07.local

sudo apt update && sudo apt upgrade -y && sudo apt install eog unclutter -y
sudo raspi-config #screen blank and VNC
curl -sSL get.pimoroni.com/hyperpixel4-legacy | bash

#マウスカーソル
echo '@unclutter -idle 0.1 -root' | sudo tee -a /etc/xdg/lxsession/LXDE/autostart

#会場のwifiを追加
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
country=JP
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
ap_scan=1

update_config=1
network={
        ssid="505329194176"
        psk=e3da584fc0ab1906325fd59c4757543b825b5796ca4a5e0536178aa94b1e2ccd
        priority=2
}
network={
        ssid="IODATA-2ca928-2G"
        psk="W999K25227413"
        priority=1
}
network={
        ssid="kishi"
        psk="Yuma287903"
        priority=0
}


#Google Driveと同期
curl https://rclone.org/install.sh | sudo bash
rclone config
#client id: 87124641484-iimu2dh8nc4dkibpu8i5nq34d38f6atu.apps.googleusercontent.com
#client secret: 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

#Desktop同期
cd ~/Desktop && mkdir pi07

nano sync_image.py
#code: sync_image.py
import os
import subprocess

os.environ['DISPLAY'] = ':0'

piname = 'pi07'

def get_newest_file(path):
    files = [f for f in os.listdir(path) if os.path.isfile(os.path.join(path, f))]
    files.sort(key=lambda x: os.path.getmtime(os.path.join(path, x)), reverse=True)
    for file in files:
        if file.lower().endswith(('.png', '.jpg', '.jpeg', '.gif', '.bmp')):
            return os.path.join(path, file)
    return None

def main():
    # Sync the specified directory
    subprocess.run(['rclone', 'sync', f'googledrive:/HATRA24SS/raspi/{piname}/', f'/home/pi/Desktop/{piname}/'])

    # Get the newest image file in the directory
    newest_file = get_newest_file(f'/home/pi/Desktop/{piname}/')

    if newest_file:
        # Use eog to display the newest image file in fullscreen
        subprocess.run(['eog', '--fullscreen', newest_file])

if __name__ == "__main__":
    main()

#edic cron
chmod +x sync_image.py

(crontab -l; echo -e "* * * * * python3 /home/pi/Desktop/sync_image.py\n* * * * * (sleep 10; python3 /home/pi/Desktop/sync_image.py)") | crontab -
