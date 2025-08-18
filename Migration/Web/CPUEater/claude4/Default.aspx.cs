using System;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using System.Web.UI;

namespace CPULoadController
{
    public partial class Default : System.Web.UI.Page
    {
        private static volatile bool _isRunning = false;
        private static CancellationTokenSource _cancellationTokenSource;
        private static Task[] _cpuTasks;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                lblCoreCount.Text = Environment.ProcessorCount.ToString();
                UpdateUI();
            }
        }

        protected void btnToggleCPU_Click(object sender, EventArgs e)
        {
            if (_isRunning)
            {
                StopCPULoad();
            }
            else
            {
                StartCPULoad();
            }
            UpdateUI();
        }

        private void StartCPULoad()
        {
            try
            {
                _isRunning = true;
                _cancellationTokenSource = new CancellationTokenSource();
                
                // Calculate number of threads to use (80% of CPU cores)
                int coreCount = Environment.ProcessorCount;
                int threadsToUse = Math.Max(1, (int)(coreCount * 0.8));
                
                _cpuTasks = new Task[threadsToUse];
                
                // Start CPU intensive tasks
                for (int i = 0; i < threadsToUse; i++)
                {
                    _cpuTasks[i] = Task.Run(() => CPULoadWorker(_cancellationTokenSource.Token));
                }
            }
            catch (Exception ex)
            {
                // Log error or handle as needed
                _isRunning = false;
            }
        }

        private void StopCPULoad()
        {
            try
            {
                _isRunning = false;
                
                if (_cancellationTokenSource != null)
                {
                    _cancellationTokenSource.Cancel();
                }
                
                if (_cpuTasks != null)
                {
                    // Wait for all tasks to complete with timeout
                    Task.WaitAll(_cpuTasks, TimeSpan.FromSeconds(5));
                }
            }
            catch (Exception ex)
            {
                // Log error or handle as needed
            }
            finally
            {
                _cancellationTokenSource?.Dispose();
                _cancellationTokenSource = null;
                _cpuTasks = null;
            }
        }

        private void CPULoadWorker(CancellationToken cancellationToken)
        {
            var stopwatch = Stopwatch.StartNew();
            
            while (!cancellationToken.IsCancellationRequested)
            {
                // CPU intensive work for about 80ms
                var start = stopwatch.ElapsedMilliseconds;
                while (stopwatch.ElapsedMilliseconds - start < 80)
                {
                    if (cancellationToken.IsCancellationRequested)
                        return;
                    
                    // Perform CPU-intensive mathematical operations
                    double result = 0;
                    for (int i = 0; i < 10000; i++)
                    {
                        result += Math.Sqrt(i) * Math.Sin(i) * Math.Cos(i);
                    }
                }
                
                // Small sleep to allow for approximately 80% CPU usage
                // This creates a duty cycle: work for 80ms, sleep for 20ms
                Thread.Sleep(20);
            }
        }

        private void UpdateUI()
        {
            if (_isRunning)
            {
                btnToggleCPU.Text = "Stop CPU Load";
                btnToggleCPU.CssClass = "btn stop";
                statusText.InnerText = "CPU Load Running (80%)";
                statusDiv.Attributes["class"] = "status running";
            }
            else
            {
                btnToggleCPU.Text = "Start CPU Load (80%)";
                btnToggleCPU.CssClass = "btn";
                statusText.InnerText = "CPU Load Stopped";
                statusDiv.Attributes["class"] = "status stopped";
            }
        }

        protected override void OnUnload(EventArgs e)
        {
            // Ensure we stop CPU load when page is unloaded
            if (_isRunning)
            {
                StopCPULoad();
            }
            base.OnUnload(e);
        }
    }
}