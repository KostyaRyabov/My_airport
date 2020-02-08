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
    public partial class ExText : Frame, IControllResult
    {
        string _propertyName;
        public string propertyName 
        { 
            get => _propertyName; 
            set => _propertyName = value; 
        }
        public string Result {
            get => $"'{entry.Text}'";
        }
        public string _oldValue;
        public string Value {
            get => entry.Text;
            set => entry.Text = value;
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
            anim.ColorTo(this, Color.White, 300, Easing.SinInOut);
        }


        public void init(Commit_Delete_Cencel CDC)
        {
            entry.TextChanged += (s, e) =>
            {
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

        public bool IsReadOnly { get => entry.IsReadOnly; }

        public ExText(bool isReadOnly = false)
        {
            InitializeComponent();
            entry.IsReadOnly = isReadOnly;
            this.BackgroundColor = Color.FromRgb(230, 230, 230);
        }
    }
}