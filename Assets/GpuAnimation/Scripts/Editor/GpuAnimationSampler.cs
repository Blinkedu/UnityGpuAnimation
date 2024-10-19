using System.IO;
using UnityEditor;
using UnityEngine;
using System.Collections.Generic;

public class GpuAnimationSampler
{
    /// <summary>
    /// 采样模式
    /// </summary>
    public enum SampleMode
    {
        Bones = 0,
        Vertices = 1,
    }

    /// <summary>
    /// 采样设置
    /// </summary>
    public class SampleSettings
    {
        public string assetPath;
        public string outputPath;
        public SampleMode sampleMode;
        public int sampleFrameRate;
        public bool appleRootMation;
        public Shader shader;
        public AnimationClip[] clips;

        public override string ToString()
        {
            System.Text.StringBuilder builder = new System.Text.StringBuilder();
            builder.AppendLine($"assetPath = {assetPath}");
            builder.AppendLine($"outputPath = {outputPath}");
            builder.AppendLine($"sampleMode = {sampleMode}");
            builder.AppendLine($"sampleFrameRate = {sampleFrameRate}");
            builder.AppendLine($"appleRootMation = {appleRootMation}");
            return builder.ToString();
        }
    }

    internal static void Bake(SampleSettings settings)
    {
        GameObject tempModel = PrefabUtility.LoadPrefabContents(settings.assetPath);
        try
        {
            tempModel.transform.SetPositionAndRotation(Vector3.zero, Quaternion.identity);

            // 记录初始位置
            Vector3 originalPosition = tempModel.transform.position;
            Quaternion originalRotation = tempModel.transform.rotation;

            SkinnedMeshRenderer skinnedMeshRenderer = tempModel.GetComponentInChildren<SkinnedMeshRenderer>();
            skinnedMeshRenderer.forceMatrixRecalculationPerRender = true;

            // GPU动画片段列表
            GpuAnimationClip[] gpuAnimClips = new GpuAnimationClip[settings.clips.Length];
            // 动画贴图颜色列表
            List<Color> animTexColors = new List<Color>();

            // 记录所有动画片段的总帧数
            int totalFrameCount = 0;

            AnimationMode.StartAnimationMode();
            for (int i = 0; i < settings.clips.Length; i++)
            {
                var animClip = settings.clips[i];
                var frameRate = settings.sampleFrameRate > 0 ? settings.sampleFrameRate : animClip.frameRate;
                var frameCount = (int)(animClip.length * frameRate);
                // GPU动画片段数据
                var gpuAnimClip = new GpuAnimationClip
                {
                    name = animClip.name,
                    startFrameIndex = totalFrameCount,
                    frameCount = frameCount,
                    frameRate = frameRate,
                    lenght = animClip.length,
                    isLoop = animClip.isLooping,
                };
                gpuAnimClips[i] = gpuAnimClip;
                totalFrameCount += gpuAnimClip.frameCount;

                // 动画采样
                float interval = 1f / frameRate;
                for (int frameIndex = 1; frameIndex <= frameCount; frameIndex++)
                {
                    if (EditorUtility.DisplayCancelableProgressBar("正在采样", $"Name={animClip.name} Frame=({frameIndex}/{frameCount})", frameIndex * 1.0f / frameCount))
                    {
                        return;
                    }

                    AnimationMode.SampleAnimationClip(tempModel, animClip, frameIndex * interval);

                    if (!settings.appleRootMation)
                    {
                        // FIXME: 这里在Unity2022版本中不生效，在Unity6中是生效的
                        // 如果没有开启根运动，就将位置恢复到初始位置
                        tempModel.transform.SetPositionAndRotation(originalPosition, originalRotation);
                    }

                    // 采样当前帧，并将结果追加到colors中
                    SampleAnimFrame(settings.sampleMode, skinnedMeshRenderer, animTexColors);
                }
            }

            // 生成并保存资源

            string modelName = Path.GetFileNameWithoutExtension(settings.assetPath);
            string outputDir = Path.Combine(settings.outputPath, modelName);
            if (!Directory.Exists(outputDir))
            {
                Directory.CreateDirectory(outputDir);
            }

            // 动画数据
            GpuAnimationData data = ScriptableObject.CreateInstance<GpuAnimationData>();
            data.clips = gpuAnimClips;
            string dataPath = Path.Combine(outputDir, $"{modelName}_Data.asset");
            AssetDatabase.CreateAsset(data, dataPath);

            // 动画贴图
            int animTexWidht = GetAnimTexWidth(settings.sampleMode, skinnedMeshRenderer);
            Texture2D animTex = CreateAnimTex(animTexWidht, totalFrameCount, animTexColors.ToArray(), false);
            string animTexPath = Path.Combine(outputDir, $"{modelName}_{settings.sampleMode}Tex.asset");
            AssetDatabase.CreateAsset(animTex, animTexPath);

            // 材质球
            Material material = new Material(settings.shader);
            material.SetTexture("_AnimTex", animTex);
            material.enableInstancing = true;
            string materialPath = Path.Combine(outputDir, $"{modelName}_Mat.mat");
            AssetDatabase.CreateAsset(material, materialPath);

            // 网格
            Mesh mesh = Object.Instantiate(skinnedMeshRenderer.sharedMesh);
            string meshPath = Path.Combine(outputDir, $"{modelName}_Mesh.mesh");
            AssetDatabase.CreateAsset(mesh, meshPath);

            // 预制体
            GameObject prefab = new GameObject(modelName);
            prefab.transform.SetLocalPositionAndRotation(Vector3.zero, Quaternion.identity);
            prefab.AddComponent<MeshFilter>().sharedMesh = mesh;
            prefab.AddComponent<MeshRenderer>().sharedMaterial = material;
            prefab.AddComponent<GpuAnimationPlayer>().SetData(data);
            string prefabPath = Path.Combine(outputDir, $"{modelName}.prefab");
            PrefabUtility.SaveAsPrefabAsset(prefab, prefabPath);
            Object.DestroyImmediate(prefab);
        }
        catch (System.Exception e)
        {
            Debug.LogException(e);
        }
        finally
        {
            AnimationMode.StopAnimationMode();
            if (tempModel != null)
            {
                PrefabUtility.UnloadPrefabContents(tempModel);
            }
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            EditorUtility.ClearProgressBar();
        }
    }

    // 获取动画贴图宽度
    private static int GetAnimTexWidth(SampleMode sampleMode, SkinnedMeshRenderer skinnedMeshRenderer)
    {
        switch (sampleMode)
        {
            case SampleMode.Bones:
                return skinnedMeshRenderer.bones.Length * 4;
            case SampleMode.Vertices:
                return skinnedMeshRenderer.sharedMesh.vertexCount;
            default:
                return 0;
        }
    }

    // 采样动画帧
    private static void SampleAnimFrame(SampleMode sampleMode, SkinnedMeshRenderer skinnedMeshRenderer, List<Color> colors)
    {
        switch (sampleMode)
        {
            case SampleMode.Bones:
                SampleBones(skinnedMeshRenderer, colors);
                break;
            case SampleMode.Vertices:
                SampleVertices(skinnedMeshRenderer, colors);
                break;
            default:
                break;
        }
    }

    // 采样骨骼
    private static void SampleBones(SkinnedMeshRenderer skinnedMeshRenderer, List<Color> colors)
    {
        Matrix4x4[] bindPoses = skinnedMeshRenderer.sharedMesh.bindposes;
        for (int boneIndex = 0; boneIndex < skinnedMeshRenderer.bones.Length; boneIndex++)
        {
            Matrix4x4 boneMatrix = skinnedMeshRenderer.bones[boneIndex].localToWorldMatrix * bindPoses[boneIndex];
            colors.Add(new Color(boneMatrix.m00, boneMatrix.m01, boneMatrix.m02, boneMatrix.m03));
            colors.Add(new Color(boneMatrix.m10, boneMatrix.m11, boneMatrix.m12, boneMatrix.m13));
            colors.Add(new Color(boneMatrix.m20, boneMatrix.m21, boneMatrix.m22, boneMatrix.m23));
            colors.Add(new Color(boneMatrix.m30, boneMatrix.m31, boneMatrix.m32, boneMatrix.m33));
        }
    }

    // 采样顶点
    private static void SampleVertices(SkinnedMeshRenderer skinnedMeshRenderer, List<Color> colors)
    {
        var mesh = new Mesh();
        skinnedMeshRenderer.BakeMesh(mesh);
        for (int i = 0; i < mesh.vertexCount; i++)
        {
            var vertex = mesh.vertices[i];
            colors.Add(new Color(vertex.x, vertex.y, vertex.z));
        }
    }

    /// <summary>
    /// 创建动画贴图
    /// </summary>
    /// <param name="width">宽度</param>
    /// <param name="height">高度</param>
    /// <param name="colors">填充颜色</param>
    /// <param name="isPowerTow">是否将宽高设置为最接近的2次幂</param>
    /// <returns></returns>
    private static Texture2D CreateAnimTex(int width, int height, Color[] colors, bool isPowerTow = false)
    {
        int w = width;
        int h = height;
        if (isPowerTow)
        {
            width = Mathf.NextPowerOfTwo(width);
            height = Mathf.NextPowerOfTwo(height);
        }
        Texture2D texture = new Texture2D(width, height, TextureFormat.RGBAHalf, false);
        texture.filterMode = FilterMode.Point;
        texture.wrapMode = TextureWrapMode.Clamp;
        texture.SetPixels(0, 0, w, h, colors);
        texture.Apply();
        return texture;
    }
}