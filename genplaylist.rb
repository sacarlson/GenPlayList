#!/usr/bin/env ruby
#
# Author::    Scott A. Carlson  (mailto:sacarlson@ipipi.com)
# Copyright:: Copyright (c) 2012 sacarlson
# License::   Distributes under the same terms as Ruby GPL, see detailed terms in gui
# This file is gererated by ruby-glade-create-template 1.1.4.
#
# to install
# gem install ruby-mpris
# and posibly some of the other requires bellow might need to be installed if you don't already have them.
# note that this also requires that whatplayed.rb is ran with VLC to capture play activity

require 'libglade2'
require 'rubygems'
require "find"
require 'mpris'
require 'yaml'


class Genplaylist2Glade
  include GetText

  attr :glade, :config
  
  def initialize(path_or_data, root = nil, domain = nil, localedir = nil, flag = GladeXML::FILE)
    bindtextdomain(domain, localedir, nil, "UTF-8")
    @glade = GladeXML.new(path_or_data, root, domain, localedir, flag) {|handler| method(handler)}
    @config = loadconfig(configFile = "./genPlayListconfig.yml")
  end
  
  def on_updatePlaylist_clicked(widget)
    maxHours = @glade["entryFileAge"].text
    matches = @glade["entryMatches"].text
    notMatch = @glade["entryNotmatch"].text
    minHours = @glade["entryMinHours"].text
    matchCase =@glade["checkbuttoncase1"].active?
    notMatchCase = @glade["checkbuttoncase2"].active?
    neverseen = @glade["checkNeverSeen"].active?
    config = @config
    @glade["textview1"].buffer.text = genPlaylist(config, matches, notMatch, minHours, maxHours, matchCase, notMatchCase, neverseen, enableSend=true)
  end

  def on_genPreview_clicked(widget)
    maxHours = @glade["entryFileAge"].text
    matches = @glade["entryMatches"].text
    notMatch = @glade["entryNotmatch"].text
    minHours = @glade["entryMinHours"].text
    matchCase =@glade["checkbuttoncase1"].active?
    notMatchCase = @glade["checkbuttoncase2"].active?
    neverseen = @glade["checkNeverSeen"].active?
    puts "matchCase = #{matchCase}"
    config = @config
    #genPlaylist(config, match, notMatch, minHoursLastSeen, maxHoursLastSeen,matchCase=true,notMatchCase=true, enableSend=false)
    @glade["textview1"].buffer.text = genPlaylist(config, matches, notMatch, minHours, maxHours,matchCase, notMatchCase, neverseen, enableSend=false)
  end

  def on_quit_clicked(widget)
    Gtk.main_quit
  end
  
  def on_imagemenuQuit_activate(widget)
    Gtk.main_quit
    puts "on_imagemenuQuit_activate() is not implemented yet."
  end
  
  def on_cancelConfig_clicked(widget)
    window = @glade['dialogConfig']
    window.hide
    puts "on_cancelConfig_clicked() is not implemented yet."
  end

  def on_preferences_activate(widget)
    config = loadconfig(configFile = "./genPlayListconfig.yml")
    @glade['entryMediaPath'].buffer.text = config['mediaPath'].to_s
    @glade['entryMediaPathIgnore'].buffer.text = config['tempPath'].to_s
    @glade['entryPlayHistoryFile'].buffer.text = config['playHistoryFile'].to_s
    @glade['entryExt'].buffer.text = config['mediaExt'].to_s
    window = @glade['dialogConfig']
    window.show
    puts "on_preferences_activate() is not implemented yet."
  end

  def on_buttonMediaPath_clicked(widget)
    @glade['entryMediaPath'].buffer.text = filechooser()
    puts "on_buttonMediaPath_clicked() is not implemented yet."
  end

  def on_buttonTempPath_clicked(widget)
    @glade['entryMediaPathIgnore'].buffer.text = filechooser()
    puts "on_buttonTempPath_clicked() is not implemented yet."
  end

  def on_buttonHistoryFile_clicked(widget)
    @glade['entryPlayHistoryFile'].buffer.text = filechooser()
    puts "on_buttonHistoryFile_clicked() is not implemented yet."
  end

  def on_saveConfig_clicked(widget)
    config = {}   
    config['mediaPath'] = @glade['entryMediaPath'].text
    config['tempPath'] = @glade['entryMediaPathIgnore'].text 
    config['playHistoryFile'] = @glade['entryPlayHistoryFile'].text
    config['mediaExt'] = @glade['entryExt'].text
    saveconfig(config, configFile="./genPlayListconfig.yml")
    @config = config
    window = @glade['dialogConfig']
    window.hide
    puts "on_saveConfig_clicked() is not implemented yet."
  end

  def on_imagemenuAbout_activate(widget)
    window = @glade['aboutdialog1']
    window.show
    responce = window.run
    window.hide
    puts "on_imagemenuAbout_activate() is not implemented yet."
  end

   def getPlayHistory(playHistoryFile)
    historyhash = {}
    #puts "playHistoryFile = #{play_history_file}"
    File.open(playHistoryFile) do |fp|
      fp.each do |line|
        mode, minits, timestamp, filename = line.chomp.split("|")
        basename = (File.basename(filename)).strip
        historyhash[basename] = timestamp
        #puts "basename #{basename} timestamp #{timestamp}"
      end
    end
    return historyhash
  end

  def genPlaylist(config, match, notMatch, minHoursLastSeen, maxHoursLastSeen,matchCase=true,notMatchCase=true, neverseen=true, enableSend=false)
    count = 0
    if enableSend then
      mpris = MPRIS.new
    end
    historyhash = getPlayHistory(config['playHistoryFile'])
    display = ""
    Find.find(config['mediaPath']) do |file|
      #skip .. and . dirs
      next if file =~ /^\.\.?$/
      #skip it if the entry is a directory
      if test(?d, file) then next end
      # the base is just the file name less the full directory path
      base = File.basename(file).strip
      #puts "base = #{base}"
      # keep the dir as the directory that the present file is in to be used later
      dir  = File.dirname(file)
      # keep the file extention to filter out ones we don't want in our playlist
      ext = File.extname(base)
      #puts "dir = #{dir}"
      # skip unfinished torrent downloads in temp path
      if dir == config['tempPath'] then next end
      #puts "not tempPath"
      # skip if file is now type avi video
      if ext != ".avi" then next end
      #puts "is an .avi file"
      # many torrents come with samples and stuf that I don't want to bother with so filter them out
      if notMatch.length > 0  then
        if notMatchCase then        
          if base.include?(notMatch) then next end
        else
          if base.downcase.include?(notMatch.downcase) then next end
        end
      end
      #puts "is not a notMatch"
      # skip if file has no match to entered search param in argument
      #puts "match = #{match}"
      if matchCase then
        if not base.include?(match.strip) then next end
      else
        if not base.downcase.include?(match.strip) then next end
      end
      #puts "it is a match"
      # turn min max into secounds ago relitive to time now
      maxLastSeen = Time.now.to_i - (minHoursLastSeen.to_i * 60 * 60)
      minLastSeen = Time.now.to_i - (maxHoursLastSeen.to_i * 60 * 60)
      hlastseen = (Time.now.to_i - historyhash[base].to_i)/(60*60)
      #puts "hours last seen = #{hlastseen}"
      puts "base = #{base}"
      puts "historyhash[base].to_i =  #{historyhash[base].to_i}"
      if neverseen then 
        if historyhash[base.strip].to_i != 0  then next end
      else   
        if maxHoursLastSeen.to_i != 0 then
          # skip if it's been more than maxHoursLastSeen hours ago
          puts "maxHoursLastSeen not zero"
          if historyhash[base].to_i < minLastSeen then next end
        end
        if minHoursLastSeen.to_i != 0 then
          #puts "minHoursLastSeen not zero"
          # skip if we have already seen within the last minHoursLastSeen hours ago         
          if historyhash[base].to_i > maxLastSeen then next end
        end
      end
      
      puts "base = #{base}"
      puts "lastseen = #{historyhash[base].to_i}"
      #puts "maxtime = #{maxtime}"
      display = "#{display}#{base} \n"
      if historyhash[base.strip].to_i != 0 then
        #puts "seen here as not zero history"
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

  def saveconfig(config, configFile="./genPlayListconfig.yml")
    File.open(configFile, "w") do |file|
      file.write config.to_yaml
    end
  end

  def loadconfig(configFile = "./genPlayListconfig.yml")
    if File.exist?(configFile) then
      config = YAML::load_file configFile
      if config['mediaPath'].length == 0 then
        config['mediaPath'] = "./media"
      end
      if config['playHistoryFile'].length == 0 then
        config['playHisitoryFile'] = "./playHistoryFile.yml"
      end
      if config['tempPath'].length == 0 then
        config['tempPath'] = "./media/temp"
      end
      if config['mediaExt'].length == 0 then
        config['mediaExt'] = ".avi"
      end 
    else
      config = {}
      config['mediaPath'] = "./media"
      config['playHistoryFile'] = "./playHistoryFile.yml"
      config['tempPath'] = "./media/temp"
      config['mediaExt'] = ".avi"
    end   
    puts config.inspect
    return config
  end

  def filechooser()
    filename = ""
    dialog = Gtk::FileChooserDialog.new("Select File", nil,
             Gtk::FileChooser::ACTION_OPEN, nil,
             [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
             [Gtk::Stock::OPEN,   Gtk::Dialog::RESPONSE_ACCEPT] )
    filename = dialog.filename if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
    dialog.destroy
    return filename
  end

end

# Main program
if __FILE__ == $0
  # Set values as your own application. 
  PROG_PATH = "genplaylist.glade"
  PROG_NAME = "YOUR_APPLICATION_NAME"
  Genplaylist2Glade.new(PROG_PATH, nil, PROG_NAME)
  Gtk.main
end
