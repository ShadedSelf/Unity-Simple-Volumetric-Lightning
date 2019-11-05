using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class VolumeRenderer : MonoBehaviour
{

    public ComputeShader cs;

    public Vector3Int res = Vector3Int.one * 128;
    public float pow = 1;
	public float density = 50;

    private Camera cam;

	private ComputeBuffer test; 
	
    void OnEnable()
    {
		test = new ComputeBuffer(res.x * res.y * res.z, sizeof(float) * 3);

		cs.SetBuffer(0, "_Test", test);
        cs.SetBuffer(1, "_Test", test);

		Shader.SetGlobalBuffer("_Test", test);
		Shader.SetGlobalVector("_Res", new Vector3(res.x, res.y, res.z));

        cam = GetComponent<Camera>();
    }

    void Update()
    {
        SetVariables();

        cs.Dispatch(0, res.x / 8, res.y / 8, res.z / 8);
        cs.Dispatch(1, res.x / 32, res.y / 32, 1);
    }

    void SetVariables()
    {
        Matrix4x4 matrix = cam.worldToCameraMatrix.inverse * cam.projectionMatrix.inverse;

        cs.SetMatrix("_LocalToWorldFrustrum", matrix);
        cs.SetFloat("_POW", pow);
        cs.SetFloat("_Density", density);
        cs.SetFloat("_Time", Time.time);
        cs.SetFloat("_DT", Time.deltaTime);
        cs.SetFloat("_EdgeDis", Vector3.Distance(cam.ScreenToWorldPoint(new Vector3(0, 0, cam.nearClipPlane)), cam.ScreenToWorldPoint(new Vector3(0, 0, cam.farClipPlane))));
        cs.SetInts("_Res", new int[3] { res.x, res.y, res.z });
        cs.SetVector("_CamDir", cam.transform.forward);

        Shader.SetGlobalMatrix("_LTWF", matrix);
        Shader.SetGlobalMatrix("_iLTWF", cam.projectionMatrix * cam.worldToCameraMatrix);
        Shader.SetGlobalFloat("_POW", pow);

        Vector4[] origins = new Vector4[4]
		{
			cam.ScreenPointToRay(new Vector3(0, Screen.height - 1, 0)).origin,
			cam.ScreenPointToRay(new Vector3(Screen.width - 1, Screen.height - 1, 0)).origin,
            cam.ScreenPointToRay(new Vector3(0, 0, 0)).origin,
			cam.ScreenPointToRay(new Vector3(Screen.width - 1, 0, 0)).origin
		};
        Shader.SetGlobalVectorArray("_Origins", origins);
        cs.SetVectorArray("_Origins", origins);

        Vector4[] directions = new Vector4[4]
		{
			cam.ScreenPointToRay(new Vector3(0, Screen.height - 1, 0)).direction,
			cam.ScreenPointToRay(new Vector3(Screen.width - 1, Screen.height - 1, 0)).direction,
            cam.ScreenPointToRay(new Vector3(0, 0, 0)).direction,
			cam.ScreenPointToRay(new Vector3(Screen.width - 1, 0, 0)).direction
		};
        Shader.SetGlobalVectorArray("_Directions", directions);
        cs.SetVectorArray("_Directions", directions);

        float far = cam.farClipPlane;
        float near = cam.nearClipPlane;
        Vector4 depthParams = new Vector4(near, far, (1 - far / near) / far, (far / near) / far);
        cs.SetVector("_DepthParams", depthParams);
    }

	void OnDisable()
	{
		test.Release();
	}
}
