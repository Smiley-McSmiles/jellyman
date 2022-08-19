#!/bin/bash
JELLYFINDIR=/opt/jellyfin 
FFMPEGDIR=/usr/share/ffmpeg 

$JELLYFINDIR/jellyfin/jellyfin \
 -d $JELLYFINDIR/data \
 -C $JELLYFINDIR/cache \
 -c $JELLYFINDIR/config \
 -l $JELLYFINDIR/log \
 --ffmpeg $FFMPEGDIR/ffmpeg 
