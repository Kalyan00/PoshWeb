param($fn)

function DefaultPage() {
   @{
      ContentType = "text/html; charset=UTF-8"
      Content =
@"
   <script src="handlebars.min-latest.js"></script>
   <script src="jquery-3.3.1.min.js"></script>

   <script id="entry-template" type="text/x-handlebars-template">
      <a href="#" onclick="getData('fn=builds');">show build definitions</a> <br><br>

      {{#each MainJs}}
      <div>
         <h1>{{title}}</h1>
         <div class="body">
            {{body}}
         </div>
      </div>
      {{/each}}


      {{#if count}}
      <h1>Count={{count}}</h1
      {{/if}}

      {{#each value}}
         <a href="{{_links.web.href}}">{{name}}</a> <br>
      {{/each}}


   </script>

   <script>
   var glob = {}
   function getData(str){
      $.getJSON(document.location.pathname+"?"+str, function( data ) {
         document.getElementById("main-body").innerHTML = glob.template(data);
      });
   }


   function start(){
      //Handlebars.registerHelper('ExtractHref', function(str) {
      //  return jQuery.parseJSON(str).href;
      //});

      glob.template = Handlebars.compile(document.getElementById("entry-template").innerHTML);
      getData("fn=MainJs");
   }
   </script>

   <body onload="start();">
   <div id="main-body">smthng went wrong...</div>
"@
   }
}


$global = @{
   ForisTfs = "https://tfs.mtsit.com/STS"
}

function TFS-RestGetWi($wi)
{
   $uri = "$($global.ForisTfs)/_apis/wit/workItems/$($wi)?api-version=3.1"
   Invoke-RestMethod -UseDefaultCredentials -uri $uri
}


function TFS-RestBuild($func, $arg)
{
   $uri = "$($global.ForisTfs)/FORIS_Mobile/_apis/build/$($func)?api-version=3.1"
   if($arg) { $uri = "$uri&$($arg)" }
   Invoke-RestMethod -UseDefaultCredentials -uri $uri
}


if($fn -eq "MainJs")
{
   return  @{
      Content = @{MainJs=@(@{title= "My New Post"; body= "This is my first post2!"})} | ConvertTo-Json -Depth 3
   }
}
elseif($fn -eq "builds")
{
   return  @{
      Content = TFS-RestBuild "definitions" |%{
         $result = $_
         @{
            count = $result.count
            value = $result.value | Sort-Object -Property name -Descending
         }
         }| ConvertTo-Json -Depth 10
   }
}
else {
   return DefaultPage;
}

