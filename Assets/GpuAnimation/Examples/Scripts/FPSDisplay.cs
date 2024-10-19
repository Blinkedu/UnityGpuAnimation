using UnityEngine;

public class FPSDisplay : MonoBehaviour
{
    private float deltaTime = 0.0f;
    private float fps = 0.0f;
    private float updateInterval = 0.1f;  // ÿ0.1�����һ��FPS
    private float fpsAccum = 0.0f;        // �ۻ���FPS
    private int frames = 0;               // ��¼��֡��
    private float timeleft;               // ����һ�θ��µ�ʱ��

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

        // ʱ�䵽������֡����ʾ
        if (timeleft <= 0.0f)
        {
            fps = fpsAccum / frames;  // ����ƽ��FPS
            timeleft = updateInterval; // ����ʱ��
            fpsAccum = 0.0f;           // �����ۻ���FPS
            frames = 0;                // ����֡����
        }
    }

    void OnGUI()
    {
        string text = string.Format("{0:0.} fps", fps);
        GUI.Label(rect, text, style);
    }
}
