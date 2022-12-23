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
  return drives
end

function Initialize(force)
  local drives = GetDrives()
  local disks = SKIN:GetVariable("CURRENTPATH") .. "Disks.inc"

  if tablelength(drives) == 0 then
    drives['C'] = 'Fetching disk drives failed!'
  end

  if force or UpdateNeeded(drives) then
    local file = io.open(disks, "w")
    file:write(
      "; DO NOT MODIFY THIS FILE! IT IS CREATED AUTOMATICALLY AND WILL BE OVERWRITTEN.\n"
    )
    for a in Abc() do
      if drives[a] then
        file:write(GetDriveEntry(a, drives[a]))
      end
    end
    file:close()
    SKIN:Bang('!Refresh CompactCombo')
  end
end

function UpdateNeeded(drives)
  for a in Abc() do
    local meter = SKIN:GetMeter('MeterDiskName' .. a)
    if not drives[a] and meter
      or drives[a] and not meter
      or drives[a] and meter and meter:GetOption('Text') ~= MeterText(drives[a], 1)
    then
      return true
    end
  end
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

function tablelength(T)
  local count = 0
  for _ in pairs(T) do
    count = count + 1
  end
  return count
end

function GetDriveEntry(drive, name)
  entry = [[

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
MiddleMouseUpAction=[!CommandMeasure "MeasureDisks" "Initialize(true)"]
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
Text=]]..MeterText(name).."\n"

  text = string.gsub(entry, "$d", drive)
  return text
end

function MeterText(name, newline)
  return name and name..(newline and "\n" or "#CRLF#").."%1" or ""
end
