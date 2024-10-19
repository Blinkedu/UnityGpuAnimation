using UnityEngine;

public class Spawner : MonoBehaviour
{
    public GameObject prefab;
    public int row = 100;
    public int col = 100;
    public float space = 2;

    private void Start()
    {
        for (int i = 0; i < row; i++)
        {
            for(int j = 0; j < col; j++)
            {
                GameObject go = GameObject.Instantiate(prefab, new Vector3(i * space, 0, j * space), Quaternion.identity, transform);
                GpuAnimationPlayer animationPlayer = go.GetComponent<GpuAnimationPlayer>();
                if (animationPlayer != null )
                {
                    animationPlayer.Play(Random.Range(0, animationPlayer.Clips.Length));

                    animationPlayer.MaterialPropertyBlock.SetColor("_Color", new Color(Random.Range(0f, 1f), Random.Range(0f, 1f), Random.Range(0f, 1f), 1));
                    animationPlayer.MeshRenderer.SetPropertyBlock(animationPlayer.MaterialPropertyBlock);
                }
            }
        }
    }
}
