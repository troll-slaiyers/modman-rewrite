package;

import h3d.Matrix;
import h3d.Camera;


class Camera3D2D extends Camera
{

    public var width: Float = 1280.0;
    public var height: Float = 720.0;

    public var vanishPointX: Float = 1280 / 2;
    public var vanishPointY: Float = 720 / 2;

    function frustumMatrix(m: Matrix, l: Float, r: Float, b: Float, t: Float, zn: Float, zf: Float ) {
		m.zero();

        var A: Float = (r+l) / (r-l);
        var B: Float = (t+b) / (t-b);
        var C: Float = -1 * (zf+zn) / (zf-zn);
        var D: Float = -1 * (2*zf*zn) / (zf-zn);

        m._11 = 2 * zn / (r - l);
        m._22 = 2 * zn / (t - b);
        m._31 = A;
        m._32 = B;
        m._33 = C;
        m._34 = -1;
        m._43 = D;

        if( rightHanded ) {
			m._33 *= -1;
			m._34 *= -1;
		}


    }

    function remap(value:Float, start1:Float, stop1:Float, start2:Float, stop2:Float):Float
		return start2 + (value - start1) * ((stop2 - start2) / (stop1 - start1));
	

    override function update() {

        var degToRad = (Math.PI / 180);
        var fovRads = degToRad * 45;
        var theta = fovRads / 2.0;
        var dist = width / 2.0 / Math.tan(theta);

        
        var tempVanishPointX = remap( vanishPointX, 0, width, width, 0 );
        var tempVanishPointY = remap( vanishPointY, 0, height, height, 0 );
        
        tempVanishPointX -= width / 2.0;
        tempVanishPointY -= height / 2.0;

        var l: Float = (tempVanishPointX-width/2)/dist;
        var r: Float = (tempVanishPointX+width/2)/dist;
        var b: Float = (tempVanishPointY+height/2)/dist;
        var t: Float = (tempVanishPointY-height/2)/dist;

        var zn = 1;
        var zf = 1000 + dist;

        frustumMatrix(mproj, l, r, b, t, zn, zf);
        
        pos.set(
            -tempVanishPointX+width/2,
            dist,
            -tempVanishPointY-height/2
        );

        target.set(
            -tempVanishPointX+width/2,
            0,
            -tempVanishPointY-height/2
        );

        makeCameraMatrix(mcam);

		m.multiply(mcam, mproj);

		initFlag = 0;

		frustum.loadMatrix(m);
    }
}