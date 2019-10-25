
//////
float4 permute(float4 x){return fmod(((x*34.0)+1.0)*x, 289.0);}
float permute(float x){return floor(fmod(((x*34.0)+1.0)*x, 289.0));}
float4 taylorInvSqrt(float4 r){return 1.79284291400159 - 0.85373472095314 * r;}
float taylorInvSqrt(float r){return 1.79284291400159 - 0.85373472095314 * r;}

float4 grad4(float j, float4 ip)
{
	float4 ones = float4(1.0, 1.0, 1.0, -1.0);
 	float4 p,s;

	p.xyz = floor( frac ((float3)j * ip.xyz) * 7.0) * ip.z - 1.0;
	p.w = 1.5 - dot(abs(p.xyz), ones.xyz);
	s = 1 - step(0.0, p);
	p.xyz = p.xyz + (s.xyz*2.0 - 1.0) * s.www; 

	return p;
}

float snoise(float4 v)
{
  float2  C = float2( 0.138196601125010504,
                        0.309016994374947451);
  float4 i  = floor(v + dot(v, C.yyyy) );
  float4 x0 = v -   i + dot(i, C.xxxx);

  float4 i0;

  float3 isX = step( x0.yzw, x0.xxx );
  float3 isYZ = step( x0.zww, x0.yyz );
  i0.x = isX.x + isX.y + isX.z;
  i0.yzw = 1.0 - isX;

  i0.y += isYZ.x + isYZ.y;
  i0.zw += 1.0 - isYZ.xy;

  i0.z += isYZ.z;
  i0.w += 1.0 - isYZ.z;

  float4 i3 = clamp( i0, 0.0, 1.0 );
  float4 i2 = clamp( i0-1.0, 0.0, 1.0 );
  float4 i1 = clamp( i0-2.0, 0.0, 1.0 );

  float4 x1 = x0 - i1 + 1.0 * C.xxxx;
  float4 x2 = x0 - i2 + 2.0 * C.xxxx;
  float4 x3 = x0 - i3 + 3.0 * C.xxxx;
  float4 x4 = x0 - 1.0 + 4.0 * C.xxxx;

  i = fmod(i, 289.0); 
  float j0 = permute( permute( permute( permute(i.w) + i.z) + i.y) + i.x);
  float4 j1 = permute( permute( permute( permute (
             i.w + float4(i1.w, i2.w, i3.w, 1.0 ))
           + i.z + float4(i1.z, i2.z, i3.z, 1.0 ))
           + i.y + float4(i1.y, i2.y, i3.y, 1.0 ))
           + i.x + float4(i1.x, i2.x, i3.x, 1.0 ));

  float4 ip = float4(1.0/294.0, 1.0/49.0, 1.0/7.0, 0.0) ;

  float4 p0 = grad4(j0,   ip);
  float4 p1 = grad4(j1.x, ip);
  float4 p2 = grad4(j1.y, ip);
  float4 p3 = grad4(j1.z, ip);
  float4 p4 = grad4(j1.w, ip);

  float4 norm = taylorInvSqrt(float4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;
  p4 *= taylorInvSqrt(dot(p4,p4));

  float3 m0 = max(0.6 - float3(dot(x0,x0), dot(x1,x1), dot(x2,x2)), 0.0);
  float2 m1 = max(0.6 - float2(dot(x3,x3), dot(x4,x4)            ), 0.0);
  m0 = m0 * m0;
  m1 = m1 * m1;
  return 49.0 * ( dot(m0*m0, float3( dot( p0, x0 ), dot( p1, x1 ), dot( p2, x2 )))
               + dot(m1*m1, float2( dot( p3, x3 ), dot( p4, x4 ) ) ) ) ;

}
//////