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
# this version modified to work with gtk2 instead of the depricated libglade2 with minimal changes as 
# an example of some of the changes that are needed to port ruby apps from libglade2 to gtk2
# this may be a start to creating a new ruby-glade-create-template version that supports gtk2

#require 'libglade2'
require 'gtk2'
require 'rubygems'
require "find"
require 'mpris'
require 'yaml'

class Genplaylist2Glade
  #include GetText

  attr :glade, :config
  
  def initialize(path_or_data, root = nil, domain = nil, localedir = nil)
    #bindtextdomain(domain, localedir, nil, "UTF-8")
    #@glade = GladeXML.new(path_or_data, root, domain, localedir, flag) {|handler| method(handler)}
    @glade = Gtk::Builder.new
    # had to save genplaylist.glade as a gtk type in glade editor for it to work with ruby gtk2
    #@glade.add_from_file("./genplaylistgtkb.glade")
    @glade.add_from_file(path_or_data)

    @config = loadconfig(configFile = "./genPlayListconfig.yml")

    @listview = @glade["listview"]
    ["File Name", "Files Age hours", "Hours Last Seen", "File Size MB"].each_with_index { |name, i|
      column = Gtk::TreeViewColumn.new(name, Gtk::CellRendererText.new, :text => i)
      column.set_resizable(true)
      column.set_sort_column_id(i)
      @listview.append_column(column)
    }
    @store = Gtk::ListStore.new(String, Integer, Integer, Integer,String)
    @listview.model = @store

    # signal switches bellow added to make work with gtk2 instead of libglade2
    # attempted to make minimal changes to see what is required to change

    @glade['window_main'].signal_connect("destroy") do
      #Gtk.main_quit
      on_window_main_destroy(nil)
    end

    #@glade['listview_row'].signal_connect("activate") do
      #won't work yet, don't know how to get arg0 and arg1
      #on_listview_row_activated(nil, arg0, arg1)
      #puts "listview_row.activate"
    #end

    @glade['updatePlaylist'].signal_connect("clicked") do
      on_updatePlaylist_clicked(nil)
    end
    
    @glade['genPreview'].signal_connect("clicked") do
      on_genPreview_clicked(nil)
    end 

    @glade['quit'].signal_connect("clicked") do
      on_quit_clicked(nil)
    end

    @glade['imagemenuQuit'].signal_connect("activate") do
      on_imagemenuQuit_activate(nil)
    end

    @glade['cancelConfig'].signal_connect("clicked") do
      on_cancelConfig_clicked(nil)
    end

    @glade['preferences'].signal_connect("activate") do
      on_preferences_activate(nil)
    end

    @glade['buttonMediaPath'].signal_connect("clicked") do
       on_buttonMediaPath_clicked(nil)
    end

    @glade['buttonTempPath'].signal_connect("clicked") do
      on_buttonTempPath_clicked(nil)
    end

    @glade['buttonHistoryFile'].signal_connect("clicked") do
      on_buttonHistoryFile_clicked(nil)
    end

    @glade['saveConfig'].signal_connect("clicked") do
      on_saveConfig_clicked(nil)
    end

    @glade['imagemenuAbout'].signal_connect("activate") do
      on_imagemenuAbout_activate(nil)
    end
  end
# end changes I hope********************************

  def on_window_main_destroy(widget)
    puts "on_window_main_destroy() "
    Gtk.main_quit
  end

  #  double click on preview listed file will send to VLC play list
  def on_listview_row_activated(widget, arg0, arg1)
    #this method not working after a sort
    puts "on_listview_row_activated() #{arg0.indices[0]} }"
    filenamefull = ""
    row = 0
    @store.each{ |model,path,iter| 
      if row == arg0.indices[0] then
        filenamefull = iter[4]
        break
      end
      row = row + 1    
    }
    puts filenamefull
    mpris = MPRIS.new
    mpris.tracklist.add_track(filenamefull, false )
  end
  
  def on_updatePlaylist_clicked(widget)
    result = genPlaylist( enableSend=true )
  end

  def on_genPreview_clicked(widget)   
     result = genPlaylist( enableSend=false )
  end

  def on_quit_clicked(widget)
    Gtk.main_quit
  end
  
  def on_imagemenuQuit_activate(widget)
    Gtk.main_quit
    puts "on_imagemenuQuit_activate() ."
  end
  
  def on_cancelConfig_clicked(widget)
    window = @glade['dialogConfig']
    window.hide
    puts "on_cancelConfig_clicked() ."
  end

  def on_preferences_activate(widget)
    config = loadconfig(configFile = "./genPlayListconfig.yml")
    @glade['entryMediaPath'].buffer.text = config['mediaPath'].to_s
    @glade['entryMediaPathIgnore'].buffer.text = config['tempPath'].to_s
    @glade['entryPlayHistoryFile'].buffer.text = config['playHistoryFile'].to_s
    @glade['entryExt'].buffer.text = config['mediaExt'].to_s
    window = @glade['dialogConfig']
    window.show
    puts "on_preferences_activate() ."
  end

  def on_buttonMediaPath_clicked(widget)
    @glade['entryMediaPath'].buffer.text = filechooser()
    puts "on_buttonMediaPath_clicked() ."
  end

  def on_buttonTempPath_clicked(widget)
    @glade['entryMediaPathIgnore'].buffer.text = filechooser()
    puts "on_buttonTempPath_clicked()."
  end

  def on_buttonHistoryFile_clicked(widget)
    @glade['entryPlayHistoryFile'].buffer.text = filechooser()
    puts "on_buttonHistoryFile_clicked() ."
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
    puts "on_saveConfig_clicked() ."
  end

  def on_imagemenuAbout_activate(widget)
    window = @glade['aboutdialog1']
    window.show
    responce = window.run
    window.hide
    puts "on_imagemenuAbout_activate() ."
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

  def genPlaylist( enableSend=false )
    maxFileAgeHours = @glade["entryMaxFileAge"].text
    maxLastSeenHours = @glade["entryMaxLastSeen"].text
    match = @glade["entryMatches"].text
    puts "match = #{match}"
    matchCase =@glade["checkbuttoncase1"].active?
    puts "matchCase = #{matchCase}"
    notMatch = @glade["entryNotmatch"].text        
    notMatchCase = @glade["checkbuttoncase2"].active?
    neverseen = @glade["checkNeverSeen"].active?
    fileSizeMax = @glade["entryFileSizeMax"].text
    fileSizeMin = @glade["entryFileSizeMin"].text
    if enableSend then
      mpris = MPRIS.new
    end
    historyhash = getPlayHistory(@config['playHistoryFile'])
    count = 0
    @store.clear
    @filename = []
    Find.find(@config['mediaPath']) do |file|
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
      if dir == @config['tempPath'] then next end
      #puts "not tempPath"
      # skip if file is now type avi video
      if ext != @config['mediaExt'] then next end
      #puts "is an .avi file"
      # many torrents come with samples and stuf that I don't want to bother with so filter them out if you want
      if notMatch.length > 0  then
        if notMatchCase then        
          if base.include?(notMatch) then next end
        else
          if base.downcase.include?(notMatch.downcase) then next end
        end
      end
      #puts "is not a notMatch"
      #puts "match = #{match}"
      if matchCase then
        if not base.include?(match.strip) then next end
      else
        if not base.downcase.include?(match.strip) then next end
      end
      #puts "it is a match"
      # turn min max hours into secounds relitive to time now
      maxLastSeenTime = Time.now.to_i - (maxLastSeenHours.to_i * 60 * 60)
      maxFileAgeTime = Time.now.to_i - (maxFileAgeHours.to_i * 60 * 60)
      hoursLastSeen = (Time.now.to_i - historyhash[base].to_i)/(60*60)
      puts "base = #{base}"
      puts "historyhash[base].to_i =  #{historyhash[base].to_i}"
      if neverseen then 
        if historyhash[base].to_i != 0  then next end
      else   
        # nothing yet, might move maxLastSeenHours here      
      end
      if maxLastSeenHours.length != 0 then
        puts "maxLastSeenHours not zero #{maxLastSeenTime}"
        if historyhash[base].to_i == 0 then next end 
          if historyhash[base].to_i < maxLastSeenTime then next end
        #end
      end  
      if maxFileAgeHours.length != 0 then
        puts "minLastSeenHours not zero, maxLastSeenHours = #{maxLastSeenHours} mtime = #{File.stat(file).mtime.to_i} "
        if File.stat(file).mtime.to_i < maxFileAgeTime then next end        
      end 
      if fileSizeMax.length > 0 then 
        puts "fileSize.length > 0 "
        if (fileSizeMax.to_i * 1000000) < File.stat(file).size then next end
      end
      if fileSizeMin.length > 0 then 
        if (fileSizeMin.to_i * 1000000) > File.stat(file).size then next end
      end
      puts "base = #{base}"
      puts "file size = #{File.stat(file).size}"
      puts "lastseen = #{historyhash[base].to_i}"
      if historyhash[base.strip].to_i != 0 then
        #puts "seen here as not zero history"
      end
      if hoursLastSeen > 300000 then hoursLastSeen = 0 end
      fileAgeHours = (Time.now.to_i - File.stat(file).mtime.to_i)/(60*60)
      puts "fileAgeHours = #{fileAgeHours}"
      listviewApend(base,fileAgeHours,hoursLastSeen,File.stat(file).size/1000000,file)
      #puts "ext = #{ ext }"
      #puts "file #{file}" 
      if enableSend then
        # add it to the vlc playlist but don't play it yet
        mpris.tracklist.add_track( file, false )
      end
      count = count + 1
    end
    puts "count = #{count}"
    return count
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

  def listviewApend(fileName,fileAgeHours,hoursLastSeen,size,filenamefullpath = "")
    iter = @store.append
    iter[0] = fileName.to_s
    iter[1] = fileAgeHours.to_i
    iter[2] = hoursLastSeen.to_i
    iter[3] = size.to_i
    iter[4] = filenamefullpath.to_s
  end

end

# Main program
if __FILE__ == $0
  # Set values as your own application. 
  PROG_PATH = "genplaylistgtkb.glade"
  PROG_NAME = "YOUR_APPLICATION_NAME"
  Genplaylist2Glade.new(PROG_PATH, nil, PROG_NAME)
  Gtk.main
end
