using UnityEngine;


public class GpuAnimationPlayer : MonoBehaviour
{
    public GpuAnimationClip[] Clips
    {
        get { return m_Data.clips; }
    }

    public MeshRenderer MeshRenderer
    {
        get { return m_MeshRenderer; }
    }

    public MaterialPropertyBlock MaterialPropertyBlock
    {
        get { return m_MaterialPropertyBlock; }
    }

    [SerializeField]
    private GpuAnimationData m_Data;

    private MaterialPropertyBlock m_MaterialPropertyBlock;
    private MeshRenderer m_MeshRenderer;

    private int m_ShaderPropID_StartIndex;
    private int m_ShaderPropID_FrameRate;
    private int m_ShaderPropID_AnimFrameCount;

    private void Awake()
    {
        m_ShaderPropID_StartIndex = Shader.PropertyToID("_StartIndex");
        m_ShaderPropID_FrameRate = Shader.PropertyToID("_FrameRate");
        m_ShaderPropID_AnimFrameCount = Shader.PropertyToID("_AnimFrameCount");

        m_MeshRenderer = GetComponent<MeshRenderer>();
        m_MaterialPropertyBlock = new MaterialPropertyBlock();
        m_MeshRenderer.GetPropertyBlock(m_MaterialPropertyBlock);
    }

    public void Play(string name)
    {
        var clip = GetClip(name);
        if (clip != null)
        {
            UpdateMaterialPropertyBlock(clip);
        }
    }

    public void Play(int index)
    {
        var clip = GetClip(index);
        if (clip != null)
        {
            UpdateMaterialPropertyBlock(clip);
        }
    }

    private GpuAnimationClip GetClip(string name)
    {
        foreach (var clip in m_Data.clips)
        {
            if (clip.name.Equals(name))
            {
                return clip;
            }
        }
        return null;
    }

    public void SetData(GpuAnimationData data)
    {
        m_Data = data;
    }

    private GpuAnimationClip GetClip(int index)
    {
        if (m_Data != null)
        {
            return m_Data.clips[index];
        }
        return null;
    }

    private void UpdateMaterialPropertyBlock(GpuAnimationClip clip)
    {
        m_MaterialPropertyBlock.SetInt(m_ShaderPropID_StartIndex, clip.startFrameIndex);
        m_MaterialPropertyBlock.SetInt(m_ShaderPropID_AnimFrameCount, clip.frameCount);
        m_MaterialPropertyBlock.SetFloat(m_ShaderPropID_FrameRate, clip.frameRate);
        m_MeshRenderer.SetPropertyBlock(m_MaterialPropertyBlock);
    }
}

