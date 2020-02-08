using System;
using System.Data.SqlClient;
using System.Data;
using System.Threading.Tasks;
using Xamarin.Forms;
using System.Threading;
using Client.Pages;
using System.Text.RegularExpressions;
using Xamarin.Essentials;

namespace Client
{
    public class client
    {
        string[] Login = { "GuestL", "AdminL" };
        public LoadForm loader = new LoadForm();
        public static SqlConnection con;
        public byte UID = 1;            //current
        public bool getError = false;
        Regex r = new Regex(@"^\d{1,3}[.]\d{1,3}[.]\d{1,3}[.]\d{1,3}$");          // ip-address format
        private bool checkInternet()
        {
            if (Connectivity.NetworkAccess == NetworkAccess.Internet) return true;

            cError("проверьте интернет-соединение");
            Disconnect();
            return false;
        }
        private async Task timer()
        {
            if (!loader.windowed)
            {
                await Task.Delay(1000);

                if (con.State == ConnectionState.Connecting)
                {
                    pushLoader();
                    await loader.page_open();
                }
            }

            if (loader.windowed)
            {
                Device.BeginInvokeOnMainThread(() => loader.Message = "подключение");

                loader.progress.Progress = 0;
                loader.time = 1;

                await Task.WhenAll(loader.progress.FadeTo(1, 500),
                    loader.progress.ProgressTo((float)loader.time / loader.timeout, 1000, Easing.Linear)
                );
                loader.time++;

                if (checkInternet())
                {
                    if (checkIP())
                    {
                        if (loader.pwd.Text.Length > 0)
                        {
                            while (con.State == ConnectionState.Connecting && loader.time < loader.timeout && checkInternet())
                            {
                                //after the first second the loading window appears
                                await loader.progress.ProgressTo((float)loader.time / loader.timeout, 1000, Easing.Linear);
                                loader.time++;
                            }
                        }
                        else
                        {
                            cError("введите пароль");
                            Disconnect();
                        }
                    }
                    else
                    {
                        cError("ip написан не правильно");
                        Disconnect();
                    }
                }
                else
                {
                    cError("проверьте интернет-соединение");
                    Disconnect();
                }

                await Task.WhenAll(
                    loader.progress.ProgressTo(1, 1000, Easing.Linear),
                    Task.Run(async () =>
                    {
                        await Task.Delay(500);
                        await loader.progress.FadeTo(0, 500);
                    })
                );
            }
        }
        bool checkIP()
        {
            if (r.IsMatch(loader.ip.Text))
            {
                var arr = loader.ip.Text.Split('.');

                foreach (var item in arr)
                {
                    if (int.Parse(item) > 255)
                        return false;
                }

                return true;
            }

            return false;
        }
        private async Task<bool> TryConnect(string connectionStr)
        {
            var back_task = Task.Factory.StartNew(timer).Unwrap();
            getError = false;

            try
            {
                if (con != null) con.Dispose();
                con = new SqlConnection(connectionStr);
                await con.OpenAsync();
                Device.BeginInvokeOnMainThread(() => loader.Message = "welcome");
                back_task.Wait(Timeout.Infinite);
            }
            catch (Exception ex)
            {
                if (!loader.windowed)
                {
                    pushLoader();
                    await loader.page_open();
                }

                if (ex is SqlException)
                {
                    if ((ex as SqlException).Number == 0) cError("время ожидания истекло");
                    else cError("неверный пароль");
                }

                back_task.Wait(Timeout.Infinite);

                return false;
            }

            return true;
        }
        public void Disconnect()
        {
            con.Close();
            con.Dispose();
        }
        public async Task<bool> Connection()
        {
            loader.Continue = true;

            if (UID == 0)       //admin
            {
                Device.BeginInvokeOnMainThread(() => loader.pwd.Text = "");
                UID = 1;
                pushLoader();
                Device.BeginInvokeOnMainThread(()=> loader.Message = "введите пароль");
                await loader.page_open();
                await loader.showPasswordEntry();
                Device.BeginInvokeOnMainThread(() => {
                    loader.reloadBn.IsEnabled = true;
                    loader.ip.IsEnabled = true;
                    loader.active = true;
                });
                await loader.reloadBn.FadeTo(1, 400);
                await loader.reloadBnWait();            //repeat-button or back-button
                Device.BeginInvokeOnMainThread(() => {
                    loader.reloadBn.IsEnabled = false;
                    loader.ip.IsEnabled = false;
                });
                await loader.reloadBn.FadeTo(0, 400);
            }
            else
            {
                UID = 0;   //user
                loader.active = false;          //disable buttons
                Device.BeginInvokeOnMainThread(() => loader.pwd.Text = "user");
                await Task.Delay(1000);
            }

            while (loader.Continue && !await TryConnect($@"Data Source={loader.ip.Text},1433\SQLEXPRESS;Initial Catalog = DB;user id={Login[UID]};password={loader.pwd.Text};connection timeout={loader.timeout}"))
            {
                Device.BeginInvokeOnMainThread(() => {
                    loader.reloadBn.IsEnabled = true;
                    loader.ip.IsEnabled = true;
                    loader.active = true;
                });
                await loader.reloadBn.FadeTo(1, 400);
                await loader.reloadBnWait();            //repeat-button or back-button
                Device.BeginInvokeOnMainThread(() => {
                    loader.reloadBn.IsEnabled = false;
                    loader.ip.IsEnabled = false;
                });
                await loader.reloadBn.FadeTo(0, 400);
            }

            if (UID == 1) await loader.hidePasswordEntry();
            
            if (!loader.Continue) return false;

            if (loader.windowed)
            {
                await loader.page_close();
                popLoader();
            }

            return true;
        }
        public delegate void MessageStreamDelegate(string message);
        public event MessageStreamDelegate cMessage = delegate { };
        public event MessageStreamDelegate cError = delegate { };
        public delegate void BoolDelegate();
        public event BoolDelegate pushLoader = delegate { };
        public event BoolDelegate popLoader = delegate { };
    }
}