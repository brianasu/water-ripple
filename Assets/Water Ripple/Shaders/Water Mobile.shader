Shader "Custom/Water Ripple/Mobile" 
{
	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "black" {}
		_WaterTex ("Diffuse", 2D) = "black" {}
		_Displacement ("Displacement", RANGE(0, 1)) = 0.5 
	}

	CGINCLUDE

	#include "UnityCG.cginc"

	struct v2f 
	{
		float4 pos : POSITION;
		float2 uv : TEXCOORD0;
		float2 uvWater : TEXCOORD1;
	};

	sampler2D _MainTex;
	sampler2D _WaterTex;
	float4 _WaterTex_ST;

	v2f vert(appdata_tan v) 
	{		
		v2f o;
		o.uv = v.texcoord;
		o.uvWater = v.texcoord * _WaterTex_ST.xy + _WaterTex_ST.zw;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

		return o;
	}
	
	fixed _Displacement;

	fixed4 frag(v2f i) : COLOR
	{
		fixed sample = tex2D(_MainTex, i.uv).r;
		sample *= _Displacement;
		return tex2D(_WaterTex, i.uvWater + sample);
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
 		Blend One One
		CGPROGRAM
		#pragma vertex vert 
		#pragma fragment frag 
		ENDCG
	}
}

Fallback "VertexLit"

} // shader