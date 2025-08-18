<%@ Page Language="C#" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>CPU Utilization Demo</title>
    <link rel="stylesheet" href="/css/xp.css" />
    <style>
        body {
            background-image: url('/images/SSqqQ53.jpg');
            background-size: cover;
            background-position: center;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0;
            font-family: Tahoma, sans-serif;
        }
        .window {
            width: 480px;
        }
        .window-body {
            padding: 20px;
            text-align: center;
        }
    </style>
    <script type="text/javascript">
        window.addEventListener('load', function () {
            var slider = document.getElementById('cpuSlider');
            var output = document.getElementById('sliderValue');
            output.textContent = slider.value;
            slider.addEventListener('input', function () {
                output.textContent = this.value;
            });
        });
    </script>
</head>
<body>
    <div class="window">
        <div class="title-bar">
            <div class="title-bar-text">CPU Utilization Demo</div>
            <div class="title-bar-controls">
                <button aria-label="Minimize" title="Minimize"></button>
                <button aria-label="Maximize" title="Maximize"></button>
                <button aria-label="Close" title="Close"></button>
            </div>
        </div>
        <div class="window-body">
            <div><p style="text-align:center;"><h2>CPU Eater v2.0</h2></p></div>
            <form id="form1" runat="server">
                <div class="field-row">
                    <label for="cpuSlider">CPU Utilization (%):</label>
                    <input id="cpuSlider" name="cpuSlider" type="range" min="10" max="80" value="50" step="10" />
                    <span id="sliderValue">50</span>%
                </div>
                <div>
                    <asp:Button ID="btnToggle" runat="server" Text="Start CPU Utilization" OnClick="btnToggle_Click" />
                </div>
            </form>
        </div>
    </div>
</body>
</html>

<script runat="server">
    private static bool _running = false;
    private static System.Threading.CancellationTokenSource _cts;
    private static readonly System.Collections.Generic.List<System.Threading.Tasks.Task> _tasks = new System.Collections.Generic.List<System.Threading.Tasks.Task>();

    protected void btnToggle_Click(object sender, System.EventArgs e)
    {
        if (!_running)
        {
            StartCpuUtilization();
            btnToggle.Text = "Stop CPU Utilization";
        }
        else
        {
            StopCpuUtilization();
            btnToggle.Text = "Start CPU Utilization";
        }
        _running = !_running;
    }

    private void StartCpuUtilization()
    {
        _cts = new System.Threading.CancellationTokenSource();
        int numCores = System.Environment.ProcessorCount;
        int utilizationPercentage = int.Parse(Request.Form["cpuSlider"]);
        double factor = utilizationPercentage / 100.0;
        int numThreads = (int)System.Math.Floor((double)numCores * factor);
        if (numThreads == 0 && utilizationPercentage > 0) numThreads = 1; // Ensure at least one thread for minimal utilization

        for (int i = 0; i < numThreads; i++)
        {
            var task = System.Threading.Tasks.Task.Run(() =>
            {
                long counter = 0;
                var token = _cts.Token;
                while (!token.IsCancellationRequested)
                {
                    counter++;
                    if (counter == long.MaxValue) counter = 0; // Prevent overflow, though unlikely
                }
            }, _cts.Token);
            _tasks.Add(task);
        }
    }

    private void StopCpuUtilization()
    {
        _cts.Cancel();
        try
        {
            System.Threading.Tasks.Task.WaitAll(_tasks.ToArray());
        }
        catch (System.AggregateException) { } // Handle any task exceptions if needed
        _tasks.Clear();
        _cts.Dispose();
        _cts = null;
    }
</script>