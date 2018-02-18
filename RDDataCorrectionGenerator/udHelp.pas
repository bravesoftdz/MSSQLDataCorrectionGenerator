unit udHelp;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TdHelp = class(TForm)
    mmoControlTable: TMemo;
    mmoStoredProc: TMemo;
    lblHelp: TLabel;
    lblHelp2: TLabel;
    lbl1: TLabel;
    lbl2: TLabel;
    lbl3: TLabel;
    lbl4: TLabel;
    lbl5: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  dHelp: TdHelp;

implementation

{$R *.dfm}

end.
