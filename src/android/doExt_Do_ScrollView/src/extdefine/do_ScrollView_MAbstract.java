package extdefine;

import core.object.DoProperty;
import core.object.DoProperty.PropertyDataType;
import core.object.DoUIModuleCollection;


public abstract class do_ScrollView_MAbstract extends DoUIModuleCollection{

	protected do_ScrollView_MAbstract() throws Exception {
		super();
	}
	
	/**
	 * 初始化
	 */
	@Override
	public void onInit() throws Exception{
        super.onInit();
        //注册属性
        this.registProperty(new DoProperty("direction", PropertyDataType.String, "vertical", true));
		this.registProperty(new DoProperty("isShowbar", PropertyDataType.Bool, "true", true));
		this.registProperty(new DoProperty("headerView", PropertyDataType.String, "", true));
    }
	
}