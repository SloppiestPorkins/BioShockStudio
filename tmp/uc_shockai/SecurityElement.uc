class SecurityElement extends ShockAI
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

var config array<name> DontAttackWithControllablesStimuliSetNames;

event OnSecuritySystemActive()
{
	return;
}

event OnSecuritySystemInactive()
{
	return;
}

event OnSecurityAlarmOn(ShockPawn AlarmTarget)
{
	return;
}

event OnSecurityAlarmOff(bool TurnedOffBySecurityStation, bool CleanupSecurityImmediately)
{
	return;
}

event OnSecurityBeaconApplied(Actor Damager, ShockPawn SecurityBeaconTarget)
{
	return;
}

event OnAlarmTargetChanged(ShockPawn NewTarget)
{
	return;
}

function bool ShouldBeAttackedByControllablesWhenAttacked(ShockPawn DamagingPawn, DamageStimuliSet DamageStimuli)
{
	local int i;

	i = 0;
	// End:0x62
	if(__NFUN_150__(i, DontAttackWithControllablesStimuliSetNames.Length))
	{
		// End:0x54
		if(__NFUN_254__(DontAttackWithControllablesStimuliSetNames[i], DamageStimuli.GetStimuliSetName()))
		{
			return false;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x0B;
			return super(ShockPawn).ShouldBeAttackedByControllablesWhenAttacked(DamagingPawn, DamageStimuli);
		}
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

defaultproperties
{
	DontAttackWithControllablesStimuliSetNames[0]="IcicleAssaultStimuliSet"
	DontAttackWithControllablesStimuliSetNames[1]="IcicleAssaultTwoStimuliSet"
	DontAttackWithControllablesStimuliSetNames[2]="IcicleAssaultThreeStimuliSet"
	DontAttackWithControllablesStimuliSetNames[3]="ElectricBoltStimuliSet"
	DontAttackWithControllablesStimuliSetNames[4]="ElectricBoltTwoStimuliSet"
	DontAttackWithControllablesStimuliSetNames[5]="ElectricBoltThreeStimuliSet"
}