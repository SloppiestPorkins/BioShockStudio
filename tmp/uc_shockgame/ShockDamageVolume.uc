class ShockDamageVolume extends Volume
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Force,LightColor,Lighting,Sound,Object);

var float DamagePerSecond;
var float DelayBetweenDamage;
var DamageStimuliSet.DamageStimulusType DamageType;
var private bool bVolumeEnabled;
var VolumeTimer PainTimer;

function Touch(Actor Other)
{
	local Pawn P;
	local bool bFoundPawn;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x141
	/*@Error*/
	// End:0x4E
	if(Other.bDestroyInPainVolume)
	{
		Other.__NFUN_279__();
		return;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x141
		/*@Error*/
	}
	ApplyDamage(Other);
	// End:0xC0
	if(__NFUN_114__(PainTimer, none))
	{
		PainTimer = __NFUN_278__(Class'Engine.VolumeTimer', self);
		PainTimer.__NFUN_280__(DelayBetweenDamage, true);
		goto J0x141;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x141
		/*@Error*/
		// End:0x117
		foreach __NFUN_307__(Class'Engine.Pawn', P)
		{
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x116
			/*@Error*/
			bFoundPawn = true;
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x09C! */
		goto J0x117;				
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x141
		/*@Error*/
		PainTimer.__NFUN_280__(DelayBetweenDamage, true);
		return;
		@NULL
		Item
		stop;
		default.@NULL
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x05D! */
}

function ApplyDamage(Actor Other)
{
	local ShockPawn PawnOther;

	assert(bVolumeEnabled);
	PawnOther = ShockPawn(Other);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x139
	/*@Error*/
	// End:0x8A
	if(__NFUN_130__(Region.Zone.bSoftKillZ, __NFUN_155__(int(Other.Physics), int(2))))
	{
		return;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x139
		/*@Error*/
		log('Damage', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Doing ", string(__NFUN_171__(DamagePerSecond, DelayBetweenDamage))), " damage of type "), string(DamageType)), " to "), string(PawnOther)));
	}
	PawnOther.TakeSimpleDamage(DamageType, __NFUN_171__(DamagePerSecond, DelayBetweenDamage), 1.0000000, self);
	return;
	@NULL
	Item
	Item
	@NULL
}

function TimerPop(VolumeTimer t)
{
	local Actor A;
	local bool bFound;

	assert(__NFUN_114__(t, PainTimer));
	// End:0x38
	if(__NFUN_129__(bVolumeEnabled))
	{
		PainTimer.__NFUN_279__();
		return;
		// End:0x70
		foreach __NFUN_307__(Class'Engine.Actor', A)
		{
			ApplyDamage(A);
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x028! */
		bFound = true;				
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x90
		/*@Error*/
		PainTimer.__NFUN_279__();
		return;
		@NULL
		Item
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x00F! */
	Item
	@NULL
}

function EnableVolume()
{
	local Actor A;

	bVolumeEnabled = true;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x69
	/*@Error*/
	// End:0x68
	foreach __NFUN_307__(Class'Engine.Actor', A)
	{
		PainTimer = __NFUN_278__(Class'Engine.VolumeTimer', self);
		PainTimer.__NFUN_280__(DelayBetweenDamage, true);		
		return;				
		return;
		@NULL
		Item
		Item
		@NULL
	}
}

function DisableVolume()
{
	bVolumeEnabled = false;
	return;
	@NULL
}

defaultproperties
{
	DelayBetweenDamage=1.0000000
	bVolumeEnabled=true
}