using System.IO;
using UnityEditor;
using UnityEngine;
using System.Collections.Generic;

public class GpuAnimationSampler
{
    /// <summary>
    /// ����ģʽ
    /// </summary>
    public enum SampleMode
    {
        Bones = 0,
        Vertices = 1,
    }

    /// <summary>
    /// ��������
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

            // ��¼��ʼλ��
            Vector3 originalPosition = tempModel.transform.position;
            Quaternion originalRotation = tempModel.transform.rotation;

            SkinnedMeshRenderer skinnedMeshRenderer = tempModel.GetComponentInChildren<SkinnedMeshRenderer>();
            skinnedMeshRenderer.forceMatrixRecalculationPerRender = true;

            // GPU����Ƭ���б�
            GpuAnimationClip[] gpuAnimClips = new GpuAnimationClip[settings.clips.Length];
            // ������ͼ��ɫ�б�
            List<Color> animTexColors = new List<Color>();

            // ��¼���ж���Ƭ�ε���֡��
            int totalFrameCount = 0;

            AnimationMode.StartAnimationMode();
            for (int i = 0; i < settings.clips.Length; i++)
            {
                var animClip = settings.clips[i];
                var frameRate = settings.sampleFrameRate > 0 ? settings.sampleFrameRate : animClip.frameRate;
                var frameCount = (int)(animClip.length * frameRate);
                // GPU����Ƭ������
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

                // ��������
                float interval = 1f / frameRate;
                for (int frameIndex = 1; frameIndex <= frameCount; frameIndex++)
                {
                    if (EditorUtility.DisplayCancelableProgressBar("���ڲ���", $"Name={animClip.name} Frame=({frameIndex}/{frameCount})", frameIndex * 1.0f / frameCount))
                    {
                        return;
                    }

                    AnimationMode.SampleAnimationClip(tempModel, animClip, frameIndex * interval);

                    if (!settings.appleRootMation)
                    {
                        // FIXME: ������Unity2022�汾�в���Ч����Unity6������Ч��
                        // ���û�п������˶����ͽ�λ�ûָ�����ʼλ��
                        tempModel.transform.SetPositionAndRotation(originalPosition, originalRotation);
                    }

                    // ������ǰ֡���������׷�ӵ�colors��
                    SampleAnimFrame(settings.sampleMode, skinnedMeshRenderer, animTexColors);
                }
            }

            // ���ɲ�������Դ

            string modelName = Path.GetFileNameWithoutExtension(settings.assetPath);
            string outputDir = Path.Combine(settings.outputPath, modelName);
            if (!Directory.Exists(outputDir))
            {
                Directory.CreateDirectory(outputDir);
            }

            // ��������
            GpuAnimationData data = ScriptableObject.CreateInstance<GpuAnimationData>();
            data.clips = gpuAnimClips;
            string dataPath = Path.Combine(outputDir, $"{modelName}_Data.asset");
            AssetDatabase.CreateAsset(data, dataPath);

            // ������ͼ
            int animTexWidht = GetAnimTexWidth(settings.sampleMode, skinnedMeshRenderer);
            Texture2D animTex = CreateAnimTex(animTexWidht, totalFrameCount, animTexColors.ToArray(), false);
            string animTexPath = Path.Combine(outputDir, $"{modelName}_{settings.sampleMode}Tex.asset");
            AssetDatabase.CreateAsset(animTex, animTexPath);

            // ������
            Material material = new Material(settings.shader);
            material.SetTexture("_AnimTex", animTex);
            material.enableInstancing = true;
            string materialPath = Path.Combine(outputDir, $"{modelName}_Mat.mat");
            AssetDatabase.CreateAsset(material, materialPath);

            // ����
            Mesh mesh = Object.Instantiate(skinnedMeshRenderer.sharedMesh);
            string meshPath = Path.Combine(outputDir, $"{modelName}_Mesh.mesh");
            AssetDatabase.CreateAsset(mesh, meshPath);

            // Ԥ����
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

    // ��ȡ������ͼ���
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

    // ��������֡
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

    // ��������
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

    // ��������
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
    /// ����������ͼ
    /// </summary>
    /// <param name="width">���</param>
    /// <param name="height">�߶�</param>
    /// <param name="colors">�����ɫ</param>
    /// <param name="isPowerTow">�Ƿ񽫿������Ϊ��ӽ���2����</param>
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