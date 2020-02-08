using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;

using Client.Pages;

namespace Client.Controls
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class Commit_Delete_Cencel : Frame
    {
        private StackLayout own;
        private byte counter = 0;
        public void showBns()
        {
            if (counter++ < 1)
            {
                this.Animate("showBns", new Animation(t =>
                {
                    commit.Width = new GridLength(t, GridUnitType.Star);
                    cancel.Width = new GridLength(t, GridUnitType.Star);
                }, 0, 1), 16, 300);
            }
        }
        public void hideBns()
        {
            if (--counter == 0)
            {
                this.Animate("showBns", new Animation(t =>
                {
                    commit.Width = new GridLength(t, GridUnitType.Star);
                    cancel.Width = new GridLength(t, GridUnitType.Star);
                }, 1, 0), 16, 300);
            }
        }

        private void Select()
        {
            sqlClicked("select", DataView.curTable);
        }
        private void Update()
        {
            string args = "";

            for (int i = 0; i < own.Children.Count-2; i++)
            {
                var item = own.Children[i] as IControllResult;
                if (item.isChanged) args += $"[{item.propertyName}]={item.Result},";
            }

            if (args.Length > 0) args = args.Remove(args.Length - 1);
            args += $" where id={(own.Children[own.Children.Count - 2] as Label).Text}";

            sqlClicked("update", args);
        }
        private void Delete()
        {
            sqlClicked("delete", (own.Children[own.Children.Count-2] as Label).Text);
        }

        public Commit_Delete_Cencel(StackLayout own)
        {
            InitializeComponent();

            this.own = own;

            cancelBn.Clicked += (s, e) => Select();
            commitBn.Clicked += (s, e) => Update();
            deleteBn.Clicked += (s, e) => Delete();
        }

        public delegate void ButtonDelegate(string type, string args = "");
        public event ButtonDelegate sqlClicked = delegate { };
    }
}