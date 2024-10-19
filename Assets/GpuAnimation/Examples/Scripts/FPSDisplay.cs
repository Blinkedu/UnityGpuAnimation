using UnityEngine;

public class FPSDisplay : MonoBehaviour
{
    private float deltaTime = 0.0f;
    private float fps = 0.0f;
    private float updateInterval = 0.1f;  // 每0.1秒更新一次FPS
    private float fpsAccum = 0.0f;        // 累积的FPS
    private int frames = 0;               // 记录的帧数
    private float timeleft;               // 离下一次更新的时间

    private GUIStyle style;
    private Rect rect;
    private int width;
    private int height;

    void Start()
    {
        width = Screen.width;
        height = Screen.height;
        rect = new Rect(10, 10, width, height * 2 / 50);
        style = new GUIStyle();
        style.alignment = TextAnchor.UpperLeft;
        style.fontSize = height * 2 / 50;
        style.normal.textColor = Color.white;

        timeleft = updateInterval;
    }

    void Update()
    {
        timeleft -= Time.deltaTime;
        deltaTime += (Time.unscaledDeltaTime - deltaTime) * 0.1f;
        fpsAccum += 1.0f / deltaTime;
        frames++;

        // 时间到，更新帧率显示
        if (timeleft <= 0.0f)
        {
            fps = fpsAccum / frames;  // 计算平均FPS
            timeleft = updateInterval; // 重置时间
            fpsAccum = 0.0f;           // 重置累积的FPS
            frames = 0;                // 重置帧计数
        }
    }

    void OnGUI()
    {
        string text = string.Format("{0:0.} fps", fps);
        GUI.Label(rect, text, style);
    }
}
