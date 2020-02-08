using Xamarin.Forms;
using Xamarin.Forms.Xaml;

using System;

namespace Client.Controls
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class exSlider : Frame, IControllResult
    {
        string _propertyName;
        public string propertyName
        {
            get => _propertyName;
            set => _propertyName = value;
        }
        public string Result
        {
            get => entry.Text;
        }
        public exSlider()
        {
            InitializeComponent();
        }
        public void init(Commit_Delete_Cencel CDC)
        {
            entry.TextChanged += (s, e) => {
                if (isChanged)
                {
                    if (this.BackgroundColor == Color.White)
                    {
                        anim.ColorTo(this, Color.FromHex("FFC47F"), 300, Easing.SinInOut);
                        CDC.showBns();
                    }
                }
                else if (this.BackgroundColor == Color.FromHex("FFC47F"))
                {
                    anim.ColorTo(this, Color.White, 300, Easing.SinInOut);
                    CDC.hideBns();
                }
            };
        }

        public string Name
        {
            get => title.Text;
            set => title.Text = value;
        }

        private int _oldValue;
        public int Value
        {
            get => (int)slider.Value;
            set
            {
                slider.Value = value;
            }
        }

        public int Maximum
        {
            get => (int)slider.Maximum;
            set
            {
                slider.Maximum = value;
            }
        }
        public bool isChanged { get => (_oldValue != Value); }
        public void CommitChanges()
        {
            _oldValue = (int)Value;
            anim.ColorTo(this, Color.White, 300, Easing.SinInOut);
        }

        //проверить на зацикленность
        private void OnValueChanged(object sender, ValueChangedEventArgs e)
        {
            entry.Text = ((int)e.NewValue).ToString();
        }
        private void OnTextChanged(object sender, TextChangedEventArgs e)
        {
            string sNum = entry.Text;
            int iNum;

            if (sNum.Length > 0)
            {
                if ((iNum = sNum.IndexOf('-')) != -1 || (iNum = sNum.IndexOf(',')) != -1) entry.Text = entry.Text.Remove(iNum, 1);
                else
                {
                    iNum = int.Parse(sNum);

                    if (iNum > slider.Maximum) entry.Text = slider.Maximum.ToString();
                    else slider.Value = iNum;
                }
            }
            else entry.Text = "0";
        }


        private void Plus_Clicked(object sender, System.EventArgs e)
        {
            if ((int)Value < slider.Maximum) Value++;
            else Value = (int)slider.Maximum;
        }

        private void Minus_Clicked(object sender, System.EventArgs e)
        {
            if ((int)Value > 0) Value--;
            else Value = 0;
        }
    }
}