using doControlLib;
using doControlLib.Environment;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace doUIViewDesign
{
    class do_ScrollView : doComponentUIView
    {
        public override void DrawControl(int _x, int _y, int _width, int _height, Graphics g)
        {
            base.DrawControl(_x, _y, _width, _height, g);
            Point point1 = new Point(_x + _width * 18 / 20, _y+12);
            Point point2 = new Point(_x + _width * 17 / 20, _y +Convert.ToInt32(Math.Sqrt(3)*(_width*1/20)) +12);
            Point point3 = new Point(_x + _width * 19 / 20, _y + Convert.ToInt32(Math.Sqrt(3) * (_width * 1 / 20)) + 12);
            Point[] pol = { point1, point2, point3 };
            g.DrawPolygon(new Pen(Color.Gray, 2), pol);
            g.FillPolygon(new SolidBrush(Color.Gray), pol);

            point1.X = _x + _width * 18 / 20;
            point1.Y = _y + _height - 12;
            point2.X = _x + _width * 17 / 20;
            point2.Y = _y + _height - Convert.ToInt32(Math.Sqrt(3) * (_width * 1 / 20)) - 12;
            point3.X = _x + _width * 19 / 20;
            point3.Y = _y + _height - Convert.ToInt32(Math.Sqrt(3) * (_width * 1 / 20)) - 12;
            Point[] pol1 = { point1, point2, point3 };
            g.DrawPolygon(new Pen(Color.Gray, 2), pol1);
            g.FillPolygon(new SolidBrush(Color.Gray), pol1);
            g.DrawLine(new Pen(Color.Gray, 2), new Point(_x + _width * 18 / 20, _y + 12), point1);
            
        }

    }
}
