$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$fileList = Join-Path -path $toolsDir -childpath "file-list.txt"

if (!(Test-Path -path "$fileList")) {
  Throw "Unable to find file '$fileList', cannot proceed with uninstall"
}

$lines = Get-Content "$fileList"
foreach ($file in $lines) {
  if (Test-Path -path "$file") {
    # We cannot guarentee a directory is only populated with files from
    # this package, so we cannot whole-sale remove directories. We could
    # check to see if a directory is empty after we remove all the files,
    # but that would still end up with some reminantes of our skeletal
    # directory structure. It doesn't seem worth it ATM. As is, only remove
    # things that are files, and do not remove any directories.
    if (!((Get-Item "$file") -is [System.IO.DirectoryInfo])) {
      Write-Debug "Removing '$file'"
      remove-item -Path "$file" -Force
    }
  } else {
    Write-Debug "Skipping missing file '$file'"
  }
}
