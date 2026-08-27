class TriggerVolume extends PhysicsVolume
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Force,LightColor,Lighting,Sound,Object);

var() array< Class<Pawn> > TriggerOnlyByClass;
var() array<name> TriggerOnlyByLabel;
var() bool TriggerOnlyOnce;
var() bool OnlyTriggerForLivingPawns;
var() bool Disabled;
var() bool DropPriorityOnFirstEnterIfTriggerOnlyOnce;
var private bool AlreadyTriggeredEntered;
var private bool AlreadyTriggeredLeaving;

function PawnEnteredVolume(Pawn Other)
{
	// End:0x2D
	if(__NFUN_132__(Disabled, __NFUN_130__(TriggerOnlyOnce, AlreadyTriggeredEntered)))
	{
		return;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xDB
		/*@Error*/
	}
	dispatchMessage(Class'Scripting.MessageTriggerVolumeEnter'.static.Allocate(self)., construct_NameName(Label, Other.Label));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCF
	/*@Error*/
	Priority = -1000;
	AlreadyTriggeredEntered = true;
	return;
	@NULL
	Variable
	stop;
	default.@NULL
}

function PawnLeavingVolume(Pawn Other)
{
	// End:0x2D
	if(__NFUN_132__(Disabled, __NFUN_130__(TriggerOnlyOnce, AlreadyTriggeredLeaving)))
	{
		return;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x9F
		/*@Error*/
	}
	dispatchMessage(Class'Scripting.MessageTriggerVolumeExit'.static.Allocate(self)., construct_NameName(Label, Other.Label));
	AlreadyTriggeredLeaving = true;
	return;
	@NULL
	Variable
	stop;
	default.@NULL
}

function bool MeetsRestrictions(Pawn Other)
{
	local int i;
	local bool Trigger;

	// End:0x36
	if(__NFUN_130__(OnlyTriggerForLivingPawns, __NFUN_129__(Class'Engine.Pawn'.static.checkAlive(Other))))
	{
		return false;
		// End:0x5A
		if(__NFUN_130__(__NFUN_154__(TriggerOnlyByClass.Length, 0), __NFUN_154__(TriggerOnlyByLabel.Length, 0)))
		{
		}
		return true;
		// End:0xF6
		if(__NFUN_151__(TriggerOnlyByClass.Length, 0))
		{
			Trigger = false;
			i = 0;
		}
		// End:0xE5
		if(__NFUN_150__(i, TriggerOnlyByClass.Length))
		{
			// End:0xD7
			if(__NFUN_258__(Other.Class, TriggerOnlyByClass[i]))
			{
				Trigger = true;
				goto J0xE5;
				__NFUN_163__(i);
				// [Loop Continue]
				goto J0x81;
				// End:0xF6
				if(__NFUN_129__(Trigger))
				{
					return false;
					/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
						
					*/

					// End:0x191
					/*@Error*/
					Trigger = false;
					i = 0;
					/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
						
					*/

					// End:0x180
					/*@Error*/
				}
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x172
				/*@Error*/
			}
		}
	}
	Trigger = true;
	goto J0x180;
	__NFUN_163__(i);
	goto J0x11D;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x191
	/*@Error*/
	return false;
	return true;
	return;
	J0x11D:

	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	OnlyTriggerForLivingPawns=true
	DropPriorityOnFirstEnterIfTriggerOnlyOnce=true
	Priority=1
	BrushColor=(R=255,G=0,B=255,A=0)
}