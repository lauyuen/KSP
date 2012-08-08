using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace Managed_Kinect
{
    class KinectUtility
    {
        public const UInt16 MaxDepthDistance = 0xFFF;
        public const UInt16 MinDepthDistance = 0x352;
        public const UInt16 MaxDepthDistanceOffset = MaxDepthDistance - MinDepthDistance;

        public const UInt16 HEIGHT = 480;
        public const UInt16 WIDTH = 640;
        public const Byte BRGA_STRIDE = 4;
        public const Byte BGR_STRIDE = 3;
        public const Byte LUM_STRIDE = 1;

        public const UInt32 RESOLUTION = HEIGHT * WIDTH;
        public const UInt32 LUM_RES = HEIGHT * WIDTH;
        public const UInt32 BGRA_RES = HEIGHT * WIDTH * BRGA_STRIDE;
        public const UInt32 BGR_RES = HEIGHT * WIDTH * BGR_STRIDE;

        public static Byte[, ,] CDATA = new Byte[HEIGHT, WIDTH, BGR_STRIDE];
        public static Byte[, ,] DDATA = new Byte[HEIGHT, WIDTH, LUM_STRIDE];

        private static int lastTick;
        private static int lastFrameRate;
        private static int frameRate;

        public static int CalculateColorFrameRate()
        {
            if (System.Environment.TickCount - lastTick >= 1000)
            {
                lastFrameRate = frameRate;
                frameRate = 0;
                lastTick = System.Environment.TickCount;
            }
            frameRate++;
            return lastFrameRate;
        }

        public static int CalculateDepthFrameRate()
        {
            if (System.Environment.TickCount - lastTick >= 1000)
            {
                lastFrameRate = frameRate;
                frameRate = 0;
                lastTick = System.Environment.TickCount;
            }
            frameRate++;
            return lastFrameRate;
        }

        public static byte getDepthBGBytes(short depth)
        {
            return (byte)(0xFF - (0xFF * Math.Max(depth - MinDepthDistance, 0) / (MaxDepthDistanceOffset)));
        }
    }
}
