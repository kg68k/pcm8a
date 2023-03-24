*
*	X68k polyphonic ADPCM driver PCM8A.X v1.02.1				*;version
*		音程変換対応(MPCM.X相当)
*		Xellent30ｼﾘｰｽﾞ ﾛｰｶﾙSRAM用ﾜｰｸ分離対応
*		040turbo 対応 , ﾊｲﾒﾓﾘ常駐対応
*		ADPCM clock-up 対応
*					philly	1997/9/2
*
*	改造は自由ですが、利用者の混乱を防ぐために、
*	改造内容をドキュメント等に明記しておいてください。

	.include	doscall.mac
	.include	iocscall.mac

PCMCI1	equ	25			* ﾁｬﾝﾈﾙ数のﾃﾞﾌｫﾙﾄ値
PCMCI2	equ	32			*   〃   (常駐時の領域確保用)
PCMCIN	equ	25			*   〃   最小値
PCMCIX	equ	250			*   〃   最大値
PCMBI1	equ	48			* 処理ﾊﾞｲﾄ数のﾃﾞﾌｫﾙﾄ値
PCMBI2	equ	144			*     〃    (常駐時の領域確保用)
PCMBIX	equ	144			*     〃    の指定可能最大値
PCMIOC	equ	9			* IOCS出力ﾁｬﾝﾈﾙ数のﾃﾞﾌｫﾙﾄ

VOLMN1	equ	$40			* 最小音量のﾃﾞﾌｫﾙﾄ値
VOLMN2	equ	$40			*    〃   (常駐時の領域確保用)
VOLMX1	equ	$A0			* 最大音量のﾃﾞﾌｫﾙﾄ値
VOLMX2	equ	$A0			*    〃   (常駐時の領域確保用)
VOLWID	equ	48
VOLCLP	equ	79
VOLOFS	equ	$80

PCM8FL	equ	$42			* 動作中の$0C32の値
PCM8OK	equ	'PCM8'
PCM8NG	equ	'@PCM'
MPCMOK	equ	'MPCM'
PCMSPC	equ	$08			* 無音部
PCMSP1	equ	$88			* 停止時
PCMSP2	equ	$88			* 強制停止時
PCMSP3	equ	$00			* 無音部2
PCMSPN	equ	2			* PCMSP2ﾊﾞｲﾄ数
PCMSPR	equ	6			* PCMSP3ﾊﾞｲﾄ数
PCMBGN	equ	8			* 開始時ﾊﾞｲﾄ数
TRYNUM	equ	4			* 過負荷時ﾘﾄﾗｲ回数
KEPSIZ	equ	32			* 占有名長さ
KEPNUM	equ	32			* 最大占有数
CHNSIZ	equ	$80			* ﾁｬﾝﾈﾙﾊﾞｯﾌｧｻｲｽﾞ
WKCNT	equ	5			* ﾜｰｸｴﾘｱ数
WKSNUM	equ	$10			* 2^(ﾜｰｸｴﾘｱ数-1)
DCOL0	equ	$0000			* 動作表示色ｺｰﾄﾞ(割り込み終了)
DCOL1	equ	$0020			*	〃	(DPCM→ADPCM変換中)
DCOL2	equ	$0018			*	〃	(ADPCM→DPCM変換中)
CACHEL	equ	16			* ｷｬｯｼｭ1ﾗｲﾝのﾊﾞｲﾄ数
CACHES	equ	4			*	〃   ｼﾌﾄ回数
REPT	equ	5			* ｸﾛｯｸｱｯﾌﾟ自動判別の繰り返し回数-1
WKSIZ	equ	1024

T1VECT	equ	$0021
T2VECT	equ	$0022			* trap #2 ﾍﾞｸﾀ番号

T1VECA	equ	$0084
T2VECA	equ	$0088
FM1BBF	equ	$09DA
ADIOCS	equ	$0C32
MPUFLG	equ	$0CBC
HUTOP	equ	$6800
TXTPL0	equ	$00E82200
DMACH3	equ	$00E840C0
MFPIMA	equ	$00E88013
MFPIMB	equ	$00E88015
MFPTMC	equ	$00E88023
FMADR	equ	$00E90001
FMDAT	equ	$00E90003
PCMCNT	equ	$00E92001
PCMDAT	equ	$00E92003
PPIPC	equ	$00E9A005
PPICTL	equ	$00E9A007

*************************************************
*  ADPCM → DPCM 変換ﾏｸﾛ			*
*************************************************

AP00:	.macro
	move.b	(a0)+,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	d0,a3
	move.l	(a3,a2.l),d0
	add.l	d0,(a1)+
	move.l	(a3),d0
	.endm

AP01:	.macro
	move.b	(a0)+,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	d0,a3
	move.l	(a3,a2.l),(a1)+
	move.l	(a3),d0
	.endm

AP10:	.macro
	move.b	(a0)+,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	d0,a3
	move.w	(a3,a2.l),d0
	add.w	2(a3,a2.l),d0
	add.w	d0,(a1)+
	move.l	(a3),d0
	.endm

AP11:	.macro
	move.b	(a0)+,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	d0,a3
	move.w	(a3,a2.l),d0
	add.w	2(a3,a2.l),d0
	move.w	d0,(a1)+
	move.l	(a3),d0
	.endm

AP12:	.macro
	move.b	(a0)+,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	d0,a3
	add.w	(a3,a2.l),d1
	add.w	d1,(a1)+
	move.w	2(a3,a2.l),d1
	move.l	(a3),d0
	.endm

AP13:	.macro
	move.b	(a0)+,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	d0,a3
	add.w	(a3,a2.l),d1
	move.w	d1,(a1)+
	move.w	2(a3,a2.l),d1
	move.l	(a3),d0
	.endm

AP20:	.macro
	move.b	(a0)+,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	d0,a3
	move.w	(a3,a2.l),d1
	add.w	2(a3,a2.l),d1
	move.l	(a3),d0
	.endm

AP21:	.macro
	move.b	(a0)+,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	d0,a3
	add.w	(a3,a2.l),d1
	add.w	2(a3,a2.l),d1
	move.l	(a3),d0
	.endm

AP22:	.macro
	move.b	(a0)+,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	d0,a3
	add.w	(a3,a2.l),d1
	add.w	2(a3,a2.l),d1
	add.w	d1,(a1)+
	move.l	(a3),d0
	.endm

AP23:	.macro
	move.b	(a0)+,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	d0,a3
	add.w	(a3,a2.l),d1
	add.w	2(a3,a2.l),d1
	move.w	d1,(a1)+
	move.l	(a3),d0
	.endm

APA0:	.macro
	move.b	(a0)+,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	d0,a3
	move.l	(a3,a2.l),d0
	move.l	d0,d1
	swap	d0
	add.w	d0,(a1)+
	move.l	(a3),d0
	.endm

APA1:	.macro
	move.b	(a0)+,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	d0,a3
	move.w	(a3,a2.l),(a1)+
	move.w	2(a3,a2.l),d1
	move.l	(a3),d0
	.endm

APA2:	.macro
	move.b	(a0)+,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	d0,a3
	move.l	(a3,a2.l),d0
	add.w	d0,4(a1)
	swap	d0
	add.w	d0,(a1)
	addq.l	#8,a1
	move.l	(a3),d0
	.endm

APA3:	.macro
	move.b	(a0)+,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	d0,a3
	move.w	(a3,a2.l),(a1)+
	move.w	d6,(a1)+
	move.w	2(a3,a2.l),(a1)+
	move.w	d6,(a1)+
	move.l	(a3),d0
	.endm

*************************************************
*  DPCM → ADPCM 変換ﾏｸﾛ			*
*************************************************

PCM2AD	.macro
	add.w	(a1)+,d0
	move.b	(a3,d0.w),d2
	adda.w	d2,a2
	move.b	(a2),d1
	sub.w	256(a2),d0
	adda.w	512(a2),a2
	add.w	(a1)+,d0
	move.b	(a3,d0.w),d2
	adda.w	d2,a2
	or.w	(a2),d1
	move.b	d1,(a0)+
	sub.w	256(a2),d0
	adda.w	512(a2),a2
	.endm

*************************************************
*  16/8bit PCM 音量/音程変換ﾏｸﾛ			*
*************************************************

P16A	.macro	P16A1
	.local	P16AA,P16AB,P16AC,P16AX,P16AA0
	.local	P16AA1,P16AA2,P16AA3,P16AA4,P16AA5,P16AA6
	.local	P16AA7,P16AA8
	.local	P16AB1,P16AB2,P16AB3,P16AB4,P16AB5,P16AB6
	.local	P16AB7,P16AB8,P16AB9,P16ABA
	.local	P16AC1,P16AC2,P16AC3,P16AC4,P16AC5,P16AC6
	.local	P16AC7,P16AC8,P16AC9,P16ACA

	.dc.w	P16AA0-P16AA
P16AA:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	P16AB
	dbra	d3,P16AA1
	jmp	(a5)
	.dc.w	P16AX-P16AA0
P16AA0:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	P16AB
	dbra	d3,P16AA1
	jmp	(a5)
P16AA1:	add.w	d5,d4
	bcc	P16AA3
	subq.w	#2,d2
	bcs	P16AA4
P16AA2:	move.w	(a0)+,d0
	asl.w	#P16A1,d0
P16AA3:	add.w	d0,(a1)+
	dbra	d3,P16AA1
	jmp	(a5)
P16AA4:	subi.l	#$10000,d2
	bcc	P16AA2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16AA7
	lea	P16AA6(pc),a4
P16AA5:	jmp	(a5)
	.dc.w	P16AX-P16AA6
P16AA6:	subq.l	#2,d2
	bcs	P16AA5
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0)+,d0
	asl.w	#P16A1,d0
	add.w	d0,(a1)+
	dbra	d3,P16AA1
	jmp	(a5)
P16AA7:	lea	P16AA8(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	P16AX-P16AA8
P16AA8:	subq.l	#2,d2
	bcs	P16AA5
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0)+,d0
	asl.w	#P16A1,d0
	add.w	d0,(a1)+
	dbra	d3,P16AA1
P16AX:	jmp	(a5)

P16AB:	move.l	d5,d7
	swap	d7
	add.w	d7,d7
	movea.w	d7,a2
	addq.w	#2,d7
	dbra	d3,P16AB1
	jmp	(a5)
P16AB1:	add.w	d5,d4
	bcc	P16AC1
	sub.w	d7,d2
	bcs	P16AB3
P16AB2:	move.w	(a0),d0
	adda.w	d7,a0
	asl.w	#P16A1,d0
	add.w	d0,(a1)+
	dbra	d3,P16AB1
	jmp	(a5)
P16AB3:	subi.l	#$10000,d2
	bcc	P16AB2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16AB7
	lea	P16AB5(pc),a4
P16AB4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16AX-P16AB5
P16AB5:	sub.w	d1,d2
	bcs	P16AB6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	asl.w	#P16A1,d0
	add.w	d0,(a1)+
	dbra	d3,P16AB1
	jmp	(a5)
P16AB6:	subi.l	#$10000,d2
	bcs	P16AB4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	asl.w	#P16A1,d0
	add.w	d0,(a1)+
	dbra	d3,P16AB1
	jmp	(a5)
P16AB7:	lea	P16AB9(pc),a4
	addq.l	#2,a1
P16AB8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16AX-P16AB9
P16AB9:	sub.w	d1,d2
	bcs	P16ABA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	asl.w	#P16A1,d0
	add.w	d0,(a1)+
	dbra	d3,P16AB1
	jmp	(a5)
P16ABA:	subi.l	#$10000,d2
	bcs	P16AB8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	asl.w	#P16A1,d0
	add.w	d0,(a1)+
	dbra	d3,P16AB1
	jmp	(a5)
P16AC1:	sub.w	a2,d2
	bcs	P16AC3
P16AC2:	move.w	(a0),d0
	adda.w	a2,a0
	asl.w	#P16A1,d0
	add.w	d0,(a1)+
	dbra	d3,P16AB1
	jmp	(a5)
P16AC3:	subi.l	#$10000,d2
	bcc	P16AC2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16AC7
	lea	P16AC5(pc),a4
P16AC4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16AX-P16AC5
P16AC5:	sub.w	d1,d2
	bcs	P16AC6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	asl.w	#P16A1,d0
	add.w	d0,(a1)+
	dbra	d3,P16AB1
	jmp	(a5)
P16AC6:	subi.l	#$10000,d2
	bcs	P16AC4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	asl.w	#P16A1,d0
	add.w	d0,(a1)+
	dbra	d3,P16AB1
	jmp	(a5)
P16AC7:	lea	P16AC9(pc),a4
	addq.l	#2,a1
P16AC8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16AX-P16AC9
P16AC9:	sub.w	d1,d2
	bcs	P16ACA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	asl.w	#P16A1,d0
	add.w	d0,(a1)+
	dbra	d3,P16AB1
	jmp	(a5)
P16ACA:	subi.l	#$10000,d2
	bcs	P16AC8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	asl.w	#P16A1,d0
	add.w	d0,(a1)+
	dbra	d3,P16AB1
	jmp	(a5)

	.endm

*-------
P16B	.macro	P16B1
	.local	P16BA,P16BB,P16BC,P16BX,P16BA0
	.local	P16BA1,P16BA2,P16BA3,P16BA4,P16BA5,P16BA6
	.local	P16BA7,P16BA8
	.local	P16BB1,P16BB2,P16BB3,P16BB4,P16BB5,P16BB6
	.local	P16BB7,P16BB8,P16BB9,P16BBA
	.local	P16BC1,P16BC2,P16BC3,P16BC4,P16BC5,P16BC6
	.local	P16BC7,P16BC8,P16BC9,P16BCA

	.dc.w	P16BA0-P16BA
P16BA:	add.w	d3,d3
	moveq	#P16B1,d1
	cmpi.l	#$10000,d5
	bcc	P16BB
	dbra	d3,P16BA1
	jmp	(a5)
	.dc.w	P16BX-P16BA0
P16BA0:	add.w	d3,d3
	moveq	#P16B1,d1
	cmpi.l	#$10000,d5
	bcc	P16BB
	dbra	d3,P16BA1
	jmp	(a5)
P16BA1:	add.w	d5,d4
	bcc	P16BA3
	subq.w	#2,d2
	bcs	P16BA4
P16BA2:	move.w	(a0)+,d0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
P16BA3:	add.w	d0,(a1)+
	dbra	d3,P16BA1
	jmp	(a5)
P16BA4:	subi.l	#$10000,d2
	bcc	P16BA2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16BA7
	lea	P16BA6(pc),a4
P16BA5:	jmp	(a5)
	.dc.w	P16BX-P16BA6
P16BA6:	subq.l	#2,d2
	bcs	P16BA5
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0)+,d0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16BA1
	jmp	(a5)
P16BA7:	lea	P16BA8(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	P16BX-P16BA8
P16BA8:	subq.l	#2,d2
	bcs	P16BA5
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0)+,d0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16BA1
P16BX:	jmp	(a5)

P16BB:	move.l	d5,d7
	swap	d7
	add.w	d7,d7
	movea.w	d7,a2
	addq.w	#2,d7
	dbra	d3,P16BB1
	jmp	(a5)
P16BB1:	add.w	d5,d4
	bcc	P16BC1
	sub.w	d7,d2
	bcs	P16BB3
P16BB2:	move.w	(a0),d0
	adda.w	d7,a0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16BB1
	jmp	(a5)
P16BB3:	subi.l	#$10000,d2
	bcc	P16BB2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16BB7
	lea	P16BB5(pc),a4
P16BB4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16BX-P16BB5
P16BB5:	sub.w	d1,d2
	bcs	P16BB6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16B1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16BB1
	jmp	(a5)
P16BB6:	subi.l	#$10000,d2
	bcs	P16BB4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16B1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16BB1
	jmp	(a5)
P16BB7:	lea	P16BB5(pc),a4
	addq.l	#2,a1
P16BB8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16BX-P16BB9
P16BB9:	sub.w	d1,d2
	bcs	P16BBA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16B1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16BB1
	jmp	(a5)
P16BBA:	subi.l	#$10000,d2
	bcs	P16BB8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16B1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16BB1
	jmp	(a5)
P16BC1:	sub.w	a2,d2
	bcs	P16BC3
P16BC2:	move.w	(a0),d0
	adda.w	a2,a0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16BB1
	jmp	(a5)
P16BC3:	subi.l	#$10000,d2
	bcc	P16BC2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16BC7
	lea	P16BC5(pc),a4
P16BC4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16BX-P16BC5
P16BC5:	sub.w	d1,d2
	bcs	P16BC6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16B1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16BB1
	jmp	(a5)
P16BC6:	subi.l	#$10000,d2
	bcs	P16BC4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16B1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16BB1
	jmp	(a5)
P16BC7:	lea	P16BC9(pc),a4
P16BC8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16BX-P16BC9
P16BC9:	sub.w	d1,d2
	bcs	P16BCA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16B1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16BB1
	jmp	(a5)
P16BCA:	subi.l	#$10000,d2
	bcs	P16BC8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16B1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16BB1
	jmp	(a5)

	.endm

*-------
P16C	.macro	P16C1
	.local	P16CA,P16CB,P16CC,P16CX,P16CA0
	.local	P16CA1,P16CA2,P16CA3,P16CA4,P16CA5,P16CA6
	.local	P16CA7,P16CA8
	.local	P16CB1,P16CB2,P16CB3,P16CB4,P16CB5,P16CB6
	.local	P16CB7,P16CB8,P16CB9,P16CBA
	.local	P16CC1,P16CC2,P16CC3,P16CC4,P16CC5,P16CC6
	.local	P16CC7,P16CC8,P16CC9,P16CCA

	.dc.w	P16CA0-P16CA
P16CA:	add.w	d3,d3
	moveq	#P16C1,d1
	cmpi.l	#$10000,d5
	bcc	P16CB
	dbra	d3,P16CA1
	jmp	(a5)
	.dc.w	P16CX-P16CA0
P16CA0:	add.w	d3,d3
	moveq	#P16C1,d1
	cmpi.l	#$10000,d5
	bcc	P16CB
	dbra	d3,P16CA1
	jmp	(a5)
P16CA1:	add.w	d5,d4
	bcc	P16CA3
	subq.w	#2,d2
	bcs	P16CA4
P16CA2:	move.w	(a0)+,d0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
P16CA3:	add.w	d0,(a1)+
	dbra	d3,P16CA1
	jmp	(a5)
P16CA4:	subi.l	#$10000,d2
	bcc	P16CA2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16CA7
	lea	P16CA6(pc),a4
P16CA5:	jmp	(a5)
	.dc.w	P16CX-P16CA6
P16CA6:	subq.l	#2,d2
	bcs	P16CA5
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0)+,d0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16CA1
	jmp	(a5)
P16CA7:	lea	P16CA8(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	P16CX-P16CA8
P16CA8:	subq.l	#2,d2
	bcs	P16CA5
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0)+,d0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16CA1
P16CX:	jmp	(a5)

P16CB:	move.l	d5,d7
	swap	d7
	add.w	d7,d7
	movea.w	d7,a2
	addq.w	#2,d7
	dbra	d3,P16CB1
	jmp	(a5)
P16CB1:	add.w	d5,d4
	bcc	P16CC1
	sub.w	d7,d2
	bcs	P16CB3
P16CB2:	move.w	(a0),d0
	adda.w	d7,a0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16CB1
	jmp	(a5)
P16CB3:	subi.l	#$10000,d2
	bcc	P16CB2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16CB7
	lea	P16CB5(pc),a4
P16CB4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16CX-P16CB5
P16CB5:	sub.w	d1,d2
	bcs	P16CB6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16C1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16CB1
	jmp	(a5)
P16CB6:	subi.l	#$10000,d2
	bcs	P16CB4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16C1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16CB1
	jmp	(a5)
P16CB7:	lea	P16CB5(pc),a4
	addq.l	#2,a1
P16CB8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16CX-P16CB9
P16CB9:	sub.w	d1,d2
	bcs	P16CBA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16C1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16CB1
	jmp	(a5)
P16CBA:	subi.l	#$10000,d2
	bcs	P16CB8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16C1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16CB1
	jmp	(a5)
P16CC1:	sub.w	a2,d2
	bcs	P16CC3
P16CC2:	move.w	(a0),d0
	adda.w	a2,a0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16CB1
	jmp	(a5)
P16CC3:	subi.l	#$10000,d2
	bcc	P16CC2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16CC7
	lea	P16CC5(pc),a4
P16CC4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16CX-P16CC5
P16CC5:	sub.w	d1,d2
	bcs	P16CC6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16C1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16CB1
	jmp	(a5)
P16CC6:	subi.l	#$10000,d2
	bcs	P16CC4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16C1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16CB1
	jmp	(a5)
P16CC7:	lea	P16CC9(pc),a4
	addq.l	#2,a1
P16CC8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16CX-P16CC9
P16CC9:	sub.w	d1,d2
	bcs	P16CCA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16C1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16CB1
	jmp	(a5)
P16CCA:	subi.l	#$10000,d2
	bcs	P16CC8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16C1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16CB1
	jmp	(a5)

	.endm

*-------
P16D	.macro	P16D1
	.local	P16DA,P16DB,P16DC,P16DX,P16DA0
	.local	P16DA1,P16DA2,P16DA3,P16DA4,P16DA5,P16DA6
	.local	P16DA7,P16DA8
	.local	P16DB1,P16DB2,P16DB3,P16DB4,P16DB5,P16DB6
	.local	P16DB7,P16DB8,P16DB9,P16DBA
	.local	P16DC1,P16DC2,P16DC3,P16DC4,P16DC5,P16DC6
	.local	P16DC7,P16DC8,P16DC9,P16DCA

	.dc.w	P16DA0-P16DA
P16DA:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	P16DB
	dbra	d3,P16DA1
	jmp	(a5)
	.dc.w	P16DX-P16DA0
P16DA0:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	P16DB
	dbra	d3,P16DA1
	jmp	(a5)
P16DA1:	add.w	d5,d4
	bcc	P16DA3
	subq.w	#2,d2
	bcs	P16DA4
P16DA2:	move.w	(a0)+,d0
	move.w	d0,d6
	asr.w	#P16D1,d6
	add.w	d6,d0
P16DA3:	add.w	d0,(a1)+
	dbra	d3,P16DA1
	jmp	(a5)
P16DA4:	subi.l	#$10000,d2
	bcc	P16DA2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16DA7
	lea	P16DA6(pc),a4
P16DA5:	jmp	(a5)
	.dc.w	P16DX-P16DA6
P16DA6:	subq.l	#2,d2
	bcs	P16DA5
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0)+,d0
	move.w	d0,d6
	asr.w	#P16D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16DA1
	jmp	(a5)
P16DA7:	lea	P16DA8(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	P16DX-P16DA8
P16DA8:	subq.l	#2,d2
	bcs	P16DA5
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0)+,d0
	move.w	d0,d6
	asr.w	#P16D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16DA1
P16DX:	jmp	(a5)

P16DB:	move.l	d5,d7
	swap	d7
	add.w	d7,d7
	movea.l	d7,a2
	addq.w	#2,d7
	dbra	d3,P16DB1
	jmp	(a5)
P16DB1:	add.w	d5,d4
	bcc	P16DC1
	sub.w	d7,d2
	bcs	P16DB3
P16DB2:	move.w	(a0),d0
	adda.w	d7,a0
	move.w	d0,d6
	asr.w	#P16D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16DB1
	jmp	(a5)
P16DB3:	subi.l	#$10000,d2
	bcc	P16DB2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16DB7
	lea	P16DB5(pc),a4
P16DB4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16DX-P16DB5
P16DB5:	sub.w	d1,d2
	bcs	P16DB6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#P16D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16DB1
	jmp	(a5)
P16DB6:	subi.l	#$10000,d2
	bcs	P16DB4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#P16D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16DB1
	jmp	(a5)
P16DB7:	lea	P16DB9(pc),a4
	addq.l	#2,a1
P16DB8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16DX-P16DB9
P16DB9:	sub.w	d1,d2
	bcs	P16DBA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#P16D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16DB1
	jmp	(a5)
P16DBA:	subi.l	#$10000,d2
	bcs	P16DB8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#P16D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16DB1
	jmp	(a5)
P16DC1:	sub.w	a2,d2
	bcs	P16DC3
P16DC2:	move.w	(a0),d0
	adda.w	a2,a0
	move.w	d0,d6
	asr.w	#P16D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16DB1
	jmp	(a5)
P16DC3:	subi.l	#$10000,d2
	bcc	P16DC2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16DC7
	lea	P16DC5(pc),a4
P16DC4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16DX-P16DC5
P16DC5:	sub.w	d1,d2
	bcs	P16DC6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#P16D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16DB1
	jmp	(a5)
P16DC6:	subi.l	#$10000,d2
	bcs	P16DC4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#P16D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16DB1
	jmp	(a5)
P16DC7:	lea	P16DC9(pc),a4
	addq.l	#2,a1
P16DC8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16DX-P16DC9
P16DC9:	sub.w	d1,d2
	bcs	P16DCA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#P16D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16DB1
	jmp	(a5)
P16DCA:	subi.l	#$10000,d2
	bcs	P16DC8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#P16D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16DB1
	jmp	(a5)

	.endm

*-------
P16E	.macro	P16E1
	.local	P16EA,P16EB,P16EC,P16EX,P16EA0
	.local	P16EA1,P16EA2,P16EA3,P16EA4,P16EA5,P16EA6
	.local	P16EA7,P16EA8
	.local	P16EB1,P16EB2,P16EB3,P16EB4,P16EB5,P16EB6
	.local	P16EB7,P16EB8,P16EB9,P16EBA
	.local	P16EC1,P16EC2,P16EC3,P16EC4,P16EC5,P16EC6
	.local	P16EC7,P16EC8,P16EC9,P16ECA

	.dc.w	P16EA0-P16EA
P16EA:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	P16EB
	dbra	d3,P16EA1
	jmp	(a5)
	.dc.w	P16EX-P16EA0
P16EA0:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	P16EB
	dbra	d3,P16EA1
	jmp	(a5)
P16EA1:	add.w	d5,d4
	bcc	P16EA3
	subq.w	#2,d2
	bcs	P16EA4
P16EA2:	move.w	(a0)+,d0
	asr.w	#P16E1,d0
P16EA3:	add.w	d0,(a1)+
	dbra	d3,P16EA1
	jmp	(a5)
P16EA4:	subi.l	#$10000,d2
	bcc	P16EA2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16EA7
	lea	P16EA6(pc),a4
P16EA5:	jmp	(a5)
	.dc.w	P16EX-P16EA6
P16EA6:	subq.l	#2,d2
	bcs	P16EA5
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0)+,d0
	asr.w	#P16E1,d0
	add.w	d0,(a1)+
	dbra	d3,P16EA1
	jmp	(a5)
P16EA7:	lea	P16EA8(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	P16EX-P16EA8
P16EA8:	subq.l	#2,d2
	bcs	P16EA5
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0)+,d0
	asr.w	#P16E1,d0
	add.w	d0,(a1)+
	dbra	d3,P16EA1
P16EX:	jmp	(a5)

P16EB:	move.l	d5,d7
	swap	d7
	add.w	d7,d7
	movea.l	d7,a2
	addq.w	#2,d7
	dbra	d3,P16EB1
	jmp	(a5)
P16EB1:	add.w	d5,d4
	bcc	P16EC1
	sub.w	d7,d2
	bcs	P16EB3
P16EB2:	move.w	(a0),d0
	adda.w	d7,a0
	asr.w	#P16E1,d0
	add.w	d0,(a1)+
	dbra	d3,P16EB1
	jmp	(a5)
P16EB3:	subi.l	#$10000,d2
	bcc	P16EB2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16EB7
	lea	P16EB5(pc),a4
P16EB4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16EX-P16EB5
P16EB5:	sub.w	d1,d2
	bcs	P16EB6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	asr.w	#P16E1,d0
	add.w	d0,(a1)+
	dbra	d3,P16EB1
	jmp	(a5)
P16EB6:	subi.l	#$10000,d2
	bcs	P16EB4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	asr.w	#P16E1,d0
	add.w	d0,(a1)+
	dbra	d3,P16EB1
	jmp	(a5)
P16EB7:	lea	P16EB9(pc),a4
	addq.l	#2,a1
P16EB8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16EX-P16EB9
P16EB9:	sub.w	d1,d2
	bcs	P16EBA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	asr.w	#P16E1,d0
	add.w	d0,(a1)+
	dbra	d3,P16EB1
	jmp	(a5)
P16EBA:	subi.l	#$10000,d2
	bcs	P16EB8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	asr.w	#P16E1,d0
	add.w	d0,(a1)+
	dbra	d3,P16EB1
	jmp	(a5)
P16EC1:	sub.w	a2,d2
	bcs	P16EC3
P16EC2:	move.w	(a0),d0
	adda.w	a2,a0
	asr.w	#P16E1,d0
	add.w	d0,(a1)+
	dbra	d3,P16EB1
	jmp	(a5)
P16EC3:	subi.l	#$10000,d2
	bcc	P16EC2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16EC7
	lea	P16EC5(pc),a4
P16EC4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16EX-P16EC5
P16EC5:	sub.w	d1,d2
	bcs	P16EC6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	asr.w	#P16E1,d0
	add.w	d0,(a1)+
	dbra	d3,P16EB1
	jmp	(a5)
P16EC6:	subi.l	#$10000,d2
	bcs	P16EC4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	asr.w	#P16E1,d0
	add.w	d0,(a1)+
	dbra	d3,P16EB1
	jmp	(a5)
P16EC7:	lea	P16EC9(pc),a4
	addq.l	#2,a1
P16EC8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16EX-P16EC9
P16EC9:	sub.w	d1,d2
	bcs	P16ECA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	asr.w	#P16E1,d0
	add.w	d0,(a1)+
	dbra	d3,P16EB1
	jmp	(a5)
P16ECA:	subi.l	#$10000,d2
	bcs	P16EC8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	asr.w	#P16E1,d0
	add.w	d0,(a1)+
	dbra	d3,P16EB1
	jmp	(a5)

	.endm

*-------
P16F	.macro	P16F1,P16F2
	.local	P16FA,P16FB,P16FC,P16FX,P16FA0
	.local	P16FA1,P16FA2,P16FA3,P16FA4,P16FA5,P16FA6
	.local	P16FA7,P16FA8
	.local	P16FB1,P16FB2,P16FB3,P16FB4,P16FB5,P16FB6
	.local	P16FB7,P16FB8,P16FB9,P16FBA
	.local	P16FC1,P16FC2,P16FC3,P16FC4,P16FC5,P16FC6
	.local	P16FC7,P16FC8,P16FC9,P16FCA

	.dc.w	P16FA0-P16FA
P16FA:	add.w	d3,d3
	moveq	#P16F1,d1
	cmpi.l	#$10000,d5
	bcc	P16FB
	dbra	d3,P16FA1
	jmp	(a5)
	.dc.w	P16FX-P16FA0
P16FA0:	add.w	d3,d3
	moveq	#P16F1,d1
	cmpi.l	#$10000,d5
	bcc	P16FB
	dbra	d3,P16FA1
	jmp	(a5)
P16FA1:	add.w	d5,d4
	bcc	P16FA3
	subq.w	#2,d2
	bcs	P16FA4
P16FA2:	move.w	(a0)+,d0
	asr.w	d1,d0
	move.w	d0,d6
	asr.w	#P16F2,d6
	add.w	d6,d0
P16FA3:	add.w	d0,(a1)+
	dbra	d3,P16FA1
	jmp	(a5)
P16FA4:	subi.l	#$10000,d2
	bcc	P16FA2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16FA7
	lea	P16FA6(pc),a4
P16FA5:	jmp	(a5)
	.dc.w	P16FX-P16FA6
P16FA6:	subq.l	#2,d2
	bcs	P16FA5
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0)+,d0
	asr.w	d1,d0
	move.w	d0,d6
	asr.w	#P16F2,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16FA1
	jmp	(a5)
P16FA7:	lea	P16FA8(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	P16FX-P16FA8
P16FA8:	subq.l	#2,d2
	bcs	P16FA5
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0)+,d0
	asr.w	d1,d0
	move.w	d0,d6
	asr.w	#P16F2,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16FA1
P16FX:	jmp	(a5)

P16FB:	move.l	d5,d7
	swap	d7
	add.w	d7,d7
	movea.l	d7,a2
	addq.w	#2,d7
	dbra	d3,P16FB1
	jmp	(a5)
P16FB1:	add.w	d5,d4
	bcc	P16FC1
	sub.w	d7,d2
	bcs	P16FB3
P16FB2:	move.w	(a0),d0
	adda.w	d7,a0
	asr.w	d1,d0
	move.w	d0,d6
	asr.w	#P16F2,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16FB1
	jmp	(a5)
P16FB3:	subi.l	#$10000,d2
	bcc	P16FB2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16FB7
	lea	P16FB5(pc),a4
P16FB4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16FX-P16FB5
P16FB5:	sub.w	d1,d2
	bcs	P16FB6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16F1,d1
	asr.w	d1,d0
	move.w	d0,d6
	asr.w	#P16F2,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16FB1
	jmp	(a5)
P16FB6:	subi.l	#$10000,d2
	bcs	P16FB4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16F1,d1
	asr.w	d1,d0
	move.w	d0,d6
	asr.w	#P16F2,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16FB1
	jmp	(a5)
P16FB7:	lea	P16FB9(pc),a4
	addq.l	#2,a1
P16FB8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16FX-P16FB9
P16FB9:	sub.w	d1,d2
	bcs	P16FBA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16F1,d1
	asr.w	d1,d0
	move.w	d0,d6
	asr.w	#P16F2,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16FB1
	jmp	(a5)
P16FBA:	subi.l	#$10000,d2
	bcs	P16FB8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16F1,d1
	asr.w	d1,d0
	move.w	d0,d6
	asr.w	#P16F2,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16FB1
	jmp	(a5)
P16FC1:	sub.w	a2,d2
	bcs	P16FC3
P16FC2:	move.w	(a0),d0
	adda.w	a2,a0
	asr.w	d1,d0
	move.w	d0,d6
	asr.w	#P16F2,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16FB1
	jmp	(a5)
P16FC3:	subi.l	#$10000,d2
	bcc	P16FC2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16FC7
	lea	P16FC5(pc),a4
P16FC4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16FX-P16FC5
P16FC5:	sub.w	d1,d2
	bcs	P16FC6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16F1,d1
	asr.w	d1,d0
	move.w	d0,d6
	asr.w	#P16F2,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16FB1
	jmp	(a5)
P16FC6:	subi.l	#$10000,d2
	bcs	P16FC4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16F1,d1
	asr.w	d1,d0
	move.w	d0,d6
	asr.w	#P16F2,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16FB1
	jmp	(a5)
P16FC7:	lea	P16FC5(pc),a4
	addq.l	#2,a1
P16FC8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16FX-P16FC9
P16FC9:	sub.w	d1,d2
	bcs	P16FCA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16F1,d1
	asr.w	d1,d0
	move.w	d0,d6
	asr.w	#P16F2,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16FB1
	jmp	(a5)
P16FCA:	subi.l	#$10000,d2
	bcs	P16FC8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	moveq	#P16F1,d1
	asr.w	d1,d0
	move.w	d0,d6
	asr.w	#P16F2,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P16FB1
	jmp	(a5)

	.endm

*-------
PC8A	.macro	PC8A1
	.local	PC8AA,PC8AB,PC8AC,PC8AX,PC8AA0
	.local	PC8AA1,PC8AA2,PC8AA3,PC8AA4,PC8AA5,PC8AA6
	.local	PC8AA7,PC8AA8
	.local	PC8AB1,PC8AB2,PC8AB3,PC8AB4,PC8AB5,PC8AB6
	.local	PC8AB7,PC8AB8,PC8AB9,PC8ABA
	.local	PC8AC1,PC8AC2,PC8AC3,PC8AC4,PC8AC5,PC8AC6
	.local	PC8AC7,PC8AC8,PC8AC9,PC8ACA

	.dc.w	PC8AA0-PC8AA
PC8AA:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	PC8AB
	dbra	d3,PC8AA1
	jmp	(a5)
	.dc.w	PC8AX-PC8AA0
PC8AA0:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	PC8AB
	dbra	d3,PC8AA1
	jmp	(a5)
PC8AA1:	add.w	d5,d4
	bcc	PC8AA3
	subq.w	#1,d2
	bcs	PC8AA4
PC8AA2:	move.b	(a0)+,d0
	ext.w	d0
	asl.w	#PC8A1,d0
PC8AA3:	add.w	d0,(a1)+
	dbra	d3,PC8AA1
	jmp	(a5)
PC8AA4:	subi.l	#$10000,d2
	bcc	PC8AA2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8AA7
	lea	PC8AA6(pc),a4
PC8AA5:	jmp	(a5)
	.dc.w	PC8AX-PC8AA6
PC8AA6:	subq.l	#1,d2
	bcs	PC8AA5
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0)+,d0
	ext.w	d0
	asl.w	#PC8A1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8AA1
	jmp	(a5)
PC8AA7:	lea	PC8AA8(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	PC8AX-PC8AA8
PC8AA8:	subq.l	#1,d2
	bcs	PC8AA5
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0)+,d0
	ext.w	d0
	asl.w	#PC8A1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8AA1
PC8AX:	jmp	(a5)

PC8AB:	move.l	d5,d7
	swap	d7
	movea.w	d7,a2
	addq.w	#1,d7
	dbra	d3,PC8AB1
	jmp	(a5)
PC8AB1:	add.w	d5,d4
	bcc	PC8AC1
	sub.w	d7,d2
	bcs	PC8AB3
PC8AB2:	move.b	(a0),d0
	ext.w	d0
	adda.w	d7,a0
	asl.w	#PC8A1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8AB1
	jmp	(a5)
PC8AB3:	subi.l	#$10000,d2
	bcc	PC8AB2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8AB7
	lea	PC8AB5(pc),a4
PC8AB4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8AX-PC8AB5
PC8AB5:	sub.w	d1,d2
	bcs	PC8AB6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	asl.w	#PC8A1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8AB1
	jmp	(a5)
PC8AB6:	subi.l	#$10000,d2
	bcs	PC8AB4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	asl.w	#PC8A1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8AB1
	jmp	(a5)
PC8AB7:	lea	PC8AB9(pc),a4
	addq.l	#2,a1
PC8AB8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8AX-PC8AB9
PC8AB9:	sub.w	d1,d2
	bcs	PC8ABA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	asl.w	#PC8A1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8AB1
	jmp	(a5)
PC8ABA:	subi.l	#$10000,d2
	bcs	PC8AB8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	asl.w	#PC8A1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8AB1
	jmp	(a5)
PC8AC1:	sub.w	a2,d2
	bcs	PC8AC3
PC8AC2:	move.b	(a0),d0
	ext.w	d0
	adda.w	a2,a0
	asl.w	#PC8A1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8AB1
	jmp	(a5)
PC8AC3:	subi.l	#$10000,d2
	bcc	PC8AC2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8AC7
	lea	PC8AC5(pc),a4
PC8AC4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8AX-PC8AC5
PC8AC5:	sub.w	d1,d2
	bcs	PC8AC6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	asl.w	#PC8A1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8AB1
	jmp	(a5)
PC8AC6:	subi.l	#$10000,d2
	bcs	PC8AC4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	asl.w	#PC8A1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8AB1
	jmp	(a5)
PC8AC7:	lea	PC8AC9(pc),a4
	addq.l	#2,a1
PC8AC8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8AX-PC8AC9
PC8AC9:	sub.w	d1,d2
	bcs	PC8ACA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	asl.w	#PC8A1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8AB1
	jmp	(a5)
PC8ACA:	subi.l	#$10000,d2
	bcs	PC8AC8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	asl.w	#PC8A1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8AB1
	jmp	(a5)

	.endm

*-------
PC8B	.macro	PC8B1
	.local	PC8BA,PC8BB,PC8BC,PC8BX,PC8BA0
	.local	PC8BA1,PC8BA2,PC8BA3,PC8BA4,PC8BA5,PC8BA6
	.local	PC8BA7,PC8BA8
	.local	PC8BB1,PC8BB2,PC8BB3,PC8BB4,PC8BB5,PC8BB6
	.local	PC8BB7,PC8BB8,PC8BB9,PC8BBA
	.local	PC8BC1,PC8BC2,PC8BC3,PC8BC4,PC8BC5,PC8BC6
	.local	PC8BC7,PC8BC8,PC8BC9,PC8BCA

	.dc.w	PC8BA0-PC8BA
PC8BA:	add.w	d3,d3
	moveq	#PC8B1,d1
	cmpi.l	#$10000,d5
	bcc	PC8BB
	dbra	d3,PC8BA1
	jmp	(a5)
	.dc.w	PC8BX-PC8BA0
PC8BA0:	add.w	d3,d3
	moveq	#PC8B1,d1
	cmpi.l	#$10000,d5
	bcc	PC8BB
	dbra	d3,PC8BA1
	jmp	(a5)
PC8BA1:	add.w	d5,d4
	bcc	PC8BA3
	subq.w	#1,d2
	bcs	PC8BA4
PC8BA2:	move.b	(a0)+,d0
	ext.w	d0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
PC8BA3:	add.w	d0,(a1)+
	dbra	d3,PC8BA1
	jmp	(a5)
PC8BA4:	subi.l	#$10000,d2
	bcc	PC8BA2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8BA7
	lea	PC8BA6(pc),a4
PC8BA5:	jmp	(a5)
	.dc.w	PC8BX-PC8BA6
PC8BA6:	subq.l	#1,d2
	bcs	PC8BA5
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0)+,d0
	ext.w	d0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8BA1
	jmp	(a5)
PC8BA7:	lea	PC8BA8(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	PC8BX-PC8BA8
PC8BA8:	subq.l	#1,d2
	bcs	PC8BA5
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0)+,d0
	ext.w	d0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8BA1
PC8BX:	jmp	(a5)

PC8BB:	move.l	d5,d7
	swap	d7
	movea.w	d7,a2
	addq.w	#1,d7
	dbra	d3,PC8BB1
	jmp	(a5)
PC8BB1:	add.w	d5,d4
	bcc	PC8BC1
	sub.w	d7,d2
	bcs	PC8BB3
PC8BB2:	move.b	(a0),d0
	ext.w	d0
	adda.w	d7,a0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8BB1
	jmp	(a5)
PC8BB3:	subi.l	#$10000,d2
	bcc	PC8BB2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8BB7
	lea	PC8BB5(pc),a4
PC8BB4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8BX-PC8BB5
PC8BB5:	sub.w	d1,d2
	bcs	PC8BB6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	moveq	#PC8B1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8BB1
	jmp	(a5)
PC8BB6:	subi.l	#$10000,d2
	bcs	PC8BB4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	moveq	#PC8B1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8BB1
	jmp	(a5)
PC8BB7:	lea	PC8BB9(pc),a4
	addq.l	#2,a1
PC8BB8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8BX-PC8BB9
PC8BB9:	sub.w	d1,d2
	bcs	PC8BBA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	moveq	#PC8B1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8BB1
	jmp	(a5)
PC8BBA:	subi.l	#$10000,d2
	bcs	PC8BB8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	moveq	#PC8B1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8BB1
	jmp	(a5)
PC8BC1:	sub.w	a2,d2
	bcs	PC8BC3
PC8BC2:	move.b	(a0),d0
	ext.w	d0
	adda.w	a2,a0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8BB1
	jmp	(a5)
PC8BC3:	subi.l	#$10000,d2
	bcc	PC8BC2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8BC7
	lea	PC8BC5(pc),a4
PC8BC4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8BX-PC8BC5
PC8BC5:	sub.w	d1,d2
	bcs	PC8BC6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	moveq	#PC8B1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8BB1
	jmp	(a5)
PC8BC6:	subi.l	#$10000,d2
	bcs	PC8BC4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	moveq	#PC8B1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8BB1
	jmp	(a5)
PC8BC7:	lea	PC8BC9(pc),a4
	addq.l	#2,a1
PC8BC8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8BX-PC8BC9
PC8BC9:	sub.w	d1,d2
	bcs	PC8BCA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	moveq	#PC8B1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8BB1
	jmp	(a5)
PC8BCA:	subi.l	#$10000,d2
	bcs	PC8BC8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	moveq	#PC8B1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8BB1
	jmp	(a5)

	.endm

*-------
PC8C	.macro	PC8C1
	.local	PC8CA,PC8CB,PC8CC,PC8CX,PC8CA0
	.local	PC8CA1,PC8CA2,PC8CA3,PC8CA4,PC8CA5,PC8CA6
	.local	PC8CA7,PC8CA8
	.local	PC8CB1,PC8CB2,PC8CB3,PC8CB4,PC8CB5,PC8CB6
	.local	PC8CB7,PC8CB8,PC8CB9,PC8CBA
	.local	PC8CC1,PC8CC2,PC8CC3,PC8CC4,PC8CC5,PC8CC6
	.local	PC8CC7,PC8CC8,PC8CC9,PC8CCA

	.dc.w	PC8CA0-PC8CA
PC8CA:	add.w	d3,d3
	moveq	#PC8C1,d1
	cmpi.l	#$10000,d5
	bcc	PC8CB
	dbra	d3,PC8CA1
	jmp	(a5)
	.dc.w	PC8CX-PC8CA0
PC8CA0:	add.w	d3,d3
	moveq	#PC8C1,d1
	cmpi.l	#$10000,d5
	bcc	PC8CB
	dbra	d3,PC8CA1
	jmp	(a5)
PC8CA1:	add.w	d5,d4
	bcc	PC8CA3
	subq.w	#1,d2
	bcs	PC8CA4
PC8CA2:	move.b	(a0)+,d0
	ext.w	d0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
PC8CA3:	add.w	d0,(a1)+
	dbra	d3,PC8CA1
	jmp	(a5)
PC8CA4:	subi.l	#$10000,d2
	bcc	PC8CA2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8CA7
	lea	PC8CA6(pc),a4
PC8CA5:	jmp	(a5)
	.dc.w	PC8CX-PC8CA6
PC8CA6:	subq.l	#1,d2
	bcs	PC8CA5
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0)+,d0
	ext.w	d0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8CA1
	jmp	(a5)
PC8CA7:	lea	PC8CA8(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	PC8CX-PC8CA8
PC8CA8:	subq.l	#1,d2
	bcs	PC8CA5
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0)+,d0
	ext.w	d0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8CA1
PC8CX:	jmp	(a5)

PC8CB:	move.l	d5,d7
	swap	d7
	movea.w	d7,a2
	addq.w	#1,d7
	dbra	d3,PC8CB1
	jmp	(a5)
PC8CB1:	add.w	d5,d4
	bcc	PC8CC1
	sub.w	d7,d2
	bcs	PC8CB3
PC8CB2:	move.b	(a0),d0
	ext.w	d0
	adda.w	d7,a0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8CB1
	jmp	(a5)
PC8CB3:	subi.l	#$10000,d2
	bcc	PC8CB2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8CB7
	lea	PC8CB5(pc),a4
PC8CB4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8CX-PC8CB5
PC8CB5:	sub.w	d1,d2
	bcs	PC8CB6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	moveq	#PC8C1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8CB1
	jmp	(a5)
PC8CB6:	subi.l	#$10000,d2
	bcs	PC8CB4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	moveq	#PC8C1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8CB1
	jmp	(a5)
PC8CB7:	lea	PC8CB9(pc),a4
	addq.l	#2,a1
PC8CB8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8CX-PC8CB9
PC8CB9:	sub.w	d1,d2
	bcs	PC8CBA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	moveq	#PC8C1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8CB1
	jmp	(a5)
PC8CBA:	subi.l	#$10000,d2
	bcs	PC8CB8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	moveq	#PC8C1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8CB1
	jmp	(a5)
PC8CC1:	sub.w	a2,d2
	bcs	PC8CC3
PC8CC2:	move.b	(a0),d0
	ext.w	d0
	adda.w	a2,a0
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8CB1
	jmp	(a5)
PC8CC3:	subi.l	#$10000,d2
	bcc	PC8CC2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8CC7
	lea	PC8CC5(pc),a4
PC8CC4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8CX-PC8CC5
PC8CC5:	sub.w	d1,d2
	bcs	PC8CC6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	moveq	#PC8C1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8CB1
	jmp	(a5)
PC8CC6:	subi.l	#$10000,d2
	bcs	PC8CC4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	moveq	#PC8C1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8CB1
	jmp	(a5)
PC8CC7:	lea	PC8CC9(pc),a4
	addq.l	#2,a1
PC8CC8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8CX-PC8CC9
PC8CC9:	sub.w	d1,d2
	bcs	PC8CCA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	moveq	#PC8C1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8CB1
	jmp	(a5)
PC8CCA:	subi.l	#$10000,d2
	bcs	PC8CC8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	moveq	#PC8C1,d1
	asl.w	d1,d0
	move.w	d0,d6
	add.w	d0,d0
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8CB1
	jmp	(a5)

	.endm

*-------
PC8D	.macro	PC8D1
	.local	PC8DA,PC8DB,PC8DC,PC8DX,PC8DA0
	.local	PC8DA1,PC8DA2,PC8DA3,PC8DA4,PC8DA5,PC8DA6
	.local	PC8DA7,PC8DA8
	.local	PC8DB1,PC8DB2,PC8DB3,PC8DB4,PC8DB5,PC8DB6
	.local	PC8DB7,PC8DB8,PC8DB9,PC8DBA
	.local	PC8DC1,PC8DC2,PC8DC3,PC8DC4,PC8DC5,PC8DC6
	.local	PC8DC7,PC8DC8,PC8DC9,PC8DCA

	.dc.w	PC8DA0-PC8DA
PC8DA:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	PC8DB
	dbra	d3,PC8DA1
	jmp	(a5)
	.dc.w	PC8DX-PC8DA0
PC8DA0:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	PC8DB
	dbra	d3,PC8DA1
	jmp	(a5)
PC8DA1:	add.w	d5,d4
	bcc	PC8DA3
	subq.w	#1,d2
	bcs	PC8DA4
PC8DA2:	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,d6
	asr.w	#PC8D1,d6
	add.w	d6,d0
PC8DA3:	add.w	d0,(a1)+
	dbra	d3,PC8DA1
	jmp	(a5)
PC8DA4:	subi.l	#$10000,d2
	bcc	PC8DA2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8DA7
	lea	PC8DA6(pc),a4
PC8DA5:	jmp	(a5)
	.dc.w	PC8DX-PC8DA6
PC8DA6:	subq.l	#1,d2
	bcs	PC8DA5
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,d6
	asr.w	#PC8D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8DA1
	jmp	(a5)
PC8DA7:	lea	PC8DA8(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	PC8DX-PC8DA8
PC8DA8:	subq.l	#1,d2
	bcs	PC8DA5
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,d6
	asr.w	#PC8D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8DA1
PC8DX:	jmp	(a5)

PC8DB:	move.l	d5,d7
	swap	d7
	movea.w	d7,a2
	addq.w	#1,d7
	dbra	d3,PC8DB1
	jmp	(a5)
PC8DB1:	add.w	d5,d4
	bcc	PC8DC1
	sub.w	d7,d2
	bcs	PC8DB3
PC8DB2:	move.b	(a0),d0
	ext.w	d0
	adda.w	d7,a0
	move.w	d0,d6
	asr.w	#PC8D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8DB1
	jmp	(a5)
PC8DB3:	subi.l	#$10000,d2
	bcc	PC8DB2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8DB7
	lea	PC8DB5(pc),a4
PC8DB4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8DX-PC8DB5
PC8DB5:	sub.w	d1,d2
	bcs	PC8DB6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#PC8D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8DB1
	jmp	(a5)
PC8DB6:	subi.l	#$10000,d2
	bcs	PC8DB4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#PC8D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8DB1
	jmp	(a5)
PC8DB7:	lea	PC8DB9(pc),a4
	addq.l	#2,a1
PC8DB8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8DX-PC8DB9
PC8DB9:	sub.w	d1,d2
	bcs	PC8DBA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#PC8D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8DB1
	jmp	(a5)
PC8DBA:	subi.l	#$10000,d2
	bcs	PC8DB8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#PC8D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8DB1
	jmp	(a5)
PC8DC1:	sub.w	a2,d2
	bcs	PC8DC3
PC8DC2:	move.b	(a0),d0
	ext.w	d0
	adda.w	a2,a0
	move.w	d0,d6
	asr.w	#PC8D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8DB1
	jmp	(a5)
PC8DC3:	subi.l	#$10000,d2
	bcc	PC8DC2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8DC7
	lea	PC8DC5(pc),a4
PC8DC4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8DX-PC8DC5
PC8DC5:	sub.w	d1,d2
	bcs	PC8DC6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#PC8D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8DB1
	jmp	(a5)
PC8DC6:	subi.l	#$10000,d2
	bcs	PC8DC4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#PC8D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8DB1
	jmp	(a5)
PC8DC7:	lea	PC8DC9(pc),a4
	addq.l	#2,a1
PC8DC8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8DX-PC8DC9
PC8DC9:	sub.w	d1,d2
	bcs	PC8DCA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#PC8D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8DB1
	jmp	(a5)
PC8DCA:	subi.l	#$10000,d2
	bcs	PC8DC8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#PC8D1,d6
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,PC8DB1
	jmp	(a5)

	.endm

*-------
PC8E	.macro	PC8E1
	.local	PC8EA,PC8EB,PC8EC,PC8EX,PC8EA0
	.local	PC8EA1,PC8EA2,PC8EA3,PC8EA4,PC8EA5,PC8EA6
	.local	PC8EA7,PC8EA8
	.local	PC8EB1,PC8EB2,PC8EB3,PC8EB4,PC8EB5,PC8EB6
	.local	PC8EB7,PC8EB8,PC8EB9,PC8EBA
	.local	PC8EC1,PC8EC2,PC8EC3,PC8EC4,PC8EC5,PC8EC6
	.local	PC8EC7,PC8EC8,PC8EC9,PC8ECA

	.dc.w	PC8EA0-PC8EA
PC8EA:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	PC8EB
	dbra	d3,PC8EA1
	jmp	(a5)
	.dc.w	PC8EX-PC8EA0
PC8EA0:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	PC8EB
	dbra	d3,PC8EA1
	jmp	(a5)
PC8EA1:	add.w	d5,d4
	bcc	PC8EA3
	subq.w	#1,d2
	bcs	PC8EA4
PC8EA2:	move.b	(a0)+,d0
	ext.w	d0
	asr.w	#PC8E1,d0
PC8EA3:	add.w	d0,(a1)+
	dbra	d3,PC8EA1
	jmp	(a5)
PC8EA4:	subi.l	#$10000,d2
	bcc	PC8EA2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8EA7
	lea	PC8EA6(pc),a4
PC8EA5:	jmp	(a5)
	.dc.w	PC8EX-PC8EA6
PC8EA6:	subq.l	#1,d2
	bcs	PC8EA5
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0)+,d0
	ext.w	d0
	asr.w	#PC8E1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8EA1
	jmp	(a5)
PC8EA7:	lea	PC8EA8(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	PC8EX-PC8EA8
PC8EA8:	subq.l	#1,d2
	bcs	PC8EA5
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0)+,d0
	ext.w	d0
	asr.w	#PC8E1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8EA1
PC8EX:	jmp	(a5)

PC8EB:	move.l	d5,d7
	swap	d7
	movea.w	d7,a2
	addq.w	#1,d7
	dbra	d3,PC8EB1
	jmp	(a5)
PC8EB1:	add.w	d5,d4
	bcc	PC8EC1
	sub.w	d7,d2
	bcs	PC8EB3
PC8EB2:	move.b	(a0),d0
	ext.w	d0
	adda.w	d7,a0
	asr.w	#PC8E1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8EB1
	jmp	(a5)
PC8EB3:	subi.l	#$10000,d2
	bcc	PC8EB2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8EB7
	lea	PC8EB5(pc),a4
PC8EB4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8EX-PC8EB5
PC8EB5:	sub.w	d1,d2
	bcs	PC8EB6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	asr.w	#PC8E1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8EB1
	jmp	(a5)
PC8EB6:	subi.l	#$10000,d2
	bcs	PC8EB4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	asr.w	#PC8E1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8EB1
	jmp	(a5)
PC8EB7:	lea	PC8EB9(pc),a4
	addq.l	#2,a1
PC8EB8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8EX-PC8EB9
PC8EB9:	sub.w	d1,d2
	bcs	PC8EBA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	asr.w	#PC8E1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8EB1
	jmp	(a5)
PC8EBA:	subi.l	#$10000,d2
	bcs	PC8EB8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	asr.w	#PC8E1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8EB1
	jmp	(a5)
PC8EC1:	sub.w	a2,d2
	bcs	PC8EC3
PC8EC2:	move.b	(a0),d0
	ext.w	d0
	adda.w	a2,a0
	asr.w	#PC8E1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8EB1
	jmp	(a5)
PC8EC3:	subi.l	#$10000,d2
	bcc	PC8EC2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8EC7
	lea	PC8EC5(pc),a4
PC8EC4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8EX-PC8EC5
PC8EC5:	sub.w	d1,d2
	bcs	PC8EC6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	asr.w	#PC8E1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8EB1
	jmp	(a5)
PC8EC6:	subi.l	#$10000,d2
	bcs	PC8EC4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	asr.w	#PC8E1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8EB1
	jmp	(a5)
PC8EC7:	lea	PC8EC9(pc),a4
	addq.l	#2,a1
PC8EC8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8EX-PC8EC9
PC8EC9:	sub.w	d1,d2
	bcs	PC8ECA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	asr.w	#PC8E1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8EB1
	jmp	(a5)
PC8ECA:	subi.l	#$10000,d2
	bcs	PC8EC8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	ext.w	d0
	adda.w	d1,a0
	asr.w	#PC8E1,d0
	add.w	d0,(a1)+
	dbra	d3,PC8EB1
	jmp	(a5)

	.endm

*-------
PC8F	.macro
	.local	PC8FA,PC8FB,PC8FC,PC8FX,PC8FY,PC8FA0
	.local	PC8FA1,PC8FA2,PC8FA3,PC8FA4,PC8FA5,PC8FA6
	.local	PC8FA7,PC8FA8
	.local	PC8FB1,PC8FB2,PC8FB3,PC8FB4,PC8FB5,PC8FB6
	.local	PC8FB7,PC8FB8,PC8FB9,PC8FBA
	.local	PC8FC1,PC8FC2,PC8FC3,PC8FC4,PC8FC5,PC8FC6
	.local	PC8FC7,PC8FC8,PC8FC9,PC8FCA

	.dc.w	PC8FA0-PC8FA
PC8FA:	add.w	d3,d3
	lea	PC8FY(pc),a2
	cmpi.l	#$10000,d5
	bcc	PC8FB
	dbra	d3,PC8FA1
	jmp	(a5)
	.dc.w	PC8FX-PC8FA0
PC8FA0:	add.w	d3,d3
	lea	PC8FY(pc),a2
	cmpi.l	#$10000,d5
	bcc	PC8FB
	dbra	d3,PC8FA1
	jmp	(a5)
PC8FA1:	add.w	d5,d4
	bcc	PC8FA3
	subq.w	#1,d2
	bcs	PC8FA4
PC8FA2:	move.b	(a0)+,d6
	move.b	(a2,d6.w),d0
	ext.w	d0
PC8FA3:	add.w	d0,(a1)+
	dbra	d3,PC8FA1
	jmp	(a5)
PC8FA4:	subi.l	#$10000,d2
	bcc	PC8FA2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8FA7
	lea	PC8FA6(pc),a4
PC8FA5:	jmp	(a5)
	.dc.w	PC8FX-PC8FA6
PC8FA6:	subq.l	#1,d2
	bcs	PC8FA5
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0)+,d6
	move.b	(a2,d6.w),d0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,PC8FA1
	jmp	(a5)
PC8FA7:	lea	PC8FA8(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	PC8FX-PC8FA8
PC8FA8:	subq.l	#1,d2
	bcs	PC8FA5
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0)+,d6
	move.b	(a2,d6.w),d0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,PC8FA1
PC8FX:	jmp	(a5)

PC8FB:	move.l	d5,d7
	swap	d7
	movea.w	d7,a3
	addq.w	#1,d7
	dbra	d3,PC8FB1
	jmp	(a5)
PC8FB1:	add.w	d5,d4
	bcc	PC8FC1
	sub.w	d7,d2
	bcs	PC8FB3
PC8FB2:	move.b	(a0),d6
	adda.w	d7,a0
	move.b	(a2,d6.w),d0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,PC8FB1
	jmp	(a5)
PC8FB3:	subi.l	#$10000,d2
	bcc	PC8FB2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8FB7
	lea	PC8FB5(pc),a4
PC8FB4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8FX-PC8FB5
PC8FB5:	sub.w	d1,d2
	bcs	PC8FB6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	subq.w	#1,d7
	movea.w	d7,a3
	addq.w	#1,d7
	move.b	(a0),d6
	adda.w	d1,a0
	move.b	(a2,d6.w),d0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,PC8FB1
	jmp	(a5)
PC8FB6:	subi.l	#$10000,d2
	bcs	PC8FB4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	subq.w	#1,d7
	movea.w	d7,a3
	addq.w	#1,d7
	move.b	(a0),d6
	adda.w	d1,a0
	move.b	(a2,d6.w),d0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,PC8FB1
	jmp	(a5)
PC8FB7:	lea	PC8FB9(pc),a4
	addq.l	#2,a1
PC8FB8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8FX-PC8FB9
PC8FB9:	sub.w	d1,d2
	bcs	PC8FBA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	subq.w	#1,d7
	movea.w	d7,a3
	addq.w	#1,d7
	move.b	(a0),d6
	adda.w	d1,a0
	move.b	(a2,d6.w),d0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,PC8FB1
	jmp	(a5)
PC8FBA:	subi.l	#$10000,d2
	bcs	PC8FB8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	subq.w	#1,d7
	movea.w	d7,a3
	addq.w	#1,d7
	move.b	(a0),d6
	adda.w	d1,a0
	move.b	(a2,d6.w),d0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,PC8FB1
	jmp	(a5)
PC8FC1:	sub.w	a3,d2
	bcs	PC8FC3
PC8FC2:	move.b	(a0),d6
	adda.w	a3,a0
	move.b	(a2,d6.w),d0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,PC8FB1
	jmp	(a5)
PC8FC3:	subi.l	#$10000,d2
	bcc	PC8FC2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	PC8FC7
	lea	PC8FC5(pc),a4
PC8FC4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8FX-PC8FC5
PC8FC5:	sub.w	d1,d2
	bcs	PC8FC6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	subq.w	#1,d7
	movea.w	d7,a3
	addq.w	#1,d7
	move.b	(a0),d6
	adda.w	d1,a0
	move.b	(a2,d6.w),d0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,PC8FB1
	jmp	(a5)
PC8FC6:	subi.l	#$10000,d2
	bcs	PC8FC4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	subq.w	#1,d7
	movea.w	d7,a3
	addq.w	#1,d7
	move.b	(a0),d6
	adda.w	d1,a0
	move.b	(a2,d6.w),d0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,PC8FB1
	jmp	(a5)
PC8FC7:	lea	PC8FC5(pc),a4
	addq.l	#2,a1
PC8FC8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	PC8FX-PC8FC9
PC8FC9:	sub.w	d1,d2
	bcs	PC8FCA
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	subq.w	#1,d7
	movea.w	d7,a3
	addq.w	#1,d7
	move.b	(a0),d6
	adda.w	d1,a0
	move.b	(a2,d6.w),d0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,PC8FB1
	jmp	(a5)
PC8FCA:	subi.l	#$10000,d2
	bcs	PC8FC8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	subq.w	#1,d7
	movea.w	d7,a3
	addq.w	#1,d7
	move.b	(a0),d6
	adda.w	d1,a0
	move.b	(a2,d6.w),d0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,PC8FB1
	jmp	(a5)
PC8FY:

	.endm

*--------------------------------------------------------------------
*	ここからプログラム本体
*--------------------------------------------------------------------
*	ﾃﾞﾊﾞｲｽﾄﾞﾗｲﾊﾞﾍｯﾀﾞ

TOPADR:	.dc.l	-1			* ｺﾏﾝﾄﾞﾗｲﾝからの常駐ではここに'PCM8/048'と
	.dc.w	$C020			* trap #2 ｴﾝﾄﾘへの bra 命令を置く
	.dc.l	ENTSET
	.dc.l	DEVENT
DEVNAM:	.dc.b	'PCM     '		* ﾃﾞﾊﾞｲｽﾄﾞﾗｲﾊﾞ名(8文字)

HEADD1:	.dc.b	'PCM8A Header'		* PCM8A 認識用ﾃﾞｰﾀ(12文字)
HEADD2:	.dc.l	T2KEEP

ENTWK:	.dc.l	0

ENTSET:	move.l	a5,ENTWK
	rts

DEVENT:	movem.l	d0/a5,-(sp)
	movea.l	ENTWK(pc),a5
	moveq	#0,d0
	move.b	2(a5),d0
	cmpi.b	#13,d0
	bcs	DEVEN1
	moveq	#1,d0
DEVEN1:	add.w	d0,d0
	move.w	JTBL(pc,d0.w),d0
	jsr	JTBL(pc,d0.w)
	move.b	d0,3(a5)
	move.w	d0,-(sp)
	move.b	(sp)+,4(a5)
	movem.l	(sp)+,d0/a5
	rts

JTBL:	.dc.w	DEVINI-JTBL
	.dc.w	DEVERR-JTBL
	.dc.w	DEVERR-JTBL
	.dc.w	DEVCHK-JTBL
	.dc.w	DEVIN-JTBL
	.dc.w	DEVNOP-JTBL
	.dc.w	DEVNOP-JTBL
	.dc.w	DEVNOP-JTBL
	.dc.w	DEVOUT-JTBL
	.dc.w	DEVOUT-JTBL
	.dc.w	DEVNOP-JTBL
	.dc.w	DEVERR-JTBL
	.dc.w	DEVMOD-JTBL

DEVINI:	jmp	DEVSET			* 実行後 bra DEVERR に書き替えられる

DEVERR:	move.w	#$5003,d0
	rts

DEVIN:	movem.l	d1-d2/a1,-(sp)
	move.l	$12(a5),d2
	movea.l	$E(a5),a1
	move.w	DEVMD(pc),d1
	IOCS	_ADPCMINP
	bra	DEVOU1

DEVOUT:	movem.l	d1-d2/a1,-(sp)
	move.l	$12(a5),d2
	movea.l	$E(a5),a1
	move.w	DEVMD(pc),d1
	IOCS	_ADPCMOUT
DEVOU1:	movem.l	(sp)+,d1-d2/a1
	bra	DEVNOP

DEVCHK:	move.l	a1,-(sp)
	IOCS	_ADPCMSNS
	movea.l	$E(a5),a1
	move.b	d0,(a1)
	bra	DEVMO1

DEVMOD:	move.l	a1,-(sp)
	movea.l	$E(a5),a1
	move.b	(a1)+,DEVMD
	move.b	(a1)+,DEVMD+1
DEVMO1:	movea.l	(sp)+,a1

DEVNOP:	moveq	#0,d0
	rts

DEVMD:	.dc.w	$0403

DEVEND:
*--------------------------------------------------------------------
*	IOCS用ｴﾝﾄﾘ

IOCS63:	moveq	#$14,d0			* ｱﾚｲﾁｪｰﾝ入力
	bra	IOCSRX

IOCS65:	moveq	#$24,d0			* ﾘﾝｸｱﾚｲﾁｪｰﾝ入力
	bra	IOCSRX

IOCS61:	moveq	#$04,d0			* 通常入力
IOCSRX:	movem.l	d1-d4/a0/a2/a5-a6,-(sp)
	lea	WK(pc),a6
	bsr	T2KILL			* PCM8A停止
	move.b	d0,ADIOCS.w
	move.l	d2,d3
	cmpi.b	#$10,d0
	bcs	IOCSRY
	moveq	#10,d2
	cmpi.b	#$20,d0
	bcc	IOCSRY
	move.l	d3,d2
	add.l	d2,d2
	add.l	d3,d2
	add.l	d2,d2
IOCSRY:	bclr	#15,d1
	bne	IOCSRZ
	bsr	TCWAIT			* 時間待ち+ｷｬｯｼｭｸﾘｱ
IOCSRZ:	move.w	d0,d2
	move.w	d1,d0
	lsr.w	#8,d0
	bsr	FRQSET			* 周波数設定
	bne	IOCSRR			* 設定できない場合エラー
	bsr	PANSET
	bsr	PANCNG
	move.b	d2,ADIOCS.w
	lsr.b	#4,d2
	lea	DMACH3,a5
	move.b	IOCSRT(pc,d2.w),d4
	cmpi.b	#1,d2
	bcc	IOCSR1
	move.l	#$FFF0,d1		* 通常入力
	move.l	d1,d2
	cmp.l	d1,d3
	bhi	IOCSR01
	moveq	#0,d1			* ﾊﾞｲﾄ数≦$FFF0
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	sf	M1MOD-WK(a6)
	move.l	d1,M1LEN-WK(a6)
	move.b	d4,5(a5)
	st	(a5)
	move.w	d3,$A(a5)
	move.l	a1,$C(a5)
	bra	IOCSRS

IOCSRR:	sf	ADIOCS.w
	moveq	#-1,d0
	bra	IOCSR4

IOCSRT:	.dc.b	$B2,$BA,$BE,$BE

IOCSR01:				* ﾊﾞｲﾄ数＞$FFF0
	sub.l	d1,d3
	lea	(a1,d1.l),a2
	cmp.l	d2,d3
	bhi	IOCSR02
	move.l	d3,d2
IOCSR02:
	sub.l	d2,d3
	lea	(a2,d2.l),a0
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	sf	M1MOD-WK(a6)
	move.l	d3,M1LEN-WK(a6)
	move.l	a0,M1ADR-WK(a6)
	move.b	d4,5(a5)
	st	(a5)
	move.w	d1,$A(a5)
	move.l	a1,$C(a5)
	move.w	d2,$1A(a5)
	move.l	a2,$1C(a5)
	move.b	#$C8,7(a5)
	bra	IOCSR2

IOCSR1:	bhi	IOCSR11			* ｱﾚｲﾁｪｰﾝ,ﾘﾝｸｱﾚｲﾁｪｰﾝ
	moveq	#0,d0
	not.w	d0
	cmp.l	d0,d3
	bls	IOCSR11
	move.l	d0,d3
IOCSR11:
	moveq	#0,d0
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	sf	M1MOD-WK(a6)
	move.l	d0,M1LEN-WK(a6)
	move.b	d4,5(a5)
	st	(a5)
	move.w	d3,$1A(a5)
	move.l	a1,$1C(a5)
IOCSRS:	move.b	#$88,7(a5)
IOCSR2:	move.b	#4,PCMCNT
IOCSRE:	move.w	(sp)+,sr
IOCSR3:	moveq	#0,d0
IOCSR4:	movem.l	(sp)+,d1-d4/a0/a2/a5-a6
	rts

IOCS62:	movem.l	d1/a5-a6,-(sp)		* ｱﾚｲﾁｪｰﾝ出力
	swap	d1
	move.w	#$1108,d1
	bra	IOCS1

IOCS64:	movem.l	d1/a5-a6,-(sp)		* ﾘﾝｸｱﾚｲﾁｪｰﾝ出力
	swap	d1
	move.w	#$1208,d1
	bra	IOCS1

IOCS60:	movem.l	d1/a5-a6,-(sp)		* 通常出力
	swap	d1
	move.w	#$1008,d1
IOCS1:	swap	d1
	andi.w	#$7FFF,d1
	lea	WK(pc),a6
	move.b	ADIOCS.w,d0
	beq	IOCS10
	cmpi.b	#PCM8FL,d0
	bne	IOCSER
IOCS10:	move.w	sr,-(sp)
	tst.b	SYSFLG-WK(a6)
	bmi	IOCSM
	tst.b	IOFLG-WK(a6)
	beq	IOCS12
	move.l	d1,-(sp)
	movea.l	CHNWK-WK(a6),a5
	moveq	#-1,d0
	add.w	PCMCHN-WK(a6),d0
	moveq	#8,d1
IOCS11:	or.b	d1,(a5)
	lea	CHNSIZ(a5),a5
	dbra	d0,IOCS11
	move.l	(sp)+,d1
IOCS12:	moveq	#7,d0			* ﾁｬﾝﾈﾙｻｰﾁ中のADPCM割り込みを禁止
	and.b	(sp),d0
	cmpi.b	#3,d0
	bcc	IOCS5
	ori.w	#$0300,sr
IOCS5:	bsr	CHNSRC
	move.b	d0,IOCHNW-WK(a6)
	tst.w	d0
	bmi	IOCSE1
	movea.l	CHNWK-WK(a6),a5
	lsl.w	#7,d0
	adda.w	d0,a5
	bset	#5,(a5)
	bne	IOCS5
	bset	#4,(a5)
	bsr	T2XE10
	bclr	#5,(a5)
IOCS4:	move.w	(sp)+,sr
IOCS2:	moveq	#0,d0
IOCS3:	movem.l	(sp)+,d1/a5-a6
	rts

IOCSM:	tst.b	IOCHN-WK(a6)		* 単音再生ﾓｰﾄﾞ
	beq	IOCSE1
	bsr	T2XE10
	bra	IOCS4
IOCSE1:	move.w	(sp)+,sr
IOCSER:	moveq	#-1,d0
	bra	IOCS3

IOCS66:	movem.l	d1/a5-a6,-(sp)		* 動作ﾓｰﾄﾞﾁｪｯｸ
	lea	WK(pc),a6
	moveq	#0,d0
	move.b	ADIOCS.w,d0
	cmpi.b	#PCM8FL,d0
	bne	IOCS3
	tst.b	SYSFLG-WK(a6)
	bmi	IOCS66M
	tst.b	SKPFLG-WK(a6)
	bne	IOCS2
	move.b	IOCHNW-WK(a6),d0
	cmp.b	PCMCHN+1-WK(a6),d0
	bcc	IOCS2
	movea.l	CHNWK-WK(a6),a5
	lsl.w	#7,d0
	move.b	(a5,d0.w),d0
	bmi	IOCS2			* ﾁｬﾝﾈﾙは停止している
	btst	#4,d0
	beq	IOCS2			* IOCS出力ﾁｬﾝﾈﾙではない
IOCS661:
	andi.w	#3,d0
	lsl.w	#4,d0
	ori.w	#2,d0
	bra	IOCS3

IOCS66M:				* 単音再生ﾓｰﾄﾞ
	btst	#0,(a6)
	beq	IOCS2
	move.b	M1MOD-WK(a6),d0
	bra	IOCS661

IOCS67:	movem.l	d1/a5-a6,-(sp)		* 動作制御
	lea	WK(pc),a6
	cmpi.l	#'PCM8',d1
	beq	IOCS673
	cmpi.l	#'PCMA',d1
	beq	IOCS674
	cmpi.l	#'MPCM',d1
	beq	IOCS679
	btst	#2,ADIOCS.w
	bne	IOCS675
	tst.b	SYSFLG-WK(a6)
	bmi	IOCS675
	move.b	IOCHNW-WK(a6),d0
	cmp.b	PCMCHN+1-WK(a6),d0
	bcc	IOCS2X
	movea.l	CHNWK-WK(a6),a5
	moveq	#-1,d0
	add.w	PCMCHN-WK(a6),d0
	subq.b	#1,d1
	bcc	IOCS671
	tst.b	IOFLG-WK(a6)
	bne	IOCS6702
	move.w	sr,-(sp)
	moveq	#$DC,d1			* ﾁｪｰﾝ動作終了
IOCS670:
	ori.w	#$0700,sr
	btst	#4,(a5)
	beq	IOCS6701
	and.b	d1,(a5)
IOCS6701:
	move.w	(sp),sr
	lea	CHNSIZ(a5),a5
	dbra	d0,IOCS670
	addq.l	#2,sp
	bra	IOCS2X

IOCS6702:				* 全ﾁｬﾝﾈﾙ一時停止解除禁止
	moveq	#$8,d1
IOCS6703:
	or.b	d1,(a5)
	lea	CHNSIZ(a5),a5
	dbra	d0,IOCS6703
	sf	IOFLG-WK(a6)
	bra	IOCS2X

IOCS673:
	moveq	#48,d0			* ﾊﾞｰｼﾞｮﾝ情報(PCM8 v0.48)
	bra	IOCS3X

IOCS674:
	moveq	#102,d0			* ﾊﾞｰｼﾞｮﾝ情報(PCM8A v1.02)		*;version
	bra	IOCS3X

IOCS679:
	moveq	#45,d0			* ﾊﾞｰｼﾞｮﾝ情報(MPCM v0.45)
	bra	IOCS3X

IOCS675:				* 単音再生ﾓｰﾄﾞ/録音時動作制御
	lea	DMACH3+7,a5
	subq.b	#1,d1
	bcc	IOCS676
	btst	#2,ADIOCS.w
	bne	IOCS678
	bsr	T2KIL0
	bra	IOCS2X

IOCS671:
	subq.b	#1,d1
	bcc	IOCS672
	st	IOFLG-WK(a6)
	move.w	sr,d1
IOCS6711:				* 一時停止
	ori.w	#$0700,sr
	btst	#4,(a5)
	beq	IOCS6712
	tas	(a5)
IOCS6712:
	move.w	d1,sr
	lea	CHNSIZ(a5),a5
	dbra	d0,IOCS6711
IOCS2X:	moveq	#0,d0
IOCS3X:	movem.l	(sp)+,d1/a5-a6
	rts

IOCS672:
	bhi	IOCS2X
	move.w	sr,-(sp)
IOCS6721:				* 一時停止解除
	ori.w	#$0700,sr
	move.b	(a5),d1
	bpl	IOCS6722
	btst	#4,d1
	beq	IOCS6722
	btst	#3,d1
	bne	IOCS6722
	andi.b	#$0F,d1
	ori.b	#$50,d1
	move.b	d1,(a5)
IOCS6722:
	move.w	(sp),sr
	lea	CHNSIZ(a5),a5
	dbra	d0,IOCS6721
	addq.l	#2,sp
	sf	IOFLG-WK(a6)
	bsr	T2XE1X
	bra	IOCS3X

IOCS676:
	bhi	IOCS677
	move.b	#$20,(a5)
	bra	IOCS2X
IOCS677:
	move.b	#$08,(a5)
	bra	IOCS2X
IOCS678:
	bsr	T2KILL
	bra	IOCS2X

CHNSRC:	movem.l	d1-d5/a0-a1,-(sp)	* IOCSﾁｬﾝﾈﾙｻｰﾁ
	moveq	#-1,d0
	moveq	#0,d1
	move.b	IOCHN-WK(a6),d1
	beq	CHNSRE
	move.w	d1,d0
	move.w	PCMCHN-WK(a6),d3
	move.w	d3,d4
	sub.w	d0,d3
	subq.w	#1,d0
	subq.w	#1,d4
	lsl.w	#7,d4
	movea.w	d4,a0
	adda.l	CHNWK-WK(a6),a0
	btst	#4,SYSFLG-WK(a6)
	bne	CHNSR5
	moveq	#-1,d4
	moveq	#-1,d5
CHNSR1:	moveq	#$A3,d1
	and.b	(a0),d1
	bmi	CHNSR5
	bne	CHNSR4
	move.l	$28(a0),d2		* 残りﾊﾞｲﾄ数
	sub.l	$1C(a0),d2
	cmp.l	d2,d4
	bls	CHNSR4
	move.l	d2,d4
	move.w	d0,d5
CHNSR4:	lea	-CHNSIZ(a0),a0
	dbra	d0,CHNSR1
	move.w	d5,d0
	bmi	CHNSRE
CHNSR5:	add.b	d3,d0
CHNSRE:	movem.l	(sp)+,d1-d5/a0-a1
	rts

	.dc.w	0,0,0			* 4ﾊﾞｲﾄ境界調整用			*;dummy

CHKFL2:	.dc.b	'@PCM/045'		* MPCM 認識用

*--------------------------------------------------------------------
*	trap #1 ｴﾝﾄﾘ (MPCM ｻｰﾋﾞｽﾙｰﾁﾝ入口)

T1ENT:	movem.l	d1-d7/a0-a6,-(sp)
	lea	WK(pc),a6
	pea	T1END(pc)
T1ENT0:	cmpi.w	#$1000,d0
	bcc	T1ENX
	move.w	#$00FF,d3
	and.w	d0,d3
	cmpi.w	#$00FF,d3
	beq	T1ENT2
	cmpi.w	#16,d3
	bcc	T1ERR
	lsl.w	#7,d3
	movea.w	d3,a5
	lsr.w	#7,d3
	adda.l	CHNWK-WK(a6),a5
T1ENT1:	andi.w	#$0F00,d0
	lsr.w	#7,d0
	move.w	T1JTBL(pc,d0.w),d4
	jmp	T1JTBL(pc,d4.w)
T1ENT2:	movea.l	CHNWK-WK(a6),a5		* 全ﾁｬﾝﾈﾙ処理時
	bra	T1ENT1
T1ERR:	moveq	#-1,d0
	addq.l	#4,sp
T1END:	movem.l	(sp)+,d1-d7/a0-a6
	rte

T1JTBL:	.dc.w	T1X0-T1JTBL		* $00xx:KEY ON
	.dc.w	T1X1-T1JTBL		* $01xx:KEY OFF
	.dc.w	T1X2-T1JTBL		* $02xx:ﾃﾞｰﾀ登録
	.dc.w	T1X3-T1JTBL		* $03xx:周波数指定
	.dc.w	T1X4-T1JTBL		* $04xx:音程設定
	.dc.w	T1X5-T1JTBL		* $05xx:音量設定
	.dc.w	T1X6-T1JTBL		* $06xx:PAN設定
	.dc.w	T1X7-T1JTBL		* $07xx:PCM種類設定
	.dc.w	T1X8-T1JTBL		* $08xx:KEY OFFﾓｰﾄﾞ設定
	.dc.w	T1ERR-T1JTBL
	.dc.w	T1ERR-T1JTBL
	.dc.w	T1ERR-T1JTBL
	.dc.w	T1ERR-T1JTBL
	.dc.w	T1ERR-T1JTBL
	.dc.w	T1ERR-T1JTBL
	.dc.w	T1ERR-T1JTBL

T1ENX:	cmpi.w	#$1400,d0
	bcc	T1ENN
	move.w	#$00FF,d3
	and.w	d0,d3
	cmpi.w	#$00FF,d3
	beq	T1ENX2
	addi.w	#16,d3
	cmp.w	PCMCMX-WK(a6),d3
	bcc	T1ERR
	lsl.w	#7,d3
	movea.w	d3,a5
	lsr.w	#7,d3
	adda.l	CHNWK-WK(a6),a5
T1ENX1:	andi.w	#$0F00,d0
	lsr.w	#7,d0
	move.w	T1JTBX(pc,d0.w),d4
	jmp	T1JTBX(pc,d4.w)
T1ENX2:	movea.l	CHNWK-WK(a6),a5
	bra	T1ENX1

T1JTBX:	.dc.w	T1EX0-T1JTBX		* $10xx:効果音再生
	.dc.w	T1EX0-T1JTBX		* $11xx:ｱﾚｲﾁｪｰﾝ効果音再生
	.dc.w	T1EX0-T1JTBX		* $12xx:ﾘﾝｸｱﾚｲﾁｪｰﾝ効果音再生
	.dc.w	T1EX3-T1JTBX		* $13xx:効果音停止

T1ENN:	subi.w	#$8000,d0
	bcs	T1ERR
	cmpi.w	#7,d0
	bcc	T1ERR
	add.w	d0,d0
	move.w	T1JTBN(pc,d0.w),d4
	jmp	T1JTBN(pc,d4.w)

T1JTBN:	.dc.w	T1EN0-T1JTBN		* $8000:MPCM占有
	.dc.w	T1EN1-T1JTBN		* $8001:MPCM占有解除
	.dc.w	T1EN2-T1JTBN		* $8002:MPCM初期化
	.dc.w	T1EN3-T1JTBN		* $8003:MPU/MFPﾏｽｸ設定
	.dc.w	T1ERR-T1JTBN		* $8004:動作ﾓｰﾄﾞ設定
	.dc.w	T1EN5-T1JTBN		* $8005:音量ﾃｰﾌﾞﾙ設定
	.dc.w	T1EN6-T1JTBN		* $8006:効果音発声数指定

T1EN0:	moveq	#-2,d4			* $8000:MPCM占有
	move.b	(a1),d0
	beq	T1ENER
	moveq	#-3,d4
	moveq	#KEPNUM-1,d0
	movea.l	KEPBUF-WK(a6),a0
	bra	T1EN02
T1EN01:	lea	KEPSIZ(a0),a0
T1EN02:	tst.b	(a0)
	dbeq	d0,T1EN01
	bne	T1ENER
	moveq	#KEPSIZ-2,d0
T1EN03:	move.b	(a1)+,(a0)+
	dbeq	d0,T1EN03
T1EN04:	moveq	#0,d4
	move.b	d4,(a0)
T1ENER:	move.l	d4,d0
	rts

T1EN1:	moveq	#-2,d4			* $8001:MPCM占有解除
	move.b	(a1),d1
	beq	T1ENER
	moveq	#-3,d4
	moveq	#KEPNUM-1,d0
	movea.l	KEPBUF-WK(a6),a0
	bra	T1EN12
T1EN11:	lea	$20(a0),a0
T1EN12:	cmp.b	(a0),d1
	dbeq	d0,T1EN11
	lea	1(a0),a2
	lea	1(a1),a3
	moveq	#KEPSIZ-2,d2
	bra	T1EN14
T1EN13:	tst.b	d3
	beq	T1EN04
T1EN14:	move.b	(a2)+,d3
	cmp.b	(a3)+,d3
	dbne	d2,T1EN13
	beq	T1EN04
	dbra	d0,T1EN11
	move.l	d4,d0
	rts

T1EN2:	bsr	T2KILL			* $8002:MPCM初期化
	moveq	#0,d0
	rts

T1EN3:	bsr	T2X2			* $8003:MPU/MFPﾏｽｸ設定
	rts

T1EN5:	moveq	#-2,d4			* $8005:音量ﾃｰﾌﾞﾙ設定
	addq.l	#1,d1
	cmpi.l	#3,d1
	bcc	T1ENER
	moveq	#127,d2
	lea	VOLCTB(pc),a0
	tst.b	d1
	beq	T1EN52
	lea	VOLCT1(pc),a1		* -1以外ならﾃﾞﾌｫﾙﾄのﾃｰﾌﾞﾙ
T1EN51:	move.b	(a1)+,(a0)+
	dbra	d2,T1EN51
	moveq	#0,d0
	rts
T1EN52:	moveq	#-1,d3
T1EN53:	move.w	(a1)+,d0
	mulu	#355,d0
	add.l	#$40,d0
	lsr.l	#7,d0
	cmp.w	d3,d0
	bcc	T1EN54
	moveq	#VOLMX2-VOLMN2,d4
	lea	VOLCT2(pc),a2
T1EN54:	move.w	d0,d3
	bra	T1EN56
T1EN55:	addq.l	#2,a2
T1EN56:	cmp.w	(a2),d0			* 対応する音量をｻｰﾁ
	dbcs	d4,T1EN55
	move.b	#VOLMX2-1,d0
	sub.b	d4,d0
	move.b	d0,(a0)+
	dbra	d2,T1EN53
	moveq	#0,d0
	rts

T1EN6:	moveq	#-2,d4			* $8006:効果音発声数指定
	cmpi.b	#9,d1
	bhi	T1ENER
	moveq	#0,d0
	move.b	IOCHMX-WK(a6),d0
	cmpi.b	#$FF,d0
	bne	T1EN61
	move.b	IOCHN-WK(a6),d0
T1EN61:	move.b	d1,IOCHMX-WK(a6)
	rts

T1EX0:	move.b	IOCHN-WK(a6),d5		* $10xx,$11xx,$12xx:効果音再生
	beq	T1EX0E
	cmpi.b	#9,d5
	bls	T1EX00
	moveq	#9,d5
T1EX00:	lsr.w	#1,d0
	move.w	d0,d6
	subq.b	#1,d5
	moveq	#0,d4
	cmpi.b	#$E0,d3
	bne	T1EX01
	bsr	T1SCSR
	tst.l	d0
	bmi	T1EX0E
	move.b	d0,d3
T1EX01:	cmpi.b	#$FF,d3
	bne	T1EX02
	move.b	d5,d4
	moveq	#0,d3
T1EX02:	cmp.b	d5,d3
	bhi	T1EX0E
T1EX03:	move.w	d6,d0
	bsr	T1SOUT
	lea	CHNSIZ(a5),a5
	dbra	d4,T1EX03
	moveq	#0,d0
	move.b	d3,d0
	rts

T1EX0E:	moveq	#-2,d0
	rts

T1EX3:	moveq	#0,d2			* $13xx:効果音停止
	cmpi.b	#$FF,d3
	bne	T1EX31
	moveq	#7,d2
T1EX31:	tas	(a5)
	lea	CHNSIZ(a5),a5
	dbra	d2,T1EX31
	moveq	#0,d0
	rts

T1SCSR:	movem.l	d1-d5/a0,-(sp)		* 空きﾁｬﾝﾈﾙｻｰﾁ
	moveq	#-2,d0
	moveq	#0,d3
	move.b	IOCHN-WK(a6),d3
	beq	T1SCSE
	cmpi.b	#9,d3
	bls	T1SCS0
	moveq	#9,d3
T1SCS0:	subq.w	#1,d3
	move.l	d3,d0
	moveq	#16,d2
	lsl.w	#7,d2
	movea.w	d2,a0
	adda.l	CHNWK-WK(a6),a0
	btst	#4,SYSFLG-WK(a6)
	bne	T1SCS5
	moveq	#-1,d4
	moveq	#-1,d5
T1SCS1:	moveq	#$83,d1
	and.b	(a0),d1
	bmi	T1SCS5
	bne	T1SCS4
	move.l	$28(a0),d2		* 残りﾊﾞｲﾄ数
	sub.l	$1C(a0),d2
	cmp.l	d2,d4
	bls	T1SCS4
	move.l	d2,d4
	move.w	d3,d5
T1SCS4:	lea	CHNSIZ(a0),a0
	dbra	d3,T1SCS1
	move.w	d5,d3
	bmi	T1SCSE
T1SCS5:	sub.b	d3,d0
T1SCSE:	movem.l	(sp)+,d1-d5/a0
	rts

T1SOUT:	movem.l	d0-d4/a0,-(sp)		* 効果音出力
	cmpi.l	#01000000,d1
	bcs	T1SOUE
	swap	d1
	moveq	#0,d3
	move.b	d1,d3			* 音量
	bpl	T1SO21
	moveq	#$40,d3
T1SO21:	lea	VOLCTB(pc),a0
	move.b	(a0,d3.w),d1
	ror.w	#8,d1
	moveq	#3,d3
	and.b	d1,d3
	lsl.b	#4,d3
	move.b	d3,d4
	move.b	d0,d1
	rol.w	#8,d1
	swap	d1
	move.b	d1,d3			* PAN
	bpl	T1SO01
	moveq	#1,d3
	cmpi.b	#$A0,d1
	bcs	T1SO01
	moveq	#3,d3
	cmpi.b	#$E0,d1
	bcs	T1SO01
	moveq	#2,d3
T1SO01:	cmpi.b	#4,d3
	bcs	T1SO02
	move.b	3(a5),d3
T1SO02:	move.b	d3,d1
	ror.w	#8,d1
	move.b	d1,d3			* 周波数
	cmpi.b	#7,d3
	bcs	T1SO11
	moveq	#4,d3
	cmpi.b	#$F0,d1
	beq	T1SO11
	cmpi.b	#$F1,d1
	beq	T1SO11
	move.b	2(a5),d3
T1SO11:	and.w	#$0007,d3
	or.b	d4,d3
	move.b	d3,d1
	rol.w	#8,d1
	bsr	TBLSET
T1SOUE:	movem.l	(sp)+,d0-d4/a0
	rts

T1X0:	moveq	#0,d2			* $00xx:KEY ON
	cmpi.b	#$FF,d3
	bne	T1X01
	moveq	#15,d2
T1X01:	bsr	T1KONS
	lea	CHNSIZ(a5),a5
	dbra	d2,T1X01
	bsr	T2XE1X
	moveq	#0,d0
	rts

T1X1:	moveq	#0,d2			* $01xx:KEY OFF
	cmpi.b	#$FF,d3
	bne	T1X11
	moveq	#15,d2
T1X11:	bsr	T1KOFS
	lea	CHNSIZ(a5),a5
	dbra	d2,T1X11
	moveq	#0,d0
	rts

T1X2:	moveq	#0,d2			* $02xx:ﾃﾞｰﾀ登録
	cmpi.b	#$FF,d3
	bne	T1X21
	moveq	#15,d2
T1X21:	bsr	T1CSET
	lea	CHNSIZ(a5),a5
	dbra	d2,T1X21
	rts

T1X3:	moveq	#0,d2			* $03xx:周波数指定
	cmpi.b	#$FF,d3
	bne	T1X31
	moveq	#15,d2
T1X31:	bsr	T1CFRQ
	lea	CHNSIZ(a5),a5
	dbra	d2,T1X31
	rts

T1X4:	moveq	#0,d2			* $04xx:音程設定
	cmpi.b	#$FF,d3
	bne	T1X41
	moveq	#15,d2
T1X41:	bsr	T1CNOT
	lea	CHNSIZ(a5),a5
	dbra	d2,T1X41
	rts

T1X5:	moveq	#0,d2			* $05xx:音量設定
	cmpi.b	#$FF,d3
	bne	T1X51
	moveq	#15,d2
T1X51:	bsr	T1CVOL
	lea	CHNSIZ(a5),a5
	dbra	d2,T1X51
	rts

T1X6:	moveq	#0,d2			* $06xx:PAN設定
	cmpi.b	#$FF,d3
	bne	T1X61
	moveq	#15,d2
T1X61:	bsr	T1CPAN
	lea	CHNSIZ(a5),a5
	dbra	d2,T1X61
	rts

T1X7:	moveq	#0,d2			* $07xx:PCM種類設定
	cmpi.b	#$FF,d1
	beq	T1X71
	cmpi.b	#3,d1
	bcc	T1XERR
T1X71:	cmpi.b	#$FF,d3
	bne	T1X72
	moveq	#15,d2
T1X72:	moveq	#0,d0
	move.b	$50(a5),d0
	move.b	d1,$50(a5)
	bsr	T1FCNG
	bsr	T1VCNG
	lea	CHNSIZ(a5),a5
	dbra	d2,T1X72
	rts

T1XERR:	moveq	#-2,d0
	rts

T1X8:	moveq	#0,d2			* $08xx:KEY OFFﾓｰﾄﾞ設定
	cmpi.b	#$FF,d3
	bne	T1X81
	moveq	#15,d2
T1X81:	moveq	#0,d0
	move.b	$59(a5),d0
	cmpi.b	#$FF,d1
	beq	T1X82
	move.b	d1,$59(a5)
T1X82:	lea	CHNSIZ(a5),a5
	dbra	d2,T1X81
	rts

T1KONS:	movem.l	d0-d2/a0,-(sp)		* ｷｰｵﾝ
	moveq	#3,d0
	and.b	(a5),d0
	cmpi.b	#3,d0
	bne	T1KONX
	moveq	#0,d1
	move.w	sr,d2
	ori.w	#$0700,sr
	ori.b	#$40,(a5)
	andi.b	#$7F,(a5)
	move.l	d1,8(a5)
	move.b	d1,$55(a5)
	move.w	#2,$C(a5)
	moveq	#3,d0
	and.b	$50(a5),d0
	move.b	PCMMD2-WK(a6,d0.w),d0
	move.w	d0,d1
	move.w	2+PCMMOD-WK(a6,d0.w),$E(a5)
	move.l	PCMINI-WK(a6,d0.w),$4(a5)
	moveq	#$38,d0
	add.l	a5,d0
	move.l	d0,$10(a5)
	move.l	$30(a5),$1C(a5)
	move.l	$34(a5),$28(a5)
	move.l	$48(a5),d0
	beq	T1KON1
	subq.l	#1,d0
T1KON1:	move.l	d0,$4C(a5)
	move.w	d2,sr
T1KONX:	movem.l	(sp)+,d0-d2/a0
	rts

T1KOFS:	movem.l	d0-d2/a0,-(sp)		* ｷｰｵﾌ
	tst.b	(a5)
	bmi	T1KOFE
	moveq	#3,d0
	and.b	(a5),d0
	cmpi.b	#3,d0
	bne	T1KOFE
	tst.b	$59(a5)
	bne	T1KOF1
	tas	(a5)
	bra	T1KOFE
T1KOF1:	moveq	#0,d1
	move.b	$50(a5),d0
	bpl	T1KOF5
	move.w	sr,d2
	ori.w	#$0700,sr
	move.l	$44(a5),d0
	bne	T1KOF2
	move.l	d1,$4C(a5)
	bra	T1KOF4
T1KOF2:	ori.b	#$40,(a5)
	move.l	d0,4(a5)
	move.l	d1,8(a5)
	move.b	d1,$55(a5)
	move.w	d1,$C(a5)
	lea	$40(a5),a0
	move.l	a0,$10(a5)
	move.l	$38(a5),$1C(a5)
	move.l	$3C(a5),$28(a5)
T1KOF4:	move.w	d2,sr
T1KOFE:	movem.l	(sp)+,d0-d2/a0
	rts

T1KOF5:	move.w	sr,d2
	ori.w	#$0700,sr
	ori.b	#$40,(a5)
	move.w	d1,$C(a5)
	lea	$40(a5),a0
	move.l	a0,$10(a5)
	move.l	$38(a5),$1C(a5)
	move.l	$3C(a5),$28(a5)
	move.w	d2,sr
	movem.l	(sp)+,d0-d2/a0

T1CSET:	movem.l	d1-d7/a0-a3,-(sp)	* ﾁｬﾝﾈﾙﾃﾞｰﾀｾｯﾄ
	ori.b	#$C0,(a5)
	lea	-CHNSIZ(sp),sp
	movea.l	sp,a3
	moveq	#0,d4
	move.b	#$C3,(a3)
	move.b	1(a5),1(a3)
	move.w	2(a5),2(a3)
	moveq	#0,d0
	move.l	d0,8(a3)
	move.l	d0,$14(a3)
	move.l	#$00010000,$18(a3)
	move.b	$58(a5),d0
	cmpi.b	#$F0,d0
	bcs	T1CSE1
	cmpi.b	#$F2,d0
	bcc	T1CSE1
	eori.b	#$F1,d0
	addq.b	#1,d0
	bra	T1CSE2
T1CSE1:	move.b	(a1),d0
T1CSE2:	tst.b	d0
	beq	T1CSE4
	cmpi.b	#$FF,d0
	beq	T1CSE5
	cmpi.b	#3,d0
	bcs	T1CSE5
T1CSE4:	addq.w	#1,d4
T1CSE5:	move.b	d0,$50(a3)
	move.b	d0,d7
	moveq	#3,d6
	and.b	d0,d6
	move.b	PCMMD2-WK(a6,d6.w),d6
	lea	DPCMBF(pc),a0
	move.l	(a0,d6.w),$20(a3)
	move.w	#2,$C(a3)
	move.w	PCMMOD+2-WK(a6,d6.w),$E(a3)
	move.l	PCMINI-WK(a6,d6.w),$4(a3)
	moveq	#0,d0
	move.b	1(a1),d0
	bpl	T1CSE6
	move.b	#$40,d0
T1CSE6:	move.b	d0,$51(a3)
	move.w	$52(a5),$52(a3)
	move.b	$54(a5),$54(a3)
	move.b	#0,$55(a3)
	move.w	#0,$56(a3)
	cmpi.b	#1,d7
	beq	T1CS10
	move.l	4(a1),d0
	move.l	8(a1),d3
	add.l	d0,d3
	move.l	$C(a1),d1
	add.l	d0,d1
	cmp.l	d1,d3
	bcc	T1CS01
	move.l	d3,d1
T1CS01:	move.l	$10(a1),d2
	addq.l	#1,d2
	add.l	d0,d2
	cmp.l	d1,d2
	bcc	T1CS02
	move.l	d1,d2
T1CS02:	cmp.l	d2,d3
	bcc	T1CS03
	move.l	d3,d2
T1CS03:	movem.l	d0-d3,$30(a3)
	bra	T1CS20
T1CS10:	move.l	4(a1),d0
	bclr	#0,d0
	beq	T1CS11
	addq.w	#1,d4
T1CS11:	move.l	8(a1),d3
	bclr	#0,d3
	beq	T1CS12
	addq.w	#1,d4
T1CS12:	add.l	d0,d3
	move.l	$C(a1),d1
	bclr	#0,d1
	beq	T1CS13
	addq.w	#1,d4
T1CS13:	add.l	d0,d1
	cmp.l	d1,d3
	bcc	T1CS14
	move.l	d3,d1
T1CS14:	move.l	$10(a1),d2
	addq.l	#2,d2
	bclr	#0,d2
	beq	T1CS15
	addq.w	#1,d4
T1CS15:	add.l	d0,d2
	cmp.l	d1,d2
	bcc	T1CS16
	move.l	d1,d2
T1CS16:	cmp.l	d2,d3
	bcc	T1CS17
	move.l	d3,d2
T1CS17:	movem.l	d0-d3,$30(a3)
T1CS20:	moveq	#0,d0
	move.l	d0,$24(a3)
	move.l	d0,$40(a3)
	move.l	d0,$44(a3)
	move.l	$14(a1),d1
	move.l	d1,$48(a3)
	beq	T1CS21
	subq.l	#1,d1
T1CS21:	move.l	d1,$4C(a3)
	move.l	d0,8(a3)
	move.l	d0,$14(a3)
	move.l	a5,a1
	movea.l	a3,a5
	bsr	T1FCNG
	bsr	T1VCNG
	bsr	T1KONS
	tas	(a3)
	movea.l	a1,a5
	moveq	#$38,d0
	add.l	a5,d0
	move.l	d0,$10(a3)
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	movem.l	(a3),d0-d7/a0-a2
	movem.l	d0-d7/a0-a2,(a5)
	movem.l	44(a3),d0-d7/a0-a2
	movem.l	d0-d7/a0-a2,44(a5)
	move.w	(sp)+,sr
T1CSEN:	lea	CHNSIZ(sp),sp
	move.l	d4,d0
	neg.l	d0
	movem.l	(sp)+,d1-d7/a0-a3
	rts

T1CFRQ:	moveq	#0,d0			* 周波数変更
	move.b	$58(a5),d0
	cmpi.b	#$FF,d1
	beq	T1CRTN
	cmpi.b	#$F0,d1
	beq	T1CFR1
	cmpi.b	#$F1,d1
	beq	T1CFR1
	cmpi.b	#7,d1
	bcc	T1CERR
T1CFR1:	move.b	d1,$58(a5)
	bra	T1FCNG

T1CERR:	moveq	#-2,d0
T1CRTN:	rts

T1CNOT:	moveq	#0,d0			* 音程変更
	move.w	$52(a5),d0
	cmpi.w	#$FFFF,d1
	beq	T1CRTN
	cmpi.w	#128*64,d1
	bcc	T1CERR
	move.w	d1,$52(a5)

T1FCNG:	movem.l	d0-d3/a0,-(sp)		* 周波数/音程変更
	moveq	#0,d0
	move.b	$58(a5),d0
	cmpi.b	#7,d0
	bcs	T1FCN1
	moveq	#4,d0
T1FCN1:	add.w	d0,d0
	move.w	FREQ-WK(a6,d0.w),d0
	moveq	#0,d1
	move.b	FRQSEL-WK(a6),d1
	add.w	d1,d1
	move.w	FREQ-WK(a6,d1.w),d1
	moveq	#0,d2
	move.w	$52(a5),d2
	moveq	#0,d3
	move.b	$51(a5),d3
	lsl.w	#6,d3
	bsr	FRQCAL
	move.l	d0,$18(a5)
	move.b	$50(a5),d3
	bgt	T1FCN3
	lea	PCMXTB(pc),a0
T1FCN2:	movem.l	(a0)+,d1-d2
	cmp.l	d1,d0
	bcs	T1FCN2
	move.l	d2,$2C(a5)
T1FCN3:	movem.l	(sp)+,d0-d3/a0
	rts

T1CVOL:	moveq	#0,d0			* 音量変更
	move.b	$54(a5),d0
	cmpi.b	#$FF,d1
	beq	T1CRTN
	movem.l	d1/a0,-(sp)
	tst.b	d1
	bpl	T1CVO1
	move.b	#$40,d1
T1CVO1:	move.b	d1,$54(a5)
	ext.w	d1
	lea	VOLCTB(pc),a0
	move.b	(a0,d1.w),1(a5)
	movem.l	(sp)+,d1/a0

T1VCNG:	movem.l	d0-d3/a0,-(sp)
	moveq	#0,d1
	move.b	1(a5),d1
	cmpi.b	#$10,d1
	bcc	T1VCN1
	move.b	PCMXT4-WK(a6,d1.w),d1
T1VCN1:	movem.w	VOLMN0-WK(a6),d2-d3
	cmp.b	d2,d1
	bcs	T1VC11
	cmp.b	d3,d1
	bls	T1VC12
	move.b	d3,d1
	bra	T1VC12
T1VC11:	move.b	d2,d1
T1VC12:	moveq	#6,d2			* 音量固定ﾁｪｯｸ
	and.b	SYSFLG-WK(a6),d2
	beq	T1VC13
	move.w	#$80,d1
T1VC13:	move.b	d1,1(a5)
	move.b	$50(a5),d2
	bgt	T1VCN2
	sub.b	VOLMIN+1-WK(a6),d1	* ADPCM時
	addi.w	#VOLWID+1,d1
	swap	d1
	lsr.l	#6,d1
	move.l	d1,$24(a5)
	bra	T1VCN5
T1VCN2:	subq.b	#1,d2			* PCM時
	bne	T1VCN3
	lea	PCMXT2(pc),a0
	bra	T1VCN4
T1VCN3:	lea	PCMXT3(pc),a0
T1VCN4:	subi.b	#VOLMN2,d1
	add.w	d1,d1
	add.w	d1,d1
	move.l	(a0,d1.w),$2C(a5)
T1VCN5:	movem.l	(sp)+,d0-d3/a0
	rts

T1CPAN:	moveq	#0,d0			* PAN変更
	move.b	3(a5),d0
	cmpi.b	#$7F,d1
	beq	T1CRTN
	movem.l	d1-d2,-(sp)
	move.b	d1,d2
	beq	T1CPA3
	bpl	T1CPA1
	moveq	#1,d1
	cmpi.b	#$A0,d2
	bcs	T1CPA1
	moveq	#3,d1
	cmpi.b	#$E0,d2
	bcs	T1CPA1
	moveq	#2,d1
T1CPA1:	cmpi.b	#4,d1
	bcs	T1CPA2
	move.b	d0,d1
	cmpi.b	#4,d1
	bcs	T1CPA2
	moveq	#3,d1
T1CPA2:	move.b	d1,3(a5)
	bsr	PANSET
	movem.l	(sp)+,d1-d2
	rts

T1CPA3:	tas	(a5)
	movem.l	(sp)+,d1-d2
	rts

T1VCHK:	movem.l	d1/a0,-(sp)		* TRAP #1 ﾍﾞｸﾀﾁｪｯｸ
	moveq	#0,d1			* 0:常駐可
	lea	T1VECA.w,a0
	move.l	(a0),a0
	cmpa.l	#$00F00000,a0
	bcc	T1VCH1
	moveq	#5,d1			* 5:常駐禁止
T1VCH1:	move.l	a0,d0
	swap	d0
	andi.w	#$FFF0,d0
	cmpi.w	#$21F0,d0
	beq	T1VCH2
	moveq	#5,d1
T1VCH2:	subq.l	#8,a0
	move.l	(a0),d0
	cmpi.l	#MPCMOK,d0
	beq	T1VCH3
	cmpi.l	#PCM8NG,d0
	bne	T1VCH4
T1VCH3:	moveq	#5,d1			* 5:常駐禁止
T1VCH4:	move.l	d1,d0
	movem.l	(sp)+,d1/a0
	rts

	.dc.w	0,0			* 4ﾊﾞｲﾄ境界調整用			*;dummy

T1KBUF:	dcb.b	KEPSIZ*KEPNUM,0		* 占有文字列ﾊﾞｯﾌｧ

	.dc.b	'PCM8A102'		* PCM8A 認識用				*;version
CHKFLG:	.dc.b	'@PCM/048'		* PCM8 認識用

*--------------------------------------------------------------------
*	trap #2 ｴﾝﾄﾘ (PCM8A ｻｰﾋﾞｽﾙｰﾁﾝ入口)

T2ENT:	movem.l	d1-d7/a0-a6,-(sp)
	lea	WK(pc),a6
	pea	T2END(pc)
	cmpi.w	#$1000,d0
	bcc	T2ENTX
	cmpi.w	#$0100,d0
	bcc	T2E3
	moveq	#$0F,d3
	and.w	d0,d3
T2ENT21:
	cmp.b	PCMCHN-WK+1(a6),d3
	bcc	T2ERR
	lsl.w	#7,d3
	movea.w	d3,a5
	adda.l	CHNWK-WK(a6),a5
	andi.w	#$00F0,d0
	lsr.w	#3,d0
	move.w	T2JTBL(pc,d0.w),d4
	jmp	T2JTBL(pc,d4.w)
T2ERR:	moveq	#-1,d0
	addq.l	#4,sp
T2END:	movem.l	(sp)+,d1-d7/a0-a6
	rte

T2JTBL:	.dc.w	T2XE1-T2JTBL		* $000x:通常出力
	.dc.w	T2XE1-T2JTBL		* $001x:ｱﾚｲﾁｪｰﾝ出力
	.dc.w	T2XE2-T2JTBL		* $002x:ﾘﾝｸｱﾚｲﾁｪｰﾝ出力
	.dc.w	T2ERR-T2JTBL		* $003x
	.dc.w	T2ERR-T2JTBL		* $004x
	.dc.w	T2ERR-T2JTBL		* $005x
	.dc.w	T2ERR-T2JTBL		* $006x
	.dc.w	TBLCNG-T2JTBL		* $007x:動作ﾓｰﾄﾞ変更
	.dc.w	TBLCHK-T2JTBL		* $008x:ﾃﾞｰﾀ長問い合わせ
	.dc.w	TBLMOD-T2JTBL		* $009x:動作ﾓｰﾄﾞ問い合わせ
	.dc.w	TBLADR-T2JTBL		* $00Ax:ｱｸｾｽｱﾄﾞﾚｽ問い合わせ
	.dc.w	T2STOP-T2JTBL		* $00Bx:ﾁｬﾝﾈﾙ動作中断
	.dc.w	T2CONT-T2JTBL		* $00Cx:ﾁｬﾝﾈﾙ動作継続
	.dc.w	T2ERR-T2JTBL		* $00Dx
	.dc.w	T2ERR-T2JTBL		* $00Ex
	.dc.w	T2ERR-T2JTBL		* $00Fx

T2ENTX:	cmpi.w	#$2000,d0		* $1nxx:拡張ﾁｬﾝﾈﾙ処理(n:ｺﾏﾝﾄﾞ,xx:ﾁｬﾝﾈﾙ)
	bcc	T2E4
	moveq	#0,d3
	move.b	d0,d3
	lsr.w	#4,d0
	bra	T2ENT21

T2E3:	beq	T2E30
	cmpi.w	#$0200,d0
	bcc	T2ERR
	addi.b	#9,d0
	bcs	T2ENT8
	cmpi.b	#$D,d0
	bhi	T2ERR
	beq	T2ENTB
	cmpi.b	#$B,d0
	bcs	T2ENT6
	beq	T2ENT7
T2ENTA:	bsr	T2KILL			* $0103:PCM8A停止
	moveq	#0,d0
	rts

T2ENTB:	bsr	T2ACTV			* $0104:PCM8A動作
	moveq	#0,d0
	rts

T2ENT6:	st	SKPFLG-WK(a6)		* $0101:一時停止
	moveq	#0,d0
	rts

T2ENT7:	sf	SKPFLG-WK(a6)		* $0102:一時停止解除
	bsr	T2XE1X
	rts

T2E30:	btst	#2,ADIOCS.w		* $0100:終了
	bne	T2E34
	tst.b	SKPFLG-WK(a6)
	bne	T2E33
	movea.l	CHNWK-WK(a6),a4
	moveq	#-1,d1
	add.w	PCMCHN-WK(a6),d1
	moveq	#$FC,d0			* 現在のﾌﾞﾛｯｸを出力して終了
T2E31:	and.b	d0,(a4)
	lea	CHNSIZ(a4),a4
	dbra	d1,T2E31
	moveq	#0,d0
	rts

T2E33:	move.w	sr,d2			* 即座に終了
	ori.w	#$0700,sr
	lea	DMACH3,a5
	bsr	DMASPX
	bsr	TBLCLR
	move.w	d2,sr
	bsr	DSPCLR
	sf	SKPFLG-WK(a6)
	sf	ADIOCS.w
	move.b	#PCMSP2,PCMDAT
	moveq	#0,d0
	rts

T2E34:	bsr	T2KILL
	moveq	#0,d0
	rts

T2E4A:	subi.w	#$2000,d0		* MPCMｺｰﾙへの置き換え
	bra	T1ENT0

T2E4:	cmpi.w	#$4000,d0		* MPCMｺｰﾙ?
	bcs	T2E4A
	tst.w	d0
	bpl	T2ENT9
	cmpi.w	#$A000,d0
	bcs	T2ERR1
	cmpi.w	#$B000,d0		* MPCMｺｰﾙ?
	bcs	T2E4A
	subi.w	#$FFF0,d0
	bcs	T2ERR1
	beq	T2E5
	cmpi.w	#1,d0
	beq	T2E51
	cmpi.w	#$C,d0
	bcs	T2ERR1
	beq	T2E45
	cmpi.w	#$E,d0
	bcs	T2E46
	beq	T2E47
	tst.b	KEEPFL-WK(a6)		* $FFFF:常駐解除
	bne	T2ERR1
	moveq	#KEPNUM-1,d1
	movea.l	KEPBUF-WK(a6),a0
	moveq	#0,d0
T2E41:	or.b	(a0),d0
	lea	32(a0),a0
	dbne	d1,T2E41
	bne	T2ERR1
	ori.w	#$0700,sr
	bsr	T2KILL
	lea	VECTBL-WK(a6),a0	* 元のﾍﾞｸﾀと同じか？
	moveq	#-2,d2
T2E42:	moveq	#0,d0
	move.w	(a0)+,d0
	beq	T2E43
	cmp.l	4(a0),d2
	bls	T2E421
	lsl.l	#2,d0
	movea.l	d0,a1
	move.l	(a0)+,d1
	addq.l	#4,a0
	cmp.l	(a1),d1
	beq	T2E42
	moveq	#-2,d0			* 違っていたら解除しない
	rts
T2E421:	addq.l	#8,a0
	bra	T2E42

T2ERR1:	moveq	#-1,d0
	rts

T2E43:
VCTRTN:	lea	VECTBL-WK(a6),a0	* ←常駐失敗時のｴﾝﾄﾘ
	move.l	#PCM8NG,CHKFLG-WK(a6)	* 認識用ﾌﾗｸﾞを壊す
	move.l	#PCM8NG,CHKFL2-WK(a6)	* 認識用ﾌﾗｸﾞを壊す
	moveq	#-2,d1			* 常駐解除を実行
T2E431:	move.w	(a0)+,d0
	beq	T2E433
	addq.l	#4,a0
	cmp.l	(a0),d1
	bls	T2E432
	move.l	(a0),-(sp)
	move.w	d0,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
T2E432:	move.l	d1,(a0)+		* 元のﾍﾞｸﾀ情報無効
	bra	T2E431
T2E433:	btst	#0,SYSFLG-WK(a6)
	bne	T2E436
	lea	WKADF1-WK(a6),a0
	moveq	#WKCNT-1,d1
	subq.l	#4,sp
T2E434:	bclr	#1,(a0)
	beq	T2E435
	move.l	6(a0),(sp)		* 確保したﾒﾓﾘを開放
	DOS	_MFREE
T2E435:	lea	10(a0),a0
	dbra	d1,T2E434
	pea	TOPADR-$F0(pc)
	DOS	_MFREE
	addq.l	#8,sp
T2E436:	moveq	#0,d0
	rts

T2E45:	cmpi.w	#WKCNT,d1		* $FFFC:ﾜｰｸｴﾘｱ情報
	bcc	T2ERR1
	lea	WKADR1-WK(a6),a0
	move.w	d1,d0
	add.w	d1,d1
	add.w	d1,d1
	add.w	d0,d1
	add.w	d1,d1
	move.l	(a0,d1.w),d0
	rts

T2E46:	lea	VECTBL-WK-8(a6),a2	* $FFFD:元のﾍﾞｸﾀ情報を読む
T2E461:	addq.l	#8,a2
	move.w	(a2)+,d0
	beq	T2E462
	cmp.w	d0,d1
	bne	T2E461
	move.l	4(a2),d0
	rts
T2E462:	tst.w	d1
	bne	T2ERR2
	move.l	(a2),d0
	rts

T2KEEP:	lea	WK(pc),a6		* trap #2 のﾍﾞｸﾀを設定
	lea	T2VECA.w,a2
	lea	T2ENT-WK(a6),a3
	cmpa.l	(a2),a3
	beq	T2KEE2
	lea	VECTBL-WK(a6),a1
	moveq	#-1,d0
T2KEE1:	move.w	(a1)+,d0
	beq	T2KEE2
	addq.l	#8,a1
	cmpi.w	#T2VECT,d0
	bne	T2KEE1
	move.l	(a2),-4(a1)
	move.l	a3,(a2)
T2KEE2:	rts

T2E47:	ori.w	#$0700,sr		* $FFFE:常駐
	lea	VECTBL-WK(a6),a2
	movea.l	a2,a3
T2E471:	moveq	#0,d0
	move.w	(a2)+,d0
	beq	T2E473
	cmpi.w	#T2VECT,d0		* trap #2 のﾍﾞｸﾀは無視
	beq	T2E472
	lsl.l	#2,d0
	movea.l	d0,a0
	move.l	(a0),d0
	cmp.l	(a2),d0
	addq.l	#8,a2
	bne	T2E471
T2ERR2:	moveq	#-1,d0
	rts				* 同じﾍﾞｸﾀがあったらｴﾗｰ
T2E472:	addq.l	#8,a2
	bra	T2E471
T2E473:	bsr	T2KILL
	sf	SKPFLG-WK(a6)
T2E474:	move.w	(a3)+,d0		* ﾍﾞｸﾀを設定
	beq	T2E476
	cmpi.w	#T1VECT,d0
	beq	T2E477
T2E475:	move.l	(a3)+,-(sp)
	move.w	d0,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
	addq.l	#4,a3
	cmp.l	-8(a3),d0		* 同じｱﾄﾞﾚｽは保存しない
	beq	T2E474
	move.l	d0,-4(a3)
	bra	T2E474
T2E476:	move.l	#PCM8OK,CHKFLG-WK(a6)	* 認識用ﾌﾗｸﾞを戻す
	move.l	#MPCMOK,CHKFL2-WK(a6)	* 認識用ﾌﾗｸﾞを戻す
	bsr	T2ACTV
	moveq	#0,d0
	rts
T2E477:	move.w	d0,-(sp)
	bsr	T1VCHK
	movem.w	(sp)+,d0
	beq	T2E475
	addq.l	#8,a3
	bra	T2E474

T2E5:	moveq	#0,d0			* $FFF0:割り込み中ﾌﾗｸﾞﾁｪｯｸ
	move.b	ENDFLG-WK(a6),d0
	rts

T2E51:	ori.w	#$0700,sr		* $FFF1:PCM8A内部初期化
	bsr	T2ACTV
	sf	PCMFL2-WK(a6)
	tst.b	ENDFLG-WK(a6)
	beq	T2E52
	lea	MFPIMA,a1		* 割り込みﾏｽｸ復帰
	movep.w	-$C(a1),d0
	tst.b	DMACH3-MFPIMA(a1)
	sf	ENDFLG-WK(a6)
	movep.w	d0,0(a1)
	bsr	DSPCLR
T2E52:	moveq	#0,d0
	rts

T2ENT8:	ext.w	d0
	add.w	d0,d0
	move.w	T2JTB2(pc,d0.w),d0
	jmp	T2JTB2(pc,d0.w)

T2JTB2:	.dc.w	T2X7-T2JTB2		* $01F7:周波数ﾓｰﾄﾞ設定
	.dc.w	T2X8-T2JTB2		* $01F8:PCM8Aｼｽﾃﾑ情報設定
	.dc.w	T2X0-T2JTB2		* $01F9:PCM8Aｼｽﾃﾑ情報
	.dc.w	T2X1-T2JTB2		* $01FA:PCM8Aｽﾃｰﾀｽ
	.dc.w	T2X2-T2JTB2		* $01FB:MPU･MFP割り込みﾏｽｸ設定
	.dc.w	T2X3-T2JTB2		* $01FC:多重･単音ﾓｰﾄﾞの設定
	.dc.w	T2ERR3-T2JTB2		* $01FD:reserve
	.dc.w	T2X4-T2JTB2		* $01FE:占有
	.dc.w	T2X5-T2JTB2		* $01FF:占有解除

T2ENT9:	cmpi.w	#$7F00,d0
	beq	T2E90
	cmpi.w	#$7F02,d0
	beq	T2E92
	cmpi.w	#$7F03,d0
	beq	T2E93
	cmpi.w	#$7F04,d0
	beq	T2E94
	cmpi.w	#$7F10,d0
	beq	T2E9A
	cmpi.w	#$7F11,d0
	beq	T2E9B
	cmpi.w	#$7F12,d0
	beq	T2E9C
T2ERR3:	moveq	#-1,d0
	rts

T2E90:	moveq	#0,d0			* $7F00:動作状態表示ﾓｰﾄﾞ設定
	subq.w	#1,d1
	bhi	T2E901
	seq	DSPFLG-WK(a6)
	rts
T2E901:	not.b	DSPFLG-WK(a6)
	rts

T2E92:	moveq	#$4F,d2			* $7F02:多重／単音ﾓｰﾄﾞ設定
	move.b	SYSFLG-WK(a6),d3
	and.b	d3,d2
	moveq	#0,d0
	subq.w	#1,d1
	beq	T2X3X
	bcc	T2E922
	ori.b	#$30,d2
	bra	T2X3X
T2E922:	ori.b	#$10,d2
	bra	T2X3X

T2E93:	cmp.b	#$FE,d1			* $7F03:IOCS使用ﾁｬﾝﾈﾙ数設定
	bne	T2E931
	st	IOCHMX-WK(a6)
	bra	T2E932
T2E931:	cmp.b	PCMCMX+1-WK(a6),d1
	bhi	T2ERR3
	move.b	d1,IOCHMX-WK(a6)
	cmp.b	PCMCHN+1-WK(a6),d1
	bls	T2E933
T2E932	move.b	PCMCHN+1-WK(a6),d1
T2E933:	move.b	d1,IOCHN-WK(a6)
	moveq	#0,d0
	rts

T2E94:	moveq	#0,d0
	subq.w	#1,d1			* $7F04:音量固定ﾓｰﾄﾞ設定
	beq	T2E941
	bcc	T2E942
	bset	#1,SYSFLG-WK(a6)
	rts
T2E941:	bclr	#1,SYSFLG-WK(a6)
	rts
T2E942:	bchg	#1,SYSFLG-WK(a6)
	rts

T2E9A:	move.l	a6,d0			* $7F10:内部ﾜｰｸﾎﾟｲﾝﾀ取得
	rts

T2E9B:	movea.l	KEPBUF-WK(a6),a0	* $7F11:占有ﾊﾞｯﾌｧ先頭ｱﾄﾞﾚｽ
	move.l	a0,d0
	rts

T2E9C:	move.l	#KEPNUM*$10000+KEPSIZ,d0	* $7F12:占有ﾊﾞｯﾌｧ長さ
	rts

T2X7:	moveq	#0,d0			* $01F7:周波数ﾓｰﾄﾞ設定
	move.w	FRQMOD-WK(a6),d0
	subq.b	#4,d0
	andi.b	#7,d0
	tst.l	d1
	bmi	T2X75
	ror.w	#8,d1
	cmpi.b	#$FF,d1
	bne	T2X71
	ror.w	#8,d0
	move.b	d0,d1
	rol.w	#8,d0
T2X71:	rol.w	#8,d1
	cmpi.b	#$FF,d1
	bne	T2X72
	move.b	d0,d1
	addq.b	#4,d1
	andi.b	#7,d1
T2X72:	cmpi.w	#$500,d1
	bcc	T2X75
	cmpi.w	#$100,d1
	bcc	T2X73
	cmpi.b	#4,d1
	bcc	T2X73
	clr.b	d1
T2X73:	cmpi.b	#7,d1
	bhi	T2X75
	subq.b	#4,d1
	andi.b	#7,d1
	lea	FRQTBL(pc),a0
	move.w	#$0700,d2
	and.w	d1,d2
	lsr.w	#5,d2
	adda.w	d2,a0
	moveq	#7,d2
	and.b	d1,d2
	move.b	(a0,d2.w),d2
	btst	#6,d2
	bne	T2X75
	move.w	sr,d2
	ori.w	#$0700,sr
	bsr	T2KILL
	move.w	d1,FRQMOD-WK(a6)
	move.l	a0,FRQPTR-WK(a6)
	move.b	d1,d0
	bsr	FRQSET
	move.w	d2,sr
	move.b	PCMBN0+1-WK(a6),d1
	bsr	T2X84
T2X75:	rts

T2X8:	move.b	PCMCHN+1-WK(a6),-(sp)	* $01F8:PCM8Aｼｽﾃﾑ情報設定
	move.w	(sp),d0
	move.b	PCMBN0+1-WK(a6),d0
	swap	d0
	move.b	VOLMX0+1-WK(a6),(sp)
	move.w	(sp)+,d0
	move.b	VOLMN0+1-WK(a6),d0
	addq.l	#1,d1
	bcs	T2X8X
	subq.l	#1,d1
	lea	PCMXT4-WK(a6),a0
T2X81:	move.w	d1,d2			* 音量最大値
	lsr.w	#8,d2
	cmpi.w	#$00FF,d2
	bcs	T2X811
	move.b	VOLMX0+1-WK(a6),d2
T2X811:	cmpi.b	#16,d2
	bcc	T2X812
	move.b	(a0,d2.w),d2
T2X812:	cmp.b	VOLMAX+1-WK(a6),d2
	bls	T2X82
	move.b	VOLMAX+1-WK(a6),d2
T2X82:	move.w	d1,d3			* 音量最小値
	andi.w	#$00FF,d3
	cmpi.w	#$00FF,d3
	bcs	T2X821
	move.b	VOLMN0+1-WK(a6),d3
T2X821:	cmpi.b	#16,d3
	bcc	T2X822
	move.b	(a0,d3.w),d3
T2X822:	cmp.b	VOLMIN+1-WK(a6),d3
	bcc	T2X823
	move.b	VOLMIN+1-WK(a6),d3
T2X823:	cmp.w	d2,d3
	bcc	T2X824
	exg	d2,d3
T2X824:	movem.w	d2-d3,VOLMN0-WK(a6)
T2X83:	swap	d1			* ﾁｬﾝﾈﾙ数最大値
	move.w	d1,d2
	lsr.w	#8,d2
	beq	T2X830
	cmpi.w	#$00FF,d2
	bcs	T2X831
T2X830:	move.b	PCMCHN+1-WK(a6),d2
T2X831:	cmp.b	PCMCMX+1-WK(a6),d2
	bls	T2X832
	move.b	PCMCMX+1-WK(a6),d2
T2X832:
	move.b	IOCHMX-WK(a6),d3
	cmp.b	d2,d3
	bls	T2X833
	move.b	d2,d3
T2X833:	move.b	d3,IOCHN-WK(a6)
	move.b	PCMCHN+1-WK(a6),d3
	sub.b	d2,d3
	bcc	T2X836
	neg.b	d3			* ﾁｬﾝﾈﾙ数増加時,未使用ﾁｬﾝﾈﾙ停止
	movea.l	CHNWK-WK(a6),a0
	move.w	d2,d4
	sub.b	d3,d4
	lsl.w	#7,d4
	lea	(a0,d4.w),a0
	bra	T2X835
T2X834:	tas	(a0)
	lea	CHNSIZ(a0),a0
T2X835:	dbra	d3,T2X834
T2X836:	move.w	d2,PCMCHN-WK(a6)
T2X84:	andi.w	#$00FF,d1		* 処理ﾊﾞｲﾄ数/12
	beq	T2X840
	cmpi.w	#$00FF,d1
	bcs	T2X841
T2X840:	move.b	PCMBN0+1-WK(a6),d1
T2X841:	cmp.b	PCMBNX+1-WK(a6),d1
	bls	T2X842
	move.b	PCMBNX+1-WK(a6),d1
T2X842:	moveq	#0,d2
	move.b	FRQSEL-WK(a6),d2
	add.w	d2,d2
	move.w	FREQ1-WK(a6,d2.w),d2
	mulu.w	d1,d2
	btst	#0,d2
	beq	T2X843
	addq.w	#1,d2
T2X843:	move.w	sr,d7
	ori.w	#$0700,sr
	move.w	d1,PCMBN0-WK(a6)
	move.w	d2,PCMBL0-WK(a6)
	move.w	d2,PCMBR0-WK(a6)
	move.w	#$2000,PCMFLG-WK(a6)
	move.w	d7,sr
T2X8X:	rts

T2X0:	move.w	PCMBL0-WK(a6),d0	* $01F9:PCM8Aｼｽﾃﾑ情報
	swap	d0
	move.b	VOLMX0+1-WK(a6),-(sp)
	move.w	(sp)+,d0
	move.b	VOLMN0+1-WK(a6),d0
	rts

T2X1:	moveq	#0,d0			* $01FA:PCM8Aｽﾃｰﾀｽ
	move.b	PCMCHN+1-WK(a6),-(sp)
	move.w	(sp)+,d0
	move.b	ACTFLG-WK(a6),d0	* 動作中のﾁｬﾝﾈﾙ数
	swap	d0
	move.b	SYSFLG-WK(a6),d0	* ﾃﾞﾊﾞｲｽﾄﾞﾗｲﾊﾞ組み込み/音量固定ﾓｰﾄﾞﾌﾗｸﾞ
	andi.b	#7,d0
	eori.b	#6,d0
	tst.b	DSPFLG-WK(a6)		* 動作表示ﾓｰﾄﾞ
	bpl	T2X10
	bset	#3,d0
T2X10:	move.b	d0,-(sp)
	move.w	(sp)+,d0
	move.b	IOCHN-WK(a6),d0		* IOCS使用ﾁｬﾝﾈﾙ数
	swap	d0
	tst.l	d1
	bmi	T2X16
	swap	d1
	cmpi.b	#$FE,d1
	bne	T2X11
	st	IOCHMX-WK(a6)
	bra	T2X12
T2X11:	cmp.b	PCMCMX+1-WK(a6),d1	* IOCS使用ﾁｬﾝﾈﾙ数設定
	bhi	T2X14
	move.b	d1,IOCHMX-WK(a6)
	cmp.b	PCMCHN+1-WK(a6),d1
	bls	T2X13
T2X12:	move.b	PCMCHN+1-WK(a6),d1
T2X13:	move.b	d1,IOCHN-WK(a6)
T2X14:	btst	#11,d1
	beq	T2X15
	not.b	DSPFLG-WK(a6)		* 動作表示ﾓｰﾄﾞ反転
T2X15:	btst	#10,d1
	beq	T2X16
	bchg	#2,SYSFLG-WK(a6)	* 音量固定ﾓｰﾄﾞ反転
T2X16:	rts

T2X2:	move.l	INTWK-WK(a6),d0		* $01FB:MPU･MFP割り込み設定
	swap	d0
	andi.w	#$0700,d0
	ror.w	#8,d0
	swap	d0
	tst.l	d1
	bmi	T2X22
	moveq	#$F8,d3
	moveq	#5,d2
	swap	d1
	andi.b	#7,d1
	cmp.b	d1,d2
	bcc	T2X21
	move.b	d1,d2
T2X21:	or.w	d3,d1
	rol.w	#8,d1
	swap	d1
	or.w	d3,d2
	rol.w	#8,d2
	ori.w	#$0700,sr
	move.l	d1,INTWK-WK(a6)
	move.w	d2,INTWK2-WK(a6)
T2X22:	rts

T2X3:	move.b	SYSFLG-WK(a6),d2	* $01FC:多重･単音ﾓｰﾄﾞの設定
	move.b	d2,d3
	moveq	#0,d0
	tst.b	d2
	bmi	T2X31
	lsr.b	#4,d2
	andi.w	#7,d2
	move.b	T2X3T(pc,d2.w),d0
T2X31:	tst.w	d1
	bmi	T2X34
	moveq	#$2F,d2
	and.b	SYSFLG-WK(a6),d2
	tst.w	d1
	beq	T2X32
	cmpi.w	#2,d1
	bhi	T2ERR4
	bne	T2X3X
	ori.b	#$10,d2
	bra	T2X3X
T2X32:	ori.b	#$50,d2
T2X3X:	cmpi.b	#$20,d2
	bcs	T2X33
	ori.b	#$90,d2
T2X33:	move.b	d2,SYSFLG-WK(a6)
	eor.b	d2,d3
	bpl	T2X34
	bsr	T2ACT0
T2X34:	rts

T2ERR4:	moveq	#-1,d0
	rts

T2X3T:	.dc.b	1,2,0,0,0,0,0,0

T2X4:	tst.b	KEEPFL-WK(a6)		* $01FE:占有
	bmi	T2ERR4
	st	KEEPFL-WK(a6)
	moveq	#0,d0
	rts

T2X5:	tst.b	KEEPFL-WK(a6)		* $01FF:占有解除
	bpl	T2ERR4
	sf	KEEPFL-WK(a6)
	moveq	#0,d0
	rts

*--------------------------------------------------------------------
*	ここからはｻﾌﾞﾙｰﾁﾝ群

T2ACTV:	move.w	sr,-(sp)		* DMAC/ADPCMを動作状態にする
	ori.w	#$0700,sr
	movem.l	d0-d1/a0/a5,-(sp)
	st	PANWK-WK(a6)
	moveq	#0,d1
	bsr	PANSET
	bsr	PANCNG
	bsr	DMASTP
	bsr	T2WCLR
	move.b	FRQSEL-WK(a6),d0
	bsr	FRQSET
	movea.l	ADPBFX-WK(a6),a0
	moveq	#PCMBGN,d1
	bsr	DMASTA
T2ACT1:	movem.l	(sp)+,d0-d1/a0/a5
	move.w	(sp)+,sr
	rts

T2ACT0:	move.w	sr,-(sp)
	ori.w	#$0700,sr
	movem.l	d0-d1/a0/a5,-(sp)
	lea	DMACH3,a5
	bsr	DMASP1
	bsr	T2WCLR
	move.b	FRQSEL-WK(a6),d0
	bsr	FRQSET
	movea.l	ADPBFX-WK(a6),a0
	moveq	#PCMBGN,d1
	bsr	DMASA1
	bra	T2ACT1

T2KILL:	move.w	sr,-(sp)		* 全ﾁｬﾝﾈﾙ強制停止&初期化
	ori.w	#$0700,sr
	movem.l	d0-d7/a0-a1/a5,-(sp)
	moveq	#0,d1
	move.w	d1,ADIOCS.w
	move.b	d1,M1MOD-WK(a6)
	move.l	d1,M1LEN-WK(a6)
	bsr	DMASTP
	bsr	PANSET
	bsr	PANCNG
T2KIL1:	bsr	T2WCLR
	bsr	DSPCLR
	movem.l	(sp)+,d0-d7/a0-a1/a5
	move.w	(sp)+,sr
	rts

T2KIL0:	move.w	sr,-(sp)
	ori.w	#$0700,sr
	movem.l	d0-d7/a0-a1/a5,-(sp)
	lea	DMACH3,a5
	bsr	DMASP1
	bra	T2KIL1

DSPCLR:	tst.b	DSPFLG-WK(a6)
	bpl	DSPCL1
	move.w	#DCOL0,TXTPL0		* 動作状態表示OFF
DSPCL1:	rts

DMASTA:	lea	DMACH3,a5		* DMA転送開始
DMASA0:	move.b	#$01,PCMCNT
DMASA1:	move.b	#$10,7(a5)
	st.b	(a5)
	move.b	#PCMSP2,PCMDAT
	move.l	#PCMDAT,$14(a5)
	move.l	a0,$C(a5)
	move.w	d1,$A(a5)
	move.l	#$02888004,d0
	movep.w	d0,4(a5)
	swap	d0
	movep.w	d0,5(a5)
	move.b	#$02,PCMCNT
	tas	(a6)
	rts

DMASTP:	lea	DMACH3,a5		* DMA停止
	lea	WK(pc),a6
DMASP0:	move.b	#$01,PCMCNT		* ADPCM停止
DMASP1:	move.b	#PCMSP2,PCMDAT
	move.b	#$10,7(a5)		* DMAC強制停止
	st.b	(a5)
	sf	ACTFLG-WK(a6)
	tas	(a6)
	rts

DMASPX:	move.b	#$10,7(a5)
	st.b	(a5)
	move.b	#PCMSP2,PCMDAT
	move.l	ADPBFX-WK(a6),$C(a5)
	move.w	#1,$A(a5)
	move.l	#$02808004,d0
	movep.w	d0,4(a5)
	swap	d0
	movep.w	d0,5(a5)
	sf	ACTFLG-WK(a6)
	tas	(a6)
	rts

T2WCLR:	movem.l	d0-d7/a0,-(sp)		* 全ﾁｬﾝﾈﾙ初期化
	move.w	PCMCMX-WK(a6),d6
	move.w	d6,d0
	lsl.w	#7,d0
	movea.w	d0,a0
	adda.l	CHNWK-WK(a6),a0
	move.l	DPCMBF-WK(a6),d0
	move.l	TBLAD1-WK(a6),d1
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d4
	move.l	#0,d5
	subq.w	#1,d6
	move.l	#P16X0,d7
T2WCL1:	movem.l	d2-d5,-(a0)
	movem.l	d2-d5,-(a0)
	move.l	d2,-(a0)
	move.l	#$04000000,-(a0)
	move.l	#$40000000,-(a0)
	move.l	#$FF401000,-(a0)
	movem.l	d2-d5,-(a0)
	movem.l	d2-d5,-(a0)
	movem.l	d0/d3-d4/d7,-(a0)
	movem.l	d2-d5,-(a0)
	movem.l	d1-d3,-(a0)
	move.l	#$C0080403,-(a0)
	dbra	d6,T2WCL1
	move.l	d2,M1LEN-WK(a6)
	sf	M1MOD-WK(a6)
	sf	ACTFLG-WK(a6)
	sf	(a6)
	movem.l	(sp)+,d0-d7/a0
	rts

TBLCLR:	movem.l	d0/a0,-(sp)		* 全ﾁｬﾝﾈﾙ停止
	movea.l	CHNWK-WK(a6),a0
	moveq	#-1,d0
	add.w	PCMCMX-WK(a6),d0
TBLCL1:	tas	(a0)
	lea	CHNSIZ(a0),a0
	dbra	d0,TBLCL1
	sf	ACTFLG-WK(a6)
	sf	(a6)
	movem.l	(sp)+,d0/a0
	rts

TCWTBL:	.dc.b	10,8,5,4,3,2,1,0

TCWAIT:	movem.l	d0-d3/a0-a1,-(sp)	* TIMER-CによるWAIT+ﾃﾞｰﾀｷｬｯｼｭｸﾘｱ
	lsr.w	#8,d1
	moveq	#7,d0
	and.w	d1,d0
	move.b	TCWTBL(pc,d0.w),d0
	lea	MFPTMC,a0
	moveq	#CACHEL-1,d1
	add.l	d1,d2
	lsr.l	#CACHES,d2
	move.b	(a0),d1
	move.b	(a0),d1
	cmpi.b	#3,MPUFLG.w
	bhi	TCWAI3
	bcs	TCWAI1
	.dc.w	$4E7A,$3002		* movec cacr,d3
	ori.w	#$0800,d3
	.dc.w	$4E7B,$3002		* movec d3,cacr
	andi.w	#$F7FF,d3
	.dc.w	$4E7B,$3002		* movec d3,cacr
TCWAI1:	moveq	#-1,d2
TCWAI3:	tst.l	d2
	bmi	TCWAI4
	.dc.w	$F469			* cpushl dc,(a1)
	lea	CACHEL(a1),a1
	subq.l	#1,d2
	bcc	TCWAI4
	moveq	#-1,d2
TCWAI4:	move.l	d1,d3
	move.b	(a0),d1
	sub.b	d1,d3
	beq	TCWAI3
	bhi	TCWAI5
	moveq	#1,d3
TCWAI5:	sub.l	d3,d0
	bhi	TCWAI3
	tst.l	d2
	bmi	TCWAI7
TCWAI6:	.dc.w	$F469			* cpushl dc,(a1)
	lea	CACHEL(a1),a1
	subq.l	#1,d2
	bcc	TCWAI6
TCWAI7:	movem.l	(sp)+,d0-d3/a0-a1
	rts

TBLCHK:	tst.b	SYSFLG-WK(a6)		* $008x:ﾃﾞｰﾀ長問い合せ
	bmi	TBLCH3
	move.b	(a5),d0
	bmi	TBLCH1
	andi.w	#3,d0
	bne	TBLCH2
	move.l	$28(a5),d0
	sub.l	$1C(a5),d0
	rts

TBLCH2:	neg.w	d0
	ext.l	d0
	rts

TBLCH3:	btst	#0,(a6)
	beq	TBLCH1
	moveq	#-3,d0
	rts

T2XE1:	tst.l	d2			* 出力処理(通常,ｱﾚｲﾁｪｰﾝ)
	bmi	TBLCHK
T2XE2:	lsl.w	#7,d0			* 出力処理(ﾘﾝｸｱﾚｲﾁｪｰﾝ)
	swap	d1
	andi.w	#$00FF,d1
	or.w	d0,d1
	swap	d1
T2XE10:	tst.b	SYSFLG-WK(a6)		* 出力開始(IOCSのｴﾝﾄﾘﾎﾟｲﾝﾄ)
	bmi	T2XEM
	move.b	ADIOCS.w,d0
	beq	T2XE11
	cmpi.b	#PCM8FL,d0
	beq	T2XE11
	moveq	#-1,d0
	rts

T2XE1X:	move.b	ADIOCS.w,d0		* 一時停止解除時のｴﾝﾄﾘﾎﾟｲﾝﾄ
	beq	T2XE1S
	cmpi.b	#PCM8FL,d0
	beq	T2XE1S
	moveq	#-1,d0
	rts

T2XE1S:	move.b	FRQSEL-WK(a6),d0
	bsr	FRQSET
	bra	T2XE1Y

T2XE11:	move.b	FRQSEL-WK(a6),d0
	bsr	FRQSET
	tst.b	SKPFLG-WK(a6)
	bne	T2XE13
	bclr	#1,(a6)
	beq	T2XE14
T2XE13:	bsr	TBLCLR
	sf	SKPFLG-WK(a6)
T2XE14:	bsr	TBLSET
T2XE1Y:	movem.l	d1-d2/a0/a5,-(sp)
	movea.l	CHNWK-WK(a6),a0
	moveq	#-1,d1
	add.w	PCMCHN-WK(a6),d1
	moveq	#$80,d0
T2XE1A:	and.b	(a0),d0
	lea	CHNSIZ(a0),a0
	dbeq	d1,T2XE1A
	bne	T2XE1D
	move.w	#PCM8FL*$100,ADIOCS.w
	lea	DMACH3,a5
	movea.l	ADPBFX-WK(a6),a0
	move.l	#$02C88004,d1
	move.w	sr,d2
	move.w	#$0700,d0
	and.w	d2,d0
	cmpi.w	#$0300,d0
	bcc	T2XE1B
	ori.w	#$0300,sr
T2XE1B:	moveq	#8,d0
	or.b	d0,(a6)
	tst.b	ENDFLG-WK(a6)
	bne	T2XE1C
	ori.w	#$0700,sr
	and.b	(a5),d0
	bne	T2XE1C
	tas	(a6)
	move.b	#$10,7(a5)
	st	(a5)
	move.l	a0,$C(a5)
	move.w	#PCMBGN,$A(a5)
	move.l	a0,$1C(a5)
	move.w	PCMBR2-WK(a6),$1A(a5)
	movep.w	d1,4(a5)
	swap	d1
	movep.w	d1,5(a5)
	move.b	#$02,PCMCNT
T2XE1C:	move.w	d2,sr
T2XE1D:	movem.l	(sp)+,d1-d2/a0/a5
T2XE1E:	moveq	#0,d0
	rts

T2XE1R:
	moveq	#-1,d0
	rts

T2XEM:	move.b	ADIOCS.w,d0		* 単音再生ﾓｰﾄﾞ
	beq	T2XM0
	cmpi.b	#PCM8FL,d0
	bne	T2XE1R
T2XM0:	movem.l	d1-d5,-(sp)
	lea	DMACH3,a5
	move.w	sr,d4
	move.w	d4,d5
	ori.w	#$0700,d5
	move.w	d5,sr
	sf	M1MOD-WK(a6)
	clr.l	M1LEN-WK(a6)
	move.b	#PCM8FL,ADIOCS.w
	sf	ACTFLG-WK(a6)
	bclr	#0,(a6)
	move.b	#$10,7(a5)		* DMAC停止
	st	(a5)
	move.b	#PCMSP2,PCMDAT
	move.w	d4,sr
	move.l	d2,d3
	moveq	#10,d2
	cmpi.l	#$02000000,d1
	bcc	T2XM1
	tst.l	d2
	beq	T2XM9
	move.l	d3,d2
	cmpi.l	#$01000000,d1
	bcs	T2XM1
	add.l	d2,d2
	add.l	d3,d2
	add.l	d2,d2
T2XM1:	bsr	TCWAIT
	move.w	d1,d0			* 周波数設定
	move.w	d0,-(sp)
	move.b	(sp)+,d0
	cmpi.b	#11,d0
	bcc	T2XM9
	ext.w	d0
	move.b	MODTBL-WK(a6,d0.w),d0
	bmi	T2XM9
	bsr	FRQSET
	tst.b	d1
	beq	T2XM9
	cmpi.b	#4,d1
	bcs	T2XM2
	move.b	PANWK-WK(a6),d1
T2XM2:	bsr	PANSET			* 定位設定
	bsr	PANCNG
	movea.l	ADPBFX-WK(a6),a0
	move.w	d5,sr
	move.b	#$10,7(a5)
	st	(a5)
	move.l	a0,$C(a5)
	move.w	PCMBL0-WK(a6),$A(a5)
	move.l	#$02888004,d0
	movep.w	d0,4(a5)
	swap	d0
	movep.w	d0,5(a5)
	move.b	#$02,PCMCNT
	bset	#0,(a6)
	move.w	d4,sr
	move.l	d1,d0
	rol.l	#8,d0
	andi.b	#3,d0
	move.w	d5,sr
	move.b	d0,M1MOD-WK(a6)
	subq.b	#1,d0
	beq	T2XMA
	bcc	T2XM8
	move.l	#$FFF0,d2		* 通常ﾓｰﾄﾞ
	cmp.l	d2,d3
	bcc	T2XM5
	move.l	d3,d2
T2XM5:	move.w	d2,$1A(a5)
	move.l	a1,$1C(a5)
	sub.l	d2,d3
	adda.l	d2,a1
	move.b	#$48,7(a5)
T2XM8:	move.l	d3,M1LEN-WK(a6)		* 割り込みﾙｰﾁﾝで使用する情報をｾｯﾄ
	move.l	a1,M1ADR-WK(a6)
T2XM9:	move.w	d4,sr
	movem.l	(sp)+,d1-d5
	moveq	#0,d0
	rts

T2XMA:	moveq	#0,d2			* ｱﾚｲﾁｪｰﾝﾓｰﾄﾞ(ﾃｰﾌﾞﾙの数は65535まで)
	not.w	d2
	cmp.l	d2,d3
	bls	T2XM8
	move.l	d2,d3
	bra	T2XM8

T2STOP:	tas	(a5)			* $00Bx:ﾁｬﾝﾈﾙ一時停止
TBLCH1:	moveq	#0,d0
	rts

T2CONT:	move.w	sr,-(sp)		* $00Cx:ﾁｬﾝﾈﾙ一時停止解除
	ori.w	#$0700,sr
	andi.b	#$7F,(a5)
	ori.b	#$40,(a5)
	move.w	(sp)+,sr
	bra	T2XE1X

TBLMOD:	move.l	(a5),d0			* $009x:動作ﾓｰﾄﾞ問い合せ
	andi.l	#$00FFFFFF,d0
	rts

TBLADR:	btst	#2,ADIOCS.w		* $00Ax:ｱｸｾｽｱﾄﾞﾚｽ問い合せ
	bne	TBLADR1
	tst.b	SYSFLG-WK(a6)
	bmi	TBLADR1
	move.l	$1C(a5),d0
	rts

TBLADR1:				* 単音再生ﾓｰﾄﾞ/録音中
	lea	DMACH3+$C,a0
	moveq	#2,d2			* 繰り返しは3回まで
	move.w	sr,d3
TBLADR2:
	ori.w	#$0700,sr
	move.l	(a0),d1
	move.l	(a0),d0
	move.w	d3,sr
	sub.l	d0,d1
	bcc	TBLADR3
	neg.l	d1
TBLADR3:
	cmpi.l	#$8000,d1
	dbcs	d2,TBLADR2
	rts

TBLCNG:	movem.l	d0-d5/a0,-(sp)		* $007x:動作ﾓｰﾄﾞ変更
	andi.l	#$00FFFFFF,d1
	tst.b	d1			* 定位
	beq	TBLC01
	cmpi.b	#4,d1
	bcc	TBLC02
	bsr	PANSET
	bra	TBLC03
TBLC01:	bset	#31,d1
TBLC02:	move.b	3(a5),d1
TBLC03:	ror.w	#8,d1
	cmpi.b	#$40,d1			* 周波数
	bcs	TBLC11
	move.b	2(a5),d1
TBLC11:	swap	d1
	moveq	#0,d3
	movem.w	VOLMN0-WK(a6),d0/d2
	move.b	d1,d3			* 音量
	cmpi.b	#$FF,d3
	bne	TBLC12
	move.b	1(a5),d1
	move.b	d1,d3
TBLC12:	cmpi.b	#15,d3
	bhi	TBLC13
	move.b	PCMXT4-WK(a6,d3.w),d3
TBLC13:	cmp.b	d0,d3
	bcs	TBLC21
	cmp.b	d2,d3
	bls	TBLC22
	move.b	d2,d3
	move.b	d2,d1
	bra	TBLC22
TBLC21:	move.b	d0,d3
	move.b	d0,d1
TBLC22:	swap	d1
	moveq	#$3F,d2
	and.b	d1,d2
	move.b	MODTBL-WK(a6,d2.w),d0
	moveq	#$3F,d2
	and.b	2(a5),d2
	move.b	MODTBL-WK(a6,d2.w),d2
	eor.b	d0,d2
	andi.w	#$F0,d2
	bne	TBLCER
	bclr	#7,d0			* 周波数によって分岐
	bne	TBLC41
	bclr	#6,d0
	bne	TBLCER
	andi.w	#7,d0			* ADPCM
	move.b	d0,d5
	movem.l	d1-d3,-(sp)
	add.w	d0,d0
	move.w	FREQ-WK(a6,d0.w),d0
	moveq	#0,d1
	move.b	FRQSEL-WK(a6),d1
	add.w	d1,d1
	move.w	FREQ-WK(a6,d1.w),d1
	moveq	#0,d2
	moveq	#0,d3
	bsr	FRQCAL
	move.l	d0,d4
	movem.l	(sp)+,d1-d3
	beq	TBLCER
	bsr	FRQADP
	movea.l	d0,a0
	rol.w	#8,d1
	move.b	#VOLOFS,d2
	moveq	#6,d0			* 音量固定ﾁｪｯｸ
	and.b	SYSFLG-WK(a6),d0
	bne	TBLC31
	move.b	d3,d2
TBLC31:	sub.w	VOLMIN-WK(a6),d2
	addi.w	#VOLWID+1,d2
	swap	d2
	lsr.l	#6,d2
	bra	TBLC51

TBLC41:	bclr	#6,d0			* PCM
	bne	TBLC42
	lea	PCMXT2(pc),a0		* 16ﾋﾞｯﾄPCM
	bra	TBLC43

TBLC42:	lea	PCMXT3(pc),a0		* 8ﾋﾞｯﾄPCM
TBLC43:	andi.w	#7,d0
	move.b	d0,d5
	movem.l	d0-d3,-(sp)
	add.w	d0,d0
	move.w	FREQ-WK(a6,d0.w),d0
	moveq	#0,d1
	move.b	FRQSEL-WK(a6),d1
	add.w	d1,d1
	move.w	FREQ-WK(a6,d1.w),d1
	moveq	#64,d2
	moveq	#64,d3
	bsr	FRQCAL
	move.l	d0,d4
	movem.l	(sp)+,d0-d3
	beq	TBLCER
	rol.w	#8,d1
	move.b	#VOLOFS,d2
	moveq	#6,d0			* 音量固定ﾁｪｯｸ
	and.b	SYSFLG-WK(a6),d0
	bne	TBLC44
	move.b	d3,d2			* 処理ｱﾄﾞﾚｽ
TBLC44:	subi.b	#VOLMN2,d2
	add.w	d2,d2
	add.w	d2,d2
	movea.l	(a0,d2.w),a0

TBLC51:	move.l	#$FF000000,d0
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	and.l	(a5),d0
	or.l	d0,d1
	move.l	d1,(a5)			* ﾌﾗｸﾞ変更
	move.l	d2,$24(a5)		* 音量変換用ｵﾌｾｯﾄ変更
	move.l	d4,$18(a5)		* 出力周波数変更
	move.l	a0,$2C(a5)		* 処理ﾙｰﾁﾝｱﾄﾞﾚｽ変更
	moveq	#0,d0
	move.b	$51(a5),d0
	lsl.w	#6,d0
	move.w	d0,$52(a5)
	move.w	(sp)+,sr
	move.b	SYSFLG-WK(a6),d0
	bpl	TBLCNE
	bsr	PANCNG			* 単音再生ﾓｰﾄﾞ時の処理
	move.w	d1,-(sp)
	move.b	(sp)+,d0
	ext.w	d0
	move.b	MODTBL-WK(a6,d0.w),d0
	bmi	TBLCNE
	bsr	FRQSET
TBLCNE:	movem.l	(sp)+,d0-d5/a0
	rts

TBLCER:	tas	(a5)
	bra	TBLCNE

TBLSET:	movem.l	d0-d7/a0-a4,-(sp)	* ﾁｬﾝﾈﾙ動作設定
	lea	-CHNSIZ(sp),sp
	movea.l	sp,a4
	btst	#25,d1
	bne	TBLS00
	tst.l	d2
	beq	TBLS5X
TBLS00:	tst.b	d1			* 定位
	beq	TBLS02
	cmpi.b	#4,d1
	bcs	TBLS01
	move.b	3(a5),d1
TBLS01:	bsr	PANSET
	bra	TBLS03
TBLS02:	bset	#31,d1
	move.b	3(a5),d1
TBLS03:	ror.w	#8,d1
	cmpi.b	#$40,d1			* 周波数
	bcs	TBLS11
	move.b	2(a5),d1
TBLS11:	swap	d1
	moveq	#0,d5
	movem.w	VOLMN0-WK(a6),d3-d4
	move.b	d1,d5			* 音量
	cmpi.b	#$FF,d5
	bne	TBLS12
	move.b	1(a5),d1
	move.b	d1,d5
TBLS12:	cmpi.b	#15,d5
	bhi	TBLS13
	move.b	PCMXT4-WK(a6,d5.w),d5
TBLS13:	cmp.b	d3,d5
	bcs	TBLS21
	cmp.b	d4,d5
	bls	TBLS22
	move.b	d4,d1
	move.b	d4,d5
	bra	TBLS22
TBLS21:	move.b	d3,d1
	move.b	d3,d5
TBLS22:	ori.w	#$4000,d1		* 初期化ﾌﾗｸﾞｾｯﾄ
	swap	d1
	moveq	#$3F,d0
	and.b	d1,d0
	move.b	MODTBL-WK(a6,d0.w),d0
	move.b	d0,d3
	bmi	TBLS41
	andi.w	#7,d0			* ADPCM
	moveq	#0,d6
	move.b	d0,d6
	movem.l	d1-d3,-(sp)
	add.w	d0,d0
	move.w	FREQ-WK(a6,d0.w),d0
	moveq	#0,d1
	move.b	FRQSEL-WK(a6),d1
	add.w	d1,d1
	move.w	FREQ-WK(a6,d1.w),d1
	moveq	#0,d2
	moveq	#0,d3
	bsr	FRQCAL
	move.l	d0,d7
	movem.l	(sp)+,d1-d3
	beq	TBLS5X
	bsr	FRQADP
	movea.l	d0,a2			* 処理ｱﾄﾞﾚｽ
	rol.w	#8,d1
	swap	d1
	move.l	TBLAD1-WK(a6),d3	* 倍率ﾃｰﾌﾞﾙｱﾄﾞﾚｽ
	moveq	#0,d4
	move.b	#VOLOFS,d4
	moveq	#6,d0			* 音量固定ﾁｪｯｸ
	and.b	SYSFLG-WK(a6),d0
	bne	TBLS31
	move.b	d5,d4
TBLS31:	sub.b	VOLMIN+1-WK(a6),d4
	addi.w	#VOLWID+1,d4
	swap	d4
	lsr.l	#6,d4
	bra	TBLS51

TBLS41:	bchg	#6,d0
	bne	TBLS42			* PCM
	lea	PCMXT2(pc),a0		* 16ﾋﾞｯﾄPCM
	rol.w	#8,d1
	swap	d1
	moveq	#4,d6
	move.w	d1,d0
	andi.w	#$0300,d0
	bne	TBLS46
	btst	#0,d2
	bne	TBLS45
TBLS46:	move.l	a1,d0
	andi.w	#1,d0
	beq	TBLS43
TBLS45:	ori.w	#$8000,d1
	bra	TBLS43

TBLS42:	bchg	#5,d0
	bne	TBLS5X
	lea	PCMXT3(pc),a0		* 8ﾋﾞｯﾄPCM
	rol.w	#8,d1
	swap	d1
	moveq	#8,d6
TBLS43:	moveq	#7,d0
	and.w	d3,d0
	swap	d6
	move.b	d0,d6
	movem.l	d1-d3,-(sp)
	add.w	d0,d0
	move.w	FREQ-WK(a6,d0.w),d0
	moveq	#0,d1
	move.b	FRQSEL-WK(a6),d1
	add.w	d1,d1
	move.w	FREQ-WK(a6,d1.w),d1
	moveq	#0,d2
	moveq	#0,d3
	bsr	FRQCAL
	move.l	d0,d7
	movem.l	(sp)+,d1-d3
	beq	TBLS51
	moveq	#0,d4
	move.b	#VOLOFS,d4
	moveq	#6,d3			* 音量固定ﾁｪｯｸ
	and.b	SYSFLG-WK(a6),d3
	bne	TBLS44
	move.b	d5,d4
TBLS44:	subi.b	#VOLMN2,d4
	add.w	d4,d4
	add.w	d4,d4
	movea.l	(a0,d4.w),a2		* 処理ｱﾄﾞﾚｽ
	moveq	#0,d3
TBLS51:	movea.l	a4,a3
	move.w	d1,d0
	andi.w	#$0300,d0
	cmpi.w	#$0100,d0
	bcc	TBLS52
	swap	d1			* 通常出力
	add.l	a1,d2
	moveq	#0,d0
	move.l	d1,(a3)+
	move.l	d3,(a3)+
	move.l	d0,(a3)+
	swap	d6
	move.w	d0,(a3)+
	move.w	2+PCMMOD-WK(a6,d6.w),(a3)+
	lea.l	$40(a5),a0
	move.l	a0,(a3)+
	move.l	d0,(a3)+
	move.l	d7,(a3)+
	move.l	a1,(a3)+
	lea	DPCMBF-WK(a6),a0
	move.l	(a0,d6.w),(a3)+
	move.l	d4,(a3)+
	move.l	d2,(a3)+
	move.l	a2,(a3)+
	move.l	a1,(a3)+
	move.l	a1,(a3)+
	move.l	a1,(a3)+
	move.l	d2,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.b	PCMMOD-WK(a6,d6.w),(a3)+
	move.b	#64,(a3)+
	move.w	#64*64,(a3)+
	move.b	#64,(a3)+
	move.b	d0,(a3)+
	move.w	d0,(a3)+
TBLSEE:	move.w	sr,-(sp)
	ori.w	#$0700,sr
	movem.l	(a4),d0-d7/a0-a2
	movem.l	d0-d7/a0-a2,(a5)
	movem.l	44(a4),d0-d7/a0-a2
	movem.l	d0-d7/a0-a2,44(a5)
	move.w	(sp)+,sr
TBLSE1:	lea	CHNSIZ(sp),sp
	movem.l	(sp)+,d0-d7/a0-a4
	rts

TBLS5X:	tas	(a5)			* ﾁｬﾝﾈﾙ停止
	bra	TBLSE1

TBLS52:	bne	TBLS53
	subq.w	#1,d2			* ｱﾚｲﾁｪｰﾝ出力
	bmi	TBLS5X
	move.l	a1,d0
	andi.w	#1,d0
	bne	TBLS521
	swap	d1
	moveq	#0,d0
	move.l	d1,(a3)+
	move.l	d3,(a3)+
	move.l	d0,(a3)+
	swap	d6
	move.w	d2,(a3)+
	move.w	2+PCMMOD-WK(a6,d6.w),(a3)+
	moveq	#6,d1
	add.l	a1,d1
	move.l	d1,(a3)+
	move.l	d0,(a3)+
	move.l	d7,(a3)+
	move.l	(a1)+,d3
	cmpi.b	#4,d6
	bne	TBLS522
	btst	#0,d3
	beq	TBLS522
	tas	(a4)
TBLS522:
	move.l	d3,(a3)+
	lea	DPCMBF-WK(a6),a0
	move.l	(a0,d6.w),(a3)+
	move.l	d4,(a3)+
	moveq	#0,d2
	move.w	(a1)+,d2
	cmpi.b	#4,d6
	bne	TBLS523
	btst	#0,d2
	beq	TBLS523
	tas	(a4)
TBLS523:
	add.l	d3,d2
	move.l	d2,(a3)+
	move.l	a2,(a3)+
	move.l	d3,(a3)+
	move.l	d3,(a3)+
	move.l	d3,(a3)+
	move.l	d2,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.b	PCMMOD-WK(a6,d6.w),(a3)+
	move.b	#64,(a3)+
	move.w	#64*64,(a3)+
	move.b	#64,(a3)+
	move.b	d0,(a3)+
	move.w	d0,(a3)+
	cmp.l	d2,d3
	bne	TBLSEE
	tas	(a4)
	bra	TBLSEE

TBLS521:
	ori.w	#$8000,d1
	swap	d1
	moveq	#0,d0
	move.l	d1,(a3)+
	move.l	d3,(a3)+
	move.l	d0,(a3)+
	swap	d6
	move.w	d0,(a3)+
	move.w	2+PCMMOD-WK(a6,d6.w),(a3)+
	lea	$40(a5),a0
	move.l	a0,(a3)+
	move.l	d0,(a3)+
	move.l	d7,(a3)+
	move.l	d0,(a3)+
	lea	DPCMBF-WK(a6),a0
	move.l	(a0,d6.w),(a3)+
	move.l	d4,(a3)+
	move.l	d0,(a3)+
	move.l	a2,(a3)+
	move.l	d3,(a3)+
	move.l	d3,(a3)+
	move.l	d3,(a3)+
	move.l	d2,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.b	PCMMOD-WK(a6,d6.w),(a3)+
	move.b	#64,(a3)+
	move.w	#64*64,(a3)+
	move.b	#64,(a3)+
	move.b	d0,(a3)+
	move.w	d0,(a3)+
	bra	TBLSEE

TBLS53:	move.l	a1,d0			* ﾘﾝｸｱﾚｲﾁｪｰﾝ出力
	andi.w	#1,d0
	bne	TBLS521
	swap	d1
	moveq	#0,d0
	move.l	d1,(a3)+
	move.l	d3,(a3)+
	move.l	d0,(a3)+
	swap	d6
	move.w	d0,(a3)+
	move.w	2+PCMMOD-WK(a6,d6.w),(a3)+
	moveq	#6,d1
	add.l	a1,d1
	move.l	d1,(a3)+
	move.l	d0,(a3)+
	move.l	d7,(a3)+
	move.l	(a1)+,d3
	cmpi.b	#4,d6
	bne	TBLS532
	btst	#0,d3
	beq	TBLS532
	tas	(a4)
TBLS532:
	move.l	d3,(a3)+
	lea	DPCMBF-WK(a6),a0
	move.l	(a0,d6.w),(a3)+
	move.l	d4,(a3)+
	moveq	#0,d2
	move.w	(a1)+,d2
	cmpi.b	#4,d6
	bne	TBLS533
	btst	#0,d3
	beq	TBLS533
	tas	(a4)
TBLS533:
	add.l	d3,d2
	move.l	d2,(a3)+
	move.l	a2,(a3)+
	move.l	d3,(a3)+
	move.l	d3,(a3)+
	move.l	d3,(a3)+
	move.l	d2,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.l	d0,(a3)+
	move.b	PCMMOD-WK(a6,d6.w),(a3)+
	move.b	#64,(a3)+
	move.w	#64*64,(a3)+
	move.b	#64,(a3)+
	move.b	d0,(a3)+
	move.w	d0,(a3)+
	cmp.l	d2,d3
	bne	TBLSEE
	tas	(a4)
	bra	TBLSEE

PANSET:	movem.l	d0-d1,-(sp)		* 定位設定
	cmpi.b	#4,d1
	bcc	PANSE3
	move.b	PANWK-WK(a6),d0
	tst.w	PANFLG-WK(a6)
	bne	PANSE1
	moveq	#3,d0
	and.b	PPIPC,d0
	move.b	PANTBL(pc,d0.w),d0
	move.b	d0,PANWK-WK(a6)
PANSE1:	cmp.b	d0,d1
	beq	PANSE3
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	move.b	d1,PANWK-WK(a6)
	not.b	d1
	moveq	#1,d0
	lsr.b	#1,d1
	addx.b	d0,d0
	move.b	d0,PANWK1-WK(a6)
	moveq	#0,d0
	lsr.b	#1,d1
	addx.b	d0,d0
	move.b	d0,PANWK1+1-WK(a6)
	bset	#4,PANFLG-WK(a6)
	move.w	(sp)+,sr
PANSE3:	movem.l	(sp)+,d0-d1
	rts

PANTBL:	.dc.b	3,1,2,0

PANCNG:	move.w	d0,-(sp)		* 定位変更
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	move.w	PANWK1-WK(a6),d0
	move.w	d0,PANWK2-WK(a6)
	move.w	d0,PANWK3-WK(a6)
	move.b	d0,PPICTL
	rol.w	#8,d0
	move.b	d0,PPICTL
	sf	PANFLG-WK(a6)
	move.w	(sp)+,sr
	move.w	(sp)+,d0
	rts

FRQSE0:	movem.l	d0-d2/a0,-(sp)		* 周波数ﾓｰﾄﾞ自動判別時ｴﾝﾄﾘ
	bra	FRQSE1

FRQSET:	movem.l	d0-d2/a0,-(sp)		* 再生周波数設定
	cmpi.b	#7,d0
	bcc	FRQSEE
	movea.l	FRQPTR-WK(a6),a0
	ext.w	d0
	move.b	(a0,d0.w),d0
	btst	#6,d0
	bne	FRQSEE
FRQSE1:	move.w	sr,-(sp)
	moveq	#$0C,d1
	ori.w	#$0700,sr
	and.b	PPIPC,d1
	lsr.b	#2,d1
	move.b	FM1BBF.w,d2
	bpl	FRQSE2
	tas	d1
FRQSE2:	eor.b	d0,d1
	beq	FRQSE6
	bpl	FRQSE5
FRQSE3:	tst.b	FMDAT
	bmi	FRQSE3
	move.b	#$1B,FMADR
	andi.b	#$7F,d2
	tst.b	d0
	bpl	FRQSE4
	tas	d2
FRQSE4:	tst.b	FMDAT
	bmi	FRQSE4
	move.b	d2,FMDAT
	move.b	d2,FM1BBF.w
FRQSE5:	andi.b	#3,d1
	beq	FRQSE6
	moveq	#2,d1
	lsr.b	#1,d0
	addx.b	d1,d1
	move.b	d1,PPICTL
	moveq	#3,d1
	lsr.b	#1,d0
	addx.b	d1,d1
	move.b	d1,PPICTL
FRQSE6:	move.w	(sp)+,sr
FRQSEE:	movem.l	(sp)+,d0-d2/a0
	rts

FRQCAL:	movem.l	d1-d6/a0,-(sp)
	moveq	#0,d5
	moveq	#0,d6
	move.w	d0,d5
	moveq	#1,d0
	swap	d0
	cmp.w	d5,d1
	beq	FRQC01
	moveq	#0,d0
	moveq	#1,d6
	tst.w	d5
	beq	FRQCEN
	tst.w	d1
	beq	FRQCEN
	divu.w	d1,d5
	move.w	d5,d0
	swap	d0
	cmpi.l	#$10000,d5
	bcs	FRQC01
	move.w	#$8000,d5
	divu.w	d1,d5
	move.w	d5,d0
FRQC01:	moveq	#1,d1
	swap	d1
	sub.w	d3,d2
	beq	FRQC20
	bcs	FRQC10
	ori.b	#2,d6
	ext.l	d2
	divu.w	#12*64,d2
	move.l	d2,d3
	swap	d3
	add.w	d3,d3
	beq	FRQC02
	lea	FRQCTB(pc),a0
	move.w	(a0,d3.w),d1
FRQC02:	lsl.l	d2,d1
	bra	FRQC20

FRQC10:	ori.b	#2,d6
	neg.w	d2
	ext.l	d2
	divu.w	#12*64,d2
	move.l	d2,d3
	swap	d3
	neg.w	d3
	beq	FRQC12
	addq.w	#1,d2
	addi.w	#12*64,d3
	add.w	d3,d3
	lea	FRQCTB(pc),a0
	move.w	(a0,d3.w),d1
FRQC12:	lsr.l	d2,d1
FRQC20:	cmpi.b	#2,d6
	bcs	FRQCEN
	beq	FRQC30
	move.l	d0,d3
	move.w	d0,d2
	mulu.w	d1,d2
	swap	d0
	mulu.w	d1,d0
	swap	d1
	move.w	d3,d5
	mulu.w	d1,d5
	swap	d3
	mulu.w	d1,d3
	clr.w	d2
	swap	d2
	add.l	d2,d0
	add.l	d5,d0
	swap	d3
	clr.w	d3
	add.l	d3,d0
FRQCEN:	movem.l	(sp)+,d1-d6/a0
	tst.l	d0
	rts

FRQC30:	move.l	d1,d0
	bra	FRQCEN

FRQADP:	movem.l	d1-d2/a0,-(sp)
	lea	PCMXTB(pc),a0
FRQAD1:	movem.l	(a0)+,d1-d2
	cmp.l	d1,d0
	bcs	FRQAD1
	move.l	d2,d0
	movem.l	(sp)+,d1-d2/a0
	rts

	.dc.w	0			* 4ﾊﾞｲﾄ境界調整用			*;dummy

*	音程変換用ﾃｰﾌﾞﾙ
*	以下の値は 65536*(2^(n/768)-1) の解を四捨五入したもの (n=0～767)
FRQCTB:	.dc.w	$0000,$003B,$0076,$00B2,$00ED,$0128,$0164,$019F
	.dc.w	$01DB,$0217,$0252,$028E,$02CA,$0305,$0341,$037D
	.dc.w	$03B9,$03F5,$0431,$046E,$04AA,$04E6,$0522,$055F
	.dc.w	$059B,$05D8,$0614,$0651,$068D,$06CA,$0707,$0743
	.dc.w	$0780,$07BD,$07FA,$0837,$0874,$08B1,$08EF,$092C
	.dc.w	$0969,$09A7,$09E4,$0A21,$0A5F,$0A9C,$0ADA,$0B18
	.dc.w	$0B56,$0B93,$0BD1,$0C0F,$0C4D,$0C8B,$0CC9,$0D07
	.dc.w	$0D45,$0D84,$0DC2,$0E00,$0E3F,$0E7D,$0EBC,$0EFA
	.dc.w	$0F39,$0F78,$0FB6,$0FF5,$1034,$1073,$10B2,$10F1
	.dc.w	$1130,$116F,$11AE,$11EE,$122D,$126C,$12AC,$12EB
	.dc.w	$132B,$136B,$13AA,$13EA,$142A,$146A,$14A9,$14E9
	.dc.w	$1529,$1569,$15AA,$15EA,$162A,$166A,$16AB,$16EB
	.dc.w	$172C,$176C,$17AD,$17ED,$182E,$186F,$18B0,$18F0
	.dc.w	$1931,$1972,$19B3,$19F5,$1A36,$1A77,$1AB8,$1AFA
	.dc.w	$1B3B,$1B7D,$1BBE,$1C00,$1C41,$1C83,$1CC5,$1D07
	.dc.w	$1D48,$1D8A,$1DCC,$1E0E,$1E51,$1E93,$1ED5,$1F17
	.dc.w	$1F5A,$1F9C,$1FDF,$2021,$2064,$20A6,$20E9,$212C
	.dc.w	$216F,$21B2,$21F5,$2238,$227B,$22BE,$2301,$2344
	.dc.w	$2388,$23CB,$240E,$2452,$2496,$24D9,$251D,$2561
	.dc.w	$25A4,$25E8,$262C,$2670,$26B4,$26F8,$273D,$2781
	.dc.w	$27C5,$280A,$284E,$2892,$28D7,$291C,$2960,$29A5
	.dc.w	$29EA,$2A2F,$2A74,$2AB9,$2AFE,$2B43,$2B88,$2BCD
	.dc.w	$2C13,$2C58,$2C9D,$2CE3,$2D28,$2D6E,$2DB4,$2DF9
	.dc.w	$2E3F,$2E85,$2ECB,$2F11,$2F57,$2F9D,$2FE3,$302A
	.dc.w	$3070,$30B6,$30FD,$3143,$318A,$31D0,$3217,$325E
	.dc.w	$32A5,$32EC,$3332,$3379,$33C1,$3408,$344F,$3496
	.dc.w	$34DD,$3525,$356C,$35B4,$35FB,$3643,$368B,$36D3
	.dc.w	$371A,$3762,$37AA,$37F2,$383A,$3883,$38CB,$3913
	.dc.w	$395C,$39A4,$39ED,$3A35,$3A7E,$3AC6,$3B0F,$3B58
	.dc.w	$3BA1,$3BEA,$3C33,$3C7C,$3CC5,$3D0E,$3D58,$3DA1
	.dc.w	$3DEA,$3E34,$3E7D,$3EC7,$3F11,$3F5A,$3FA4,$3FEE
	.dc.w	$4038,$4082,$40CC,$4116,$4161,$41AB,$41F5,$4240
	.dc.w	$428A,$42D5,$431F,$436A,$43B5,$4400,$444B,$4495
	.dc.w	$44E1,$452C,$4577,$45C2,$460D,$4659,$46A4,$46F0
	.dc.w	$473B,$4787,$47D3,$481E,$486A,$48B6,$4902,$494E
	.dc.w	$499A,$49E6,$4A33,$4A7F,$4ACB,$4B18,$4B64,$4BB1
	.dc.w	$4BFE,$4C4A,$4C97,$4CE4,$4D31,$4D7E,$4DCB,$4E18
	.dc.w	$4E66,$4EB3,$4F00,$4F4E,$4F9B,$4FE9,$5036,$5084
	.dc.w	$50D2,$5120,$516E,$51BC,$520A,$5258,$52A6,$52F4
	.dc.w	$5343,$5391,$53E0,$542E,$547D,$54CC,$551A,$5569
	.dc.w	$55B8,$5607,$5656,$56A5,$56F4,$5744,$5793,$57E2
	.dc.w	$5832,$5882,$58D1,$5921,$5971,$59C1,$5A10,$5A60
	.dc.w	$5AB0,$5B01,$5B51,$5BA1,$5BF1,$5C42,$5C92,$5CE3
	.dc.w	$5D34,$5D84,$5DD5,$5E26,$5E77,$5EC8,$5F19,$5F6A
	.dc.w	$5FBB,$600D,$605E,$60B0,$6101,$6153,$61A4,$61F6
	.dc.w	$6248,$629A,$62EC,$633E,$6390,$63E2,$6434,$6487
	.dc.w	$64D9,$652C,$657E,$65D1,$6624,$6676,$66C9,$671C
	.dc.w	$676F,$67C2,$6815,$6869,$68BC,$690F,$6963,$69B6
	.dc.w	$6A0A,$6A5E,$6AB1,$6B05,$6B59,$6BAD,$6C01,$6C55
	.dc.w	$6CAA,$6CFE,$6D52,$6DA7,$6DFB,$6E50,$6EA4,$6EF9
	.dc.w	$6F4E,$6FA3,$6FF8,$704D,$70A2,$70F7,$714D,$71A2
	.dc.w	$71F7,$724D,$72A2,$72F8,$734E,$73A4,$73FA,$7450
	.dc.w	$74A6,$74FC,$7552,$75A8,$75FF,$7655,$76AC,$7702
	.dc.w	$7759,$77B0,$7807,$785E,$78B4,$790C,$7963,$79BA
	.dc.w	$7A11,$7A69,$7AC0,$7B18,$7B6F,$7BC7,$7C1F,$7C77
	.dc.w	$7CCF,$7D27,$7D7F,$7DD7,$7E2F,$7E88,$7EE0,$7F38
	.dc.w	$7F91,$7FEA,$8042,$809B,$80F4,$814D,$81A6,$81FF
	.dc.w	$8259,$82B2,$830B,$8365,$83BE,$8418,$8472,$84CB
	.dc.w	$8525,$857F,$85D9,$8633,$868E,$86E8,$8742,$879D
	.dc.w	$87F7,$8852,$88AC,$8907,$8962,$89BD,$8A18,$8A73
	.dc.w	$8ACE,$8B2A,$8B85,$8BE0,$8C3C,$8C97,$8CF3,$8D4F
	.dc.w	$8DAB,$8E07,$8E63,$8EBF,$8F1B,$8F77,$8FD4,$9030
	.dc.w	$908C,$90E9,$9146,$91A2,$91FF,$925C,$92B9,$9316
	.dc.w	$9373,$93D1,$942E,$948C,$94E9,$9547,$95A4,$9602
	.dc.w	$9660,$96BE,$971C,$977A,$97D8,$9836,$9895,$98F3
	.dc.w	$9952,$99B0,$9A0F,$9A6E,$9ACD,$9B2C,$9B8B,$9BEA
	.dc.w	$9C49,$9CA8,$9D08,$9D67,$9DC7,$9E26,$9E86,$9EE6
	.dc.w	$9F46,$9FA6,$A006,$A066,$A0C6,$A127,$A187,$A1E8
	.dc.w	$A248,$A2A9,$A30A,$A36B,$A3CC,$A42D,$A48E,$A4EF
	.dc.w	$A550,$A5B2,$A613,$A675,$A6D6,$A738,$A79A,$A7FC
	.dc.w	$A85E,$A8C0,$A922,$A984,$A9E7,$AA49,$AAAC,$AB0E
	.dc.w	$AB71,$ABD4,$AC37,$AC9A,$ACFD,$AD60,$ADC3,$AE27
	.dc.w	$AE8A,$AEED,$AF51,$AFB5,$B019,$B07C,$B0E0,$B145
	.dc.w	$B1A9,$B20D,$B271,$B2D6,$B33A,$B39F,$B403,$B468
	.dc.w	$B4CD,$B532,$B597,$B5FC,$B662,$B6C7,$B72C,$B792
	.dc.w	$B7F7,$B85D,$B8C3,$B929,$B98F,$B9F5,$BA5B,$BAC1
	.dc.w	$BB28,$BB8E,$BBF5,$BC5B,$BCC2,$BD29,$BD90,$BDF7
	.dc.w	$BE5E,$BEC5,$BF2C,$BF94,$BFFB,$C063,$C0CA,$C132
	.dc.w	$C19A,$C202,$C26A,$C2D2,$C33A,$C3A2,$C40B,$C473
	.dc.w	$C4DC,$C544,$C5AD,$C616,$C67F,$C6E8,$C751,$C7BB
	.dc.w	$C824,$C88D,$C8F7,$C960,$C9CA,$CA34,$CA9E,$CB08
	.dc.w	$CB72,$CBDC,$CC47,$CCB1,$CD1B,$CD86,$CDF1,$CE5B
	.dc.w	$CEC6,$CF31,$CF9C,$D008,$D073,$D0DE,$D14A,$D1B5
	.dc.w	$D221,$D28D,$D2F8,$D364,$D3D0,$D43D,$D4A9,$D515
	.dc.w	$D582,$D5EE,$D65B,$D6C7,$D734,$D7A1,$D80E,$D87B
	.dc.w	$D8E9,$D956,$D9C3,$DA31,$DA9E,$DB0C,$DB7A,$DBE8
	.dc.w	$DC56,$DCC4,$DD32,$DDA0,$DE0F,$DE7D,$DEEC,$DF5B
	.dc.w	$DFC9,$E038,$E0A7,$E116,$E186,$E1F5,$E264,$E2D4
	.dc.w	$E343,$E3B3,$E423,$E493,$E503,$E573,$E5E3,$E654
	.dc.w	$E6C4,$E735,$E7A5,$E816,$E887,$E8F8,$E969,$E9DA
	.dc.w	$EA4B,$EABC,$EB2E,$EB9F,$EC11,$EC83,$ECF5,$ED66
	.dc.w	$EDD9,$EE4B,$EEBD,$EF2F,$EFA2,$F014,$F087,$F0FA
	.dc.w	$F16D,$F1E0,$F253,$F2C6,$F339,$F3AD,$F420,$F494
	.dc.w	$F507,$F57B,$F5EF,$F663,$F6D7,$F74C,$F7C0,$F834
	.dc.w	$F8A9,$F91E,$F992,$FA07,$FA7C,$FAF1,$FB66,$FBDC
	.dc.w	$FC51,$FCC7,$FD3C,$FDB2,$FE28,$FE9E,$FF14,$FF8A

VOLCTB:	.dc.b	$6B,$6C,$6C,$6D,$6D,$6D,$6E,$6E		* 音量変換用ﾃｰﾌﾞﾙ
	.dc.b	$6F,$6F,$6F,$6F,$70,$70,$70,$71
	.dc.b	$71,$71,$72,$72,$72,$73,$73,$73
	.dc.b	$74,$74,$75,$75,$75,$76,$76,$76
	.dc.b	$76,$77,$77,$77,$78,$78,$78,$78
	.dc.b	$79,$79,$79,$7A,$7A,$7A,$7B,$7B
	.dc.b	$7B,$7B,$7C,$7C,$7C,$7C,$7D,$7D
	.dc.b	$7D,$7E,$7E,$7E,$7F,$7F,$7F,$80
	.dc.b	$80,$80,$80,$81,$81,$81,$82,$82
	.dc.b	$82,$82,$83,$83,$83,$83,$84,$84
	.dc.b	$84,$85,$85,$85,$86,$86,$86,$87
	.dc.b	$87,$87,$88,$88,$88,$89,$89,$89
	.dc.b	$8A,$8A,$8A,$8A,$8B,$8B,$8B,$8C
	.dc.b	$8C,$8C,$8D,$8D,$8D,$8E,$8E,$8E
	.dc.b	$8F,$8F,$8F,$90,$90,$90,$91,$91
	.dc.b	$91,$92,$92,$92,$93,$93,$93,$94

VOLCT1:	.dc.b	$6B,$6C,$6C,$6D,$6D,$6D,$6E,$6E		* ﾃﾞﾌｫﾙﾄの音量変換用ﾃｰﾌﾞﾙ
	.dc.b	$6F,$6F,$6F,$6F,$70,$70,$70,$71
	.dc.b	$71,$71,$72,$72,$72,$73,$73,$73
	.dc.b	$74,$74,$75,$75,$75,$76,$76,$76
	.dc.b	$76,$77,$77,$77,$78,$78,$78,$78
	.dc.b	$79,$79,$79,$7A,$7A,$7A,$7B,$7B
	.dc.b	$7B,$7B,$7C,$7C,$7C,$7C,$7D,$7D
	.dc.b	$7D,$7E,$7E,$7E,$7F,$7F,$7F,$80
	.dc.b	$80,$80,$80,$81,$81,$81,$82,$82
	.dc.b	$82,$82,$83,$83,$83,$83,$84,$84
	.dc.b	$84,$85,$85,$85,$86,$86,$86,$87
	.dc.b	$87,$87,$88,$88,$88,$89,$89,$89
	.dc.b	$8A,$8A,$8A,$8A,$8B,$8B,$8B,$8C
	.dc.b	$8C,$8C,$8D,$8D,$8D,$8E,$8E,$8E
	.dc.b	$8F,$8F,$8F,$90,$90,$90,$91,$91
	.dc.b	$91,$92,$92,$92,$93,$93,$93,$94

VOLCT2:	.dc.w	   0,   0,   0,   1,   1,   1,   1,   1	* 音量ﾃｰﾌﾞﾙ
	.dc.w	   1,   1,   1,   2,   2,   2,   2,   3
	.dc.w	   3,   3,   4,   4,   5,   5,   6,   6
	.dc.w	   7,   8,   9,   9,  10,  12,  13,  14
	.dc.w	  15,  17,  19,  21,  23,  25,  28,  31
	.dc.w	  34,  37,  41,  45,  50,  55,  60,  66
	.dc.w	  73,  80,  88,  97, 107, 118, 130, 143
	.dc.w	 157, 173, 190, 209, 230, 253, 279, 307
	.dc.w	 337, 371, 408, 449, 494, 543, 598, 658
	.dc.w	 724, 796, 876, 963,1060,1166,1282,1410
	.dc.w	1551,1707,1877,2065,2272,2499,2749,3024
	.dc.w	3326,3659,4025,4427,4870,5357,5893,6482
	.dc.w	7131

	.dc.w	0,0,0			* 4ﾊﾞｲﾄ境界調整用			*;dummy

PCMXTB:	.dc.l	$00040000,AD20		* ADPCM音程変換ﾙｰﾁﾝﾃｰﾌﾞﾙ
	.dc.l	$00020005,AD10
	.dc.l	$0001FFFC,ADM1
	.dc.l	$00010005,AD00
	.dc.l	$0000FFFC,ADM0
	.dc.l	$00008005,ADA0
	.dc.l	$00007FFC,ADMA
	.dc.l	$00000000,ADB0

FRQTBL:	.dc.b	$80,$81,$00,$01,$02,$40,$40,$40		* -M0
	.dc.b	$40,$40,$00,$01,$02,$81,$82,$40		* -M1
	.dc.b	$80,$81,$00,$01,$02,$83,$82,$40		* -M2
	.dc.b	$80,$81,$00,$01,$02,$03,$83,$40		* -M3
	.dc.b	$80,$81,$00,$01,$02,$83,$03,$40		* -M4

PCMXT2:	.dcb.l	VOLMX2-VOLMN2+1,0	* 16bitPCM音量変換ﾙｰﾁﾝﾃｰﾌﾞﾙ

PCMXT3:	.dcb.l	VOLMX2-VOLMN2+1,0	* 8bitPCM音量変換ﾙｰﾁﾝﾃｰﾌﾞﾙ

*--------------------------------------------------------------------
*	ﾜｰｸｴﾘｱ

FRQPTR:	.dc.l	FRQTBL		* 周波数ﾃｰﾌﾞﾙｱﾄﾞﾚｽ
BFADR1:	.dc.w	0		* ADPCM出力ﾊﾞｯﾌｧｱﾄﾞﾚｽ
PCMCHN:	.dc.w	PCMCI1		* ﾁｬﾝﾈﾙ数(最大250)
PCMCMX:	.dc.w	PCMCI2		*   〃	 の最大
PCMFLG:	.dc.w	0		* ﾊﾞｲﾄ数変更ﾌﾗｸﾞ
PCMFL2:	.dc.w	0		* ﾊﾞｲﾄ数変更ﾌﾗｸﾞ
PCMBN0:	.dc.w	PCMBI1/12
PCMBN1:	.dc.w	PCMBI1/12
PCMBNX:	.dc.w	PCMBI2/12
PCMBL0:	.dc.w	PCMBI1		* 1回に処理するﾊﾞｲﾄ数ADPCM→DPCM用
PCMBL1:	.dc.w	PCMBI1		*	〃		〃
PCMBMX:	.dc.w	PCMBI2		*	〃	     の最大
PCMBR0:	.dc.w	PCMBI1		* 1回に処理するﾊﾞｲﾄ数DPCM→ADPCM用
PCMBR1:	.dc.w	PCMBI1		*	〃		〃
PCMBR2:	.dc.w	PCMBI1		*	〃		〃
VOLMN0:	.dc.w	VOLMN1		* 音量指定最小値
VOLMX0:	.dc.w	VOLMX1		* 音量指定最大値
VOLMIN:	.dc.w	VOLMN2		* 音量指定最小値
VOLMAX:	.dc.w	VOLMX2		* 音量指定最大値
OUTOF1:	.dc.w	0		* 直前のPCMﾃﾞｰﾀ
PCMOFS:	.dc.w	0		* DPCM誤差:変換時D0に入る
PCMTBL:	.dc.l	0		* DPCM→ADPCM変換ﾃｰﾌﾞﾙｱﾄﾞﾚｽ1(ﾜｰｸ):変換時A2に入る
TBLAD3:	.dc.l	0		* DPCM→ADPCM変換ﾃｰﾌﾞﾙｱﾄﾞﾚｽ2:変換時A3に入る
TBLAD1:	.dc.l	0		* ADPCM→DPCM変換ﾃｰﾌﾞﾙｱﾄﾞﾚｽ情報(初期値,ｱﾄﾞﾚｽそのものではない)
TBLAD2:	.dc.l	0		* DPCM→ADPCM変換ﾃｰﾌﾞﾙｱﾄﾞﾚｽ1(初期値)
INTWK:	.dc.l	$FBFFDF00	* 割り込みﾚﾍﾞﾙ/ﾏｽｸ
M1LEN:	.dc.l	0		* 単音再生ﾓｰﾄﾞﾃﾞｰﾀ長さ
M1ADR:	.dc.l	0		*	〃　　ｱﾄﾞﾚｽ
INTWK2:	.dc.w	$FDFF		* 割り込みﾏｽｸ中の割り込みﾚﾍﾞﾙ
PANFLG:	.dc.w	0		* 定位変更ﾌﾗｸﾞ
PANWK1:	.dc.w	$0301		* 定位変更ﾜｰｸ1
PANWK2:	.dc.w	$0301		*	〃   2
PANWK3:	.dc.w	$0301		*	〃   3

FRQMOD:	.dc.b	0		* 周波数切り替えﾓｰﾄﾞ(0:4M/8M,1:16M/8M,2～4:4M/8M/16M)
FRQSEL:	.dc.b	4		* 基準周波数(0～6)→($01F7CALL READ時:4～7,0～2)

DPCMBF:	.dc.l	0		* DPCMﾊﾞｯﾌｧｱﾄﾞﾚｽ
PCMBU1:	.dc.l	0		* 16ﾋﾞｯﾄPCM用ﾊﾞｯﾌｧｱﾄﾞﾚｽ
PCMBU2:	.dc.l	0		* 8ﾋﾞｯﾄPCM用ﾊﾞｯﾌｧｱﾄﾞﾚｽ

ADPBF1:	.dc.l	0		* ADPCMﾊﾞｯﾌｧ1ｱﾄﾞﾚｽ
ADPBF2:	.dc.l	0		*      〃   2  〃
ADPBFX:	.dc.l	0		* ADPCMﾀﾞﾐｰﾃﾞｰﾀｱﾄﾞﾚｽ
CHNWK:	.dc.l	0		* ﾁｬﾝﾈﾙﾜｰｸｱﾄﾞﾚｽ
KEPBUF:	.dc.l	T1KBUF		* 占有ﾊﾞｯﾌｧｱﾄﾞﾚｽ

FREQ:	.dc.w	3906,5208,7812,10416,15625,20833,31250	* 周波数
FREQ1:	.dc.w	   3,   4,   6,    8,   12,   16,   24	* 処理ﾊﾞｲﾄ数の単位

*		下のﾃｰﾌﾞﾙｱﾄﾞﾚｽへの変換用
PCMMD2:	.dc.b	$00,$04,$08,$00

*		ADPCM     16bitPCM  8bitPCM
PCMMOD:	.dc.l	$FF00001E,$0100801F,$0200001F
PCMINI:	.dc.l	0,$10000,$20000

*		PCM8 音量ﾃｰﾌﾞﾙ (0～15) $xx(a6,xn)でｱｸｾｽ
PCMXT4:	.dc.b	$6B,$6F,$71,$74,$76,$79,$7B,$7D
	.dc.b	$80,$82,$84,$87,$8A,$8C,$8F,$91

WK:				* ﾜｰｸｴﾘｱ/ﾃｰﾌﾞﾙｱｸｾｽ用基準ﾎﾟｲﾝﾄ(A6)
ADPBFL:	.dc.b	$00		* 動作制御ﾌﾗｸﾞ
				*	ﾋﾞｯﾄ	機能
				*	7	DPCM→ADPCM変換ｵﾌｾｯﾄ初期化
				*	3	動作開始要求ﾌﾗｸﾞ
				*	2	ｵｰﾊﾞｰﾗﾝﾌﾗｸﾞ
				*	1	過負荷ﾌﾗｸﾞ
				*	0	DPCMﾃﾞｰﾀ有効ﾌﾗｸﾞ,出力中ﾌﾗｸﾞ(単音再生ﾓｰﾄﾞ)
ACTFLG:	.dc.b	0		* 動作ﾁｬﾝﾈﾙ数
DSPFLG:	.dc.b	0		* 動作状況表示ﾌﾗｸﾞ(trap #2 設定用)
ENDFLG:	.dc.b	0		* 割り込み処理中ﾌﾗｸﾞ
SKPFLG:	.dc.b	0		* 一時停止ﾌﾗｸﾞ
KEEPFL:	.dc.b	0		* 占有ﾌﾗｸﾞ
IOCHN:	.dc.b	PCMIOC		* IOCSﾁｬﾝﾈﾙ数
IOCHMX:	.dc.b	$FF		* 最大IOCSﾁｬﾝﾈﾙ数($FFなら最大ﾁｬﾝﾈﾙ数と同じ)
IOCHNW:	.dc.b	$FF		* IOCS動作ﾁｬﾝﾈﾙ番号($FFならﾁｬﾝﾈﾙ未定)
SYSFLG:	.dc.b	0		* ｼｽﾃﾑ状態ﾌﾗｸﾞ
				*	ﾋﾞｯﾄ	機能
				*	7	単音再生ﾓｰﾄﾞ(ﾋﾞｯﾄ6,5のOR)
				*	6	単音再生ﾓｰﾄﾞ(trap #2 設定)
				*	5	単音再生ﾓｰﾄﾞ(ｺﾏﾝﾄﾞﾗｲﾝ設定)
				*	4	IOCS単音ﾓｰﾄﾞ
				*	2	音量固定ﾓｰﾄﾞ(trap #2 設定)
				*	1	音量固定ﾓｰﾄﾞ(ｺﾏﾝﾄﾞﾗｲﾝ設定)
				*	0	ﾃﾞﾊﾞｲｽﾄﾞﾗｲﾊﾞﾓｰﾄﾞ
PANWK:	.dc.b	0		* 定位(0～3)
TRYWK:	.dc.b	0		* 過負荷ﾘﾄﾗｲｶｳﾝﾀ
M1MOD:	.dc.b	0		* 単音再生ﾓｰﾄﾞﾌﾗｸﾞ(0:ﾁｪｰﾝ無し,1:ｱﾚｲﾁｪｰﾝ,2:ﾘﾝｸｱﾚｲﾁｪｰﾝ)
IOFLG:	.dc.b	0		* IOCS一時停止ﾌﾗｸﾞ

*		ADPCM/PCMﾓｰﾄﾞﾁｪｯｸﾃｰﾌﾞﾙ $xx(a6,xn)でｱｸｾｽ
MODTBL:	.dc.b	$00,$01,$02,$03,$04,$84,$C4,$05
	.dc.b	$85,$C5,$06,$86,$C6,$FF,$FF,$FF
	.dc.b	$80,$81,$82,$83,$84,$85,$86,$FF
	.dc.b	$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	.dc.b	$C0,$C1,$C2,$C3,$C4,$C5,$C6,$FF
	.dc.b	$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	.dc.b	$00,$01,$02,$03,$04,$05,$06,$FF
	.dc.b	$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

	.even

VECTBL:	.dc.w	T2VECT		* ﾍﾞｸﾀ用ﾃｰﾌﾞﾙ(ﾍﾞｸﾀ番号)
	.dc.l	T2ENT,-2	* (処理先,前の値の保存用)
VECTB1:	.dc.w	T1VECT
	.dc.l	T1ENT,-2
	.dc.w	$006A
	.dc.l	INTEXE,-2
	.dc.w	$006B
	.dc.l	INTEXE,-2
	.dc.w	$0160
	.dc.l	IOCS60,-2
	.dc.w	$0161
	.dc.l	IOCS61,-2
	.dc.w	$0162
	.dc.l	IOCS62,-2
	.dc.w	$0163
	.dc.l	IOCS63,-2
	.dc.w	$0164
	.dc.l	IOCS64,-2
	.dc.w	$0165
	.dc.l	IOCS65,-2
	.dc.w	$0166
	.dc.l	IOCS66,-2
	.dc.w	$0167
	.dc.l	IOCS67,-2
	.dc.w	0
	.dc.l	TOPADR

*		各種ﾊﾞｯﾌｧのあるｱﾄﾞﾚｽ(実際のｱﾄﾞﾚｽとMALLOCで確保した先頭ｱﾄﾞﾚｽ)
WKADF1:	.dc.w	0		* PCMﾊﾞｯﾌｧ分離ﾌﾗｸﾞ
WKADR1:	.dc.l	-2,-2		*    〃   先頭ｱﾄﾞﾚｽ
WKADF2:	.dc.w	0		* ADPCMﾊﾞｯﾌｧ分離ﾌﾗｸﾞ
WKADR2:	.dc.l	-2,-2		*     〃    先頭ｱﾄﾞﾚｽ
WKADF3:	.dc.w	0		* ﾁｬﾝﾈﾙﾜｰｸ分離ﾌﾗｸﾞ
WKADR3:	.dc.l	-2,-2		*    〃   先頭ｱﾄﾞﾚｽ
WKADF4:	.dc.w	0		* PCM→ADPCM変換ﾃｰﾌﾞﾙ分離ﾌﾗｸﾞ
WKADR4:	.dc.l	-2,-2		*         〃         先頭ｱﾄﾞﾚｽ
WKADF5:	.dc.w	0		* ADPCM→PCM変換ﾃｰﾌﾞﾙ分離ﾌﾗｸﾞ
WKADR5:	.dc.l	-2,-2		*         〃         先頭ｱﾄﾞﾚｽ

*--------------------------------------------------------------------

	.dc.w	0,0,0			* 4ﾊﾞｲﾄ境界調整用			*;dummy

INTOP2:	move.b	#$01,PCMCNT
	sf	ADIOCS.w
	rte

INTOP1:	btst	#2,ADIOCS.w
	bne	INTOP2
	move.b	#PCMSP1,PCMDAT		* 終了
	rte

INTOPR:	move.b	DMACH3,DMACH3		* 多重割り込み対策
	bmi	INTOP1
	rte

DISPON:	move.w	#DCOL1,TXTPL0		* 動作状態表示ON
	bra	INTEXA

*	.dc.w	0			* 4ﾊﾞｲﾄ境界調整用			*;dummy

*	割り込み処理ｴﾝﾄﾘ	(ｴﾗｰ時と共通)

INTEXE:	ori.w	#$0700,sr
	tas	ENDFLG
	bne	INTOPR
	movem.l	d5-d7/a5-a6,-(sp)
	lea	WK(pc),a6
	lea	DMACH3,a5
	movep.w	MFPIMA-DMACH3(a5),d7	* 割り込みﾏｽｸ
	move.w	INTWK+2-WK(a6),d5
	and.w	d7,d5
	eor.w	d5,d7
	movep.w	d5,MFPIMA-DMACH3(a5)
	tst.b	(a5)
	move.w	sr,d6
	move.w	d6,d5
	and.w	INTWK2-WK(a6),d5
	move.w	d5,sr

	move.b	DSPFLG-WK(a6),-(sp)
	bmi	DISPON
INTEXA:
	move.w	d7,-(sp)
	movem.l	d0-d4/a0-a4,-(sp)
	movem.w	d5-d6,-(sp)

	cmpi.b	#PCM8FL,ADIOCS.w
	bne	IN0000
	tst.b	SYSFLG-WK(a6)
	bmi	IN0000

	move.w	d6,sr
	move.b	(a5),d0
	st	(a5)
	bmi	INTHLT
	cmpi.b	#$40,d0
	bcs	INT999
	moveq	#9,d0
	and.b	(a6),d0
	beq	INTCNT
INT001:	andi.b	#$F3,(a6)
	move.w	d5,sr

	tst.b	SKPFLG-WK(a6)		* 一時停止中ならｽｷｯﾌﾟ
	bne	INT991

INT010:	move.w	d6,sr
INT011:	lsl.w	PANFLG-WK(a6)		* 定位変更
	beq	INT013
	bpl	INT012
	lea	PPICTL,a0
	move.b	PANWK3-WK(a6),(a0)
	move.b	PANWK3+1-WK(a6),(a0)
INT012:	move.l	PANWK1-WK(a6),PANWK2-WK(a6)
INT013:

	lsl.w	PCMFLG-WK(a6)		* 処理ﾊﾞｲﾄ数変更
	beq	INT022
	move.w	PCMBN0-WK(a6),PCMBN1-WK(a6)
	move.w	PCMBL0-WK(a6),PCMBL1-WK(a6)
	move.l	PCMBR0-WK(a6),PCMBR1-WK(a6)
INT022:	move.w	d5,sr

	move.w	BFADR1-WK(a6),d4
	movea.l	ADPBF1-WK(a6,d4.w),a4
	move.w	PCMBR2-WK(a6),d3
	movea.l	ADPBFX-WK(a6),a3
	movea.l	a3,a0

	move.w	d6,sr
INT030:	btst	#3,(a5)
	beq	INT033
	btst	#0,(a6)
	bne	INT031
	tas	(a6)
	bra	INT032
INT031:	movea.l	a4,a0
INT032:	move.l	a0,$1C(a5)		* DMA転送ｱﾄﾞﾚｽｾｯﾄ
	move.w	d3,$1A(a5)
	st	(a5)
	move.b	#$48,7(a5)
	btst	#6,7(a5)
	bne	INT035
	move.w	d5,sr

	movea.l	a3,a0

	move.w	d6,sr
INT033:	tas	(a6)
	move.b	#$10,7(a5)		* 継続起動
	st	(a5)
	move.w	d3,$A(a5)
	move.l	a3,$C(a5)
	btst	#0,(a6)
	beq	INT034
	movea.l	a4,a0
INT034:	move.w	d3,$1A(a5)
	move.l	a0,$1C(a5)
	move.b	#$C8,7(a5)
INT035:
	and.w	INTWK-WK(a6),d6		* 割り込み許可
	move.w	d6,sr

	eori.w	#4,d4
	move.w	d4,BFADR1-WK(a6)

	bclr	#0,(a6)
	beq	INT062
INT040:	bclr	#7,(a6)
	beq	INT041
	moveq	#0,d0			* 出力ｵﾌｾｯﾄ初期化
	moveq	#0,d1
	movem.l	d0-d1,OUTOF1-WK(a6)
	move.l	TBLAD2-WK(a6),PCMTBL-WK(a6)
INT041:	move.w	PCMOFS-WK(a6),d0	* DPCM→ADPCM変換
	movea.l	a4,a0
	movea.l	DPCMBF-WK(a6),a1
	movem.l	PCMTBL-WK(a6),a2-a3
	moveq	#0,d2
	moveq	#3,d1
	and.w	d3,d1
	add.w	d1,d1
	lsr.w	#2,d3
	move.w	INT0A0(pc,d1.w),d1
	jmp	INT0A0(pc,d1.w)
INT0A0:	.dc.w	INT0A5-INT0A0,INT0A4-INT0A0,INT0A3-INT0A0,INT0A2-INT0A0
INT0A1:	PCM2AD
INT0A2:	PCM2AD
INT0A3:	PCM2AD
INT0A4:	PCM2AD
INT0A5:	dbra	d3,INT0A1
	move.w	d0,PCMOFS-WK(a6)
	move.l	a2,PCMTBL-WK(a6)
INT050:	cmpi.b	#4,MPUFLG.w		* ｷｬｯｼｭ制御
	bcs	INT060
INT051:	moveq	#CACHEL-1,d0		* 68040以降ならｷｬｯｼｭの内容を書き戻す
	add.w	PCMBR2-WK(a6),d0
	lsr.w	#CACHES,d0
INT052:	.dc.w	$F46C			* cpushl dc,(a4)
	lea	CACHEL(a4),a4
	dbra	d0,INT052
INT060:	btst	#6,7(a5)		* 既に予約が消えていれば,もう一度同じﾃﾞｰﾀを出力
	beq	INT112
INT062:

	tst.b	3*2+10*4(sp)
	bmi	DISP81
INTEXC:

	movea.l	CHNWK(pc),a6		* ADPCM→DPCM変換合成+PCM合成
	bsr	PCMCNV
	lea	DMACH3,a5
	move.b	d6,ACTFLG-WK(a6)
	beq	INT120
INT112:	bset	#0,(a6)
INT120:

	ori.w	#$0700,sr		* 割り込み終了処理

	btst	#0,(a6)
	beq	INT999
	btst	#6,7(a5)
	bne	INT999
	movem.w	(sp),d5-d6		* 過負荷時
	addq.b	#1,TRYWK-WK(a6)
	cmpi.b	#TRYNUM,TRYWK-WK(a6)
	bls	INT011
	ori.b	#$A,(a6)
	move.b	(a5),(a5)
	bpl	INT999
	move.b	#PCMSP2,PCMDAT

INT999:	move.w	(sp)+,sr
	move.w	(sp)+,d6
	movem.l	(sp)+,d0-d4/a0-a4
	move.w	(sp)+,d7
	sf	TRYWK-WK(a6)
	sf	ENDFLG-WK(a6)
	lea	MFPIMA,a5
	move.w	d6,sr
	movep.w	0(a5),d6
	or.w	d7,d6
	movep.w	d6,0(a5)
	tst.b	(sp)+
	movem.l	(sp)+,d5-d7/a5-a6
	bmi	DISPOF
	rte

INT991:	st	(a5)
	bra	INT999

DISP81:	move.w	#DCOL2,TXTPL0		* 動作状態表示色変更
	bra	INTEXC

DISPOF:	move.w	#DCOL0,TXTPL0		* 動作状態表示OFF
	rte

INTCNT:	st	(a5)			* 終了時1回ｵｰﾊﾞｰﾗﾝ
	bclr	#2,(a6)
	bne	INT999
	ori.b	#$84,(a6)
	move.w	PCMBR2-WK(a6),$1A(a5)
	move.l	ADPBFX-WK(a6),$1C(a5)
	move.b	#$48,7(a5)
	bra	INT999

INTHLT:	btst	#2,ADIOCS.w
	bne	INTHL2
	tst.b	SKPFLG-WK(a6)		* 終了処理
	bne	INTHL1
	bclr	#3,(a6)
	bne	INT001
	btst	#0,(a6)
	bne	INT001
INTHL1:	st	(a5)
	move.b	#PCMSP1,PCMDAT
	bra	INT999

INTHL2:	st	(a5)
	move.b	#$01,PCMCNT
	sf	ADIOCS.w
	bra	INT999

IN0000:	move.w	d6,sr			* 単音再生ﾓｰﾄﾞ
	move.b	(a5),d0
	st	(a5)
	bmi	IN0002
	cmpi.b	#$40,d0
	bcs	IN0003
	tst.b	M1MOD-WK(a6)
	bne	IN0003
	move.l	M1LEN-WK(a6),d0		* 通常
	beq	INT999
	move.l	#$FFF0,d1
	cmp.l	d1,d0
	bcc	IN0001
	move.l	d0,d1
IN0001:	sub.l	d1,d0
	move.l	d0,M1LEN-WK(a6)
	movea.l	M1ADR-WK(a6),a0
	move.l	a0,$1C(a5)
	move.w	d1,$1A(a5)
	move.b	#$48,7(a5)
	add.l	a0,d1
	move.l	d1,M1ADR-WK(a6)
	bra	INT999

IN0002:	cmpi.b	#1,M1MOD-WK(a6)		* 終了
	bcc	IN0010
IN0003:	btst	#2,ADIOCS.w
	bne	IN0004
	bclr	#0,(a6)
	move.b	#PCMSP1,PCMDAT
	sf	ADIOCS.w
	bra	INT999

IN0004:	move.b	#$01,PCMCNT
	sf	ADIOCS.w
	bra	INT999

IN0010:	sf	M1MOD-WK(a6)
	bne	IN0011
	move.w	M1LEN+2-WK(a6),$1A(a5)	* ｱﾚｲﾁｪｰﾝ
	move.w	#$3A88,d0
	bra	IN0012

IN0011:	move.w	#$3E88,d0		* ﾘﾝｸｱﾚｲﾁｪｰﾝ
IN0012:	move.l	M1ADR-WK(a6),$1C(a5)
	movep.w	d0,5(a5)
	move.b	#$02,PCMCNT
	bra	INT999

PCMBCL:	movem.l	d0/d3/a1,-(sp)		* PCMﾊﾞｯﾌｧ初期化
	moveq	#0,d0
	dbra	d3,PCMBC1
	bra	PCMBC2
PCMBC1:	move.l	d0,(a1)+
	dbra	d3,PCMBC1
PCMBC2:	movem.l	(sp)+,d0/d3/a1
	rts

PCMCLR:	movem.l	d7/a6,-(sp)		* 過負荷時の処理
	moveq	#-1,d1
PCMCL1:	move.w	(a6),d0
	bmi	PCMCL2
	cmp.b	d0,d1			* 音量が最小のﾁｬﾝﾈﾙを選択
	bcs	PCMCL2
	move.b	d0,d1
	movea.l	a6,a0
PCMCL2:	lea	CHNSIZ(a6),a6
	dbra	d7,PCMCL1
	movem.l	(sp)+,d7/a6
	addq.b	#1,d1
	bcs	PCMCLA
	tas	(a0)			* 1ﾁｬﾝﾈﾙ停止
	bra	PCMCLX
PCMCLA:	tas	(a6)			* 全ﾁｬﾝﾈﾙ停止
	lea	CHNSIZ(a6),a6
	dbra	d7,PCMCLA
PCMCLX:	lea	WK(pc),a6
	bset	#0,(a6)			* 変換が完了したことにする
	rts

* IN	A6.L	動作ﾃｰﾌﾞﾙ先頭ｱﾄﾞﾚｽ (このﾙｰﾁﾝではこの定義になる)
* OUT	A6.L	WK を指している (本来の定義に戻している)
*	D6.W	動作ﾁｬﾝﾈﾙ数
*
PCMCNV:	moveq	#0,d7			* ADPCM → DPCM変換+合成
	move.w	PCMCHN(pc),d7
	subq.w	#1,d7
	moveq	#0,d6
	bclr	#1,ADPBFL		* 過負荷
	bne	PCMCLA			* PCMCLRにするとしつこく(笑)なる
PCMCN1:	swap	d7
	move.b	#$83,d7
	move.w	sr,d6
	ori.w	#$0700,sr		* 多重割り込み対策
	and.b	(a6),d7			* ﾁｬﾝﾈﾙの動作状態ﾁｪｯｸ
	bmi	PCMC0F
	bne	PCMC1
	andi.b	#$1F,(a6)		* 通常ﾓｰﾄﾞ
	movem.l	4(a6),d0-d5/a0-a4
	move.b	$55(a6),d7
	move.w	d6,sr
	addi.w	#$100,d7
	move.l	d3,d6
	moveq	#0,d3
	move.w	PCMBL1(pc),d3
	btst	d2,d7
	bne	PCMC00
	adda.w	-2(a4),a4
	cmpi.b	#$1F,d2
	bne	PCMC00
	bsr	PCMBCL
PCMC00:	swap	d2
	movem.l	d2/d6/d7/a6,-(sp)
	movea.l	a3,a6
	bra	PCMC02
PCMC01:	movem.l	d2/a5,(sp)
PCMC02:	move.l	a6,d2
	sub.l	a0,d2
	bls	PCMC03
	moveq	#0,d6
	lea	PCMC03(pc),a5
	jmp	(a4)
PCMC03:	tst.w	d3
	ble	PCMC07
PCMC04:	movem.l	(sp),d2/a5
	tst.w	d2
	ble	PCMC07
	tst.l	d2
	bmi	PCMC05
	movea.l	a6,a0
	movea.l	(a5)+,a6
	dbra	d2,PCMC01
	bra	PCMC06
PCMC05:	movea.l	a6,a0
	move.l	(a5)+,d6
	btst	#0,d6
	bne	PCMC06
	movea.l	d6,a6
	dbra	d2,PCMC01
PCMC06:	movem.l	d2/a5,(sp)
PCMC07:	tst.w	d3
	sgt	d5
	movea.l	a6,a3
	move.b	d7,$B(sp)
	movem.l	(sp)+,d2/d6/d7/a6
PCMC0X:	movea.l	d6,a2			* 後処理
	swap	d2
	bset	d2,d7
	bne	PCMC0E
	tst.w	d3
	ble	PCMC0E
	adda.w	-2(a4),a4
	lea	PCMC0E(pc),a5
	moveq	#0,d6
	jmp	(a4)
PCMC0E:	move.l	a2,d3
	andi.b	#$80,d5
	move.w	sr,d6
	ori.w	#$0700,sr
	btst	#6,(a6)
	bne	PCMC0F
	or.b	d5,(a6)
	movem.l	d0-d4,4(a6)
	move.l	a0,$1C(a6)
	move.l	a3,$28(a6)
	move.b	d7,$55(a6)
PCMC0F:	move.w	d6,sr
	lea	CHNSIZ(a6),a6
	swap	d7
	subq.b	#1,d7
	bcc	PCMCN1
	lea	WK(pc),a6
	tst.w	d7			* 8/16ﾋﾞｯﾄPCMの処理があったか?
	bmi	PCMC4			* あった場合DPCM変換を行う
	swap	d7
	moveq	#0,d6
	move.w	d7,-(sp)
	move.b	(sp)+,d6		* 動作ﾁｬﾝﾈﾙ数を返す
	rts

PCMC1:	cmpi.b	#2,d7
	beq	PCMC2
	bhi	PCMC3
	andi.b	#$1F,(a6)		* ｱﾚｲﾁｪｰﾝﾓｰﾄﾞ
	movem.l	4(a6),d0-d5/a0-a4
	move.b	$55(a6),d7
	move.w	d6,sr
	addi.w	#$100,d7
	move.l	d3,d6
	moveq	#0,d3
	move.w	PCMBL1(pc),d3
	btst	d2,d7
	bne	PCMC10
	adda.w	-2(a4),a4
	cmpi.b	#$1F,d2
	bne	PCMC10
	bsr	PCMBCL
PCMC10:	swap	d2
	movem.l	d2/d6/d7/a6,-(sp)
	movea.l	a3,a6
	bra	PCMC12
PCMC11:	movem.l	d2/a5,(sp)
PCMC12:	move.l	a6,d2
	sub.l	a0,d2
	bls	PCMC13
	moveq	#0,d6
	lea	PCMC13(pc),a5
	jmp	(a4)
PCMC13:	tst.w	d3
	ble	PCMC17
PCMC14:	movem.l	(sp),d2/a5
	tst.w	d2
	beq	PCMC17
	tst.l	d2
	bmi	PCMC15
	movea.l	(a5)+,a0
	movea.l	a0,a6
	moveq	#0,d6
	move.w	(a5)+,d6
	adda.l	d6,a6
	dbra	d2,PCMC11
	bra	PCMC16
PCMC15:	move.l	(a5)+,d6
	btst	#0,d6
	bne	PCMC16
	movea.l	d6,a0
	movea.l	d6,a6
	moveq	#0,d6
	move.w	(a5)+,d6
	btst	#0,d6
	bne	PCMC16
	adda.l	d6,a6
	dbra	d2,PCMC11
PCMC16:	movem.l	d2/a5,(sp)
PCMC17:	tst.w	d3
	sgt	d5
	movea.l	a6,a3
	move.b	d7,$B(sp)
	movem.l	(sp)+,d2/d6/d7/a6
	bra	PCMC0X

PCMC2:	andi.b	#$1F,(a6)		* ﾘﾝｸｱﾚｲﾁｪｰﾝﾓｰﾄﾞ
	movem.l	4(a6),d0-d5/a0-a4
	move.b	$55(a6),d7
	move.w	d6,sr
	addi.w	#$100,d7
	move.l	d3,d6
	moveq	#0,d3
	move.w	PCMBL1(pc),d3
	btst	d2,d7
	bne	PCMC20
	adda.w	-2(a4),a4
	cmpi.b	#$1F,d2
	bne	PCMC20
	bsr	PCMBCL
PCMC20:	swap	d2
	movem.l	d2/d6/d7/a6,-(sp)
	movea.l	a3,a6
	bra	PCMC22
PCMC21:	movem.l	d2/a5,(sp)
PCMC22:	move.l	a6,d2
	sub.l	a0,d2
	bls	PCMC23
	moveq	#0,d6
	lea	PCMC23(pc),a5
	jmp	(a4)
PCMC23:	tst.w	d3
	ble	PCMC27
PCMC24:	movem.l	(sp),d2/a5
	tst.w	d2
	bmi	PCMC27
	move.l	(a5)+,d6
	beq	PCMC26
	btst	#0,d6
	bne	PCMC26
	movea.l	d6,a5
	tst.l	d2
	bmi	PCMC25
	movea.l	(a5)+,a0
	movea.l	a0,a6
	moveq	#0,d6
	move.w	(a5)+,d6
	adda.l	d6,a6
	bra	PCMC21
PCMC25:	move.l	(a5)+,d6
	btst	#0,d6
	bne	PCMC26
	movea.l	d6,a0
	movea.l	d6,a6
	moveq	#0,d6
	move.w	(a5)+,d6
	btst	#0,d6
	bne	PCMC26
	adda.l	d6,a6
	bra	PCMC21
PCMC26:	move.w	#$FFFF,d2
	movem.l	d2/a5,(sp)
PCMC27:	tst.w	d3
	sgt	d5
	movea.l	a6,a3
	move.b	d7,$B(sp)
	movem.l	(sp)+,d2/d6/d7/a6
	bra	PCMC0X

PCMC3:	andi.b	#$1F,(a6)		* MPCMﾓｰﾄﾞ
	movem.l	4(a6),d0-d5/a0-a4
	move.b	$55(a6),d7
	move.w	d6,sr
	addi.w	#$100,d7
	move.l	d3,d6
	moveq	#0,d3
	move.w	PCMBL1(pc),d3
	btst	d2,d7
	bne	PCMC30
	adda.w	-2(a4),a4
	cmpi.b	#$1F,d2
	bne	PCMC30
	bsr	PCMBCL
PCMC30:	swap	d2
	movem.l	d2/d6/d7/a6,-(sp)
	movea.l	a3,a6
	bra	PCMC32
PCMC31:	movem.l	d2/a5,(sp)
PCMC32:	move.l	a6,d2
	sub.l	a0,d2
	bls	PCMC33
	moveq	#0,d6
	lea	PCMC33(pc),a5
	jmp	(a4)
PCMC33:	tst.w	d3
	ble	PCMC39
PCMC34:	movem.l	(sp),d2/a5
	tst.w	d2
	ble	PCMC39
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	cmpi.w	#2,d2
	bne	PCMC35
	move.l	8(a5),d6		* LOOP TOP情報
	bne	PCMC38
	move.l	d0,8(a5)		* ADPCMﾃｰﾌﾞﾙ情報の保存
	bra	PCMC38
PCMC35:	cmpi.w	#1,d2
	bne	PCMC38
	move.l	8(a5),d6		* LOOP END情報
	bne	PCMC36
	move.l	d0,8(a5)		* ADPCMﾃｰﾌﾞﾙ情報の保存
PCMC36:	move.l	$C(a5),d6		* LOOP回数ﾁｪｯｸ
	beq	PCMC37
	move.l	$10(a5),d6		* LOOPｶｳﾝﾀﾁｪｯｸ
	beq	PCMC38
	subq.l	#1,d6
	move.l	d6,$10(a5)
PCMC37:	movea.l	-8(a5),a0		* 繰り返し
	move.l	4(a5),d0
	move.w	(sp)+,sr
	bra	PCMC31
PCMC38:	movea.l	a6,a0			* 次のﾌﾞﾛｯｸ
	move.l	(a5)+,a6
	move.w	(sp)+,sr
	dbra	d2,PCMC31
	movem.l	d2/a5,(sp)
PCMC39:	tst.w	d3
	sgt	d5
	movea.l	a6,a3
	move.b	d7,$B(sp)
	movem.l	(sp)+,d2/d6/d7/a6
	bra	PCMC0X

PCMC4:	movea.l	DPCMBF-WK(a6),a5	* 8/16ﾋﾞｯﾄPCMの合成
	move.w	PCMBL1-WK(a6),d6
PCMC40:	moveq	#3,d4
	and.w	d6,d4
	add.w	d4,d4
	lsr.w	#2,d6
	btst	#14,d7			* DPCMﾊﾞｯﾌｧにﾃﾞｰﾀがあるか?
	bne	PCMC421
	movea.l	a5,a1
	movea.l	PCMBU1-WK(a6),a0
	move.w	OUTOF1-WK(a6),d0
	move.w	d6,d5
	move.w	PCMC410(pc,d4.w),d1
	jmp	PCMC410(pc,d1.w)
PCMC410:
	.dc.w	PCMC415-PCMC410,PCMC414-PCMC410,PCMC413-PCMC410,PCMC412-PCMC410
PCMC411:
	move.w	(a0)+,d1
	sub.w	d1,d0
	move.w	d0,(a1)+
	move.w	(a0)+,d0
	sub.w	d0,d1
	move.w	d1,(a1)+
PCMC412:
	move.w	(a0)+,d1
	sub.w	d1,d0
	move.w	d0,(a1)+
	move.w	(a0)+,d0
	sub.w	d0,d1
	move.w	d1,(a1)+
PCMC413:
	move.w	(a0)+,d1
	sub.w	d1,d0
	move.w	d0,(a1)+
	move.w	(a0)+,d0
	sub.w	d0,d1
	move.w	d1,(a1)+
PCMC414:
	move.w	(a0)+,d1
	sub.w	d1,d0
	move.w	d0,(a1)+
	move.w	(a0)+,d0
	sub.w	d0,d1
	move.w	d1,(a1)+
PCMC415:
	dbra	d5,PCMC411
	bra	PCMC441

PCMC421:				* 前のﾃﾞｰﾀに加算する場合の処理
	movea.l	a5,a1
	movea.l	PCMBU1-WK(a6),a0
	move.w	OUTOF1-WK(a6),d0
	move.w	d6,d5
	move.w	PCMC430(pc,d4.w),d1
	jmp	PCMC430(pc,d1.w)
PCMC430:
	.dc.w	PCMC435-PCMC430,PCMC434-PCMC430,PCMC433-PCMC430,PCMC432-PCMC430
PCMC431:
	move.w	(a0)+,d1
	sub.w	d1,d0
	add.w	d0,(a1)+
	move.w	(a0)+,d0
	sub.w	d0,d1
	add.w	d1,(a1)+
PCMC432:
	move.w	(a0)+,d1
	sub.w	d1,d0
	add.w	d0,(a1)+
	move.w	(a0)+,d0
	sub.w	d0,d1
	add.w	d1,(a1)+
PCMC433:
	move.w	(a0)+,d1
	sub.w	d1,d0
	add.w	d0,(a1)+
	move.w	(a0)+,d0
	sub.w	d0,d1
	add.w	d1,(a1)+
PCMC434:
	move.w	(a0)+,d1
	sub.w	d1,d0
	add.w	d0,(a1)+
	move.w	(a0)+,d0
	sub.w	d0,d1
	add.w	d1,(a1)+
PCMC435:
	dbra	d5,PCMC431
PCMC441:
	move.w	d0,OUTOF1-WK(a6)
PCMC4X:	swap	d7
	move.w	d7,-(sp)
	moveq	#0,d6
	move.b	(sp)+,d6
	rts

	.dc.w	AD01-AD00
AD00:	add.w	d3,d3			* ADPCM 1倍～2倍
	cmp.l	d3,d2
	bcs	AD02
	lsr.w	#2,d3
	tst.b	d7
	bmi	AD002
	dbra	d3,AD0000
	jmp	(a5)
AD0000:	add.w	d5,d4
	bcs	AD0011
AD0001:	APA0
	add.w	d5,d4
	bcs	AD0032
AD0002:	add.w	d1,(a1)+
	add.w	d5,d4
	bcs	AD0013
AD0003:	APA0
	add.w	d5,d4
	bcs	AD0034
AD0004:	add.w	d1,(a1)+
	dbra	d3,AD0000
	sf	d7
	jmp	(a5)
AD0011:	AP10
	add.w	d5,d4
	bcc	AD0022
AD0012:	AP10
	add.w	d5,d4
	bcc	AD0003
AD0013:	AP10
	add.w	d5,d4
	bcc	AD0024
AD0014:	AP10
	dbra	d3,AD0000
	sf	d7
	jmp	(a5)
AD002:	dbra	d3,AD0020
	jmp	(a5)
AD0020:	add.w	d5,d4
	bcs	AD0031
AD0021:	add.w	d1,(a1)+
	add.w	d5,d4
	bcs	AD0012
AD0022:	APA0
	add.w	d5,d4
	bcs	AD0033
AD0023:	add.w	d1,(a1)+
	add.w	d5,d4
	bcs	AD0014
AD0024:	APA0
	dbra	d3,AD0020
	st	d7
	jmp	(a5)
AD0031:	AP12
	add.w	d5,d4
	bcc	AD0002
AD0032:	AP12
	add.w	d5,d4
	bcc	AD0023
AD0033:	AP12
	add.w	d5,d4
	bcc	AD0004
AD0034:	AP12
	dbra	d3,AD0020
	st	d7
	jmp	(a5)

	.dc.w	AD0X-AD01
AD01:	add.w	d3,d3
	cmp.l	d3,d2
	bcs	AD03
	lsr.w	#2,d3
	tst.b	d7
	bmi	AD012
	dbra	d3,AD0100
	jmp	(a5)
AD0100:	add.w	d5,d4
	bcs	AD0111
AD0101:	APA1
	add.w	d5,d4
	bcs	AD0132
AD0102:	move.w	d1,(a1)+
	add.w	d5,d4
	bcs	AD0113
AD0103:	APA1
	add.w	d5,d4
	bcs	AD0134
AD0104:	move.w	d1,(a1)+
	dbra	d3,AD0100
	sf	d7
	jmp	(a5)
AD0111:	AP11
	add.w	d5,d4
	bcc	AD0122
AD0112:	AP11
	add.w	d5,d4
	bcc	AD0103
AD0113:	AP11
	add.w	d5,d4
	bcc	AD0124
AD0114:	AP11
	dbra	d3,AD0100
	sf	d7
	jmp	(a5)
AD012:	dbra	d3,AD0120
	jmp	(a5)
AD0120:	add.w	d5,d4
	bcs	AD0131
AD0121:	move.w	d1,(a1)+
	add.w	d5,d4
	bcs	AD0112
AD0122:	APA1
	add.w	d5,d4
	bcs	AD0133
AD0123:	move.w	d1,(a1)+
	add.w	d5,d4
	bcs	AD0114
AD0124:	APA1
	dbra	d3,AD0120
	st	d7
	jmp	(a5)
AD0131:	AP13
	add.w	d5,d4
	bcc	AD0102
AD0132:	AP13
	add.w	d5,d4
	bcc	AD0123
AD0133:	AP13
	add.w	d5,d4
	bcc	AD0104
AD0134:	AP13
	dbra	d3,AD0120
	st	d7
	jmp	(a5)

AD02:	tst.b	d7
	bmi	AD021
	dbra	d3,AD0201
	jmp	(a5)
AD0201:	subq.l	#1,d2
	bcs	AD0202
	add.w	d5,d4
	bcc	AD0208
	AP10
	dbra	d3,AD0201
	sf	d7
	jmp	(a5)
AD0202:	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	AD0206
	lea	AD0205(pc),a4
	sf	d7
AD0203:	jmp	(a5)
	.dc.w	AD0203-AD0205
AD0205:	subq.l	#1,d2
	bcs	AD0203
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	add.w	d5,d4
	bcc	AD0208
	AP10
	dbra	d3,AD0201
	sf	d7
	jmp	(a5)
AD0206:	lea	AD0207(pc),a4
	addq.l	#2,a1
	sf	d7
	jmp	(a5)
	.dc.w	AD0203-AD0207
AD0207:	subq.l	#1,d2
	bcs	AD0203
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	add.w	d5,d4
	bcc	AD0208
	AP10
	dbra	d3,AD0201
	sf	d7
	jmp	(a5)
AD0208:	APA0
	dbra	d3,AD0211
	st	d7
	jmp	(a5)
AD021:	dbra	d3,AD0211
	jmp	(a5)
AD0211:	add.w	d5,d4
	bcc	AD0218
	subq.l	#1,d2
	bcs	AD0212
	AP12
	dbra	d3,AD0211
	st	d7
	jmp	(a5)
AD0212:	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	AD0216
	lea	AD0215(pc),a4
	st	d7
AD0213:	jmp	(a5)
	.dc.w	AD0213-AD0215
AD0215:	subq.l	#1,d2
	bcs	AD0213
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0)+,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	d0,a3
	add.w	(a3,a2.l),d1
	add.w	d1,(a1)+
	move.w	2(a3,a2.l),d1
	move.l	(a3),d0
	dbra	d3,AD0211
	st	d7
	jmp	(a5)
AD0216:	lea	AD0217(pc),a4
	add.w	d1,(a1)+
	sf	d7
	jmp	(a5)
	.dc.w	AD0213-AD0217
AD0217:	subq.l	#1,d2
	bcs	AD0213
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0)+,d0
	add.w	d0,d0
	add.w	d0,d0
	movea.l	d0,a3
	move.w	(a3,a2.l),d1
	add.w	d1,(a1)+
	move.w	2(a3,a2.l),d1
	move.l	(a3),d0
	dbra	d3,AD0211
	st	d7
	jmp	(a5)
AD0218:	add.w	d1,(a1)+
	dbra	d3,AD0201
	sf	d7
	jmp	(a5)

AD03:	tst.b	d7
	bmi	AD031
	dbra	d3,AD0301
	jmp	(a5)
AD0301:	subq.l	#1,d2
	bcs	AD0302
	add.w	d5,d4
	bcc	AD0308
	AP11
	dbra	d3,AD0301
	sf	d7
	jmp	(a5)
AD0302:	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	AD0306
	lea	AD0305(pc),a4
	sf	d7
AD0303:	jmp	(a5)
	.dc.w	AD0X-AD0305
AD0305:	subq.l	#1,d2
	bcs	AD0303
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	add.w	d5,d4
	bcc	AD0308
	AP11
	dbra	d3,AD0301
	sf	d7
	jmp	(a5)
AD0306:	lea	AD0307(pc),a4
	move.w	d6,(a1)+
	sf	d7
	jmp	(a5)
	.dc.w	AD0X-AD0307
AD0307:	subq.l	#1,d2
	bcs	AD0303
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	add.w	d5,d4
	bcc	AD0308
	AP11
	dbra	d3,AD0301
	sf	d7
	jmp	(a5)
AD0308:	APA1
	dbra	d3,AD0311
	st	d7
	jmp	(a5)
AD031:	dbra	d3,AD0311
	jmp	(a5)
AD0311:	add.w	d5,d4
	bcc	AD0318
	subq.l	#1,d2
	bcs	AD0312
	AP13
	dbra	d3,AD0311
	st	d7
	jmp	(a5)
AD0312:	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	AD0316
	lea	AD0315(pc),a4
	st	d7
AD0313:	jmp	(a5)
	.dc.w	AD0X-AD0315
AD0315:	subq.l	#1,d2
	bcs	AD0313
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	AP13
	dbra	d3,AD0311
	st	d7
	jmp	(a5)
AD0316:	lea	AD0317(pc),a4
	move.w	d1,(a1)+
	sf	d7
	jmp	(a5)
	.dc.w	AD0X-AD0317
AD0317:	subq.l	#1,d2
	bcs	AD0313
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	AP13
	dbra	d3,AD0311
	st	d7
	jmp	(a5)
AD0318:	move.w	d1,(a1)+
	dbra	d3,AD0301
	sf	d7
	jmp	(a5)

AD0X1:	move.l	d6,(a1)+
AD0X:	dbra	d3,AD0X1
	jmp	(a5)

	.dc.w	AD11-AD10
AD10:	sf	d7			* ADPCM 2倍～4倍
	lsl.w	#2,d3
	lsr.l	#1,d5
	cmp.l	d3,d2
	bcs	AD12
	moveq	#$4,d2
	and.w	d3,d2
	lsr.w	#3,d3
	move.w	AD1000+2(pc,d2.w),d2
	jmp	AD1000(pc,d2.w)
AD1000:	.dc.l	AD1008-AD1000,AD1004-AD1000
AD1001:	add.w	d5,d4
	bcs	AD1011
	AP10
AD1002:	add.w	d5,d4
	bcs	AD1012
AD1003:	AP10
AD1004:	add.w	d5,d4
	bcs	AD1013
AD1005:	AP10
AD1006:	add.w	d5,d4
	bcs	AD1014
AD1007:	AP10
AD1008:	dbra	d3,AD1001
	jmp	(a5)
AD1011:	AP20
	AP22
	add.w	d5,d4
	bcc	AD1003
AD1012:	AP20
	AP22
	add.w	d5,d4
	bcc	AD1005
AD1013:	AP20
	AP22
	add.w	d5,d4
	bcc	AD1007
AD1014:	AP20
	AP22
	dbra	d3,AD1001
	jmp	(a5)

	.dc.w	AD0X-AD11
AD11:	sf	d7
	lsl.w	#2,d3
	lsr.l	#1,d5
	cmp.l	d3,d2
	bcs	AD13
	moveq	#$4,d2
	and.w	d3,d2
	lsr.w	#3,d3
	move.w	AD1100+2(pc,d2.w),d2
	jmp	AD1100(pc,d2.w)
AD1100:	.dc.l	AD1108-AD1100,AD1104-AD1100
AD1101:	add.w	d5,d4
	bcs	AD1111
	AP11
AD1102:	add.w	d5,d4
	bcs	AD1112
AD1103:	AP11
AD1104:	add.w	d5,d4
	bcs	AD1113
AD1105:	AP11
AD1106:	add.w	d5,d4
	bcs	AD1114
AD1107:	AP11
AD1108:	dbra	d3,AD1101
	jmp	(a5)
AD1111:	AP20
	AP23
	add.w	d5,d4
	bcc	AD1103
AD1112:	AP20
	AP23
	add.w	d5,d4
	bcc	AD1105
AD1113:	AP20
	AP23
	add.w	d5,d4
	bcc	AD1107
AD1114:	AP20
	AP23
	dbra	d3,AD1101
	jmp	(a5)

AD12:	lsr.w	#1,d3
	dbra	d3,AD1201
	jmp	(a5)
AD1201:	subq.l	#1,d2
	bcs	AD1202
	add.w	d5,d4
	bcs	AD1211
	AP10
	dbra	d3,AD1201
	jmp	(a5)
AD1202:	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	AD1206
	lea	AD1205(pc),a4
AD1203:	jmp	(a5)
	.dc.w	AD1203-AD1205
AD1205:	subq.l	#1,d2
	bcs	AD1203
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	add.w	d5,d4
	bcs	AD1211
	AP10
	dbra	d3,AD1201
	jmp	(a5)
AD1206:	lea	AD1207(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	AD1203-AD1207
AD1207:	subq.l	#1,d2
	bcs	AD1203
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	add.w	d5,d4
	bcs	AD1211
	AP10
	dbra	d3,AD1201
	jmp	(a5)
AD1211:	AP20
	subq.l	#1,d2
	bcs	AD1212
	AP22
	dbra	d3,AD1201
	jmp	(a5)
AD1212:	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	AD1216
	lea	AD1215(pc),a4
AD1213:	jmp	(a5)
	.dc.w	AD1213-AD1215
AD1215:	subq.l	#1,d2
	bcs	AD1213
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	AP22
	dbra	d3,AD1201
	jmp	(a5)
AD1216:	lea	AD1217(pc),a4
	add.w	d1,(a1)+
	jmp	(a5)
	.dc.w	AD1213-AD1217
AD1217:	subq.l	#1,d2
	bcs	AD1213
	movea.l	a3,a4
	add.w	d3,d3
	AP20
	add.w	d1,-2(a1)
	dbra	d3,AD1201
	jmp	(a5)

AD13:	lsr.w	#1,d3
	dbra	d3,AD1301
	jmp	(a5)
AD1301:	subq.l	#1,d2
	bcs	AD1302
	add.w	d5,d4
	bcs	AD1311
	AP11
	dbra	d3,AD1301
	jmp	(a5)
AD1302:	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	AD1306
	lea	AD1305(pc),a4
AD1303:	jmp	(a5)
	.dc.w	AD1X-AD1305
AD1305:	subq.l	#1,d2
	bcs	AD1303
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	add.w	d5,d4
	bcs	AD1311
	AP11
	dbra	d3,AD1301
	jmp	(a5)
AD1306:	lea	AD1307(pc),a4
	move.w	d6,(a1)+
	jmp	(a5)
	.dc.w	AD1X-AD1307
AD1307:	subq.l	#1,d2
	bcs	AD1303
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	add.w	d5,d4
	bcs	AD1311
	AP11
	dbra	d3,AD1301
	jmp	(a5)
AD1311:	AP20
	subq.l	#1,d2
	bcs	AD1312
	AP23
	dbra	d3,AD1301
	jmp	(a5)
AD1312:	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	AD1316
	lea	AD1315(pc),a4
AD1313:	jmp	(a5)
	.dc.w	AD1X-AD1315
AD1315:	subq.l	#1,d2
	bcs	AD1313
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	AP23
	dbra	d3,AD1301
	jmp	(a5)
AD1316:	lea	AD1317(pc),a4
	move.w	d1,(a1)+
	jmp	(a5)
	.dc.w	AD1X-AD1317
AD1317:	subq.l	#1,d2
	bcs	AD1313
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	AP23
	dbra	d3,AD1301
	jmp	(a5)

AD1X1:	move.l	d6,(a1)+
AD1X:	dbra	d3,AD1X1
	jmp	(a5)

	.dc.w	AD21-AD20
AD20:	sf	d7			* ADPCM 4倍以上
	add.w	d3,d3
	swap	d4
	clr.w	d4
	lsr.l	#1,d5
	swap	d5
	dbra	d3,AD2001
	swap	d4
	jmp	(a5)
AD2001:	add.l	d5,d4
	addx.w	d6,d4
	sub.w	d4,d2
	bcs	AD2005
AD2002:	subq.w	#2,d4
	AP20
AD2003:	AP21
	dbra	d4,AD2003
	add.w	d1,(a1)+
	clr.w	d4
	dbra	d3,AD2001
	swap	d4
	jmp	(a5)
AD2005:	subi.l	#$10000,d2
	bcc	AD2002
	addi.l	#$10000,d2
	add.w	d4,d2
	subq.w	#1,d4
	moveq	#0,d1
AD2006:	subq.l	#1,d2
	bcs	AD2010
	AP21
	dbra	d4,AD2006
	add.w	d1,(a1)+
	clr.w	d4
	dbra	d3,AD2001
	swap	d4
	jmp	(a5)
AD2010:	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	AD2013
	lea	AD2012(pc),a4
	swap	d4
AD2011:	jmp	(a5)
	.dc.w	AD2011-AD2012
AD2012:	subq.l	#1,d2
	bcs	AD2011
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	swap	d4
	AP21
	dbra	d4,AD2006
	add.w	d1,(a1)+
	clr.w	d4
	dbra	d3,AD2001
	swap	d4
	jmp	(a5)
AD2013:	lea	AD2014(pc),a4
	addq.l	#2,a1
	swap	d4
	jmp	(a5)
	.dc.w	AD2011-AD2014
AD2014:	subq.l	#1,d2
	bcs	AD2011
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	swap	d4
	AP21
	dbra	d4,AD2006
	add.w	d1,(a1)+
	clr.w	d4
	dbra	d3,AD2001
	swap	d4
	jmp	(a5)

	.dc.w	AD2X-AD21
AD21:	sf	d7
	add.w	d3,d3
	swap	d4
	clr.w	d4
	lsr.l	#1,d5
	swap	d5
	dbra	d3,AD2101
	swap	d4
	jmp	(a5)
AD2101:	add.l	d5,d4
	addx.w	d6,d4
	sub.w	d4,d2
	bcs	AD2105
AD2102:	subq.w	#2,d4
	AP20
AD2103:	AP21
	dbra	d4,AD2103
	move.w	d1,(a1)+
	clr.w	d4
	dbra	d3,AD2101
	swap	d4
	jmp	(a5)
AD2105:	subi.l	#$10000,d2
	bcc	AD2102
	addi.l	#$10000,d2
	add.w	d4,d2
	subq.w	#1,d4
	moveq	#0,d1
AD2106:	subq.l	#1,d2
	bcs	AD2110
	AP21
	dbra	d4,AD2106
	move.w	d1,(a1)+
	clr.w	d4
	dbra	d3,AD2101
	swap	d4
	jmp	(a5)
AD2110:	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	AD2113
	lea	AD2112(pc),a4
	swap	d4
AD2111:	jmp	(a5)
	.dc.w	AD2X-AD2112
AD2112:	subq.l	#1,d2
	bcs	AD2111
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	swap	d4
	AP21
	dbra	d4,AD2106
	move.w	d1,(a1)+
	clr.w	d4
	dbra	d3,AD2101
	swap	d4
	jmp	(a5)
AD2113:	lea	AD2114(pc),a4
	move.w	d1,(a1)+
	swap	d4
	jmp	(a5)
	.dc.w	AD2X-AD2114
AD2114:	subq.l	#1,d2
	bcs	AD2111
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	swap	d4
	AP21
	dbra	d4,AD2106
	move.w	d1,(a1)+
	clr.w	d4
	dbra	d3,AD2101
	swap	d4
	jmp	(a5)

AD2X1:	move.l	d6,(a1)+
AD2X:	dbra	d3,AD2X1
	jmp	(a5)

	.dc.w	ADA1-ADA0
ADA0:	cmp.l	d3,d2			* ADPCM 1/2倍～1倍
	bcs	ADA2
	lsr.w	#1,d3
	tst.b	d7
	bmi	ADA02
	dbra	d3,ADA000
	jmp	(a5)
ADA000:	add.w	d5,d4
	bcc	ADA011
ADA001:	APA0
	add.w	d5,d4
	bcc	ADA032
ADA002:	add.w	d1,(a1)+
	add.w	d5,d4
	bcc	ADA013
ADA003:	APA0
	add.w	d5,d4
	bcc	ADA034
ADA004:	add.w	d1,(a1)+
	dbra	d3,ADA000
	sf	d7
	jmp	(a5)
ADA011:	addq.l	#2,a1
	add.w	d5,d4
	bcs	ADA022
ADA012:	addq.l	#2,a1
	add.w	d5,d4
	bcs	ADA003
ADA013:	addq.l	#2,a1
	add.w	d5,d4
	bcs	ADA024
ADA014:	addq.l	#2,a1
	dbra	d3,ADA000
	sf	d7
	jmp	(a5)

ADA02:	dbra	d3,ADA020
	jmp	(a5)
ADA020:	add.w	d5,d4
	bcc	ADA031
ADA021:	add.w	d1,(a1)+
ADA02A:	add.w	d5,d4
	bcc	ADA012
ADA022:	APA0
ADA02B:	add.w	d5,d4
	bcc	ADA033
ADA023:	add.w	d1,(a1)+
ADA02C:	add.w	d5,d4
	bcc	ADA014
ADA024:	APA0
ADA02D:	dbra	d3,ADA020
	st	d7
	jmp	(a5)
ADA031:	addq.l	#2,a1
	add.w	d5,d4
	bcs	ADA002
ADA032:	addq.l	#2,a1
	add.w	d5,d4
	bcs	ADA023
ADA033:	addq.l	#2,a1
	add.w	d5,d4
	bcs	ADA004
ADA034:	addq.l	#2,a1
	dbra	d3,ADA020
	st	d7
	jmp	(a5)

	.dc.w	ADAX-ADA1
ADA1:	cmp.l	d3,d2
	bcs	ADA3
	lsr.w	#1,d3
	tst.b	d7
	bmi	ADA12
	dbra	d3,ADA100
ADA100:	add.w	d5,d4
	bcc	ADA111
ADA101:	APA1
	add.w	d5,d4
	bcc	ADA132
ADA102:	move.w	d1,(a1)+
	add.w	d5,d4
	bcc	ADA113
ADA103:	APA1
	add.w	d5,d4
	bcc	ADA134
ADA104:	move.w	d1,(a1)+
	dbra	d3,ADA100
	sf	d7
	jmp	(a5)
ADA111:	move.w	d6,(a1)+
	add.w	d5,d4
	bcs	ADA122
ADA112:	move.w	d6,(a1)+
	add.w	d5,d4
	bcs	ADA103
ADA113:	move.w	d6,(a1)+
	add.w	d5,d4
	bcs	ADA124
ADA114:	move.w	d6,(a1)+
	dbra	d3,ADA100
	sf	d7
	jmp	(a5)

ADA12:	dbra	d3,ADA120
	jmp	(a5)
ADA120:	add.w	d5,d4
	bcc	ADA131
ADA121:	move.w	d1,(a1)+
ADA12A:	add.w	d5,d4
	bcc	ADA112
ADA122:	APA1
ADA12B:	add.w	d5,d4
	bcc	ADA133
ADA123:	move.w	d1,(a1)+
ADA12C:	add.w	d5,d4
	bcc	ADA114
ADA124:	APA1
ADA12D:	dbra	d3,ADA120
	st	d7
	jmp	(a5)
ADA131:	move.w	d6,(a1)+
	add.w	d5,d4
	bcs	ADA102
ADA132:	move.w	d6,(a1)+
	add.w	d5,d4
	bcs	ADA123
ADA133:	move.w	d6,(a1)+
	add.w	d5,d4
	bcs	ADA104
ADA134:	move.w	d6,(a1)+
	dbra	d3,ADA120
	st	d7
	jmp	(a5)

ADA2:	add.w	d3,d3
	tst.b	d7
	bmi	ADA210
	dbra	d3,ADA201
	jmp	(a5)
ADA201:	add.w	d5,d4
	bcc	ADA202
	subq.l	#1,d2
	bcs	ADA205
	APA0
	dbra	d3,ADA211
	st	d7
	jmp	(a5)
ADA202:	addq.l	#2,a1
	dbra	d3,ADA201
	sf	d7
	jmp	(a5)
ADA205:	movea.l	a4,a3
	subq.w	#1,d3
	lsr.w	#1,d3
	bcs	ADA208
	lea	ADA207(pc),a4
ADA206:	jmp	(a5)
	.dc.w	ADA206-ADA207
ADA207:	subq.l	#1,d2
	bcs	ADA206
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	APA0
	dbra	d3,ADA211
	st	d7
	jmp	(a5)
ADA208:	lea	ADA209(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	ADA206-ADA209
ADA209:	subq.l	#1,d2
	bcs	ADA206
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	APA0
	dbra	d3,ADA211
	st	d7
	jmp	(a5)
ADA210:	dbra	d3,ADA211
	jmp	(a5)
ADA211:	add.w	d5,d4
	bcc	ADA212
	add.w	d1,(a1)+
	dbra	d3,ADA201
	sf	d7
	jmp	(a5)
ADA212:	addq.l	#2,a1
	dbra	d3,ADA211
	st	d7
	jmp	(a5)

ADA3:	add.w	d3,d3
	tst.b	d7
	bmi	ADA310
	dbra	d3,ADA301
	jmp	(a5)
ADA301:	add.w	d5,d4
	bcc	ADA302
	subq.l	#1,d2
	bcs	ADA305
	APA1
	dbra	d3,ADA311
	st	d7
	jmp	(a5)
ADA302:	move.w	d6,(a1)+
	dbra	d3,ADA301
	sf	d7
	jmp	(a5)
ADA305:	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	ADA308
	lea	ADA307(pc),a4
ADA306:	jmp	(a5)
	.dc.w	ADAX-ADA307
ADA307:	subq.l	#1,d2
	bcs	ADA306
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	APA1
	dbra	d3,ADA311
	st	d7
	jmp	(a5)
ADA308:	lea	ADA309(pc),a4
	move.w	d6,(a1)+
	jmp	(a5)
	.dc.w	ADAX-ADA309
ADA309:	subq.l	#1,d2
	bcs	ADA306
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	APA1
	dbra	d3,ADA311
	st	d7
	jmp	(a5)
ADA310:	dbra	d3,ADA311
	jmp	(a5)
ADA311:	add.w	d5,d4
	bcc	ADA312
	move.w	d1,(a1)+
	dbra	d3,ADA301
	sf	d7
	jmp	(a5)
ADA312:	move.w	d6,(a1)+
	dbra	d3,ADA311
	st	d7
	jmp	(a5)

ADAX1:	move.l	d6,(a1)+
ADAX:	dbra	d3,ADAX1
	jmp	(a5)

	.dc.w	ADB1-ADB0
ADB0:	add.w	d3,d3			* ADPCM 1/2倍以下
	dbra	d3,ADB000
	jmp	(a5)
ADB000:	tst.b	d7
	bmi	ADB004
ADB001:	add.w	d5,d4
	bcc	ADB002
	subq.l	#1,d2
	bcs	ADB010
	APA0
	dbra	d3,ADB004
	st	d7
	jmp	(a5)
ADB002:	addq.l	#2,a1
	dbra	d3,ADB001
	sf	d7
	jmp	(a5)
ADB004:	add.w	d5,d4
	bcc	ADB005
	add.w	d1,(a1)+
	dbra	d3,ADB001
	sf	d7
	jmp	(a5)
ADB005:	addq.l	#2,a1
	dbra	d3,ADB004
	st	d7
	jmp	(a5)
ADB010:	sf	d7
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	ADB013
	lea	ADB012(pc),a4
ADB011:	jmp	(a5)
	.dc.w	ADB011-ADB012
ADB012:	subq.l	#1,d2
	bcs	ADB011
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	APA0
	dbra	d3,ADB004
	st	d7
	jmp	(a5)
ADB013:	lea	ADB014(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	ADB011-ADB014
ADB014:	subq.l	#1,d2
	bcs	ADB011
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	APA0
	dbra	d3,ADB004
	st	d7
	jmp	(a5)

	.dc.w	ADBX-ADB1
ADB1:	add.w	d3,d3
	dbra	d3,ADB100
	jmp	(a5)
ADB100:	tst.b	d7
	bmi	ADB104
ADB101:	add.w	d5,d4
	bcc	ADB102
	subq.l	#1,d2
	bcs	ADB110
	APA1
	dbra	d3,ADB104
	st	d7
	jmp	(a5)
ADB102:	move.w	d6,(a1)+
	dbra	d3,ADB101
ADB103:	sf	d7
	jmp	(a5)
ADB104:	add.w	d5,d4
	bcc	ADB105
	move.w	d1,(a1)+
	dbra	d3,ADB101
	sf	d7
	jmp	(a5)
ADB105:	move.w	d6,(a1)+
	dbra	d3,ADB104
	st	d7
	jmp	(a5)
ADB110:	sf	d7
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	ADB113
	lea	ADB112(pc),a4
ADB111:	jmp	(a5)
	.dc.w	ADBX-ADB112
ADB112:	subq.l	#1,d2
	bcs	ADB111
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	APA1
	dbra	d3,ADB104
	st	d7
	jmp	(a5)
ADB113:	lea	ADB114(pc),a4
	move.w	d6,(a1)+
	jmp	(a5)
	.dc.w	ADBX-ADB114
ADB114:	subq.l	#1,d2
	bcs	ADB111
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	APA1
	dbra	d3,ADB104
	st	d7
	jmp	(a5)

ADBX1:	move.l	d6,(a1)+
ADBX:	dbra	d3,ADBX1
	jmp	(a5)

	.dc.w	ADM01-ADM0
ADM0:	sf	d7			* ADPCM 1倍のみ
	cmp.l	d3,d2
	bcs	ADM02
	moveq	#7,d2
	and.w	d3,d2
	lsr.w	#3,d3
	move.b	ADM001(pc,d2.w),d2
	jmp	ADM002(pc,d2.w)
ADM001:	.dc.b	ADM00A-ADM002,ADM009-ADM002,ADM008-ADM002,ADM007-ADM002
	.dc.b	ADM006-ADM002,ADM005-ADM002,ADM004-ADM002,ADM003-ADM002
ADM002:	AP00
ADM003:	AP00
ADM004:	AP00
ADM005:	AP00
ADM006:	AP00
ADM007:	AP00
ADM008:	AP00
ADM009:	AP00
ADM00A:	dbra	d3,ADM002
	jmp	(a5)

	.dc.w	ADM0X-ADM01
ADM01:	sf	d7
	cmp.l	d3,d2
	bcs	ADM03
	moveq	#7,d2
	and.w	d3,d2
	lsr.w	#3,d3
	move.b	ADM011(pc,d2.w),d2
	jmp	ADM012(pc,d2.w)
ADM011:	.dc.b	ADM01A-ADM012,ADM019-ADM012,ADM018-ADM012,ADM017-ADM012
	.dc.b	ADM016-ADM012,ADM015-ADM012,ADM014-ADM012,ADM013-ADM012
ADM012:	AP01
ADM013:	AP01
ADM014:	AP01
ADM015:	AP01
ADM016:	AP01
ADM017:	AP01
ADM018:	AP01
ADM019:	AP01
ADM01A:	dbra	d3,ADM012
	jmp	(a5)

ADM021:	subq.l	#1,d2
	bcs	ADM022
	AP00
ADM02:	dbra	d3,ADM021
	jmp	(a5)
ADM022:	movea.l	a4,a3
	addq.w	#1,d3
	lea	ADM024(pc),a4
ADM023:	jmp	(a5)
	.dc.w	ADM023-ADM024
ADM024:	subq.l	#1,d2
	bcs	ADM023
	movea.l	a3,a4
	subq.w	#1,d3
	AP00
	dbra	d3,ADM021
	jmp	(a5)

ADM031:	subq.l	#1,d2
	bcs	ADM032
	AP01
ADM03:	dbra	d3,ADM031
	jmp	(a5)
ADM032:	movea.l	a4,a3
	addq.w	#1,d3
	lea	ADM034(pc),a4
ADM033:	jmp	(a5)
	.dc.w	ADM0X-ADM034
ADM034:	subq.l	#1,d2
	bcs	ADM033
	movea.l	a3,a4
	subq.w	#1,d3
	AP01
	dbra	d3,ADM031
	jmp	(a5)

ADM0X1:	move.l	d6,(a1)+
ADM0X:	dbra	d3,ADM0X1
	jmp	(a5)

	.dc.w	ADM11-ADM1
ADM1:	sf	d7			* ADPCM 2倍のみ
	add.w	d3,d3
	cmp.l	d3,d2
	bcs	ADM12
	moveq	#6,d2
	and.w	d3,d2
	lsr.w	#3,d3
	move.w	ADM101(pc,d2.w),d2
	jmp	ADM102(pc,d2.w)
ADM101:	.dc.w	ADM106-ADM102,ADM105-ADM102,ADM104-ADM102,ADM103-ADM102
ADM102:	AP10
	AP10
ADM103:	AP10
	AP10
ADM104:	AP10
	AP10
ADM105:	AP10
	AP10
ADM106:	dbra	d3,ADM102
	jmp	(a5)

	.dc.w	ADM1X-ADM11
ADM11:	sf	d7
	add.w	d3,d3
	cmp.l	d3,d2
	bcs	ADM13
	moveq	#6,d2
	and.w	d3,d2
	lsr.w	#3,d3
	move.w	ADM111(pc,d2.w),d2
	jmp	ADM112(pc,d2.w)
ADM111:	.dc.w	ADM116-ADM112,ADM115-ADM112,ADM114-ADM112,ADM113-ADM112
ADM112:	AP11
	AP11
ADM113:	AP11
	AP11
ADM114:	AP11
	AP11
ADM115:	AP11
	AP11
ADM116:	dbra	d3,ADM112
	jmp	(a5)

ADM121:	subq.l	#1,d2
	bcs	ADM122
	AP10
ADM12:	dbra	d3,ADM121
	jmp	(a5)
ADM122:	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	ADM125
	lea	ADM124(pc),a4
ADM123:	jmp	(a5)
	.dc.w	ADM123-ADM124
ADM124:	subq.l	#1,d2
	bcs	ADM123
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	AP10
	dbra	d3,ADM121
	jmp	(a5)
ADM125:	lea	ADM126(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	ADM123-ADM126
ADM126:	subq.l	#1,d2
	bcs	ADM123
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	AP10
	dbra	d3,ADM121
	jmp	(a5)

ADM131:	subq.l	#1,d2
	bcs	ADM132
	AP11
ADM13:	dbra	d3,ADM131
	jmp	(a5)
ADM132:	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	ADM135
	lea	ADM134(pc),a4
ADM133:	jmp	(a5)
	.dc.w	ADM1X-ADM134
ADM134:	subq.l	#1,d2
	bcs	ADM133
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	AP11
	dbra	d3,ADM131
	jmp	(a5)
ADM135:	lea	ADM136(pc),a4
	move.w	d6,(a1)+
	jmp	(a5)
	.dc.w	ADM1X-ADM136
ADM136:	subq.l	#1,d2
	bcs	ADM133
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	AP11
	dbra	d3,ADM131
	jmp	(a5)

ADM1X1:	move.l	d6,(a1)+
ADM1X:	dbra	d3,ADM1X1
	jmp	(a5)

	.dc.w	ADMA1-ADMA
ADMA:	sf	d7			* ADPCM 1/2倍のみ
	lsr.w	#1,d3
	cmp.l	d3,d2
	bcs	ADMA2
	moveq	#3,d2
	and.w	d3,d2
	lsr.w	#2,d3
	move.b	ADMA01(pc,d2.w),d2
	jmp	ADMA02(pc,d2.w)
ADMA01:	.dc.b	ADMA06-ADMA02,ADMA05-ADMA02,ADMA04-ADMA02,ADMA03-ADMA02
ADMA02:	APA2
ADMA03:	APA2
ADMA04:	APA2
ADMA05:	APA2
ADMA06:	dbra	d3,ADMA02
	jmp	(a5)

	.dc.w	ADMAX-ADMA1
ADMA1:	sf	d7
	lsr.w	#1,d3
	cmp.l	d3,d2
	bcs	ADMA3
	moveq	#3,d2
	and.w	d3,d2
	lsr.w	#2,d3
	move.b	ADMA11(pc,d2.w),d2
	jmp	ADMA12(pc,d2.w)
ADMA11:	.dc.b	ADMA16-ADMA12,ADMA15-ADMA12,ADMA14-ADMA12,ADMA13-ADMA12
ADMA12:	APA3
ADMA13:	APA3
ADMA14:	APA3
ADMA15:	APA3
ADMA16:	dbra	d3,ADMA12
	jmp	(a5)

ADMA21:	subq.l	#1,d2
	bcs	ADMA22
	APA2
ADMA2:	dbra	d3,ADMA21
	jmp	(a5)
ADMA22:	movea.l	a4,a3
	addq.w	#1,d3
	add.w	d3,d3
	lea	ADMA24(pc),a4
ADMA23:	jmp	(a5)
	.dc.w	ADMA23-ADMA24
ADMA24:	subq.l	#1,d2
	bcs	ADMA23
	movea.l	a3,a4
	lsr.w	#1,d3
	subq.w	#1,d3
	APA2
	dbra	d3,ADMA21
	jmp	(a5)

ADMA31:	subq.l	#1,d2
	bcs	ADMA32
	APA3
ADMA3:	dbra	d3,ADMA31
	jmp	(a5)
ADMA32:	movea.l	a4,a3
	addq.w	#1,d3
	add.w	d3,d3
	lea	ADMA34(pc),a4
ADMA33:	jmp	(a5)
	.dc.w	ADMAX-ADMA34
ADMA34:	subq.l	#1,d2
	bcs	ADMA33
	movea.l	a3,a4
	lsr.w	#1,d3
	subq.w	#1,d3
	APA3
	dbra	d3,ADMA31
	jmp	(a5)

ADMAX1:	move.l	d6,(a1)+
ADMAX:	dbra	d3,ADMAX1
	jmp	(a5)

	.dc.w	P16X00-P16X0
P16X0:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bhi	P16X1
	dbra	d3,P16X01
	jmp	(a5)
	.dc.w	P16X0X-P16X00
P16X00:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bhi	P16X1
	dbra	d3,P16X01
	jmp	(a5)
P16X01:	add.w	d5,d4
	bcc	P16X03
	subq.w	#2,d2
	bcs	P16X04
P16X02:	addq.l	#2,a0
P16X03:	addq.l	#2,a1
	dbra	d3,P16X01
	jmp	(a5)
P16X04:	subi.l	#$10000,d2
	bcc	P16X02
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16X07
	lea	P16X06(pc),a4
P16X05:	jmp	(a5)
	.dc.w	P16X0X-P16X06
P16X06:	subq.l	#2,d2
	bcs	P16X05
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	addq.l	#2,a0
	addq.l	#2,a1
	dbra	d3,P16X01
	jmp	(a5)
P16X07:	lea	P16X08(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	P16X0X-P16X08
P16X08:	subq.l	#2,d2
	bcs	P16X05
	movea.l	a3,a4
	add.w	d3,d3
	addq.l	#2,a0
	dbra	d3,P16X01
P16X0X:	jmp	(a5)

P16X1:	swap	d5
	add.w	d5,d5
	movea.w	d5,a3
	swap	d5
	addq.l	#2,a3
	dbra	d3,P16X11
	jmp	(a5)
P16X11:	add.w	d5,d4
	bcc	P16X21
	sub.w	a3,d2
	bcs	P16X13
P16X12:	adda.w	a3,a0
	addq.l	#2,a1
	dbra	d3,P16X11
	jmp	(a5)
P16X13:	subi.l	#$10000,d2
	bcc	P16X12
	move.l	a4,d7
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16X17
	lea	P16X15(pc),a4
P16X14:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16X0X-P16X15
P16X15:	sub.w	d1,d2
	bcs	P16X16
	movea.l	d7,a4
	add.w	d3,d3
	subq.w	#1,d3
	adda.w	d1,a0
	addq.l	#2,a1
	dbra	d3,P16X11
	jmp	(a5)
P16X16:	subi.l	#$10000,d2
	bcs	P16X14
	movea.l	d7,a4
	add.w	d3,d3
	subq.w	#1,d3
	adda.w	d1,a0
	addq.l	#2,a1
	dbra	d3,P16X11
	jmp	(a5)
P16X17:	lea	P16X19(pc),a4
	addq.l	#2,a1
P16X18:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16X0X-P16X19
P16X19:	sub.w	d1,d2
	bcs	P16X1A
	movea.l	d7,a4
	add.w	d3,d3
	adda.w	d1,a0
	dbra	d3,P16X11
	jmp	(a5)
P16X1A:	subi.l	#$10000,d2
	bcs	P16X18
	movea.l	d7,a4
	add.w	d3,d3
	adda.w	d1,a0
	dbra	d3,P16X11
	jmp	(a5)
P16X21:	swap	d5
	sub.w	d5,d2
	bcs	P16X23
P16X22:	adda.w	d5,a0
	swap	d5
	addq.l	#2,a1
	dbra	d3,P16X11
	jmp	(a5)
P16X23:	subi.l	#$10000,d2
	bcc	P16X22
	swap	d5
	move.l	a4,d7
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16X27
	lea	P16X25(pc),a4
P16X24:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16X0X-P16X25
P16X25:	sub.w	d1,d2
	bcs	P16X26
	movea.l	d7,a4
	add.w	d3,d3
	subq.w	#1,d3
	adda.w	d1,a0
	addq.l	#2,a1
	dbra	d3,P16X11
	jmp	(a5)
P16X26:	subi.l	#$10000,d2
	bcs	P16X24
	movea.l	d7,a4
	add.w	d3,d3
	subq.w	#1,d3
	adda.w	d1,a0
	addq.l	#2,a1
	dbra	d3,P16X11
	jmp	(a5)
P16X27:	lea	P16X29(pc),a4
	addq.l	#2,a1
P16X28:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P16X0X-P16X29
P16X29:	sub.w	d1,d2
	bcs	P16X2A
	movea.l	d7,a4
	add.w	d3,d3
	adda.w	d1,a0
	dbra	d3,P16X11
	jmp	(a5)
P16X2A:	subi.l	#$10000,d2
	bcs	P16X28
	movea.l	d7,a4
	add.w	d3,d3
	adda.w	d1,a0
	dbra	d3,P16X11
	jmp	(a5)

	.dc.w	P08X00-P08X0
P08X0:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bhi	P08X1
	dbra	d3,P08X01
	jmp	(a5)
	.dc.w	P08X0X-P08X00
P08X00:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bhi	P08X1
	dbra	d3,P08X01
	jmp	(a5)
P08X01:	add.w	d5,d4
	bcc	P08X03
	subq.w	#1,d2
	bcs	P08404
P08X02:	addq.l	#1,a0
P08X03:	addq.l	#2,a1
	dbra	d3,P08X01
	jmp	(a5)
P08X04:	subi.l	#$10000,d2
	bcc	P08X03
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P08X07
	lea	P08X06(pc),a4
P08X05:	jmp	(a5)
	.dc.w	P08X0X-P08X06
P08X06:	subq.l	#1,d2
	bcs	P08X05
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	addq.l	#1,a0
	addq.l	#2,a1
	dbra	d3,P08X01
	jmp	(a5)
P08X07:	lea	P08X06(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	P08X0X-P08X08
P08X08:	subq.l	#1,d2
	bcs	P08X05
	movea.l	a3,a4
	add.w	d3,d3
	addq.l	#1,a0
	dbra	d3,P08X01
P08X0X:	jmp	(a5)

P08X1:	swap	d5
	movea.w	d5,a3
	swap	d5
	addq.l	#1,a3
	dbra	d3,P08X11
	jmp	(a5)
P08X11:	add.w	d5,d4
	bcc	P08X21
	sub.w	a3,d2
	bcs	P08X13
P08X12:	adda.w	a3,a0
	addq.l	#2,a1
	dbra	d3,P08X11
	jmp	(a5)
P08X13:	subi.l	#$10000,d2
	bcc	P08X12
	move.l	a4,d7
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P08X17
	lea	P08X15(pc),a4
P08X14:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P08X0X-P08X15
P08X15:	sub.w	d1,d2
	bcs	P08X16
	movea.l	d7,a4
	add.w	d3,d3
	subq.w	#1,d3
	adda.w	d1,a0
	addq.l	#2,a1
	dbra	d3,P08X11
	jmp	(a5)
P08X16:	subi.l	#$10000,d2
	bcs	P08X14
	movea.l	d7,a4
	add.w	d3,d3
	subq.w	#1,d3
	adda.w	d1,a0
	addq.l	#2,a1
	dbra	d3,P08X11
	jmp	(a5)
P08X17:	lea	P08X19(pc),a4
	addq.l	#2,a1
P08X18:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P08X0X-P08X19
P08X19:	sub.w	d1,d2
	bcs	P08X1A
	movea.l	d7,a4
	add.w	d3,d3
	adda.w	d1,a0
	dbra	d3,P08X11
	jmp	(a5)
P08X1A:	subi.l	#$10000,d2
	bcs	P08X18
	movea.l	d7,a4
	add.w	d3,d3
	adda.w	d1,a0
	dbra	d3,P08X11
	jmp	(a5)
P08X21:	swap	d5
	sub.w	d5,d2
	bcs	P08X23
P08X22:	adda.w	d5,a0
	swap	d5
	addq.l	#2,a1
	dbra	d3,P08X11
	jmp	(a5)
P08X23:	subi.l	#$10000,d2
	bcc	P08X22
	swap	d5
	move.l	a4,d7
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P08X27
	lea	P08X25(pc),a4
P08X24:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P08X0X-P08X25
P08X25:	sub.w	d1,d2
	bcs	P08X26
	movea.l	d7,a4
	add.w	d3,d3
	subq.w	#1,d3
	adda.w	d1,a0
	addq.l	#2,a1
	dbra	d3,P08X11
	jmp	(a5)
P08X26:	subi.l	#$10000,d2
	bcs	P08X24
	movea.l	d7,a4
	add.w	d3,d3
	subq.w	#1,d3
	adda.w	d1,a0
	addq.l	#2,a1
	dbra	d3,P08X11
	jmp	(a5)
P08X27:	lea	P08X29(pc),a4
	addq.l	#2,a1
P08X28:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P08X0X-P08X29
P08X29:	sub.w	d1,d2
	bcs	P08X2A
	movea.l	d7,a4
	add.w	d3,d3
	adda.w	d1,a0
	dbra	d3,P08X11
	jmp	(a5)
P08X2A:	subi.l	#$10000,d2
	bcs	P08X28
	movea.l	d7,a4
	add.w	d3,d3
	adda.w	d1,a0
	dbra	d3,P08X11
	jmp	(a5)

*--------------------------------------------------------------------
*	これ以降は常駐時のｵﾌﾟｼｮﾝ指定により変化する
TBLTOP:
TBLT16:	.dc.b	$40,$41			* 対応する音量範囲
	.dc.w	0			* 追加ﾊﾞｲﾄ数/256(ﾋﾞｯﾄ15-8),ﾌﾗｸﾞ(ﾋﾞｯﾄ7-0)←8ﾋﾞｯﾄPCM用
	.dc.w	P1641B-P1641A		* ﾌﾟﾛｸﾞﾗﾑ長さ
P1641A:	P16F	9,2
P1641B:

	.dc.b	$42,$44
	.dc.w	0
	.dc.w	P1643B-P1643A
P1643A:	P16F	9,1
P1643B:

	.dc.b	$45,$47
	.dc.w	0
	.dc.w	P1646B-P1646A
P1646A:	P16E	8
P1646B:

	.dc.b	$48,$49
	.dc.w	0
	.dc.w	P1648B-P1648A
P1648A:	P16F	8,2
P1648B:

	.dc.b	$4A,$4B
	.dc.w	0
	.dc.w	P164AB-P164AA
P164AA:	P16F	8,1
P164AB:

	.dc.b	$4C,$4E
	.dc.w	0
	.dc.w	P164DB-P164DA
P164DA:	P16E	7
P164DB:

	.dc.b	$4F,$50
	.dc.w	0
	.dc.w	P1650B-P1650A
P1650A:	P16F	7,2
P1650B:

	.dc.b	$51,$53
	.dc.w	0
	.dc.w	P1652B-P1652A
P1652A:	P16F	7,1
P1652B:

	.dc.b	$54,$56
	.dc.w	0
	.dc.w	P1655B-P1655A
P1655A:	P16E	6
P1655B:

	.dc.b	$57,$5A
	.dc.w	0
	.dc.w	P1658B-P1658A
P1658A:	P16F	6,1
P1658B:

	.dc.b	$5B,$5C
	.dc.w	0
	.dc.w	P165CB-P165CA
P165CA:	P16E	5
P165CB:

	.dc.b	$5D,$5E
	.dc.w	0
	.dc.w	P165EB-P165EA
P165EA:	P16F	5,2
P165EB:

	.dc.b	$5F,$61
	.dc.w	0
	.dc.w	P1660B-P1660A
P1660A:	P16F	5,1
P1660B:

	.dc.b	$62,$63
	.dc.w	0
	.dc.w	P1663B-P1663A
P1663A:	P16E	4
P1663B:

	.dc.b	$64,$65
	.dc.w	0
	.dc.w	P1665B-P1665A
P1665A:	P16F	4,2
P1665B:

	.dc.b	$66,$68
	.dc.w	0
	.dc.w	P1667B-P1667A
P1667A:	P16F	4,1
P1667B:

	.dc.b	$69,$6B
	.dc.w	0
	.dc.w	P166BB-P166BA
P166BA:	P16E	3
P166BB:

	.dc.b	$6C,$6D
	.dc.w	0
	.dc.w	P166DB-P166DA
P166DA:	P16F	3,2
P166DB:

	.dc.b	$6E,$6F
	.dc.w	0
	.dc.w	P166FB-P166FA
P166FA:	P16F	3,1
P166FB:

	.dc.b	$70,$72
	.dc.w	0
	.dc.w	P1671B-P1671A
P1671A:	P16E	2
P1671B:

	.dc.b	$73,$74
	.dc.w	0
	.dc.w	P1674B-P1674A
P1674A:	P16F	2,2
P1674B:

	.dc.b	$75,$77
	.dc.w	0
	.dc.w	P1676B-P1676A
P1676A:	P16F	2,1
P1676B:

	.dc.b	$78,$79
	.dc.w	0
	.dc.w	P1679B-P1679A
P1679A:	P16E	1
P1679B:

	.dc.b	$7A,$7C
	.dc.w	0
	.dc.w	P167BB-P167BA
P167BA:	P16F	1,2
P167BB:

	.dc.b	$7D,$7E
	.dc.w	0
	.dc.w	P167DB-P167DA
P167DA:	P16F	1,1
P167DB:

	.dc.b	$7F,$81
	.dc.w	0
	.dc.w	P1680B-P1680A
P1680A:	.dc.w	P16800-P1680
P1680:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	P1681
	dbra	d3,P16801
	jmp	(a5)
	.dc.w	P1680X-P16800
P16800:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	P1681
	dbra	d3,P16801
	jmp	(a5)
P16801:	add.w	d5,d4
	bcc	P16803
	subq.w	#2,d2
	bcs	P16804
P16802:	move.w	(a0)+,d0
P16803:	add.w	d0,(a1)+
	dbra	d3,P16801
	jmp	(a5)
P16804:	subi.l	#$10000,d2
	bcc	P16802
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16807
	lea	P16806(pc),a4
P16805:	jmp	(a5)
	.dc.w	P1680X-P16806
P16806:	subq.l	#2,d2
	bcs	P16805
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0)+,d0
	add.w	d0,(a1)+
	dbra	d3,P16801
	jmp	(a5)
P16807:	lea	P16808(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	P1680X-P16808
P16808:	subq.l	#2,d2
	bcs	P16805
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0)+,d0
	add.w	d0,(a1)+
	dbra	d3,P16801
P1680X:	jmp	(a5)

P1681:	move.l	d5,d7
	swap	d7
	add.w	d7,d7
	movea.w	d7,a2
	addq.w	#2,d7
	dbra	d3,P16811
	jmp	(a5)
P16811:	add.w	d5,d4
	bcc	P16821
	sub.w	d7,d2
	bcs	P16813
P16812:	move.w	(a0),d0
	adda.w	d7,a0
	add.w	d0,(a1)+
	dbra	d3,P16811
	jmp	(a5)
P16813:	subi.l	#$10000,d2
	bcc	P16812
	move.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16817
	lea	P16815(pc),a4
P16814:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P1680X-P16815
P16815:	sub.w	d1,d2
	bcs	P16816
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	add.w	d0,(a1)+
	dbra	d3,P16811
	jmp	(a5)
P16816:	subi.l	#$10000,d2
	bcs	P16814
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	add.w	d0,(a1)+
	dbra	d3,P16811
	jmp	(a5)
P16817:	lea	P16819(pc),a4
	addq.l	#2,a1
P16818:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P1680X-P16819
P16819:	sub.w	d1,d2
	bcs	P1681C
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	add.w	d0,(a1)+
	dbra	d3,P16811
	jmp	(a5)
P1681C:	subi.l	#$10000,d2
	bcs	P16818
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	add.w	d0,(a1)+
	dbra	d3,P16811
	jmp	(a5)
P16821:	sub.w	a2,d2
	bcs	P16823
P16822:	move.w	(a0),d0
	adda.w	a2,a0
	add.w	d0,(a1)+
	dbra	d3,P16811
	jmp	(a5)
P16823:	subi.l	#$10000,d2
	bcc	P16822
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P16827
	lea	P16825(pc),a4
P16824:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P1680X-P16825
P16825:	sub.w	d1,d2
	bcs	P16826
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	add.w	d0,(a1)+
	dbra	d3,P16811
	jmp	(a5)
P16826:	subi.l	#$10000,d2
	bcs	P16824
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	add.w	d0,(a1)+
	dbra	d3,P16811
	jmp	(a5)
P16827:	lea	P16829(pc),a4
	addq.l	#2,a1
P16828:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P1680X-P16829
P16829:	sub.w	d1,d2
	bcs	P1682C
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	add.w	d0,(a1)+
	dbra	d3,P16811
	jmp	(a5)
P1682C:	subi.l	#$10000,d2
	bcs	P16828
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	add.w	d0,(a1)+
	dbra	d3,P16811
	jmp	(a5)
P1680B:

	.dc.b	$82,$83
	.dc.w	0
	.dc.w	P1682B-P1682A
P1682A:	P16D	2
P1682B:

	.dc.b	$84,$85
	.dc.w	0
	.dc.w	P1684B-P1684A
P1684A:	P16D	1
P1684B:

	.dc.b	$86,$88
	.dc.w	0
	.dc.w	P1687B-P1687A
P1687A:	P16A	1
P1687B:

	.dc.b	$89,$8A
	.dc.w	0
	.dc.w	P168AB-P168AA
P168AA:	.dc.w	P168A0-P168A
P168A:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	P168B
	dbra	d3,P168A1
	jmp	(a5)
	.dc.w	P168AX-P168A0
P168A0:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	P168B
	dbra	d3,P168A1
	jmp	(a5)
P168A1:	add.w	d5,d4
	bcc	P168A3
	subq.w	#2,d2
	bcs	P168A4
P168A2:	move.w	(a0)+,d0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
P168A3:	add.w	d0,(a1)+
	dbra	d3,P168A1
	jmp	(a5)
P168A4:	subi.l	#$10000,d2
	bcc	P168A2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P168A7
	lea	P168A6(pc),a4
P168A5:	jmp	(a5)
	.dc.w	P168AX-P168A6
P168A6:	subq.l	#2,d2
	bcs	P168A5
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0)+,d0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P168A1
	jmp	(a5)
P168A7:	lea	P168A8(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	P168AX-P168A8
P168A8:	subq.l	#2,d2
	bcs	P168A5
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0)+,d0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P168A1
P168AX:	jmp	(a5)

P168B:	move.l	d5,d7
	swap	d7
	add.w	d7,d7
	movea.l	d7,a2
	addq.w	#2,d7
	dbra	d3,P168B1
	jmp	(a5)
P168B1:	add.w	d5,d4
	bcc	P168C1
	sub.w	d7,d2
	bcs	P168B3
P168B2:	move.w	(a0),d0
	adda.w	d7,a0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P168B1
	jmp	(a5)
P168B3:	subi.l	#$10000,d2
	bcc	P168B2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P168B7
	lea	P168B5(pc),a4
P168B4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P168AX-P168B5
P168B5:	sub.w	d1,d2
	bcs	P168B6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P168B1
	jmp	(a5)
P168B6:	subi.l	#$10000,d2
	bcs	P168B4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P168B1
	jmp	(a5)
P168B7:	lea	P168B9(pc),a4
	addq.l	#2,a1
P168B8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P168AX-P168B9
P168B9:	sub.w	d1,d2
	bcs	P168BC
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P168B1
	jmp	(a5)
P168BC:	subi.l	#$10000,d2
	bcs	P168B8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P168B1
	jmp	(a5)
P168C1:	sub.w	a2,d2
	bcs	P168C3
P168C2:	move.w	(a0),d0
	adda.w	a2,a0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P168B1
	jmp	(a5)
P168C3:	subi.l	#$10000,d2
	bcc	P168C2
	move.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P168C7
	lea	P168C5(pc),a4
P168C4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P168AX-P168C5
P168C5:	sub.w	d1,d2
	bcs	P168C6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P168B1
	jmp	(a5)
P168C6:	subi.l	#$10000,d2
	bcs	P168C4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P168B1
	jmp	(a5)
P168C7:	lea	P168C9(pc),a4
	addq.l	#2,a1
P168C8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P168AX-P168C9
P168C9:	sub.w	d1,d2
	bcs	P168CC
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P168B1
	jmp	(a5)
P168CC:	subi.l	#$10000,d2
	bcs	P168C8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P168B1
	jmp	(a5)
P168AB:

	.dc.b	$8B,$8D
	.dc.w	0
	.dc.w	P168CB-P168CA
P168CA:	P16B	0
P168CB:

	.dc.b	$8E,$8F
	.dc.w	0
	.dc.w	P168FB-P168FA
P168FA:	P16A	2
P168FB:

	.dc.b	$90,$91
	.dc.w	0
	.dc.w	P1691B-P1691A
P1691A:	P16C	0
P1691B:

	.dc.b	$92,$94
	.dc.w	0
	.dc.w	P1693B-P1693A
P1693A:	P16B	1
P1693B:

	.dc.b	$95,$97
	.dc.w	0
	.dc.w	P1696B-P1696A
P1696A:	P16A	3
P1696B:

	.dc.b	$98,$99
	.dc.w	0
	.dc.w	P1698B-P1698A
P1698A:	P16C	1
P1698B:

	.dc.b	$9A,$9B
	.dc.w	0
	.dc.w	P169AB-P169AA
P169AA:	P16B	2
P169AB:

	.dc.b	$9C,$9E
	.dc.w	0
	.dc.w	P169DB-P169DA
P169DA:	P16A	4
P169DB:

	.dc.b	$9F,$A0
	.dc.w	0
	.dc.w	P169FB-P169FA
P169FA:	P16C	2
P169FB:
	.dc.w	0

TBLT08:	.dc.b	$40,$53
	.dc.w	0
	.dc.w	P0840B-P0840A
P0840A:	.dc.w	P08400-P0840
P0840:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	P0841
	dbra	d3,P08401
	jmp	(a5)
	.dc.w	P0840X-P08400
P08400:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	P0841
	dbra	d3,P08401
	jmp	(a5)
P08401:	add.w	d5,d4
	bcc	P08403
	subq.w	#1,d2
	bcs	P08404
P08402:	addq.l	#1,a0
P08403:	dbra	d3,P08401
	jmp	(a5)
P08404:	subi.l	#$10000,d2
	bcc	P08403
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P08407
	lea	P08406(pc),a4
P08405:	jmp	(a5)
	.dc.w	P0840X-P08406
P08406:	subq.l	#1,d2
	bcs	P08405
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	addq.l	#1,a0
	dbra	d3,P08401
	jmp	(a5)
P08407:	lea	P08408(pc),a4
	jmp	(a5)
	.dc.w	P0840X-P08408
P08408:	subq.l	#1,d2
	bcs	P08405
	movea.l	a3,a4
	add.w	d3,d3
	addq.l	#1,a0
	dbra	d3,P08401
P0840X:	jmp	(a5)

P0841:	move.l	d5,d7
	swap	d7
	movea.w	d7,a2
	addq.w	#1,d7
	dbra	d3,P08411
	jmp	(a5)
P08411:	add.w	d5,d4
	bcc	P08421
	sub.w	d7,d2
	bcs	P08413
P08412:	adda.w	d3,a0
	dbra	d3,P08411
	jmp	(a5)
P08413:	subi.l	#$10000,d2
	bcc	P08412
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P08417
	lea	P08415(pc),a4
P08414:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P0840X-P08415
P08415:	sub.w	d1,d2
	bcs	P08416
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	adda.w	d1,a0
	dbra	d3,P08411
	jmp	(a5)
P08416:	subi.l	#$10000,d2
	bcs	P08414
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	adda.w	d1,a0
	dbra	d3,P08411
	jmp	(a5)
P08417:	lea	P08419(pc),a4
P08418:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P0840X-P08419
P08419:	sub.w	d1,d2
	bcs	P0841C
	movea.l	a3,a4
	add.w	d3,d3
	adda.w	d1,a0
	dbra	d3,P08411
	jmp	(a5)
P0841C:	subi.l	#$10000,d2
	bcs	P08418
	movea.l	a3,a4
	add.w	d3,d3
	adda.w	d1,a0
	dbra	d3,P08411
	jmp	(a5)
P08421:	sub.w	a2,d2
	bcs	P08423
P08422:	adda.w	a2,a0
	dbra	d3,P08411
	jmp	(a5)
P08423:	subi.l	#$10000,d2
	bcc	P08422
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P08427
	lea	P08425(pc),a4
P08424:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P0840X-P08425
P08425:	sub.w	d1,d2
	bcs	P08426
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	adda.w	d1,a0
	dbra	d3,P08411
	jmp	(a5)
P08426:	subi.l	#$10000,d2
	bcs	P08424
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	adda.w	d1,a0
	dbra	d3,P08411
	jmp	(a5)
P08427:	lea	P08429(pc),a4
P08428:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P0840X-P08429
P08429:	sub.w	d1,d2
	bcs	P0842C
	movea.l	a3,a4
	add.w	d3,d3
	adda.w	d1,a0
	dbra	d3,P08411
	jmp	(a5)
P0842C:	subi.l	#$10000,d2
	bcs	P08428
	movea.l	a3,a4
	add.w	d3,d3
	adda.w	d1,a0
	dbra	d3,P08411
	jmp	(a5)
P0840B:

	.dc.b	$54,$56
	.dc.w	0
	.dc.w	P0855B-P0855A
P0855A:	PC8E	6
P0855B:

	.dc.b	$57,$5A
	.dc.w	$161
	.dc.w	P0858B-P0858A
P0858A:	PC8F
P0858B:

	.dc.b	$5B,$5C
	.dc.w	0
	.dc.w	P085CB-P085CA
P085CA:	PC8E	5
P085CB:

	.dc.b	$5D,$5E
	.dc.w	$152
	.dc.w	P085EB-P085EA
P085EA:	PC8F
P085EB:

	.dc.b	$5F,$61
	.dc.w	$151
	.dc.w	P0860B-P0860A
P0860A:	PC8F
P0860B:

	.dc.b	$62,$63
	.dc.w	0
	.dc.w	P0863B-P0863A
P0863A:	PC8E	4
P0863B:

	.dc.b	$64,$65
	.dc.w	$142
	.dc.w	P0865B-P0865A
P0865A:	PC8F
P0865B:

	.dc.b	$66,$68
	.dc.w	$141
	.dc.w	P0867B-P0867A
P0867A:	PC8F
P0867B:

	.dc.b	$69,$6B
	.dc.w	0
	.dc.w	P086BB-P086BA
P086BA:	PC8E	3
P086BB:

	.dc.b	$6C,$6D
	.dc.w	$132
	.dc.w	P086DB-P086DA
P086DA:	PC8F
P086DB:

	.dc.b	$6E,$6F
	.dc.w	$131
	.dc.w	P086FB-P086FA
P086FA:	PC8F
P086FB:

	.dc.b	$70,$72
	.dc.w	0
	.dc.w	P0871B-P0871A
P0871A:	PC8E	2
P0871B:

	.dc.b	$73,$74
	.dc.w	$122
	.dc.w	P0874B-P0874A
P0874A:	PC8F
P0874B:

	.dc.b	$75,$77
	.dc.w	$121
	.dc.w	P0876B-P0876A
P0876A:	PC8F
P0876B:

	.dc.b	$78,$79
	.dc.w	0
	.dc.w	P0879B-P0879A
P0879A:	PC8E	1
P0879B:

	.dc.b	$7A,$7C
	.dc.w	$112
	.dc.w	P087BB-P087BA
P087BA:	PC8F
P087BB:

	.dc.b	$7D,$7E
	.dc.w	$111
	.dc.w	P087DB-P087DA
P087DA:	PC8F
P087DB:

	.dc.b	$7F,$81
	.dc.w	0
	.dc.w	P0880B-P0880A
P0880A:	.dc.w	P08800-P0880
P0880:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	P0881
	dbra	d3,P08801
	jmp	(a5)
	.dc.w	P0880X-P08800
P08800:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	P0881
	dbra	d3,P08801
	jmp	(a5)
P08801:	add.w	d5,d4
	bcc	P08803
	subq.w	#1,d2
	bcs	P08804
P08802:	move.b	(a0)+,d0
	ext.w	d0
P08803:	add.w	d0,(a1)+
	dbra	d3,P08801
	jmp	(a5)
P08804:	subi.l	#$10000,d2
	bcc	P08802
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P08807
	lea	P08806(pc),a4
P08805:	jmp	(a5)
	.dc.w	P0880X-P08806
P08806:	subq.l	#1,d2
	bcs	P08805
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0)+,d0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,P08801
	jmp	(a5)
P08807:	lea	P08808(pc),a4
	jmp	(a5)
	.dc.w	P0880X-P08808
P08808:	subq.l	#1,d2
	bcs	P08805
	movea.l	a3,a4
	add.w	d3,d3
	move.b	(a0)+,d0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,P08801
P0880X:	jmp	(a5)

P0881:	move.l	d5,d7
	swap	d7
	movea.w	d7,a2
	addq.w	#1,d7
	dbra	d3,P08811
	jmp	(a5)
P08811:	add.w	d5,d4
	bcc	P08821
	sub.w	d7,d2
	bcs	P08813
P08812:	move.b	(a0),d0
	adda.w	d7,a0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,P08811
	jmp	(a5)
P08813:	subi.l	#$10000,d2
	bcc	P08812
	move.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P08817
	lea	P08815(pc),a4
P08814:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P0880X-P08815
P08815:	sub.w	d1,d2
	bcs	P08816
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	adda.w	d1,a0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,P08811
	jmp	(a5)
P08816:	subi.l	#$10000,d2
	bcs	P08814
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	adda.w	d1,a0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,P08811
	jmp	(a5)
P08817:	lea	P08819(pc),a4
	addq.l	#2,a1
P08818:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P0880X-P08819
P08819:	sub.w	d1,d2
	bcs	P0881C
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	adda.w	d1,a0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,P08811
	jmp	(a5)
P0881C:	subi.l	#$10000,d2
	bcs	P08818
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	adda.w	d1,a0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,P08811
	jmp	(a5)
P08821:	sub.w	a2,d2
	bcs	P08823
P08822:	move.w	(a0),d0
	adda.w	a2,a0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,P08811
	jmp	(a5)
P08823:	subi.l	#$10000,d2
	bcc	P08822
	move.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P08827
	lea	P08825(pc),a4
P08824:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P0880X-P08825
P08825:	sub.w	d1,d2
	bcs	P08826
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,P08811
	jmp	(a5)
P08826:	subi.l	#$10000,d2
	bcs	P08824
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,P08811
	jmp	(a5)
P08827:	lea	P08829(pc),a4
	addq.l	#2,a1
P08828:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P0880X-P08829
P08829:	sub.w	d1,d2
	bcs	P0882C
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,P08811
	jmp	(a5)
P0882C:	subi.l	#$10000,d2
	bcs	P08828
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	ext.w	d0
	add.w	d0,(a1)+
	dbra	d3,P08811
	jmp	(a5)
P0880B:

	.dc.b	$82,$83
	.dc.w	0
	.dc.w	P0882B-P0882A
P0882A:	PC8D	2
P0882B:

	.dc.b	$84,$85
	.dc.w	0
	.dc.w	P0884B-P0884A
P0884A:	PC8D	1
P0884B:

	.dc.b	$86,$88
	.dc.w	0
	.dc.w	P0887B-P0887A
P0887A:	PC8A	1
P0887B:

	.dc.b	$89,$8A
	.dc.w	0
	.dc.w	P088AB-P088AA
P088AA:	.dc.w	P088A0-P088A
P088A:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	P088B
	dbra	d3,P088A1
	jmp	(a5)
	.dc.w	P088AX-P088A0
P088A0:	add.w	d3,d3
	cmpi.l	#$10000,d5
	bcc	P088B
	dbra	d3,P088A1
	jmp	(a5)
P088A1:	add.w	d5,d4
	bcc	P088A3
	subq.w	#1,d2
	bcs	P088A4
P088A2:	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
P088A3:	add.w	d0,(a1)+
	dbra	d3,P088A1
	jmp	(a5)
P088A4:	subi.l	#$10000,d2
	bcc	P088A2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P088A7
	lea	P088A6(pc),a4
P088A5:	jmp	(a5)
	.dc.w	P088AX-P088A6
P088A6:	subq.l	#1,d2
	bcs	P088A5
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P088A1
	jmp	(a5)
P088A7:	lea	P088A8(pc),a4
	addq.l	#2,a1
	jmp	(a5)
	.dc.w	P088AX-P088A8
P088A8:	subq.l	#1,d2
	bcs	P088A5
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P088A1
P088AX:	jmp	(a5)

P088B:	move.l	d5,d7
	swap	d7
	movea.w	d7,a2
	addq.w	#1,d7
	dbra	d3,P088B1
	jmp	(a5)
P088B1:	add.w	d5,d4
	bcc	P088C1
	sub.w	d7,d2
	bcs	P088B3
P088B2:	move.b	(a0),d0
	adda.w	d7,a0
	ext.w	d0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P088B1
	jmp	(a5)
P088B3:	subi.l	#$10000,d2
	bcc	P088B2
	move.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P088B7
	lea	P088B5(pc),a4
P088B4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P088AX-P088B5
P088B5:	sub.w	d1,d2
	bcs	P088B6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	adda.w	d1,a0
	ext.w	d0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P088B1
	jmp	(a5)
P088B6:	subi.l	#$10000,d2
	bcs	P088B4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.b	(a0),d0
	adda.w	d1,a0
	ext.w	d0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P088B1
	jmp	(a5)
P088B7:	lea	P088B9(pc),a4
	addq.l	#2,a1
P088B8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P088AX-P088B9
P088B9:	sub.w	d1,d2
	bcs	P088BC
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	adda.w	d1,a0
	ext.w	d0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P088B1
	jmp	(a5)
P088BC:	subi.l	#$10000,d2
	bcs	P088B8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.b	(a0),d0
	adda.w	d1,a0
	ext.w	d0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P088B1
	jmp	(a5)
P088C1:	sub.w	a2,d2
	bcs	P088C3
P088C2:	move.w	(a0),d0
	adda.w	a2,a0
	ext.w	d0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P088B1
	jmp	(a5)
P088C3:	subi.l	#$10000,d2
	bcc	P088C2
	movea.l	a4,a3
	addq.w	#1,d3
	lsr.w	#1,d3
	bcs	P088C7
	lea	P088C5(pc),a4
P088C4:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P088AX-P088C5
P088C5:	sub.w	d1,d2
	bcs	P088C6
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	ext.w	d0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P088B1
	jmp	(a5)
P088C6:	subi.l	#$10000,d2
	bcs	P088C4
	movea.l	a3,a4
	add.w	d3,d3
	subq.w	#1,d3
	move.w	(a0),d0
	adda.w	d1,a0
	ext.w	d0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P088B1
	jmp	(a5)
P088C7:	lea	P088C9(pc),a4
	addq.l	#2,a1
P088C8:	neg.w	d2
	move.w	d2,d1
	jmp	(a5)
	.dc.w	P088AX-P088C9
P088C9:	sub.w	d1,d2
	bcs	P088CC
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	ext.w	d0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P088B1
	jmp	(a5)
P088CC:	subi.l	#$10000,d2
	bcs	P088C8
	movea.l	a3,a4
	subq.l	#2,a1
	add.w	d3,d3
	move.w	(a0),d0
	adda.w	d1,a0
	ext.w	d0
	move.w	d0,d6
	asr.w	#1,d6
	add.w	d0,d0
	add.w	d6,d0
	add.w	d0,(a1)+
	dbra	d3,P088B1
	jmp	(a5)
P088AB:

	.dc.b	$8B,$8D
	.dc.w	0
	.dc.w	P088CB-P088CA
P088CA:	PC8B	0
P088CB:

	.dc.b	$8E,$8F
	.dc.w	0
	.dc.w	P088FB-P088FA
P088FA:	PC8A	2
P088FB:

	.dc.b	$90,$91
	.dc.w	0
	.dc.w	P0891B-P0891A
P0891A:	PC8C	0
P0891B:

	.dc.b	$92,$94
	.dc.w	0
	.dc.w	P0893B-P0893A
P0893A:	PC8B	1
P0893B:

	.dc.b	$95,$97
	.dc.w	0
	.dc.w	P0896B-P0896A
P0896A:	PC8A	3
P0896B:

	.dc.b	$98,$99
	.dc.w	0
	.dc.w	P0898B-P0898A
P0898A:	PC8C	1
P0898B:

	.dc.b	$9A,$9B
	.dc.w	0
	.dc.w	P089AB-P089AA
P089AA:	PC8B	2
P089AB:

	.dc.b	$9C,$9E
	.dc.w	0
	.dc.w	P089DB-P089DA
P089DA:	PC8A	4
P089DB:

	.dc.b	$9F,$A0
	.dc.w	0
	.dc.w	P089FB-P089FA
P089FA:	PC8C	2
P089FB:
	.dc.w	0

*--------------------------------------------------------------------
*	ﾜｰｸｴﾘｱ	(長さ可変)

*	.align	16
*DPCMBF	.dcb.l	PCMBLK,0	* DPCM用ﾊﾞｯﾌｧ
*PCMBU1	.dcb.l	PCMBLK,0	* PCM用ﾊﾞｯﾌｧ
*ADPBF1	.dcb.b	PCMBLK,PCMSP2	* ADPCM出力ﾊﾞｯﾌｧ1
*ADPBF2	.dcb.b	PCMBLK,PCMSP2	* ADPCM出力ﾊﾞｯﾌｧ2
*ADPBFX	.dcb.b	PCMBLK,PCMSPC	* ADPCMﾀﾞﾐｰ出力ﾊﾞｯﾌｧ
*	.align	16
*CHNWK	.dcb.b	PCMCHN,0	* チャンネルワーク
				* ﾊﾞｲﾄ位置 機能
				* 0	動作ﾓｰﾄﾞ
				*	ﾋﾞｯﾄ7	動作停止
				*	    6	初期設定
				*	    5	IOCS予約中
				*	    4	IOCSﾓｰﾄﾞで使用中
				*	    3	IOCS一時停止解除禁止(出力ｷｬﾝｾﾙ)
				*	  1～0	動作ﾓｰﾄﾞ(0:通常,1:ｱﾚｲﾁｪｰﾝ,2:ﾘﾝｸｱﾚｲﾁｪｰﾝ,3:MPCM)
				* 1		音量
				* 2		周波数
				* 3		定位
				* 4～7		ADPCM→DPCM変換ﾃｰﾌﾞﾙ情報(ADPCM)
				* 8～$B		DPCMﾊﾞｯﾌｧ
				* $C～$D	$10のﾃﾞｰﾀﾎﾟｲﾝﾀ用ｶｳﾝﾀ
				* $E～$F	ﾌﾗｸﾞﾋﾞｯﾄ番号($1E:ADPCM,$1F:PCM)
				* $10～$13	ﾃﾞｰﾀﾎﾟｲﾝﾀ
				* $14～$17	音程変換用加算ﾊﾞｯﾌｧ
				* $18～$1B	音程変換用加算値
				* $1C～$1F	(AD)PCMﾃﾞｰﾀﾎﾟｲﾝﾀ
				* $20～$23	(D)PCMﾊﾞｯﾌｧﾎﾟｲﾝﾀ
				* $24～$27	音量変換ｵﾌｾｯﾄ(ADPCM)
				* $28～$2B	次のﾃﾞｰﾀﾎﾟｲﾝﾀ
				* $2C～$2F	処理ﾙｰﾁﾝｱﾄﾞﾚｽ
				* $30～$33	ﾃﾞｰﾀ先頭
				* $34～$37	ﾙｰﾌﾟ先頭
				* $38～$3B	ﾙｰﾌﾟ終了
				* $3C～$3F	ﾃﾞｰﾀ終了
				* $40～$43	ﾙｰﾌﾟ先頭のﾃｰﾌﾞﾙ情報(4～7の内容)
				* $44～$47	ﾙｰﾌﾟ終了のﾃｰﾌﾞﾙ情報(4～7の内容)
				* $48～$4B	ﾙｰﾌﾟ回数
				* $4C～$4F	ﾙｰﾌﾟｶｳﾝﾀ
				* $50		PCMの種類($FF:ADPCM,0:無し,1:16bit,2:8bit)
				* $51		ｵﾘｼﾞﾅﾙﾉｰﾄ番号
				* $52～$53	再生音程
				* $54		音量
				* $55		DPCMﾊﾞｯﾌｧ(8～$B)有効ﾌﾗｸﾞ(bit7のみ有効)
				* $56～$57	未使用
				* $58		再生周波数(0～6,$F0,$F1)
				* $59		KEY OFFﾓｰﾄﾞ(0:STOP,1:JUMP)
				* $5A～$7F	未使用

*	これ以降はﾃｰﾌﾞﾙ領域

*--------------------------------------------------------------------
*	ｺﾏﾝﾄﾞﾗｲﾝからの実行部

START:	pea	TTLMES(pc)
	DOS	_PRINT
	addq.l	#4,sp
	lea	16(a0),a0
	move.l	a0,-(sp)
	move.l	-8(a0),-(sp)
	lea	WK,a6
	moveq	#0,d7
	moveq	#0,d6
	not.w	d6
	moveq	#0,d5
	move.b	(a2)+,d0
	beq	CMDSET
	bsr	OPTGET
	beq	CMDSET
	andi.w	#$FF3F,d7

	tst.w	d7
	bmi	USAGE
	btst	#14,d7
	beq	CMDSET

	bsr	KEEPCK			* 常駐解除
	bmi	ERR8
	subq.w	#3,d0
	bcs	ERR5
	subq.w	#2,d0
	bcc	ERR5
	moveq	#$FF,d0
	trap	#2
	addq.l	#1,d0
	beq	ERR7
	addq.l	#1,d0
	beq	ERR6
	moveq	#0,d0
	lea	RELMES(pc),a0
	bra	ERRRTN

CMDSET:	bsr	KEEPCK			* 常駐開始
	bmi	ERR8
	beq	CMDKEP
	subq.w	#2,d0
	bcs	CMDSE1
	beq	CMDSE5
	subq.w	#1,d0
	beq	CMDSE2
	subq.w	#2,d0
	bcc	ERR2
	tst.w	d7			* PCM8が常駐している
	beq	ERR2
	bra	CMDSE3

CMDSE1:	movem.l	d6-d7,-(sp)		* 常駐がはずれているので常駐する
	pea	$0000.w
	DOS	_SUPER
	move.l	d0,(sp)
	jsr	(a0)
	tst.w	(sp)
	bmi	CMDSE4
	DOS	_SUPER
CMDSE4:	addq.l	#4,sp
	movem.l	(sp)+,d6-d7
CMDSE5:	bsr	VCTSET
	bne	ERR4
	bsr	PSTOPS
	move.w	d7,d0
	beq	NERRTN
	bra	CMDSE3

CMDSE2:	move.w	#$3F2F,D0		* 常駐済
	and.w	d7,d0
	beq	ERR4
CMDSE3:	bsr	CNGMOD
	bra	CMDCNG

CMDKEP:	bsr	SYSMOD			* 常駐処理開始
	bclr	#0,SYSFLG-WK(a6)
	bsr	ADRFIX
	bmi	CMDKER
	bsr	XMOVE
	bmi	CMDKER
	bsr	CACCLR
	lea	CMDKE2(pc),a0
	adda.l	d0,a0
	jmp	(a0)
CMDKE2:	bsr	INIT
	bsr	CACCLR
	bsr	VCTINI
	bsr	PSTOPS
	bsr	VCTSET
	bsr	CNGMOD
	lea	CHKFLG,a0		* 先頭に疑似認識情報を置く
	lea	TOPADR,a1
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.w	#$6000,(a1)+
	suba.l	a1,a0
	move.w	a0,(a1)
	tst.l	d5
	beq	CMDKE3
	move.l	d5,-(sp)
	DOS	_MFREE
	addq.l	#4,sp
	tst.l	d0
	bmi	CMDKER
CMDKE3:	movem.l	(sp)+,a0-a1
	lea	-$F0(a4),a4
	suba.l	a1,a4
	move.w	#0,-(sp)
	move.l	a4,-(sp)
	DOS	_KEEPPR

STDISP:	bsr	P8ACHK
	cmpi.b	#3,d0
	bne	ERR9
	move.w	#$01FC,d0		* 動作ﾓｰﾄﾞ
	moveq	#-1,d1
	trap	#2
	lea	STAM01(pc),a0
	lea	STAMB0(pc),a1
	bsr	SERCPY
	move.w	#$01FA,d0
	moveq	#-1,d1			* 動作状況表示
	trap	#2
	move.l	d0,d2
	moveq	#-1,d0
	tst.l	d2
	bmi	STDI02
	moveq	#0,d0
	btst	#27,d2
	beq	STDI02
	moveq	#1,d0
STDI02:	lea	STAM02(pc),a0
	lea	STAMB0(pc),a1
	bsr	SERCPY
	moveq	#-1,d0			* 音量可変
	tst.l	d2
	bmi	STDI04
	moveq	#0,d0
	btst	#26,d2
	beq	STDI04
	btst	#25,d2
	beq	STDI04
	moveq	#1,d0
STDI04:	lea	STAM03(pc),a0
	lea	STAMB0(pc),a1
	bsr	SERCPY
	moveq	#-1,d0			* IOCSﾁｬﾝﾈﾙ数
	tst.l	d2
	bmi	STDI05
	move.l	d2,d0
	swap	d0
	andi.w	#$FF,d0
STDI05:	lea	STAN01(pc),a0
	bsr	DECCNV
	moveq	#-1,d0			* 有効ﾁｬﾝﾈﾙ数
	tst.l	d2
	bmi	STDI06
	move.l	d2,d0
	lsr.w	#8,d0
STDI06:	lea	STAN02(pc),a0
	bsr	DECCNV
	move.w	#$01F9,d0		* 処理ﾊﾞｲﾄ数
	trap	#2
	move.l	d0,d1
	moveq	#-1,d0
	tst.l	d1
	bmi	STDI07
	move.l	d1,d0
	swap	d0
STDI07:	lea	STAN03(pc),a0
	bsr	DECCNV
	moveq	#-1,d0			* 最大音量
	tst.l	d1
	bmi	STDI08
	moveq	#0,d0
	move.b	d1,d0
STDI08:	lea	STAH01(pc),a0
	bsr	HEXCNV
	moveq	#-1,d0			* 最小音量
	tst.l	d1
	bmi	STDI09
	move.w	d1,d0
	lsr.w	#8,d0
STDI09:	lea	STAH02(pc),a0
	bsr	HEXCNV
	move.w	#$01F7,d0		* ADPCM動作ﾓｰﾄﾞ
	moveq	#-1,d1
	trap	#2
	move.l	d0,d1
	moveq	#-1,d0
	tst.l	d1
	bmi	STDI10
	move.w	d1,d0
	lsr.w	#8,d0
STDI10:	lea	STAN10(pc),a0
	bsr	DECCNV
	moveq	#-1,d0			* ADPCM動作周波数
	tst.l	d1
	bmi	STDI11
	moveq	#0,d0
	move.b	d1,d0
	subq.b	#4,d0
	andi.b	#7,d0
STDI11:	lea	STAM10(pc),a0
	lea	STAMF0(pc),a1
	bsr	SERCPY
	moveq	#0,d0			* 常駐ﾓｰﾄﾞ
	tst.l	d2
	bmi	STDI12
	btst	#24,d2
	beq	STDI12
	moveq	#1,d0
STDI12:	lea	STAM11(pc),a0
	lea	STAMJ0(pc),a1
	bsr	SERCPY
	move.w	#$01FF,d0		* PCM8占有
	trap	#2
	move.l	d0,d1
	bne	STDI13
	move.w	#$01FE,d0
	trap	#2
STDI13:	moveq	#0,d0
	tst.l	d1
	bne	STDI14
	moveq	#1,d0
STDI14:	lea	STAM04(pc),a0
	lea	STAMB0(pc),a1
	bsr	SERCPY
	move.w	#$7F11,d0		* MPCM占有
	trap	#2
	tst.l	d0
	bmi	STDI23
	movea.l	d0,a3
	move.w	#$7F12,d0
	trap	#2
	move.l	d0,d3
	bmi	STDI23
	move.l	d3,d2
	swap	d2
	movea.l	a3,a2
	moveq	#0,d1
	bra	STDI22
STDI21:	movea.l	a2,a1
	IOCS	_B_BPEEK
	or.b	d0,d1
	adda.w	d3,a2
STDI22:	dbne	d2,STDI21
	moveq	#0,d0
	tst.b	d1
	beq	STDI24
	moveq	#1,d0
	bra	STDI24
STDI23:	moveq	#-1,d0
STDI24:	lea	STAM05(pc),a0
	lea	STAMB0(pc),a1
	bsr	SERCPY
	move.l	d0,d1
	lea	STAMES(pc),a0		* ｽﾃｰﾀｽ表示
	move.l	a0,(sp)
	DOS	_PRINT
	subq.l	#1,d1
	bne	STDI30
	lea	MPCMES(pc),a0		* MPCM占有ﾌﾟﾛｸﾞﾗﾑ名
	move.l	a0,(sp)
	DOS	_PRINT
	lea	WKBUF(pc),a4
	lea	CRLF(pc),a5
	bra	STDI29
STDI25:	swap	d3
	movea.l	a4,a2
	movea.l	a3,a1
	move.w	d3,d2
	cmpi.w	#WKSIZ,d2
	bcs	STDI27
	move.w	#WKSIZ-1,d2
	bra	STDI27
STDI26:	IOCS	_B_BPEEK
	move.b	d0,(a2)+
STDI27:	dbeq	d2,STDI26
	clr.b	(a2)
	tst.b	(a4)
	beq	STDI28
	move.l	a4,(sp)
	DOS	_PRINT
	move.l	a5,(sp)
	DOS	_PRINT
STDI28:	adda.w	d3,a3
STDI29:	swap	d3
	dbra	d3,STDI25
STDI30:	bra	NERRTN

SERCPY:	movem.l	d0-d1/a0-a2,-(sp)
	movea.l	a1,a2
	bra	SERCP3
SERCP1:	movea.l	a1,a2
SERCP2:	move.b	(a1)+,d1
	bne	SERCP2
SERCP3:	move.b	(a1),d1
	dbeq	d0,SERCP1
	bne	SERCP5
	movea.l	a2,a1
	bra	SERCP5
SERCP4:	move.b	d1,(a0)+
SERCP5:	move.b	(a1)+,d1
	bne	SERCP4
	movem.l	(sp)+,d0-d1/a0-a2
	rts

CMDCLR:	lea	CLRMES(pc),a0
	bra	CMDCN1

CMDCNG:	bclr	#13,d7
	tst.w	d7
	beq	CMDCLR
	btst	#12,d7
	beq	CMDCN2
	cmpi.l	#$0000FFFF,d6
	beq	STDISP
CMDCN2:	lea	CNGMES(pc),a0
CMDCN1:	moveq	#0,d0
	bra	ERRRTN

USAGE:	lea	USEMES(pc),a0
	moveq	#1,d0
	bra	ERRRTN

ERR2:	lea	KERMES(pc),a0
	moveq	#2,d0
	bra	ERRRTN

CMDKER:	movem.l	d5/a4,-(sp)
	pea	0.w
	DOS	_SUPER
	move.l	d0,(sp)
	jsr	VCTRTN
	tst.w	(sp)
	bmi	ERR31
	DOS	_SUPER
ERR31:	addq.l	#4,sp
	movem.l	(sp)+,d5/a4
	tst.l	d5
	beq	ERR3
	move.l	d5,-(sp)
	DOS	_MFREE
	addq.l	#4,sp
ERR3:	lea	KEMMES(pc),a0
	moveq	#3,d0
	bra	ERRRTN

ERR4:	lea	KRDMES(pc),a0
	moveq	#4,d0
	bra	ERRRTN

ERR5:	lea	REXMES(pc),a0
	moveq	#5,d0
	bra	ERRRTN

ERR6:	lea	RERMES(pc),a0
	moveq	#6,d0
	bra	ERRRTN

ERR7:	lea	RENMES(pc),a0
	moveq	#7,d0
	bra	ERRRTN

ERR8:	lea	DERMES(pc),a0
	moveq	#8,d0
	bra	ERRRTN

ERR9:	lea	OTHMES(pc),a0
	moveq	#9,d0

ERRRTN:	move.l	a0,(sp)
	DOS	_PRINT
NERRTN:	addq.l	#6,sp
	move.w	d0,(sp)
	DOS	_EXIT2

KEEPCK:	move.l	d1,-(sp)		* 常駐ﾁｪｯｸ
	pea	$0000.w
	DOS	_SUPER
	move.l	d0,(sp)
	bsr	KEPCHK
	bne	KEEPC1
	bsr	DKPCHK
KEEPC1:	move.l	d0,d1
	tst.w	(sp)
	bmi	KEEPC2
	DOS	_SUPER
KEEPC2:	addq.l	#4,sp
	move.l	d1,d0
	movem.l	(sp)+,d1
	rts

KEPCHK:	move.l	d1,-(sp)		* 飛び先ﾁｪｯｸによる常駐ﾁｪｯｸ
	moveq	#0,d1			* 0:常駐していない
	lea	T1VECA.w,a0		* trap #1 の飛び先ﾁｪｯｸ
	movea.l	(a0),a0
	subq.l	#8,a0
	move.l	(a0)+,d0
	cmpi.l	#MPCMOK,d0
	beq	KEPC02
	cmpi.l	#PCM8NG,d0
	bne	KEPC03
KEPC02:	moveq	#5,d1			* 5:組み込み拒否(MPCM常駐)
KEPC03:	lea	T2VECA.w,a0		* trap #2 の飛び先ﾁｪｯｸ
	movea.l	(a0),a0
	cmpa.l	#$00F00000,a0
	bcc	KEPCH1
	moveq	#5,d1			* 5:組み込み拒否
KEPCH1:	move.l	a0,d0
	swap	d0
	andi.w	#$FFF0,d0
	cmpi.w	#$22F0,d0
	beq	KEPCH2
	moveq	#5,d1
KEPCH2:	subq.l	#8,a0
	move.l	(a0)+,d0
	cmpi.l	#PCM8OK,d0
	beq	KEPCH3
	cmpi.l	#PCM8NG,d0
	bne	KEPCHE
	cmpi.l	#'/048',(a0)
	bne	KEPCHE
	lea	-12(a0),a0
	cmpi.l	#PCM8OK,(a0)+
	bne	KEPCHE
	cmpi.b	#'A',(a0)
	bne	KEPCHE
	moveq	#2,d1			* 2:常駐していない(trap #2 は接続)
	bra	KEPCHE
KEPCH3:	cmpi.l	#'/048',(a0)
	bne	KEPCHE
	moveq	#4,d1			* 4:他の PCM8 が常駐している
	lea	-12(a0),a0
	cmpi.l	#PCM8OK,(a0)+
	bne	KEPCHE
	cmpi.b	#'A',(a0)
	bne	KEPCHE
	moveq	#3,d1			* 3:常駐済
KEPCHE:	move.l	d1,d0
	movem.l	(sp)+,d1
	rts

DKPCHK:	movem.l	d1-d3/a1-a4,-(sp)	* ﾃﾞﾊﾞｲｽﾄﾞﾗｲﾊﾞ名でﾁｪｯｸ
	moveq	#-1,d3
	bsr	NULSRC
	cmp.l	d3,d0
	beq	DKPCH5
	movea.l	d0,a3
	moveq	#8-1,d0
	moveq	#2-1,d2
	lea	DEVNA1(pc),a1
DKPCH1:	movea.l	a3,a2
DKPCH2:	move.l	(a2),d1
	cmp.l	d3,d1
	beq	DKPCH3
	movea.l	d1,a2
	lea	14(a2),a0		* ﾃﾞﾊﾞｲｽ名ﾁｪｯｸ
	bsr	STRCMP
	bne	DKPCH2
	addq.l	#8,a0
	movem.l	d0/a1,-(sp)		* PCM8A ﾍｯﾀﾞ文字ﾁｪｯｸ
	lea	HEADD1,a1
	moveq	#HEADD2-HEADD1-1,d0
	bsr	STRCMP
	movem.l	(sp)+,d0/a1
	bne	DKPCH2
	movea.l	HEADD2-HEADD1(a0),a2	* trap #2 接続処理ｱﾄﾞﾚｽ
	moveq	#1,d0			* 1:常駐が外れている
	bra	DKPCH4
DKPCH3:	addq.l	#8,a1
	dbra	d2,DKPCH1
	moveq	#0,d0			* 0:常駐していない
DKPCH4:	movea.l	a2,a0
DKPCH5:	tst.l	d0
	movem.l	(sp)+,d1-d3/a1-a4
	rts

NULSRC:	movem.l	d1/a0-a1,-(sp)		* NULL ﾃﾞﾊﾞｲｽのｻｰﾁ
	moveq	#-1,d1
	lea	HUTOP-1.w,a0
	lea	DEVNUL,a1
NULSR1:	addq.l	#1,a0
	moveq	#8-2,d0
	bsr	STRSRC
	move.l	a0,d0
	sub.l	a1,d0
	beq	NULSR2
	cmpi.w	#$8024,-10(a0)
	bne	NULSR1
	lea	-14(a0),a0
	move.l	a0,d1
NULSR2:	move.l	d1,d0
	movem.l	(sp)+,d1/a0-a1
	rts

STRSRC:	movem.l	d1-d3/a1-a3,-(sp)	* 文字列ｻｰﾁ
	move.b	(a1)+,d1
STRSR1:	cmp.b	(a0)+,d1
	bne	STRSR1
	movea.l	a1,a3
	movea.l	a0,a2
	move.w	d0,d2
STRSR2:	move.b	(a3)+,d3
	cmp.b	(a2)+,d3
	dbne	d2,STRSR2
	bne	STRSR1
	subq.l	#1,a0
	movem.l	(sp)+,d1-d3/a1-a3
	rts

STRCMP:	movem.l	d0/a0-a1,-(sp)		* 文字列比較
STRCM1:	move.b	(a1)+,d1
	cmp.b	(a0)+,d1
	dbne	d0,STRCM1
	movem.l	(sp)+,d0/a0-a1
	rts

XMOVE:	movem.l	d1/a0-a1,-(sp)		* ﾌﾟﾛｸﾞﾗﾑ移動
	lea	LASTAD(pc),a0
	move.l	#LASTAD-TBLTOP+16,d1
	lea	(a4,d1.l),a1
	btst	#4,d7
	beq	XMOVE1
	move.l	d1,-(sp)
	DOS	_MALLOC
	addq.l	#4,sp
	tst.l	d0
	bmi	XMOVE4
	move.l	d0,d5
	add.l	d1,d0
	movea.l	d0,a1
	sub.l	a0,d0
	bra	XMOVE2
XMOVE1:	move.l	a1,d0
	sub.l	a0,d0
	bhi	XMOVE2
	moveq	#0,d0
	bra	XMOVE4
XMOVE2:	addq.l	#7,d1
	lsr.l	#3,d1
	subq.w	#3,d1
XMOVE3:	move.l	-(a0),-(a1)
	move.l	-(a0),-(a1)
	dbra	d1,XMOVE3
	moveq	#0,d1
XMOVE4:	movem.l	(sp)+,d1/a0-a1
	rts

OPTGET:	movem.l	d1-d5/a0-a1,-(sp)	* ｵﾌﾟｼｮﾝ処理
	moveq	#0,d5
OPTGS:	bsr	SPCSKP
	tst.b	d0
	beq	OPTGEE
	cmpi.w	#'/',d0
	beq	OPTG1
	cmpi.w	#'-',d0
	bne	OPTSW
OPTG1:	bsr	CHRGET
OPTG0:	tst.b	d0
	beq	OPTGEE
	cmpi.w	#' ',d0
	bls	OPTGS
	cmpi.w	#'/',d0
	beq	OPTG1
	cmpi.w	#'-',d0
	beq	OPTG1
	bsr	CAPCNG
	cmpi.w	#'R',d0
	bne	OPTG2
	ori.w	#$4000,d7
	bra	OPTG1
OPTG2:	cmpi.w	#'D',d0			* 動作表示
	bne	OPTG3
	move.w	#$0C00,d2
	move.w	#$0800,d3
	bra	OPTSUB
OPTG3:	cmpi.w	#'V',d0			* 音量可変
	bne	OPTG4
	move.w	#$0300,d2
	move.w	#$0200,d3
	bra	OPTSUB
OPTG4:	cmpi.w	#'I',d0			* IOCSﾁｬﾝﾈﾙ
	bne	OPTG5
	bsr	NUMGET
	beq	OPTG0
	swap	d7
	move.b	d1,d7
	swap	d7
	ori.w	#$0020,d7
	bra	OPTG0
OPTG5:	cmpi.w	#'N',d0			* ﾃﾞﾊﾞｲｽﾄﾞﾗｲﾊﾞ名
	bne	OPTG6
	move.w	#$00C0,d2
	move.w	#$0080,d3
	bra	OPTSUB
OPTG6:	cmpi.w	#'S',d0			* ｼｽﾃﾑ情報
	bne	OPTG7
	ori.w	#$1000,d7
	bsr	NUMGET			* ﾁｬﾝﾈﾙ数
	beq	OPTG61
	rol.l	#8,d6
	move.b	d1,d6
	ror.l	#8,d6
OPTG61:	bsr	SEPCHK
	bne	OPTG0
	bsr	NUMGET			* 処理ﾌﾞﾛｯｸ数
	beq	OPTG63
	swap	d6
	move.b	d1,d6
	swap	d6
OPTG63:	bsr	SEPCHK
	bne	OPTG0
	bsr	NUMGET			* 最小音量
	beq	OPTG65
	move.b	d1,d6
OPTG65:	bsr	SEPCHK
	bne	OPTG0
	bsr	NUMGET			* 最大音量
	beq	OPTG67
	ror.w	#8,d6
	move.b	d1,d6
	rol.w	#8,d6
OPTG67:	bra	OPTG0
OPTG7:	cmpi.w	#'M',d0			* 周波数ﾓｰﾄﾞ
	bne	OPTG8
	ori.w	#$0008,d7
	lsl.l	#4,d7
	bsr	CAPGET
	cmpi.w	#'0',d0
	bcs	OPTG73
	cmpi.w	#'4',d0
	bhi	OPTG71
	subi.w	#'0',d0
	add.b	d0,d7
	bra	OPTG72
OPTG71:	cmpi.w	#'A',d0
	bne	OPTG73
	addq.b	#8,d7
OPTG72:	ror.l	#4,d7
	bra	OPTG1
OPTG73:	addq.b	#7,d7
	ror.l	#4,d7
	bra	OPTG0
OPTG8:	cmpi.w	#'F',d0			* 基準周波数
	bne	OPTG9
	ori.w	#$0004,d7
	rol.l	#8,d7
	andi.w	#$FFF0,d7
	bsr	CAPGET
	cmpi.w	#'0',d0
	bcs	OPTG83
	cmpi.w	#'3',d0
	beq	OPTG83
	cmpi.w	#'7',d0
	bhi	OPTG81
	subi.w	#'0',d0
	add.b	d0,d7
	bra	OPTG82
OPTG81:	cmpi.w	#'A',d0
	bne	OPTG83
	addi.b	#9,d7
OPTG82:	ror.l	#8,d7
	bra	OPTG1
OPTG83:	addq.b	#8,d7
	ror.l	#8,d7
	bra	OPTG0
OPTG9:	cmpi.w	#'W',d0			* ﾜｰｸｱﾄﾞﾚｽ指定
	bne	OPTGA
OPTG91:	moveq	#1,d3
	bsr	NUMGET
	move.b	d1,d4
	bsr	SEPCHK
	bne	OPTG92
	bsr	NUMGET
	beq	OPTG92
	moveq	#$80,d3
OPTG92:	tst.b	d4
	beq	OPTG95
	lea	WKADF1-WK(a6),a0
	moveq	#WKCNT-1,d2
OPTG93:	lsr.b	#1,d4
	bcc	OPTG94
	move.b	d3,(a0)
	move.b	d5,1(a0)
	move.l	d1,2(a0)
OPTG94:	lea	10(a0),a0
	dbra	d2,OPTG93
OPTG95:	ori.w	#$0010,d7
	addq.b	#1,d5
	bsr	SEPCHK
	beq	OPTG91
	bra	OPTG0
OPTGA:	cmpi.w	#'Z',d0			* ﾃｰﾌﾞﾙ再作成
	bne	OPTGB
	ori.w	#$2000,d7		* CLR
	bsr	P8ACHK
	cmpi.b	#3,d0
	bne	OPTG1
	move.w	#$7F10,d0
	trap	#2
	tst.l	d0
	bmi	OPTG1
	move.l	d0,d1
	lea	CHKFLG-8,a0
	movea.l	d1,a1
	lea	CHKFLG-8-WK(a1),a1
	IOCS	_B_LPEEK
	cmp.l	(a0)+,d0
	bne	OPTG1
	IOCS	_B_LPEEK
	cmp.l	(a0)+,d0
	bne	OPTG1
	move.w	#$0103,d0
	trap	#2
	move.l	a6,-(sp)
	pea	$0000.w
	DOS	_SUPER
	move.l	d0,(sp)
	movea.l	d1,a6
	bsr	INIT2
	tst.w	(sp)
	bmi	OPTGA5
	DOS	_SUPER
OPTGA5:	addq.l	#4,sp
	movea.l	(sp)+,a6
	bra	OPTG1
OPTGB:	tst.b	d0
	beq	OPTGEE
OPTGER:	ori.w	#$8000,d7
OPTGEE:	movem.l	(sp)+,d1-d5/a0-a1
	tst.w	d7
	rts

OPTSUB:	or.w	d2,d7
	bsr	CHRGET
	cmpi.w	#'0',d0
	bcs	OPTG0
	cmpi.w	#'1',d0
	bhi	OPTG0
	eor.w	d3,d7
	cmpi.w	#'0',d0
	beq	OPTG1
	eor.w	d2,d7
	bra	OPTG1

OPTSW:	bsr	CAPCNG
	cmpi.w	#'O',d0
	bne	OPTSW2
	bsr	CAPGET
	cmpi.w	#'F',d0
	bne	OPTSW1
	bsr	CAPGET
	cmpi.w	#'F',d0
	bne	OPTGER
	andi.w	#$FFFC,d7		* OFF
	addq.b	#1,d7
	bra	OPTGS
OPTSW1:	cmpi.w	#'N',d0
	bne	OPTGER
	andi.w	#$FFFC,d7		* ON
	addq.b	#2,d7
	bra	OPTGS
OPTSW2:	cmpi.w	#'F',d0
	bne	OPTSW3
	bsr	CAPGET
	cmpi.w	#'N',d0
	bne	OPTGER
	bsr	CAPGET
	cmpi.w	#'C',d0
	bne	OPTGER
	andi.w	#$FFFC,d7		* FNC
	addq.b	#3,d7
	bra	OPTGS
OPTSW3:	cmpi.w	#'C',d0
	bne	OPTSWE
	bsr	CAPGET
	cmpi.w	#'L',d0
	bne	OPTGER
	bsr	CAPGET
	cmpi.w	#'R',d0
	bne	OPTGER
	ori.w	#$2000,d7		* CLR
	bra	OPTGS
OPTSWE:	tst.b	d0
	beq	OPTGEE
	bra	OPTGER

NUMGET:	movem.l	d2-d3,-(sp)		* 数値取り込み
	moveq	#0,d1
	moveq	#0,d2
	bsr	CHRGET
	beq	NUMGEE
	cmpi.w	#'0',d0
	bcs	NUMG20
	cmpi.w	#'9',d0
	bhi	NUMG20
NUMGE1:	addq.w	#1,d2
	subi.w	#'0',d0
	ext.l	d0
	move.l	d1,d3
	add.l	d1,d1
	add.l	d1,d1
	add.l	d3,d1
	add.l	d1,d1
	add.l	d0,d1
	bsr	CHRGET
	beq	NUMGEE
	cmpi.w	#'0',d0
	bcs	NUMGEE
	cmpi.w	#'9',d0
	bls	NUMGE1
NUMGEE:	tst.w	d2
	movem.l	(sp)+,d2-d3
	rts

NUMG20:	cmpi.w	#'$',d0
	beq	NUMG21
	bsr	CAPCNG
	cmpi.w	#'X',d0
	bne	NUMGEE
NUMG21:	bsr	CAPGET
	beq	NUMGEE
	cmpi.w	#'0',d0
	bcs	NUMGEE
	cmpi.w	#'9',d0
	bls	NUMG22
	cmpi.w	#'A',d0
	bcs	NUMGEE
	cmpi.w	#'F',d0
	bhi	NUMGEE
	subi.w	#'A'-'9'-1,d0
NUMG22:	addq.w	#1,d2
	subi.w	#'0',d0
	ext.l	d0
	lsl.l	#4,d1
	or.l	d0,d1
	bra	NUMG21

SEPCHK:	cmpi.w	#',',d0
	beq	SEPCH1
	cmpi.w	#':',d0
	beq	SEPCH1
	cmpi.w	#';',d0
	beq	SEPCH1
	cmpi.w	#'.',d0
SEPCH1:	rts

CAPGET:	bsr	CHRGET
CAPCNG:	cmpi.w	#'a',d0
	bcs	CAPCNE
	cmpi.w	#'z',d0
	bhi	CAPCNE
	subi.w	#$20,d0
CAPCNE:	rts

SPCSKP:	bsr	CHRGET
SPCSK0:	tst.b	d0
	beq	SPCSKE
	cmpi.w	#$20,d0
	bls	SPCSKP
SPCSKE:	tst.b	d0
	rts

CHRGET:	clr.w	d0
	move.b	(a2)+,d0
	bpl	CHRGEE
	cmpi.b	#$A0,d0
	bcs	CHRGE1
	cmpi.b	#$E0,d0
	bcs	CHRGEE
CHRGE1:	move.b	d0,-(sp)
	move.w	(sp)+,d0
	move.b	(a2)+,d0
CHRGEE:	tst.b	d0
	rts

*--------------------------------------------------------------------
*	ﾃﾞﾊﾞｲｽﾄﾞﾗｲﾊﾞ登録時の実行部

DEVSET:	movem.l	d1-d7/a0-a6,-(sp)
	lea	WK,a6
	pea	$0000.w
	move.w	#$6004,DEVINI		* 初期化処理部へ飛ばないようにする
	movea.l	18(a5),a2
DEVSE1:	move.b	(a2)+,d0
	bne	DEVSE1
	moveq	#0,d7
	moveq	#0,d6
	not.w	d6
	bra	DEVSE3
DEVSE2:	bsr	OPTGET
	tst.w	d7
	bmi	DEVER1
DEVSE3:	tst.b	(a2)
	bne	DEVSE2
	tst.w	d7
	bmi	DEVER1
	lea	WKADF1-WK(a6),a0
	bclr	#4,d7
	moveq	#$80,d0
	moveq	#WKCNT-1,d1
DEVSE4:	and.b	d0,(a0)
	lea	10(a0),a0
	dbra	d1,DEVSE4

	bsr	KEEPCK
	bmi	DEVER4
	beq	DEVSTA
	subq.w	#2,d0
	bcs	DEVSE5
	beq	DEVSE8
	subq.w	#2,d0
	bcs	DEVSE6
	bra	DEVER2

DEVSE5:	jsr	(a0)			* 常駐が外れていた
DEVSE8:	bsr	VCTSET
	bne	DEVER3
	bsr	PSTOPS
	bsr	CNGMOD
	btst	#14,d7
	bne	DEVCNG
	bra	DEVCN2

DEVSE6:	move.w	#$3F2F,D0		* 常駐済
	and.w	d7,d0
	beq	DEVER3
	bsr	CNGMOD
	btst	#14,d7
	bne	DEVSR1
	bra	DEVCNG

DEVSTA:	bsr	SYSMOD			* 組み込み開始
	bset	#0,SYSFLG-WK(a6)
	bsr	ADRFIX
	bmi	DEVSER
	bsr	XMOVE
	bmi	DEVSER
	bsr	CACCLR
	lea	DEVST3(pc),a0
	adda.l	d0,a0
	jmp	(a0)
DEVST3:	bsr	INIT
	bsr	CACCLR
	bsr	VCTINI
	bsr	PSTOPS
	bsr	VCTSET
	move.l	a4,14(a5)
	bsr	CNGMOD
	moveq	#0,d1
	lea	DEVNA1(pc),a1
	moveq	#$80,d0
	and.b	d7,d0
	beq	DEVST4
	lea	DEVNA2(pc),a1
DEVST4:	lea	DEVNAM,a0
	moveq	#8-1,d0
DEVST5:	move.b	(a1)+,(a0)+
	dbra	d0,DEVST5
	bra	DEVCN3

DEVSR1:	addq.l	#1,d0
	beq	DEVSR2
	bmi	DEVSR3
	lea	DOTMES(pc),a0		* 解除
	bra	DEVCN1

DEVSR2:	lea	RENMES(pc),a0		* 解除禁止
	bra	DEVCN1

DEVSR3:	lea	DOEMES(pc),a0		* 解除出来ず
	bra	DEVCN1

DEVER1:	lea	SWEMES(pc),a0		* スイッチ誤り
	bra	DEVCN1

DEVER2:	lea	DIEMES(pc),a0		* 組込拒否
	bra	DEVCN1

DEVER3:	lea	DRDMES(pc),a0		* 組込済
	bra	DEVCN1

DEVSER:	jsr	VCTRTN
DEVER4:	lea	DERMES(pc),a0		* 組込不可
	bra	DEVCN1

DEVCLR:	lea	CLRMES(pc),a0		* 初期化
	bra	DEVCN1

DEVCNG:	bclr	#13,d7
	tst.w	d7
	beq	DEVCLR
	lea	CNGMES(pc),a0		* 設定変更
DEVCN1:	move.l	a0,(sp)
DEVCN2:	move.w	#$500C,d1
DEVCN3:	pea	TTLME1(pc)
DEVCN4:	DOS	_PRINT
	addq.l	#4,sp
	tst.l	(sp)
	beq	DEVSEP
	DOS	_PRINT
DEVSEP:	addq.l	#4,sp
	moveq	#0,d0
	move.w	d1,d0
	movem.l	(sp)+,d1-d7/a0-a6
	rts

*--------------------------------------------------------------------
*	初期化処理ﾙｰﾁﾝ

PSTOPS:	move.l	d0,-(sp)		* 強制停止
	move.w	#$0101,d0
	trap	#2
	move.w	#$0100,d0
	trap	#2
	move.l	(sp)+,d0
	rts

CACCLR:	movem.l	d0-d1/a1,-(sp)		* ｷｬｯｼｭｸﾘｱ
	lea	MPUFLG.w,a1
	IOCS	_B_BPEEK
	cmpi.b	#2,d0
	bcs	CACCL1
	moveq	#3,d1
	moveq	#$AC,d0
	trap	#15
CACCL1:	movem.l	(sp)+,d0-d1/a1
	rts

SYSMOD:	movem.l	d0-d1,-(sp)		* 常駐時ｼｽﾃﾑ状態設定
	btst	#12,d7
	beq	SYSMOE
	moveq	#0,d0
	move.b	d6,d0			* 音量最小値
	cmpi.b	#$FF,d0
	beq	SYSM12
	cmpi.b	#15,d0
	bhi	SYSM11
	move.b	PCMXT4-WK(a6,d0.w),d0
SYSM11:	cmpi.b	#VOLMN2,d0
	bcc	SYSM13
SYSM12:	move.b	#VOLMN2,d0
SYSM13:	cmpi.b	#VOLMX2,d0
	bls	SYSM21
	move.b	#VOLMX2,d0
SYSM21:	move.w	d6,d1			* 音量最大値
	lsr.w	#8,d1
	cmpi.b	#$FF,d1
	beq	SYSM24
	cmpi.b	#15,d1
	bhi	SYSM22
	move.b	PCMXT4-WK(a6,d1.w),d1
SYSM22:	cmpi.b	#VOLMN2,d1
	bcc	SYSM23
	move.b	#VOLMN2,d1
SYSM23:	cmpi.b	#VOLMX2,d1
	bls	SYSM31
SYSM24:	move.b	#VOLMX2,d1
SYSM31:	cmp.b	d0,d1
	bcc	SYSM32
	exg	d0,d1
SYSM32:	movem.w	d0-d1,VOLMIN-WK(a6)
	cmp.w	VOLMN0-WK(a6),d0
	bls	SYSM33
	move.w	d0,VOLMN0-WK(a6)
SYSM33:	cmp.w	VOLMX0-WK(a6),d1
	bcc	SYSM34
	move.w	d1,VOLMX0-WK(a6)
SYSM34:	swap	d6
	move.w	d6,d0			* 処理ﾌﾞﾛｯｸ数
	andi.w	#$00FF,d0
	bne	SYSM41
	move.b	#PCMBI2/12,d0
	bra	SYSM42
SYSM41:	cmpi.b	#PCMBIX/12,d0
	bls	SYSM42
	move.b	#PCMBIX/12,d0
SYSM42:	move.w	d0,PCMBNX-WK(a6)
	cmp.w	PCMBN0-WK(a6),d0
	bcc	SYSM43
	move.w	d0,PCMBN0-WK(a6)
	move.w	d0,PCMBN1-WK(a6)
SYSM43:	move.w	d0,d1
	add.w	d0,d0
	add.w	d1,d0
	lsl.w	#2,d0
	move.w	d0,PCMBMX-WK(a6)
	cmp.w	PCMBL0-WK(a6),d0
	bcc	SYSM44
	move.w	d0,PCMBL0-WK(a6)
	move.w	d0,PCMBL1-WK(a6)
	move.w	d0,PCMBR0-WK(a6)
	move.w	d0,PCMBR1-WK(a6)
	move.w	d0,PCMBR2-WK(a6)
SYSM44:	move.w	d6,d0			* ﾁｬﾝﾈﾙ数
	lsr.w	#8,d0
	bne	SYSM51
	move.b	#PCMCI2,d0		* 無指定ならﾃﾞﾌｫﾙﾄ
SYSM51:	cmpi.b	#PCMCIN,d0		* 最小値以下なら最小値
	bcc	SYSM52
	move.b	#PCMCIN,d0
SYSM52:	cmpi.b	#PCMCIX,d0		* 最大値以上なら最大値
	bls	SYSM53
	move.b	#PCMCIX,d0
SYSM53:	move.w	d0,PCMCMX-WK(a6)
	cmp.w	PCMCHN-WK(a6),d0
	bcc	SYSM54
	move.w	d0,PCMCHN-WK(a6)
SYSM54:	move.w	PCMCHN-WK(a6),d0	* IOCSﾁｬﾝﾈﾙ数
	cmp.b	IOCHMX-WK(a6),d0
	bls	SYSM55
	move.b	IOCHMX-WK(a6),d0
SYSM55:	move.b	d0,IOCHN-WK(a6)
	swap	d6
SYSMOE:	movem.l	(sp)+,d0-d1
	rts

CNGMOD:	movem.l	d1/a5-a6,-(sp)		* 設定変更
	tst.w	d7
	beq	CNGMOE
	moveq	#$C,d1
	and.w	d7,d1
	beq	CNGM11
	bsr	CNGFRQ			* 周波数変更
CNGM11:	move.w	d7,d1			* 動作状況表示
	andi.w	#$0C00,d1
	beq	CNGM21
	rol.w	#6,d1
	subq.w	#1,d1
	move.w	#$7F00,d0
	trap	#2
CNGM21:	move.w	d7,d1			* 音量可変
	andi.w	#$0300,d1
	beq	CNGM31
	lsr.w	#8,d1
	subq.w	#1,d1
	move.w	#$7F04,d0
	trap	#2
CNGM31:	btst	#12,d7			* PCM8Aｼｽﾃﾑ情報
	beq	CNGM41
	bsr	P8ACHK
	cmpi.b	#2,d0
	bcs	CNGM41
	cmpi.b	#4,d0
	bcc	CNGM41
	move.l	d6,d1
	move.w	#$01F8,d0
	trap	#2
CNGM41:	btst	#5,d7			* IOCSﾁｬﾝﾈﾙ数
	beq	CNGM51
	move.l	d7,d1
	swap	d1
	andi.w	#$00FF,d1
	move.w	#$7F03,d0
	trap	#2
CNGM51:	moveq	#3,d1			* 単音再生ﾓｰﾄﾞ設定
	and.b	d7,d1
	beq	CNGM61
	subq.w	#1,d1
	move.w	#$7F02,d0
	trap	#2
CNGM61:	btst	#13,d7			* 内部初期化
	beq	CNGM71
	bsr	P8ACHK
	cmpi.b	#2,d0
	bcs	CNGM71
	cmpi.b	#4,d0
	bcc	CNGM611
	moveq	#$F1,d0
	trap	#2
	bra	CNGM71
CNGM611:
	bne	CNGM71
	pea	$0000.w
	DOS	_SUPER
	move.l	d0,(sp)
	jsr	DMASTP
	tst.w	(sp)
	bmi	CNGM612
	DOS	_SUPER
CNGM612:
	addq.l	#4,sp
	move.w	#$0101,d0
	trap	#2
	move.w	#$0100,d0
	trap	#2
CNGM71:	btst	#14,d7			* 組み込み解除
	beq	CNGMOE
	moveq	#$FF,d0
	trap	#2
CNGMOE:	movem.l	(sp)+,d1/a5-a6
	rts

CNGFRQ:	movem.l	d0-d3,-(sp)		* 基準周波数変更
	bsr	P8ACHK
	cmpi.b	#2,d0
	bcs	CNGFRE
	cmpi.b	#4,d0
	bcc	CNGFRE
	moveq	#-1,d1
	move.w	#$01F7,d0
	trap	#2
	tst.l	d0
	bmi	CNGFRE
	move.w	d0,d3
	moveq	#0,d1
	btst	#3,d7
	bne	CNGF11
	ror.w	#8,d0
	move.b	d0,d1
	rol.w	#8,d0
	bra	CNGF21
CNGF11:	moveq	#$F,d1
	rol.l	#4,d7
	and.b	d7,d1
	ror.l	#4,d7
CNGF21:	moveq	#0,d2
	btst	#2,d7
	bne	CNGF22
	move.b	d0,d2
	bra	CNGF31
CNGF22:	moveq	#$F,d2
	rol.l	#8,d7
	and.b	d7,d2
	ror.l	#8,d7
CNGF31:	cmpi.b	#7,d1
	bne	CNGF41
	bsr	ENVCHK			* 環境変数ﾁｪｯｸ
	move.b	d0,d1
CNGF41:	cmpi.b	#8,d1
	bcs	CNGF51
	bsr	AUTMOD			* 自動判定
	move.b	d0,d1
CNGF51:	cmpi.b	#3,d2
	beq	CNGF52
	cmpi.b	#8,d2
	bcs	CNGF61
CNGF52:	moveq	#0,d2			* 最大周波数
	tst.b	d1
	beq	CNGF61
	moveq	#2,d2
CNGF61:	ext.l	d1
	lsl.w	#8,d1
	move.b	d2,d1
	cmp.w	d1,d3
	beq	CNGFRE
	move.w	#$01F7,d0
	trap	#2
CNGFRE:	movem.l	(sp)+,d0-d3
	rts

ENVCHK:	movem.l	d1/a1-a2,-(sp)		* 環境変数ﾁｪｯｸ
	btst	#0,SYSFLG-WK(a6)
	bne	ENVCER
	movea.l	#$1800+$53*4,a1
	IOCS	_B_LPEEK
	move.l	d0,d1
	movea.l	#$1800+$83*4,a1
	IOCS	_B_LPEEK
	pea	WKBUF(pc)
	pea	0.w
	pea	ADPMOD(pc)
	cmp.l	d0,d1
	beq	ENVC01
	.dc.w	$FF53			* DOS _GETENV
	bra	ENVC02
ENVC01:	.dc.w	$FF83			* DOS _GETENV (Human v3以降)
ENVC02:	lea	12(sp),sp
	moveq	#0,d1
	lea	WKBUF(pc),a2
	bsr	SPCSKP
	beq	ENVCHE			* なし:MODE0
	cmpi.w	#'4',d0
	bne	ENVC21
	bsr	SPCSKP
	beq	ENVCHE			* 4:MODE0
	cmpi.w	#',',d0
	beq	ENVC11
	cmpi.w	#'/',d0
	bne	ENVCER
ENVC11:	bsr	SPCSKP
	beq	ENVCER
	cmpi.w	#'1',d0
	bne	ENVCER
	bsr	SPCSKP
	beq	ENVCER
	cmpi.w	#'6',d0
	bne	ENVCER
	moveq	#2,d1
	bsr	SPCSKP
	beq	ENVCHE			* 4/16:MODE2
	bra	ENVCER
ENVC21:	cmpi.w	#'1',d0
	bne	ENVC31
	bsr	SPCSKP
	beq	ENVCER
	cmpi.w	#'6',d0
	bne	ENVCER
	moveq	#1,d1
	bsr	SPCSKP
	beq	ENVCHE			* 16:MODE1
	cmpi.w	#',',d0
	beq	ENVC22
	cmpi.w	#'/',d0
	bne	ENVCER
ENVC22:	bsr	SPCSKP
	beq	ENVCER
	cmpi.w	#'4',d0
	bne	ENVCER
	moveq	#2,d1
	bsr	SPCSKP
	beq	ENVCHE			* 16/4:MODE2
	bra	ENVCER
ENVC31:	bsr	CAPCNG
	cmpi.w	#'M',d0
	bne	ENVC41
	bsr	SPCSKP
	beq	ENVCER
	cmpi.w	#'0',d0
	bcs	ENVCER
	cmpi.w	#'4',d0
	bhi	ENVCER
	subi.w	#'0',d0
	move.w	d0,d1
	bsr	SPCSKP
	beq	ENVCHE			* Mn:MODEn
	bra	ENVCER
ENVC41:	moveq	#8,d1
	cmpi.w	#'A',d0
	bne	ENVCER
	bsr	CAPGET
	beq	ENVCHE			* A:自動判定
	cmpi.w	#'U',d0
	bne	ENVCER
	bsr	CAPGET
	beq	ENVCHE			* AU:自動判定
	cmpi.w	#'T',d0
	bne	ENVCER
	bsr	CAPGET
	beq	ENVCHE			* AUT:自動判定
	cmpi.w	#'O',d0
	bne	ENVCER
	bsr	SPCSKP
	beq	ENVCHE			* AUTO:自動判定
ENVCER:	moveq	#0,d1
ENVCHE:	move.l	d1,d0
	movem.l	(sp)+,d1/a1-a2
	rts

AUTMOD:	movem.l	d1-d4/a0-a1/a5,-(sp)	* 周波数ﾓｰﾄﾞ自動判定
	move.w	#$0103,d0
	trap	#2
	pea	0.w
	DOS	_SUPER
	move.l	d0,(sp)
	moveq	#0,d3
	lea	WKBUF(pc),a0
	lea	WKBUFE(pc),a1
	move.l	a0,d2
	suba.l	a0,a1
	move.l	a1,d1
	moveq	#PCMSPC,d0
	dbra	d1,AUTM01
	bra	AUTM02
AUTM01:	move.b	d0,(a0)+
	dbra	d1,AUTM01
AUTM02:	move.l	a0,d0
	btst	#0,d0
	beq	AUTM03
	addq.l	#1,a0
AUTM03:	move.l	a1,2(a0)
	move.l	d2,(a0)
	move.l	a0,6(a0)
	lea	DMACH3,a5
	move.w	sr,d0
	move.w	d0,-(sp)
	andi.w	#$0700,d0
	cmpi.w	#$0300,d0
	bcc	AUTM10
	ori.w	#$0300,sr
AUTM10:	move.w	#$0200,ADIOCS.w
	moveq	#REPT,d4
	moveq	#2,d0			* 15.6kHz:基準用
	jsr	FRQSE0
	bsr	AUTMSB
	tst.l	d0
	beq	AUTMER
	move.l	d0,d1
	move.l	d0,d2
	lsr.l	#1,d0
	add.l	d0,d2
	lsr.l	#1,d0
	add.l	d0,d1			* D1=D0*5/4
	add.l	d0,d2			* D2=D0*7/4
	moveq	#$82,d0			* 31.2kHz:M1/M2,7.8kHz:M0/M3/M4
	jsr	FRQSE0
	bsr	AUTMSB
	tst.l	d0
	beq	AUTMER
	cmp.l	d1,d0
	shi	d3
	add.w	d3,d3
	moveq	#$81,d0			* 20.8kHz:M1,5.2kHz:M0/M2/M3/M4
	jsr	FRQSE0
	bsr	AUTMSB
	tst.l	d0
	beq	AUTMER
	cmp.l	d1,d0
	shi	d3
	add.w	d3,d3
	moveq	#$83,d0			* 7.8kHz:M0,20.8kHz:M2/M4,31.2kHz:M1/M3
	jsr	FRQSE0
	bsr	AUTMSB
	tst.l	d0
	beq	AUTMER
	cmp.l	d1,d0
	shi	d3
	add.w	d3,d3
	cmp.l	d2,d0
	shi	d3
	lsr.w	#7,d3
	moveq	#0,d1
	move.b	AUTMTB(pc,d3.w),d1
	bra	AUTMOE
AUTMER:	moveq	#0,d1
AUTMOE:	clr.w	ADIOCS.w
	move.w	(sp)+,sr
	tst.w	(sp)
	bmi	AUTMOX
	DOS	_SUPER
AUTMOX:	addq.l	#4,sp
	move.l	d1,d0
	movem.l	(sp)+,d1-d4/a0-a1/a5
	rts

AUTMTB:	.dc.b	0,0,4,3,0,0,0,0
	.dc.b	0,0,2,0,0,0,0,1

AUTMSB:	movem.l	d1-d6/a0-a1,-(sp)
	move.l	(a0),d5
	moveq	#0,d6
	move.b	#1,PCMCNT
	move.b	#$10,7(a5)
	st	(a5)
	move.l	a0,$1C(a5)
	move.l	#$0E808004,d0
	movep.w	d0,4(a5)
	swap	d0
	movep.w	d0,5(a5)
	move.b	#2,PCMCNT
AUTMS0:	IOCS	_ONTIME
	move.l	d0,d2
	moveq	#-1,d3
AUTMS1:	IOCS	_ONTIME
	cmp.l	d0,d2
	dbne	d3,AUTMS1
	beq	AUTMSE
	move.l	d0,d2
	moveq	#-1,d3
AUTMS2:	IOCS	_ONTIME
	cmp.l	d0,d2
	dbne	d3,AUTMS2
	beq	AUTMSE
	move.l	$C(a5),d0
	tst.w	d0
	beq	AUTMS3
	move.l	(a0),d1
	cmp.w	d0,d1
	bne	AUTMS4
AUTMS3:	move.l	$C(a5),d0
AUTMS4:	move.l	d0,d2
	sub.l	d5,d0
	bcc	AUTMS5
	moveq	#0,d1
	move.w	4(a0),d1
	add.l	d1,d0
AUTMS5:	move.l	d2,d5
	cmp.l	d0,d6
	beq	AUTMSX
	move.l	d0,d6
	dbra	d4,AUTMS0
AUTMSE:	moveq	#0,d0
AUTMSX:	move.b	#1,PCMCNT
	move.b	#PCMSP2,PCMDAT
	move.b	#$10,7(a5)
	st	(a5)
	movem.l	(sp)+,d1-d6/a0-a1
	rts

P8ACHK:	move.l	d1,-(sp)		* PCM8Aﾁｪｯｸ
	pea	$0000.w
	DOS	_SUPER
	move.l	d0,(sp)
	bsr	KEPCHK
	move.l	d0,d1
	tst.w	(sp)
	bmi	P8ACH1
	DOS	_SUPER
P8ACH1:	addq.l	#4,sp
	move.l	d1,d0
	move.l	(sp)+,d1
	rts

VCTINI:	movem.l	d0/a1,-(sp)		* trap #2 のみ接続
	lea	VECTBL-WK(a6),a1
	move.w	(a1)+,d0
	move.l	(a1)+,-(sp)
	move.w	d0,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
	move.l	d0,(a1)
	movem.l	(sp)+,d0/a1
	rts

VCTSET:	moveq	#$FE,d0			* 残りのﾍﾞｸﾀを接続
	trap	#2
	tst.l	d0
	rts

ADRFIX:	movem.l	d1-d5/a0-a3,-(sp)	* ﾜｰｸ/ﾃｰﾌﾞﾙｱﾄﾞﾚｽの決定
	lea	TBLTOP,a3		* 常駐部の後ろに配置するｻｲｽﾞの決定
	moveq	#$80,d0
	bsr	SIZCAL
	adda.l	d0,a3
	lea	WKADF1-WK(a6),a0
	moveq	#1,d2
ADRF02:	tst.b	(a0)
	bne	ADRF03
	bsr	ADRFSB
	move.l	d0,2(a0)
	move.b	d2,d0
	bsr	SIZCAL
	adda.l	d0,a3
ADRF03:	lea	10(a0),a0
	rol.b	#1,d2
	cmpi.b	#WKSNUM,d2
	bls	ADRF02
ADRF05:	lea	LASTAD(pc),a0
	cmpa.l	a0,a3
	bcc	ADRF06
	movea.l	a0,a3
ADRF06:	movea.l	a3,a4
	moveq	#0,d0
	btst	#0,SYSFLG-WK(a6)
	bne	ADRF10
	movea.l	a3,a1
	lea	TOPADR-$F0,a0
	suba.l	a0,a1
	movem.l	a0-a1,-(sp)
	DOS	_SETBLOCK
	addq.l	#8,sp
	tst.l	d0
	bmi	ADRF99

ADRF10:	lea	WKADF1-WK(a6),a0	* 最大値を得る
	moveq	#0,d1
	moveq	#0,d4
	moveq	#WKCNT-1,d2
ADRF11:	or.b	(a0)+,d1
	move.b	(a0)+,d0
	cmp.b	d0,d4
	bcc	ADRF12
	move.b	d0,d4
ADRF12:	addq.l	#8,a0
	dbra	d2,ADRF11

	moveq	#0,d0
	tst.b	d1
	bpl	ADRF20
	moveq	#0,d5			* 絶対番地を決定
	move.w	d4,d5
ADRF41:	swap	d5
	lea	WKADF1-WK(a6),a0
	moveq	#1,d2
	moveq	#0,d3
ADRF43:	tst.b	(a0)
	bpl	ADRF45
	cmp.b	1(a0),d5
	bne	ADRF45
	tst.w	d3
	bne	ADRF44
	st	d3
	movea.l	2(a0),a3
ADRF44:	bsr	ADRFSB
	move.l	a3,2(a0)
	move.b	d2,d0
	bsr	SIZCAL
	adda.l	d0,a3
ADRF45:	lea	10(a0),a0
	rol.b	#1,d2
	cmpi.b	#WKSNUM,d2
	bls	ADRF43
	addq.w	#1,d5
	swap	d5
	dbra	d5,ADRF41

ADRF20:	moveq	#0,d0
	andi.b	#$7F,d1
	beq	ADRF99
	moveq	#0,d5
ADRF21:	suba.l	a3,a3			* 仮のｱﾄﾞﾚｽで所要ﾊﾞｲﾄ数計算
	lea	WKADF1-WK(a6),a0
	moveq	#1,d2
ADRF23:	tst.b	(a0)
	ble	ADRF24
	cmp.b	1(a0),d5
	bne	ADRF24
	addq.l	#1,a3
	bsr	ADRFSB
	move.b	d2,d0
	bsr	SIZCAL
	adda.l	d0,a3
ADRF24:	lea	10(a0),a0
	rol.b	#1,d2
	cmpi.b	#WKSNUM,d2
	bls	ADRF23
	move.l	a3,-(sp)		* ﾒﾓﾘ確保
	DOS	_MALLOC
	addq.l	#4,sp
	tst.l	d0
	bmi	ADRF99

	move.l	d0,a3			* 実際のｱﾄﾞﾚｽを決定
	movea.l	a3,a1
	lea	WKADF1-WK(a6),a0
	moveq	#1,d2
	moveq	#0,d3
ADRF31:	tst.b	(a0)
	ble	ADRF34
	cmp.b	1(a0),d5
	bne	ADRF34
	tst.w	d3
	bne	ADRF32
	st	d3
	bset	#1,(a0)
	move.l	a3,6(a0)
ADRF32:	bsr	ADRFSB
	move.l	d0,2(a0)
	move.b	d2,d0
	bsr	SIZCAL
	adda.l	d0,a3
ADRF34:	lea	10(a0),a0
	rol.b	#1,d2
	cmpi.b	#WKSNUM,d2
	bls	ADRF31
	move.l	a3,a2			* 余分に確保した領域を詰める
	suba.l	a1,a2
	movem.l	a1-a2,-(sp)
	DOS	_SETBLOCK
	addq.l	#8,sp
	tst.l	d0
	bmi	ADRF99
	addq.b	#1,d5
	dbra	d4,ADRF21
	moveq	#0,d0
ADRF99:	tst.l	d0
	movem.l	(sp)+,d1-d5/a0-a3
	rts

ADRFSB:	btst	#4,d2
	bne	ADRFS1
	moveq	#CACHEL-1,d0
	add.l	a3,d0
	andi.w	#-CACHEL,d0
	movea.l	d0,a3
	rts

ADRFS1:	lea	$3FF(a3),a3
	move.l	a3,d0
	andi.w	#$FC00,d0
	movea.l	d0,a3
	rts

TBLREL:	.dc.l	TBLT16-TBLREL,TBLT08-TBLREL

SIZCAL:	movem.l	d1-d5/a0,-(sp)		* ﾜｰｸｴﾘｱ/ﾃｰﾌﾞﾙｴﾘｱｻｲｽﾞ計算
	move.l	d0,d5
	moveq	#0,d0
	movem.w	VOLMIN-WK(a6),d3-d4
	tst.b	d5
	bpl	SIZCA1
	lea	TBLREL(pc),a0
	adda.l	(a0),a0
	bsr	SIZCSB
	lea	TBLREL(pc),a0
	adda.l	4(a0),a0
	bsr	SIZCSB
SIZCA1:	btst	#0,d5
	beq	SIZCA2
	move.w	PCMBNX-WK(a6),d1
	mulu	#(24*4+24*4),d1
*		   ↑   ↑DPCM用ﾊﾞｯﾌｧ
*		   └PCM用ﾊﾞｯﾌｧ
	add.l	d1,d0
SIZCA2:	btst	#1,d5
	beq	SIZCA3
	move.w	PCMBNX-WK(a6),d1
	mulu	#(24*3),d1
*		   ↑ADPCM用ﾊﾞｯﾌｧ*3
	add.l	d1,d0
SIZCA3:	btst	#2,d5
	beq	SIZCA4
	move.w	PCMCMX-WK(a6),d1
	ext.l	d1
	lsl.w	#7,d1
	add.l	d1,d0
SIZCA4:	btst	#3,d5
	beq	SIZCA5
	add.l	#$10000+(VOLWID+1)*$300,d0
*		 ↑ADPCM変換	↑ADPCM変換
*		   ﾃｰﾌﾞﾙ2	  ﾃｰﾌﾞﾙ1
SIZCA5:	btst	#4,d5
	beq	SIZCA6
	sub.b	d3,d4
	addi.w	#VOLWID+1,d4
	swap	d4
	lsr.l	#6,d4
	add.l	d4,d0
	addi.l	#(VOLWID+1)*$400,d0
SIZCA6:	movem.l	(sp)+,d1-d5/a0
	rts

SIZCSB:	moveq	#0,d1			* 16/8ﾋﾞｯﾄﾙｰﾁﾝｻｲｽﾞ計算
	move.w	(a0),d1
	beq	SIZCS7			* 終わり
	move.b	d1,d2
	lsr.w	#8,d1
	cmp.b	d2,d3			* 音量範囲ﾁｪｯｸ
	bhi	SIZCS5
	cmp.b	d1,d4
	bcs	SIZCS5
	move.w	2(a0),d1		* 追加ﾊﾞｲﾄ数
	clr.b	d1
	add.l	d1,d0
	move.w	4(a0),d1		* ﾌﾟﾛｸﾞﾗﾑ長さ
	add.l	d1,d0
	bra	SIZCS6
SIZCS5:	move.w	4(a0),d1
SIZCS6:	adda.l	d1,a0			* 次のﾃｰﾌﾞﾙ
	addq.l	#6,a0
	bra	SIZCSB
SIZCS7:	rts

SUBGEN:	movem.l	d0-d5/a0-a2,-(sp)	* 8/16ﾋﾞｯﾄPCMﾙｰﾁﾝ作成
	movem.w	VOLMIN-WK(a6),d3-d4
	lea	TBLREL(pc),a0		* 16ﾋﾞｯﾄPCMﾙｰﾁﾝ作成
	adda.l	(a0),a0
	lea	PCMXT2-WK(a6),a1
	lea	P16X0,a2
	bsr	SUBGSB
	lea	TBLREL(pc),a0		* 8ﾋﾞｯﾄPCMﾙｰﾁﾝ作成
	adda.l	4(a0),a0
	lea	PCMXT3-WK(a6),a1
	lea	P08X0,a2
	bsr	SUBGSB
	movem.l	(sp)+,d0-d5/a0-a2
	rts

SUBGSB:	moveq	#VOLMN2,d5		* PCMﾙｰﾁﾝ作成
SUBG10:	move.w	(a0)+,d1
	beq	SUBG40			* 終わり
	move.b	d1,d2
	lsr.w	#8,d1
	cmp.b	d2,d3			* 音量範囲ﾁｪｯｸ
	bhi	SUBG30
	cmp.b	d1,d4
	bcs	SUBG30
SUBG20:	cmp.b	d1,d5
	bcc	SUBG21
	move.l	a2,(a1)+		* 音量が最小値以下の場合
	addq.b	#1,d5
	bra	SUBG20
SUBG21:	moveq	#2,d0
	add.l	a3,d0
SUBG22:	cmp.b	d2,d5
	bhi	SUBG23
	move.l	d0,(a1)+		* 処理ｱﾄﾞﾚｽの設定
	addq.b	#1,d5
	bra	SUBG22
SUBG23:	move.l	(a0)+,d1
	dbra	d1,SUBG25
	bra	SUBG26
SUBG25:	move.b	(a0)+,(a3)+		* 処理ﾙｰﾁﾝのｺﾋﾟｰ
	dbra	d1,SUBG25
SUBG26:	swap	d1
	tst.w	d1
	beq	SUBG10
	bsr	TBLISB
	bra	SUBG10
SUBG30:	move.l	(a0)+,d1
	adda.w	d1,a0			* 次のﾃｰﾌﾞﾙ(上位16ﾋﾞｯﾄはﾌﾗｸﾞのため無視)
	bra	SUBG10
SUBG40:	cmpi.b	#VOLMX2,d5
	bhi	SUBGSE
	move.l	a2,(a1)+
	addq.b	#1,d5
	bra	SUBG40
SUBGSE:	rts

TBLISB:	movem.l	d0-d4,-(sp)		* 8ﾋﾞｯﾄPCM音量変換ﾃｰﾌﾞﾙ作成(256ﾊﾞｲﾄ)
	move.b	d1,d3			* D3:ｼﾌﾄ量1,D4:ｼﾌﾄ量2
	lsr.b	#4,d3
	moveq	#$F,d4
	and.b	d1,d4
	moveq	#0,d2			* 入力値初期化
TBLIS1:	move.b	d2,d0
	ext.w	d0
	asl.w	#2,d0			* 精度を稼ぐために下駄を履かせる
	asr.w	d3,d0
	move.w	d0,d1
	asr.w	d4,d1
	add.w	d1,d0
	asr.w	#2,d0			* 下駄を戻す
	move.b	d0,(a3)+
	addq.b	#1,d2
	bcc	TBLIS1
	movem.l	(sp)+,d0-d4
	rts

INIT:	lea	TBLTOP,a3		* 各種初期化
	bsr	SUBGEN			* 8/16ﾋﾞｯﾄPCMﾙｰﾁﾝ作成

INIT2:	pea	0.w
	DOS	_SUPER
	move.l	d0,(sp)

	moveq	#0,d1			* ﾊﾞｯﾌｧｴﾘｱ確保
	movea.l	WKADR1-WK(a6),a3
	move.w	PCMBNX-WK(a6),d2
	move.l	a3,DPCMBF-WK(a6)
	move.w	d2,d0
	mulu	#24*4,d0
	bsr	WKINIT
	move.l	a3,PCMBU1-WK(a6)
	move.l	a3,PCMBU2-WK(a6)
	move.w	d2,d0
	mulu	#24*4,d0
	bsr	WKINIT

	movea.l	WKADR2-WK(a6),a3
	move.l	a3,ADPBF1-WK(a6)
	moveq	#PCMSPC,d1
	move.w	d2,d0
	mulu	#24,d0
	move.w	d0,d2
	bsr	WKINIT
	move.l	a3,ADPBF2-WK(a6)
	bsr	WKINIT
	move.l	a3,ADPBFX-WK(a6)
	moveq	#PCMSP2,d1
	moveq	#PCMSPN,d0
	sub.w	d0,d2
	bsr	WKINIT
	moveq	#PCMSP3,d1
	moveq	#PCMSPR,d0
	sub.w	d0,d2
	bsr	WKINIT
	moveq	#PCMSPC,d1
	move.w	d2,d0
	bsr	WKINIT

	movea.l	WKADR3-WK(a6),a3
	move.l	a3,CHNWK-WK(a6)		* ﾁｬﾝﾈﾙﾜｰｸ確保
	move.w	PCMCMX-WK(a6),d0
	lsl.w	#7,d0
	adda.w	d0,a3

	movea.l	WKADR4-WK(a6),a3
	movea.l	a3,a0			* DPCM→ADPCM変換ﾃｰﾌﾞﾙ作成
	adda.l	#$8000,a0
	move.l	a0,TBLAD3-WK(a6)
	adda.l	#$8000,a0
	move.l	a0,TBLAD2-WK(a6)
	bsr	TBLADP

	movea.l	WKADR5-WK(a6),a3
	lea	$3FF(a3),a3		* 1024ﾊﾞｲﾄ境界にｾｯﾄ
	move.l	a3,d0
	andi.w	#$FC00,d0
	movea.l	d0,a3
	lsr.w	#2,d0
	move.l	d0,TBLAD1-WK(a6)
	move.l	d0,PCMINI-WK(a6)

	bsr	TBLGEN			* ADPCM→DPCM変換ﾃｰﾌﾞﾙ作成

	tst.w	(sp)
	bmi	INITE
	DOS	_SUPER
INITE:	addq.l	#4,sp
	rts

WKINIT:	move.w	d0,-(sp)
	bra	WKINI2
WKINI1:	move.b	d1,(a3)+
WKINI2:	dbra	d0,WKINI1
	move.w	(sp)+,d0
	rts

TBLADP:	movem.l	d0-d7/a0-a2/a4-a6,-(sp)	* DPCM→ADPCM変換ﾃｰﾌﾞﾙ作成
	lea	DLTTBX(pc),a0		* 65536ﾊﾞｲﾄﾙｯｸｱｯﾌﾟﾃｰﾌﾞﾙ
	adda.l	#$8000,a3		*	入力	出力
	movea.l	a3,a2			*	$8000	$FE
	movea.l	a3,a1			*	 ：	 ：
	addq.l	#1,a1			*	$FFFF	$80
	moveq	#0,d0			*	$0000	$00
	moveq	#0,d3			*	 ：	 ：
TBLA11:	cmpi.w	#$7C,d0			*	$7FFF	$7E
	bcs	TBLA12
	addq.l	#2,a0
TBLA12:	moveq	#0,d4
	move.w	(a0)+,d4
	move.w	d4,d2
	sub.w	d3,d2
	subq.w	#1,d2
	bcs	TBLA14
	move.w	d0,d1
	tas	d1
TBLA13:	move.b	d1,-(a1)
	move.b	d0,(a3)+
	dbra	d2,TBLA13
	addq.b	#2,d0
TBLA14:	move.w	d4,d3
	cmpi.b	#$7E,d0
	bcs	TBLA11
	move.w	#$7FFF,d4
	sub.w	d3,d4
	move.w	d0,d1
	tas	d1
TBLA15:	move.b	d1,-(a1)
	move.b	d0,(a3)+
	dbra	d4,TBLA15
	move.b	d1,-(a1)

	lea	DLTTBA(pc),a0		* ADPCM変換ﾃｰﾌﾞﾙ
	moveq	#0,d7			*	入力	$00～$FE
TBLA20:	movea.l	a3,a4			*	出力	(1)ADPCMﾃﾞｰﾀ(256ﾊﾞｲﾄ)
	swap	d7			*		(2)DPCMﾃﾞｰﾀ(256ﾊﾞｲﾄ)
	lea	DLTTB3(pc),a1		*		(3)次のﾃｰﾌﾞﾙへのｵﾌｾｯﾄ(256ﾊﾞｲﾄ)
	clr.w	d7			*		ﾃｰﾌﾞﾙは49個(合計768*49=37632ﾊﾞｲﾄ)
	moveq	#0,d6
TBLA21:	movem.w	(a1)+,d4-d5
	mulu	(a0),d4
	move.w	d4,d3
	sub.w	(a0),d4
	lsr.w	#3,d4
	move.w	d3,d2
	lsr.w	#4,d2
	add.w	d2,d3
	addq.w	#4,d3
	lsr.w	#3,d3
	cmpi.w	#$0700,d7
	bcs	TBLA22
	move.w	#$80,d2
	bra	TBLA23
TBLA22:	moveq	#0,d2
	move.b	(a2,d3.w),d2
TBLA23:	move.w	d2,d3
	sub.w	d6,d2
	lsr.w	#1,d2
	subq.w	#1,d2
	bcs	TBLA27
	move.w	d7,d0
	ori.w	#$0880,d0
	move.w	d4,d1
	neg.w	d1
	swap	d7
	add.w	d7,d5
	bpl	TBLA24
	move.w	d7,d5
TBLA24:	cmpi.w	#VOLWID,d5
	bls	TBLA25
	move.w	#VOLWID,d5
TBLA25:	sub.w	d7,d5
	swap	d7
	lsl.w	#8,d5
	movea.l	a4,a5
	adda.w	d5,a5
	add.w	d5,d5
	adda.w	d5,a5
TBLA26:	move.w	d7,(a3)
	move.w	d0,$80(a3)
	move.w	d4,$100(a3)
	move.w	d1,$180(a3)
	movea.l	a5,a6
	suba.l	a3,a6
	move.w	a6,$200(a3)
	lea	-$80(a6),a6
	move.w	a6,$280(a3)
	addq.l	#2,a3
	dbra	d2,TBLA26
TBLA27:	move.w	d3,d6
	addi.w	#$0110,d7
	cmpi.w	#$80,d6
	bcs	TBLA21
	lea	$280(a3),a3
	addq.l	#2,a0
	swap	d7
	addq.w	#1,d7
	cmpi.w	#VOLWID,d7
	bls	TBLA20
	movem.l	(sp)+,d0-d7/a0-a2/a4-a6
	rts

TBLGEN:	movem.l	d0-d6/a0-a2/a4,-(sp)	* ADPCM→DPCM変換ﾃｰﾌﾞﾙ作成
	lea	DLTTB2(pc),a1		* (1)倍率変化ﾃｰﾌﾞﾙ作成(256*4*49=50176ﾊﾞｲﾄ)
	moveq	#0,d3			* 現在の倍率を初期化
TBLG01:	move.l	a3,d5			* 現在のﾃｰﾌﾞﾙの先頭ｱﾄﾞﾚｽを保存
	moveq	#0,d4
TBLG02:	move.w	d4,d0			* 下位4ﾋﾞｯﾄのADPCMﾃﾞｰﾀによる倍率の変化量を求める
	andi.w	#$F,d0
	add.w	d0,d0
	move.w	(a1,d0.w),d1
	add.w	d3,d1			* 範囲制限(0～VOLWID)
	bpl	TBLG03
	moveq	#0,d1
	bra	TBLG04
TBLG03:	cmpi.w	#VOLWID,d1
	bls	TBLG04
	moveq	#VOLWID,d1
TBLG04:	sub.w	d3,d1
	move.w	d4,d0			* 上位4ﾋﾞｯﾄのADPCMﾃﾞｰﾀによる倍率の変化量を求める
	andi.w	#$F0,d0
	lsr.w	#3,d0
	add.w	(a1,d0.w),d1
	add.w	d3,d1			* 範囲制限(0～VOLWID)
	bpl	TBLG05
	moveq	#0,d1
	bra	TBLG06
TBLG05:	cmpi.w	#VOLWID,d1
	bls	TBLG06
	moveq	#VOLWID,d1
TBLG06:	sub.w	d3,d1
	swap	d1			* 変化先のｱﾄﾞﾚｽを求める
	clr.w	d1
	asr.l	#6,d1
	add.l	d5,d1
	lsr.w	#2,d1
	move.b	d4,d1			* 下位ﾊﾞｲﾄに現在のADPCMﾃﾞｰﾀを入れる(意味無し)
	move.l	d1,(a3)+
	addq.b	#1,d4			* 次のADPCMﾃﾞｰﾀ
	bcc	TBLG02
	addq.w	#1,d3			* 次の倍率
	cmpi.w	#VOLWID,d3
	bls	TBLG01
	move.l	a3,d5			* (2)DPCMﾃﾞｰﾀ作成,合計256*4*(64+49+32)=148480ﾊﾞｲﾄ
	lea	DLTTBA(pc),a0		*	(下位4ﾋﾞｯﾄ分)
	move.w	VOLMIN-WK(a6),d4	* 音量ﾚﾍﾞﾙ初期化
	subi.w	#VOLOFS,d4
	move.w	d4,d3
	add.w	d3,d3
	adda.w	d3,a0
	move.w	VOLMAX-WK(a6),d6
	subi.w	#VOLOFS-VOLWID,d6
	moveq	#0,d3
TBLG11:	move.w	(a0)+,d3
	cmpi.w	#VOLCLP,d4		* 変化量の上限を制限
	blt	TBLG12
	subq.l	#2,a0
TBLG12:	move.l	d3,d2			* 下位4ﾋﾞｯﾄのﾃﾞｰﾀを作成
	moveq	#8-1,d0
TBLG13:	cmpi.l	#$3FFFF,d2
	bls	TBLG14
	move.l	#$3FFFF,d2
TBLG14:	ror.l	#3,d2
	move.w	d2,d1
	neg.w	d1
	move.w	d2,(a3)
	move.w	d1,$20(a3)
	move.w	d2,$40(a3)
	move.w	d1,$60(a3)
	move.w	d2,$80(a3)
	move.w	d1,$A0(a3)
	move.w	d2,$C0(a3)
	move.w	d1,$E0(a3)
	move.w	d2,$100(a3)
	move.w	d1,$120(a3)
	move.w	d2,$140(a3)
	move.w	d1,$160(a3)
	move.w	d2,$180(a3)
	move.w	d1,$1A0(a3)
	move.w	d2,$1C0(a3)
	move.w	d1,$1E0(a3)
	move.w	d2,$200(a3)
	move.w	d1,$220(a3)
	move.w	d2,$240(a3)
	move.w	d1,$260(a3)
	move.w	d2,$280(a3)
	move.w	d1,$2A0(a3)
	move.w	d2,$2C0(a3)
	move.w	d1,$2E0(a3)
	move.w	d2,$300(a3)
	move.w	d1,$320(a3)
	move.w	d2,$340(a3)
	move.w	d1,$360(a3)
	move.w	d2,$380(a3)
	move.w	d1,$3A0(a3)
	move.w	d2,$3C0(a3)
	move.w	d1,$3E0(a3)
	addq.l	#4,a3
	rol.l	#3,d2
	add.l	d3,d2
	add.l	d3,d2
	dbra	d0,TBLG13
	lea	$3E0(a3),a3
	addq.w	#1,d4
	cmp.w	d6,d4
	ble	TBLG11
	movea.l	d5,a3			* (3)DPCMﾃﾞｰﾀ作成2(上位4ﾋﾞｯﾄ分)
	movea.l	d5,a0			* ﾃｰﾌﾞﾙの先頭ｱﾄﾞﾚｽに戻す
	movea.l	a0,a2
	moveq	#VOLWID,d3
	add.w	VOLMAX-WK(a6),d3
	sub.w	VOLMIN-WK(a6),d3
	swap	d3
	lsr.l	#6,d3
	adda.l	d3,a2
	addq.l	#2,a3
	move.w	VOLMIN-WK(a6),d4
	subi.w	#VOLOFS,d4
TBLG31:	moveq	#0,d3
TBLG32:	move.b	d3,d0			* 下位4ﾋﾞｯﾄによるﾃﾞｰﾀを求める
	andi.w	#$F,d0
	add.w	d0,d0
	move.w	(a1,d0.w),d0
	move.w	VOLMIN-WK(a6),d2
	subi.w	#VOLOFS,d2
	add.w	d0,d2
	lsl.w	#8,d0
	sub.w	d3,d0
	ext.l	d0
	lsl.l	#2,d0
	moveq	#0,d5			* 上位4ﾋﾞｯﾄによるｵﾌｾｯﾄを求める
	move.b	d3,d5
	andi.w	#$F0,d5
	lsr.w	#2,d5
	add.l	d5,d0
	moveq	#VOLWID,d1
	add.w	VOLMAX-WK(a6),d1
	sub.w	VOLMIN-WK(a6),d1
	movea.l	a3,a4
TBLG33:	cmp.w	d4,d2			* 範囲制限(VOLMIN～VOLLIM)
	blt	TBLG34
	cmp.w	d6,d2
	bgt	TBLG35
	move.w	-2(a4,d0.l),(a4)	* ﾃﾞｰﾀ設定(変化先の値を複写する)
	lea	$400(a4),a4
	addq.w	#1,d2
	dbra	d1,TBLG33
	bra	TBLG36
TBLG34:	move.w	(a0,d5.l),(a4)		* 下方向のｸﾘｯﾌﾟ(最下位のﾃｰﾌﾞﾙを参照)
	lea	$400(a4),a4
	addq.w	#1,d2
	dbra	d1,TBLG33
	bra	TBLG36
TBLG35:	move.w	(a2,d5.l),(a4)		* 上方向のｸﾘｯﾌﾟ(最上位のﾃｰﾌﾞﾙを参照)
	lea	$400(a4),a4
	addq.w	#1,d2
	dbra	d1,TBLG33
TBLG36:	addq.l	#4,a3
	addq.b	#1,d3
	bcc	TBLG32
	lea	$400(a2),a3
	movem.l	(sp)+,d0-d6/a0-a2/a4
	rts

HEXCNV:	movem.l	d0-d2/a0,-(sp)		* 16進文字列変換,D0.W→(A0)～2ﾊﾞｲﾄ
	moveq	#2-1,d2
	tst.w	d0
	bmi	HEXCN4
HEXCN1:	rol.b	#4,d0
	moveq	#$F,d1
	and.b	d0,d1
	addi.b	#'0',d1
	cmpi.b	#'9',d1
	bls	HEXCN2
	addi.b	#'A'-'9'-1,d1
HEXCN2:	move.b	d1,(a0)+
	dbra	d2,HEXCN1
HEXCN3:	movem.l	(sp)+,d0-d2/a0
	rts

HEXCN4:	move.b	#'?',(a0)+
	dbra	d2,HEXCN4
	bra	HEXCN3

DECCNV:	movem.l	d0-d4/a0-a1,-(sp)	* 10進文字列変換,D0.W→(A0)～3ﾊﾞｲﾄ
	tst.w	d0
	bmi	DECCN8
	lea	DECTBL(pc),a1
	andi.w	#$FF,d0
	moveq	#0,d4
	bra	DECCN5
DECCN1:	move.w	(a1)+,d1
	moveq	#0,d3
DECCN2:	add.b	d3,d3
	cmp.w	d1,d0
	bcs	DECCN3
	sub.w	d1,d0
	addq.b	#1,d3
DECCN3:	lsr.w	#1,d1
	dbra	d2,DECCN2
	or.b	d3,d4
	bne	DECCN4
	moveq	#' '-'0',d3		* 頭の0は空白にする
DECCN4:	addi.b	#'0',d3
	move.b	d3,(a0)+
DECCN5:	move.w	(a1)+,d2
	bpl	DECCN1
DECCN6:	addi.b	#'0',d0
	move.b	d0,(a0)
DECCN7:	movem.l	(sp)+,d0-d4/a0-a1
	rts

DECCN8:	moveq	#3-1,d0
DECCN9:	move.b	#'?',(a0)+
	dbra	d0,DECCN9
	bra	DECCN7

	.data

*		↓これらの値は 32768/1.1^(80-n) の解の小数点未満を切り捨てたもの
*		  (ちなみに PCM8.X のテーブルは7捨8入した値になっている)
DLTTB1:	.dc.w	   0,   0,   0,   0,   0,   0,   0,   0		* -64...-57
	.dc.w	   0,   0,   0,   0,   0,   0,   0,   0		* -56...-49
	.dc.w	   0,   0,   0,   0,   0,   0,   0,   0		* -48...-41
	.dc.w	   0,   0,   0,   0,   0,   0,   0,   0		* -40...-33
	.dc.w	   0,   0,   0,   1,   1,   1,   1,   1		* -32...-25
	.dc.w	   1,   1,   1,   2,   2,   2,   2,   3		* -24...-17
	.dc.w	   3,   3					* -16...-15
DLTTBX:	.dc.w	             4,   4,   5,   5,   6,   6		* -14... -9
	.dc.w	   7,   8,   9,   9,  10,  12,  13,  14		*  -8... -1
DLTTBA:	.dc.w	  15,  17,  19,  21,  23,  25,  28,  31		*   0...  7
	.dc.w	  34,  37,  41,  45,  50,  55,  60,  66		*   8... 15
	.dc.w	  73,  80,  88,  97, 107, 118, 130, 143		*  16... 23
	.dc.w	 157, 173, 190, 209, 230, 253, 279, 307		*  24... 31
	.dc.w	 337, 371, 408, 449, 494, 543, 598, 658		*  32... 39
	.dc.w	 724, 796, 876, 963,1060,1166,1282,1410		*  40... 47
	.dc.w	1551,1707,1877,2065,2272,2499,2749,3024		*  48... 55
	.dc.w	3326,3659,4025,4427,4870,5357,5893,6482		*  56... 63
	.dc.w	7131,7844,8628,9491,10440,11484,12633,13896	*  64... 71
	.dc.w	15286,16815,18496,20346,22380,24619,27080,29789	*  72... 79

DLTTB2:	.dc.w	-1,-1,-1,-1, 2, 4, 6, 8
	.dc.w	-1,-1,-1,-1, 2, 4, 6, 8

DLTTB3:	.dc.w	 2,-1
	.dc.w	 4,-1
	.dc.w	 6,-1
	.dc.w	 8,-1
	.dc.w	10, 2
	.dc.w	12, 4
	.dc.w	14, 6
	.dc.w	16, 8

DECTBL:	.dc.w	1,200
	.dc.w	3,80
	.dc.w	-1

TTLME1:	.dc.b	13,10
TTLMES:	.dc.b	'X68k PCM8A polyphonic ADPCM driver v1.02.1 '			*;version
	.dc.b	'(c)1993-97 philly',13,10,0
USEMES:	.dc.b	'使用法：PCM8A [<ｽｲｯﾁ>]',13,10
	.dc.b	'<ｽｲｯﾁ>',9,'ON',9,': 多重再生ﾓｰﾄﾞ(通常)',13,10
	.dc.b	9,'OFF',9,': 単音再生ﾓｰﾄﾞ',13,10
	.dc.b	9,'FNC',9,': IOCSのみ単音再生ﾓｰﾄﾞ',13,10
	.dc.b	9,'CLR',9,': 全ﾁｬﾝﾈﾙを初期化',13,10
	.dc.b	9,'-R',9,': 常駐解除',13,10
	.dc.b	9,'-D[n]',9,': 動作表示 ON/OFF (通常:0)',13,10
	.dc.b	9,9,'  n = 0:OFF , 1:ON , 省略:ON/OFFの反転',13,10
	.dc.b	9,'-V[n]',9,': 音量変換 ON/OFF (通常:1)',13,10
	.dc.b	9,9,'  n = 0:OFF , 1:ON , 省略:ON/OFFの反転',13,10
	.dc.b	9,'-In',9,': IOCSで使用するﾁｬﾝﾈﾙ数 (通常:8)',13,10
	.dc.b	9,9,'  n = 0～9 (0:IOCS出力を禁止)',13,10
	.dc.b	9,'-S[n1],[n2],[n3],[n4] : ｼｽﾃﾑ状態の設定',13,10
	.dc.b	9,9,'  n1= ﾁｬﾝﾈﾙ数  (1～32,通常:25)',13,10
	.dc.b	9,9,'  n2= 処理ﾊﾞｲﾄ数/12 (1～12,通常:4)',13,10
	.dc.b	9,9,'  n3= 最小音量 (0～15,$40～$A0,通常:$40)',13,10
	.dc.b	9,9,'  n4= 最大音量 (0～15,$40～$A0,通常:$A0)',13,10
	.dc.b	9,'-Wn',9,': ﾊﾞｯﾌｧ/ﾃｰﾌﾞﾙの分離 (常駐時のみ有効)',13,10
	.dc.b	9,9,'  n = 1～31 (ﾋﾞｯﾄ0～4で分離する領域を指定)',13,10
	.dc.b	9,'-M[n]',9,': ADPCM動作ﾓｰﾄﾞ (通常:0)',13,10
	.dc.b	9,9,'  n = 0:4M/8M , 1:16M/8M , 2～4:4M/8M/16M (Hz)',13,10
	.dc.b	9,9,'      A:自動判定 , 省略:環境変数(OPM_CT1)参照',13,10
	.dc.b	9,9,9,'(1～4はADPCMをｸﾛｯｸｱｯﾌﾟ改造してある場合に有効)',13,10
	.dc.b	9,'-F[n]',9,': ADPCM動作周波数 (通常:0)',13,10
	.dc.b	9,9,'  n = 0:15.6k , 1:20.8k , 2:31.2k',13,10
	.dc.b	9,9,'      4: 3.9k , 5: 5.2k , 6: 7.8k , 7:10.4k (Hz)',13,10
	.dc.b	9,9,'      省略:最高周波数(-Mｽｲｯﾁの指定に依存する)',13,10
	.dc.b	9,9,9,'(1,2はADPCMをｸﾛｯｸｱｯﾌﾟ改造してある場合に有効)',13,10
	.dc.b	9,'〈常駐状態での設定変更が可能です〉',13,10
	.dc.b	0

KERMES:	.dc.b	'《常駐を拒否されました》',13,10,0
KEMMES:	.dc.b	'《メモリが足りないので常駐できません》',13,10,0
KRDMES:	.dc.b	'《既に常駐しています》',13,10,0
REXMES:	.dc.b	'《常駐していません》',13,10,0
RELMES:	.dc.b	'《常駐を解除しました》',13,10,0
RERMES:	.dc.b	'《ベクタが変更されているので常駐を解除できません》',13,10,0
RENMES:	.dc.b	'《解除が禁止されています》',13,10,0
DIEMES:	.dc.b	'《組み込みを拒否されました》',13,10,0
DRDMES:	.dc.b	'《既に組み込まれています》',13,10,0
DOTMES:	.dc.b	'《解除しました》',13,10,0
DOEMES:	.dc.b	'《ベクタが変更されているので解除できません》',13,10,0
DERMES:	.dc.b	'《組み込みができません》',13,10,0
SWEMES:	.dc.b	'《スイッチの指定に誤りがあります》',13,10,0
CNGMES:	.dc.b	'《設定を変更しました》',13,10,0
CLRMES:	.dc.b	'《内部を初期化しました》',13,10,0
OTHMES:	.dc.b	'《他のADPCMドライバが常駐しています》',13,10
DMYMES:	.dc.b	0

STAMES:	.dc.b	'多重再生モード  ：'
STAM01:	.dc.b	'OFF',13,10
	.dc.b	'動作表示モード  ：'
STAM02:	.dc.b	'OFF',13,10
	.dc.b	'音量変換モード  ：'
STAM03:	.dc.b	'OFF',13,10
	.dc.b	'IOCSチャンネル数：'
STAN01:	.dc.b	'000',13,10
	.dc.b	'有効チャンネル数：'
STAN02:	.dc.b	'000',13,10
	.dc.b	'処理バイト数    ：'
STAN03:	.dc.b	'000',13,10
	.dc.b	'最小音量値      ：$'
STAH01:	.dc.b	'00',13,10
	.dc.b	'最大音量値      ：$'
STAH02:	.dc.b	'00',13,10
	.dc.b	'ADPCM動作モード ：'
STAN10:	.dc.b	'000',13,10
	.dc.b	'ADPCM動作周波数 ：'
STAM10:	.dc.b	'15.6kHz',13,10
	.dc.b	'常駐モード      ：'
STAM11:	.dc.b	'コマンドライン  ',13,10
	.dc.b	'ＰＣＭ８占有    ：'
STAM04:	.dc.b	'OFF',13,10
	.dc.b	'ＭＰＣＭ占有    ：'
STAM05:	.dc.b	'OFF',13,10,0
MPCMES:	.dc.b	'占有しているアプリケーション'
CRLF:	.dc.b	13,10,0

STAMB0:	.dc.b	'OFF',0
	.dc.b	'ON ',0
	.dc.b	'FNC',0
	.dc.b	'???',0,0
STAMF0:	.dc.b	' 3.9',0
	.dc.b	' 5.2',0
	.dc.b	' 7.8',0
	.dc.b	'10.4',0
	.dc.b	'15.6',0
	.dc.b	'20.8',0
	.dc.b	'31.2',0
	.dc.b	'????',0,0
STAMJ0:	.dc.b	'コマンドライン  ',0
	.dc.b	'デバイスドライバ',0,0

DEVNUL:	.dc.b	'NUL     '		* ﾃﾞﾊﾞｲｽ名
DEVNA1:	.dc.b	'PCM     '
DEVNA2:	.dc.b	'@PCM    '

ADPMOD:	.dc.b	'OPM_CT1',0

	.bss

WKBUF:	.ds.b	WKSIZ
WKBUFE:	.ds.b	10

	.even
LASTAD:

	.end	START
