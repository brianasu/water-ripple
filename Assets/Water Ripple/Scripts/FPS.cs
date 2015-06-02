using UnityEngine;

using System.Collections;

public class FPS : MonoBehaviour
{
	float timeA;
	public int fps;
	public int lastFPS;
	public GUIStyle textStyle;

	void Start ()
	{
		Application.targetFrameRate = 120;
		timeA = Time.timeSinceLevelLoad;
		useGUILayout = false;
	}

	void Update ()
	{
		if (Time.timeSinceLevelLoad - timeA <= 1) {
			fps++;
		} else {
			lastFPS = fps + 1;
			timeA = Time.timeSinceLevelLoad;
			fps = 0;
		}
	}

	void OnGUI ()
	{
		GUI.Label (new Rect (0, 0, 200, 200), "" + lastFPS, textStyle);
	}

}