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
    public partial class exCheckBox : Frame, IControllResult
    {
        string _propertyName;
        public string propertyName
        {
            get => _propertyName;
            set => _propertyName = value;
        }
        public string Result
        {
            get => cb.IsChecked?"1":"0";
        }
        private bool _oldValue;
        public bool Value
        {
            get => cb.IsChecked;
            set => cb.IsChecked = value;
        }
        public string Name
        {
            get => title.Text;
            set => title.Text = value;
        }
        public bool isChanged { get => (_oldValue != Value); }
        public void CommitChanges()
        {
            _oldValue = Value;
            anim.ColorTo(this, Color.FromHex("FFC47F"), Color.White, 300, Easing.SinInOut);
        }
        public void init(Commit_Delete_Cencel CDC)
        {
            cb.CheckedChanged += (s, e) => {
                if (isChanged)
                {
                    anim.ColorTo(this, Color.White, Color.FromHex("FFC47F"), 300, Easing.SinInOut);
                    CDC.showBns();
                }
                else
                {
                    anim.ColorTo(this, Color.FromHex("FFC47F"), Color.White, 300, Easing.SinInOut);
                    CDC.hideBns();
                }
            };
        }
        public exCheckBox()
        {
            InitializeComponent();
        }
    }
}