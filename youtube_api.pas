{$I YOUTUBE_PLUGIN_DEFINES.INC}

unit youtube_api;

interface

uses tntclasses, superobject;

const
  {$I APIKEY.INC}
  {$IFDEF LOCALTRACE}
  LogInit : String = 'c:\log\.YouYube_Channel_plugin.txt';
  {$ENDIF}

var
  APIKey  : String = '';

function  YouTube_ConvertUserNameToChannelID(sUserName : String) : String;
function  YouTube_ConvertChannelNameToChannelID(sChannelName : String) : String;
procedure YouTube_GetChannelDetails(sChannelID : String; var sTitle,sThumbnail,sPlaylistID : String; MaxThumbnailRes : Boolean);
procedure YouTube_GetCategoryIDs(regionCode : String; uList : TTNTStringList);
function  YouTube_GetBestThumbnailURL(jSnippet : ISuperObject; MaxThumbnailRes : Boolean) : String;
function  YouTube_ISO8601toSeconds(sISO : String) : Integer;



implementation


uses classes, WinInet, misc_utils_unit, sysutils, TNTSysUtils;


function YouTube_ConvertChannelNameToChannelID(sChannelName : String) : String;
var
  sList    : TStringList;
  jBase    : ISuperObject;
  jItems   : ISuperObject;
  jEntry   : ISuperObject;
  dlStatus : String;
  dlError  : Integer;
  sJSON    : String;
  sURL     : String;
  jID      : ISuperObject;
begin
  Result   := '';
  sList    := TStringList.Create;
  dlStatus := '';
  dlError  := 0;
 // https://developers.google.com/apis-explorer/#p/youtube/v3/youtube.search.list?part=snippet&q=YouTube+for+Developers&type=channel
  sURL := 'https://www.googleapis.com/youtube/v3/search?key='+APIKEY+'&part=id&q='+sChannelName+'&type=channel';
  //sURL := 'https://www.googleapis.com/youtube/v3/search?key='+APIKEY+'&part=id,snippet&q='+sChannelName+'&type=channel';
  {$IFDEF LOCALTRACE}DebugMsgFT(LogInit,'YouTube_ConvertChannelNameToChannelID "'+sURL+'"');{$ENDIF}
  If DownloadFileToStringList(sURL,sList,dlStatus,dlError,2000) = True then
  Begin
    If sList.Count > 0 then
    Begin
      sJSON := StringReplace(sList.Text,CRLF,'',[rfReplaceAll]);
      {$IFDEF LOCALTRACE}DebugMsgFT(LogInit,'JSON Returned : '+CRLF+'---'+CRLF+sList.Text+CRLF+'---'+CRLF);{$ENDIF}
      jBase := SO(sJSON);
      If jBase <> nil then
      Begin
        jItems := jBase.O['items'];
        If jItems <> nil then
        Begin
          If jItems.AsArray.Length > 0 then
          Begin
            jEntry := jItems.AsArray.O[0];
            If jEntry <> nil then
            Begin
              ///Result := jEntry.S['id'];
              jID := jEntry.O['id'];
              If jID <> nil then
              Begin
                Result := jID.S['channelId'];
                jID.Clear(True);
                jID := nil;
              End
              {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON id object returned nil'){$ENDIF};
              jEntry.Clear(True);
              jEntry := nil;
            End
            {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON entry object returned nil'){$ENDIF};
          End;
          jItems.Clear(True);
          jItems := nil;
          //ShowMessageW(jItems.AsString);
        End
        {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON items object returned nil'){$ENDIF};
        jBase.Clear(True);
        jBase := nil;
      End
      {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON base object returned nil'){$ENDIF};
    End
    {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'Download returned no data on User Name to Channel ID translation'){$ENDIF};
  End
  {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'Download error on User Name to Channel ID translation'){$ENDIF};
  sList.Free;
end;


function YouTube_ConvertUserNameToChannelID(sUserName : String) : String;
var
  sList    : TStringList;
  jBase    : ISuperObject;
  jItems   : ISuperObject;
  jEntry   : ISuperObject;
  dlStatus : String;
  dlError  : Integer;
  sJSON    : String;
  sURL     : String;
begin
  Result   := '';
  sList    := TStringList.Create;
  dlStatus := '';
  dlError  := 0;
  sURL     := 'https://www.googleapis.com/youtube/v3/channels?key='+APIKEY+'&forUsername='+sUserName+'&part=id';
  {$IFDEF LOCALTRACE}DebugMsgFT(LogInit,'YouTube_ConvertUserNameToChannelID "'+sURL+'"');{$ENDIF}
  If DownloadFileToStringList(sURL,sList,dlStatus,dlError,2000) = True then
  Begin
    If sList.Count > 0 then
    Begin
      sJSON := StringReplace(sList.Text,CRLF,'',[rfReplaceAll]);
      {$IFDEF LOCALTRACE}DebugMsgFT(LogInit,'JSON Returned : '+CRLF+'---'+CRLF+sList.Text+CRLF+'---'+CRLF);{$ENDIF}
      jBase := SO(sJSON);
      If jBase <> nil then
      Begin
        jItems := jBase.O['items'];
        If jItems <> nil then
        Begin
          If jItems.AsArray.Length > 0 then
          Begin
            jEntry := jItems.AsArray.O[0];
            If jEntry <> nil then
            Begin
              Result := jEntry.S['id'];
              jEntry.Clear(True);
              jEntry := nil;
            End
            {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON entry object returned nil'){$ENDIF};
          End;
          jItems.Clear(True);
          jItems := nil;
          //ShowMessageW(jItems.AsString);
        End
        {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON items object returned nil'){$ENDIF};
        jBase.Clear(True);
        jBase := nil;
      End
      {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON base object returned nil'){$ENDIF};
    End
    {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'Download returned no data on User Name to Channel ID translation'){$ENDIF};
  End
  {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'Download error on User Name to Channel ID translation'){$ENDIF};
  sList.Free;
end;


{procedure YouTube_GetUploadPlaylistID(sChannelID : String; var sPlaylistID : String);
var
  sList    : TStringList;
  jBase    : ISuperObject;
begin
  // https://www.googleapis.com/youtube/v3/channels?key=[apikey]&part=contentDetails&id=[ChannelID]
  //https://www.googleapis.com/youtube/v3/channels?key=AIzaSyBieQxSpir6Y2-iYPokdu90UxqM_skzZFo&part=snippet&id=UCEK3tT7DcfWGWJpNEDBdWog
  //https://www.googleapis.com/youtube/v3/channels?key=AIzaSyBieQxSpir6Y2-iYPokdu90UxqM_skzZFo&part=snippet,contentDetails&id=UCEK3tT7DcfWGWJpNEDBdWog
  sList := TStringList.Create;
  If DownloadFileToStringList('https://www.googleapis.com/youtube/v3/channels?key='+APIKEY+'&part=snippet&id='+sChannelID,sList,dlStatus,dlError,2000) = True then
  Begin

  End;
  sList.Free;
end;}


procedure YouTube_GetChannelDetails(sChannelID : String; var sTitle,sThumbnail,sPlaylistID : String; MaxThumbnailRes : Boolean);
var
  sList      : TStringList;
  jBase      : ISuperObject;
  jItems     : ISuperObject;
  jEntry     : ISuperObject;
  jSnippet   : ISuperObject;
  jPlaylists : ISuperObject;
  dlStatus   : String;
  dlError    : Integer;
  sJSON      : String;
begin
  // test: https://www.youtube.com/channel/UCEK3tT7DcfWGWJpNEDBdWog
  // https://www.googleapis.com/youtube/v3/channels?key=AIzaSyBieQxSpir6Y2-iYPokdu90UxqM_skzZFo&part=snippet,contentDetails&id=UCEK3tT7DcfWGWJpNEDBdWog

  sTitle     := '';
  sThumbnail := '';

  sList := TStringList.Create;
  If DownloadFileToStringList('https://www.googleapis.com/youtube/v3/channels?key='+APIKEY+'&part=snippet,contentDetails&id='+sChannelID,sList,dlStatus,dlError,2000) = True then
  Begin
    If sList.Count > 0 then
    Begin
      sJSON := StringReplace(sList.Text,CRLF,'',[rfReplaceAll]);
      {$IFDEF LOCALTRACE}DebugMsgFT(LogInit,'JSON Channel Snippet : '+CRLF+'---'+CRLF+sList.Text+CRLF+'---'+CRLF);{$ENDIF}
      jBase := SO(sJSON);
      If jBase <> nil then
      Begin
        jItems := jBase.O['items'];
        If jItems <> nil then
        Begin
          If jItems.AsArray.Length > 0 then
          Begin
            jEntry := jItems.AsArray.O[0];
            If jEntry <> nil then
            Begin
              // Get Title & Thumbnail
              jSnippet := jEntry.O['snippet'];
              If jSnippet <> nil then
              Begin
                sTitle := EncodeTextTags(jSnippet.S['title'],True);
                {$IFDEF LOCALTRACE}DebugMsgFT(LogInit,'Channel Title: '+UTF8Decode(sTitle));{$ENDIF}

                sThumbnail := YouTube_GetBestThumbnailURL(jSnippet,MaxThumbnailRes);
                {$IFDEF LOCALTRACE}DebugMsgFT(LogInit,'Channel Thumbnail: '+UTF8Decode(sThumbnail));{$ENDIF}
                jSnippet.Clear(True);
                jSnippet := nil;
              End
              {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON snippet object returned nil'){$ENDIF};

              // Get upload playlist ID - problematic, doesn't return videos by publish date
              //{$IFDEF USEUPLOADPLAYLIST}
              jSnippet := jEntry.O['contentDetails'];
              If jSnippet <> nil then
              Begin
                jPlaylists := jSnippet.O['relatedPlaylists'];
                If jPlaylists <> nil then
                Begin
                  sPlaylistID := jPlaylists.S['uploads'];
                  {$IFDEF LOCALTRACE}DebugMsgFT(LogInit,'Upload playlist ID: '+sPlaylistID);{$ENDIF}
                  jPlaylists.Clear(True);
                  jPlaylists := nil;
                End
                {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON entry object returned nil for "relatedPlaylists"'){$ENDIF};
                jSnippet.Clear(True);
                jSnippet := nil;
              End
              {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON object returned nil for "contentDetails"'){$ENDIF};
              //{$ENDIF}

              jEntry.Clear(True);
              jEntry := nil;
            End
            {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON entry object returned nil'){$ENDIF};
          End;
          jItems.Clear(True);
          jItems := nil;
        End
        {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON items object returned nil for "items"'){$ENDIF};

        jBase.Clear(True);
        jBase := nil;
      End
      {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON base object returned nil'){$ENDIF};
    End
    {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'Download returned no data on User Name to Channel ID translation'){$ENDIF};
  End
  {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'Download error on Channel ID to Channel Name translation'){$ENDIF};

  sList.Free;
end;


procedure YouTube_GetCategoryIDs(regionCode : String; uList : TTNTStringList);
var
  sList    : TStringList;
  jBase    : ISuperObject;
  jItems   : ISuperObject;
  jEntry   : ISuperObject;
  jSnippet : ISuperObject;
  dlStatus : String;
  dlError  : Integer;
  sJSON    : String;
  sTitle   : String;
  cID      : Integer;
  I        : Integer;
begin
  // https://www.googleapis.com/youtube/v3/videoCategories?part=snippet&regionCode=IL&key=[key]

  sList := TStringList.Create;
  If DownloadFileToStringList('https://www.googleapis.com/youtube/v3/videoCategories?part=snippet&regionCode='+regionCode+'&key='+APIKey,sList,dlStatus,dlError,2000) = True then
  Begin
    If sList.Count > 0 then
    Begin
      sJSON := StringReplace(sList.Text,CRLF,'',[rfReplaceAll]);
      {$IFDEF LOCALTRACE}DebugMsgFT(LogInit,'JSON Category List Snippet : '+CRLF+'---'+CRLF+sList.Text+CRLF+'---'+CRLF);{$ENDIF}
      jBase := SO(sJSON);
      If jBase <> nil then
      Begin
        jItems := jBase.O['items'];
        If jItems <> nil then
        Begin
          If jItems.AsArray.Length > 0 then For I := 0 to jItems.AsArray.Length-1 do
          Begin
            jEntry := jItems.AsArray.O[I];
            If jEntry <> nil then
            Begin
              cID      := StrToIntDef(jEntry.S['id'],-1);
              jSnippet := jEntry.O['snippet'];
              If jSnippet <> nil then
              Begin
                sTitle := jSnippet.S['title'];

                If (sTitle <> '') and (cID > -1) then uList.AddObject(UTF8StringToWideString(sTitle),TObject(cID));

                jSnippet.Clear(True);
                jSnippet := nil;
              End
              {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON snippet object returned nil'){$ENDIF};
              jEntry.Clear(True);
              jEntry := nil;
            End
            {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON entry object returned nil'){$ENDIF};
          End;
          jItems.Clear(True);
          jItems := nil;
        End
        {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON items object returned nil'){$ENDIF};
        jBase.Clear(True);
        jBase := nil;
      End
      {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON base object returned nil'){$ENDIF};
    End
    {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'Download returned no data on GetCategoyIDs'){$ENDIF};
  End
  {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'Download error on GetCategoyIDs'){$ENDIF};

  sList.Free;


end;


function YouTube_GetBestThumbnailURL(jSnippet : ISuperObject; MaxThumbnailRes : Boolean) : String;
var
  jThumb      : ISuperObject;
  jThumbRez   : ISuperObject;
begin
  Result := '';

  jThumbRez := jSnippet.O['thumbnails'];
  If jThumbRez <> nil then
  Begin
    If MaxThumbnailRes = True then jThumb := jThumbRez.O['maxres'] else jThumb := nil;
    If jThumb = nil then jThumb := jThumbRez.O['standard'];
    If jThumb = nil then jThumb := jThumbRez.O['high'];
    If jThumb = nil then jThumb := jThumbRez.O['medium'];
    If jThumb = nil then jThumb := jThumbRez.O['default'];

    If jThumb <> nil then
    Begin
      Result := jThumb.S['url'];
      jThumb.Clear(True);
      jThumb := nil;
    End
    {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON thumb object returned nil'){$ENDIF};
    jThumbRez.Clear(True);
    jThumbRez := nil;
  End
  {$IFDEF LOCALTRACE}Else DebugMsgFT(LogInit,'JSON thumb resolution object returned nil'){$ENDIF};
end;


function YouTube_ISO8601toSeconds(sISO : String) : Integer;
var
  I     : Integer;
  sLen  : Integer;
  iHour : Integer;
  iMin  : Integer;
  iSec  : Integer;
  S     : String;
begin
  iHour := 0;
  iMin  := 0;
  iSec  := 0;

  S     := '';
  sLen  := Length(sISO);

  If sLen > 3 then
  Begin
    If Pos('PT',sISO) = 1 then
    Begin
      For I := 3 to sLen do
      Begin
        Case sISO[I] of
          '0'..'9' : S := S+sISO[I];
          'H'      : Begin iHour := StrToIntDef(S,0); S := ''; End;
          'M'      : Begin iMin  := StrToIntDef(S,0); S := ''; End;
          'S'      : Begin iSec  := StrToIntDef(S,0); S := ''; End;
        End;
      End;
    End;
  End;

  Result := (iHour*3600)+(iMin*60)+iSec;
end;





{
//original:
https://www.googleapis.com/youtube/v3/channels?key=[APIKEY]&part=snippet,contentDetails&id=[ChannelID]

//Here is the URL request for retrieve the "upload" playlist id from the channel_id previously mentioned:
https://www.googleapis.com/youtube/v3/channels?key=<APIKEY>&part=id,snippet,contentDetails&fields=items(contentDetails/relatedPlaylists,uploads,snippet/localized)&id=UCT2rZIAL-zNqeK1OmLLUa6g


//original:
https://www.googleapis.com/youtube/v3/playlistItems?key=[APIKey]&playlistId=[PlaylistID]&part=snippet,id&order=date&type=video&maxResults=25

//Once retrieved the uploads value (as specified in previous lines), now it's time to use the "playlistItems" API for build the following URL:
https://www.googleapis.com/youtube/v3/playlistItems?key=<APIKEY>&playlistId=[PlaylistID]&part=snippet,contentDetails&fields=items(contentDetails(videoId,videoPublishedAt),snippet/title,status)&maxResults=25

https://www.googleapis.com/youtube/v3/playlistItems?key=AIzaSyBieQxSpir6Y2-iYPokdu90UxqM_skzZFo&playlistId=UU1yBKRuGpC1tSM73A0ZjYjQ&part=snippet,contentDetails&fields=items(contentDetails(videoId,videoPublishedAt),snippet/title,status)&maxResults=25

}

end.
