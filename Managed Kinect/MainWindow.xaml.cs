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
// using System.Windows.Interop;
using System.Threading;
using System.Windows.Threading;
using System.Threading.Tasks;

namespace Managed_Kinect
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
        private readonly KinectSensor sensorOne;

        /// <summary>
        /// Stopwatch that determines the time.
        /// </summary>
        private readonly Stopwatch stopwatch = new Stopwatch();

        private Byte[] rawColorData = new Byte[KinectUtility.BGRA_RES];
        private short[] rawDepthData = new short[KinectUtility.LUM_RES];
        private short[] sDepthData = new short[KinectUtility.LUM_RES];
        private short[] bgDepthData = new short[KinectUtility.LUM_RES];
        private short[] fgDepthData = new short[KinectUtility.LUM_RES];

        private Byte[] cPixels = new Byte[KinectUtility.BGR_RES];
        private Byte[] dPixels = new Byte[KinectUtility.LUM_RES];
        private Byte[] dsPixels = new Byte[KinectUtility.LUM_RES];
        private Byte[] fgPixels = new Byte[KinectUtility.LUM_RES];
        private Byte[] bgPixels = new Byte[KinectUtility.LUM_RES];


        private Image<Bgr, Byte> bgr_image = new Image<Bgr, byte>(KinectUtility.CDATA);
        private Image<Gray, Byte> depth_image = new Image<Gray, byte>(KinectUtility.DDATA);
        private Image<Gray, Byte> fg_image = new Image<Gray, byte>(KinectUtility.DDATA);
        private Image<Gray, Byte> bg_image = new Image<Gray, byte>(KinectUtility.DDATA);

        // Features
        private static bool dProcessFlag = true;
        private static bool cProcessFlag = false;
        private static bool dSmootherFlag = false;

        private static bool dSubtractionFlag = false;

        private static float alpha = 0.06f;
        private static int depthC = KinectUtility.MaxDepthDistance;

        private static MCvFont _font = new MCvFont(Emgu.CV.CvEnum.FONT.CV_FONT_HERSHEY_SIMPLEX, 1.0, 1.0);

        #endregion


        public MainWindow()
        {
            InitializeComponent();
            this.SensorChooserUI.KinectSensorChooser = sensorChooser;
            this.sensorOne = KinectSensor.KinectSensors[0];
            this.sensorChooser.Start();
            Parallel.For(0, KinectUtility.RESOLUTION,
                (i) =>
                {
                    sDepthData[i] = 0;
                    bgDepthData[i] = 0;
                    fgDepthData[i] = 0;
                }
            );

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
                this.sensorOne.DepthFrameReady += new EventHandler<DepthImageFrameReadyEventArgs>(sensorOne_DepthFrameReady);
                this.sensorOne.ColorFrameReady += new EventHandler<ColorImageFrameReadyEventArgs>(sensorOne_ColorFrameReady);
            }
        }

        void sensorOne_ColorFrameReady(object sender, ColorImageFrameReadyEventArgs e)
        {
            using (ColorImageFrame colorFrame = e.OpenColorImageFrame())
            {
                if (colorFrame != null && cProcessFlag)
                {
                    #region Color Processing
                    colorFrame.CopyPixelDataTo(this.rawColorData);
                    Parallel.For(0, KinectUtility.RESOLUTION,
                        (c_i) =>
                        {
                            int bgrIndex = (int)c_i * 3;
                            int bgraIndex = (int)c_i * 4;
                            this.cPixels[bgrIndex++] = this.rawColorData[bgraIndex++];
                            this.cPixels[bgrIndex++] = this.rawColorData[bgraIndex++];
                            this.cPixels[bgrIndex] = this.rawColorData[bgraIndex];
                        }
                    );
                    #endregion

                    this.bgr_image.Bytes = cPixels;
                    this.ImageL1.Source = BitmapSourceConvert.ToBitmapSource(this.bgr_image);
                    this.CFPS.Content = KinectUtility.CalculateColorFrameRate().ToString();
                    //bgr_image.Save("c:\\Users\\elderlab\\sitting\\test-"+imgname.ToString()+".png");
                    //this.imgname++;
                }
            }
        }

        void sensorOne_DepthFrameReady(object sender, DepthImageFrameReadyEventArgs e)
        {
            using (DepthImageFrame depthFrame = e.OpenDepthImageFrame())
            {
                if (depthFrame != null && dProcessFlag)
                {
                    processDepthData(depthFrame);
                    if (dSubtractionFlag)
                    {
                        this.fg_image.Bytes = fgPixels;
                        this.bg_image.Bytes = bgPixels;
                        this.ImageL1.Source = BitmapSourceConvert.ToBitmapSource(this.fg_image);
                        this.ImageL2.Source = BitmapSourceConvert.ToBitmapSource(this.bg_image);
                    }
                    else
                    {
                        this.depth_image.Bytes = dSmootherFlag ? dsPixels : dPixels;
                        this.ImageL2.Source = BitmapSourceConvert.ToBitmapSource(this.depth_image);
                    }
                    this.DFPS.Content = KinectUtility.CalculateDepthFrameRate().ToString();
                    //depth_image.Save("c:\\Users\\elderlab\\sittingd\\test-" + imgname.ToString() + ".png");
                    //this.imgname++;
                }

            }
        }

        //void ProcessImage()
        //{
        //    if (this.bgr_image != null)
        //    {
        //        // Thread.Sleep(10000);
        //        if (Thread.CurrentThread.Name == null)
        //        {
        //            Thread.CurrentThread.Name = "Processing Image";
        //        }
        //        this.bgr_image._SmoothGaussian(3);
        //        _detector.Update(this.bgr_image);
        //        this.forgroundMask = _detector.ForgroundMask;

        //        _tracker.Process(bgr_image, forgroundMask);

        //        foreach (MCvBlob blob in _tracker)
        //        {
        //            Console.WriteLine(blob.Center.X.ToString() + " " + blob.Center.Y.ToString());
        //            bgr_image.Draw((System.Drawing.Rectangle)blob, new Bgr(255.0, 255.0, 255.0), 2);
        //            bgr_image.Draw(blob.ID.ToString(), ref _font, System.Drawing.Point.Round(blob.Center), new Bgr(255.0, 255.0, 255.0));
        //        }

        //        this.cvnImage.Dispatcher.Invoke(
        //            new Action(() => this.cvnImage.Source = BitmapSourceConvert.ToBitmapSource(bgr_image)),
        //            DispatcherPriority.ApplicationIdle, null);
        //        this.cvbImage.Dispatcher.Invoke(
        //            new Action(() => this.cvbImage.Source = BitmapSourceConvert.ToBitmapSource(forgroundMask)),
        //            DispatcherPriority.ApplicationIdle, null);
        //        // this.cvnImage.Source = BitmapSourceConvert.ToBitmapSource(bgr_image);
        //        // this.cvnImage.Source = BitmapSourceConvert.ToBitmapSource(_detector.BackgroundMask);
        //        // this.cvbImage.Source = BitmapSourceConvert.ToBitmapSource(forgroundMask);
        //    }
        //}


        ///// <summary>
        ///// Method to convert native depth data from the sensor to colored pixels
        ///// </summary>
        ///// <param name="depthFrame"> Depth frame data from the sensor</param>
        //// private byte[] getColorBytes(ColorImageFrame colorFrame)
        //private void processColorData(ColorImageFrame colorFrame)
        //{
        //    colorFrame.CopyPixelDataTo(this.rawColorData);
        //    Parallel.For(0, RESOLUTION,
        //        (colorIndex) =>
        //        {
        //            int bgrIndex = (int)colorIndex * 3;
        //            int bgraIndex = (int)colorIndex * 4;
        //            this.cPixels[bgrIndex++] = this.rawColorData[bgraIndex++];
        //            this.cPixels[bgrIndex++] = this.rawColorData[bgraIndex++];
        //            this.cPixels[bgrIndex] = this.rawColorData[bgraIndex];
        //        }
        //    );
        //}

        /// <summary>
        /// Method to convert native depth data from the sensor to colored pixels
        /// </summary>
        /// <param name="depthFrame"> Depth frame data from the sensor</param>
        private void processDepthData(DepthImageFrame depthFrame)
        {
            depthFrame.CopyPixelDataTo(rawDepthData);

            Parallel.For(0, KinectUtility.RESOLUTION,
                (d_i) =>
                {
                    short depth = (short)(rawDepthData[d_i] >> DepthImageFrame.PlayerIndexBitmaskWidth);

                    if (dSmootherFlag)
                    {
                        if (depth > 0)
                        {
                            sDepthData[d_i] = (short)((alpha * depth + (1 - alpha) * sDepthData[d_i]));

                        }
                        dsPixels[d_i] = KinectUtility.getDepthBGBytes(sDepthData[d_i]);
                    }
                    else if (dSubtractionFlag)
                    {
                        if (depth > 0)
                        {
                            if (bgDepthData[d_i] - depth > 64)
                            {
                                // Foreground
                                fgDepthData[d_i] = depth;
                                bgDepthData[d_i] = bgDepthData[d_i];
                            }
                            else
                            {
                                fgDepthData[d_i] = 0;
                                bgDepthData[d_i] = (short)((alpha * depth + (1 - alpha) * bgDepthData[d_i]));
                            }
                        }
                        fgPixels[d_i] = KinectUtility.getDepthBGBytes(fgDepthData[d_i]);
                        bgPixels[d_i] = KinectUtility.getDepthBGBytes(bgDepthData[d_i]);
                    }
                    else
                    {
                        dPixels[d_i] = KinectUtility.getDepthBGBytes(depth);
                    }
                }
            );
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
            //var displayMap = new PlanarMap();
            //displayMap.Show();
            //this.thread = new Thread(ProcessImage);
            //thread.Start();
        }
        
        private void check_depth_smoother_Click(object sender, RoutedEventArgs e)
        {
            dSmootherFlag = dSmootherFlag ? false : true;
        }

        private void check_color_Click(object sender, RoutedEventArgs e)
        {
            cProcessFlag = cProcessFlag ? false : true;
        }

        private void check_depth_Click(object sender, RoutedEventArgs e)
        {
            dProcessFlag = dProcessFlag ? false : true;
        }

        private void check_depth_subtraction_Click(object sender, RoutedEventArgs e)
        {
            dSubtractionFlag = dSubtractionFlag ? false : true;
        }
    }
}
