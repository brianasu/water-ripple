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
	private RenderTexture _bufferCurrent;
	[SerializeField]
	private Shader waterShader;
	//
	//
	private int _waterSizeWidth;
	private int _waterSizeHeight;
	private RenderTextureFormat _format = RenderTextureFormat.ARGB32;
	private int _count = 0;
	private Dictionary<Shader, Material> _shaderMap = new Dictionary<Shader, Material>();
	private RenderTexture _bufferPrev;

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

	private void Awake()
	{
		this.useGUILayout = false;
	}

	private void Start()
	{
		RenderTexture.active = _bufferPrev;
		GL.Clear(true, true, Color.grey);
		RenderTexture.active = null;

		RenderTexture.active = _bufferCurrent;
		GL.Clear(true, true, Color.grey);
		RenderTexture.active = null;
	}

	private void OnEnable()
	{
		_waterSizeWidth = _bufferCurrent.width;
		_waterSizeHeight = _bufferCurrent.height;
		_format = _bufferCurrent.format;

		_bufferPrev = new RenderTexture(_waterSizeWidth, _waterSizeHeight, 0, _format, RenderTextureReadWrite.Linear);
		_bufferPrev.filterMode = _bufferCurrent.filterMode;

		GetComponent<Renderer>().material.mainTexture = _bufferCurrent;
	}

	private void OnDestroy()
	{
		Destroy(GetComponent<Renderer>().material);
		Destroy(_bufferPrev);

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

		var scratchRT = RenderTexture.GetTemporary(_waterSizeWidth, _waterSizeHeight, 0, _format, RenderTextureReadWrite.Linear);
		scratchRT.filterMode = _bufferCurrent.filterMode;

		RenderTexture.active = scratchRT;
		GL.Clear(true, true, Color.grey);
		RenderTexture.active = null;

		if(Input.GetMouseButton(0))
		{
			var cam = Camera.main;
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
				Graphics.Blit(_bufferCurrent, scratchRT, GetMaterial(waterShader), 0);
				Graphics.Blit(scratchRT, _bufferCurrent, GetMaterial(waterShader), 0);
			}
		}

		// Raindrops
		if(rainDrops)
		{
			GetMaterial(waterShader).SetVector("_MousePos", Random.onUnitSphere);
			Graphics.Blit(_bufferCurrent, scratchRT, GetMaterial(waterShader), 0);
			Graphics.Blit(scratchRT, _bufferCurrent, GetMaterial(waterShader), 0);
		}

		UpdateWater();

		RenderTexture.ReleaseTemporary(scratchRT);
	}

	private void UpdateWater()
	{
		var bufferOne = (_count % 2 == 0) ? _bufferCurrent : _bufferPrev;
		var bufferTwo = (_count % 2 == 0) ? _bufferPrev : _bufferCurrent;
		_count++;

		GetMaterial(waterShader).SetTexture("_PrevTex", bufferTwo);
		Graphics.Blit(bufferOne, bufferTwo, GetMaterial(waterShader), 1);
	}
}
