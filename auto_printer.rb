drawings_path = "/Users/lilyszajnberg/Documents/Processing/Subway-Sizer/Subway_Local_Pics_March"

def most_recent_file(path, ext)
  files = `ls -ctq #{path}`.split("\n").select{|f| f=~ /\.#{ext}/}
  files.first
end

newest = most_recent_file(drawings_path, "jpg")

while true do
  to_print = most_recent_file(drawings_path, "jpg")
  
  if to_print != newest
    sleep 1
    puts "printing #{to_print}"
    # replace the path to the printer.app here with yours
    `open -a ~/Library/Printers/HP\\ LaserJet\\ 4200.app #{to_print}`
    newest = to_print
  end
end