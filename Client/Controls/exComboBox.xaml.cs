using System.Collections.Generic;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace Client.Controls
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class exComboBox : Frame, IControllResult
    {
        string _propertyName;
        public string propertyName
        {
            get => _propertyName;
            set => _propertyName = value;
        }
        public string Result
        {
            get
            {
                if (picker.SelectedIndex <= 0) return "null";
                return picker.SelectedIndex.ToString();
            }
        }
        public Dictionary<int,int> keys = new Dictionary<int, int>();

        public int _oldValue;
        public int Value {
            get => keys[picker.SelectedIndex];
            set
            {
                if (value < 0) picker.SelectedIndex = 0;
                else picker.SelectedIndex = value;
            }
        }
        public string Name
        {
            get => title.Text;
            set => title.Text = value;
        }
        public bool isChanged { get => (_oldValue != picker.SelectedIndex); }
        public void CommitChanges()
        {
            if (_oldValue < 0) picker.SelectedIndex = 0;
            else _oldValue = picker.SelectedIndex;
            anim.ColorTo(this, Color.White, 300, Easing.SinInOut);
        }

        public void init(Commit_Delete_Cencel CDC)
        {
            picker.SelectedIndexChanged += (s, e) => {
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
        }
        public exComboBox()
        {
            InitializeComponent();
        }
    }
}