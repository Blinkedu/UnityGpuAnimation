using System;
using UnityEngine;

[Serializable]
public class GpuAnimationClip
{
    public string name;
    public int startFrameIndex;
    public int frameCount;
    public float frameRate;
    public float lenght;
    public bool isLoop;
}

public class GpuAnimationData : ScriptableObject
{
    public GpuAnimationClip[] clips;
}
