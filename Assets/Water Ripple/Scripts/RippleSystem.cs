using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class RippleSystem : MonoBehaviour
{
	[SerializeField]
	private bool rainDrops = false;
	[SerializeField]
	private float dropSize = 1;
	[SerializeField]
	private float damping = 1;
	[SerializeField]
	private Projector targetProjector;
	[SerializeField]
	private int waterSize = 128;
	[SerializeField]
	private Shader waterShader;
	//
	private int _count = 0;
	private Dictionary<Shader, Material> _shaderMap = new Dictionary<Shader, Material>();
	private RenderTexture _bufferPrev;
	private RenderTexture _bufferCurrent;

	private Material GetMaterial(Shader shader)
	{
		Material material;
		if(_shaderMap.TryGetValue(shader, out material))
		{
			return material;
		}
		else
		{
			material = new Material(shader);
			_shaderMap.Add(shader, material);
			return material;
		}
	}

	private void Start()
	{
		RenderTexture.active = _bufferPrev;
		GL.Clear(true, true, Color.black);
		RenderTexture.active = null;

		RenderTexture.active = _bufferCurrent;
		GL.Clear(true, true, Color.black);
		RenderTexture.active = null;
	}

	private void OnEnable()
	{
		_bufferPrev = new RenderTexture(waterSize, waterSize, 0, RenderTextureFormat.ARGBFloat);
		_bufferCurrent = new RenderTexture(waterSize, waterSize, 0, RenderTextureFormat.ARGBFloat);

		GetComponent<Renderer>().material.mainTexture = _bufferCurrent;

		if(targetProjector != null)
		{
			targetProjector.material.SetTexture("_ShadowTex", _bufferCurrent);
		}
	}

	private void OnDestroy()
	{
		Destroy(GetComponent<Renderer>().material);

		Destroy(_bufferPrev);
		Destroy(_bufferCurrent);

		foreach (KeyValuePair<Shader, Material> item in _shaderMap)
		{
			Destroy(item.Value);
		}

		_shaderMap.Clear();
	}

	private void Update()
	{
		damping = Mathf.Clamp(damping, 0, 1);

		GetMaterial(waterShader).SetFloat("_DropSize", dropSize);
		GetMaterial(waterShader).SetFloat("_Damping", damping);

		if(Input.GetMouseButton(0))
		{
			Camera cam = Camera.main;
			RaycastHit info;
			if(GetComponent<Collider>().Raycast(cam.ScreenPointToRay(Input.mousePosition), out info, float.MaxValue))
			{
				Vector2 uv;
				if(GetComponent<Collider>() is MeshCollider)
				{
					uv = info.textureCoord;
				}
				else
				{
					// plane is from -0.5 to 0.5
					Vector3 point = GetComponent<Collider>().transform.localToWorldMatrix.MultiplyPoint(info.point);
					point += new Vector3(0.5f, 0, 0.5f);
					uv = new Vector2(point.x, point.z);
				}

				GetMaterial(waterShader).SetVector("_MousePos", uv);
				Graphics.Blit(_bufferCurrent, _bufferCurrent, GetMaterial(waterShader), 0);
			}
		}

		// Raindrops
		if(rainDrops)
		{
			GetMaterial(waterShader).SetVector("_MousePos", Random.onUnitSphere);
			Graphics.Blit(_bufferCurrent, _bufferCurrent, GetMaterial(waterShader), 0);
		}

		UpdateWater();
	}

	private void UpdateWater()
	{
		RenderTexture bufferOne = (_count % 2 == 0) ? _bufferCurrent : _bufferPrev;
		RenderTexture bufferTwo = (_count % 2 == 0) ? _bufferPrev : _bufferCurrent;
		_count++;

		GetMaterial(waterShader).SetTexture("_PrevTex", bufferTwo);
		Graphics.Blit(bufferOne, bufferTwo, GetMaterial(waterShader), 1);
	}

//	private void OnGUI()
//	{
//		GUILayout.Label(_bufferCurrent);
//	}
}
