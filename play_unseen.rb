#!/usr/bin/ruby
#
# Script to add never yet seen and/or not watched in some time video avi files to the vlc playlist
# for this to work you must have the whatplayed.rb running with vlc to track what and when each file played
# see also startvlc.sh that starts both whatplayed and vlc for you to make this work without added effort
#
# Author::    Scott A. Carlson  (mailto:sacarlson@ipipi.com)
# Copyright:: Copyright (c) 2012 sacarlson
# License::   Distributes under the same terms as Ruby
# Note:: only tested working on Ubuntu 10.04  (alpha)
# 
#mediapath is where all video files are kept, it goes recursive into all subdirs
mediaPath = "/media/a2fa7d4f-7d8e-4315-a565-1881d5e884b1/scotty"
#play_history_file is data captured with whatplayed.rb
play_history_file = "/home/sacarlson/vlc_history.txt"
#temp_parts is location of unfinished torrent downloads to be skiped
tempPath = "/media/a2fa7d4f-7d8e-4315-a565-1881d5e884b1/scotty/video/qBT/temp_parts"
# minimum number of hours since last seen to be listed, if zero then disabled
#minhourslastseen = 500
notMatch = "sample"
minHoursLastSeen = 0
maxHoursLastSeen = 0

require 'rubygems'
require "find"
require 'mpris'
require 'yaml'
#require 'pp'

#raise "Usage: play_unseen.rb <substring>" unless (ARGV.size == 1)

def saveconfig(mediaPath, play_history_file, tempPath, ext)
  config = {}
  config['mediaPath'] = mediaPath
  config['playHistoryFile'] = play_history_file
  config['tempPath'] = tempPath
  config['mediaExt'] = ext
  File.open("./genPlayListconfig.yml", "w") do |file|
    file.write config.to_yaml
  end
end

def loadconfig(filepath = "./genPlayListconfig.yml")
  settings = YAML::load_file "./genPlayListconfig.yml"
  puts settings.inspect
  return settings
end


def getPlayHistory(playHistoryFile)
  historyhash = {}
  File.open(playHistoryFile) do |fp|
    fp.each do |line|
      mode, minits, timestamp, filename = line.chomp.split("|")
      basename = (File.basename(filename)).strip
      historyhash[basename] = timestamp
    end
  end
  return historyhash
end

def genPlaylist(config, match, notMatch, minHoursLastSeen, maxHoursLastSeen, enableSend=false, enableNeverSeen=true)
  count = 0
  if enableSend then
    mpris = MPRIS.new
  end
  #config['mediaPath'] = mediaPath
  #config['playHistoryFile'] = play_history_file
  #config['tempPath'] = tempPath
  #config['mediaExt'] = ".avi"
  historyhash = getPlayHistory(config['playHistoryFile'])
  display = ""
  Find.find(config['mediaPath']) do |file|
    #skip .. and . dirs
    next if file =~ /^\.\.?$/
    #skip it if the entry is a directory
    if test(?d, file) then next end
    # the base is just the file name less the full directory path
    base = File.basename(file).strip
    # keep the dir as the directory that the present file is in to be used later
    dir  = File.dirname(file)
    # keep the file extention to filter out ones we don't want in our playlist
    ext = File.extname(base)
    #puts "dir = #{dir}"
    # skip unfinished torrent downloads in temp path
    if dir == config['tempPath'] then next end
    # skip if file is now type avi video
    if ext != config['mediaExt'] then next end
    # many torrents come with samples and stuf that I don't want to bother with so filter them out
    if base.downcase.include?(notMatch) then next end
    # skip if file has no match to entered search param in argument
    if not base.include?(match) then next end
    # turn min max into secounds ago relitive to time now
    maxLastSeen = Time.now.to_i - (minHoursLastSeen * 60 * 60)
    minLastSeen = Time.now.to_i - (maxHoursLastSeen * 60 * 60)
    #puts "maxLastSeen = #{maxLastSeen}"
    #puts "minLastSeen = #{minLastSeen}"
    #puts "lastseensec = #{(Time.now.to_i - historyhash[base].to_i)}"
    hlastseen = (Time.now.to_i - historyhash[base].to_i)/(60*60)
    #puts "hours last seen = #{hlastseen}"
    #puts "historyhash[base].to_i =  #{historyhash[base].to_i}"
    #puts "minHoursLastSeen = #{minHoursLastSeen}"
    #puts "maxHoursLastSeen = #{maxHoursLastSeen}"
    if enableNeverSeen then
      if historyhash[base.strip].to_i != 0  then next end
    else
      if maxHoursLastSeen != 0 then
        # skip if it's been more than maxHoursLastSeen hours ago
        if historyhash[base.strip].to_i < minLastSeen then next end
      end
      if minHoursLastSeen != 0 then
        # skip if we have already seen within the last minHoursLastSeen hours ago
        if historyhash[base.strip].to_i > maxLastSeen then next end
      end
    end
    puts "base = #{base}"
    puts "lastseen = #{historyhash[base].to_i}"
    #puts "maxtime = #{maxtime}"
    display = "#{display}#{base} \n"
    if historyhash[base.strip].to_i != 0 then
      puts "seen here as not zero history"
      display = "#{display}lastseen = #{historyhash[base].to_i}\n"
    end
    #puts "ext = #{ ext }"
    #puts "file #{file}"    
    if enableSend then
      # add it to the vlc playlist but don't play it yet
      mpris.tracklist.add_track( file, false )
    end
    count = count + 1
  end
  display = "#{display}\nfile count = #{count}"
  puts "count = #{count}"
  #puts display
  return display
end

if ARGV.size != 1 then 
  match = ""
else
  match = ARGV[0]
end
#match = "House"
notMatch = "sample"
# was seen within the last 20 hours ago
minHoursLastSeen = 0
#was seen last not less than 500 hours ago
maxHoursLastSeen = 0
config = loadconfig(filepath = "./genPlayListconfig.yml")
genPlaylist(config, match,notMatch, minHoursLastSeen, maxHoursLastSeen, send=false)

