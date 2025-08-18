using System;
using System.Web;

namespace CPULoadController
{
    public class Global : HttpApplication
    {
        protected void Application_Start(object sender, EventArgs e)
        {
            // Code that runs on application startup
        }

        protected void Application_End(object sender, EventArgs e)
        {
            // Code that runs on application shutdown
            // Ensure any running CPU load tasks are stopped
        }

        protected void Application_Error(object sender, EventArgs e)
        {
            // Code that runs when an unhandled error occurs
            Exception exception = Server.GetLastError();
            
            // Log the exception (implement your logging mechanism)
            // For production, consider using a logging framework like NLog or log4net
        }

        protected void Session_Start(object sender, EventArgs e)
        {
            // Code that runs when a new session is started
        }

        protected void Session_End(object sender, EventArgs e)
        {
            // Code that runs when a session ends
        }
    }
}