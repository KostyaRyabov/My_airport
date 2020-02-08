using System;
using System.Collections.Generic;
using System.Text;

namespace Client.Controls
{
    public interface IControllResult
    {
        string Result { get; }
        bool isChanged { get; }
        string propertyName { get; set; }
        string Name { get; set; }
    }
}
