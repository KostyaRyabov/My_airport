using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace Client.Controls
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class exNavigator : Frame
    {
        private int _Value = 0;

        public int Value
        {
            get => _Value;
            set
            {
                _Value = value;
                num.Text = _Value.ToString();
            }
        }

        public delegate void ReloadDelegate();
        public event ReloadDelegate reloadPage = delegate { };
        public exNavigator()
        {
            InitializeComponent();
        }
        private void Plus_Clicked(object sender, System.EventArgs e)
        {
            Value++;
            reloadPage();
        }

        private void Minus_Clicked(object sender, System.EventArgs e)
        {
            if (Value > 0)
            {
                Value--;
                reloadPage();
            }
            else Value = 0;
        }

        private void num_Unfocused(object sender, FocusEventArgs e)
        {
            Int32.TryParse(num.Text, out _Value);
            reloadPage();
        }
    }
}