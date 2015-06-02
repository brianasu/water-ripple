Shader "Custom/Water Ripple/Mobile" 
{
	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "black" {}
		_WaterTex ("Diffuse", 2D) = "black" {}
	}

	CGINCLUDE

	#include "UnityCG.cginc"

	struct v2f 
	{
		float4 pos : POSITION;
		float2 uv : TEXCOORD0;
	};

	sampler2D _MainTex;
	sampler2D _WaterTex;

	v2f vert(appdata_tan v) 
	{
		v2f o;
		o.uv = v.texcoord;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

		return o;
	}

	fixed4 frag(v2f i) : COLOR
	{
		fixed sample = tex2D(_MainTex, i.uv).r;
		return tex2D(_WaterTex, i.uv + sample);
	}

	ENDCG

Subshader 
{
	Pass 
	{
 		Tags { "IgnoreProjector"="True" "Queue"="Transparent" "RenderType"="Transparent"}
 		ZWrite Off
 		Blend One One
		CGPROGRAM
		#pragma vertex vert 
		#pragma fragment frag 
		ENDCG
	}
}

Fallback off

} // shader