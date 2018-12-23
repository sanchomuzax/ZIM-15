program zim15;

{
	ZIM-15 típusú ipari robotot szimuláló program.


				V 1.5 beta


	95.05.07.					Virág Attila
}

uses
	crt, graph, grdrvrs;		{Használt unit-ok megadása}

const

	mm=200;				{A valós adatok méretaránya}

	rad=pi/180;			{radiánra számolás konstansa}

	{Az axisok távolsága mm-ben megadva:}

	kar1=787/mm;
	kar2=600/mm;
	kar3=900/mm;
	kar4=112/mm;

	{Az axisok szög-határadatai fokban megadva:}

	max	: array	[1..6] of integer =(	165,
						40,
						20,
						135,
						250,
						180);

	min	: array	[1..6] of integer =(	-165,
						-40,
						-40,
						-135,
						-250,
						-180);

	bit	: array [1..6] of byte	= 	(1, 2, 4, 8, 16, 32);

var
	i	: integer;

	paletta,

	oldpaletta	: PaletteType;

	color	: word;

	zoom	: real;

	txt	: string;

	step,

	active	: byte;

	x0, y0	: real;					{bázis-frém a képen}

	new	: array [	1..3]	of real;	{rotált koordináták}

	rot	: array	[0..3,	0..3] 	of real;	{rotációs mátrix}

	ang	: array [	1..3]	of real;	{ROTATE bemenő szögei}

	kor	: array [	1..3]	of real;	{ROTATE bemenő k.-tái}

	look_ang: array [	1..3]	of real;	{nézőponti szögek}

	pnt	: array [0..6,	1..3]	of real;	{világkoord. adatok}

	dat	: array [0..6,	1..12,
				1..3]	of real;	{testek adatai}

	bod	: array [0..6,	1..12,
				1..3]	of integer;	{törlendő adatok}

	pic	: array	[	1..2]	of integer;	{képpont koordináták}

	eye	: array [	1..3]	of real;	{nézőpont orientáció}

	axi	: array	[	0..6]	of real;	{axis szögadatok}

PROCEDURE grafinit;			{Képernyőmeghajtók inicializálása}
var
	gdriver, gmode, errorcode	: integer;
begin
	IF registerbgidriver(@egaVga_driver) < 0 THEN halt(1);
	IF registerbgidriver(@herc_driver)   < 0 THEN halt(1);
	IF registerbgidriver(@cga_driver)    < 0 THEN halt(1);
	IF registerbgifont(@goth_font)       < 0 THEN halt(1);
	IF registerbgifont(@litt_font)       < 0 THEN halt(1);

	gdriver:=detect;

	InitGraph(gdriver, gmode,'');

	errorcode:= GraphResult;

	if errorcode<>grOK then
	begin
		writeln('Graphics error: ', GraphErrorMsg(errorcode));
		repeat until keypressed;
		closegraph;
		halt;
	end;
end;

PROCEDURE data;			{Testek adatainak beolvasása a ZIM#15.DAT-ból}
var
	f	: text;

	i, j, k	: byte;
begin
	assign (f,'zim#15.dat');

	{$I-} reset (f);

	if ioresult<>0 then
	begin
		setcolor(white);
		outtextxy(0,0,'The ZIM#15.DAT file not found.');
		halt;
	end;

	{$i+};

	for i:=0 to 5 do			{dat [i,j,k] változó feltöltése}
		for j:=1 to 12 do		{i - test sorszáma}
			for k:=1 to 3 do	{j - test pontszáma}
			begin			{k - x, y ill. z koordináta}
				read(f, dat [i,j,k]);
				dat [i,j,k]:=dat [i,j,k]/mm;
			end;
	close(f);

end;

PROCEDURE init;				{Változók szükséges értékadása}
var
	i : byte;
begin
	grafinit;			{Grafikus-mód beállítása}

	data;				{Test adatainak beolvasása}

	zoom:=20;			{nagyitási arány}
{
	cleardevice;
	setvisualpage(0);
	setactivepage(1);
	cleardevice;
	Active := 1;
}
	x0:=getmaxx/2;			{origó beállítása}
	y0:=getmaxy/3*2;

	eye [1]:=-6;			{Nézőponti torzítás beállítása}
	eye [2]:=30;
	eye [3]:=9;

	step:=5;			{lépésköz}

	for i:=0 to 6 do axi [i]:=0;	{axisok alapállapota 0 fok}

	for i:=1 to 3 do		{többi számolásban használt szög is}
	begin
		ang [i]:=0;
		look_ang [i]:=0;
	end;

	pnt [0,1]:=0;			{Ezeket elég egyszer kiszámolni}
	pnt [0,2]:=0;
	pnt [0,3]:=0;

	pnt [1,1]:=0;
	pnt [1,2]:=0;
	pnt [1,3]:=0;

	pnt [2,1]:=0;
	pnt [2,2]:=0;
	pnt [2,3]:=kar1;		{A többit a MOVE_TO-ban számolja}

end;

FUNCTION arcsin(x:real):real;		{Kimenő adat -pi/2 es +pi/2 közt }
var
	y	: real;
begin
	if x*x=1 then y:=pi/2
	else y:=arctan(x/sqrt(1-x*x));

	arcsin:=y;
end;

FUNCTION arccos(x:real):real;   	{Kimenő adat 0 és pi között}
var
	y	: real;
begin
	if x=0 then y:=pi/2
	else y:=arctan(sqrt(1-x*x)/x);

	if y<0 then y:=y+pi;

	arccos:=y;
end;

PROCEDURE rotate;		{Adott pont elforgatása a saját frémben. }
var				{Bemenő adatok: kor [1..3] és ang [1..3],}
	i : byte;		{ahol az 1. a pont koordinátája és a 2. a}
begin				{tengelyeken vett orientáció radiánban...}

	for i:= 1 to 3 do if ang [i] >= 2*pi then ang [i]:=ang [i]-2*pi;

	rot [1,1]:=	 cos(ang [2])
			*cos(ang [3]);

	rot [1,2]:=	-cos(ang [2])
			*sin(ang [3]);

	rot [1,3]:= 	 sin(ang [2]);

	rot [2,1]:= 	 cos(ang [1])
			*sin(ang [3])
			+sin(ang [1])
			*sin(ang [2])
			*cos(ang [3]);

	rot [2,2]:= 	 cos(ang [1])
			*cos(ang [3])
			-sin(ang [1])
			*sin(ang [2])
			*sin(ang [3]);

	rot [2,3]:=	-sin(ang [1])
			*cos(ang [2]);

	rot [3,1]:= 	 sin(ang [1])
			*sin(ang [3])
			-cos(ang [1])
			*sin(ang [2])
			*cos(ang [3]);

	rot [3,2]:=	 sin(ang [1])
			*cos(ang [3])
			+cos(ang [1])
			*sin(ang [2])
			*sin(ang [3]);

	rot [3,3]:= 	 cos(ang [1])
			*cos(ang [2]);

	for i:=1 to 3 do			{Kimeneti változó feltöltése}
	begin
		new [i]:=	rot [1,i]* kor [1]+
				rot [2,i]* kor [2]+
				rot [3,i]* kor [3];	{Az új térkoord.-ák}

		ang [i]:=0;				{Biztonsági törlés}
	end;

end;

PROCEDURE trans;	{Képkoordinátává számolás}
var
	pro	: real;					{Levetítési arány}

	i	: byte;

begin		

	for i:= 1 to 3 do ang [i]:=look_ang [i]+ang [i];{Nézőponti elfor-}

	rotate;						{gatás végrehajtása}

	if ((new [2]-eye [2])=0) then pro:=0		{Néző szeme}
	else pro:=new [2]/(new [2]-eye [2]);

 {Síkadatok:}

	pic [1]:=round(x0-zoom*(new [1]-pro*(new [1]-eye [1])));		{Képpont adatok}
	pic [2]:=round(y0-zoom*(new [3]-pro*(new [3]-eye [3])));

end;

FUNCTION limiter : byte;{Axisok határérték vizsgálata logikai kimenettel}
var
	i, j	: byte;
begin
	j:=0;

	for i:=1 to 6 do
	begin
		if (axi [i]>max[i]) then
		begin
			axi [i]:=max [i];

			j:=j+bit[i];
		end
		else
		if (axi [i]<min[i]) then
		begin
			axi [i]:=min [i];

			j:=j+bit[i];
		end;
	end;

	limiter:=j;
end;

PROCEDURE control_on (l :integer);	{Axisadatok kiiratása BE}
var
	i : byte;
begin
	setcolor(white);

	str(axi [l]:3:0,txt);
	outtextxy(0,l*10,txt);

	for i:=1 to 3 do
	begin
		str((look_ang [i]/rad):3:0,txt);
		outtextxy(0,100+i*10,txt);
	end;
end;

PROCEDURE control_off(l :integer);	{Axisadatok kiiratása KI}
var
	i : byte;

begin
	setcolor(black);

	outtextxy(0,l*10,'███████');

	for i:=1 to 3 do outtextxy(0,100+i*10,'███████');
end;

FUNCTION angel(a : byte; b : byte) : real;
begin			{Adott test -bemeneten 'a'- adott tengely}
	case a of	{körüli -bemeneten 'b'- forgatás kiszámítása.}

		0:
		begin
			case b of

				1:	angel:=	0;
				2:	angel:=	0;
				3:	angel:=	0;
			end;
		end;

		1:
		begin
			case b of

				1:	angel:=	0;
				2:	angel:=	0;
				3:	angel:=	axi [1]*rad;
			end;
		end;

		2:
		begin
			case b of

				1:	angel:=	-axi [2]*rad;
				2:	angel:=	0;
				3:	angel:=	axi [1]*rad;
			end;
		end;

		3:
		begin
			case b of

				1:	angel:=	-axi [2]*rad
						-axi [3]*rad;
				2:	angel:=	0;
				3:	angel:=	axi [1]*rad;
			end;
		end;

		4:
		begin
			case b of

				1:	angel:=	-axi [2]*rad
						-axi [3]*rad
						-axi [4]*rad;
				2:	angel:=	0;
				3:	angel:=	axi [1]*rad;
			end;
		end;

		5:
		begin
			case b of

				1:	angel:=	-axi [2]*rad
						-axi [3]*rad
						-axi [4]*rad;
				2:	angel:=	0;
				3:	angel:=	axi [1]*rad;
			end;
		end;

		6:
		begin
			case b of

				1:	angel:=	0;
				2:	angel:=	0;
				3:	angel:=	axi [6];
			end;
		end;
	end;
end;

PROCEDURE body(num : byte; color : word);
var				{Adott test -bemeneten 'num'- adott}
	i, j	: byte;		{színnel -bemeneten 'color'- történő
							kirajzolása}
begin

	if color<>black then	{Ha nem töröljük, nem számoljuk újra.}
	begin
		for i:=1 to 12 do
		begin
			if num=5 then
			begin
				for j:=1 to 3 do kor [j]:=dat [num,i,j];
				ang [1]:=0;
				ang [2]:= axi [5]*rad;
				ang [3]:=0;

				rotate;

				for j:=1 to 3 do kor [j]:=new [j];
			end
			else
				for j:=1 to 3 do kor [j]:=dat [num,i,j];

			for j:=1 to 3 do ang [j]:=angel(num,j);

			rotate;			{Test orientációja}

			for j:=1 to 3 do kor [j]:=pnt [num,j]+new [j];

			trans;			{Test helyvektora}

			bod [num,i,1]:=pic [1];	{Megjegyezni a törléshez}
			bod [num,i,2]:=pic [2];
		end;
	end;

	setcolor(color);

	moveto(bod [num,1,1], bod [num,1,2]);

	for i:=2 to 12 do lineto(bod [num,i,1], bod [num,i,2]);

	lineto(bod [num,1,1], bod [num,1,2]);

	lineto(bod [num,4,1], bod [num,4,2]);

	lineto(bod [num,9,1], bod [num,9,2]);

	lineto(bod [num,12,1], bod [num,12,2]);

	line(bod [num,2,1], bod [num,2,2], bod [num,11,1], bod [num,11,2]);

	line(bod [num,3,1], bod [num,3,2], bod [num,10,1], bod [num,10,2]);

	line(bod [num,5,1], bod [num,5,2], bod [num,8,1], bod [num,8,2]);

	line(bod [num,6,1], bod [num,6,2], bod [num,3,1], bod [num,3,2]);

	line(bod [num,7,1], bod [num,7,2], bod [num,10,1], bod [num,10,2]);

end;

{
PROCEDURE page;
begin
	setvisualpage(active);
	active:=1-active;
	setactivepage(active);
	cleardevice;
end;
}

PROCEDURE move_to(ax1, ax2, ax3, ax4, ax5, ax6: real);
var
	h	: real;					{ax2-től ax4-ig}

	f	: real;					{h & y teng. szoge}

	g	: real;					{y' teng.-re vetület}

	s	: real;					{ax2+ax3+ax4}

	sa	: real;					{sin(ax1)}

	ca	: real;					{cos(ax1)}

	i, j	: byte;

begin
	i:=limiter;			{Szélsőérték figyelése}

	ax1:=ax1*rad;			{Ãtszámolás radiánra, és }
	ax2:=ax2*rad+pi;		{alaphelyzet orientációja}
	ax3:=ax3*rad+pi/2;
	ax4:=ax4*rad+pi;
	ax5:=ax5*rad;
	ax6:=ax6*rad;

 {0. axis-pont:}
{
	pnt [0,1]:=0;
	pnt [0,2]:=0;
	pnt [0,3]:=0;
}
 {1. axis-pont:}
{
	pnt [1,1]:=0;
	pnt [1,2]:=0;
	pnt [1,3]:=0;
}
 {2. axis-pont:}
{
	pnt [2,1]:=0;
	pnt [2,2]:=0;
	pnt [2,3]:=kar1;
}
 {3. axis-pont:}

	g:=kar2*cos(ax2-pi/2);

	sa:=sin(ax1);
	ca:=cos(ax1);

	pnt [3,1]:=g*sa;
	pnt [3,2]:=g*ca;
	pnt [3,3]:=kar1+kar2*sin(ax2-pi/2);

 {4. axis-pont:}

	h:=sqrt(kar2*kar2+kar3*kar3-2*kar2*kar3*cos(ax3));
	f:=ax2-pi/2-arcsin(kar3/h*sin(ax3));

	pnt [4,1]:=h*sa*cos(f);
	pnt [4,2]:=h*ca*cos(f);
	pnt [4,3]:=kar1+h*sin(f);

 {5. axis-pont:}

	s:=ax2+ax3+ax4;

	pnt [5,1]:=sa*(h*cos(f)+kar4*sin(s));
	pnt [5,2]:=ca*(h*cos(f)+kar4*sin(s));
	pnt [5,3]:=kar1+h*sin(f)-kar4*cos(s);

{	cleardevice;}

	for i:=0 to 5 do body(i,black);

	for i:=0 to 5 do body(i,white);		{Íj test kirajzolása}

{	page;}
end;

PROCEDURE axis(a : byte; b : real);	{Az 'a' axis 'b'-vel történő változása}
var
	i : byte;
begin
	axi [a]:=axi [a]+b;

	{Orientáció megtartása végett:}

	if 	(axi [2]>= min[2]) and
		(axi [2]<= max[2]) and
		(axi [3]>= min[3]) and
		(axi [3]<= max[3]) and
		((a=2) or (a=3)) then axi [4]:=axi [4]-b;
		
	i:=limiter;

	move_to(axi [1],
		axi [2],
		axi [3],
		axi [4],
		axi [5],
		axi [6]);			{A szögek felvétele}
end;

PROCEDURE normal;				{Alapállapot felvétele}
var
	i, j	: byte;
begin
	x0:=getmaxx/2;
	y0:=getmaxy/3*2;

	zoom:=30;

	for i:=0 to 6 do axi [i]:=0;

	for i:=1 to 3 do look_ang [i]:=0;

	move_to(axi [1],
		axi [2],
		axi [3],
		axi [4],
		axi [5],
		axi [6]);
end;

PROCEDURE look(a : byte; b : real);	{Nézőpont változtatása}
begin
	look_ang [a]:=look_ang [a]+b;

	if look_ang [a] >= 2*pi then look_ang [a]:=look_ang [a]-2*pi;

	if look_ang [a] < 0 then look_ang [a]:=look_ang [a]+2*pi;

	move_to(axi [1],
		axi [2],
		axi [3],
		axi [4],
		axi [5],
		axi [6]);
end;

PROCEDURE inkey;			{Billenty▄zet figyelése}
var
	quit	: boolean;

	ch	: char;
begin
	quit:=false;

	repeat

		ch:=readkey;

		case ch of

			'q'	:	axis(1,+step);
			'w'	:	axis(2,+step);
			'e'	:	axis(3,+step);
			'r'	:	axis(4,+step);
			't'	:	axis(5,+step);

			'a'	:	axis(1,-step);
			's'	:	axis(2,-step);
			'd'	:	axis(3,-step);
			'f'	:	axis(4,-step);
			'g'	:	axis(5,-step);

			'['	:	look(1,+step*rad);
			']'	:	look(1,-step*rad);
			';'	:	look(2,+step*rad);
			#39	:	look(2,-step*rad);
			'-'	:	look(3,+step*rad);
			'='	:	look(3,-step*rad);

			'.'	:	begin
						zoom:=zoom+step/10;
						move_to(axi [1],
							axi [2],
							axi [3],
							axi [4],
							axi [5],
							axi [6]);
					end;

			','	:	begin
						zoom:=zoom-step/10;
						move_to(axi [1],
							axi [2],
							axi [3],
							axi [4],
							axi [5],
							axi [6]);
					end;

			#75	:       begin
						x0:=x0-step;
						if x0<-999 then x0:=-999;
						move_to(axi [1],
							axi [2],
							axi [3],
							axi [4],
							axi [5],
							axi [6]);
					end;

			#77	:	begin
						x0:=x0+step;
						if x0>999 then x0:=999;
						move_to(axi [1],
							axi [2],
							axi [3],
							axi [4],
							axi [5],
							axi [6]);
					end;

			#72	:	begin
						y0:=y0-step;
						if y0<-999 then y0:=-999;
						move_to(axi [1],
							axi [2],
							axi [3],
							axi [4],
							axi [5],
							axi [6]);
					end;

			#80	:	begin
						y0:=y0+step;
						if y0>999 then y0:=999;
						move_to(axi [1],
							axi [2],
							axi [3],
							axi [4],
							axi [5],
							axi [6]);
					end;

			'p'	:	begin
						step:=step+1;
						if step>45 then step:=45;
					end;
			'l'	:	begin
						step:=step-1;
						if step<1 then step:=1;
					end;

			'n'	:	normal;

			' '	:	quit:=true;
		end;

        until quit=true;		{Kiszállás SPACE-re}
end;

{****************************************************************************}

BEGIN
	init;

	normal;

	inkey;

	closegraph;
END.
