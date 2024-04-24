# XZYComm

#### Description
Serial communication control for delphi

#### Software Architecture
The serial communication component is modified from the SPCOMM serial communication component of Small-Pig Team (China Taiwan)

The latest version V3.3 supports delphi11，Delphi12

#### Installation

1. Configure XZYComm.inc to adapt to the delphi version
2. Depending on the compiled version, modify! AdminBuild_XZYComm.cmd line 108 in the file "set VCLVersion=29"
2. Run !AdminBuild_XZYComm.cmd to compile
3. Start delphi and mount the compiled bpl file

#### Version
  - Version 2.51 2002/3/15
    > Rewritten based on Spcomm 2.5.
  - Version 2.6 2008/3/5
    > Add Eof char, Evt char;
  - Version 2.01 2015/5/13
    > Fix the bug that Com10 and above cannot be opened
  - Version 2.02 2018/6/16
    > Correct the error message
  - Version 3.0 2020/6/12
    > Compatible with Delphi 10.3
    > Upgrade to delphi 10.3.3
    > Fix Parity setting bug, szInputBuffer is changed to @szInputBuffer;
  - Version 3.01 2020/6/16
    > Modify some error from source code, and can send data without
    > lose any byte.Modified some error about the SENDEMPTY property,
    > so it can be checked in applicaiton.
  - Version 3.1 2020/6/17
    > Add new property Connected;
    > Compatible with Delphi XE and above, Char changed to AnsiChar
  - Version 3.3 2021/11/17
    > Compatible with Delphi 11