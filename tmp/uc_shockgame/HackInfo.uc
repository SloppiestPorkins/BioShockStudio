class HackInfo extends DeletableObject
	native
	config(Hacking)
	perobjectconfig;

struct native atomic HackingGameTile
{
	var config string Type;
	var config int Row;
	var config int Column;
};

var config int HackCost;
var config int MinimumHackingLevel;
var config float InitSpeed;
var config float SlowSpeed;
var config float NormalSpeed;
var config float FastSpeed;
var config float TradeSpeed;
var config int TotalPieces;
var config int CheckPointCount;
var config int StraightHCount;
var config int StraightVCount;
var config int ElbowTRCount;
var config int ElbowBRCount;
var config int ElbowTLCount;
var config int ElbowBLCount;
var config int AlarmCount;
var config int ResistorVCount;
var config int ResistorHCount;
var config int ShortCircuitCount;
var config int AcceleratorHCount;
var config int AcceleratorVCount;
var config int StartRow;
var config int StartColumn;
var config int EndRow;
var config int EndColumn;
var config int WinRow;
var config int WinColumn;
var config float DamageDealtOnOverload;
var config float DamageDealtOnShortCircuit;
var int HackingHandSize;
var bool CanRotate;
var bool HackPurchaseOptionEnabled;
var config float MinimumPurchaseOptionCost;
var config localized string AlarmBotType;
var config int AlarmBotCount;
var config array<HackingGameTile> RevealedTile;

defaultproperties
{
	DamageDealtOnOverload=30.0000000
	DamageDealtOnShortCircuit=5.0000000
	HackingHandSize=1
	HackPurchaseOptionEnabled=true
	MinimumPurchaseOptionCost=1.0000000
	AlarmBotType="ShockAIClasses.SpawnedMediumSecurityBotA"
	AlarmBotCount=3
}