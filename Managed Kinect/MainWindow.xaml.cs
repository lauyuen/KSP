using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;


using Emgu.CV;
using Emgu.CV.CvEnum;
using Emgu.CV.Structure;
using Emgu.CV.WPF;
using Emgu.CV.VideoSurveillance;

using Microsoft.Kinect;
using Microsoft.Kinect.Toolkit;

using System.Drawing;
using System.Diagnostics;
using System.IO;
using System.Windows.Interop;
using System.Threading;

namespace WpfApplication1
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        #region Private Declarations
        /// <summary>
        /// KinectSensorChooser used to manage kinect sensors.
        /// </summary>
        private readonly KinectSensorChooser sensorChooser = new KinectSensorChooser();

        /// <summary>
        /// KinectSensorChooser used to manage kinect sensors.
        /// </summary>
        private readonly KinectSensor sensor;

        /// <summary>
        /// Intermediate storage for the color data received from the camera
        /// </summary>
        private byte[] colorPixels;

        /// <summary>
        /// Intermediate storage for the depth data received from the IR sensor
        /// </summary>
        private byte[] depthPixels;

        /// <summary>
        /// Intermediate storage for the depth data received from the IR sensor
        /// </summary>
        //private byte[] lastDepthPixels;
        private WriteableBitmap depthBitmap;

        /// <summary>
        /// Bitmap that will hold depth information
        /// </summary>
        //private WriteableBitmap backgroundBitmap;

        /// <summary>
        /// Stopwatch that determines the time.
        /// </summary>
        private readonly Stopwatch stopwatch = new Stopwatch();

        const float MaxDepthDistance = 4095; // max value returned
        const float MinDepthDistance = 850; // min value returned
        const float MaxDepthDistanceOffset = MaxDepthDistance - MinDepthDistance;

        private static byte[, ,] data = new byte[480, 640, 4];
        private Image<Bgra, Byte> rgba_Image = new Image<Bgra, byte>(data);
        private Image<Bgr, byte> bgr_image;
        private Image<Gray, byte> gray_image;
        private Image<Gray, byte> forgroundMask;

        private static BlobTrackerAuto<Bgr> _tracker;
        private static IBGFGDetector<Bgr> _detector;

        private static MCvFont _font = new MCvFont(Emgu.CV.CvEnum.FONT.CV_FONT_HERSHEY_SIMPLEX, 1.0, 1.0);
        // private Image<Bgr, Byte> cvBackgroundImage = new Image<Bgr, byte>("ss640.jpg");

        #endregion


        public MainWindow()
        {
            InitializeComponent();
    
            // This will handle Kinect Errors, plug and play, and kinect choosing.
            this.SensorChooserUI.KinectSensorChooser = sensorChooser;
            this.sensor = KinectSensor.KinectSensors[0];
            //this.sensorChooser.Kinect = sensorChooser;
            this.sensorChooser.Start();
            
        }

        /// <summary>
        /// Event handler for WPF window loaded event
        /// </summary>
        /// <param name="sender">object sending the event</param>
        /// <param name="e">event arguments</param>
        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
            if (this.sensorChooser.Kinect != null)
            {
                // Allocate space to put the pixels we'll receive
                this.colorPixels = new byte[this.sensorChooser.Kinect.ColorStream.FramePixelDataLength];

                this.depthBitmap = new WriteableBitmap(this.sensorChooser.Kinect.DepthStream.FrameWidth,
                    this.sensor.DepthStream.FrameHeight, 96.0, 96.0, PixelFormats.Bgr32, null);
                //this.backgroundBitmap = new WriteableBitmap(this.sensorChooser.Kinect.DepthStream.FrameWidth,
                //    this.sensor.ColorStream.FrameHeight, 96.0, 96.0, PixelFormats.Bgr32, null);

                // Set the image we display to point to the bitmap where we'll put the image data
                this.depthImage.Source = this.depthBitmap;

                // ComponentDispatcher.ThreadIdle += new EventHandler(ComponentDispatcher_ThreadIdle);
                this.sensor.AllFramesReady += new EventHandler<AllFramesReadyEventArgs>(Kinect_AllFramesReady);

                _detector = new FGDetector<Bgr>(FORGROUND_DETECTOR_TYPE.FGD);
                _tracker = new BlobTrackerAuto<Bgr>();
                //ComponentDispatcher.ThreadIdle += new EventHandler(ComponentDispatcher_ThreadIdle);
            }
        }

        void Kinect_AllFramesReady(object sender, AllFramesReadyEventArgs e)
        {
            using (DepthImageFrame depthFrame = e.OpenDepthImageFrame())
            using (ColorImageFrame colorFrame = e.OpenColorImageFrame())
            {
                if (depthFrame != null)
                {
                    // Copy the pixel data from the image to a temporary array
                    this.depthPixels = GenerateColoredBytes(depthFrame);
                    //colorFrame.CopyPixelDataTo(this.colorPixels);

                    // Write the pixel data into our bitmap
                    this.depthBitmap.WritePixels(
                        new Int32Rect(0, 0, this.depthBitmap.PixelWidth, this.depthBitmap.PixelHeight),
                        this.depthPixels,
                        this.depthBitmap.PixelWidth * sizeof(int),
                        0);
                }

                if (colorFrame != null)
                {
                    // Copy the pixel data from the image to a temporary array
                    // colorFrame.CopyPixelDataTo(this.colorPixels);
                    colorFrame.CopyPixelDataTo(this.colorPixels);
                    rgba_Image.Bytes = colorPixels;

                    // _detector = new FGDetector<Bgr>(FORGROUND_DETECTOR_TYPE.MOG);
                    // _tracker = new BlobTrackerAuto<Bgr>();

                    bgr_image = rgba_Image.Convert<Bgr, byte>();
                    this.bgrImage.Source = BitmapSourceConvert.ToBitmapSource(bgr_image);

                    System.Windows.Threading.Dispatcher.CurrentDispatcher.BeginInvoke(
                        System.Windows.Threading.DispatcherPriority.ContextIdle,
                        new Action(ProcessImage));


                    //gray_image = rgba_Image.Convert<Gray, byte>();
                    //this.grayImage.Source = BitmapSourceConvert.ToBitmapSource(gray_image);
                    //this.cvbImage.Source = BitmapSourceConvert.ToBitmapSource(forgroundMask);
                }
            }
        }

        void ProcessImage()
        {
            if (this.bgr_image != null)
            {
                Console.WriteLine("Processing Image");
                this.bgr_image._SmoothGaussian(3);
                _detector.Update(this.bgr_image);
                this.forgroundMask = _detector.ForgroundMask;

                _tracker.Process(bgr_image, forgroundMask);

                foreach (MCvBlob blob in _tracker)
                {
                    bgr_image.Draw((System.Drawing.Rectangle)blob, new Bgr(255.0, 255.0, 255.0), 2);
                    bgr_image.Draw(blob.ID.ToString(), ref _font, System.Drawing.Point.Round(blob.Center), new Bgr(255.0, 255.0, 255.0));
                }

                this.cvbImage.Source = BitmapSourceConvert.ToBitmapSource(forgroundMask);
            }
        }

        /// <summary>
        /// Method to convert native depth data from the sensor to colored pixels
        /// </summary>
        /// <param name="depthFrame"> Depth frame data from the sensor</param>
        private byte[] GenerateColoredBytes(DepthImageFrame depthFrame)
        {
            //get the raw data from kinect with the depth for every pixel
            short[] rawDepthData = new short[depthFrame.PixelDataLength];
            depthFrame.CopyPixelDataTo(rawDepthData);

            //use depthFrame to create the image to display on-screen
            //depthFrame contains color information for all pixels in image
            //Height x Width x 4 (Red, Green, Blue, empty byte)
            Byte[] pixels = new byte[depthFrame.Height * depthFrame.Width * 4];

            //Bgr32  - Blue, Green, Red, empty byte
            //Bgra32 - Blue, Green, Red, transparency 
            //You must set transparency for Bgra as .NET defaults a byte to 0 = fully transparent

            //hardcoded locations to Blue, Green, Red (BGR) index positions       
            const int BlueIndex = 0;
            const int GreenIndex = 1;
            const int RedIndex = 2;

            int runningAverage = 0;

            //loop through all distances
            //pick a RGB color based on distance
            for (int depthIndex = 0, colorIndex = 0;
                depthIndex < rawDepthData.Length && colorIndex < pixels.Length;
                depthIndex++, colorIndex += 4)
            {
                int y = depthIndex / 640;
                int x = depthIndex % 640;
                
                //get the player (requires skeleton tracking enabled for values)
                int player = rawDepthData[depthIndex] & DepthImageFrame.PlayerIndexBitmask;

                //gets the depth value
                int depth = rawDepthData[depthIndex] >> DepthImageFrame.PlayerIndexBitmaskWidth;

                //equal coloring for monochromatic histogram
                byte intensity = CalculateIntensityFromDepth(depth);
                //intensity = (byte)(((int)intensity > 225) ? intensity : (intensity + 30));
                pixels[colorIndex + BlueIndex] = intensity;
                pixels[colorIndex + GreenIndex] = intensity;
                pixels[colorIndex + RedIndex] = intensity;
                
                if ( 310 < x && x < 330 &&
                     230 < y && y < 250 )
                {
                    runningAverage += depth;
                    pixels[colorIndex + BlueIndex] = 0;
                }

                ////Color all players "gold"
                ////(byte)(intensity - 30)
                //if (player > 0)
                //{
                //    pixels[colorIndex + BlueIndex] = Colors.Gold.B;
                //    pixels[colorIndex + GreenIndex] = Colors.Gold.G;
                //    pixels[colorIndex + RedIndex] = Colors.Gold.R;
                //}

            }
            Console.WriteLine((float)(runningAverage/400)/1000);

            return pixels;
        }

       public static byte CalculateIntensityFromDepth(int distance)
        {
            //formula for calculating monochrome intensity for histogram
            return (byte)(255 - (255 * Math.Max(distance - MinDepthDistance, 0)
                / (MaxDepthDistanceOffset)));
        }

        /// <summary>
        /// Event handler for window closing event.
        /// </summary>
        /// <param name="sender">object sending the event.</param>
        /// <param name="e">event arguments.</param>
        private void Window_Closing(object sender, System.ComponentModel.CancelEventArgs e)
        {

        }


        private void button_cv_Click(object sender, RoutedEventArgs e)
        {

            
        }


    }
}
