{$I XZYComm.inc}
// XueZiYing
//
// 15/06/2020
//
// 串口通讯组件修改自 小猪工作室 Small-Pig Team （中国台湾）的SPCOMM V2.5 串口通讯组件
//
// Email   : Xueziying@sina.com;Xueziying@Hotmail.com
// Date : 2020/6/123
// Spcomm Ver 1.01   1996/9/4
// - Add setting Parity, Databits, StopBits
// - Add setting Flowcontrol:Dtr-Dsr, Cts-Rts, Xon-Xoff
// - Add setting Timeout information for read/write
// Spcomm Ver 1.02   1996/12/24
// - Add Sender parameter to TReceiveDataEvent
// Spcomm Ver 2.0    1997/4/15
// - Support separatly DTR/DSR and RTS/CTS hardware flow control setting
// - Support separatly OutX and InX software flow control setting
// - Log file(for debug) may used by many comms at the same time
// - Add DSR sensitivity property
// - You can set error char. replacement when parity error
// - Let XonLim/XoffLim and XonChar/XoffChar setting by yourself
// - You may change flow-control when comm is still opened
// - Add OnReceiveError event handler
// - Add OnReceiveError event handler when overrun, framing error,
// parity error
// - Fix some bug
// Spcomm Ver 2.01   1997/4/19
// - Support some property for modem
// - Add OnModemStateChange event hander when RLSD(CD) change state
// Spcomm Ver 2.02   1997/4/28
// - Bug fix: When receive XOFF character, the system FAULT!!!!
// Spcomm Ver 2.5    1997/5/9
// - Add OnSendDataEmpty event handler when all data in buffer
// are sent(send-buffer become empty) this handler is called.
// You may call send data here.
// - Change the ModemState parameters in OnModemStateChange
// to ModemEvent to indicate what modem event make this call
// - Add RING signal detect. When RLSD changed state or
// RING signal was detected, OnModemStateChange handler is called
// - Change XonLim and XoffLim from 100 to 500
// - Remove TWriteThread.WriteData member
// - PostHangupCall is re-design for debuging function
// - Add a boolean property SendDataEmpty, True when send buffer
// is empty
// Version 2.51   2002/3/15
// - 基于Spcomm 2.5改写。
// Version 2.6    2008/3/5
// - Add Eof char,Evt char;
// Version 2.01   2015/5/13
// - 修正不能打开Com10以上Bug
// Version 2.02   2018/6/16
// - 修正错误提示信息
// Version 3.0    2020/6/12
// - 兼容Delphi10.3
// - 升级到delphi 10.3.3
// - 修复 Parity 设置Bug , szInputBuffer 修改为@szInputBuffer;
// Version 3.01		2020/6/16
// - Modify some error from source code,and can send data without
// lose any byte.Modified some error about the SENDEMPTY property,
// so it can be checked in applicaiton.
// Version 3.1		2020/6/17
// - Add new property Connected;

unit XZYComm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs;

const
  // messages from read/write threads
  PWM_GOTCOMMDATA = WM_USER + 1;
  PWM_RECEIVEERROR = WM_USER + 2;
  PWM_REQUESTHANGUP = WM_USER + 3;
  PWM_MODEMSTATECHANGE = WM_USER + 4;
  PWM_SENDDATAEMPTY = WM_USER + 5;
  XZY_COMPONENT_VERSION = 'v3.10 2020.6.16';
  XZY_AUTHOR = AnsiString('薛自影');
  XZY_CONTACT = 'XueZiYing@sina.com QQ:22236263';

type
  TParity = (None, Odd, Even, Mark, Space);
  TStopBits = (_1, _1_5, _2);
  TByteSize = (_5, _6, _7, _8);
  TDtrControl = (DtrEnable, DtrDisable, DtrHandshake);
  TRtsControl = (RtsEnable, RtsDisable, RtsHandshake, RtsTransmissionAvailable);
  TWait_Mask = (mEV_RXCHAR, mEV_RXFLAG, mEV_TXEMPTY, mEV_CTS, mEV_DSR, mEV_RLSD, mEV_BREAK, mEV_ERR, mEV_RING, mEV_PERR,
    mEV_RX80FULL, mEV_EVENT1, mEV_EVENT2);
  TWait_MaskSet = set of TWait_Mask;
  ECommsError = class(Exception);
  TReceiveDataEvent = procedure(Sender: TObject; Buffer: Pointer; BufferLength: Word) of object;
  TReceiveErrorEvent = procedure(Sender: TObject; EventMask: DWORD) of object;
  TModemStateChangeEvent = procedure(Sender: TObject; ModemEvent: DWORD) of object;
  TSendDataEmptyEvent = procedure(Sender: TObject) of object;

const
  //
  // Modem Event Constant
  //
  ME_CTS = 1;
  ME_DSR = 2;
  ME_RING = 4;
  ME_RLSD = 8;

type
  TReadThread = class(TThread)
  protected
    procedure Execute; override;
  public
    hCommFile: THandle;
    hCloseEvent: THandle;
    hComm32Window: THandle;

    function SetupCommEvent(lpOverlappedCommEvent: POverlapped; var lpfdwEvtMask: DWORD): Boolean;
    function SetupReadEvent(lpOverlappedRead: POverlapped;
                              lpszInputBuffer: LPSTR; dwSizeofBuffer: DWORD;
                              var lpnNumberOfBytesRead: DWORD): Boolean;
    function HandleCommEvent(lpOverlappedCommEvent: POverlapped;
                              var lpfdwEvtMask: DWORD; fRetrieveEvent: Boolean): Boolean;
    function HandleReadEvent(lpOverlappedRead: POverlapped;
                              lpszInputBuffer: LPSTR; dwSizeofBuffer: DWORD;
                              var lpnNumberOfBytesRead: DWORD): Boolean;
    function HandleReadData(lpszInputBuffer: LPCSTR; dwSizeofBuffer: DWORD): Boolean;
    function ReceiveData(lpNewString: LPSTR; dwSizeofNewString: DWORD): BOOL;
    function ReceiveError(EvtMask: DWORD): BOOL;
    function ModemStateChange(ModemEvent: DWORD): BOOL;
    procedure PostHangupCall;
  end;

  TWriteThread = class(TThread)
  protected
    procedure Execute; override;
    function HandleWriteData(lpOverlappedWrite: POverlapped; pDataToWrite: PChar;
      dwNumberOfBytesToWrite: DWORD): Boolean;
  public
    hCommFile: THandle;
    hCloseEvent: THandle;
    hComm32Window: THandle;
    pFSendDataEmpty: ^Boolean;
    procedure PostHangupCall;
  end;

type
  TXZYComm = class(TComponent)
  private
    { Private declarations }
    ReadThread: TReadThread;
    WriteThread: TWriteThread;
    hCommFile: THandle;
    hCloseEvent: THandle;
    FHWnd: THandle;
    FSendDataEmpty: Boolean; // True if send buffer become empty

    FCommName: string;
    FBaudRate: DWORD;
    FBuffInSize: DWORD;
    FBuffOutSize: DWORD;
    FTxAbort: Boolean;
    FRxAbort: Boolean;
    FTxClear: Boolean;
    FRxClear: Boolean;
    FWait_Mask: TWait_MaskSet;

    FParityCheck: Boolean;
    FOutx_CtsFlow: Boolean;
    FOutx_DsrFlow: Boolean;
    FDtrControl: TDtrControl;
    FDsrSensitivity: Boolean;
    FTxContinueOnXoff: Boolean;
    FOutx_XonXoffFlow: Boolean;
    FInx_XonXoffFlow: Boolean;
    FReplaceWhenParityError: Boolean;
    FIgnoreNullChar: Boolean;
    FRtsControl: TRtsControl;
    FXonLimit: Word;
    FXoffLimit: Word;
    FByteSize: TByteSize;
    FParity: TParity;
    FStopBits: TStopBits;
    FXonChar: AnsiChar;
    FXoffChar: AnsiChar;
    FReplacedChar: AnsiChar;
    FEofChar: AnsiChar;
    FEvtChar: AnsiChar;
    FinBuffer: string;
    FDtr: Boolean;
    FRts: Boolean;

    FReadIntervalTimeout: DWORD;
    FReadTotalTimeoutMultiplier: DWORD;
    FReadTotalTimeoutConstant: DWORD;
    FWriteTotalTimeoutMultiplier: DWORD;
    FWriteTotalTimeoutConstant: DWORD;
    FOnReceiveData: TReceiveDataEvent;
    FOnRequestHangup: TNotifyEvent;
    FOnReceiveError: TReceiveErrorEvent;
    FOnModemStateChange: TModemStateChangeEvent;
    FOnSendDataEmpty: TSendDataEmptyEvent;

    procedure SetBaudRate(Rate: DWORD);
    procedure SetParityCheck(b: Boolean);
    procedure SetOutx_CtsFlow(b: Boolean);
    procedure SetOutx_DsrFlow(b: Boolean);
    procedure SetDtrControl(c: TDtrControl);
    procedure SetDsrSensitivity(b: Boolean);
    procedure SetTxContinueOnXoff(b: Boolean);
    procedure SetOutx_XonXoffFlow(b: Boolean);
    procedure SetInx_XonXoffFlow(b: Boolean);
    procedure SetReplaceWhenParityError(b: Boolean);
    procedure SetIgnoreNullChar(b: Boolean);
    procedure SetRtsControl(c: TRtsControl);
    procedure SetXonLimit(Limit: Word);
    procedure SetXoffLimit(Limit: Word);
    procedure SetByteSize(Size: TByteSize);
    procedure SetParity(p: TParity);
    procedure SetStopBits(Bits: TStopBits);
    procedure SetXonChar(c: AnsiChar);
    procedure SetXoffChar(c: AnsiChar);
    procedure SetReplacedChar(c: AnsiChar);
    procedure SetEvtChar(c: AnsiChar);
    procedure SetEofChar(c: AnsiChar);
    procedure SetDtr(b: Boolean);
    procedure SetRts(b: Boolean);

    procedure SetReadIntervalTimeout(v: DWORD);
    procedure SetReadTotalTimeoutMultiplier(v: DWORD);
    procedure SetReadTotalTimeoutConstant(v: DWORD);
    procedure SetWriteTotalTimeoutMultiplier(v: DWORD);
    procedure SetWriteTotalTimeoutConstant(v: DWORD);

    procedure CommWndProc(var msg: TMessage);
    procedure _SetCommState;
    procedure _SetCommTimeout;

    function GetConnected: Boolean;

  protected
    { Protected declarations }
    procedure CloseReadThread;
    procedure CloseWriteThread;
    procedure ReceiveData(Buffer: PChar; BufferLength: Word);
    procedure ReceiveError(EvtMask: DWORD);
    procedure ModemStateChange(ModemEvent: DWORD);
    procedure RequestHangup;
    procedure _SendDataEmpty;
    function GetVersion: string;
    procedure SetVersion(const Val: string);
    function GetAuthor: AnsiString;
    // procedure SetAuthor(const Val: string);
    function GetContact: string;
    // procedure SetContact(const Val: string);

  public
    { Public declarations }
    property Handle: THandle read hCommFile;
    property SendDataEmpty: Boolean read FSendDataEmpty;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // procedure StartComm;
    function StartComm: Boolean;
    procedure StopComm;
    function WriteCommData(pDataToWrite: PAnsiChar; dwSizeofDataToWrite: Word): Boolean;
    function GetModemState: DWORD;
    function GetInBuffer: string;

  published
    { Published declarations }
    property CommName: string read FCommName write FCommName;
    property BaudRate: DWORD read FBaudRate write SetBaudRate;
    property BuffInSize: DWORD read FBuffInSize write FBuffInSize;
    property BuffOutSize: DWORD read FBuffOutSize write FBuffOutSize;
    property PurgeTxAbort: Boolean read FTxAbort write FTxAbort;
    property PurgeRxAbort: Boolean read FRxAbort write FRxAbort;
    property PurgeTxClear: Boolean read FTxClear write FTxClear;
    property PurgeRxClear: Boolean read FRxClear write FRxClear;
    property Wait_Mask: TWait_MaskSet read FWait_Mask write FWait_Mask default [];

    property ParityCheck: Boolean read FParityCheck write SetParityCheck;
    property Outx_CtsFlow: Boolean read FOutx_CtsFlow write SetOutx_CtsFlow;
    property Outx_DsrFlow: Boolean read FOutx_DsrFlow write SetOutx_DsrFlow;
    property DtrControl: TDtrControl read FDtrControl write SetDtrControl;
    property DsrSensitivity: Boolean read FDsrSensitivity write SetDsrSensitivity;
    property TxContinueOnXoff: Boolean read FTxContinueOnXoff write SetTxContinueOnXoff;
    property Outx_XonXoffFlow: Boolean read FOutx_XonXoffFlow write SetOutx_XonXoffFlow;
    property Inx_XonXoffFlow: Boolean read FInx_XonXoffFlow write SetInx_XonXoffFlow;
    property ReplaceWhenParityError: Boolean read FReplaceWhenParityError write SetReplaceWhenParityError;
    property IgnoreNullChar: Boolean read FIgnoreNullChar write SetIgnoreNullChar;
    property RtsControl: TRtsControl read FRtsControl write SetRtsControl;
    property XonLimit: Word read FXonLimit write SetXonLimit;
    property XoffLimit: Word read FXoffLimit write SetXoffLimit;
    property ByteSize: TByteSize read FByteSize write SetByteSize;
    property Parity: TParity read FParity write SetParity;
    property StopBits: TStopBits read FStopBits write SetStopBits;
    property XonChar: AnsiChar read FXonChar write SetXonChar;
    property XoffChar: AnsiChar read FXoffChar write SetXoffChar;
    property ReplacedChar: AnsiChar read FReplacedChar write SetReplacedChar;
    property Connected: Boolean read GetConnected;
    property EofChar: AnsiChar read FEofChar write SetEofChar;
    property EvtChar: AnsiChar read FEvtChar write SetEvtChar;

    property ReadIntervalTimeout: DWORD read FReadIntervalTimeout write SetReadIntervalTimeout;
    property ReadTotalTimeoutMultiplier: DWORD read FReadTotalTimeoutMultiplier write SetReadTotalTimeoutMultiplier;
    property ReadTotalTimeoutConstant: DWORD read FReadTotalTimeoutConstant write SetReadTotalTimeoutConstant;
    property WriteTotalTimeoutMultiplier: DWORD read FWriteTotalTimeoutMultiplier write SetWriteTotalTimeoutMultiplier;
    property WriteTotalTimeoutConstant: DWORD read FWriteTotalTimeoutConstant write SetWriteTotalTimeoutConstant;
    property DtrEnabled: Boolean read FDtr write SetDtr;
    property RtsEnabled: Boolean read FRts write SetRts;

    property OnReceiveData: TReceiveDataEvent read FOnReceiveData write FOnReceiveData;
    property OnReceiveError: TReceiveErrorEvent read FOnReceiveError write FOnReceiveError;
    property OnModemStateChange: TModemStateChangeEvent read FOnModemStateChange write FOnModemStateChange;
    property OnRequestHangup: TNotifyEvent read FOnRequestHangup write FOnRequestHangup;
    property OnSendDataEmpty: TSendDataEmptyEvent read FOnSendDataEmpty write FOnSendDataEmpty;
    property Version: string read GetVersion write SetVersion stored FALSE;
    property Author: AnsiString read GetAuthor; // write SetAuthor stored FALSE;
    property AuthorContact: string read GetContact; // write SetContact stored FALSE;

  end;

const
  // This is the message posted to the WriteThread
  // When we have something to write.
  PWM_COMMWRITE = WM_USER + 1;

  // Default size of the Input Buffer used by this code.
  INPUTBUFFERSIZE = 4096; // 4096;2048; 1024; //$FFFF   Max 64 KBytes

procedure Register;

implementation

(* **************************************************************************** *)
// TXZYComm PUBLIC METHODS
(* **************************************************************************** *)
constructor TXZYComm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ReadThread := nil;
  WriteThread := nil;
  hCommFile := 0;
  hCloseEvent := 0;
  FSendDataEmpty := True;

  FCommName := 'COM2';
  FBaudRate := 9600;
  FBuffInSize := 4096;
  FBuffOutSize := 4096;
  FTxAbort := True;
  FRxAbort := True;
  FTxClear := True;
  FRxClear := True;
  FWait_Mask := [mEV_RLSD, mEV_ERR, mEV_RING];
  // FMask_EV_RXCHAR := Flase;
  // FMask_EV_RXFLAG := Flase;        { Received certain character }
  // FMask_EV_TXEMPTY := Flase;       { Transmitt Queue Empty }
  // FMask_EV_CTS := Flase;           { CTS changed state }
  // FMask_EV_DSR := Flase;         { DSR changed state }
  // FMask_EV_RLSD := True;        { RLSD changed state }
  // FMask_EV_BREAK := Flase;       { BREAK received }
  // FMask_EV_ERR := True;         { Line status error occurred }
  // FMask_EV_RING := True;       { Ring signal detected }
  // FMask_EV_PERR := Flase;       { Printer error occured }
  // FMask_EV_RX80FULL := Flase;   { Receive buffer is 80 percent full }
  // FMask_EV_EVENT1 := Flase;     { Provider specific event 1 }
  // FMask_EV_EVENT2 := Flase;    { Provider specific event 2 }
  // =============={ Events 来源于Windows }====================
  // EV_RXCHAR = 1;        { Any Character received }
  // EV_RXFLAG = 2;        { Received certain character }
  // EV_TXEMPTY = 4;       { Transmitt Queue Empty }
  // EV_CTS = 8;           { CTS changed state }
  // EV_DSR = $10;         { DSR changed state }
  // EV_RLSD = $20;        { RLSD changed state }
  // EV_BREAK = $40;       { BREAK received }
  // EV_ERR = $80;         { Line status error occurred }
  // EV_RING = $100;       { Ring signal detected }
  // EV_PERR = $200;       { Printer error occured }
  // EV_RX80FULL = $400;   { Receive buffer is 80 percent full }
  // EV_EVENT1 = $800;     { Provider specific event 1 }
  // EV_EVENT2 = $1000;    { Provider specific event 2 }
  // ================= Error Flags 来源于Windows==========================
  // CE_RXOVER = 1;        { Receive Queue overflow .输入缓冲区字符溢出，或在收到文件接收结束表示符后，又接到字符。}
  // CE_OVERRUN = 2;       { Receive Overrun Error .缓冲区字符溢出，有数据丢失。}
  // CE_RXPARITY = 4;      { Receive Parity Error .奇偶检验错误。}
  // CE_FRAME = 8;         { Receive Framing error .检测到有个侦差错.}
  // CE_BREAK = $10;       { Break Detected  硬件检测到有个终止条件.}
  // CE_TXFULL = $100;     { TX Queue is full .在输出缓冲区已满的情况下，尝试输出字符。}
  // CE_PTO = $200;        { LPTx Timeout .仅用于win95: 有相应设备使用时间事件超时.}
  // CE_IOE = $400;        { LPTx I/O Error .设备通信中出现一个I/O错误.}
  // CE_DNS = $800;        { LPTx Device not selected. 仅用于win95: 没有选择相应的驱动.}
  // CE_OOP = $1000;       { LPTx Out-Of-Paper .仅用于win95: 相应的驱动超出了文件的范围。}
  // CE_MODE = $8000;      { Requested mode unsupported .要求的模式不支持, 或hFile 句柄的参数是非法的。}

  FParityCheck := FALSE;
  FOutx_CtsFlow := FALSE;
  FOutx_DsrFlow := FALSE;
  FDtrControl := DtrEnable;
  FDsrSensitivity := FALSE;
  FTxContinueOnXoff := True;
  FOutx_XonXoffFlow := True;
  FInx_XonXoffFlow := True;
  FReplaceWhenParityError := FALSE;
  FIgnoreNullChar := FALSE;
  FRtsControl := RtsEnable;
  FXonLimit := 500;
  FXoffLimit := 500;
  FByteSize := _8;
  FParity := None;
  FStopBits := _1;
  FXonChar := chr($11); // Ctrl-Q
  FXoffChar := chr($13); // Ctrl-S
  FReplacedChar := chr(0);
  FEvtChar := chr(0);
  FEofChar := chr(0);
  FDtr := True;
  FRts := True;
  FReadIntervalTimeout := 100;
  FReadTotalTimeoutMultiplier := 0;
  FReadTotalTimeoutConstant := 0;
  FWriteTotalTimeoutMultiplier := 0;
  FWriteTotalTimeoutConstant := 0;

  if not(csDesigning in ComponentState) then
    FHWnd := AllocateHWnd(CommWndProc)
end;

destructor TXZYComm.Destroy;
begin
  if not(csDesigning in ComponentState) then
    DeallocateHWnd(FHWnd);

  inherited Destroy;
end;

//
// FUNCTION: StartComm
//
// PURPOSE: Starts communications over the comm port.
//
// PARAMETERS:
// hNewCommFile - This is the COMM File handle to communicate with.
// This handle is obtained from TAPI.
//
// Output:
// Successful: Startup the communications.
// Failure: Raise a exception
//
// COMMENTS:
//
// StartComm makes sure there isn't communication in progress already,
// creates a Comm file, and creates the read and write threads.  It
// also configures the hNewCommFile for the appropriate COMM settings.
//
// If StartComm fails for any reason, it's up to the calling application
// to close the Comm file handle.
//
//

// procedure TXZYComm.StartComm;

// 用于Boolen

function TXZYComm.StartComm: Boolean;

var
  hNewCommFile: THandle;
  PurgedwFlags: DWORD;
begin
  // Are we already doing comm?
  if (hCommFile <> 0) then
  begin
    // 用于Boolen﹝
    Result := True;
    exit;
    raise ECommsError.Create(FCommName + ' 端口已经打开' + #13 + 'This serial port already opened');
  end;

  hNewCommFile := CreateFile(PChar('\\.\' + FCommName), GENERIC_READ or GENERIC_WRITE, 0, { not shared }
    nil, { no security ?? }
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_OVERLAPPED, 0 { template } );

  if hNewCommFile = INVALID_HANDLE_VALUE then
  begin
    raise ECommsError.Create('打开 ' + FCommName + ' 端口错误' + #13 + 'Error opening serial port');
    Result := FALSE;
    exit;
  end;
  // Is this a valid comm handle?
  if GetFileType(hNewCommFile) <> FILE_TYPE_CHAR then
  begin
    CloseHandle(hNewCommFile);
    raise ECommsError.Create('定义端口名 ' + FCommName + ' 错误' + #13 + 'File handle is not a comm handle ');
    Result := FALSE;
    exit;
  end;

  if not SetupComm(hNewCommFile, FBuffInSize, FBuffOutSize) then
  begin
    CloseHandle(hCommFile);
    raise ECommsError.Create('不能建立 ' + FCommName + ' 缓冲区' + #13 + 'Cannot setup comm buffer');
    Result := FALSE;
    exit;
  end;

  // It is ok to continue.

  hCommFile := hNewCommFile;

  // purge any information in the buffer
  PurgedwFlags := 0;
  if FTxAbort then
    PurgedwFlags := PurgedwFlags or PURGE_TXABORT;
  if FRxAbort then
    PurgedwFlags := PurgedwFlags or PURGE_RXABORT;
  if FTxClear then
    PurgedwFlags := PurgedwFlags or PURGE_TXCLEAR;
  if FRxClear then
    PurgedwFlags := PurgedwFlags or PURGE_RXCLEAR;

  PurgeComm(hCommFile, PurgedwFlags);

  FSendDataEmpty := True;

  // Setting the time-out value
  _SetCommTimeout;

  // Querying then setting the comm port configurations.
  _SetCommState;

  // Create the event that will signal the threads to close.
  hCloseEvent := CreateEvent(nil, True, FALSE, nil);

  if hCloseEvent = 0 then
  begin
    CloseHandle(hCommFile);
    hCommFile := 0;

    Result := FALSE;

    raise ECommsError.Create('不能创建事件' + #13 + 'Unable to create event');

  end;

  // Create the Read thread.
  try
    ReadThread := TReadThread.Create(True { suspended } );
  except
    ReadThread := nil;
    CloseHandle(hCloseEvent);
    CloseHandle(hCommFile);
    hCommFile := 0;
    raise ECommsError.Create('不能创建读取数据线程' + #13 + 'Unable to create read thread');

  end;
  ReadThread.hCommFile := hCommFile;
  ReadThread.hCloseEvent := hCloseEvent;
  ReadThread.hComm32Window := FHWnd;

  // Comm threads should have a higher base priority than the UI thread.
  // If they don't, then any temporary priority boost the UI thread gains
  // could cause the COMM threads to loose data.
  ReadThread.Priority := tpHighest;

  // Create the Write thread.
  try
    WriteThread := TWriteThread.Create(True { suspended } );
  except
    CloseReadThread;
    WriteThread := nil;
    CloseHandle(hCloseEvent);
    CloseHandle(hCommFile);
    hCommFile := 0;
    raise ECommsError.Create('不能创建写数线程' + #13 + 'Unable to create write thread');

  end;
  WriteThread.hCommFile := hCommFile;
  WriteThread.hCloseEvent := hCloseEvent;
  WriteThread.hComm32Window := FHWnd;
  WriteThread.pFSendDataEmpty := @FSendDataEmpty;

  WriteThread.Priority := tpHigher;

  ReadThread.Resume;
  WriteThread.Resume;

  // Everything was created ok.  Ready to go!
  // 用于Boolen﹝
  Result := True;
end; { TXZYComm.StartComm }

//
// FUNCTION: StopComm
//
// PURPOSE: Stop and end all communication threads.
//
// PARAMETERS:
// none
//
// RETURN VALUE:
// none
//
// COMMENTS:
//
// Tries to gracefully signal all communication threads to
// close, but terminates them if it has to.
//
//

procedure TXZYComm.StopComm;
begin
  // No need to continue if we're not communicating.
  if hCommFile = 0 then
    exit;

  // Close the threads.
  CloseReadThread;
  CloseWriteThread;

  // Not needed anymore.
  CloseHandle(hCloseEvent);

  // Now close the comm port handle.
  CloseHandle(hCommFile);
  hCommFile := 0
end; { TXZYComm.StopComm }

//
// FUNCTION: WriteCommData(PChar, Word)
//
// PURPOSE: Send a String to the Write Thread to be written to the Comm.
//
// PARAMETERS:
// pszStringToWrite     - String to Write to Comm port.
// nSizeofStringToWrite - length of pszStringToWrite.
//
// RETURN VALUE:
// Returns TRUE if the PostMessage is successful.
// Returns FALSE if PostMessage fails or Write thread doesn't exist.
//
// COMMENTS:
//
// This is a wrapper function so that other modules don't care that
// Comm writing is done via PostMessage to a Write thread.  Note that
// using PostMessage speeds up response to the UI (very little delay to
// 'write' a string) and provides a natural buffer if the comm is slow
// (ie: the messages just pile up in the message queue).
//
// Note that it is assumed that pszStringToWrite is allocated with
// LocalAlloc, and that if WriteCommData succeeds, its the job of the
// Write thread to LocalFree it.  If WriteCommData fails, then its
// the job of the calling function to free the string.
//
//

function TXZYComm.WriteCommData(pDataToWrite: PAnsiChar; dwSizeofDataToWrite: Word): Boolean;
var
  Buffer: Pointer;
  S:Ansistring;
begin
  if (WriteThread <> nil) and (dwSizeofDataToWrite <> 0) then
  begin
    Buffer := Pointer(LocalAlloc(LPTR, dwSizeofDataToWrite +1));
    Move(pDataToWrite^, Buffer^, dwSizeofDataToWrite);
   // SetLength(s,dwSizeofDataToWrite);
   // Move(pDataToWrite^,s[1],dwSizeofDataToWrite);

    FSendDataEmpty := FALSE;
    if PostThreadMessage(WriteThread.ThreadID, PWM_COMMWRITE, WPARAM(dwSizeofDataToWrite), LPARAM(Buffer)) then
    begin
      Result := True;
      exit
    end
  end;

  Result := FALSE
end; { TXZYComm.WriteCommData }

//
// FUNCTION: GetModemState
//
// PURPOSE: Read the state of modem input pin right now
//
// PARAMETERS:
// none
//
// RETURN VALUE:
//
// A DWORD variable containing one or more of following codes:
//
// Value       Meaning
// ----------  -----------------------------------------------------------
// MS_CTS_ON   The CTS (clear-to-send) signal is on.  ME_CTS = 1;
// MS_DSR_ON   The DSR (data-set-ready) signal is on.  ME_DSR = 2;
// MS_RING_ON  The ring indicator signal is on.   ME_RING = 4;
// MS_RLSD_ON  The RLSD (receive-line-signal-detect) signal is on.  ME_RLSD = 8;
//
// If this comm have bad handle or not yet opened, the return value is 0
//
// COMMENTS:
//
// This member function calls GetCommModemStatus and return its value.
// Before calling this member function, you must have a successful
// 'StartOpen' call.
//
//

function TXZYComm.GetModemState: DWORD;
var
  dwModemState: DWORD;
begin
  if not GetCommModemStatus(hCommFile, dwModemState) then
    Result := 0
  else
    Result := dwModemState
end;

function TXZYComm.GetInBuffer: string;
begin
  Result := FinBuffer;
  FinBuffer := '';
end;

(* **************************************************************************** *)
// TXZYComm PROTECTED METHODS
(* **************************************************************************** *)

//
// FUNCTION: CloseReadThread
//
// PURPOSE: Close the Read Thread.
//
// PARAMETERS:
// none
//
// RETURN VALUE:
// none
//
// COMMENTS:
//
// Closes the Read thread by signaling the CloseEvent.
// Purges any outstanding reads on the comm port.
//
// Note that terminating a thread leaks memory.
// Besides the normal leak incurred, there is an event object
// that doesn't get closed.  This isn't worth worrying about
// since it shouldn't happen anyway.
//
//

procedure TXZYComm.CloseReadThread;
begin
  // If it exists...
  if ReadThread <> nil then
  begin
    // Signal the event to close the worker threads.
    SetEvent(hCloseEvent);

    // Purge all outstanding reads
    PurgeComm(hCommFile, PURGE_RXABORT + PURGE_RXCLEAR);

    // Wait 10 seconds for it to exit.  Shouldn't happen.
    if (WaitForSingleObject(ReadThread.Handle, 10000) = WAIT_TIMEOUT) then
      ReadThread.Terminate;
    ReadThread.Free;
    ReadThread := nil
  end
end; { TXZYComm.CloseReadThread }

//
// FUNCTION: CloseWriteThread
//
// PURPOSE: Closes the Write Thread.
//
// PARAMETERS:
// none
//
// RETURN VALUE:
// none
//
// COMMENTS:
//
// Closes the write thread by signaling the CloseEvent.
// Purges any outstanding writes on the comm port.
//
// Note that terminating a thread leaks memory.
// Besides the normal leak incurred, there is an event object
// that doesn't get closed.  This isn't worth worrying about
// since it shouldn't happen anyway.
//
//

procedure TXZYComm.CloseWriteThread;
begin
  // If it exists...
  if WriteThread <> nil then
  begin
    // Signal the event to close the worker threads.
    SetEvent(hCloseEvent);

    // Purge all outstanding writes.
    PurgeComm(hCommFile, PURGE_TXABORT + PURGE_TXCLEAR);
    FSendDataEmpty := True;

    // Wait 10 seconds for it to exit.  Shouldn't happen.
    if WaitForSingleObject(WriteThread.Handle, 10000) = WAIT_TIMEOUT then
      WriteThread.Terminate;
    WriteThread.Free;
    WriteThread := nil
  end
end; { TXZYComm.CloseWriteThread }

procedure TXZYComm.ReceiveData(Buffer: PChar; BufferLength: Word);
begin
  if Assigned(FOnReceiveData) then
    FOnReceiveData(self, Buffer, BufferLength);
  FinBuffer := Buffer;
end;

procedure TXZYComm.ReceiveError(EvtMask: DWORD);
begin
  if Assigned(FOnReceiveError) then
    FOnReceiveError(self, EvtMask)
end;

procedure TXZYComm.ModemStateChange(ModemEvent: DWORD);
begin
  if Assigned(FOnModemStateChange) then
    FOnModemStateChange(self, ModemEvent)
end;

procedure TXZYComm.RequestHangup;
begin
  if Assigned(FOnRequestHangup) then
    FOnRequestHangup(self)
end;

procedure TXZYComm._SendDataEmpty;
begin
  if Assigned(FOnSendDataEmpty) then
    FOnSendDataEmpty(self)
end;

(* **************************************************************************** *)
// TXZYComm PRIVATE METHODS
(* **************************************************************************** *)

procedure TXZYComm.CommWndProc(var msg: TMessage);
begin
  case msg.msg of
    PWM_GOTCOMMDATA:
      begin
        ReceiveData(PChar(msg.LPARAM), msg.WPARAM);
        LocalFree(msg.LPARAM)
      end;
    PWM_RECEIVEERROR:
      ReceiveError(msg.LPARAM);
    PWM_MODEMSTATECHANGE:
      ModemStateChange(msg.LPARAM);
    PWM_REQUESTHANGUP:
      RequestHangup;
    PWM_SENDDATAEMPTY:
      _SendDataEmpty
  end
end;

procedure TXZYComm._SetCommState;
var
  dcb: Tdcb;
  commprop: TCommProp;
  fdwEvtMask, fEvMask: DWORD;
begin
  // Configure the comm settings.
  // NOTE: Most Comm settings can be set through TAPI, but this means that
  // the CommFile will have to be passed to this component.

  GetCommState(hCommFile, dcb);
  GetCommProperties(hCommFile, commprop);
  GetCommMask(hCommFile, fdwEvtMask);

  // fAbortOnError is the only DCB dependancy in TapiComm.
  // Can't guarentee that the SP will set this to what we expect.
  { dcb.fAbortOnError := False; NOT VALID }

  dcb.BaudRate := FBaudRate;

  dcb.Flags := 1; // Enable fBinary

  if FParityCheck then
    dcb.Flags := dcb.Flags or 2; // Enable parity check

  // setup hardware flow control

  if FOutx_CtsFlow then
    dcb.Flags := dcb.Flags or 4;

  if FOutx_DsrFlow then
    dcb.Flags := dcb.Flags or 8;

  if FDtrControl = DtrEnable then
    dcb.Flags := dcb.Flags or $10
  else if FDtrControl = DtrHandshake then
    dcb.Flags := dcb.Flags or $20;

  if FDsrSensitivity then
    dcb.Flags := dcb.Flags or $40;

  if FTxContinueOnXoff then
    dcb.Flags := dcb.Flags or $80;

  if FOutx_XonXoffFlow then
    dcb.Flags := dcb.Flags or $100;

  if FInx_XonXoffFlow then
    dcb.Flags := dcb.Flags or $200;

  if FReplaceWhenParityError then
    dcb.Flags := dcb.Flags or $400;

  if FIgnoreNullChar then
    dcb.Flags := dcb.Flags or $800;

  if FRtsControl = RtsEnable then
    dcb.Flags := dcb.Flags or $1000
  else if FRtsControl = RtsHandshake then
    dcb.Flags := dcb.Flags or $2000
  else if FRtsControl = RtsTransmissionAvailable then
    dcb.Flags := dcb.Flags or $3000;

  dcb.XonLim := FXonLimit;
  dcb.XoffLim := FXoffLimit;

  dcb.ByteSize := Ord(FByteSize) + 5;
  dcb.Parity := Ord(FParity);
  dcb.StopBits := Ord(FStopBits);

  dcb.XonChar := FXonChar;
  dcb.XoffChar := FXoffChar;

  dcb.ErrorChar := FReplacedChar;
  dcb.EvtChar := FEvtChar;
  dcb.EofChar := FEofChar;
  // dcb.EvtChar
  // dcb.wReserved
  // dcb.EofChar
  // dcb.wReserved1
  SetCommState(hCommFile, dcb);

  fEvMask := 0;

  if (mEV_RXCHAR in FWait_Mask) then
    fEvMask := fEvMask or EV_RXCHAR;
  if (mEV_RXFLAG in FWait_Mask) then
    fEvMask := fEvMask or EV_RXFLAG;
  if (mEV_TXEMPTY in FWait_Mask) then
    fEvMask := fEvMask or EV_TXEMPTY;
  if (mEV_CTS in FWait_Mask) then
    fEvMask := fEvMask or EV_CTS;
  if (mEV_DSR in FWait_Mask) then
    fEvMask := fEvMask or EV_DSR;
  if (mEV_RLSD in FWait_Mask) then
    fEvMask := fEvMask or EV_RLSD;
  if (mEV_BREAK in FWait_Mask) then
    fEvMask := fEvMask or EV_BREAK;
  if (mEV_ERR in FWait_Mask) then
    fEvMask := fEvMask or EV_ERR;
  if (mEV_RING in FWait_Mask) then
    fEvMask := fEvMask or EV_RING;
  if (mEV_PERR in FWait_Mask) then
    fEvMask := fEvMask or EV_PERR;
  if (mEV_RX80FULL in FWait_Mask) then
    fEvMask := fEvMask or EV_RX80FULL;
  if (mEV_EVENT1 in FWait_Mask) then
    fEvMask := fEvMask or EV_EVENT1;
  if (mEV_EVENT2 in FWait_Mask) then
    fEvMask := fEvMask or EV_EVENT2;

  SetCommMask(hCommFile, fEvMask);

end;

procedure TXZYComm._SetCommTimeout;
var
  commtimeouts: TCommTimeouts;
begin
  GetCommTimeouts(hCommFile, commtimeouts);

  // The CommTimeout numbers will very likely change if you are
  // coding to meet some kind of specification where
  // you need to reply within a certain amount of time after
  // recieving the last byte.  However,  If 1/4th of a second
  // goes by between recieving two characters, its a good
  // indication that the transmitting end has finished, even
  // assuming a 1200 baud modem.

  commtimeouts.ReadIntervalTimeout := FReadIntervalTimeout;
  commtimeouts.ReadTotalTimeoutMultiplier := FReadTotalTimeoutMultiplier;
  commtimeouts.ReadTotalTimeoutConstant := FReadTotalTimeoutConstant;
  commtimeouts.WriteTotalTimeoutMultiplier := FWriteTotalTimeoutMultiplier;
  commtimeouts.WriteTotalTimeoutConstant := FWriteTotalTimeoutConstant;

  SetCommTimeouts(hCommFile, commtimeouts);
end;
// 200207加

procedure TXZYComm.SetDtr(b: Boolean);
begin
  // if b=FDtr then Exit;
  FDtr := b;
  if hCommFile <> 0 then
  begin
    if b then
      EscapeCommFunction(hCommFile, 5)
    else
      EscapeCommFunction(hCommFile, 6);
  end;

end;

procedure TXZYComm.SetRts(b: Boolean);
begin
  // if b=FRts then Exit;
  FRts := b;
  if hCommFile <> 0 then
  begin
    if b then
      EscapeCommFunction(hCommFile, 3)
    else
      EscapeCommFunction(hCommFile, 4);
  end;

end;

procedure TXZYComm.SetBaudRate(Rate: DWORD);
begin
  if Rate = FBaudRate then
    exit;

  FBaudRate := Rate;

  if hCommFile <> 0 then
    _SetCommState
end;
{ procedure TXZYComm.SetWait_Mask(const WaitMask:FWait_MaskSet);
  begin
  //
  end;
}

procedure TXZYComm.SetParityCheck(b: Boolean);
begin
  if b = FParityCheck then
    exit;

  FParityCheck := b;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetOutx_CtsFlow(b: Boolean);
begin
  if b = FOutx_CtsFlow then
    exit;

  FOutx_CtsFlow := b;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetOutx_DsrFlow(b: Boolean);
begin
  if b = FOutx_DsrFlow then
    exit;

  FOutx_DsrFlow := b;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetDtrControl(c: TDtrControl);
begin
  if c = FDtrControl then
    exit;

  FDtrControl := c;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetDsrSensitivity(b: Boolean);
begin
  if b = FDsrSensitivity then
    exit;

  FDsrSensitivity := b;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetTxContinueOnXoff(b: Boolean);
begin
  if b = FTxContinueOnXoff then
    exit;

  FTxContinueOnXoff := b;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetOutx_XonXoffFlow(b: Boolean);
begin
  if b = FOutx_XonXoffFlow then
    exit;

  FOutx_XonXoffFlow := b;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetInx_XonXoffFlow(b: Boolean);
begin
  if b = FInx_XonXoffFlow then
    exit;

  FInx_XonXoffFlow := b;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetReplaceWhenParityError(b: Boolean);
begin
  if b = FReplaceWhenParityError then
    exit;

  FReplaceWhenParityError := b;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetIgnoreNullChar(b: Boolean);
begin
  if b = FIgnoreNullChar then
    exit;

  FIgnoreNullChar := b;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetRtsControl(c: TRtsControl);
begin
  if c = FRtsControl then
    exit;

  FRtsControl := c;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetXonLimit(Limit: Word);
begin
  if Limit = FXonLimit then
    exit;

  FXonLimit := Limit;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetXoffLimit(Limit: Word);
begin
  if Limit = FXoffLimit then
    exit;

  FXoffLimit := Limit;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetByteSize(Size: TByteSize);
begin
  if Size = FByteSize then
    exit;

  FByteSize := Size;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetParity(p: TParity);
begin
  if p = FParity then
    exit;

  FParity := p;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetStopBits(Bits: TStopBits);
begin
  if Bits = FStopBits then
    exit;

  FStopBits := Bits;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetXonChar(c: AnsiChar);
begin
  if c = FXonChar then
    exit;

  FXonChar := c;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetXoffChar(c: AnsiChar);
begin
  if c = FXoffChar then
    exit;

  FXoffChar := c;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetReplacedChar(c: AnsiChar);
begin
  if c = FReplacedChar then
    exit;

  FReplacedChar := c;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetEofChar(c: AnsiChar);
begin
  if c = FEofChar then
    exit;

  FEofChar := c;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetEvtChar(c: AnsiChar);
begin
  if c = FEvtChar then
    exit;

  FEvtChar := c;

  if hCommFile <> 0 then
    _SetCommState
end;

procedure TXZYComm.SetReadIntervalTimeout(v: DWORD);
begin
  if v = FReadIntervalTimeout then
    exit;

  FReadIntervalTimeout := v;

  if hCommFile <> 0 then
    _SetCommTimeout
end;

procedure TXZYComm.SetReadTotalTimeoutMultiplier(v: DWORD);
begin
  if v = FReadTotalTimeoutMultiplier then
    exit;

  FReadTotalTimeoutMultiplier := v;

  if hCommFile <> 0 then
    _SetCommTimeout
end;

procedure TXZYComm.SetReadTotalTimeoutConstant(v: DWORD);
begin
  if v = FReadTotalTimeoutConstant then
    exit;

  FReadTotalTimeoutConstant := v;

  if hCommFile <> 0 then
    _SetCommTimeout
end;

procedure TXZYComm.SetWriteTotalTimeoutMultiplier(v: DWORD);
begin
  if v = FWriteTotalTimeoutMultiplier then
    exit;

  FWriteTotalTimeoutMultiplier := v;

  if hCommFile <> 0 then
    _SetCommTimeout
end;

procedure TXZYComm.SetWriteTotalTimeoutConstant(v: DWORD);
begin
  if v = FWriteTotalTimeoutConstant then
    exit;

  FWriteTotalTimeoutConstant := v;

  if hCommFile <> 0 then
    _SetCommTimeout
end;

function TXZYComm.GetConnected: Boolean;
begin
  Result := (hCommFile <> 0); //
end;

function TXZYComm.GetVersion: string;
begin
  Result := XZY_COMPONENT_VERSION;
end;

procedure TXZYComm.SetVersion(const Val: string);
begin
  // empty write method, just needed to get it to show up in Object Inspector
end;

function TXZYComm.GetAuthor: AnsiString;
begin
  Result := XZY_AUTHOR;
end;

{ procedure TXZYComm.SetAuthor(const Val: string);
  begin
  // empty write method, just needed to get it to show up in Object Inspector
  end;
}
function TXZYComm.GetContact: string;
begin
  Result := XZY_CONTACT;
end;
{
  procedure TXZYComm.SetContact(const Val: string);
  begin
  // empty write method, just needed to get it to show up in Object Inspector
  end;
}

(* **************************************************************************** *)
// READ THREAD
(* **************************************************************************** *)

//
// PROCEDURE: TReadThread.Execute
//
// PURPOSE: This is the starting point for the Read Thread.
//
// PARAMETERS:
// None.
//
// RETURN VALUE:
// None.
//
// COMMENTS:
//
// The Read Thread uses overlapped ReadFile and sends any data
// read from the comm port to the Comm32Window.  This is
// eventually done through a PostMessage so that the Read Thread
// is never away from the comm port very long.  This also provides
// natural desynchronization between the Read thread and the UI.
//
// If the CloseEvent object is signaled, the Read Thread exits.
//
// Separating the Read and Write threads is natural for a application
// where there is no need for synchronization between
// reading and writing.  However, if there is such a need (for example,
// most file transfer algorithms synchronize the reading and writing),
// then it would make a lot more sense to have a single thread to handle
// both reading and writing.
//
//

procedure TReadThread.Execute;
var
 // szInputBuffer: array [0 .. INPUTBUFFERSIZE - 1] of Char;
  szInputBuffer: array of Char;
  nNumberOfBytesRead: DWORD;

  HandlesToWaitFor: array [0 .. 2] of THandle;
  dwHandleSignaled: DWORD;

  fdwEvtMask: DWORD;
  // Needed for overlapped I/O (ReadFile)
  overlappedRead: TOverlapped;

  // Needed for overlapped Comm Event handling.
  overlappedCommEvent: TOverlapped;
label
  EndReadThread;
begin
   SetLength(szInputBuffer, INPUTBUFFERSIZE);//新方法数组大小可变
   FillChar(overlappedRead, Sizeof(overlappedRead), 0);
  FillChar(overlappedCommEvent, Sizeof(overlappedCommEvent), 0);

  // Lets put an event in the Read overlapped structure.
  overlappedRead.hEvent := CreateEvent(nil, True, True, nil);
  if overlappedRead.hEvent = 0 then
  begin
    PostHangupCall;
    goto EndReadThread
  end;

  // And an event for the CommEvent overlapped structure.
  overlappedCommEvent.hEvent := CreateEvent(nil, True, True, nil);
  if overlappedCommEvent.hEvent = 0 then
  begin
    PostHangupCall();
    goto EndReadThread
  end;

  // We will be waiting on these objects.
  HandlesToWaitFor[0] := hCloseEvent;
  HandlesToWaitFor[1] := overlappedCommEvent.hEvent;
  HandlesToWaitFor[2] := overlappedRead.hEvent;

  // Setup CommEvent handling.

  // Set the comm mask so we receive error signals.

  if not SetCommMask(hCommFile, EV_ERR or EV_RING or EV_RLSD) then
  begin
    PostHangupCall;
    goto EndReadThread
  end;

  // Start waiting for CommEvents (Errors)
  if not SetupCommEvent(@overlappedCommEvent, fdwEvtMask) then
    goto EndReadThread;

  // Start waiting for Read events.
  if not SetupReadEvent(@overlappedRead, PAnsichar(szInputBuffer), INPUTBUFFERSIZE,
    // @szInputBuffer, INPUTBUFFERSIZE,
    nNumberOfBytesRead) then
    goto EndReadThread;

  // Keep looping until we break out.
  while True do
  begin
    // Wait until some event occurs (data to read; error; stopping).
    dwHandleSignaled := WaitForMultipleObjects(3, @HandlesToWaitFor, FALSE, INFINITE);

    // Which event occured?
    case dwHandleSignaled of
      WAIT_OBJECT_0: // Signal to end the thread.
        begin
          // Time to exit.
          goto EndReadThread
        end;

      WAIT_OBJECT_0 + 1: // CommEvent signaled.
        begin
          // Handle the CommEvent.
          if not HandleCommEvent(@overlappedCommEvent, fdwEvtMask, True) then
            goto EndReadThread;

          // Start waiting for the next CommEvent.
          if not SetupCommEvent(@overlappedCommEvent, fdwEvtMask) then
            goto EndReadThread
            { break;?? }
        end;

      WAIT_OBJECT_0 + 2: // Read Event signaled.
        begin
          // Get the new data!
          if not HandleReadEvent(@overlappedRead,
                                  PAnsichar(szInputBuffer),   // @szInputBuffer,
                                  INPUTBUFFERSIZE, nNumberOfBytesRead) then
            goto EndReadThread;

          // Wait for more new data.
          if not SetupReadEvent(@overlappedRead,
                                PAnsichar(szInputBuffer),
                                INPUTBUFFERSIZE,
                                      // @szInputBuffer, INPUTBUFFERSIZE,
                                nNumberOfBytesRead) then
            goto EndReadThread
            { break; }
        end;

      WAIT_FAILED: // Wait failed.  Shouldn't happen.
        begin
          PostHangupCall;
          goto EndReadThread
        end
    else // This case should never occur.
      begin
        PostHangupCall;
        goto EndReadThread
      end
    end { case dwHandleSignaled }
  end; { while True }

  // Time to clean up Read Thread.
EndReadThread:

  PurgeComm(hCommFile, PURGE_RXABORT + PURGE_RXCLEAR);
  CloseHandle(overlappedRead.hEvent);
  CloseHandle(overlappedCommEvent.hEvent)
end; { TReadThread.Execute }

//
// FUNCTION: SetupReadEvent(LPOVERLAPPED, LPSTR, DWORD, LPDWORD)
//
// PURPOSE: Sets up an overlapped ReadFile
//
// PARAMETERS:
// lpOverlappedRead      - address of overlapped structure to use.
// lpszInputBuffer       - Buffer to place incoming bytes.
// dwSizeofBuffer        - size of lpszInputBuffer.
// lpnNumberOfBytesRead  - address of DWORD to place the number of read bytes.
//
// RETURN VALUE:
// TRUE if able to successfully setup the ReadFile.  FALSE if there
// was a failure setting up or if the CloseEvent object was signaled.
//
// COMMENTS:
//
// This function is a helper function for the Read Thread.  This
// function sets up the overlapped ReadFile so that it can later
// be waited on (or more appropriatly, so the event in the overlapped
// structure can be waited upon).  If there is data waiting, it is
// handled and the next ReadFile is initiated.
// Another possible reason for returning FALSE is if the comm port
// is closed by the service provider.
//
//
//

function TReadThread.SetupReadEvent(lpOverlappedRead: POverlapped; lpszInputBuffer: LPSTR; dwSizeofBuffer: DWORD;
  var lpnNumberOfBytesRead: DWORD): Boolean;
var
  dwLastError: DWORD;
label
  StartSetupReadEvent;
begin
  Result := FALSE;

StartSetupReadEvent:

  // Make sure the CloseEvent hasn't been signaled yet.
  // Check is needed because this function is potentially recursive.
  if WAIT_TIMEOUT <> WaitForSingleObject(hCloseEvent, 0) then
    exit;

  // Start the overlapped ReadFile.
  if ReadFile(hCommFile, lpszInputBuffer^, dwSizeofBuffer, lpnNumberOfBytesRead, lpOverlappedRead) then
  begin
    // This would only happen if there was data waiting to be read.

    // Handle the data.
    if not HandleReadData(lpszInputBuffer, lpnNumberOfBytesRead) then
      exit;

    // Start waiting for more data.
    goto StartSetupReadEvent
  end;

  // ReadFile failed.  Expected because of overlapped I/O.
  dwLastError := GetLastError;

  // LastError was ERROR_IO_PENDING, as expected.
  if dwLastError = ERROR_IO_PENDING then
  begin
    Result := True;
    exit
  end;

  // Its possible for this error to occur if the
  // service provider has closed the port.  Time to end.
  if dwLastError = ERROR_INVALID_HANDLE then
    exit;

  // Unexpected error come here. No idea what could cause this to happen.
  PostHangupCall
end; { TReadThread.SetupReadEvent }

//
// FUNCTION: HandleReadData(LPCSTR, DWORD)
//
// PURPOSE: Deals with data after its been read from the comm file.
//
// PARAMETERS:
// lpszInputBuffer  - Buffer to place incoming bytes.
// dwSizeofBuffer   - size of lpszInputBuffer.
//
// RETURN VALUE:
// TRUE if able to successfully handle the data.
// FALSE if unable to allocate memory or handle the data.
//
// COMMENTS:
//
// This function is yet another helper function for the Read Thread.
// It LocalAlloc()s a buffer, copies the new data to this buffer and
// calls PostWriteToDisplayCtl to let the EditCtls module deal with
// the data.  Its assumed that PostWriteToDisplayCtl posts the message
// rather than dealing with it right away so that the Read Thread
// is free to get right back to waiting for data.  Its also assumed
// that the EditCtls module is responsible for LocalFree()ing the
// pointer that is passed on.
//
//

function TReadThread.HandleReadData(lpszInputBuffer: LPCSTR; dwSizeofBuffer: DWORD): Boolean;
var
  lpszPostedBytes: LPSTR;
begin
  Result := FALSE;

  // If we got data and didn't just time out empty...
  if dwSizeofBuffer <> 0 then
  begin
    // Do something with the bytes read.

    lpszPostedBytes := PAnsiChar(LocalAlloc(LPTR, dwSizeofBuffer + 1));

    if lpszPostedBytes = nil { NULL } then
    begin
      // Out of memory

      PostHangupCall;
      exit
    end;

    Move(lpszInputBuffer^, lpszPostedBytes^, dwSizeofBuffer);
    lpszPostedBytes[dwSizeofBuffer] := #0;

    Result := ReceiveData(lpszPostedBytes, dwSizeofBuffer)
  end
end; { TReadThread.HandleReadData }

//
// FUNCTION: HandleReadEvent(LPOVERLAPPED, LPSTR, DWORD, LPDWORD)
//
// PURPOSE: Retrieves and handles data when there is data ready.
//
// PARAMETERS:
// lpOverlappedRead      - address of overlapped structure to use.
// lpszInputBuffer       - Buffer to place incoming bytes.
// dwSizeofBuffer        - size of lpszInputBuffer.
// lpnNumberOfBytesRead  - address of DWORD to place the number of read bytes.
//
// RETURN VALUE:
// TRUE if able to successfully retrieve and handle the available data.
// FALSE if unable to retrieve or handle the data.
//
// COMMENTS:
//
// This function is another helper function for the Read Thread.  This
// is the function that is called when there is data available after
// an overlapped ReadFile has been setup.  It retrieves the data and
// handles it.
//
//

function TReadThread.HandleReadEvent(lpOverlappedRead: POverlapped; lpszInputBuffer: LPSTR; dwSizeofBuffer: DWORD;
  var lpnNumberOfBytesRead: DWORD): Boolean;
var
  dwLastError: DWORD;
begin
  Result := FALSE;

  if GetOverlappedResult(hCommFile, lpOverlappedRead^, lpnNumberOfBytesRead, FALSE) then
  begin
    Result := HandleReadData(lpszInputBuffer, lpnNumberOfBytesRead);
    exit
  end;

  // Error in GetOverlappedResult; handle it.

  dwLastError := GetLastError;

  // Its possible for this error to occur if the
  // service provider has closed the port.  Time to end.
  if dwLastError = ERROR_INVALID_HANDLE then
    exit;

  // Unexpected error come here. No idea what could cause this to happen.
  PostHangupCall
end; { TReadThread.HandleReadEvent }

//
// FUNCTION: SetupCommEvent(LPOVERLAPPED, LPDWORD)
//
// PURPOSE: Sets up the overlapped WaitCommEvent call.
//
// PARAMETERS:
// lpOverlappedCommEvent - Pointer to the overlapped structure to use.
// lpfdwEvtMask          - Pointer to DWORD to received Event data.
//
// RETURN VALUE:
// TRUE if able to successfully setup the WaitCommEvent.
// FALSE if unable to setup WaitCommEvent, unable to handle
// an existing outstanding event or if the CloseEvent has been signaled.
//
// COMMENTS:
//
// This function is a helper function for the Read Thread that sets up
// the WaitCommEvent so we can deal with comm events (like Comm errors)
// if they occur.
//
//

function TReadThread.SetupCommEvent(lpOverlappedCommEvent: POverlapped; var lpfdwEvtMask: DWORD): Boolean;
var
  dwLastError: DWORD;
label
  StartSetupCommEvent;
begin
  Result := FALSE;

StartSetupCommEvent:

  // Make sure the CloseEvent hasn't been signaled yet.
  // Check is needed because this function is potentially recursive.
  if WAIT_TIMEOUT <> WaitForSingleObject(hCloseEvent, 0) then
    exit;

  // Start waiting for Comm Errors.
  if WaitCommEvent(hCommFile, lpfdwEvtMask, lpOverlappedCommEvent) then
  begin
    // This could happen if there was an error waiting on the
    // comm port.  Lets try and handle it.

    if not HandleCommEvent(nil, lpfdwEvtMask, FALSE) then
    begin
      { ??? GetOverlappedResult does not handle "NIL" as defined by Borland }
      exit
    end;

    // What could cause infinite recursion at this point?
    goto StartSetupCommEvent
  end;

  // We expect ERROR_IO_PENDING returned from WaitCommEvent
  // because we are waiting with an overlapped structure.

  dwLastError := GetLastError;

  // LastError was ERROR_IO_PENDING, as expected.
  if dwLastError = ERROR_IO_PENDING then
  begin
    Result := True;
    exit
  end;

  // Its possible for this error to occur if the
  // service provider has closed the port.  Time to end.
  if dwLastError = ERROR_INVALID_HANDLE then
    exit;

  // Unexpected error. No idea what could cause this to happen.
  PostHangupCall
end; { TReadThread.SetupCommEvent }

//
// FUNCTION: HandleCommEvent(LPOVERLAPPED, LPDWORD, BOOL)
//
// PURPOSE: Handle an outstanding Comm Event.
//
// PARAMETERS:
// lpOverlappedCommEvent - Pointer to the overlapped structure to use.
// lpfdwEvtMask          - Pointer to DWORD to received Event data.
// fRetrieveEvent       - Flag to signal if the event needs to be
// retrieved, or has already been retrieved.
//
// RETURN VALUE:
// TRUE if able to handle a Comm Event.
// FALSE if unable to setup WaitCommEvent, unable to handle
// an existing outstanding event or if the CloseEvent has been signaled.
//
// COMMENTS:
//
// This function is a helper function for the Read Thread that (if
// fRetrieveEvent == TRUE) retrieves an outstanding CommEvent and
// deals with it.  The only event that should occur is an EV_ERR event,
// signalling that there has been an error on the comm port.
//
// Normally, comm errors would not be put into the normal data stream
// as this sample is demonstrating.  Putting it in a status bar would
// be more appropriate for a real application.
//
//

function TReadThread.HandleCommEvent(lpOverlappedCommEvent: POverlapped; var lpfdwEvtMask: DWORD;
  fRetrieveEvent: Boolean): Boolean;
var
  dwDummy: DWORD;
  dwErrors: DWORD;
  dwLastError: DWORD;
  dwModemEvent: DWORD;
begin
  Result := FALSE;

  // If this fails, it could be because the file was closed (and I/O is
  // finished) or because the overlapped I/O is still in progress.  In
  // either case (or any others) its a bug and return FALSE.
  if fRetrieveEvent then
  begin
    if not GetOverlappedResult(hCommFile, lpOverlappedCommEvent^, dwDummy, FALSE) then
    begin
      dwLastError := GetLastError;

      // Its possible for this error to occur if the
      // service provider has closed the port.  Time to end.
      if dwLastError = ERROR_INVALID_HANDLE then
        exit;

      PostHangupCall;
      exit
    end
  end;

  // Was the event an error?
  if (lpfdwEvtMask and EV_ERR) <> 0 then
  begin
    // Which error was it?
    if not ClearCommError(hCommFile, dwErrors, nil) then
    begin
      dwLastError := GetLastError;

      // Its possible for this error to occur if the
      // service provider has closed the port.  Time to end.
      if dwLastError = ERROR_INVALID_HANDLE then
        exit;

      PostHangupCall;
      exit
    end;

    // Its possible that multiple errors occured and were handled
    // in the last ClearCommError.  Because all errors were signaled
    // individually, but cleared all at once, pending comm events
    // can yield EV_ERR while dwErrors equals 0.  Ignore this event.

    if not ReceiveError(dwErrors) then
      exit;

    Result := True
  end;

  dwModemEvent := 0;

  // 添加的状态改变事件

  if ((lpfdwEvtMask and EV_RXCHAR) <> 0) then
    dwModemEvent := dwModemEvent or EV_RXCHAR;
  if ((lpfdwEvtMask and EV_RXFLAG) <> 0) then
    dwModemEvent := dwModemEvent or EV_RXFLAG;
  if ((lpfdwEvtMask and EV_TXEMPTY) <> 0) then
    dwModemEvent := dwModemEvent or EV_TXEMPTY;
  if ((lpfdwEvtMask and EV_CTS) <> 0) then
    dwModemEvent := dwModemEvent or EV_CTS;
  if ((lpfdwEvtMask and EV_DSR) <> 0) then
    dwModemEvent := dwModemEvent or EV_DSR;
  if ((lpfdwEvtMask and EV_RLSD) <> 0) then
    dwModemEvent := dwModemEvent or EV_RLSD;
  if ((lpfdwEvtMask and EV_BREAK) <> 0) then
    dwModemEvent := dwModemEvent or EV_BREAK;
  if ((lpfdwEvtMask and EV_ERR) <> 0) then
    dwModemEvent := dwModemEvent or EV_ERR;
  if ((lpfdwEvtMask and EV_RING) <> 0) then
    dwModemEvent := dwModemEvent or EV_RING;
  if ((lpfdwEvtMask and EV_PERR) <> 0) then
    dwModemEvent := dwModemEvent or EV_PERR;
  if ((lpfdwEvtMask and EV_RX80FULL) <> 0) then
    dwModemEvent := dwModemEvent or EV_RX80FULL;
  if ((lpfdwEvtMask and EV_EVENT1) <> 0) then
    dwModemEvent := dwModemEvent or EV_EVENT1;
  if ((lpfdwEvtMask and EV_EVENT2) <> 0) then
    dwModemEvent := dwModemEvent or EV_EVENT2;

  if dwModemEvent <> 0 then
  begin
    if not ModemStateChange(dwModemEvent) then
    begin
      Result := FALSE;
      exit
    end;

    Result := True
  end;

  if ((lpfdwEvtMask and EV_ERR) = 0) and (dwModemEvent = 0) then
  begin
    // Should not have gotten here.
    PostHangupCall
  end
end; { TReadThread.HandleCommEvent }

function TReadThread.ReceiveData(lpNewString: LPSTR; dwSizeofNewString: DWORD): BOOL;
begin
  Result := FALSE;

  if not PostMessage(hComm32Window, PWM_GOTCOMMDATA, WPARAM(dwSizeofNewString), LPARAM(lpNewString)) then
    PostHangupCall
  else
    Result := True
end;

function TReadThread.ReceiveError(EvtMask: DWORD): BOOL;
begin
  Result := FALSE;

  if not PostMessage(hComm32Window, PWM_RECEIVEERROR, 0, LPARAM(EvtMask)) then
    PostHangupCall
  else
    Result := True
end;

function TReadThread.ModemStateChange(ModemEvent: DWORD): BOOL;
begin
  Result := FALSE;

  if not PostMessage(hComm32Window, PWM_MODEMSTATECHANGE, 0, LPARAM(ModemEvent)) then
    PostHangupCall
  else
    Result := True
end;

procedure TReadThread.PostHangupCall;
begin
  PostMessage(hComm32Window, PWM_REQUESTHANGUP, 0, 0)
end;

(* **************************************************************************** *)
// WRITE THREAD
(* **************************************************************************** *)

//
// PROCEDURE: TWriteThread.Execute
//
// PURPOSE: The starting point for the Write thread.
//
// PARAMETERS:
// lpvParam - unused.
//
// RETURN VALUE:
// DWORD - unused.
//
// COMMENTS:
//
// The Write thread uses a PeekMessage loop to wait for a string to write,
// and when it gets one, it writes it to the Comm port.  If the CloseEvent
// object is signaled, then it exits.  The use of messages to tell the
// Write thread what to write provides a natural desynchronization between
// the UI and the Write thread.
//
//

procedure TWriteThread.Execute;
var
  msg: TMsg;
  dwHandleSignaled: DWORD;
  overlappedWrite: TOverlapped;
  CompleteOneWriteRequire: Boolean;
label
  EndWriteThread;
begin
  // Needed for overlapped I/O.
  FillChar(overlappedWrite, Sizeof(overlappedWrite), 0); { 0, 0, 0, 0, NULL }

  overlappedWrite.hEvent := CreateEvent(nil, True, True, nil);
  if overlappedWrite.hEvent = 0 then
  begin
    PostHangupCall;
    goto EndWriteThread
  end;

  CompleteOneWriteRequire := True;

  // This is the main loop.  Loop until we break out.
  while True do
  begin
    if not PeekMessage(msg, 0, 0, 0, PM_REMOVE) then
    begin
      // If there are no messages pending, wait for a message or
      // the CloseEvent.

      pFSendDataEmpty^ := True;

      if CompleteOneWriteRequire then
      begin
        if not PostMessage(hComm32Window, PWM_SENDDATAEMPTY, 0, 0) then
        begin
          PostHangupCall;
          goto EndWriteThread
        end
      end;

      CompleteOneWriteRequire := FALSE;

      dwHandleSignaled := MsgWaitForMultipleObjects(1, hCloseEvent, FALSE, INFINITE, QS_ALLINPUT);

      case dwHandleSignaled of
        WAIT_OBJECT_0: // CloseEvent signaled!
          begin
            // Time to exit.
            goto EndWriteThread
          end;

        WAIT_OBJECT_0 + 1: // New message was received.
          begin
            // Get the message that woke us up by looping again.
            Continue
          end;

        WAIT_FAILED: // Wait failed.  Shouldn't happen.
          begin
            PostHangupCall;
            goto EndWriteThread
          end

      else // This case should never occur.
        begin
          PostHangupCall;
          goto EndWriteThread
        end
      end
    end;

    // Make sure the CloseEvent isn't signaled while retrieving messages.
    if WAIT_TIMEOUT <> WaitForSingleObject(hCloseEvent, 0) then
      goto EndWriteThread;

    // Process the message.
    // This could happen if a dialog is created on this thread.
    // This doesn't occur in this sample, but might if modified.
    if msg.hwnd <> 0 { NULL } then
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
      Continue
    end;

    // Handle the message.
    case msg.message of
      PWM_COMMWRITE: // New string to write to Comm port.
        begin
          // Write the string to the comm port.  HandleWriteData
          // does not return until the whole string has been written,
          // an error occurs or until the CloseEvent is signaled.
          if not HandleWriteData(@overlappedWrite, PChar(msg.LPARAM), DWORD(msg.WPARAM)) then
          begin
            // If it failed, either we got a signal to end or there
            // really was a failure.

            LocalFree(HLOCAL(msg.LPARAM));
            goto EndWriteThread
          end;

          CompleteOneWriteRequire := True;
          // Data was sent in a LocalAlloc()d buffer.  Must free it.
          LocalFree(HLOCAL(msg.LPARAM));
          pFSendDataEmpty^ := True;
        end
    end
  end; { main loop }

  // Thats the end.  Now clean up.
EndWriteThread:

  PurgeComm(hCommFile, PURGE_TXABORT + PURGE_TXCLEAR);
  pFSendDataEmpty^ := True;
  CloseHandle(overlappedWrite.hEvent)
end; { TWriteThread.Execute }

//
// FUNCTION: HandleWriteData(LPOVERLAPPED, LPCSTR, DWORD)
//
// PURPOSE: Writes a given string to the comm file handle.
//
// PARAMETERS:
// lpOverlappedWrite  - Overlapped structure to use in WriteFile
// pDataToWrite       - String to write.
// dwNumberOfBytesToWrite - Length of String to write.
//
// RETURN VALUE:
// TRUE if all bytes were written.  False if there was a failure to
// write the whole string.
//
// COMMENTS:
//
// This function is a helper function for the Write Thread.  It
// is this call that actually writes a string to the comm file.
// Note that this call blocks and waits for the Write to complete
// or for the CloseEvent object to signal that the thread should end.
// Another possible reason for returning FALSE is if the comm port
// is closed by the service provider.
//
//

function TWriteThread.HandleWriteData(lpOverlappedWrite: POverlapped; pDataToWrite: PChar;
  dwNumberOfBytesToWrite: DWORD): Boolean;
var
  dwLastError,

    dwNumberOfBytesWritten, dwWhereToStartWriting,

    dwHandleSignaled: DWORD;
  HandlesToWaitFor: array [0 .. 1] of THandle;
begin
  Result := FALSE;

  dwNumberOfBytesWritten := 0;
  dwWhereToStartWriting := 0; // Start at the beginning.

  HandlesToWaitFor[0] := hCloseEvent;
  HandlesToWaitFor[1] := lpOverlappedWrite^.hEvent;

  // Keep looping until all characters have been written.
  repeat
    // Start the overlapped I/O.
    if not WriteFile(hCommFile, pDataToWrite[dwWhereToStartWriting], dwNumberOfBytesToWrite, dwNumberOfBytesWritten,
      lpOverlappedWrite) then
    begin
      // WriteFile failed.  Expected; lets handle it.
      dwLastError := GetLastError;

      // Its possible for this error to occur if the
      // service provider has closed the port.  Time to end.
      if dwLastError = ERROR_INVALID_HANDLE then
        exit;

      // Unexpected error.  No idea what.
      if dwLastError <> ERROR_IO_PENDING then
      begin
        PostHangupCall;
        exit
      end;

      // This is the expected ERROR_IO_PENDING case.

      // Wait for either overlapped I/O completion,
      // or for the CloseEvent to get signaled.
      dwHandleSignaled := WaitForMultipleObjects(2, @HandlesToWaitFor, FALSE, INFINITE);

      case dwHandleSignaled of
        WAIT_OBJECT_0: // CloseEvent signaled!
          begin
            // Time to exit.
            exit
          end;

        WAIT_OBJECT_0 + 1: // Wait finished.
          begin
            SetLastError(ERROR_SUCCESS);
            // Time to get the results of the WriteFile
            if not GetOverlappedResult(hCommFile, lpOverlappedWrite^, dwNumberOfBytesWritten, True) then
            begin
              dwLastError := GetLastError;

              // Its possible for this error to occur if the
              // service provider has closed the port.
              if dwLastError = ERROR_INVALID_HANDLE then
                exit;

              // No idea what could cause another error.
              PostHangupCall;
              exit
            end;
            if (dwNumberOfBytesToWrite) <> dwNumberOfBytesWritten then
            begin
              PostHangupCall;
              exit;
            end;

          end;

        WAIT_FAILED: // Wait failed.  Shouldn't happen.
          begin
            PostHangupCall;
            exit
          end

      else // This case should never occur.
        begin
          PostHangupCall;
          exit
        end
      end { case }
    end; { WriteFile failure }

    // Some data was written.  Make sure it all got written.
    if (dwNumberOfBytesToWrite = dwNumberOfBytesWritten) then
    begin
      Dec(dwNumberOfBytesToWrite, dwNumberOfBytesWritten);
      Inc(dwWhereToStartWriting, dwNumberOfBytesWritten)
    end
    else
    begin
      PostHangupCall;
      exit;
    end;

  until (dwNumberOfBytesToWrite <= 0); // Write the whole thing!

  // Wrote the whole string.
  Result := True
end; { TWriteThread.HandleWriteData }

procedure TWriteThread.PostHangupCall;
begin
  PostMessage(hComm32Window, PWM_REQUESTHANGUP, 0, 0)
end;

procedure Register;
begin
  RegisterComponents('XueDU', [TXZYComm]);
end;

end.
