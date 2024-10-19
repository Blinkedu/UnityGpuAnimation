using System.Collections.Generic;
using UnityEditor;
using UnityEditor.UIElements;
using UnityEngine;
using UnityEngine.UIElements;

public class GpuAnimationSamplerWindow : EditorWindow
{
    [SerializeField]
    private VisualTreeAsset m_VisualTreeAsset = default;

    [SerializeField]
    private List<AnimationClip> m_AnimationClips;
    private SerializedProperty m_AnimationClipsProperty;
    private SerializedObject m_SerializedObject;

    [MenuItem("工具/GpuAnimationSampler")]
    public static void ShowExample()
    {
        GpuAnimationSamplerWindow wnd = GetWindow<GpuAnimationSamplerWindow>();
        wnd.titleContent = new GUIContent("GpuAnimationSamplerWindow");
    }

    private void OnEnable()
    {
        if (m_AnimationClips == null)
        {
            m_AnimationClips = new List<AnimationClip>();
        }
        if (m_SerializedObject == null)
        {
            m_SerializedObject = new SerializedObject(this);
            m_AnimationClipsProperty = m_SerializedObject.FindProperty("m_AnimationClips");
        }
    }

    private void OnDisable()
    {
        m_AnimationClips?.Clear();
    }

    public void CreateGUI()
    {
        VisualElement root = rootVisualElement;
        VisualElement labelFromUXML = m_VisualTreeAsset.Instantiate();
        root.Add(labelFromUXML);

        ObjectField objectFieldInput = root.Q<ObjectField>("Input");
        objectFieldInput.RegisterValueChangedCallback(OnGameObjectChanged);

        PropertyField propertyField = root.Q<PropertyField>("AnimationClips");
        propertyField.BindProperty(m_AnimationClipsProperty);

        Button btnBake = root.Q<Button>("BtnBake");
        btnBake.clicked += OnClickBtnBake;
    }

    private void OnGameObjectChanged(ChangeEvent<Object> evt)
    {
        UpdateAnimtionsClips();

        if (evt.newValue == null)
        {
            rootVisualElement.Q<Button>("BtnBake").SetEnabled(false);
            return;
        }

        rootVisualElement.Q<Button>("BtnBake").SetEnabled(true);
    }

    private void OnClickBtnBake()
    {
        string outputPath = rootVisualElement.Q<TextField>("OutputPath").text;
        if (string.IsNullOrEmpty(outputPath))
        {
            EditorUtility.DisplayDialog("错误", "请设置Output Path!", "确定");
            return;
        }

        Object obj = rootVisualElement.Q<ObjectField>("Input").value;
        string assetPath = AssetDatabase.GetAssetPath(obj);
        bool applyRootMotion = rootVisualElement.Q<Toggle>("ApplyRootMotion").value;
        GpuAnimationSampler.SampleMode sampleMode = (GpuAnimationSampler.SampleMode)rootVisualElement.Q<EnumField>("SampleMode").value;
        Shader shader = rootVisualElement.Q<ObjectField>("Shader").value as Shader;
        int sampleFrameRate = rootVisualElement.Q<IntegerField>("SampleFrameRate").value;

        GpuAnimationSampler.SampleSettings settings = new GpuAnimationSampler.SampleSettings
        {
            assetPath = assetPath,
            outputPath = outputPath,
            sampleMode = sampleMode,
            sampleFrameRate = sampleFrameRate,
            appleRootMation = applyRootMotion,
            shader = shader,
            clips = m_AnimationClips.ToArray()
        };

        GpuAnimationSampler.Bake(settings);
    }

    private void UpdateAnimtionsClips()
    {
        GameObject gameObject = rootVisualElement.Q<ObjectField>("Input").value as GameObject;
        if (gameObject != null)
        {
            AnimationClip[] clips = AnimationUtility.GetAnimationClips(gameObject);
            m_AnimationClips.AddRange(clips);
        }
        else
        {
            m_AnimationClips.Clear();
        }
    }
}
