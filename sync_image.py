import os
import subprocess
import time
import threading
import sys

os.environ['DISPLAY'] = ':0'

# コマンドライン引数からpinameを取得
if len(sys.argv) != 2:
    print("Usage: python script.py <piname>")
    sys.exit(1)

piname = sys.argv[1]
stop_display = threading.Event()
last_mtime = None

def get_newest_file(path):
    global last_mtime
    files = [f for f in os.listdir(path) if os.path.isfile(os.path.join(path, f))]
    files.sort(key=lambda x: os.path.getmtime(os.path.join(path, x)), reverse=True)
    for file in files:
        if file.lower().endswith(('.png', '.jpg', '.jpeg', '.gif', '.bmp')):
            new_mtime = os.path.getmtime(os.path.join(path, file))
            if new_mtime != last_mtime:
                last_mtime = new_mtime
                return os.path.join(path, file)
    return None

def display_image(image_path):
    global stop_display
    proc = subprocess.Popen(['eog', '--fullscreen', image_path])

    while not stop_display.wait(1):
        pass

    proc.terminate()

def check_for_new_images(path):
    global stop_display
    while not stop_display.is_set():
        newest_file = get_newest_file(path)
        if newest_file:
            stop_display.set()

def main():
    while True:
        subprocess.run(['rclone', 'sync', f'googledrive:/HATRA24SS/raspi/{piname}/', f'/home/pi/Desktop/{piname}/'])

        image_path = f'/home/pi/Desktop/{piname}/'
        newest_file = get_newest_file(image_path)

        if newest_file:
            global stop_display
            stop_display = threading.Event()

            display_thread = threading.Thread(target=display_image, args=(newest_file,))
            display_thread.start()

            check_thread = threading.Thread(target=check_for_new_images, args=(image_path,))
            check_thread.start()

            check_thread.join(180)
            stop_display.set()
            display_thread.join()

        # フォールバック画像のパスを設定
        bg_image_path_gif = '/home/pi/Desktop/{piname}/hatra24ss_bg.gif'
        bg_image_path_png = '/home/pi/Desktop/{piname}/hatra24ss_bg.png'

        # gifが存在するかどうかをチェックし、存在しない場合はpngを使用
        if os.path.isfile(bg_image_path_gif):
            display_image(bg_image_path_gif)
        elif os.path.isfile(bg_image_path_png):
            display_image(bg_image_path_png)
        else:
            print("Background image not found.")
            break  # 背景画像がない場合、ループを終了

if __name__ == "__main__":
    main()
