#GenPlayList
Copyright:: Copyright (c) 2012 sacarlson

genplaylist.rb is a simple gui program to search for video's that you haven't seen yet and add them to your VLC play list (or most any mpris api compatible player)  It does this by analizing a playHistoryFile that is updated with another program that runs as a demon to monitor and record the play activity of the VLC player.

##License:
 GPL same as ruby

##Instalation:
to run you will need ruby 1.8 or grater also rubygems posibly a few other packages in rubygems and some system libs including:
 
>`gem install ruby-mpris`

>`apt-get install libglade2-0`

I run it on Ubuntu 10.04.  Not tested on any other platform at the time of this writing but I guess it would run on most any system that runs ruby and the VLC player.

## Configuration:
goto edit>preferences and fill in the boxes of your Media Path with the location were you keep your video files, it will search all subdirs from this location to find all video files within it.  Media Path Ignore is the path of your temp directory to be skiped if you happen to keep your temp dir within the Media Path. PlayHistoryFile location where whatplayed.rb is writing your VLC play history.  The boxes will all be filled with defaults if never configured before or no config file is found.

##Features:
* Match string to search for file names with a sub string in it (optional none).

* Not Match string to filter out files that have a sub string you don't want in the file name (optional none).

* List only files of video's that you have never played yet, as tracked with whatplayed.rb that is also included in this package.

* Filter for video's that you have watched in the last X hours.

* Filter for video's that have been modified within the last X hours. 

* Filter for max and min file sizes.

* Filter for media extensions to be accepted in search.

* Config settings for media directory, temp directory to ignore files that are not fully downloaded yet, media extension and play history file location.

* After previewing results of searches you find that you want, you can then send the list to Your VLC player or most any mpris compatible media player.

Also see some of the screen shots provided to get an idea of it's simplisity and operation.

##Manifest:
1. genplaylist.rb main gui program
2. whatplayed.rb  runs with VLC to track activity.
3. genplaylist.glade must be in same dir as main gui program when run.
4. startvlc.sh   bash script to startup whatplayed.rb and vlc to be run whenever you play video with vlc.
5. some png image files screen shots three on last count.
6. play_unseen.rb  earlier work command line program that was used in development may be deleted later.
7. readme.md  this file you are now reading.

##Why I wrote this:
  I wrote this when I found I couldn't remember the last series episodes I had watched in a now growing number of over 600 show's and movies and other avi files I would spend the first 20 or more minits just trying to start playing shows that I soon find I had already seen.  I also fall asleep watching some of them so I can use the filter to see what I had watched in the last 7 hours when I had fallen asleep and replay them.  I may later add more features if I find I need them.  It's writen in simple to edit ruby so you can add other things to it or simply modify it to your needs.  I hope at some point something like this or better will be incorporated into VLC or added with a plugin at some point maybe using this as an example.