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
    public partial class exTime : Frame, IControllResult
    {
        string _propertyName;
        public string propertyName
        {
            get => _propertyName;
            set => _propertyName = value;
        }
        public string Result
        {
            get => $"'{timeP.Time.ToString()}'";
        }
        private TimeSpan _oldValue;
        public TimeSpan Value
        {
            get => timeP.Time;
            set
            {
                timeP.Time = value;
            }
        }
        public string Name
        {
            get => title.Text;
            set => title.Text = value;
        }
        public bool isChanged
        {
            get
            {
                return (_oldValue != Value);
            }
        }
        public void CommitChanges()
        {
            _oldValue = Value;
            anim.ColorTo(this, Color.White, 300, Easing.SinInOut);
        }
        public void init(Commit_Delete_Cencel CDC)
        {
            timeP.PropertyChanged += (s, e) => {
                if (e.PropertyName == TimePicker.TimeProperty.PropertyName)
                {
                    if (isChanged)
                    {
                        anim.ColorTo(this, Color.FromHex("FFC47F"), 300, Easing.SinInOut);
                        CDC.showBns();
                    }
                    else if (this.BackgroundColor == Color.FromHex("FFC47F"))
                    {
                        anim.ColorTo(this, Color.White, 300, Easing.SinInOut);
                        CDC.hideBns();
                    }
                }
            };
        }
        public exTime()
        {
            InitializeComponent();
        }
    }
}