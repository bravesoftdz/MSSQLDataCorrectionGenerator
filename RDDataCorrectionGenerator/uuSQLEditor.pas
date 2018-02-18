unit uuSQLEditor;
{
  Jan 2015 Code By: Daniel Campbell
}
interface

uses
   SynCompletionProposal, SynMemo, Classes, StdCtrls;

type
  //used as the original and proposed sql
  TSQL = record
     Text : String;
     Cursor : Integer;
  end;

  procedure AddToCompletionProposal(const aWord : String; aSCP : TSynCompletionProposal);
  procedure MoveSQLCursorTo(aCursorPos : Integer; ammoSQL : TSynMemo);
  procedure AddSQLKeywordsToCompletionList(const aWord : String; aSCP : TSynCompletionProposal);
  procedure GetFields(var aFieldList : TStringList; aTableName : String);
  function  GetPrimaryKey(aTableName : String) : String;
  procedure AddFieldNamesToCompletionList(const aWord : String; const aTableName : String; aSCP : TSynCompletionProposal);
  procedure AddTableNamesToCompletionList(const aWord : String; aSCP : TSynCompletionProposal);
  procedure AddFieldNamesFromTablesInSQLAndAliases(const aWord : String; ammoSQL : TSynMemo; aSCP : TSynCompletionProposal);
  function  GetWordBeforeCursor(ammoSQL : TSynMemo) : String;
  procedure SplitSQL(var aStrList : TStringList; aSQL : String; aDelimiter : Char; aStrict : Boolean);
  function  GetTableNamesFromSchema : TStringList;
  function  GetTableNames(aSQL : String; var aAliases : TStringList) : TStringList;
  function  GetIndexOfWord(lStrList : TStringList; aWord : String) : Integer;


implementation

uses
   uuGlobals, StrUtils, SysUtils;

procedure AddToCompletionProposal(const aWord : String; aSCP : TSynCompletionProposal);
begin
   if aSCP.ItemList.IndexOf(aWord) = -1 then
      aSCP.ItemList.Add(aWord);
end;

procedure MoveSQLCursorTo(aCursorPos : Integer; ammoSQL : TSynMemo);
begin
   with ammoSQL do
   begin
      SelStart := aCursorPos;//Length(mmoSQL.Text);
      //Perform(EM_LINEINDEX, Lines.Count, 0) + Length(Lines[Lines.Count - 1]) + 1;
      SelLength := 0;
      //Perform(EM_SCROLLCARET, 0, 0);
      //SetFocus;
   end;
end;

procedure AddSQLKeywordsToCompletionList(const aWord : String; aSCP : TSynCompletionProposal);
   procedure AddKeyWord(aKeyWord : String);
   begin
      if AnsiStartsStr(aWord, aKeyWord) then
         AddToCompletionProposal(UpperCase(aKeyWord), aSCP);
   end;
begin
   AddKeyWord('select');
   AddKeyWord('update');
   AddKeyWord('insert');
   AddKeyWord('delete');
   AddKeyWord('from');
   AddKeyWord('into');
   AddKeyWord('values');
   AddKeyWord('create');
   AddKeyWord('drop');
   AddKeyWord('alter');
   AddKeyWord('table');
   AddKeyWord('index');
   AddKeyWord('distinct');
   AddKeyWord('unique');
   AddKeyWord('where');
   AddKeyWord('and');
   AddKeyWord('or');
   AddKeyWord('not');
   AddKeyWord('null');
   AddKeyWord('in');
   AddKeyWord('join');
   AddKeyWord('on');   
   AddKeyWord('left');
   AddKeyWord('right');
   AddKeyWord('sum');
   AddKeyWord('min');
   AddKeyWord('max');
   AddKeyWord('avg');
   AddKeyWord('count');   
   AddKeyWord('between');
   AddKeyWord('group');
   AddKeyWord('order');
   AddKeyWord('by');
   AddKeyWord('with');
   AddKeyWord('(nolock)');
   AddKeyWord('top');
end;

procedure AddFieldNamesToCompletionList(const aWord : String; const aTableName : String; aSCP : TSynCompletionProposal);
var
   lFieldList : TStringList;
   I : Integer;
begin
   lFieldList := TStringList.Create;
   try
      GetFields(lFieldList, aTableName);
      for I := 0 to lFieldList.Count - 1 do
      begin
         if AnsiStartsStr(aWord, lFieldList[I]) then
             AddToCompletionProposal(lFieldList[I], aSCP);
      end;
   finally
      FreeAndNil(lFieldList);
   end;
end;

procedure AddTableNamesToCompletionList(const aWord : String; aSCP : TSynCompletionProposal);
var
   I : Integer;
   lTableList : TStringList;
begin
   lTableList := GetTableNamesFromSchema;
   try
      for I := 0 to lTableList.Count - 1 do
      begin
         if AnsiStartsStr(aWord, lTableList[I]) then
            AddToCompletionProposal(lTableList[I], aSCP);
      end;
   finally
      FreeAndNil(lTableList);
   end;
end;

procedure AddFieldNamesFromTablesInSQLAndAliases(const aWord : String; ammoSQL : TSynMemo; aSCP : TSynCompletionProposal);
var
   lSQLStrList, lTableNames, lAliases : TStringList;
   I, J : Integer;
   lAlias : string;
begin
   lSQLStrList := TStringList.Create;
   lAliases := TStringList.Create;
   try
      SplitSQL(lSQLStrList, Trim(ammoSQL.Text), ';', True);
      for I := 0 to lSQLStrList.Count - 1 do
      begin
         lTableNames := GetTableNames(Trim(lSQLStrList[I]), lAliases);
         try
            for J := 0 to lTableNames.Count - 1 do
            begin
               AddFieldNamesToCompletionList(aWord, lTableNames[J], aSCP);
               if lAliases[J] <> '' then
               begin
                  lAlias := lAliases[J];
                  AddToCompletionProposal(Lowercase(lAlias), aSCP);
               end;
            end;
         finally
            FreeAndNil(lTableNames);
         end;
      end;
   finally
      FreeAndNil(lSQLStrList);
      FreeAndNil(lAliases);
   end;
end;

function GetWordBeforeCursor(ammoSQL : TSynMemo) : String;
var
   lCursor, I : Integer;
   lResult : String;
begin
   lResult := '';
   lCursor := ammoSQL.SelStart;
   if (Length(ammoSQL.Text) > 0) and (ammoSQL.Text[lCursor] <> ' ') and (Trim(ammoSQL.Text[lCursor + 1]) = '') then
   begin
      for I := lCursor downto 1 do
      begin
         if Trim(ammoSQL.Text[I]) = '' then
            break
         else
            lResult := Copy(ammoSQL.Text, I, lCursor - I + 1);
      end;
   end;
   Result := lResult;
end;

procedure SplitSQL(var aStrList : TStringList; aSQL : String; aDelimiter : Char; aStrict : Boolean);
begin
   if AnsiPos(aDelimiter, aSQL) <> 0 then
   begin
      aStrList.Clear;
      aStrList.StrictDelimiter := aStrict;
      aStrList.Delimiter := aDelimiter;
      aStrList.DelimitedText := aSQL;
   end
   else
      aStrList.Add(aSQL);
end;

function GetTableNamesFromSchema : TStringList;
var
   searchResult : TSearchRec;
   tbl : string;
begin
   Result := TStringList.Create;

   if FindFirst(gSettings.SchemaDir + '\*.ddl', faAnyFile, searchResult) = 0 then
   begin
      repeat
         tbl := searchResult.Name;
         Delete(tbl, Length(tbl) - 3, 4); //Delete '.ddl'
         Result.Add(tbl);
      until FindNext(searchResult) <> 0;
      FindClose(searchResult);
   end;
end;

procedure GetFields(var aFieldList : TStringList; aTableName : String);
var
   lWords : TStringList;
   lDDLFile : TextFile;
   lLine : string;
   lInTable : Boolean;
begin
   lInTable := False;
   if not FileExists(gSettings.SchemaDir + '\' + aTableName + '.ddl') then
      Exit;
   AssignFile(lDDLFile, gSettings.SchemaDir + '\' + aTableName + '.ddl');
   Reset(lDDLFile);
   lWords := TStringList.Create;
   try
      while not EOF(lDDLFile) do
      begin
         lWords.Clear;
         ReadLn(lDDLFile, lLine);

         if (not lInTable) and AnsiContainsStr('create table ' + aTableName + ' (', Trim(lLine)) then
            lInTable := True
         else if lInTable then
         begin
            if AnsiStartsStr(')', Trim(lLine)) then
               lInTable := False
         end;

         if lInTable then
         begin
            if (AnsiPos('primary key',lLine) = 0) then
            begin
               SplitSQL(lWords, lLine, ' ', True);
               aFieldList.Add(lWords[0]);
            end;
         end;
      end;
   finally
      FreeAndNil(lWords);
      CloseFile(lDDLFile);
   end;

end;

function GetPrimaryKey(aTableName : String) : String;
var
   lWords : TStringList;
   lDDLFile : TextFile;
   lLine : string;
   lInTable : Boolean;
begin
   lInTable := False;
   Result := '';
   if not FileExists(gSettings.SchemaDir + '\' + aTableName + '.ddl') then
      Exit;
   AssignFile(lDDLFile, gSettings.SchemaDir + '\' + aTableName + '.ddl');
   Reset(lDDLFile);
   lWords := TStringList.Create;
   try
      while not EOF(lDDLFile) do
      begin
         lWords.Clear;
         ReadLn(lDDLFile, lLine);

         if (not lInTable) and AnsiContainsStr('create table ' + aTableName + ' (', Trim(lLine)) then
            lInTable := True
         else if lInTable then
         begin
            if AnsiStartsStr(')', Trim(lLine)) then
               lInTable := False
         end;

         if lInTable then
         begin
            if (AnsiPos('primary key',lLine) <> 0) then
            begin
               SplitSQL(lWords, lLine, ' ', True);
               if lWords.Count > 2 then
               begin
                  Result := lWords[2];
                  Delete(Result, 1, 1);
                  Delete(Result, Length(Result), 1);
                  break;
               end;
            end;
         end;
      end;
   finally
      FreeAndNil(lWords);
      CloseFile(lDDLFile);
   end;
end;

function GetTableNames(aSQL : String; var aAliases : TStringList) : TStringList;
var
   lWords, lAliases : TStringList;
   lIndexOfWord : Integer;
   lPossAlias : string;
begin
   Result := TStringList.Create;

   lWords := TStringList.Create;
   try
      SplitSQL(lWords, aSQL,' ', False);
      if lWords.Count > 0 then
      begin
         if (Uppercase(lWords[0]) = 'SELECT') then
         begin
            lIndexOfWord := GetIndexOfWord(lWords, 'FROM');
            if (lIndexOfWord <> -1) and (lWords.Count > (lIndexOfWord + 1)) then
            begin
               Result.Add(lWords[lIndexOfWord + 1]);
               //add possible aliases
               if Assigned(aAliases) then
               begin
                  if (lWords.Count > (lIndexOfWord + 2)) then
                  begin
                     lPossAlias := UpperCase(lWords[lIndexOfWord + 2]);
                     if (lPossAlias <> 'JOIN') and (lPossAlias <> 'WHERE') and
                        (lPossAlias <> 'GROUP') and (lPossAlias <> 'ORDER') then
                        aAliases.Add(lPossAlias)
                     else
                        aAliases.Add('');
                  end
                  else
                     aAliases.Add('');
               end;
            end;

            //find all instances of join, this only gets the first one
            lIndexOfWord := GetIndexOfWord(lWords, 'JOIN');
            if (lIndexOfWord <> -1) and (lWords.Count > (lIndexOfWord + 1)) then
            begin
               Result.Add(lWords[lIndexOfWord + 1]);
               //add possible aliases
               if Assigned(aAliases) then
               begin
                  if (lWords.Count > (lIndexOfWord + 2)) then
                  begin
                     lPossAlias := UpperCase(lWords[lIndexOfWord + 2]);
                     if (lPossAlias <> 'ON') then
                        aAliases.Add(lPossAlias)
                     else
                        aAliases.Add('');
                  end
                  else
                     aAliases.Add('');
               end;
            end;
         end
         else if (Uppercase(lWords[0]) = 'UPDATE') then
         begin
            if lWords.Count > 1 then
            begin
               Result.Add(LowerCase(lWords[1]));
               if Assigned(aAliases) then
               begin
                  if lWords.Count > 2 then
                     aAliases.Add(lWords[2])
                  else
                     aAliases.Add('');
               end;
            end;
         end
         else if (Uppercase(lWords[0]) = 'INSERT') then
         begin
            if lWords.Count > 2 then
            begin
               Result.Add(LowerCase(lWords[2]));
               if Assigned(aAliases) then
               begin
                  if lWords.Count > 3 then
                     aAliases.Add(lWords[3])
                  else
                     aAliases.Add('');
               end;
            end;
         end
         else if (Uppercase(lWords[0]) = 'DELETE') then
         begin
            if (lWords.Count > 2) and (Uppercase(lWords[2]) = 'FROM') then
            begin
               if (lWords.Count > 3) then
               begin
                  Result.Add(LowerCase(lWords[3]));
                  if Assigned(aAliases) then
                  begin
                     if lWords.Count > 4 then
                        aAliases.Add(lWords[4])
                     else
                        aAliases.Add('');
                  end;
               end;
            end
            else
            begin
               if (lWords.Count > 2) then
               begin
                  Result.Add(LowerCase(lWords[2]));
                  if Assigned(aAliases) then
                  begin
                     if lWords.Count > 3 then
                        aAliases.Add(lWords[3])
                     else
                        aAliases.Add('');
                  end;
               end;
            end;
         end;
      end;
   finally
      FreeAndNil(lWords);
   end;
end;

function GetIndexOfWord(lStrList : TStringList; aWord : String) : Integer;
var
   I : Integer;
begin
   Result := -1;
   for I := 0 to lStrList.Count - 1 do
   begin
      if Uppercase(lStrList[I]) = aWord then
         Result := I;
   end;
end;

end.
