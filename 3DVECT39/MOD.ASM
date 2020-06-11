;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; MOD playback routine using 'GUS' lowlevel GUS & SB routines.
;
; Written by: John McCarthy
;             1316 Redwood Lane
;             Pickering, Ontario.
;             Canada, Earth, Milky Way (for those out-of-towners)
;             L1X 1C5
;
; Most of the main MOD effects are implemented, Vibrato, Tone sliding, Volume
; Sliding and such.  I seem to have a little problem with the sample loop.  I
; dont think I am loading the loop start and end pointers correctly.  (I have
; one mod that clicks annoyingly when playing a certin sample.  But  I  can't
; figure out why the other players I have don't click  when  this  sample  is
; played).  All looped samples are bi-directionally looped.  This  means that
; intruments sound great when looped, but voices get really screwed up.   You
; can change the loop_bi option in the sample  loading  routine.   Anyway,  I
; coded this thing in about 3 days so don't expect too much.
;
; 4,6 or 8 channel mods are supported.  But only "31 sample" mods can be
; played. Sorry - 15 sample mods not supported.
;
; Send Me a Postcard!
;
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

         .386p
code32   segment para public use32
         assume cs:code32, ds:code32

include  pmode.ext
include  gus.ext
include  irq.ext

public   _mod_init, _mod_uninit, _mod_load, _mod_play, _mod_stop, _mod_sample_play
public   _ordmod, _currow

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; DATA
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

; memory usage
;
; samples first:  (496 bytes)
;  length    dd
;  volume    dd   ; xxqqyyzz  qq = loop yes/no, zz = fine tune, yy = volume
;  loopstart dd
;  loopend   dd
;
; pattern order   (128 bytes)
;
;  db 128 dup (0)
;
; patterns
;
;  db channels*4*64

; Mod Pattern Info
;
;7654-3210 7654-3210 7654-3210 7654-3210
;wwww xxxxxxxxxxxxxx yyyy zzzzzzzzzzzzzz
;
;    wwwwyyyy (8 bits) is the sample for this channel/division (0 = no sample)
;xxxxxxxxxxxx (12 bits) is the sample's period (or effect parameter)
;zzzzzzzzzzzz (12 bits) is the effect for this channel/division

sambase  dd 0                               ; offset to sample data table
ordbase  dd 0                               ; offset to pattern order
patterns dd 0                               ; offset to patterns
patternend dd 0
whendone dd _ret                            ; routine to call when done module

_ordmod  db 0                               ; current order position (0-127 tables)
_currow  db 0                               ; current row (0-63) set, but never used
ordwidth dd 0                               ; 4,6 or 8
ordsize  db 0                               ; number of patterns
currow   dd 0                               ; order position row (offset in memory)
lastord  db 0                               ; when does song end

panloc   db 0                               ; base of ping-pong pan
tempo    db 0
tempoc   db 0
rowleft  db 0                               ; coloumns left before next order
break    db 0

cursamp  db 8 dup (0)                       ; sample for channel
modvol   db 8 dup (0)                       ; volume for channel (0-64)
effect   dw 8 dup (0)                       ; channel effect
portto   dw 8 dup (0)
period   dw 8 dup (0)                       ; current sample period
portparm db 8 dup (0)
vibpos   db 8 dup (0)
vibparm  db 8 dup (0)
arp      dd 16 dup (0)                      ; dw index,arp,arp,arp


         align 4

whichmodcontrol dd -1                       ; irq timing control number

pantbl   db 3,3,3,4,4,5,6,7,8,9,10,11,11,12,12,12
         db 12,12,12,11,11,10,9,8,7,6,5,4,4,3,3,3
         db 3,3,3,4,4,5,6,7,8,9,10,11,11,12,12,12
         db 12,12,12,11,11,10,9,8,7,6,5,4,4,3,3,3
         db 3,3,3,4,4,5,6,7,8,9,10,11,11,12,12,12
         db 12,12,12,11,11,10,9,8,7,6,5,4,4,3,3,3
         db 3,3,3,4,4,5,6,7,8,9,10,11,11,12,12,12
         db 12,12,12,11,11,10,9,8,7,6,5,4

sintable db 0,25,50,74,98,120,142,162,180,197,212,225
         db 236,244,250,254,255,254,250,244,236,225
         db 212,197,180,162,142,120,98,74,50,25

pitchtbl dw 828 dup (0)

;ax = 5.6865
;
;FOR z = 5 - 1 / 12 / 16 TO 0 STEP -1 / 12 / 16
; PRINT "dw "; INT(2 ^ (ax + z) + .5)
; q = q + 1
;NEXT z
;
;END

periods label word
dw 1642,1636,1630,1624,1619,1613,1607,1601,1595,1590,1584,1578,1572,1567,1561
dw 1556,1550,1544,1539,1533,1528,1522,1517,1511,1506,1500,1495,1490,1484,1479
dw 1474,1468,1463,1458,1452,1447,1442,1437,1432,1426,1421,1416,1411,1406,1401
dw 1396,1391,1386,1381,1376,1371,1366,1361,1356,1351,1346,1341,1337,1332,1327
dw 1322,1317,1313,1308,1303,1299,1294,1289,1285,1280,1275,1271,1266,1262,1257
dw 1253,1248,1244,1239,1235,1230,1226,1221,1217,1213,1208,1204,1199,1195,1191
dw 1187,1182,1178,1174,1170,1165,1161,1157,1153,1149,1144,1140,1136,1132,1128
dw 1124,1120,1116,1112,1108,1104,1100,1096,1092,1088,1084,1080,1076,1072,1069
dw 1065,1061,1057,1053,1049,1046,1042,1038,1034,1031,1027,1023,1020,1016,1012
dw 1009,1005,1001,998,994,991,987,983,980,976,973,969,966,962,959,955,952,949
dw 945,942,938,935,932,928,925,922,918,915,912,908,905,902,899,895,892,889,886
dw 882,879,876,873,870,867,864,860,857,854,851,848,845,842,839,836,833,830,827
dw 824,821,818,815,812,809,806,803,801,798,795,792,789,786,783,781,778,775,772
dw 769,767,764,761,758,756,753,750,747,745,742,739,737,734,731,729,726,724,721
dw 718,716,713,711,708,706,703,700,698,695,693,690,688,685,683,680,678,676,673
dw 671,668,666,664,661,659,656,654,652,649,647,645,642,640,638,635,633,631,629
dw 626,624,622,620,617,615,613,611,608,606,604,602,600,598,595,593,591,589,587
dw 585,583,581,578,576,574,572,570,568,566,564,562,560,558,556,554,552,550,548
dw 546,544,542,540,538,536,534,532,530,529,527,525,523,521,519,517,515,513,512
dw 510,508,506,504,502,501,499,497,495,493,492,490,488,486,485,483,481,479,478
dw 476,474,473,471,469,467,466,464,462,461,459,457,456,454,453,451,449,448,446
dw 444,443,441,440,438,436,435,433,432,430,429,427,426,424,423,421,419,418,416
dw 415,413,412,411,409,408,406,405,403,402,400,399,397,396,395,393,392,390,389
dw 387,386,385,383,382,381,379,378,376,375,374,372,371,370,368,367,366,364,363
dw 362,360,359,358,357,355,354,353,351,350,349,348,346,345,344,343,341,340,339
dw 338,337,335,334,333,332,331,329,328,327,326,325,323,322,321,320,319,318,317
dw 315,314,313,312,311,310,309,308,306,305,304,303,302,301,300,299,298,297,296
dw 294,293,292,291,290,289,288,287,286,285,284,283,282,281,280,279,278,277,276
dw 275,274,273,272,271,270,269,268,267,266,265,264,263,262,261,260,260,259,258
dw 257,256,255,254,253,252,251,250,249,249,248,247,246,245,244,243,242,241,241
dw 240,239,238,237,236,235,235,234,233,232,231,230,230,229,228,227,226,225,225
dw 224,223,222,221,221,220,219,218,217,217,216,215,214,214,213,212,211,211,210
dw 209,208,207,207,206,205,205,204,203,202,202,201,200,199,199,198,197,197,196
dw 195,194,194,193,192,192,191,190,190,189,188,188,187,186,186,185,184,184,183
dw 182,182,181,180,180,179,178,178,177,176,176,175,174,174,173,173,172,171,171
dw 170,170,169,168,168,167,166,166,165,165,164,164,163,162,162,161,161,160,159
dw 159,158,158,157,157,156,155,155,154,154,153,153,152,152,151,150,150,149,149
dw 148,148,147,147,146,146,145,145,144,144,143,143,142,142,141,140,140,139,139
dw 138,138,137,137,136,136,136,135,135,134,134,133,133,132,132,131,131,130,130
dw 129,129,128,128,127,127,127,126,126,125,125,124,124,123,123,122,122,122,121
dw 121,120,120,119,119,119,118,118,117,117,116,116,116,115,115,114,114,114,113
dw 113,112,112,112,111,111,110,110,110,109,109,108,108,108,107,107,106,106,106
dw 105,105,104,104,104,103,103,103,102,102,102,101,101,100,100,100,99,99,99,98
dw 98,98,97,97,97,96,96,95,95,95,94,94,94,93,93,93,92,92,92,91,91,91,90,90,90
dw 89,89,89,89,88,88,88,87,87,87,86,86,86,85,85,85,84,84,84,84,83,83,83,82,82
dw 82,81,81,81,81,80,80,80,79,79,79,79,78,78,78,77,77,77,77,76,76,76,76,75,75
dw 75,74,74,74,74,73,73,73,73,72,72,72,72,71,71,71,71,70,70,70,69,69,69,69,68
dw 68,68,68,68,67,67,67,67,66,66,66,66,65,65,65,65,64,64,64,64,63,63,63,63,63
dw 62,62,62,62,61,61,61,61,61,60,60,60,60,60,59,59,59,59,58,58,58,58,58,57,57

;ax = 11.08082
;
;FOR z = 0 TO 5 STEP 1 / 12 / 16
; PRINT "dw "; INT(2 ^ (ax + z) + .5)
; q = q + 1
;NEXT z
;
;END

rawfreq label word
dw 2166,2174,2182,2190,2198,2205,2213,2221,2229,2238,2246,2254,2262,2270,2278
dw 2287,2295,2303,2311,2320,2328,2337,2345,2354,2362,2371,2379,2388,2396,2405
dw 2414,2422,2431,2440,2449,2458,2467,2476,2484,2493,2502,2512,2521,2530,2539
dw 2548,2557,2567,2576,2585,2594,2604,2613,2623,2632,2642,2651,2661,2671,2680
dw 2690,2700,2709,2719,2729,2739,2749,2759,2769,2779,2789,2799,2809,2819,2829
dw 2840,2850,2860,2870,2881,2891,2902,2912,2923,2933,2944,2955,2965,2976,2987
dw 2998,3008,3019,3030,3041,3052,3063,3074,3085,3097,3108,3119,3130,3142,3153
dw 3164,3176,3187,3199,3210,3222,3234,3245,3257,3269,3281,3293,3304,3316,3328
dw 3340,3353,3365,3377,3389,3401,3414,3426,3438,3451,3463,3476,3488,3501,3514
dw 3526,3539,3552,3565,3578,3591,3604,3617,3630,3643,3656,3669,3682,3696,3709
dw 3723,3736,3750,3763,3777,3790,3804,3818,3832,3845,3859,3873,3887,3901,3916
dw 3930,3944,3958,3972,3987,4001,4016,4030,4045,4059,4074,4089,4104,4118,4133
dw 4148,4163,4178,4194,4209,4224,4239,4255,4270,4285,4301,4316,4332,4348,4363
dw 4379,4395,4411,4427,4443,4459,4475,4491,4507,4524,4540,4557,4573,4590,4606
dw 4623,4640,4656,4673,4690,4707,4724,4741,4758,4776,4793,4810,4828,4845,4863
dw 4880,4898,4915,4933,4951,4969,4987,5005,5023,5041,5059,5078,5096,5115,5133
dw 5152,5170,5189,5208,5227,5245,5264,5284,5303,5322,5341,5360,5380,5399,5419
dw 5438,5458,5478,5498,5517,5537,5557,5578,5598,5618,5638,5659,5679,5700,5720
dw 5741,5762,5783,5803,5824,5846,5867,5888,5909,5931,5952,5974,5995,6017,6039
dw 6060,6082,6104,6126,6149,6171,6193,6216,6238,6261,6283,6306,6329,6352,6375
dw 6398,6421,6444,6467,6491,6514,6538,6561,6585,6609,6633,6657,6681,6705,6729
dw 6754,6778,6803,6827,6852,6877,6902,6926,6952,6977,7002,7027,7053,7078,7104
dw 7129,7155,7181,7207,7233,7259,7286,7312,7338,7365,7392,7418,7445,7472,7499
dw 7526,7553,7581,7608,7636,7663,7691,7719,7747,7775,7803,7831,7859,7888,7916
dw 7945,7974,8003,8031,8061,8090,8119,8148,8178,8207,8237,8267,8297,8327,8357
dw 8387,8417,8448,8478,8509,8540,8571,8602,8633,8664,8695,8727,8758,8790,8822
dw 8854,8886,8918,8950,8983,9015,9048,9080,9113,9146,9179,9212,9246,9279,9313
dw 9346,9380,9414,9448,9482,9517,9551,9586,9620,9655,9690,9725,9760,9796,9831
dw 9867,9902,9938,9974,10010,10046,10083,10119,10156,10192,10229,10266,10303
dw 10341,10378,10416,10453,10491,10529,10567,10605,10644,10682,10721,10759
dw 10798,10837,10877,10916,10955,10995,11035,11075,11115,11155,11195,11236
dw 11276,11317,11358,11399,11440,11482,11523,11565,11607,11649,11691,11733
dw 11776,11818,11861,11904,11947,11990,12034,12077,12121,12165,12209,12253
dw 12297,12342,12386,12431,12476,12521,12566,12612,12657,12703,12749,12795
dw 12841,12888,12935,12981,13028,13075,13123,13170,13218,13266,13314,13362
dw 13410,13459,13507,13556,13605,13654,13704,13753,13803,13853,13903,13953
dw 14004,14054,14105,14156,14207,14259,14310,14362,14414,14466,14519,14571
dw 14624,14677,14730,14783,14836,14890,14944,14998,15052,15107,15161,15216
dw 15271,15326,15382,15437,15493,15549,15606,15662,15719,15775,15833,15890
dw 15947,16005,16063,16121,16179,16238,16296,16355,16415,16474,16533,16593
dw 16653,16714,16774,16835,16896,16957,17018,17079,17141,17203,17265,17328
dw 17391,17453,17517,17580,17644,17707,17771,17836,17900,17965,18030,18095
dw 18161,18226,18292,18358,18425,18491,18558,18625,18693,18760,18828,18896
dw 18965,19033,19102,19171,19240,19310,19380,19450,19520,19591,19662,19733
dw 19804,19876,19948,20020,20092,20165,20238,20311,20384,20458,20532,20606
dw 20681,20756,20831,20906,20982,21058,21134,21210,21287,21364,21441,21519
dw 21597,21675,21753,21832,21911,21990,22069,22149,22229,22310,22390,22471
dw 22553,22634,22716,22798,22881,22963,23047,23130,23214,23298,23382,23466
dw 23551,23636,23722,23808,23894,23980,24067,24154,24241,24329,24417,24505
dw 24594,24683,24772,24862,24952,25042,25132,25223,25315,25406,25498,25590
dw 25683,25776,25869,25962,26056,26151,26245,26340,26435,26531,26627,26723
dw 26820,26917,27014,27112,27210,27308,27407,27506,27606,27705,27806,27906
dw 28007,28108,28210,28312,28415,28517,28620,28724,28828,28932,29037,29142
dw 29247,29353,29459,29566,29673,29780,29888,29996,30104,30213,30322,30432
dw 30542,30652,30763,30875,30986,31098,31211,31324,31437,31551,31665,31779
dw 31894,32010,32125,32241,32358,32475,32593,32710,32829,32947,33067,33186
dw 33306,33427,33548,33669,33791,33913,34036,34159,34282,34406,34531,34655
dw 34781,34907,35033,35160,35287,35414,35542,35671,35800,35929,36059,36190
dw 36321,36452,36584,36716,36849,36982,37116,37250,37385,37520,37656,37792
dw 37929,38066,38204,38342,38481,38620,38759,38900,39040,39181,39323,39465
dw 39608,39751,39895,40039,40184,40330,40475,40622,40769,40916,41064,41213
dw 41362,41511,41662,41812,41963,42115,42268,42420,42574,42728,42882,43037
dw 43193,43349,43506,43663,43821,43980,44139,44299,44459,44620,44781,44943
dw 45105,45269,45432,45597,45762,45927,46093,46260,46427,46595,46764,46933
dw 47103,47273,47444,47615,47788,47961,48134,48308,48483,48658,48834,49011
dw 49188,49366,49544,49724,49903,50084,50265,50447,50629,50812,50996,51181
dw 51366,51552,51738,51925,52113,52301,52491,52680,52871,53062,53254,53447
dw 53640,53834,54029,54224,54420,54617,54815,55013,55212,55412,55612,55813
dw 56015,56218,56421,56625,56830,57035,57242,57449,57656,57865,58074,58284
dw 58495,58707,58919,59132,59346,59561,59776,59992,60209,60427,60645,60865
dw 61085,61306,61528,61750,61973

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Main playback routine called by IRQ routine
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; mr_???? main mod playing effects handler (called only as often as tempo requires)
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

mr_modpolling:
         dec tempoc
         jnz fx_between_rows

         inc panloc
         and panloc,3fh

         mov esi,currow
         xor ebp,ebp
mr_mainloop:
         movzx eax,panloc
         lea eax,[eax+ebp*4]
         mov bl,pantbl[eax+ebp*4]
         mov _vcpan[ebp],bl
         or _vccmnd[ebp],pan

         lodsw
         xchg al,ah
         mov bl,ah
         and ah,0fh
         mov cx,ax
         lodsw
         xchg al,ah
         mov bh,ah
         and ah,0fh
         mov dx,ax
         mov effect[ebp*2],dx
         and bl,0F0h
         shr bh,4

         or bl,bh
         je mr_nosample

         and ebx,0ffh                       ; play new sample
         dec ebx
         mov edi,ebx
         mov cursamp[ebp],bl

         shl edi,4
         add edi,sambase

         mov eax,[edi]
         mov _vcsbeg[ebp*4],eax
         mov eax,[edi+8]
         mov _vclbeg[ebp*4],eax
         mov eax,[edi+12]
         mov _vclend[ebp*4],eax

         mov al,byte ptr [edi+4+1]
         mov modvol[ebp],al
         mov al,modvol[ebp]
         cmp al,63
         jb short mr_novol64
         mov al,63
mr_novol64:
         shr al,2
         mov _vcvol[ebp],al

         mov al,byte ptr [edi+4+2]
         mov _vccntrl[ebp],al
         or _vccmnd[ebp],play+vol+freq+pan

mr_nosample:
         test cx,cx                         ; set new pitch
         je short mr_testtempo

         mov portto[ebp*2],cx

         cmp dh,3
         je short mr_testtempo

         mov period[ebp*2],cx
         sub ecx,57
         and ecx,0fffeh
         mov ax,pitchtbl[ecx]
         mov _vcfreq[ebp*2],ax
         or _vccmnd[ebp],freq
mr_testtempo:
         test dx,dx
         je mr_done_channel

         cmp dh,0fh                         ; set tempo
         jne short mr_jump

         test dl,dl
         je mr_done_channel

         cmp dl,31
         ja short mr_setbpm

         mov tempo,dl
         mov tempoc,dl
         jmp mr_done_channel

mr_setbpm:
         mov eax,900
         movzx ebx,dl
         xor edx,edx
         div bx
         mov tempo,al
         mov tempoc,al
         jmp mr_done_channel
mr_jump:
         cmp dh,0bh                         ; jump to new pattern
         jne short mr_break
         mov _ordmod,dl
         mov rowleft,1
         jmp mr_done_channel
mr_break:
         cmp dh,0dh                         ; pattern break
         jne short mr_setvolume

         mov dh,dl
         and dl,0fh
         shr dh,4
         add dh,dh
         add dl,dh
         shl dh,2
         add dl,dh
         mov break,dl
         mov rowleft,1
         jmp mr_done_channel

mr_setvolume:
         cmp dh,0ch                         ; set volume
         jne short mr_tone_slide

         mov modvol[ebp],dl
         cmp dl,63
         jbe short mr_not_6chan4
         mov dl,63
mr_not_6chan4:
         shr dl,2
         mov _vcvol[ebp],dl
         or _vccmnd[ebp],vol
         jmp mr_done_channel

mr_tone_slide:
         cmp dh,3                           ; tone slide
         jne short mr_init_vibrato

         test dl,dl
         jne short mr_notlastslide
         mov dl,[ebp+portparm]
mr_notlastslide:
         mov [ebp+portparm],dl
         mov [ebp*2+effect],dx
         and _vccmnd[ebp],-1-play
         jmp mr_done_channel

mr_init_vibrato:
         cmp dh,4                           ; initialize vibrato
         jne short mr_initarp

         mov al,[ebp+vibparm]
         mov ah,al
         and al,0fh
         and ah,0f0h
         test dl,0fh
         jne short mr_okdepth
         or dl,al
mr_okdepth:
         test dl,0f0h
         jne short mr_okrate
         or dl,ah
mr_okrate:
         mov [ebp+vibparm],dl
         mov [ebp*2+effect],dx
         test cx,cx
         je mr_done_channel
         mov [ebp+vibpos],0
         jmp mr_done_channel

mr_initarp:
         cmp dh,0                           ; initialize arpeggio
         jne mr_more_effects

         mov dh,dl
         and dl,0fh
         shr dh,4
         xor ebx,ebx
         mov ax,[ebp*2+period]

mr_scanperiod:
         cmp ax,periods[ebx*2]
         jae mr_set_arp
         inc ebx
         cmp ebx,930
         jb short mr_scanperiod
mr_set_arp:
         xor eax,eax
         mov al,dh
         shl eax,4
         add eax,ebx

         xor ecx,ecx
         mov cl,dl
         shl ecx,4
         add ecx,ebx

         mov bx,periods[ebx*2]
         sub ebx,57
         and ebx,0fffeh
         mov bx,[pitchtbl+ebx]
         mov word ptr [ebp*8+arp+2],bx

         mov cx,periods[ecx*2]
         sub ecx,57
         and ecx,0fffeh
         mov cx,[pitchtbl+ecx]
         mov word ptr [ebp*8+arp+4],cx

         mov ax,periods[eax*2]
         sub eax,57
         and eax,0fffeh
         mov ax,[pitchtbl+eax]
         mov word ptr [ebp*8+arp+6],ax

         mov byte ptr [ebp*8+arp],0
         jmp mr_done_channel

mr_more_effects:

; Put more effects here

; dh = effect
; dl = data

mr_done_channel:
         inc ebp
         cmp ordwidth,ebp
         jne mr_mainloop

         mov currow,esi                     ; save current pattern position

         inc _currow
         dec rowleft                        ; how many rows left?
         jnz mr_nonewrow

         inc _ordmod                        ; done pattern, find next
         movzx eax,_ordmod
         cmp al,lastord                     ; done song?
         jne short mr_moresong
         xor eax,eax                        ; set up to loop forever unless user calls _mod_stop
         mov _ordmod,al
         call [whendone]                    ; call user routine when finished mod
mr_moresong:
         add eax,ordbase
         movzx eax,byte ptr [eax]
         shl eax,10
         cmp ordwidth,8
         jne short mr_not_8chan
         shl eax,1
mr_not_8chan:
         cmp ordwidth,6
         jne short mr_not_6chan
         mov ebx,eax
         shr ebx,1
         add eax,ebx
mr_not_6chan:
         add eax,patterns
         mov currow,eax
         movzx eax,break
         mov ebx,ordwidth
         shl eax,4
         cmp ebx,8
         jne short mr_not_8chanbrk
         shl eax,1
mr_not_8chanbrk:
         cmp ebx,6
         jne short mr_not_6chanbrk
         mov ecx,eax
         shr ecx,1
         add eax,ecx
mr_not_6chanbrk:
         add currow,eax
         mov rowleft,64
         mov _currow,0
         mov break,0
mr_nonewrow:
         mov al,tempo
         mov tempoc,al
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; fx_???? effects handler called in between rows (called every IRQ)
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

fx_between_rows:
         mov ebp,ordwidth
         dec ebp
fx_mainloop:
         mov dx,[effect+ebp*2]
         test dx,dx
         je fx_doneeffect

         cmp dh,0ah                         ; volume slide
         jne short fx_portamento_up

         mov dh,dl
         and dl,0fh
         shr dh,3                           ; 4
         mov al,[ebp+modvol]
         sub al,dl
         cmp al,65
         jb short fx_vollow
         xor al,al
fx_vollow:
         add al,dh
         cmp al,64
         jbe short fx_volhigh
         mov al,64
fx_volhigh:
         mov [ebp+modvol],al
         cmp al,63
         jb short fx_not64
         mov al,63
fx_not64:
         shr al,2
         mov _vcvol[ebp],al
         or _vccmnd[ebp],vol
         jmp fx_doneeffect
fx_portamento_up:
         cmp dh,01h                         ; portup
         jne short fx_portamento_down

         xor dh,dh
         mov bx,period[ebp*2]
         sub bx,dx
         cmp bx,57
         jae short fx_notbelow
         mov bx,57
fx_notbelow:
         mov period[ebp*2],bx
         sub ebx,57
         and ebx,0fffeh
         mov bx,pitchtbl[ebx]
         mov _vcfreq[ebp*2],bx
         or _vccmnd[ebp],freq
         jmp fx_doneeffect

fx_portamento_down:
         cmp dh,02h                         ; portdown
         jne short fx_volumeslide

         xor dh,dh
         mov bx,period[ebp*2]
         add bx,dx
         cmp bx,1711
         jb short fx_nooverflow
         mov bx,1711
fx_nooverflow:
         mov period[ebp*2],bx
         sub ebx,57
         and ebx,0fffeh
         mov bx,pitchtbl[ebx]
         mov _vcfreq[ebp*2],bx
         or _vccmnd[ebp],freq
         jmp fx_doneeffect

fx_volumeslide:
         cmp dh,05h                         ; handle volume slide
         jne short fx_tone_slide

         mov dh,dl
         and dl,0fh
         shr dh,3                           ; 4
         mov al,[ebp+modvol]
         sub al,dl
         cmp al,65
         jb fx_volunder
         xor al,al
fx_volunder:
         add al,dh
         cmp al,64
         jbe fx_volover
         mov al,64
fx_volover:
         mov [ebp+modvol],al
         cmp al,63
         jb short fx_vol63
         mov al,63
fx_vol63:
         shr al,2
         mov _vcvol[ebp],al
         or _vccmnd[ebp],vol

         mov dh,3
         mov dl,[portparm+ebp]
fx_tone_slide:
         cmp dh,3                           ; tone slide
         jne fx_vibrato

         xor dh,dh
         mov ax,[ebp*2+portto]
         mov bx,[ebp*2+period]
         cmp bx,ax
         je fx_doneeffect
         jg short fx_toneup
fx_tonedown:
         add bx,dx
         cmp bx,ax
         jle short fx_settone
fx_underflow:
         mov bx,ax
         jmp short fx_settone
fx_toneup:
         sub bx,dx
         cmp bx,ax
         jl short fx_underflow
fx_settone:
         mov [ebp*2+period],bx
         sub bx,57
         and ebx,0fffeh
         mov ax,pitchtbl[ebx]
         mov _vcfreq[ebp*2],ax
         or _vccmnd[ebp],freq
         jmp fx_doneeffect

fx_vibslide:
         cmp dh,6                           ; volume slide + vibrato
         jne fx_vibrato

         mov dh,dl
         and dl,0fh
         shr dh,3                           ; 4
         mov al,[ebp+modvol]
         sub al,dl
         cmp al,65
         jb short fx_vlunder
         xor al,al
fx_vlunder:
         add al,dh
         cmp al,64
         jbe short fx_vlover
         mov al,64
fx_vlover:
         mov [ebp+modvol],al
         cmp al,63
         jb short fx_vl63
         mov al,63
fx_vl63:
         shr al,2
         mov _vcvol[ebp],al
         or _vccmnd[ebp],vol

         mov dh,4
         mov dl,vibparm[ebp]

fx_vibrato:
         cmp dh,4                           ; vibrato
         jne fx_arp

         mov dh,dl
         and dl,0fh
         shr dh,4
         shl dh,2
         add [ebp+vibpos],dh
         mov dh,[ebp+vibpos]
         mov bl,dh
         shr bl,2
         and ebx,1fh
         mov al,[sintable+ebx]
         mul dl
         rol ax,1
         xchg al,ah
         and ah,1
         test dh,dh
         jns fx_vibup
         neg ax
fx_vibup:
         add ax,[ebp*2+period]
         mov bx,ax
         cmp bx,57
         jge short fx_nolovib
         mov bx,57
fx_nolovib:
         cmp bx,1712
         jle short fx_nohivib
         mov bx,1712
fx_nohivib:
         sub ebx,57
         and ebx,0fffeh
         mov ax,pitchtbl[ebx]
         mov _vcfreq[ebp*2],ax
         or _vccmnd[ebp],freq
         jmp fx_doneeffect
fx_arp:
         cmp dh,0                           ; arpeggio
         jne fx_more_effects

         xor ebx,ebx
         mov bl,byte ptr [ebp*8+arp]
         mov ax,word ptr [ebp*8+arp+ebx+2]
         mov _vcfreq[ebp*2],ax
         or _vccmnd[ebp],freq
         add bl,2
         cmp bl,6
         jb short fx_setarp
         xor bl,bl
fx_setarp:
         mov byte ptr [ebp*8+arp],bl
         jmp fx_doneeffect

fx_more_effects:

; Put more effects here

; dh = effect
; dl = data

fx_doneeffect:
         dec ebp
         jnl fx_mainloop

         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Init mod player
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_mod_init:
         ret                                ; nothing to init!

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Reset mod player
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_mod_uninit:
         call _mod_stop
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Load a mod, samples go directly into GUS ram
; In:
;   EAX -> stream input routine (In:ECX=len,EDX->buf, Out:EAX=len,CF=1 error)
;   EDX -> buffer large enough for all music data plus largest sample
; _sfxmem -> location to begin storing on GUS memory
; Out:
;  CF = 1 mod not recognized!
;  CF = 0 mod loaded ok!
;   EAX - number of bytes of buffer to keep
;   EBX - number of bytes used on GUS
; _sfxmem -> next free GUS memory location
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_mod_load:
         pushad
         mov sambase,edx
         mov ecx,1084
         call eax

         mov eax,4
         mov ebx,[edx+1080]

         cmp ebx,"4TLF"
         je ml_foundtype
         cmp ebx,".K.M"
         je ml_foundtype
         cmp ebx,"!K!M"
         je ml_foundtype

         mov al,6
         cmp ebx,"6TLF"
         je ml_foundtype
         cmp ebx,"NHC6"
         je ml_foundtype

         mov al,8
         cmp ebx,"8TLF"
         je ml_foundtype
         cmp ebx,"NHC8"
         je ml_foundtype

         popad                              ; unknown module type
         stc
         ret

ml_foundtype:
         mov ordwidth,eax

         mov al,[edx+950]
         mov lastord,al

         mov ecx,31
         lea esi,[edx+20]
         mov edi,edx

ml_sampledata:
         movzx eax,word ptr [esi+22]
         xchg ah,al
         shl eax,1
         stosd                              ; sample length

         movzx eax,word ptr [esi+24]
         stosd

         movzx eax,word ptr [esi+26]
         xchg ah,al
         shl eax,1
         stosd                              ; sample repeat start

         movzx eax,word ptr [esi+28]
         xchg ah,al
         shl eax,1
         stosd                              ; repeat length

         add esi,30
         loop ml_sampledata

         mov ordbase,edi

         mov ecx,128
         lea esi,[edx+952]
         xor al,al
ml_rep:
         mov ah,[esi]                       ; copy pattern order
         mov [edi],ah                       ; and find highest pattern number
         cmp ah,al
         jb ml_notl
         mov al,ah
ml_notl:
         inc esi
         inc edi
         loop ml_rep

         mov patterns,edi

         inc al
         mov ordsize,al

         mov edx,edi
         mov ecx,ordwidth
         shl ecx,6+2
         movzx eax,ordsize
         imul ecx,eax
         call dword ptr [esp+28]

         add edx,ecx
         mov patternend,edx

         mov ebx,_sfxmem
         mov esi,sambase
         mov edi,31
         mov _sfxsign,80h
ml_loop1:
         mov ecx,[esi]                      ; [esi+0]  = length
         jcxz ml_nextsample                 ; [esi+8]  = repeat start
         cmp ecx,[esi+12]                   ; [esi+12] = repeat length
         ja ml_nofixl                       ; ebx = GUS memory, ecx = length
         mov [esi+12],ecx
ml_nofixl:
         mov eax,[esi+8]
         add eax,[esi+12]
         cmp eax,ecx
         jb mr_nofixr
         mov eax,ecx
         sub eax,[esi+12]
         mov [esi+8],eax
mr_nofixr:
         mov ebp,ecx

         mov eax,[esi+12]
         cmp eax,4
         jb short ml_noloop

         or byte ptr [esi+4+2],loop_on+loop_bi
         mov ebp,eax
         add ebp,[esi+8]

ml_noloop:
         mov [esi],ebx
         add [esi+8],ebx
         add ebp,ebx
         mov [esi+12],ebp

         call dword ptr [esp+28]
         call _sfx_putram
         add ebx,ecx

ml_nextsample:
         add esi,4*4
         dec edi
         jnz ml_loop1

         mov edx,sambase
         sub edx,patternend

         mov [esp+28],edx
         mov [esp+16],ebx                   ; save amount of GUS ram used for samples
         add _sfxmem,ebx

         mov ebp,57

         xor eax,eax
ml_findpitch:
         cmp bp,periods[eax*2]
         jae ml_set_freq
         inc eax
         cmp eax,930
         jne ml_findpitch
ml_set_freq:
         mov ax,rawfreq[eax*2]
         call _sfx_getfreq
         mov ecx,ebp
         sub ecx,57
         and ecx,0fffeh
         mov pitchtbl[ecx],ax
         add ebp,2
         xor eax,eax
         cmp ebp,1713
         jb ml_findpitch

         popad
         clc                                ; clc = mod OK!
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Play a loaded mod
; In:
;  EAX = routine to call when done module
;     eg: _ret      = loop module forever.
;         _mod_stop = stop module when done
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_mod_play:
         push eax ecx edi esi
         call _mod_stop
         mov whendone,eax
         mov _ordmod,0
         mov tempo,6
         mov tempoc,1
         mov panloc,0
         mov rowleft,64
         mov _currow,0
         mov esi,ordbase
         movzx eax,byte ptr [esi]
         shl eax,10
         add eax,patterns
         mov currow,eax

         call _irq_findcontrol
         jc short mp_nomod
         mov _irqcontrol[ecx*4],offset mr_modpolling
         mov whichmodcontrol,ecx
mp_nomod:
         xor eax,eax

         mov edi,offset effect
         mov ecx,8
         rep stosw

         mov edi,offset cursamp
         mov ecx,152
         rep stosb

         mov edi,offset modvol
         mov eax,64
         mov ecx,8
         rep stosb

         pop esi edi ecx eax
         clc
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Stop playback
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_mod_stop:
         push ecx
         mov dword ptr _vcvol[0],0000000h
         mov dword ptr _vcvol[4],0000000h
         mov dword ptr _vccmnd[0],20202020h
         mov dword ptr _vccmnd[4],20202020h
         mov ecx,whichmodcontrol
         or ecx,ecx
         jl ms_ret
         mov _irqcontrol[ecx*4],offset _ret
         mov whichmodcontrol,-1
ms_ret:
         pop ecx
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Play mod sample # al
; In: AL sample play
;   DL = channel (0-31)
;   BL = volume  (0-15)
;   BH = pan     (0-8)
;   CH = precalculated frequency (0-59)
; Out:
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_mod_sample_play:
         pushad
         movzx eax,al
         mov esi,sambase

         shl eax,4
         add esi,eax
         mov edi,[esi]
         mov eax,[esi+8]
         mov ebp,[esi+12]

         mov _vcsbeg[edx*4],edi
         mov _vclbeg[edx*4],eax
         mov _vclend[edx*4],ebp
         mov cl,byte ptr [esi+4+2]

         mov _vcpan[edx],bh
         mov _vcvol[edx],bl
         movzx eax,ch
         mov ax,_freqtbl[eax*2]
         mov _vcfreq[edx*2],ax
         mov _vccntrl[edx],cl
         mov _vccmnd[edx],play              ; command comes last
         popad
         ret

code32   ends
         end
