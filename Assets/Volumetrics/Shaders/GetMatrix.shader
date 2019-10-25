Shader "Hidden/GetMatrix" 
{
	SubShader 
	{
		Pass
		{
			ZWrite Off ZTest Always Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0

			#include "UnityCG.cginc"

			struct v2f
			{
				float4 pos : SV_POSITION;
			};

			RWStructuredBuffer<float4x4> _MatrixBuf : register(u1);

			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos = float4(float2(v.texcoord.x, 1.0 - v.texcoord.y) * 2.0 - 1.0, 0.0, 1.0);
				return o;
			}


			float4 frag(v2f i) : SV_Target
			{
				_MatrixBuf[0] = unity_WorldToShadow[0];
				// _MatrixBuf[1] = unity_WorldToShadow[1];
				// _MatrixBuf[2] = unity_WorldToShadow[2];
				// _MatrixBuf[3] = unity_WorldToShadow[3];

				// _MatrixBuf[4] = float4x4(_LightSplitsNear, _LightSplitsFar, float4(0, 0, 0, 0), float4(0, 0, 0, 0));

				return 0.0;
			}
			ENDCG
		}
	}
	Fallback Off
}