function GetDrives()
  local path = SKIN:GetVariable("CURRENTPATH") .. "Disks.txt"
  local cim =
     "Get-CimInstance -ClassName CIM_LogicalDisk" ..
     " | % {$_.DeviceID +','+ $_.VolumeName +','+ $_.Size}"
  local cmd = 'powershell -WindowStyle Hidden -command "' .. cim .. '" > ' .. path
  os.execute(cmd)

  local drives = {}
  local file = io.open(path, "r")
  for l in file:lines() do
    local drive, name, size = string.match(l, "(.):,(.*),(.*)")
    if size and #size > 0 then
      drives[drive] = name
    end
  end
  file:close()

  if TableLength(drives) == 0 then
    drives['C'] = 'Fetching disk drives failed!'
  end

  return drives
end

function Initialize()
  local disks = SKIN:GetVariable("CURRENTPATH") .. "Disks.inc"
  local file = io.open(disks, "r")
  local old
  if file then
    old = file:read("*a")
    file:close()
  end
  local new = GetDisksIncText(GetDrives())

  if old ~= new then
    local file = io.open(disks, "w")
    if file then
      file:write(new)
      file:close()
      SKIN:Bang('!Refresh CompactCombo')
    end
  end
end

function GetDisksIncText(drives)
  local text =
    "; DO NOT MODIFY THIS FILE!" ..
    " IT IS CREATED AUTOMATICALLY AND WILL BE OVERWRITTEN.\n"

  for a in Abc() do
    if drives[a] then
      text = text .. GetDriveEntry(a, drives[a])
    end
  end

  return text
end

function Abc()
  local abc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  local index = 0

  return function()
    index = index + 1
    if index <= #abc then
      return abc:sub(index, index)
    end
  end
end

function TableLength(T)
  local count = 0
  for _ in pairs(T) do
    count = count + 1
  end
  return count
end

function GetDriveEntry(drive, name)
  local text = [[

;;; Drive $d

[MeasureTotalDisk$d]
Measure=FreeDiskSpace
Drive=$d:
Total=1
IgnoreRemovable=0
UpdateDivider=60

[MeasureDiskFree$d]
Measure=FreeDiskSpace
Drive=$d:
IgnoreRemovable=0
UpdateDivider=10

[MeasureDiskReadWrite$d]
Measure=Plugin
Plugin=UsageMonitor
Category=LogicalDisk
Counter="Disk Bytes/sec"
Name=$d:
AverageSize=2

[MeasureDiskReadWriteCalc$d]
Measure=Calc
Formula=MeasureDiskReadWrite$d

[MeterDiskBar$d]
Meter=Bar
MeasureName=MeasureDiskFree$d
MeterStyle=StyleBasic|StyleBar
MiddleMouseUpAction=[!CommandMeasure "MeasureDisks" "Initialize()"]
ToolTipText=Press middle mouse button to renew drive list
Flip=1

[MeterDiskText$d]
Meter=String
MeterStyle=StyleBasic|StyleBar|StyleString
Text=$d:

[MeterDiskPercent$d]
Meter=String
MeasureName=MeasureDiskFree$d
MeterStyle=StyleBasic|StyleBar|StyleString|StyleRight
AutoScale=1
Text="%1 free"

[MeterDiskDiskReadWriteBar$d]
Y=#SmallSeparator#R
Meter=Bar
MeasureName=MeasureDiskReadWrite$d
MeterStyle=StyleBasic|StyleBar

[MeterDiskDiskReadWriteText$d]
Meter=String
MeterStyle=StyleBasic|StyleBar|StyleString|StyleRight
MeasureName=MeasureDiskReadWriteCalc$d
AutoScale=1
Text=%1B/s

[MeterDiskDiskReadWriteLine$d]
Meter=Line
MeasureName=MeasureDiskReadWrite$d
MeterStyle=StyleBasic|StyleLine

[MeterDiskName$d]
Meter=String
MeterStyle=StyleBasic|StyleLine|StyleString
MeasureName=MeasureTotalDisk$d
AutoScale=2
Text=$n#CRLF#%1
]]

  text = string.gsub(text, "$d", drive)
  text = string.gsub(text, "$n", name)
  return text
end
