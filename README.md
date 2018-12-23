# ZIM-15 - 3D robot szimuláció

* **Készült:** Virág Attila, Budapest, KKMF, 1995-05-07
* **Nyelv:** Turbo Pascal 6.0
* **Megjegyzés:** Az alábbi leírás egy szakdolgozat része. Olyan külső hivatkozásokra, fájlokra és ábrákra hivatkozik, melyek a jelenlegi leírásnak nem részei. Ettől függetlenól a dokumentáció kellően részletes ahhoz, hogy érthető legyen a program működési elve.

## Gyakorlati megvalósítás:

A program kifejlesztésekor a következő problémákkal kellet szembenéznem:

1. A megrajzolt robot felépítésében és arányaiban összehasonlítható legyen a robotlaborunkban megtalálható **ZIM-15** típusú ipari robot manipulátor felépítésével. Az animáció sebessége a mozgás során a lehetőségekhez mérten érje el a valóságos robot mozgási sebességét.
2. A kirajzolás villogás-mentes legyen, és a megjelenő alakzatok elkülöníthetőek legyenek egymástól.
3. A nézőpontot változtatni lehessen, elérve a robot bármely pontját.
4. A megírt UNIT-ot illeszteni lehessen egy főprogramhoz, mely a robot további fejlesztését, mozgatását és programozását teszi lehetővé.
5. Legyen a megjelenítés felhasználó centrikus, kulturált megjelenésű.
6. A program jól dokumentált legyen könnyen fejleszthetősége érdekében.
Persze, még számos támpontot felírhattam volna, mely a program megírása során felmerült, de ezek vagy alapvető elvárások, vagy a már említett feladatok, célkitűzések közé illeszthetőek.

A feladat megtervezésekor figyelembe vettem a rendelkezésemre álló tudásanyagot, mely a robotok matematikájával és a számítógépes animációval foglalkozik. A kettő együttes figyelembevétele hozhatta csak létre a működő szoftvert.

## Problémák általános tárgyalása:

### 1. A megjelenítés módja

Elsőként felmerülő problémát a megjelenítés módja jelentette: Milyen formában jelenjen meg a szimulált robot a számítógép monitoron? Az ezzel foglalkozó irodalmakban egyértelmű válasz a kérdésre a háló-rajz volt. Tehát a megjelenésre kerülő alakzatokat, testeket kizárólag ezzel a módszerrel, vagyis téglatestekké történő leegyszerűsítésükkel kaphatjuk meg. A robotot mozgó alkatrészeire kellett képzeletben bontanom, s a lehetőségekhez mérten élethű mását kellett adnom azoknak.

A megjelenítés másik problémája a gyors grafika. Ha egy téglatestet és egy gömböt összehasonlítunk, akkor a következők mondhatóak el: Egy gömb végtelen sok ponttal jellemezhető, egyszerű eljárás megrajzolására (mely kielégítően gyors) a lapokra történő bontása. Tehát vonalakból történő megrajzolása. A téglatest esetében adottak a csúcspontok, melyeket összekötve megkapjuk az alakzat képét. Belátható, hogy a téglatest megrajzolása jóval rövidebb időt vesz igénybe, nem is beszélve arról, hogy mozgatni szeretnénk a testet.

A mozgatáshoz két fajta műveletet kell megkülönböztetnünk. Az egyik a forgatás, mely során a testet valamely pont körül adott irányba elforgatjuk; a másik a test eltolása, mely során a testet az egyik pontból a másikba toljuk. E probléma megoldásához Hartenberg-Denavit féle koordináta-rendszerek elve adta a megoldást, melyet már ismertettem. A konkrét megvalósítás leírása elött még beszélni szeretnék a megjelenítendő testekről.

Mindegyik alakzatot megterveztem saját koordinátarendszerében, melynek origója a test forgáspontja, vagyis az adott axis. Ezeket a paramétereket a `ZIM#15.DAT` file-ban tároltam; listája a mellékletben megtalálható. Mindegyik testet 12 pontal jellemeztem ugyanazzal a körüljárási iránnyal. Mivel 8 pont még nem adott megfelelő alakhűséget, a 14 pont pedig már igen csak lassította az eljárást, ezért állapodtam meg ennél a csúcs-számnál. Az adatok tárolási szisztémája a következő:

**Hét test sorrendre:** talapzat, robot test, felkar, alkar, kézfej, csukló, asztal- adatai között egy üres ENTER található. Az adatcsoportokon belül a 12 pont egymás után következik, és így egy sorban sorrendre az adott pont X, Y illetve Z koordinátái találhatóak meg.

A beolvasott adatokat egyszer töltöm fel egy tömbbe, melyekre a UNIT működése során mindig szükség van. Ezt a műveletet a PROCEDURE data látja el, mely hibaüzenetet ad, ha nem találta meg a működési könyvtárában a `ZIM#15.DAT` file-t.

### 2. Villogás kezelése

A villogás-mentesség, mint probléma, azért merült fel, mert a képfrissítés során használható eljárások nem mindegyike képes kihasználni az emberi szem tehetetlenségét.

Az egyik legegyszerűbb eljárás során letöröljük a képernyőt és utána kirajzoljuk az új alakzatot. Az alkalmazott módszer hibája -egyszerűségénél fogva- az, hogy meglehetősen villog a kirajzolt sorozatkép egy mozgatás során. Ha csak az előző alakzatot töröljük le saját inverzével, a mi esetünkben azért nem célravezető mert -utána számolva- 140! darab vonalat kell "végigzavarnunk" egymáson. Mivel a Pascal nyelv nem éppen a leggyorsabb vonalhúzó eljárással dolgozik, ezért ez sem a leg célravezetőbb eljárás a villogásmentesség érdekében.

Nagyfelbontású grafikus képernyők rendelkeznek azzal a tulajdonsággal, hogy bizonyos felbontás módokat használva egyszerre több munkalapot is használhatunk a video-memóriában. Ennek előnye, hogy a video-memóriát felhasználva jelentősen gyorsíthatjuk a megjelenítéseket. Egyik -esetünkben nem bevált- módszer, miszerint a nem látható munkalapon előre megrajzolt alakzatokat átmásoljuk, átvágjuk grafikus memóriacím olvasással a látható lapra. A **Turbo Pascal 6.0** nyelv igaz, rendelkezik e lehetőség megvalósítására alkalmas utasításokkal, de nem a leggyorsabbak azok, mivel nem közvetlen a memóriacímek közötti másolást teszi lehetővé, hanem egy memóriára irányított pointeren keresztül tudjuk átmásolni a látható munkalapra a képünket.

Viszont igen gyors eljárást biztosít a képernyők lapozása. Ekkor az aktív munkalapunkat nem látjuk. Erre rajzolunk, majd a művelet befejezésével átkapcsolunk, vagyis a két munkalapot megcseréljük. Igy az aktív munkalapunk lesz a látható, és a látható lesz az aktív. Teljesen villogás mentes ez az eljárás, de ügyelnünk, kell ügyes használatára, mely az egyéb kiírandó információk, adatok esetében más fajta gondolkodást igényel, mint azt eddig megszoktuk az egy lapos grafikáknál.

Tehát keresnem kellett egy olyan grafikus képernyőmódot, mely lehetővé teszi egynél több munkalap alkalmazását szinte mindegyik videokártyán. Végső döntésem a `VGAMed` felbontásra esett, mely 640x350 képernyőpont megjelenítését teszi lehetővé 16 színnel. Mindegyik VGA kártya ismeri ezt az üzemmódot, s mivel a program működéséhez minimum matematikai koprocesszorral ellátott gép-konfiguráció szükséges, ezért feltételeztem, minimum ilyen volumenű grafikus kártya megtalálható ezeken a számítógépeken. A színes üzemmód az alakzatok biztos elkülönítése érdekében szükséges.

### 3. A nézőpont változása

A nézőpont változtatása magával hozza annak lehetőségét, hogy a robotot igen közelről is megtekinthessük. Mivel a roboton kívül más adatokat is szeretnénk egyidőben a képernyőn megjeleníteni, ezért a szimulált alakzatot az előző kívánalom érdekében egy ablakban kell tartanunk, oly formán, hogy az ablakon kívülre ne rajzoljon a program vonalakta. A Pascal nyelv rendelkezik azzal a lehetőséggel, hogy az aktuális rajzoló ablak méretét mi határozzuk meg a pozíciójával együtt. Használatakor figyelembe kellett vennem a képernyőlapozással járó igényeket.

Egyébként e módszerrel biztosítottam azt is, hogy a megjelenő képernyőablakokba csak azok méretein belül lehessen írni, megkönnyítve a UNIT-ot felhasználó munkáját.

### 4. Mozgatás, kezelés

Programom lehetővé teszi, hogy UNIT-ként történő felhasználása során ne csupán a `PROCEDURE move_to` eljárást lehessen meghívni - mely adott axist adott fokhelyzetbe visz -, hanem a már említett ablakba írást is megkönnyítettem, és létrehoztam egy billentyűkről történő mozgatást, valamint nézőpont változtatást biztosító procedúrát is.

A forrásprogram jól dokumentált, áttekinthető szerkezetű, könnyen fejleszthető, átalakítható a későbbi felhasználást tekintve. Mindössze egy olyan UNIT-ot használtam fel, mely nincs meg az alap Pascal nyelvben. Ennek használatára csupán azért volt szükség, hogy a felhasznált képernyőmeghajtó file-okat ne kelljen a programmal együtt hordozni, hanem azokat .EXE állományba fordítás során kódolja bele programunkba, ezzel is leegyszerűsítve annak gyakorlati használatát. Listája a mellékletben megtalálható.

### 5. A felhasználói felület

A UNIT meghívásakor egy felhasználóbarát ablakrendszer jelenik meg. A nyugodt színekből felépített térhatású ablakokat optimálisan helyeztem el. A robotot megjelenítő ablakkeret a lehető legnagyobb méretű. Méretét azért nem érdemes a végtelenségig növelni, mert a megnövekedett vonalhosszak lassítják a szimulációs időt. A robot-ablak alatt biztosítottam egy keskeny ablakot, mely alkalmas a UNIT felhasználásakor a valós TEACH-BOX-on található display szimulálására, továbbá egyéb kommunikációs üzenetek megjelenítésére. A jobb oldalt megjelenő ablak alkalmas az axisok adatainak kiíratására, és egyéb információk megjelenítésére is.

A kirajzolt alakzatok jól elkülöníthető színárnyalatokkal jelennek meg, még MONO-VGA monitorokon is viszonylag jó e színösszeállítás. A megjelenő szövegek térhatásúak, kihasználva a grafikus üzemmód adta egyszerű lehetőségeket.

### 6. Dokumentáció

Már említettem a forrásnyelvű UNIT jól dokumentáltságát, áttekinthetőségét. Törekedtem arra az eshetőségre, hogy a gyakorlati felhasználás során felmerülő problémákat viszonylag nagy gond nélkül korrigálni lehessen. Egyszerűen átírható bármely más - hasonló felépítésű - manipulátor-szerkezetre is. Az 9. ábra mutatja a működéskor látható monitor-képet.

## A forrásprogram:

Nem építettem fel fontossági sorrendet az általam megírt eljárások között, így azok tárgyalását a forrásnyelvű programlista folytonossága alapján végzem.

Kimeneti változóként (globális változó) deklaráltam az axi:array of real tömböt. Ennek oka, hogy kilépve a UNIT-ból a tömb elemei megadják az axisok szögadatait fokban, lehetővé téve pontok felvételét. A konstans definíció is globálisan történik, esetleges külső felhasználás érdekében. Némelyik konstans külsőleg változtatható is (például testek színei, vagy az aktív lap sorszáma).

## Felhasználói eljárások:

A UNIT-felhasználó a következő procedurákat használhatja fel a UNIT kezelésekor (tárgyalásukra a későbbiekben térek ki):

~~~
PROCEDURE move_to(ax1, ax2, ax3, ax4, ax5, ax6 : real);
PROCEDURE inkey;
PROCEDURE normal;
PROCEDURE grafinit;
PROCEDURE screen_data(x, y : word; st: string);
PROCEDURE screen_user(x, y : word; st: string);
~~~

## Használt UNIT-ok:

UNIT-om mindössze a szabványos UNIT eljárásokat használja (uses Crt, Graph), kivéve a már említett uses `grdrvrs`-t, melynek forráslistája a mellékletben szintén megtalálható. Fordításához szükséges a megfelelő `.BGI` file-ok `.OBJ` file-á történő átkonvertálása.

Eljárások és függvények leírása:

`FUNCTION arcsin(x : real): real;`

és

`FUNCTION arccos(x : real): real;`

Mivel az alap Pascal nyelv nem rendelkezik `arcsin(x)` és `arccos(x)` szögfüggvényekkel, ezért létrehoztam ezeket ismerve a trigonometriából a ezek helyettesíthetőségét, számítási módjait. Ez a két függvény majd az igen nagy sebességet igénylő számításoknál lesz fontos, ezért törekedtem lehető legegyszerűbb, leggyorsabb megvalósításukra. Igy deklarálásuk során - és máshol is a programban - próbáltam elkerülni a fontosabb részeknél az `if...then...else` utasítást. Mint látható, tiszta logikai műveletekkel oldottam meg kiváltásukat, mely a UNIT lefordítása során rövidebb gépikódot kap, mint egy `if...then...else` szerkezet, tehát gyorsabb lesz annak végrehajtása is. Egyébként csak az `arcsin(x)` függvényt használja a UNIT.

A szögfüggvények tárgyalására még a fejezet végén visszatérek...

### `PROCEDURE ubar(xa, ya, xb, yb, mode:word);`

A monitoron megjelenő ablakok térhatásúak. Ezt egyszerű téglalap kirajzolással értem el, úgy hogy a téglalap széleihez vonalakat húztam különböző (világosabb és sötétebb) színekkel, így érve el azok kiemelkedését, vagy belemélyülését a képernyőbe.

Bemeneti változóként deklaráltam a doboz két szélső koordinátáját, és egy `mode:word` változót is. Ennek állapotai a következők:

`0`: a fény a bal felső irányban törik meg az ablakon, tehát kiemelkedik,

`1`: a fény a jobb alsó irányban törik meg az ablakon, tehát besüllyed.

Az árnyékhatást dupla vonalakkal értem el, így azok megnyerőbbek.

### `PROCEDURE door(xa,ya,xb,yb:word);`

A `PROCEDURE bar` eljárást felhasználva egy kerettel rendelkező ablakot rajzol meg e procedúra.

### `PROCEDURE print(x,y:word;st:string);`

A látvány érdekében kibővítettem a Pascal-ból jól ismert uses Graph-ból `outtextxy` eljárását oly módon, hogy az adott koordinátára az adott sztringet 3D hatással árnyékolva írja ki. A régi szöveget egyszerűen kitörli maga alól az új kiírandó sztring.

### `PROCEDURE monitor(a : byte);`

A teljes képernyőt ez az eljárás jeleníti meg. Az ablakok egymás mellé illeszkednek. Méreteik a robotszimulációs munkaterétől függenek `(x1, x2, y1, y2 : word)`.

Továbbá a kezdeti információ kiírását is ez a procedúra végzi. Bementi változója az aktív munkaablak számát adja meg.

### `PROCEDURE screen_user(x,y:word;st:string);`

Az alsó ablak kezelését teszi lehetővé. A bemenő koordináták az ablak koordinátáiban értendőek. Nem lehet az ablakon kívülre írni, így nem sérül meg a keretek grafikája sem.

Az `st : string` bemeneti változó tartalmazza a kiírandó szöveget is.

### `PROCEDURE screen_data(x,y:word;st:string);`

A jobb oldali ablak kezelését teszi lehetővé. A bemenő koordináták az ablak koordinátáiban értendőek. Nem lehet az ablakon kívülre írni, így nem sérül meg a keretek grafikája sem. Az `st : string` bemeneti változó tartalmazza a kiírandó szöveget is.

### `PROCEDURE info;`

Lehetővé teszi az éppen aktuális szögadatok kiíratását a jobb oldali képernyőre. Ha a display : booleanb változó értéke false, akkor a frissítése elmarad, mely jelentősen gyorsítja a szimuláció idejét.

### `PROCEDURE grafinit;`

A grafikus képernyő inicializálását végzi el. Beállítja a `VGAMed` grafikus módot, valamint mindkét munkalapot letörli és a _0. lapot_ teszi láthatóvá, és meghívja a `PROCEDURE monitor` eljárást mindkét lapra.

### `PROCEDURE data;`

A robot testadatainak, testkoordinátáinak behívását végzi a `ZIM#15.DAT` file-ból. Ha nem találja, hibaüzenettel tér vissza. További hibafigyelést nem végez, így az adattok megváltoztatásakor különös figyelemmel kell eljárni. A 10. ábra nagyítva ábrázolja az egyes testeket.

Továbbá feltölti a `dat : real` tömböt és átszámolja rögtön milliméterből pontkoordinátákká az `mm` konstans segítségével.

### `PROCEDURE init;`

A változók kiindulási értékeit állítja be, és meghívja a `PROCEDURE grafinit` valamint a `PROCEDURE data` eljáráskat.

### `PROCEDURE rotate;`

Ez a procedúra egy olyan matematikai eljárást tesz lehetővé, melynek során egy derékszögű koordinátarendszerben megadott pontot tetszőleges szöggel elforgathatunk a saját koordinátarendszerének három tengelye mentén.

Bemeneteként fel kell tölteni a `kor : real` tömböt a pont x, y illetve z koordinátáival, illetve az `ang : real` tömböt az x, y illetve z tengelyek körüli elforgatások szögértékeivel, melyek _radiánban_ értendőek. Az új térkoordinátákat a `new : real` tömbben kapjuk meg. Az `ang : real` értékei lenullázódnak, hogy a köztes műveletek során ne okozzanak számolási problémákat.

Megjegyzem, hogy e forgató eljárás a **Hartenberg-Denavit módszer**ekből jól ismert mátrix műveletekre épül. Általam használt formája megtalálható az [1]-ben.

### `PROCEDURE move_to(ax1, ax2, ax3, ax4, ax5, ax6: real);`

A UNIT tulajdonképpeni lelke ez a procedúra. Bemeneti -fokban megadott- axisadatok, melyek a robot szinkronállapotára vonatkoztatva vannak megadva.

Itt történik az axis végpontok koordinátáinak kiszámolása a szögadatok és a kar hosszainak -melyeket konstansként deklaráltam- segítségével. Tisztán a robot felépítésére alapoztam az eljárást, tehát háromszögek éleinek és szögeinek ismeretében írtam fel a kar végpontjainak egyenleteit. A pontok adatait a pnt : real tömbben tároltam. Csak azokat számolja a program mindig újra, melyek paraméterei változhattak a meghívás elött, így a többi a `PROCEDURE init`-ben található meg. A tömb első indexe a test sorszámát, míg a második az x, y illetve z koordinátájára történő hivatkozást volt hivatott jelölni.

Itt kitérek az egyik legfontosabbra, mely a programom megírása során az egyik legnagyobb problémát jelentette. Az axis végpontjainak kiszámítása ugyanis nem volt a legegyszerűbb. Több fajta módszert megvizsgálva ez az eljárás tűnt a legegyszerűbbnek és legcélravezetőbbnek.

A robotot leegyszerűsítettem a 11. ábra szerint, és felírtam az ismert változókat, paramétereket, továbbá kijelöltem azokat a változókat, melyekre szükségem van a testek helyzetének meghatározásához. Mint már említésre került, nem mindig célravezető az ízületi változókból és térkoordinátákból felírható mátrixokkal történő számolás, ha figyelembe veszük azok bonyolultságát és számolási algoritmusuk lassúságát. Igy a háromszögek arányosságából, koszinusz-tételekből és egyéb szabályok alapján megkapható ugyanaz a végeredmény. Az általam kapott végeredményt a programlista tartalmazza.

Ezen adatok kiszámítása után kijelölöm a rajzolás munkaterét a setviewport utasítással, így nem rajzol az ablakon kívülre feleslegesen. Az aktív munkalap nem látható, ekkor a régi rajz törölhető.

Az egymásba ágyazott `for...to...do` ciklusokkal számolom ki a 7 darab test pontjainak képernyő koordinátáit. Kövessük nyomon egy pont kiszámításának menetét:

A `kor : real` tömböt feltöltöm a `dat : real` tömb megfelelő elemeivel. Figyelembe kell venni, hogy az ötödik axis pontjait számítjuk e vagy sem. Erre azért van szükség, mert nem mindegy a forgatás sorrendje ennél az axisnál. Ha elforgattuk y tengely mentén, csak akkor lehetséges a további orientáció beállítása. A további elforgatásokat három egyenlettel az összes testre megoldottam. A már említett `if...then..else` szerkezet lassúságát logikai műveletekkel váltottam ki.

A saját frame-jükben elforgatott testeket eltolom az axis végpontba adott helyvektorral, melyet már kiszámoltam a bázis frame-re vonatkoztatva. Majd az eltolt pontokat a nézőponti szögekkel is orientálni kell.

Ezek után jön a képkoordinátákká történő átszámolás. Mivel én a 3D grafikát választottam, ezért nem lehetett figyelmen kívül hagynom a térhatású képek sajátosságait, miszerint a nézőponthoz közelebb eső tárgyak nagyobbak, míg a távolabbiak kisebbek. E probléma megoldására a pro:real változóban megadott művelettel ezt figyelembe vettem. Az eye:real tömb elemei határozzák meg a nézőponti torzítás mértékét (lásd. [1]). Ezután következik a síkra leképzés.

Itt kell megjegyeznem, hogy az általam használt képernyő-felbontásnál a képpixelek nem négyzet alakúak. Ezért az y képkoordinátát le kellett osztanom 1.39-cel, mely arányossá teszi a robotot, és nem nyújtja el. A `bod : integer` tömbbe tárolom el az adott test adott pontjának x és y képkoordinátáját.

Az előre `boxcolor : word` tömben definiált színbeállítások szerint történik az adott alakzat színbeállítása.

A pontokat adott körüljárási irányban összehúzom. Ahol lehetett, ott elkerültem a `for...to...do` ciklusok használatát, hogy ezzel is gyorsítsam a program működését. Igaz a program hossza így növekedett, de érezhetően meggyorsul a felesleges műveletek elhagyásával a UNIT futása. A megrajzolt kép (12. ábra) még ekkor nem látható. Ha a `display : boolean` értéke true, akkor megtörténik az axis-információk kiíratása, frissítése a jobb oldali ablakban. Ezek után lapcsere történik, a munkalapok felcserélődnek. A felhasználó ebből csak annyit lát, hogy a robot megmozdul adott szöggel adott irányba.

### `PROCEDURE axis(a : byte; b : real);`

Ez az eljárás az adott számú axist adott szögeltéréssel mozdítja el, figyelembe véve az orientáció megtartását. Itt történik véghelyzet figyelés is; ha az adott axis véghelyzetbe kerül, nem lehetséges azt tovább mozdítani. Felhasználása a `PROCEDURE inkey`-ben történik.

### `PROCEDURE upper;`

E procedúra nem került felhasználásra, csupán annak lehetőségét mutatja be, hogy hogyan lehetséges a robotot látványosan felnagyítani, és így optimális képkitöltést beállítani. Meghívásakor a robot a végtelenből közelít felénk a `zoom : real` nagyítási paraméter növelésével, mindaddig, míg bármely pontja az alakzatnak a megadott határokat el nem éri.

### `PROCEDURE normal;`

A kép-robot felveszi alapállapotát. Az axisok 0 fok értéket vesznek fel, a nagyítás és nézőponti paraméterek is normalizálódnak, felveszik optimális értékeiket.

### `PROCEDURE look(a : byte; b : real);`

A nézőpont változtatása érhető el vele. Az első bemeneti paraméter a bázis-frame adott tengelyét jelöli, a második változó pedig az adott lépésközzel történő elforgatást adja meg radiánban. Használata a `PROCEDURE inkey`-ben történik. A 13. és 14. ábra egy közelebbi és egy távolabbi helyzetben ábrázolja a szimulált robotot.

### `PROCEDURE inkey;`

Meghívása során kiíródnak az aktuális információk, és a billentyűzet figyelése után adott műveletek meghívása történik. Lehetőséget ad az _5+1 axis_ tetszőleges mozgatására, a nézőpont megváltoztatására, ráközelítésre, fel-le-jobbra-balra történő mozgatásra, valamint az adatok frissítésének kikapcsolására, és a lépésköz - vagy más néven mozgatási sebesség - változtatására, mely az összes mozgatásra globális paraméterként szolgál. Visszatérés az eljárásból a SPACE gomb leütése után következik be.

## Fordítás, meghívás és kilépés:

A forrásnyelvű program **Turbo Pascal 6.0** programozási nyelven íródott. A megfelelő működési sebesség eléréséhez minimum 386DX 40MHz alaplap szükséges 8087 numerikus koprocesszorral együtt. Lefordításakor (koprocesszor esetén) használjuk az `{$N+}` kapcsolót! Ha nincs 8087-ünk, használjuk a `{$E+}` direktívát a processzor emulálására. 

A UNIT oly módon lett kialakítva, hogy a hozzá írt Pascal programok futtatásukkor elsőként -és csak egyszer- végrehajtják a `PROCEDURE init` és `PROCEDURE normal` eljárásokat, így rögtön megjelenik a UNIT felhasználói felülete. Ha felhasználjuk e UNIT-ot, akkor a `CloseGraph` utasítás hatására visszatérhetünk a karakteres üzemmódba. A `PROCEDURE graf-init` meghívásakor pedig újból a UNIT felülete tér vissza az éppen aktuális szögértékekkel.

## Megjegyzés:

Az inverz szögfüggvényeknél említettem, hogy visszatérek tárgyalásukra. Ennek oka az, hogy a program dokumentálása közben felmerült egy újabb ötlet a matematikai eljárások gyorsítására. A számítógép a szögfüggvényeket minden egyes meghívásukkor újra és újra kiszámolja _real_ változónak megadott pontossággal, ami igen csak lassítja a számolási algoritmusokat. Esetünkben elég lenne - például a szinusz függvényt vizsgálva -, ha a 360 fokos tartományban mindössze 1 fokonként kiszámolnánk egy tömbbe (`fsin [0..360]`) a szögek szinuszait. Ez természetesen a program elején, mindössze egyszer történne meg. Mivel egy változóból az értékolvasás jóval gyorsabb, mint egy bonyolult matematikai művelet (például szögfüggvények sorokkal történő közelítése), ezért nem lehet figyelmen kívül hagyni e módszer lehetőségét sem. Egyetlen hátulütője ennek a megoldásnak a nagy memóriaigény...

A program dokumentálása után készítettem el a gyorsabb, ezeket a programozási trükköket kihasználó UNIT-ot. Létrehoztam egy `fsin : real`, és egy `fcos : real` tömböt, mely fokonként tartalmazza -720 fok és +720 fok közötti szögek szinuszát, illetve koszinuszát. A program már numerikus koprocesszor nélkül is elég szép sebességgel működik ezzel a megoldással.

Viszont az `arkusz` függvények kiváltását nem találtam célravezetőnek, mivel a megfelelő pontosság eléréséhez nem volt elegendő a változóknak összesen fenttartott 64 KByte memóriahely. Továbbá, ha figyelembe vesszük, hogy mindössze csak az `arcsin(x)` függvényre, és mindössze egyszer lett volna szükségem egy mozzanat kiszámolása során, akkor belátható, hogy jelentős sebesség változást nem okoz a művelet kiváltása. A gyakorlat is bebizonyította igazam, így "mindössze" a már említett szögfüggvények terén történt változtatás.

Az 1 fokos pontosság éppen kielégítő. A jó szemű megfigyelő észre veheti, hogy már ekkor is egy nagyon kis torzulás létrejön, ha a pontok egymáshoz közeliek. Hibaszámítást lehetne végezni például a forgató procedurára, melyben igen sok a szögekkel végzett művelet; de ez túllépné szakdolgozatom kereteit.

További sebességnövekedést gyorsabb grafikuskártyával (minimum TRIDENT 8900), vagy a már említett Assembly rutinokkal érhetnénk el (például saját vonalhúzó rutinnal).

A UNIT folyamatosan bővül, alakul a célszerű felhasználást segítve. Teljes dokumentálása ilyen formán nem lehetséges a szakdolgozat beadási határidejére való tekintettel.
