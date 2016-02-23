$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$fileList = Join-Path -path $toolsDir -childpath "file-list.txt"

if (!(Test-Path -path "$fileList")) {
  Throw "Unable to find file '$fileList', cannot proceed with install"
}

$lines = Get-Content "$fileList"
foreach ($destination in $lines) {
  $originFile = "$destination" -replace '^[a-zA-Z]:/',''
  $origin = Join-Path -path "$toolsDir" -childpath "$originFile"
  if (Test-Path -path "$origin") {
    $parent = Split-Path -path "$destination" -parent
    if (!(Test-Path -path "$parent")) {
      New-Item -ItemType directory -Path "$parent"
    }
    if (Test-Path -path "$destination") {
      Write-Debug "Overwriting '$destination'"
    }
    Copy-Item -path "$origin" -destination "$destination" -Force
  } else {
    # If the item we are trying to copy over does not exist in our source directory,
    # we assume it is an empty directory and simply create one in its place. There is
    # a possibility that this will hide an error where there is actually a missing
    # file. However, this is such a slim possibity, this action was deemed safe.
    if (Test-Path -path "$destination") {
      if (Test-Path -path "$destination" -pathType container) {
        Write-Debug "Directory '$destination' already exists"
      } else {
        Throw "File '$destination' exists and is not a directory, cannot proceed with install"
      }
    } else {
      New-Item -ItemType directory -Path "$destination"
    }
  }
}
