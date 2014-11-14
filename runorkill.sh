#!/bin/bash

term=$1

pid=$(xdotool search --class $term  getwindowpid)  
kill -TERM $pid || ($term > /dev/null 2>&1 &) 
