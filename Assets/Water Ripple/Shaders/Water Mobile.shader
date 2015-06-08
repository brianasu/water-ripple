Shader "Custom/Water Ripple/Mobile" 
{
	Properties 
	{
		[HideInInspector]_MainTex ("Base (RGB)", 2D) = "grey" {}
		_WaterTex ("Diffuse", 2D) = "grey" {}
		_Displacement ("Displacement", RANGE(0, 1)) = 0.5 
	}

	CGINCLUDE

	#include "UnityCG.cginc"

	struct v2f 
	{
		float4 pos : POSITION;
		float2 uv[4] : TEXCOORD0;
		float2 uvWater : TEXCOORD5;
	};

	sampler2D _MainTex;
	float4 _MainTex_TexelSize;
	
	sampler2D _WaterTex;
	float4 _WaterTex_ST;

	v2f vert(appdata_tan v) 
	{		
		v2f o;
		o.uvWater = v.texcoord * _WaterTex_ST.xy + _WaterTex_ST.zw;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		
		float3 size = float3(_MainTex_TexelSize.x, -_MainTex_TexelSize.x, 0);
		o.uv[0] = v.texcoord.xy + size.xz;
		o.uv[1] = v.texcoord.xy + size.yz;
		o.uv[2] = v.texcoord.xy + size.zx;
		o.uv[3] = v.texcoord.xy + size.zy;

		return o;
	}
	
	fixed _Displacement;

	fixed4 frag(v2f i) : COLOR
	{
		half sample = tex2D(_MainTex, i.uv[0]).r * 2 - 1;
		sample += tex2D(_MainTex, i.uv[1]).r * 2 - 1;
		sample += tex2D(_MainTex, i.uv[2]).r * 2 - 1;
		sample += tex2D(_MainTex, i.uv[3]).r * 2 - 1;
		sample /= 4;
		
		sample *= _Displacement;		
		return tex2D(_WaterTex, i.uvWater + float2(sample, sample));
	}

	ENDCG

Subshader 
{
	Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" }
	LOD 100
	
	Pass 
	{
		Tags { "ForceNoShadowCasting" = "True"   "LightMode"="Always" }
 		ZWrite Off
 		Blend SrcAlpha OneMinusSrcAlpha
		CGPROGRAM
		#pragma vertex vert 
		#pragma fragment frag 
		ENDCG
	}
}

Fallback "VertexLit"

} // shader