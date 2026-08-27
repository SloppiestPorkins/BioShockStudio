class HealthAdvisor extends DifficultyAdvisor
	config(Difficulty);

function int AssessInternal(ShockPlayer Player, out int BaseEase)
{
	local array<DifficultyStat> CheckedStats;

	CheckedStats[0] = DifficultyManager.DifficultyStatsManager.TotalHealthStats;
	return DifficultyEvaluator.Evaluate(CheckedStats, DifficultyManager, BaseEase);
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

defaultproperties
{
	AdjustmentRecommendations[0]=(AdjustmentClass=Class'ShockGame.SpawnMedHypoAdjustment',ProbabilityTableName="DefaultProbabilityTable",Count=10,Priority=10,Weight=-1.0000000)
	AdjustmentRecommendations[1]=(AdjustmentClass=Class'ShockGame.RemoveMedHypoAdjustment',ProbabilityTableName="DefaultProbabilityTable",Count=0,Priority=9,Weight=1.0000000)
	DifficultyEvaluatorClass=Class'ShockGame.EaseTableEvaluator'
	DifficultyEvaluatorName="HealthEaseTableEvaluator"
	CreditsNeededToBeConsideredRich=100
	AdvisorCategory="Health"
}