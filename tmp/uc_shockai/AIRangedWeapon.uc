class AIRangedWeapon extends AIWeapon
	native
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

var private config bool WeaponUsesAimPoses;
var private config Range AccuracyRangeVsPlayer;
var private config Range AccuracyChangeTimeRangeVsPlayer;
var private config Range AccuracyRangeVsAI;
var private config Range AccuracyChangeTimeRangeVsAI;
var private config bool bResetAccuracyWhenStartingBurstFire;
var private Range AccuracyRange;
var private Range AccuracyChangeTimeRange;
var private float AccuracyChangeStartTime;
var private float TimeToCompleteAccuracyChange;
var private float CurrentAccuracy;

function bool HasChangingAccuracy()
{
	return __NFUN_177__(AccuracyChangeTimeRange.Max, 0.0000000);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function ResetChangingAccuracy(ShockPawn Target)
{
	// End:0x56
	if(__NFUN_130__(__NFUN_119__(Target, none), Target.__NFUN_303__('ShockPlayer')))
	{
		AccuracyRange = AccuracyRangeVsPlayer;
		AccuracyChangeTimeRange = AccuracyChangeTimeRangeVsPlayer;
		goto J0x7C;
		AccuracyRange = AccuracyRangeVsAI;
		AccuracyChangeTimeRange = AccuracyChangeTimeRangeVsAI;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x115
		/*@Error*/
	}
	CurrentAccuracy = AccuracyRange.Max;
	AccuracyChangeStartTime = Level.TimeSeconds;
	TimeToCompleteAccuracyChange = RandRange(AccuracyChangeTimeRange.Min, AccuracyChangeTimeRange.Max);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnFiringStarted()
{
	super(Weapon).OnFiringStarted();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5B
	/*@Error*/
	ResetChangingAccuracy(NextWeaponAttackInfo.Target);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function float GetAccuracy()
{
	// End:0xF0
	if(HasChangingAccuracy())
	{
		// End:0x63
		if(__NFUN_179__(Level.TimeSeconds, __NFUN_174__(TimeToCompleteAccuracyChange, AccuracyChangeStartTime)))
		{
			CurrentAccuracy = AccuracyRange.Min;
			goto J0xED;
			CurrentAccuracy = __NFUN_175__(AccuracyRange.Max, __NFUN_172__(__NFUN_171__(__NFUN_175__(AccuracyRange.Max, AccuracyRange.Min), __NFUN_175__(Level.TimeSeconds, AccuracyChangeStartTime)), TimeToCompleteAccuracyChange));
		}
		goto J0x103;
		CurrentAccuracy = BaseAccuracy;
		return Holder.ModifyStat(string(__NFUN_112__(string(Class.Name), "Accuracy_Modifier")), CurrentAccuracy);
		return;
		@NULL
		CommanderAction
		stop;
	}
	default.@NULL
}

function ScriptedSetAccuracyValues(Range inAccuracyRangeVsPlayer, Range inAccuracyChangeTimeRangeVsPlayer, Range inAccuracyRangeVsAI, Range inAccuracyChangeTimeRangeVsAI)
{
	AccuracyRangeVsPlayer = inAccuracyRangeVsPlayer;
	AccuracyChangeTimeRangeVsPlayer = inAccuracyChangeTimeRangeVsPlayer;
	AccuracyRangeVsAI = inAccuracyRangeVsAI;
	AccuracyChangeTimeRangeVsAI = inAccuracyChangeTimeRangeVsAI;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	bUseTargetTrackingLocation=true
}