#!/bin/bash

# ugly fix to chrome, chrome-driver on travis -
# see more info:
# https://github.com/travis-ci/travis-ci/issues/938
# based on: https://github.com/jsdevel/webdriver-sync/blob/master/.travis.yml
sudo apt-get remove chromium-browser
sudo apt-get install libappindicator1
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
sudo apt-get install ttf-mscorefonts-installer
sudo apt-get install x-ttcidfont-conf
sudo mkfontdir
sudo apt-get install defoma libgl1-mesa-dri xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo mkdir -p /usr/share/desktop-directories
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt-get install -f
sudo dpkg -i google-chrome-stable_current_amd64.deb
export CHROME_SANDBOX=/opt/google/chrome/chrome-sandbox
sudo rm -f $CHROME_SANDBOX
sudo wget https://googledrive.com/host/0B5VlNZ_Rvdw6NTJoZDBSVy1ZdkE -O $CHROME_SANDBOX
sudo chown root:root $CHROME_SANDBOX; sudo chmod 4755 $CHROME_SANDBOX
sudo md5sum $CHROME_SANDBOX
export DISPLAY=:99.0
Xvfb :99.0 -extension RANDR > /dev/null &
sudo chmod 1777 /dev/shm
export WEBDRIVER_SYNC_ENABLE_SELENIUM_STDOUT=true
export WEBDRIVER_SYNC_ENABLE_SELENIUM_STDERR=true
# end ugly fix to chrome, chrome-driver on travis

# echo "installing browsers..."
# wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
# sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
# sudo apt-get update
# sudo apt-get install google-chrome-stable firefox
# sudo apt-get install -f
# echo "downloading chromedriver..."
wget http://chromedriver.storage.googleapis.com/2.9/chromedriver_linux64.zip
unzip -o chromedriver_linux64.zip
echo "adding execution permission to chromedriver binary file"
chmod +x chromedriver
