const
  gridSize = 15;
  gridsToMake = 50;
  emptyCell = '_';
  attemptsToFitWords = 500;

type
  Word = record
    text: string;
    row: integer;
    column: integer;
    vertical: boolean;
  end;

  CrosswordPuzzle = record
    grid: array of array of char;
  end;

var
  words: array of string = ('программа', 'кроссворд', 'слово', 'генератор', 'вертикаль', 'горизонталь',
                            'паскаль','тест','оценка','экзамен','работа','учеба','студсовет','проверка',
                            'алгоритмы','университет','преподаватель','гений','ручка','карандаш','стол',
                            'стакан','толстовка','мерч','пары','перемена','столовка','крокодил','бегемот','лев');
  usedWords: array of string;
  generatedGrids: set of string;
  goodStartingLetters: set of char;
  slots: integer;
  gridDiv: array of array of char;

function WordToString(word: Word): string;
begin
  WordToString := word.text + ' (' + IntToStr(word.row) + ', ' + IntToStr(word.column) + ')';
end;

function CrosswordPuzzleToString(puzzle: CrosswordPuzzle): string;
var
  row, column: integer;
  temp:string;
begin
  temp := '';
  for row := 0 to gridSize-1 do
  begin
    for column := 0 to gridSize-1 do
    begin
      temp := temp + puzzle.grid[row][column] + ' ';
    end;
    CrosswordPuzzleToString := temp + #13#10;
  end;
end;

function IsValidPosition(row, column: integer): boolean;
begin
  IsValidPosition := (row >= 0) and (row < gridSize) and (column >= 0) and (column < gridSize);
end;

function IsLetter(row, column: integer; grid: CrosswordPuzzle): boolean;
begin
  IsLetter := grid.grid[row][column] <> emptyCell;
end;

function IsInterference(row, column, nextRow, nextColumn: integer; grid: CrosswordPuzzle): boolean;
begin
  IsInterference := IsValidPosition(row, column) and
                    IsValidPosition(nextRow, nextColumn) and
                    IsLetter(row, column, grid) and
                    IsLetter(nextRow, nextColumn, grid);
end;

function IsEmptyCell(row, column: integer; grid: CrosswordPuzzle): boolean;
begin
  IsEmptyCell := not IsLetter(row, column, grid);
end;

function OverwritingVerticalWord(row, column: integer; grid: CrosswordPuzzle): boolean;
begin
  OverwritingVerticalWord := IsValidPosition(row - 1, column) and
                             IsLetter(row, column, grid) and
                             IsLetter(row - 1, column, grid);
end;

function DoesCharacterExist(row, column: integer; grid: CrosswordPuzzle): boolean;
begin
  DoesCharacterExist := IsValidPosition(row, column) and IsLetter(row, column, grid);
end;

function OverwritingHorizontalWord(row, column: integer; grid: CrosswordPuzzle): boolean;
begin
  OverwritingHorizontalWord := IsValidPosition(row, column - 1) and
                               IsLetter(row, column, grid) and
                               IsLetter(row, column - 1, grid);
end;

function EndOfWord(word: Word; row, column: integer): boolean;
begin
  if (word.vertical) then
  begin
    EndOfWord := (word.row + Length(word.text) - 1) = row;
  end
  else
  begin
    EndOfWord := (word.column + Length(word.text) - 1) = column;
  end;
end;

function InvadingTerritory(word: Word; row, column: integer; grid: CrosswordPuzzle): boolean;
var
  invading, empty, weHaveNeighbors: boolean;
begin
  invading := false;
  empty := IsEmptyCell(row, column, grid);
  if (word.vertical) then
  begin
    weHaveNeighbors := (DoesCharacterExist(row, column - 1, grid) or
                        DoesCharacterExist(row, column + 1, grid)) or
                       (EndOfWord(word, row, column) and DoesCharacterExist(row + 1, column, grid));
    invading := empty and weHaveNeighbors;
  end
  else
  begin
    weHaveNeighbors := (DoesCharacterExist(row - 1, column, grid) or
                        DoesCharacterExist(row + 1, column, grid)) or
                       (EndOfWord(word, row, column) and DoesCharacterExist(row, column + 1, grid));
    invading := empty and weHaveNeighbors;
  end;
  InvadingTerritory := invading;
end;

function PlacementLegal(word1: Word; row, column: integer; grid: CrosswordPuzzle): boolean;
var 
  temp:boolean;
begin
  temp := false;
  if (word1.vertical) then
  begin
    temp := IsInterference(row, column + 1, row + 1, column, grid) or
                      IsInterference(row, column - 1, row + 1, column, grid) or
                      OverwritingVerticalWord(row, column, grid) or
                      InvadingTerritory(word1, row, column, grid);
  end
  else
  begin
    temp := IsInterference(row + 1, column, row, column + 1, grid) or
                      IsInterference(row - 1, column, row, column + 1, grid) or
                      OverwritingHorizontalWord(row, column, grid) or
                      InvadingTerritory(word1, row, column, grid);
  end;
  PlacementLegal := not temp;
end;

function FitsOnGrid(word: Word): boolean;
begin
  if (word.vertical) then
  begin
    FitsOnGrid := (word.row + Length(word.text)) <= gridSize;
  end
  else
  begin
    FitsOnGrid := (word.column + Length(word.text)) <= gridSize;
  end;
end;

function CanBePlaced(word: Word; grid: CrosswordPuzzle): boolean;
var
  index, currentRow, currentColumn: integer;
  b:boolean;
begin
  //writeln('CanBePlaced');
  b := true;
  if (IsValidPosition(word.row, word.column) and FitsOnGrid(word)) then
  begin
    index := 1;
    while (index <= Length(word.text)) do
    begin
      if (word.vertical) then
      begin
        currentRow := word.row + index - 1;
        currentColumn := word.column;
      end
      else
      begin
        currentRow := word.row;
        currentColumn := word.column + index - 1;
      end;
      if ((word.text[index] = grid.grid[currentRow, currentColumn]) or (emptyCell = grid.grid[currentRow, currentColumn]) and PlacementLegal(word, word.row, word.column, grid)) then
      begin
        // 
      end
      else
      begin
        b := false;
        Break;
      end;
      index := index + 1;
    end;
  end
  else
  begin
    b := false;
  end;
  CanBePlaced := b;
end;

procedure PushUsedWords(text: string);
var
  i: integer;
begin
  SetLength(usedWords, Length(usedWords)+1);
  usedWords[Length(usedWords)-1] := text;
  for i := 1 to Length(text) do
  begin
    goodStartingLetters := goodStartingLetters + [text[i]];
  end;
end;

function GetIntersections(grid: CrosswordPuzzle): integer;
var
  row, column,temp: integer;
begin
  //writeln('GetIntersections');
  temp := 0;
  for row := 0 to gridSize-1 do
  begin
    for column := 0 to gridSize-1 do
    begin
      if (IsLetter(row, column, grid)) then
      begin
        if (IsValidPosition(row - 1, column) and
            IsValidPosition(row + 1, column) and
            IsValidPosition(row, column - 1) and
            IsValidPosition(row, column + 1) and
            IsLetter(row - 1, column, grid) and
            IsLetter(row + 1, column, grid) and
            IsLetter(row, column - 1, grid) and
            IsLetter(row, column + 1, grid)) then
        begin
          temp := temp + 1;
        end;
      end;
    end;
  end;
  GetIntersections:=temp;
end;

procedure AddWord(word1: Word; var grid: CrosswordPuzzle);
var
  terIndex, row, column: integer;
begin
  //writeln('AddWord');
  for terIndex := 1 to Length(word1.text) do
  begin
    row := word1.row;
    column := word1.column;
    if (word1.vertical) then
    begin
      row := row + terIndex - 1;
    end
    else
    begin
      column := column + terIndex - 1;
    end;
    grid.grid[row, column] := word1.text[terIndex];
  end;
  PushUsedWords(word1.text);
end;

function Update(word1: word; grid: CrosswordPuzzle): boolean;
var
  updated: boolean;
begin
  //writeln('Update');
  updated := false;
  if canBePlaced(word1,grid) then
  begin
    AddWord(word1,grid);
    updated := true;
  end;
  Update := updated;
end;

function GetUnusedWords: array of string;
var
  unusedWords: set of string;
  unusedWords1:array of string;
  word1:string;
  i: integer;
begin
  //writeln('GetUnusedWords');//////////////////////////////////////////////////////////
  setlength(unusedWords1,0);
  for i := 0 to Length(words)-1 do
  begin
    if not (words[i] in usedWords) then
    begin
      Include(unusedWords,words[i]);
    end;
  end;
  foreach word1 in unusedWords do begin
    SetLength(unusedWords1, Length(unusedWords1)+1);
    unusedWords1[Length(unusedWords1)-1] := word1;
  end;
  GetUnusedWords := unusedWords1;
end;

function GetRandomWordOfSize(wordList: array of string; wordSize: integer;randomizer:integer): string;
var
  i:integer;
  storage:array of string;
begin
  //writeln('GetRandomWordOfSize');///////////////////////////////////////////////////////
  SetLength(storage, 0);
  for i:=1 to High(wordList) do begin
    if Length(wordList[i]) >= wordSize then begin
        SetLength(storage, Length(storage)+1);
        storage[Length(storage)-1] := wordList[i] ;
      end;     
  end;
  Result := storage[random(randomizer + gridsToMake) mod length(storage)];
end;

function IsGoodWord(word1: string): boolean;
var
  ter: char;
  b:boolean;
begin  
  b := False;
  //write(word1);
  if Length(word1) <= 1 then begin
    isGoodWord:=False; 
    Exit;
    end;
  foreach ter in goodStartingLetters do
  begin
    if ter = word1[1] then
    begin
      //writeln('IsGoodWord - ', word1);
      b := True;
      Break;
    end;
  end;
  isGoodWord:=b;
end;

function GetAWordToTry: string;
var
  word1: string;
  goodWord: boolean;
  i,n:integer;
  unusedWords: array of string;
begin
  //writeln('GetAWordToTry');///////////////////////////////////////////////////////
  unusedWords := GetUnusedWords;
  n:=length(unusedWords);
  if n = 0 then begin
    GetAWordToTry:=''; 
    Exit;
    end;
  
  for i:=0 to n-1 do begin
    word1 := unusedWords[i];
    if word1 = '' then begin
      GetAWordToTry := '';
      Exit;
    end;
    goodWord := IsGoodWord(word1);    
    if (not (word1 in usedWords)) and goodWord then begin
      GetAWordToTry := word1;
      Exit;
      end;
  end;
  
  GetAWordToTry := '';
  Exit;
end;

function AttemptToPlaceWordOnGrid(var grid: CrosswordPuzzle; var word1: Word): boolean;
var
  text: string;
  row, column,t: integer;
begin  
  text := GetAWordToTry;
  //writeln('AttemptToPlaceWordOnGrid - ',text);
  if text = '' then begin
    AttemptToPlaceWordOnGrid:=False;  
    exit;
    end;
  for row := 0 to gridSize-1 do
  begin
    for column := 0 to gridSize-1 do
    begin
      for t:=0 to 1 do begin
      word1.text := text;
      word1.row := row;
      word1.column := column;
      word1.vertical := t >= 0.5;
      if IsLetter(row, column, grid) then
        if Update(word1, grid) then begin
        begin
          //writeln(grid.grid);///////////////////////////////////////////////
          PushUsedWords(word1.text);
          AttemptToPlaceWordOnGrid := True;
          Exit;
      end;
      end;
      end;
    end;
  end;
  AttemptToPlaceWordOnGrid := False;
end;

function Box(object1: array of array of char):string;
var 
  s:string;
  row,column:integer;
begin
  s:='';
  for row := 0 to gridSize-1 do
  begin
    for column := 0 to gridSize-1 do
    begin
      s:=s+object1[row][column]; 
    end;
  end;
  Box:=s;
end;

function Unbox(object1:string): CrosswordPuzzle;
var
  row,column,i:integer;
  temp:array of array of char;
  tt:CrosswordPuzzle;
begin
  setlength(temp,gridSize);
  for i:=0 to gridSize-1 do
    setlength(temp[i],gridSize);
  row:=0;
  column:=0;
  for i:=1 to gridSize*gridSize do begin
    temp[row][column]:=object1[i];
    column:=column+1;
    if i mod gridsize = 0 then begin
      column:=0;
      row:=row+1;
    end;
  end;
  tt:=CrosswordPuzzle.Create();
  tt.grid:=temp;
  Unbox:=tt;
end;

procedure GenerateGrids;
var
  word1: Word;
  gridsMade, attempts, continuousFails,counter,row,column: integer;
  placed: boolean;
  grid:CrosswordPuzzle;
begin
  //writeln('GenerateGrids');
  for gridsMade := 0 to gridsToMake-1 do
  begin
    goodStartingLetters := [];
    setlength(usedWords,0);
    
    grid:=CrosswordPuzzle.Create();
    
    for row := 0 to gridSize-1 do
      begin
        for column := 0 to gridSize-1 do
        begin
          gridDiv[row][column] := emptyCell;
        end;
      end;
  
    word1.text := GetRandomWordOfSize(GetUnusedWords,5,gridsMade);
      
    {
    counter:=10;
    word1.text := GetRandomWordOfSize(GetUnusedWords,counter);
    while word1.text = '' do begin
      counter:=counter-1;
      word1.text := GetRandomWordOfSize(GetUnusedWords,counter);
    end; 
    }
    
    word1.row := gridSize div 10;
    word1.column := gridSize div 10;
    word1.vertical := False;
    
    //grid.grid:=Clone(gridDiv);
    
    grid.grid:=gridDiv;
    
    Update(word1,grid);
        
    //writeln(grid);  /////////////////////////////////
    
    for attempts := 0 to attemptsToFitWords-1 do
    begin
      placed := AttemptToPlaceWordOnGrid(grid, word1);
      //writeln(placed);///////////////////////////////////////////////////////////////////      
    end;
    Include(generatedGrids,Box(grid.grid));
  end;
end;

function CountEmpty(grid:CrosswordPuzzle):integer;
var
  c,row,column:integer;
begin
  c:=0;
  for row := 0 to gridSize-1 do
  begin
    setlength(gridDiv[row],gridSize);
    for column := 0 to gridSize-1 do
    begin
      if grid.grid[row][column] = emptyCell then
        c:=c+1;
    end;
  end;
  CountEmpty:=c;  
end;

procedure DisplayCrosswordPuzzle(grid: CrosswordPuzzle);
var
  row, column: integer;
begin
  //writeln('DisplayCrosswordPuzzle');
  for row := 0 to gridSize-1 do
  begin
    for column := 0 to gridSize-1 do
    begin
      if IsLetter(row, column, grid) then
      begin
        write(grid.grid[row, column],' ');
      end
      else
      begin
        write(emptyCell,' ');
      end;
    end;
    writeln();
  end;
end;

function GetBestGrid(grids: set of string): CrosswordPuzzle;
var
  bestGrid: CrosswordPuzzle;
  grid:string;
  grid1: CrosswordPuzzle;
  c,row,column:integer;
begin
  //writeln('GetBestGrid');
  setlength(bestGrid.grid,gridSize);    
  for row := 0 to gridSize-1 do
  begin
    setlength(bestGrid.grid[row],gridSize);
    for column := 0 to gridSize-1 do
    begin
      bestGrid.grid[row][column] := emptyCell;
    end;
  end;
  
  c:=1;
  foreach grid in grids do
    begin
      grid1:=Unbox(grid);
      writeln(c);      
      DisplayCrosswordPuzzle(grid1);/////////////////////////////////////////////////////////////////////////////
      //if GetIntersections(grid1) >= GetIntersections(bestGrid) then
      if CountEmpty(grid1) < CountEmpty(bestGrid) then
      begin
        bestGrid := grid1;
      end;
      c:=c+1;
    end;
    writeln('THE BEST (ПО ЧИСЛУ ПЕРЕСЕЧЕНИЙ)');
  GetBestGrid:= bestGrid;
end;

procedure CreateCrosswordPuzzle;
begin
  GenerateGrids;
  DisplayCrosswordPuzzle(GetBestGrid(generatedGrids));
end;

var
  row,column:integer;

begin
  Randomize;
  slots := gridSize * gridSize;
  goodStartingLetters := [];
  setlength(usedWords,0);
    
  setlength(gridDiv,gridSize);    
  for row := 0 to gridSize-1 do
  begin
    setlength(gridDiv[row],gridSize);
    for column := 0 to gridSize-1 do
    begin
      gridDiv[row][column] := emptyCell;
    end;
  end;
  
  CreateCrosswordPuzzle;

end.