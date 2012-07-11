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

using Microsoft.Kinect;
using Microsoft.Kinect.Toolkit;
using System.Diagnostics;
using System.IO;

using Emgu.CV;
using Emgu.CV.Structure;
using Emgu.CV.WPF;

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
        private byte[] lastDepthPixels;

        /// <summary>
        /// Bitmap that will hold color information
        /// </summary>4
        private WriteableBitmap colorBitmap;

        /// <summary>
        /// Bitmap that will hold depth information
        /// </summary>
        private WriteableBitmap depthBitmap;

        /// <summary>
        /// Bitmap that will hold depth information
        /// </summary>
        private WriteableBitmap backgroundBitmap;

        /// <summary>
        /// Stopwatch that determines the time.
        /// </summary>
        private readonly Stopwatch stopwatch = new Stopwatch();

        /// <summary>
        /// Last remembered timestamp for the last color frame
        /// </summary>
        private int prevColorTimeStamp = 0;

        /// <summary>
        /// Last remembered timestamp for the last depth frame
        /// </summary>
        private int prevDepthTimeStamp = 0;

        const float MaxDepthDistance = 4095; // max value returned
        const float MinDepthDistance = 850; // min value returned
        const float MaxDepthDistanceOffset = MaxDepthDistance - MinDepthDistance;

        private Image<Bgr, Byte> backgroundImage = new Image<Bgr, byte>(680, 320);

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

                // This is the bitmap we'll display on-screen
                this.colorBitmap = new WriteableBitmap(this.sensorChooser.Kinect.ColorStream.FrameWidth,
                    this.sensor.ColorStream.FrameHeight, 96.0, 96.0, PixelFormats.Bgr32, null);
                this.depthBitmap = new WriteableBitmap(this.sensorChooser.Kinect.DepthStream.FrameWidth,
                    this.sensor.DepthStream.FrameHeight, 96.0, 96.0, PixelFormats.Bgr32, null);
                //this.backgroundBitmap = new WriteableBitmap(this.sensorChooser.Kinect.DepthStream.FrameWidth,
                //    this.sensor.ColorStream.FrameHeight, 96.0, 96.0, PixelFormats.Bgr32, null);

                // Set the image we display to point to the bitmap where we'll put the image data
                this.colorImage.Source = this.colorBitmap;
                this.depthImage.Source = this.depthBitmap;
                //this.backgroundImage.Source = this.backgroundBitmap;

                // Add an event handler to be called whenever there is new color frame data
                this.sensor.AllFramesReady += new EventHandler<AllFramesReadyEventArgs>(Kinect_AllFramesReady);
            }
        }

        void Kinect_AllFramesReady(object sender, AllFramesReadyEventArgs e)
        {
            int currenttime = 0;
            using (DepthImageFrame depthFrame = e.OpenDepthImageFrame())
            {
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

                        // Write the pixel data into our bitmap
                        //this.backgroundBitmap.WritePixels(
                        //    new Int32Rect(0, 0, this.colorBitmap.PixelWidth, this.colorBitmap.PixelHeight),
                        //    this.colorPixels,
                        //    this.colorBitmap.PixelWidth * sizeof(int),
                        //    0);


                        currenttime = Int32.Parse(depthFrame.Timestamp.ToString());

                        if (depthFrame != null // && this.colorBitmap != null 
                        && currenttime - this.prevDepthTimeStamp > 3000
                        && false
                        )
                        {
                            Console.WriteLine(currenttime);
                            this.prevDepthTimeStamp = currenttime;

                            // create a png bitmap encoder which knows how to save a .png file
                            BitmapEncoder encoder = new PngBitmapEncoder();
                            encoder.Frames.Add(BitmapFrame.Create(this.depthBitmap));

                            string myPhotos = Environment.GetFolderPath(Environment.SpecialFolder.MyPictures);

                            string path = System.IO.Path.Combine(myPhotos, "Kinect-d-" + currenttime + ".png");

                            try
                            {
                                using (FileStream fs = new FileStream(path, FileMode.Create))
                                {
                                    encoder.Save(fs);
                                }

                                Console.WriteLine(string.Format("Depth Success {0}", path));
                            }
                            catch (IOException)
                            {
                                Console.WriteLine(string.Format("Depth Failed {0}", path));
                            }
                        }
                    }

                    if (colorFrame != null)
                    {
                        // Copy the pixel data from the image to a temporary array
                        colorFrame.CopyPixelDataTo(this.colorPixels);

                        // Write the pixel data into our bitmap
                        this.colorBitmap.WritePixels(
                            new Int32Rect(0, 0, this.colorBitmap.PixelWidth, this.colorBitmap.PixelHeight),
                            this.colorPixels,
                            this.colorBitmap.PixelWidth * sizeof(int),
                            0);

                        currenttime = Int32.Parse(colorFrame.Timestamp.ToString());

                        if (colorFrame != null // && this.colorBitmap != null 
                            && currenttime - this.prevColorTimeStamp > 3000
                            && false
                            )
                        {
                            // Copy the pixel data from the image to a temporary array
                            colorFrame.CopyPixelDataTo(this.colorPixels);

                            Console.WriteLine(currenttime);
                            this.prevColorTimeStamp = currenttime;

                            // create a png bitmap encoder which knows how to save a .png file
                            BitmapEncoder encoder = new PngBitmapEncoder();
                            encoder.Frames.Add(BitmapFrame.Create(this.colorBitmap));

                            string myPhotos = Environment.GetFolderPath(Environment.SpecialFolder.MyPictures);

                            string path = System.IO.Path.Combine(myPhotos, "Kinect-c-" + currenttime + ".png");

                            try
                            {
                                using (FileStream fs = new FileStream(path, FileMode.Create))
                                {
                                    encoder.Save(fs);
                                }

                                Console.WriteLine(string.Format("Color Success {0}", path));
                            }
                            catch (IOException)
                            {
                                Console.WriteLine(string.Format("Color Failed {0}", path));
                            }
                        }
                    }
                }
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
            
            MCvFont f = new MCvFont(Emgu.CV.CvEnum.FONT.CV_FONT_HERSHEY_PLAIN, 3.0, 3.0);
            this.image.Draw("Hello, world", ref f, new System.Drawing.Point(10, 50), new Bgr(255.0, 0.0, 0.0));

            this.backgroundImage.Source = BitmapSourceConvert.ToBitmapSource(image);
            
        }


    }
}
