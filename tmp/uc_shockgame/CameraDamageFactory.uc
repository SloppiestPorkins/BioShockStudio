class CameraDamageFactory extends DamageFactory
	native
	config(ResearchCamera);

struct native atomic PhotoScoreMapping
{
	var int Score;
	var float Value;
};

var config array<PhotoScoreMapping> CenteringScoreMapping;
var config array<PhotoScoreMapping> SizeScoreMapping;
var config array<PhotoScoreMapping> RepeatPenaltyMapping;
var config int DeadSubjectPenalty;
var config int LowScoreCutoff;
var config int BonusPerSubject;

function CalculatePhoto(ShockPlayer thePlayer, out PhotoScore PhotoScore, out IPhotographTarget PhotoSubject)
{
	//native.thePlayer;
	//native.PhotoScore;
	//native.PhotoSubject;	
	@NULL
	@NULL
	return default.@NULL;
}

defaultproperties
{
	CenteringScoreMapping[0]=(Score=0,Value=0.0000000)
	CenteringScoreMapping[1]=(Score=1,Value=0.0500000)
	CenteringScoreMapping[2]=(Score=2,Value=0.1000000)
	CenteringScoreMapping[3]=(Score=3,Value=0.1500000)
	CenteringScoreMapping[4]=(Score=4,Value=0.2000000)
	CenteringScoreMapping[5]=(Score=5,Value=0.2500000)
	CenteringScoreMapping[6]=(Score=7,Value=0.3000000)
	CenteringScoreMapping[7]=(Score=11,Value=0.3500000)
	CenteringScoreMapping[8]=(Score=14,Value=0.4000000)
	CenteringScoreMapping[9]=(Score=17,Value=0.4500000)
	CenteringScoreMapping[10]=(Score=20,Value=0.5000000)
	CenteringScoreMapping[11]=(Score=23,Value=0.5500000)
	CenteringScoreMapping[12]=(Score=26,Value=0.6000000)
	CenteringScoreMapping[13]=(Score=29,Value=0.6500000)
	CenteringScoreMapping[14]=(Score=32,Value=0.7000000)
	CenteringScoreMapping[15]=(Score=35,Value=0.7500000)
	CenteringScoreMapping[16]=(Score=38,Value=0.8000000)
	CenteringScoreMapping[17]=(Score=41,Value=0.8500000)
	CenteringScoreMapping[18]=(Score=44,Value=0.9000000)
	CenteringScoreMapping[19]=(Score=47,Value=0.9500000)
	CenteringScoreMapping[20]=(Score=50,Value=1.0000000)
	SizeScoreMapping[0]=(Score=0,Value=0.0000000)
	SizeScoreMapping[1]=(Score=5,Value=0.0500000)
	SizeScoreMapping[2]=(Score=10,Value=0.1000000)
	SizeScoreMapping[3]=(Score=15,Value=0.1500000)
	SizeScoreMapping[4]=(Score=20,Value=0.2000000)
	SizeScoreMapping[5]=(Score=26,Value=0.2500000)
	SizeScoreMapping[6]=(Score=29,Value=0.3000000)
	SizeScoreMapping[7]=(Score=32,Value=0.3500000)
	SizeScoreMapping[8]=(Score=35,Value=0.4000000)
	SizeScoreMapping[9]=(Score=38,Value=0.4500000)
	SizeScoreMapping[10]=(Score=41,Value=0.5000000)
	SizeScoreMapping[11]=(Score=44,Value=0.5500000)
	SizeScoreMapping[12]=(Score=47,Value=0.6000000)
	SizeScoreMapping[13]=(Score=50,Value=0.6500000)
	SizeScoreMapping[14]=(Score=50,Value=0.7000000)
	SizeScoreMapping[15]=(Score=47,Value=0.7500000)
	SizeScoreMapping[16]=(Score=44,Value=0.8000000)
	SizeScoreMapping[17]=(Score=41,Value=0.8500000)
	SizeScoreMapping[18]=(Score=38,Value=0.9000000)
	SizeScoreMapping[19]=(Score=24,Value=0.9500000)
	SizeScoreMapping[20]=(Score=15,Value=1.0000000)
	RepeatPenaltyMapping[0]=(Score=0,Value=0.0000000)
	RepeatPenaltyMapping[1]=(Score=30,Value=1.0000000)
	RepeatPenaltyMapping[2]=(Score=45,Value=2.0000000)
	RepeatPenaltyMapping[3]=(Score=60,Value=3.0000000)
	RepeatPenaltyMapping[4]=(Score=75,Value=4.0000000)
	RepeatPenaltyMapping[5]=(Score=90,Value=5.0000000)
	RepeatPenaltyMapping[6]=(Score=5000,Value=6.0000000)
	DeadSubjectPenalty=40
	LowScoreCutoff=30
	BonusPerSubject=10
}