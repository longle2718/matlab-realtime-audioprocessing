#!/bin/bash
# Automate getting google speech data

for i in "$@"; do
	wget ""https://ssl.gstatic.com/dictionary/static/sounds/de/0/"$i"".mp3"  
done
