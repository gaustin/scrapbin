#!/usr/bin/env ruby

# maximize_window - Maximize a Window somewhere on the desktop.
# 
# Searches through open Win32 windows for a window whose caption
# matches the argument passed to the file.
# 
# Usage:
#     ruby maximize_window.rb "Open Playlist"
require 'dl/import'
require 'dl/struct'
require "timeout"
require 'Win32API'

#caption = "Open Playlist"
caption = ARGV[0]
wndclass = ARGV[1] || ""
 
HWND_TOPMOST = -1
SWP_NOMOVE = 2
SWP_NOSIZE = 1
setWindowPos = Win32API.new('user32', 'SetWindowPos', ["P", "P", "I", "I", "I", "I", "I"], "I")
puts setWindowPos

def getWindowHandle(title, wndclass = "" )
  user32 = DL.dlopen("user32")

  enum_windows = user32['EnumWindows', 'IPL']
  get_class_name = user32['GetClassName', 'ILpI']
  get_caption_length = user32['GetWindowTextLengthA' ,'LI' ]    # format here - return value type (Long) followed by parameter types - int in this case -      see http://www.ruby-lang.org/cgi-bin/cvsweb.cgi/~checkout~/ruby/ext/dl/doc/dl.txt?
  get_caption = user32['GetWindowTextA', 'iLsL' ] 

  #if wndclass != ""
  #    len = wndclass.length + 1
  #else
  len = 32
  #end
  buff = " " * len
  classMatch = false
  
  puts("getWindowHandle - looking for: " + title.to_s )

  bContinueEnum = -1  # Windows "true" to continue enum_windows.
  found_hwnd = -1
  enum_windows_proc = DL.callback('ILL') {|hwnd,lparam|
    sleep 0.05
    r,rs = get_class_name.call(hwnd, buff, buff.size)
    # puts "Found window: " + rs[1].to_s

    if wndclass != "" then
      if /#{wndclass}/ =~ rs[1].to_s
        classMatch = true
      end
    else
      classMatch = true
    end

    if classMatch ==true
      textLength, a = get_caption_length.call(hwnd)
      captionBuffer = " " * (textLength+1)

      t ,  textCaption  = get_caption.call(hwnd, captionBuffer  , textLength+1)    
      # puts "Caption =" +  textCaption[1].to_s

      if /#{title}/ =~ textCaption[1].to_s
        puts "Found Window with correct caption (" + textCaption[1].to_s + " hwnd=" + hwnd.to_s + ")"
        found_hwnd = hwnd
        bContinueEnum = 0 # False, discontinue enum_windows
        #                        return hwnd  # NO!  Don't do a return from the callback
      end
      bContinueEnum
    else
      bContinueEnum
    end
  }
  r,rs = enum_windows.call(enum_windows_proc, 0)
  DL.remove_callback(enum_windows_proc)
  return found_hwnd
end

hwnd = getWindowHandle(caption, wndclass)
setWindowPos.call(hwnd, HWND_TOPMOST, 0,0,0,0,SWP_NOMOVE|SWP_NOSIZE) unless hwnd.zero?

