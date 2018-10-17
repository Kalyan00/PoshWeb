param($fn, $path)

$global = @{
   ForisTfs = "https://tfs.company.com/STS"
   Project = "Project"
}

function TFS-RestGetWi($wi)
{
   $uri = "$($global.ForisTfs)/_apis/wit/workItems/$($wi)?api-version=3.1"
   Invoke-RestMethod -UseDefaultCredentials -uri $uri
}


function TFS-RestBuild($func, $arg)
{
   $uri = "$($global.ForisTfs)/$($global.Project)/_apis/build/$($func)?api-version=3.1"
   if($arg) { $uri = "$uri&$($arg)" }
   Invoke-RestMethod -UseDefaultCredentials -uri $uri
}

function ContentJson($content) {
   @{
      Content = $content| ConvertTo-Json -Depth 30
   }
}

if($fn -eq "ShowPaths")
{
   ContentJson @{
      BuildPath = (TFS-RestBuild "definitions").value | select -property path -unique | sort -property path
   }
}
elseif($fn -eq "Showbuilds")
{
   ContentJson @{
      path = $path
      Definitions = [array]((TFS-RestBuild "definitions").value |?{$_.path -eq $path} | sort -property name)
   }
}
else {
   return @{
      HttpStatus=404
   };
}

