using System;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace Client
{
    static class anim
    {
        public static void ColorTo(VisualElement self, Color fromColor, Color toColor, uint length = 250, Easing easing = null)
        {
            Func<double, Color> transform = (t) =>
              Color.FromRgba(fromColor.R + t * (toColor.R - fromColor.R),
                             fromColor.G + t * (toColor.G - fromColor.G),
                             fromColor.B + t * (toColor.B - fromColor.B),
                             1);

            Task.Factory.StartNew(() => self.Animate("CBGC", new Animation(t => self.BackgroundColor = transform(t), 0, 1), 16, length, easing));
        }
        public static void ColorTo(VisualElement self, Color toColor, uint length = 250, Easing easing = null)
        {
            Color fromColor = self.BackgroundColor;

            Func<double, Color> transform = (t) =>
              Color.FromRgba(fromColor.R + t * (toColor.R - fromColor.R),
                             fromColor.G + t * (toColor.G - fromColor.G),
                             fromColor.B + t * (toColor.B - fromColor.B),
                             1);

            Task.Factory.StartNew(() => self.Animate("CBGC", new Animation(t => self.BackgroundColor = transform(t), 0, 1), 16, length, easing));
        }
    }
}
