<%@ Page Language="C#" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Threading.Tasks" %>
<%@ Import Namespace="System.Diagnostics" %>

<!DOCTYPE html>
<html>
<head>
    <title>CPU Load Controller</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 50px auto; 
            max-width: 500px;
            text-align: center;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .status {
            padding: 15px;
            margin: 20px 0;
            border-radius: 5px;
            font-weight: bold;
        }
        .running { background: #d4edda; color: #155724; }
        .stopped { background: #f8d7da; color: #721c24; }
        .btn {
            padding: 15px 30px;
            font-size: 16px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            margin: 10px;
            min-width: 200px;
        }
        .start { background: #28a745; color: white; }
        .stop { background: #dc3545; color: white; }
        .start:hover { background: #218838; }
        .stop:hover { background: #c82333; }
    </style>
</head>
<body>
    <div class="container">
        <h1>CPU Load Controller</h1>
        
        <div class="status <%=GetStatusClass()%>">
            Status: <%=GetStatusText()%>
        </div>
        
        <form method="post" runat="server">
            <asp:Button ID="btnToggle" runat="server" OnClick="ToggleButton_Click" 
                       Text="" CssClass="" />
        </form>
        
        <p><small>CPU Cores: <%=Environment.ProcessorCount%></small></p>
        <p><small><strong>Warning:</strong> This will use 80% of your CPU resources</small></p>
    </div>

    <script runat="server">
        private bool IsRunning
        {
            get 
            { 
                object running = Application["CPULoadRunning"];
                if (running == null) return false;
                return (bool)running;
            }
            set 
            { 
                Application["CPULoadRunning"] = value;
            }
        }

        private CancellationTokenSource GetCancellationTokenSource()
        {
            return Application["CPUCancellationToken"] as CancellationTokenSource;
        }

        private void SetCancellationTokenSource(CancellationTokenSource source)
        {
            Application["CPUCancellationToken"] = source;
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            UpdateButtonUI();
        }

        private void UpdateButtonUI()
        {
            if (IsRunning)
            {
                btnToggle.Text = "Stop CPU Load";
                btnToggle.CssClass = "btn stop";
            }
            else
            {
                btnToggle.Text = "Start CPU Load (80%)";
                btnToggle.CssClass = "btn start";
            }
        }

        protected string GetStatusClass()
        {
            return IsRunning ? "running" : "stopped";
        }

        protected string GetStatusText()
        {
            return IsRunning ? "CPU Load Running (80%)" : "CPU Load Stopped";
        }

        protected void ToggleButton_Click(object sender, EventArgs e)
        {
            if (IsRunning)
            {
                StopCPULoad();
            }
            else
            {
                StartCPULoad();
            }
            UpdateButtonUI();
        }

        private void StartCPULoad()
        {
            try
            {
                StopCPULoad();
                
                IsRunning = true;
                CancellationTokenSource cancellationTokenSource = new CancellationTokenSource();
                SetCancellationTokenSource(cancellationTokenSource);
                
                int coreCount = Environment.ProcessorCount;
                int threadsToUse = Math.Max(1, (int)(coreCount * 0.8));
                
                for (int i = 0; i < threadsToUse; i++)
                {
                    Task.Run(() => CPULoadWorker(cancellationTokenSource.Token));
                }
            }
            catch (Exception)
            {
                IsRunning = false;
            }
        }

        private void StopCPULoad()
        {
            try
            {
                IsRunning = false;
                
                CancellationTokenSource cancellationTokenSource = GetCancellationTokenSource();
                if (cancellationTokenSource != null)
                {
                    cancellationTokenSource.Cancel();
                    cancellationTokenSource.Dispose();
                    SetCancellationTokenSource(null);
                }
            }
            catch (Exception)
            {
                // Handle exception
            }
        }

        private void CPULoadWorker(CancellationToken cancellationToken)
        {
            Random random = new Random();
            
            while (!cancellationToken.IsCancellationRequested)
            {
                try
                {
                    int startTime = Environment.TickCount;
                    
                    while (Environment.TickCount - startTime < 80 && !cancellationToken.IsCancellationRequested)
                    {
                        double result = 0;
                        for (int i = 0; i < 5000; i++)
                        {
                            double val = random.NextDouble() * 1000;
                            result += Math.Sqrt(val) * Math.Sin(val) * Math.Cos(val);
                        }
                        
                        if (result == double.MaxValue) break;
                    }
                    
                    if (!cancellationToken.IsCancellationRequested)
                    {
                        Thread.Sleep(20);
                    }
                }
                catch (OperationCanceledException)
                {
                    break;
                }
                catch (Exception)
                {
                    break;
                }
            }
        }

        protected override void OnUnload(EventArgs e)
        {
            if (IsRunning)
            {
                StopCPULoad();
            }
            base.OnUnload(e);
        }
    </script>
</body>
</html>