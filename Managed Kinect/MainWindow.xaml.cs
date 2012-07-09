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
using Microsoft.Samples.Kinect.WpfViewers;
using System.Diagnostics;
using System.Threading;
using System.IO;
using System.Globalization;

namespace Managed_Kinect
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        /// <summary>
        /// KinectSensorChooser used to manage kinect sensors.
        /// </summary>
        private readonly KinectSensorChooser sensorChooser = new KinectSensorChooser();

        /// <summary>
        /// Intermediate storage for the color data received from the camera
        /// </summary>
        private byte[] colorPixels;

        /// <summary>
        /// Bitmap that will hold color information
        /// </summary>
        private WriteableBitmap colorBitmap;

        /// <summary>
        /// Stopwatch that determines the time.
        /// </summary>
        private readonly Stopwatch stopwatch = new Stopwatch();

        /// <summary>
        /// The path of the stream.
        /// </summary>
        private readonly StreamWriter file = new StreamWriter("C:\\Kinect\\test.txt",true);

        /// <summary>
        /// Last remembered timestamp.
        /// </summary>
        private int prevTimeStamp = 0;

        public MainWindow()
        {
            InitializeComponent();
            this.SensorChooserUI.KinectSensorChooser = sensorChooser;
            sensorChooser.Start();
        }
        

        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
            if (this.sensorChooser.Kinect != null )
            {
                this.colorPixels = new byte[this.sensorChooser.Kinect.ColorStream.FramePixelDataLength];
                
                // This is the bitmap we'll display on-screen
                this.colorBitmap = new WriteableBitmap(this.sensorChooser.Kinect.ColorStream.FrameWidth, 
                    this.sensorChooser.Kinect.ColorStream.FrameHeight, 96.0, 96.0, PixelFormats.Bgr32, null);

                this.sensorChooser.Kinect.ColorFrameReady += this.SensorColorFrameReady;
            }
            
        }

        /// <summary>
        /// Event handler for Kinect sensor's ColorFrameReady event
        /// </summary>
        /// <param name="sender">object sending the event</param>
        /// <param name="e">event arguments</param>
        private void SensorColorFrameReady(object sender, ColorImageFrameReadyEventArgs e)
        {
            int currenttime = 0;

            using (ColorImageFrame colorFrame = e.OpenColorImageFrame())
            {
                if (colorFrame != null && (currenttime = (Int32.Parse(colorFrame.Timestamp.ToString())) / 100) % 10 == 0
                    && this.prevTimeStamp != currenttime && this.colorBitmap != null)
                {
                    // Copy the pixel data from the image to a temporary array
                    colorFrame.CopyPixelDataTo(this.colorPixels);

                    Console.WriteLine(currenttime);
                    this.prevTimeStamp = currenttime;

                    // create a png bitmap encoder which knows how to save a .png file
                    BitmapEncoder encoder = new PngBitmapEncoder();
                    encoder.Frames.Add(BitmapFrame.Create(this.colorBitmap));

                    string myPhotos = Environment.GetFolderPath(Environment.SpecialFolder.MyPictures);

                    string path = System.IO.Path.Combine(myPhotos, "Kinect-" + currenttime + ".png");

                    try
                    {
                        using (FileStream fs = new FileStream(path, FileMode.Create))
                        {
                            encoder.Save(fs);
                        }

                        Console.WriteLine(string.Format("Success {0}", path));
                    }
                    catch (IOException)
                    {
                        Console.WriteLine(string.Format("Failed {0}", path));
                    }

                    // Write the pixel data into our bitmap
                    this.colorBitmap.WritePixels(
                        new Int32Rect(0, 0, this.colorBitmap.PixelWidth, this.colorBitmap.PixelHeight),
                        this.colorPixels,
                        this.colorBitmap.PixelWidth * sizeof(int),
                        0);
                }
            }
        }

        /// <summary>
        /// Event handler for window closing event.
        /// </summary>
        /// <param name="sender">object sending the event.</param>
        /// <param name="e">event arguments.</param>
        private void Window_Closing(object sender, System.ComponentModel.CancelEventArgs e)
        {

        }

        private void button1_Click(object sender, RoutedEventArgs e)
        {
            Console.WriteLine("Clicked");
        }
    }
}

