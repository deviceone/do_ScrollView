package extimplement;

import java.util.Map;

import android.content.Context;
import android.graphics.Color;
import android.os.Handler;
import android.view.MotionEvent;
import android.view.View;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import core.DoServiceContainer;
import core.helper.DoTextHelper;
import core.helper.DoUIModuleHelper;
import core.helper.DoUIModuleHelper.LayoutParamsType;
import core.helper.jsonparse.DoJsonNode;
import core.interfaces.DoIPage;
import core.interfaces.DoIScriptEngine;
import core.interfaces.DoIUIModuleView;
import core.object.DoInvokeResult;
import core.object.DoSourceFile;
import core.object.DoUIContainer;
import core.object.DoUIModule;
import extdefine.do_ScrollView_IMethod;
import extdefine.do_ScrollView_MAbstract;

/**
 * 自定义扩展UIView组件实现类，此类必须继承相应VIEW类，并实现DoIUIModuleView,Do_ScrollView_IMethod接口；
 * #如何调用组件自定义事件？可以通过如下方法触发事件：
 * this.model.getEventCenter().fireEvent(_messageName, jsonResult);
 * 参数解释：@_messageName字符串事件名称，@jsonResult传递事件参数对象；
 * 获取DoInvokeResult对象方式new DoInvokeResult(this.model.getUniqueKey());
 */
public class do_ScrollView_View extends LinearLayout implements DoIUIModuleView,do_ScrollView_IMethod{

	private static final int PULL_TO_REFRESH = 0; // 下拉刷新
	private static final int RELEASE_TO_REFRESH = 1; // 松开后刷新
	private static final int REFRESHING = 2; // 加载中...
	private static final int PULL_DOWN_STATE = 3; // 刷新完成
	/**
	 * 每个UIview都会引用一个具体的model实例；
	 */
	private do_ScrollView_MAbstract model;
	private String defaultDirection = "vertical";
	private DoIScrollView doIScrollView;
	private View childView;
	private View mHeaderView;
	private int mHeaderViewHeight;
	private int mLastMotionX, mLastMotionY;
	private int mHeaderState;
	private int mPullState;
	private boolean supportHeaderRefresh;
	

	public do_ScrollView_View(Context context) {
		super(context);
		this.setOrientation(VERTICAL);
	}
	
	/**
	 * 初始化加载view准备,_doUIModule是对应当前UIView的model实例
	 */
	@Override
	public void loadView(DoUIModule _doUIModule) throws Exception {
		this.model = (do_ScrollView_MAbstract)_doUIModule;
		int childSize = model.getChildUIModules().size();
		if (childSize == 0) {
			return;
		}
		if (childSize > 1) {
			throw new RuntimeException("ScrollView loadView Error! 只允许包含一个子UIView");
		}
		DoUIModule _childUI = this.model.getChildUIModules().get(0);
		childView = (View) _childUI.getCurrentUIModuleView();
		_childUI.setLayoutParamsType(LayoutParamsType.Alayout.toString());

		String _headerViewPath = this.model.getHeaderView();
		if (_headerViewPath != null && !"".equals(_headerViewPath.trim())) {
			try {
				DoIPage _doPage = this.model.getCurrentPage();
				DoSourceFile _uiFile = _doPage.getCurrentApp().getSourceFS().getSourceByFileName(_headerViewPath);
				if (_uiFile != null) {

					DoUIContainer _rootUIContainer = new DoUIContainer(_doPage);
					_rootUIContainer.loadFromFile(_uiFile, null, null);
					_rootUIContainer.loadDefalutScriptFile(_headerViewPath);
					DoUIModule _model = _rootUIContainer.getRootView();

					View _headerView = (View) _model.getCurrentUIModuleView();
					// 设置headerView 的 宽高
					_headerView.setLayoutParams(new LayoutParams((int) _model.getRealWidth(), (int) _model.getRealHeight()));
					addHeaderView(_headerView);
					this.supportHeaderRefresh = true;
				} else {
					this.supportHeaderRefresh = false;
					DoServiceContainer.getLogEngine().writeDebug("试图打开一个无效的页面文件:" + _headerViewPath);
				}
			} catch (Exception _err) {
				DoServiceContainer.getLogEngine().writeError("DoScrollView  headerView \n", _err);
			}
		}
		String direction = this.model.getDirection();
		if (direction == null || "".equals(direction.trim())) {
			direction = defaultDirection;
		}
		initView(direction);
	}
	
	/**
	 * 动态修改属性值时会被调用，方法返回值为true表示赋值有效，并执行onPropertiesChanged，否则不进行赋值；
	 * @_changedValues<key,value>属性集（key名称、value值）；
	 */
	@Override
	public boolean onPropertiesChanging(Map<String, String> _changedValues) {
		return true;
	}
	
	/**
	 * 属性赋值成功后被调用，可以根据组件定义相关属性值修改UIView可视化操作；
	 * @_changedValues<key,value>属性集（key名称、value值）；
	 */
	@Override
	public void onPropertiesChanged(Map<String, String> _changedValues) {
		DoUIModuleHelper.handleBasicViewProperChanged(this.model, _changedValues);
		if (_changedValues.containsKey("isShowbar")) {
			boolean verticalScrollBarEnabled = DoTextHelper.strToBool(_changedValues.get("isShowbar"), true);
			doIScrollView.isShowbar(verticalScrollBarEnabled);
		}
	}
	
	/**
	 * 同步方法，JS脚本调用该组件对象方法时会被调用，可以根据_methodName调用相应的接口实现方法；
	 * @_methodName 方法名称
	 * @_dictParas 参数（K,V）
	 * @_scriptEngine 当前Page JS上下文环境对象
	 * @_invokeResult 用于返回方法结果对象
	 */
	@Override
	public boolean invokeSyncMethod(String _methodName, DoJsonNode _dictParas,
			DoIScriptEngine _scriptEngine, DoInvokeResult _invokeResult)throws Exception {
		if ("toBegin".equals(_methodName)) {
			toBegin(_dictParas, _scriptEngine, _invokeResult);
			return true;
		}
		if ("toEnd".equals(_methodName)) {
			toEnd(_dictParas, _scriptEngine, _invokeResult);
			return true;
		}
		if ("rebound".equals(_methodName)) {
			rebound(_dictParas, _scriptEngine, _invokeResult);
			return true;
		}
		return false;
	}
	
	/**
	 * 异步方法（通常都处理些耗时操作，避免UI线程阻塞），JS脚本调用该组件对象方法时会被调用，
	 * 可以根据_methodName调用相应的接口实现方法；
	 * @_methodName 方法名称
	 * @_dictParas 参数（K,V）
	 * @_scriptEngine 当前page JS上下文环境
	 * @_callbackFuncName 回调函数名
	 * #如何执行异步方法回调？可以通过如下方法：
	 *	_scriptEngine.callback(_callbackFuncName, _invokeResult);
	 * 参数解释：@_callbackFuncName回调函数名，@_invokeResult传递回调函数参数对象；
	   获取DoInvokeResult对象方式new DoInvokeResult(this.model.getUniqueKey());
	 */
	@Override
	public boolean invokeAsyncMethod(String _methodName, DoJsonNode _dictParas,
			DoIScriptEngine _scriptEngine, String _callbackFuncName) {
		//...do something
		return false;
	}
	
	/**
	* 释放资源处理，前端JS脚本调用closePage或执行removeui时会被调用；
	*/
	@Override
	public void onDispose() {
		//...do something
	}
	
	/**
	* 重绘组件，构造组件时由系统框架自动调用；
	  或者由前端JS脚本调用组件onRedraw方法时被调用（注：通常是需要动态改变组件（X、Y、Width、Height）属性时手动调用）
	*/
	@Override
	public void onRedraw() throws Exception{
		if (this.model.getLayoutParamsType() != null) {
			this.setLayoutParams(DoUIModuleHelper.getLayoutParams(this.model));
		}
		int childSize = model.getChildUIModules().size();
		if (childSize == 0) {
			return;
		}
		DoUIModule _childUI = this.model.getChildUIModules().get(0);
		_childUI.getCurrentUIModuleView().onRedraw();
	}
	
	private void initView(String direction) {
		Context context = (Context) model.getCurrentPage().getPageView();
		if ("horizontal".equals(direction)) {
			this.doIScrollView = new HScrollView(context);
		} else if ("vertical".equals(direction)) {
			this.doIScrollView = new VScrollView(context);
		}
		doIScrollView.addFirstView(childView);
		this.addView((View) doIScrollView);
	}
	
	/**
	 * 获取当前model实例
	 */
	@Override
	public DoUIModule getModel() {
		return model;
	}
	
	private void addHeaderView(View _mHeaderView) {
		// header view
		this.mHeaderView = _mHeaderView;
		// header layout
		DoUIModuleHelper.measureView(mHeaderView);
		mHeaderViewHeight = mHeaderView.getMeasuredHeight();
		LayoutParams params = new LayoutParams(LayoutParams.MATCH_PARENT, mHeaderViewHeight);
		// 设置topMargin的值为负的header View高度,即将其隐藏在最上方
		params.topMargin = -(mHeaderViewHeight);
		addView(mHeaderView, params);
	}

	@Override
	public boolean onInterceptTouchEvent(MotionEvent e) {
		int y = (int) e.getRawY();
		int x = (int) e.getRawX();
		switch (e.getAction()) {
		case MotionEvent.ACTION_DOWN:
			// 首先拦截down事件,记录y坐标
			mLastMotionY = y;
			mLastMotionX = x;
			break;
		case MotionEvent.ACTION_MOVE:
			// deltaY > 0 是向下运动,< 0是向上运动
			int deltaX = x - mLastMotionX;
			int deltaY = y - mLastMotionY;
			boolean isRefresh = isRefreshViewScroll(deltaX, deltaY);
			// 一旦底层View收到touch的action后调用这个方法那么父层View就不会再调用onInterceptTouchEvent了，也无法截获以后的action
			getParent().requestDisallowInterceptTouchEvent(isRefresh);
			if (isRefresh) {
				return true;
			}
			break;
		case MotionEvent.ACTION_UP:
		case MotionEvent.ACTION_CANCEL:
			break;
		}
		return false;
	}

	/**
	 * 是否应该到了父View,即PullToRefreshView滑动
	 * 
	 * @param deltaY
	 *            , deltaY > 0 是向下运动,< 0是向上运动
	 * @return
	 */
	private boolean isRefreshViewScroll(int deltaX, int deltaY) {
		if (mHeaderState == REFRESHING) {
			return false;
		}
		// 对于ScrollView
		if (doIScrollView != null) {
			// 子scroll view滑动到最顶端
			if (deltaY > 0 && supportHeaderRefresh && doIScrollView.getScrollY() == 0) {
				mPullState = PULL_DOWN_STATE;
				// 刷新完成......
				return true;
			}
		}
		return false;
	}

	/*
	 * 如果在onInterceptTouchEvent()方法中没有拦截(即onInterceptTouchEvent()方法中 return
	 * false)则由PullToRefreshView 的子View来处理;否则由下面的方法来处理(即由PullToRefreshView自己来处理)
	 */
	@Override
	public boolean onTouchEvent(MotionEvent event) {
		int y = (int) event.getRawY();
		switch (event.getAction()) {
		case MotionEvent.ACTION_DOWN:
			// onInterceptTouchEvent已经记录
			// mLastMotionY = y;
			break;
		case MotionEvent.ACTION_MOVE:
			int deltaY = y - mLastMotionY;
			if (mPullState == PULL_DOWN_STATE) {// 执行下拉
				if (supportHeaderRefresh)
					headerPrepareToRefresh(deltaY);
				// setHeaderPadding(-mHeaderViewHeight);
			}
			mLastMotionY = y;
			break;
		case MotionEvent.ACTION_UP:
		case MotionEvent.ACTION_CANCEL:
			int topMargin = getHeaderTopMargin();
			if (mPullState == PULL_DOWN_STATE) {
				if (topMargin >= 0) {
					// 开始刷新
					if (supportHeaderRefresh)
						headerRefreshing();
				} else {
					if (supportHeaderRefresh)
						// 还没有执行刷新，重新隐藏
						setHeaderTopMargin(-mHeaderViewHeight);
				}
			}
			break;
		}
		return false;
	}

	/**
	 * 获取当前header view 的topMargin
	 * 
	 */
	private int getHeaderTopMargin() {
		LayoutParams params = (LayoutParams) mHeaderView.getLayoutParams();
		return params.topMargin;
	}

	/**
	 * header refreshing
	 * 
	 */
	private void headerRefreshing() {
		mHeaderState = REFRESHING;
		setHeaderTopMargin(0);
		doPullRefresh(mHeaderState, 0);
		new Handler().postDelayed(new Runnable() {
			@Override
			public void run() {
				onHeaderRefreshComplete();
			}
		}, 3000);

	}

	/**
	 * 设置header view 的topMargin的值
	 * 
	 * @param topMargin
	 *            ，为0时，说明header view 刚好完全显示出来； 为-mHeaderViewHeight时，说明完全隐藏了
	 */
	private void setHeaderTopMargin(int topMargin) {
		LayoutParams params = (LayoutParams) mHeaderView.getLayoutParams();
		params.topMargin = topMargin;
		mHeaderView.setLayoutParams(params);
		invalidate();
	}

	/**
	 * header view 完成更新后恢复初始状态
	 * 
	 */
	public void onHeaderRefreshComplete() {
		setHeaderTopMargin(-mHeaderViewHeight);
		mHeaderState = PULL_TO_REFRESH;
	}

	/**
	 * header 准备刷新,手指移动过程,还没有释放
	 * 
	 * @param deltaY
	 *            ,手指滑动的距离
	 */
	private void headerPrepareToRefresh(int deltaY) {
		int newTopMargin = changingHeaderViewTopMargin(deltaY);
		// 当header view的topMargin>=0时，说明已经完全显示出来了,修改header view 的提示状态
		if (newTopMargin >= 0 && mHeaderState != RELEASE_TO_REFRESH) {
			mHeaderState = RELEASE_TO_REFRESH;
		} else if (newTopMargin < 0 && newTopMargin > -mHeaderViewHeight) {// 拖动时没有释放
			mHeaderState = PULL_TO_REFRESH;
		}
		doPullRefresh(mHeaderState, newTopMargin);
	}

	/**
	 * 修改Header view top margin的值
	 * 
	 * @param deltaY
	 */
	private int changingHeaderViewTopMargin(int deltaY) {
		LayoutParams params = (LayoutParams) mHeaderView.getLayoutParams();
		float newTopMargin = params.topMargin + deltaY * 0.3f;
		// 这里对上拉做一下限制,因为当前上拉后然后不释放手指直接下拉,会把下拉刷新给触发了
		// 表示如果是在上拉后一段距离,然后直接下拉
//		if (deltaY > 0 && mPullState == PULL_UP_STATE && Math.abs(params.topMargin) <= mHeaderViewHeight) {
//			return params.topMargin;
//		}
		// 同样地,对下拉做一下限制,避免出现跟上拉操作时一样的bug
		if (deltaY < 0 && mPullState == PULL_DOWN_STATE && Math.abs(params.topMargin) >= mHeaderViewHeight) {
			return params.topMargin;
		}
		params.topMargin = (int) newTopMargin;
		mHeaderView.setLayoutParams(params);
		invalidate();
		return params.topMargin;
	}
	
	interface DoIScrollView {
		// view.post方法里等待队列处理，view获得当前线程（即UI线程）的Handler;
		void toBegin();

		int getScrollY();

		void toEnd();

		void isShowbar(boolean verticalScrollBarEnabled);

		void addFirstView(View childView);
	}

	class HScrollView extends HorizontalScrollView implements DoIScrollView {

		public HScrollView(Context context) {
			super(context);
			this.setFillViewport(true);
			this.setBackgroundColor(Color.TRANSPARENT);
			this.setHorizontalScrollBarEnabled(false);
		}

		@Override
		public void toBegin() {
			this.post(new Runnable() {
				@Override
				public void run() {
					fullScroll(ScrollView.FOCUS_LEFT);
				}
			});
		}

		@Override
		public void toEnd() {
			this.post(new Runnable() {
				@Override
				public void run() {
					fullScroll(ScrollView.FOCUS_RIGHT);
				}
			});
		}

		@Override
		public void isShowbar(boolean horizontalScrollBarEnabled) {
			this.setHorizontalScrollBarEnabled(horizontalScrollBarEnabled);
		}

		@Override
		public void addFirstView(View childView) {
			if (null != childView) {
				this.addView(childView);
			}
		}
	}

	class VScrollView extends ScrollView implements DoIScrollView {

		public VScrollView(Context context) {
			super(context);
			this.setFillViewport(true);
			this.setBackgroundColor(Color.TRANSPARENT);
			this.setVerticalScrollBarEnabled(false);
		}

		@Override
		public void toBegin() {
			this.post(new Runnable() {
				@Override
				public void run() {
					fullScroll(ScrollView.FOCUS_UP);
				}
			});
		}

		@Override
		public void toEnd() {
			this.post(new Runnable() {
				@Override
				public void run() {
					fullScroll(ScrollView.FOCUS_DOWN);
				}
			});
		}

		@Override
		public void isShowbar(boolean verticalScrollBarEnabled) {
			this.setVerticalScrollBarEnabled(verticalScrollBarEnabled);
		}

		@Override
		public void addFirstView(View childView) {
			if (null != childView) {
				this.addView(childView);
			}
		}
	}

	private void doPullRefresh(int mHeaderState, int newTopMargin) {
		DoInvokeResult _invokeResult = new DoInvokeResult(this.model.getUniqueKey());
		try {
			DoJsonNode _node = new DoJsonNode();
			_node.setOneInteger("state", mHeaderState);
			_node.setOneText("y", (newTopMargin / this.model.getInnerYZoom()) + "");
			_invokeResult.setResultNode(_node);
			this.model.getEventCenter().fireEvent("pull", _invokeResult);
		} catch (Exception _err) {
			DoServiceContainer.getLogEngine().writeError("DoScrollview pull \n", _err);
		}
	}

	@Override
	public void toBegin(DoJsonNode _dictParas, DoIScriptEngine _scriptEngine,
			DoInvokeResult _invokeResult) throws Exception {
		doIScrollView.toBegin();
		
	}

	@Override
	public void toEnd(DoJsonNode _dictParas, DoIScriptEngine _scriptEngine,
			DoInvokeResult _invokeResult) throws Exception {
		doIScrollView.toEnd();
		
	}

	@Override
	public void rebound(DoJsonNode _dictParas, DoIScriptEngine _scriptEngine,
			DoInvokeResult _invokeResult) throws Exception {
		onHeaderRefreshComplete();
		
	}
}
