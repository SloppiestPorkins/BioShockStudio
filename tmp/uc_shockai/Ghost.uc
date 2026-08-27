class Ghost extends ShockAI
	abstract
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

function AddCommanderAbility()
{
	assert(__NFUN_119__(CharacterAI, none));
	CharacterAI.addAbility_Class(Class'ShockAI.ScriptedAICommanderAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function MovementAICreated()
{
	super.MovementAICreated();
	MovementAI.addAbility_Class(Class'ShockAI.MoveToAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function CharacterAICreated()
{
	super.CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.CharacterMoveToAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function int GetDesiredAnimationCapabilities()
{
	return __NFUN_158__(super.GetDesiredAnimationCapabilities(), 64);
	return;
	@NULL
}

defaultproperties
{
	bShouldUseLocomotion=true
	bRotateToDesired=false
}