class AnimNotify_InitiateDamage extends AnimNotify
	native
	config(ShockGame)
	editinlinenew
	collapsecategories
	hidecategories(Object);

var name EffectEventName;
var config array<name> DefaultEffectEventNames;

function PopulateEffectEventNames(LevelInfo Level, out array<name> ResultArray)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x58
	/*@Error*/
	ResultArray[i] = DefaultEffectEventNames[i];
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	DefaultEffectEventNames[0]="HitNoDirection"
	DefaultEffectEventNames[1]="HitLeftToRight"
	DefaultEffectEventNames[2]="HitRightToLeft"
	DefaultEffectEventNames[3]="HitHighToLow"
	DefaultEffectEventNames[4]="HitLowToHigh"
	DefaultEffectEventNames[5]="BigKnockDown"
	DefaultEffectEventNames[6]="BigRightHook"
	DefaultEffectEventNames[7]="BigLeftHook"
}