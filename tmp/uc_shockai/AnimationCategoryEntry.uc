class AnimationCategoryEntry extends Object
	native
	config(Spawning)
	perobjectconfig;

struct native atomic AIAnimInfo
{
	var config name AIClassName;
	var config name AnimationName;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var config array<AIAnimInfo> AIAnimInfos;
