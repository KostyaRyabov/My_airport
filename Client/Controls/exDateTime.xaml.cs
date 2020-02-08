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
    public partial class exDateTime : Frame, IControllResult
    {
        string _propertyName;
        public string propertyName
        {
            get => _propertyName;
            set => _propertyName = value;
        }
        public string Result
        {
            //'2010-12-31T00:00:00'
            get => $"'{dataP.Date.Year}-{dataP.Date.Month}-{dataP.Date.Day.ToString("00")}T{timeP.Time.Hours.ToString("00")}:{timeP.Time.Minutes.ToString("00")}:{timeP.Time.Seconds.ToString("00")}'";
        }
        private DateTime _oldValue;
        public DateTime Value
        {
            get => dataP.Date + timeP.Time;
            set 
            {
                dataP.Date = value;
                timeP.Time = value.TimeOfDay;
            }
        }
        public string Name
        {
            get => title.Text;
            set => title.Text = value;
        }
        public bool isChanged {
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
            dataP.DateSelected += (s, e) => {
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
            };

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
        public exDateTime()
        {
            InitializeComponent();
        }
    }
}