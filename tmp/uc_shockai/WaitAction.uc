class WaitAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

state Running
{Begin:

	stop;			
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.WaitGoal'
	bExclusiveAction=true
}