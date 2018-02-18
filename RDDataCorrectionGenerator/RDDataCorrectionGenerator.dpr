program RDDataCorrectionGenerator;

uses
  Forms,
  udRDDataCorrectionGenerator in 'udRDDataCorrectionGenerator.pas' {dRDDataCorrectionGenerator},
  Visio_TLB in 'Visio_TLB.pas',
  uuGlobals in 'uuGlobals.pas',
  uuSQLEditor in 'uuSQLEditor.pas',
  udSettings in 'udSettings.pas' {dSettings},
  ufDBEDatabase in 'Library\ufDBEDatabase.pas',
  ufDBEQuery in 'Library\ufDBEQuery.pas',
  ufISQLDatabase in 'Library\ufISQLDatabase.pas',
  ufISQLQuery in 'Library\ufISQLQuery.pas',
  udHelp in 'udHelp.pas' {dHelp};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TdRDDataCorrectionGenerator, dRDDataCorrectionGenerator);
  Application.CreateForm(TdHelp, dHelp);
  Application.Run;
end.
