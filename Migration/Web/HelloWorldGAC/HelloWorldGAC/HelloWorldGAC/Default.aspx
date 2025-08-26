<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="_Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Hello World Demo</title>
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
</head>
<body>
    <div class="window">
        <div class="title-bar">
            <div class="title-bar-text">Hello World GAC Demo</div>
            <div class="title-bar-controls">
                <button aria-label="Minimize" title="Minimize"></button>
                <button aria-label="Maximize" title="Maximize"></button>
                <button aria-label="Close" title="Close"></button>
            </div>
        </div>
        <div class="window-body">
            <form id="form1" runat="server">
                <div class="field-row">
                    <asp:Label ID="lblHello" runat="server" Font-Bold="true" Font-Size="Large" ></asp:Label>
                </div>
            </form>
        </div>
    </div>
</body>
</html>
