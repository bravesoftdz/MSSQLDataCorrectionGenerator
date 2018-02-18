object dHelp: TdHelp
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Help'
  ClientHeight = 919
  ClientWidth = 1096
  Color = 15400938
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object lblHelp: TLabel
    Left = 16
    Top = 16
    Width = 696
    Height = 19
    Caption = 
      '1. To begin, fill out the call/task number, then any remaining p' +
      'arameters at the top of the screen. '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lblHelp2: TLabel
    Left = 16
    Top = 40
    Width = 538
    Height = 19
    Caption = 
      '2. Go to the Select Into tab, choose a table and press Update/In' +
      'sert/Delete. '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbl1: TLabel
    Left = 16
    Top = 64
    Width = 774
    Height = 19
    Caption = 
      '3. As a minimum, you will probably need to write a where clause ' +
      'and insert_set_sql(for updates and inserts).'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbl2: TLabel
    Left = 16
    Top = 88
    Width = 1050
    Height = 19
    Caption = 
      '4. To correct/replicate multiple tables, choose a different tabl' +
      'e and press Update/Insert/Delete again. This will add more recor' +
      'ds to the control table.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbl3: TLabel
    Left = 16
    Top = 112
    Width = 604
    Height = 19
    Caption = 
      '5. Go to the Verification tab, choose a table, press Example, th' +
      'en modify accordingly.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbl4: TLabel
    Left = 16
    Top = 136
    Width = 499
    Height = 19
    Caption = 
      '6. Go to the Result tab to find your script. Save it and press F' +
      'lowchart.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lbl5: TLabel
    Left = 16
    Top = 160
    Width = 1012
    Height = 19
    Caption = 
      '7. You will need to make sure the client has the required stored' +
      ' procedures and latest usp_data_correction installed before runn' +
      'ing your script.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object mmoControlTable: TMemo
    Left = 8
    Top = 205
    Width = 1065
    Height = 340
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Tahoma'
    Font.Style = []
    Lines.Strings = (
      '---------NECESSARY CONTROL TABLE FIELDS-----------------'
      ''
      'execution_date_time  -- i.e. @now = GetDate'
      'table_name                 -- i.e. '#39'sale'#39
      'backup_tablename      -- '#39'Call_067345'#39
      'pkey                            -- i.e. '#39'sale_code'#39
      'pkey_value                 -- i.e. '#39'21045356734'#39' or sale_code'
      
        'action_type                -- '#39'I'#39'(Insert), '#39'U'#39'(Update), '#39'D'#39'(Dele' +
        'te)'
      
        'insert_set_sql             -- For inserts i.e. '#39'(a,b,c,d) VALUES' +
        ' (1,2,3,4)'#39' '
      
        '                                   -- Updates i.e. '#39'script.statu' +
        's_ind = control.status_ind_new, script.product_ref = NULL'#39
      #9'    '#9'   -- For deletes it must be '#39#39
      '--Replication fields (IF @replication_ind <> '#39'N'#39')'
      
        'replicate_rec_ind'#9'    -- '#39'Y'#39'(Yes), '#39'N'#39'(No). '#39'O'#39' (Replicate Only,' +
        ' no DB change). If '#39'N'#39', then the following parameters are ignore' +
        'd'
      'replicated_ind             -- '#39'Y'#39'(Yes), '#39'N'#39'(No).'
      
        'businessobject_name -- i.e. '#39'ToSale'#39', '#39'ToLayby'#39', '#39'ToUnitLoad'#39'   ' +
        '   '#9'  '
      
        'transmit_full_ind         -- '#39'Y'#39'(Replicate the whole BO), '#39'N'#39'(Ju' +
        'st from this table)'#9'  '
      
        'rep_target                  -- This record will only replicate t' +
        'o this location. NULL/'#39#39' means everywhere. '
      
        '                                       Use ('#39'^'#39' + retailchain_co' +
        'de) to replicate to all locations in a retail chain.')
    ParentFont = False
    TabOrder = 0
  end
  object mmoStoredProc: TMemo
    Left = 8
    Top = 551
    Width = 1065
    Height = 360
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Tahoma'
    Font.Style = []
    Lines.Strings = (
      '--------STORED PROCEDURE PARAMETERS-------------'
      ''
      
        '  @control_table               AS NVARCHAR(64),    -- This can e' +
        'ither be the name of a global temp table or a persistent table'
      
        '  @transaction_sql             AS NVARCHAR(MAX),   -- Additional' +
        ' custom SQL, executed inside the transaction. Optional for rare ' +
        'occasions.'
      
        '  @verification_condition_sql  AS NVARCHAR(MAX),   -- This SQL g' +
        'oes inside an IF condition before the transaction is committed. ' +
        'It'#39's optional.'
      
        '  @commit_tran                 CHAR(1),            -- '#39'Y'#39'(Yes), ' +
        #39'N'#39'(No). If '#39'N'#39', then you have the opportunity to spot check bef' +
        'ore committing.'
      
        '  @debug_ind                   CHAR(1),            -- This will ' +
        'select some intermediate tables used in the calculation. It does' +
        'n'#39't stop the transaction.'
      '  --Backup'
      
        '  @control_backup_table        AS NVARCHAR(64),    -- i.e.'#39'rd_06' +
        '3567_22052016'#39
      '  @now                         DATETIME,           -- GetDate()'
      '  --Audit Trail (Writes to errorevent table)'
      
        '  @calltasknum'#9#9'           VARCHAR(12),'#9'       -- This is your C' +
        'all Number or Task Number'
      
        '  @remediuser_code'#9'           VARCHAR(12),'#9'       -- This will b' +
        'e your ErrorEvent ID (auto-generated)'
      
        '  @script_name'#9#9'           VARCHAR(50),'#9'       -- This is the sh' +
        'ort description of your script.'
      
        '  @script_desc'#9#9'           VARCHAR(120),       -- This is the de' +
        'scription of your script from SQL Checklist.'
      '  --Replication'
      
        '  @replication_ind             CHAR(1) = '#39'N'#39',      -- '#39'Y'#39'(Yes), ' +
        #39'N'#39'(No), '#39'P'#39'(Only replicate from a persistent control table crea' +
        'ted previously without DB changes).   '
      
        '  @rep_batch_limit             INTEGER = NULL      -- This is th' +
        'e number of records to replicate, for all tables being replicate' +
        'd. NULL means no limit.')
    ParentFont = False
    TabOrder = 1
  end
end
