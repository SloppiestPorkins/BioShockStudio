class MediumSecurityBot extends SecurityBot
	abstract
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

defaultproperties
{
	DormantString="Security Bot (Disabled)"
	DeactivatedString="Security Bot (Deactivated)"
	DesiredRangeWhileAttacking=(Min=400.0000000,Max=600.0000000)
	DesiredHeightWhileAttacking=(Min=50.0000000,Max=500.0000000)
	MaximumAttackRange=1600.0000000
	MinRandomPointDistanceFromTarget=300.0000000
	BurstIntervalRange=(Min=2.0000000,Max=7.0000000)
	DormantDuration=240.0000000
	BotLifeSpanAfterDeath=1.0000000
	FriendlyName="Security Bot"
	FOV=90.0000000
	DamageResistanceSetName="SecurityBotResistanceSet"
	MaxHealth=300.0000000
	MaxFrozenHealth=150.0000000
	Health=300.0000000
}