#!/bin/bash

# place it in /etc/profile.d/

name=$(whoami)
host=$(uname -a)

banner=$(cat << EOF
	 WXOdc,,,:okKW
      WKxl:,'',;:cccldk0XW                  WELCOME TO
  WX00d;''',:okKKOo;,'',:okKN
Kkl:ll,';cdOXW   WN0xl:,''';cd0W
:,';oookKN           WXOdc;''';kW                                                                                                                                     W
''':ONW                 WN0o:,'lX  NkdxxxxxxkOXW  Xkdxxxxxxxx0W WKkddoodxOXWNkdkN   KxdxK    NkdkN  W0xdx0W    W0xddddddxxOXW W0ddx0W   WKxddOW  WXOxxxxxxOKW    NOkxxxxxkXW
'''c0                     NxclcoX  Kcck00K00xll0W 0:ck0000000XWWk:;lxkkd:;oKNd,:OW Nd,,,oN  WO;,dN  Kc,;,c0    Nd,,ldxxdo:,cOWNd,,,cK   Kl,,,oN Nklok0KK0OdcdX  XockKXXKOooK
'''cK                     No,;ckN  KclX     Wx;xW 0:oX         Nd,;xXNWWXKKNW0:,oN 0:;c;:0W No,:0  Xo,lOo,oX   Nd,;kW   Wk;,oNNd,:c;dN Nx;::,oNWk:dN      Wk:oX Kcc0NW   WXW
'''c0                     No'',dN  Kcck0000OxloKW 0::dxxxxxxON WKd:;:cldxOXW Nd,:0Nd,oOo,dKN0:,dN Nx;:OW0:,xN  Nd,,lkkkkxc,cOWNo,cxc:OW0:cxl,oNXo:0        Xl:0 W0dooddxk0NW
:,'c0                     No,''lX  Kc:dxxxo;cON   0:ck000000KW   WXKOkxo:,:kW 0:,dOc;kWk;cdOd,c0 WO:':dkdc':OW Nd,,:llc;';dXW No,l0x;lOo;x0l,oNXo:O        Xlc0   WNX0OkdllOW
lc;c0                     No'''lX  KclX   NxcdX   0coX         XOxONW  WO:'lX Nd,:c;lX Kl;;c:,dN Kl,:oddoo:,cK Nd,;kWWNk:,lKW Nd,lKXo;:;lXXl'oNWO:oKW     Nx:dNWK0X     W0:lX
,:cdK                     No'''lX  KclX    WOcoKW 0:cxOOOOOOO0NNx:;cdxdoc;cOW  0c'';kW Wk;'''cK Nd,:OW   W0:,oXNd,;k   W0c,cOWNo,lKW0:':OWXl,oN WOolxO00OxolkN W0llxO000kolkW
,',;lx0NW              NKOkl'',oN  NO0N     WKk0W NOxkkkkkkkkON WXOkxxxxk0NW   W0xxON   XOxxx0W NOx0N     W0kOXWKkkX     XkxONW0k0N W0k0W N0x0W   NKOkxxxk0NW   WN0kkxxkk0XW
xc,''',cdOKW       WXOdc;cl:,;oK
WX0xl;,'',;lx0NWNKko:,'';oxdOXW
    NKkocc::clddl;,'',;lONWW                ${name}
       WWX0dc;,'',,cdOXW
           NOl;,;cxXW                       ${host}

EOF
)

echo ""
echo "${banner}"
echo ""

