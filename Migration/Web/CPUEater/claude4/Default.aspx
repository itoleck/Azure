<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="CPULoadController.Default" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>CPU Load Controller</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 50px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .status {
            background-color: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 5px;
            padding: 15px;
            margin: 20px 0;
            text-align: center;
        }
        .running {
            background-color: #d4edda;
            border-color: #c3e6cb;
            color: #155724;
        }
        .stopped {
            background-color: #f8d7da;
            border-color: #f5c6cb;
            color: #721c24;
        }
        .btn {
            background-color: #007bff;
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            display: block;
            margin: 20px auto;
            min-width: 150px;
        }
        .btn:hover {
            background-color: #0056b3;
        }
        .btn.stop {
            background-color: #dc3545;
        }
        .btn.stop:hover {
            background-color: #c82333;
        }
        .info {
            color: #6c757d;
            font-size: 14px;
            text-align: center;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="container">
            <h1>CPU Load Controller</h1>
            
            <div class="status" id="statusDiv" runat="server">
                <strong>Status:</strong> <span id="statusText" runat="server">CPU Load Stopped</span>
            </div>
            
            <asp:Button ID="btnToggleCPU" runat="server" Text="Start CPU Load (80%)" 
                CssClass="btn" OnClick="btnToggleCPU_Click" />
            
            <div class="info">
                <p><strong>Warning:</strong> This will utilize approximately 80% of your CPU resources.</p>
                <p>Click the button again to stop the CPU load.</p>
                <p>CPU cores detected: <asp:Label ID="lblCoreCount" runat="server"></asp:Label></p>
            </div>
        </div>
    </form>
</body>
</html>