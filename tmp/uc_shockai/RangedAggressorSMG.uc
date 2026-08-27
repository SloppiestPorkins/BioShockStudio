class RangedAggressorSMG extends RangedAggressor
	abstract
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

function AddInitialKeywords()
{
	super(Aggressor).AddInitialKeywords();
	AddLocomotionKeyword('RangedAggressorSMG', Class'ShockAI.ShockAI'.0);
	GetRagdoll().AddRequiredRiseFromRagdollKeyword('RangedAggressorSMG');
	return;
	@NULL
	CommanderAction
}

function CharacterAICreated()
{
	super(Aggressor).CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.RangedAggressorSMGAttackAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}
