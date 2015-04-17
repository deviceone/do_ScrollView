using doCore.Helper;
using doCore.Helper.JsonParse;
using doCore.Interface;
using doCore.Object;
using do_ScrollView.extdefine;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using Windows.Storage;
using Windows.Storage.Streams;
using Windows.UI;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Media;
using Windows.UI.Xaml.Media.Imaging;
using Windows.UI.Text;
using doCore;

namespace do_ScrollView.extimplement
{
    /// <summary>
    /// 自定义扩展UIView组件实现类，此类必须继承相应控件类或UserControl类，并实现doIUIModuleView,@TYPEID_IMethod接口；
    /// #如何调用组件自定义事件？可以通过如下方法触发事件：
    /// this.model.EventCenter.fireEvent(_messageName, jsonResult);
    /// 参数解释：@_messageName字符串事件名称，@jsonResult传递事件参数对象；
    /// 获取doInvokeResult对象方式new doInvokeResult(model.UniqueKey);
    /// </summary>
    public class do_ScrollView_View : UserControl, doIUIModuleView
    {
        /// <summary>
        /// 每个UIview都会引用一个具体的model实例；
        /// </summary>
        private do_ScrollView_Model model;
        ScrollViewer scroll = new ScrollViewer();
        public do_ScrollView_View()
        {
        }
        public void LoadView(doUIModule _doComponentUI)
        {
            this.model = _doComponentUI as do_ScrollView_Model;
            this.HorizontalAlignment = Windows.UI.Xaml.HorizontalAlignment.Left;
            this.VerticalAlignment = Windows.UI.Xaml.VerticalAlignment.Top;
            this.Content = scroll;
            if (this.model.ChildUIComponents.Count == 1)
            {
                doUIModule _childUI = this.model.ChildUIComponents[0];
                if (_childUI.CurrentComponentUIView != null)
                {
                    FrameworkElement _view = _childUI.CurrentComponentUIView as FrameworkElement;
                    scroll.Content = _view;
                }
            }
            scroll.HorizontalScrollBarVisibility = ScrollBarVisibility.Hidden;
            scroll.VerticalScrollBarVisibility = ScrollBarVisibility.Hidden;
            scroll.VerticalScrollMode = ScrollMode.Enabled;
                scroll.HorizontalScrollMode = ScrollMode.Disabled;
        }
        public doUIModule GetModel()
        {
            return this.model;
        }

        public void OnRedraw()
        {
            var tp = doUIModuleHelper.GetThickness(this.model);
            this.Margin = tp.Item1;
            this.Width = tp.Item2;
            this.Height = tp.Item3;
            if (this.model.ChildUIComponents.Count == 1)
            {
                doUIModule _childUI = this.model.ChildUIComponents[0];
                _childUI.CurrentComponentUIView.OnRedraw();
            }
        }

        public void OnDispose()
        {

        }

        public bool OnPropertiesChanging(Dictionary<string, string> _changedValues)
        {
            return true;
        }

        public void OnPropertiesChanged(Dictionary<string, string> _changedValues)
        {
            doUIModuleHelper.HandleBasicViewProperChanged(this.model, _changedValues);
            if (_changedValues.Keys.Contains("isShowbar"))
            {
                if (_changedValues["isShowbar"] == "true")
                {
                    scroll.HorizontalScrollBarVisibility = ScrollBarVisibility.Visible;
                    scroll.VerticalScrollBarVisibility = ScrollBarVisibility.Visible;
                }
                else
                {
                    scroll.HorizontalScrollBarVisibility = ScrollBarVisibility.Hidden;
                    scroll.VerticalScrollBarVisibility = ScrollBarVisibility.Hidden;
                }
            }
            


            if (_changedValues.Keys.Contains("direction"))
            {
                if (_changedValues["direction"] == "horizontal")
                {
                    scroll.VerticalScrollMode = ScrollMode.Disabled;
                    scroll.HorizontalScrollMode = ScrollMode.Enabled;
                }
                else
                {
                    scroll.VerticalScrollMode = ScrollMode.Enabled;
                    scroll.HorizontalScrollMode = ScrollMode.Disabled;
                }
            }

            if (_changedValues.Keys.Contains("headerView"))
            {

            }
            if (_changedValues.Keys.Contains("bgColor"))
            {
                scroll.Background = doUIModuleHelper.GetColorFromString(_changedValues["bgColor"], new SolidColorBrush(Colors.White));
            }
        }
        public bool InvokeSyncMethod(string _methodName, doJsonNode _dictParas, doIScriptEngine _scriptEngine, doInvokeResult _invokeResult)
        {
            if ("toBegin".Equals(_methodName))
            {
                this.toBegin(_dictParas, _scriptEngine, _invokeResult);
                return true;
            }
            if ("toEnd".Equals(_methodName))
            {
                this.toEnd(_dictParas, _scriptEngine, _invokeResult);
                return true;
            }
            return false;
        }

        public bool InvokeAsyncMethod(string _methodName, doJsonNode _dictParas, doIScriptEngine _scriptEngine, string _callbackFuncName)
        {
            return false;
        }

        //=========================================================================

        private void toBegin(doJsonNode _dictParas, doIScriptEngine _scriptEngine, doInvokeResult _invokeResult)
        {
            try
            {
                if (this.model.GetPropertyValue("direction") == "horizontal")
                {
                    scroll.ChangeView(0, null, null);
                }
                else
                {
                    scroll.ChangeView(null,0, null);
                }

            }
            catch (Exception _err)
            {
                doServiceContainer.LogEngine.WriteError("doScrollView toBegin \n", _err);
            }
        }
        private void toEnd(doJsonNode _dictParas, doIScriptEngine _scriptEngine, doInvokeResult _invokeResult)
        {
            try
            {
                if (this.model.GetPropertyValue("direction") == "horizontal")
                {
                    scroll.ChangeView(scroll.ScrollableWidth, null, null);
                }
                else
                {
                    scroll.ChangeView(null, scroll.ScrollableHeight, null);
                }
            }
            catch (Exception _err)
            {
                doServiceContainer.LogEngine.WriteError("doScrollView toEnd \n", _err);
            }
        }
    }
}
