#!/usr/bin/ruby
#
# Script to display and save history of what files have been played and when on vlc or other mpris player
#
# Author::    Scott A. Carlson  (mailto:sacarlson@ipipi.com)
# Copyright:: Copyright (c) 2012 sacarlson
# License::   Distributes under the same terms as Ruby
#
# to run you will need to install
# gem install ruby-mpris
# gem install ruby-dbus
# you must run vlc --control dbus & before you run this so what I did is write a bash script to run both for me
# see startvlc.sh to do that.
# when you exit vlc this program will error out and exit to stop itself, thats normal, not perfect but it works
# change filename bellow to disired location for your history file
filename = "/home/sacarlson/vlc_history.txt"
require 'rubygems'
require 'mpris'
#require 'pp'
puts "start time #{Time.now.strftime("%m/%d/%Y at %I:%M%p")}"
mpris = MPRIS.new
laststatus = 2
lastplayed = ""
starttime = Time.now.to_i
while true
  status = mpris.player.status
  #puts "status = #{status}"
  if status == 0 then
    meta = mpris.player.metadata
    if meta["location"] != lastplayed then
      lastplayed = meta["location"]
      #if status == 0 then playstop = "playing" end
      #if status == 2 then playstop = "stoped" end
      #if status == 1 then playstop = "paused" end
      t = Time.now
      #puts t.strftime("%m/%d/%Y at %I:%M%p")
      timestamp = Time.now.to_i
      playminits = (Time.now.to_i - starttime)/60
      #puts "location = #{meta["location"]}"
      line = "playing|#{playminits}|#{timestamp}|#{meta["location"]} \n"
      puts line
      File.open(filename, 'a') {|f| f.write(line) }
      laststatus = status
    end
  end
  sleep 5 
end
